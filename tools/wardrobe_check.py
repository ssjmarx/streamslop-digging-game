#!/usr/bin/env python3
"""Wardrobe export validator: gate the Blender-authored body GLBs.

Reads a glTF-binary export of a wardrobe body (every piece skinned to the one
armature) and checks the contract the runtime relies on: exactly one skin,
clean node names, the universal-rig bones present, every mesh skinned with no
zero-weight vertices, no scaled nodes, embedded buffers. It READS; it never
writes or fixes geometry -- that is the automation boundary (dev_log Entry #4).

Usage:
    python3 tools/wardrobe_check.py BODY.glb [MORE.glb ...]

Exit codes: 0 = every file passes; 1 = violations listed; 2 = usage/IO error.
"""

import json
import struct
import sys

# Node names the runtime looks up directly. A missing one is fatal.
REQUIRED_NODES = ("Armature", "Head", "Body", "Arms", "Legs", "Feet")

# Universal-rig bones the animation and wardrobe systems rely on (Quaternius
# universal rig; the names body_cull.gd's region map and the UAL libraries
# are built from -- note the rig's head bone is "Head", capital H, matching
# player_controller.gd's HEAD_BONE).
REQUIRED_BONES = (
    "pelvis", "spine_01", "spine_02", "spine_03", "neck_01", "Head",
    "clavicle_l", "clavicle_r", "upperarm_l", "upperarm_r",
    "lowerarm_l", "lowerarm_r", "hand_l", "hand_r",
    "thigh_l", "thigh_r", "calf_l", "calf_r", "foot_l", "foot_r",
)

# Forbidden in any node name: spaces and dots (catches "My Mesh", "Armature.001").
_FORBIDDEN_CHARS = (" ", ".")

# The naming grammar (dev_log Addendum 30): single-token names are body
# regions or face furniture; two-token names are garment slots; three-plus
# are free accessories.
_REGION_WORDS = ("Head", "Body", "Arms", "Legs", "Feet")
_FIXED_PIECE_NAMES = ("Eyes", "Eyebrows")
_HAIR_PREFIX = "Hair_"
_SLOT_WORDS = ("Body", "Arms", "Legs", "Feet")

_COMPONENT_SIZES = {5120: 1, 5121: 1, 5122: 2, 5123: 2, 5125: 4, 5126: 4}
_TYPE_COUNTS = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT3": 9, "MAT4": 16}


class GlbError(ValueError):
    """A file this checker cannot or should not judge."""


def parse_glb(path):
    """Return (doc, bin_bytes) for a .glb; reject non-GLB files and external buffers."""
    with open(path, "rb") as fh:
        data = fh.read()
    if len(data) < 20 or data[0:4] != b"glTF":
        raise GlbError("not a glTF-binary file (bad magic)")
    version = struct.unpack_from("<I", data, 4)[0]
    if version != 2:
        raise GlbError("glTF version %d, need 2" % version)
    doc = None
    blob = b""
    offset = 12
    while offset + 8 <= len(data):
        chunk_len = struct.unpack_from("<I", data, offset)[0]
        chunk_type = data[offset + 4:offset + 8]
        chunk = data[offset + 8:offset + 8 + chunk_len]
        if chunk_type == b"JSON":
            doc = json.loads(chunk.decode("utf-8"))
        elif chunk_type == b"BIN\x00":
            blob = chunk
        offset += 8 + chunk_len
    if doc is None:
        raise GlbError("no JSON chunk found")
    if any("uri" in b for b in doc.get("buffers", [])):
        raise GlbError("external buffer uri found -- the export must embed its data (.glb)")
    return doc, blob


def accessor_flat(doc, blob, index):
    """Read an accessor into a flat float list (de-normalized), honoring strides."""
    acc = doc["accessors"][index]
    count = acc["count"]
    ncomp = _TYPE_COUNTS[acc["type"]]
    ctype = acc["componentType"]
    size = _COMPONENT_SIZES[ctype]
    view = doc["bufferViews"][acc["bufferView"]]
    start = view.get("byteOffset", 0) + acc.get("byteOffset", 0)
    stride = view.get("byteStride") or size * ncomp
    normalized = acc.get("normalized", False)
    out = []
    for i in range(count):
        base = start + i * stride
        for c in range(ncomp):
            raw = blob[base + c * size:base + (c + 1) * size]
            if ctype == 5126:
                out.append(struct.unpack("<f", raw)[0])
            elif ctype == 5121:
                out.append(raw[0] / 255.0 if normalized else float(raw[0]))
            elif ctype == 5120:
                v = struct.unpack("<b", raw)[0]
                out.append(v / 127.0 if normalized else float(v))
            elif ctype == 5123:
                v = struct.unpack("<H", raw)[0]
                out.append(v / 65535.0 if normalized else float(v))
            elif ctype == 5122:
                v = struct.unpack("<h", raw)[0]
                out.append(v / 32767.0 if normalized else float(v))
            else:
                out.append(float(struct.unpack("<I", raw)[0]))
    return out, count


def _node_scale_bad(node):
    """True when a node carries a non-unit scale (TRS or matrix form)."""
    scale = node.get("scale")
    if scale is not None:
        return any(abs(s - 1.0) > 1e-4 for s in scale)
    if "matrix" in node:
        m = node["matrix"]  # column-major; basis columns are the axes
        cols = [(m[0], m[1], m[2]), (m[4], m[5], m[6]), (m[8], m[9], m[10])]
        return any(abs(sum(v * v for v in col) ** 0.5 - 1.0) > 1e-4 for col in cols)
    return False


def _name_grammar_violation(name):
    """Return a violation message for a piece name, or None when it conforms.

    Body regions and face furniture are single-token and fixed; Hair_<name>
    is the hair slot; a two-token name must end in a slot word; three-or-more
    tokens are accessories and always pass.
    """
    if name in _REGION_WORDS or name in _FIXED_PIECE_NAMES:
        return None
    if name.startswith(_HAIR_PREFIX):
        return None
    parts = name.split("_")
    if len(parts) == 2:
        if parts[1] in _SLOT_WORDS:
            return None
        return ("two-token piece %r must end in a slot word (Body/Arms/"
                "Legs/Feet)" % name)
    if len(parts) >= 3:
        return None
    return "single-token name %r is not a body region or face furniture" % name


def check_glb(path):
    """Check one export against the wardrobe contract; return (lines, ok)."""
    lines = []
    state = {"ok": True}

    def fail(msg):
        state["ok"] = False
        lines.append("FAIL " + msg)

    try:
        doc, blob = parse_glb(path)
    except (GlbError, OSError) as exc:
        return ["FAIL %s" % exc], False

    nodes = doc.get("nodes", [])
    skins = doc.get("skins", [])
    meshes = doc.get("meshes", [])

    # -- Names: present, clean, unique among siblings, required trio exists.
    # A bone and a mesh may share a name (different namespaces once imported);
    # same-parent duplicates are what Godot silently renames, so those fail.
    parent = {}
    for i, node in enumerate(nodes):
        for child in node.get("children", []):
            parent[child] = i
    seen = {}
    for i, node in enumerate(nodes):
        name = node.get("name")
        if not name:
            fail("node %d has no name -- every node needs a stable runtime name" % i)
            continue
        for ch in _FORBIDDEN_CHARS:
            if ch in name:
                fail("node name %r contains %r -- underscores only" % (name, ch))
        if name in seen:
            if seen[name][1] == parent.get(i, -1):
                fail("duplicate node name %r under the same parent (nodes %d, %d) "
                     "-- Godot would silently rename one" % (name, seen[name][0], i))
            else:
                lines.append("INFO node name %r is shared across namespaces "
                             "(nodes %d, %d) -- legal, e.g. the Head bone and "
                             "the Head mesh" % (name, seen[name][0], i))
        else:
            seen[name] = (i, parent.get(i, -1))
    for required in REQUIRED_NODES:
        if required not in seen:
            fail("required node %r missing" % required)

    # -- Exactly one armature: one skin, and its joints carry the rig.
    if len(skins) != 1:
        fail("expected exactly 1 skin (one Armature); found %d -- a duplicate "
             "armature survived the attach" % len(skins))
    joints = skins[0].get("joints", []) if skins else []
    bone_names = []
    for j in joints:
        name = nodes[j].get("name")
        if not name:
            fail("joint node %d has no name" % j)
        else:
            bone_names.append(name)
    missing = [b for b in REQUIRED_BONES if b not in bone_names]
    if missing:
        fail("universal-rig bones missing: %s" % ", ".join(missing))

    # -- Every mesh node is skinned; primitives carry skin data; no zero-weight
    # vertices; no scaled nodes; no blend shapes.
    pieces = 0
    for i, node in enumerate(nodes):
        name = node.get("name", "node_%d" % i)
        if "mesh" not in node:
            if _node_scale_bad(node):
                fail("%s carries a non-unit scale (the tiny/huge trap)" % name)
            continue
        pieces += 1
        if node.get("name"):
            violation = _name_grammar_violation(node["name"])
            if violation:
                fail(violation)
        if "skin" not in node:
            fail("%s has a mesh but no skin -- it would not deform" % name)
        if _node_scale_bad(node):
            fail("%s carries a non-unit scale (the tiny/huge trap)" % name)
        mesh = meshes[node["mesh"]]
        if mesh.get("targets"):
            fail("%s carries blend shape targets -- not part of the contract" % name)
        for p, prim in enumerate(mesh.get("primitives", [])):
            attrs = prim.get("attributes", {})
            label = "%s primitive %d" % (name, p)
            if "WEIGHTS_0" not in attrs or "JOINTS_0" not in attrs:
                fail("%s lacks JOINTS_0/WEIGHTS_0 -- no skin data" % label)
                continue
            weights, count = accessor_flat(doc, blob, attrs["WEIGHTS_0"])
            zeros = 0
            for v in range(count):
                w = weights[v * 4:(v + 1) * 4]
                if not any(w):
                    zeros += 1
            if zeros:
                fail("%s: %d of %d vertices have all-zero weights (they would "
                     "not follow any bone)" % (label, zeros, count))

    lines.insert(0, "stats: %d nodes, %d skinned pieces, %d joints, %d meshes"
                % (len(nodes), pieces, len(joints), len(meshes)))
    return lines, state["ok"]


def main(argv):
    """Gate every file named on the command line; exit 0 only if all pass."""
    if len(argv) < 2:
        print(__doc__.strip())
        return 2
    result = 0
    for path in argv[1:]:
        lines, ok = check_glb(path)
        print("== %s: %s" % (path, "PASS" if ok else "FAIL"))
        for line in lines:
            print("   " + line)
        if not ok:
            result = 1
    return result


if __name__ == "__main__":
    sys.exit(main(sys.argv))


