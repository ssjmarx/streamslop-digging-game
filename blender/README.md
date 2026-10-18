# blender/ — wardrobe sources (human-authored)

Sources for the wardrobe GLBs. Two-roots law: these `.blend` files are sources,
not `res://` assets — they are committed here; the exports land in
`godot/assets/characters/wardrobe/` and get their catalog entries there.

## The one rule of this directory
Geometry is human. No script in this repo writes a mesh; tools may only check.

## Files
- `wardrobe_female.blend` — the female body + every female piece
- `wardrobe_male.blend` — the male body + every male piece

## Naming convention (node names become the runtime table's keys)
Underscores, no spaces, no dots. Names are looked up at runtime — keep them.
- `Armature` — the ONE skeleton. Never rename. UAL binds animations by it.
- `Body_Under` — the body mesh with the head split off.
- `Head` — the split-off head (weights ride along; it still animates).
- `Eyes`, `Brows`, `Hair_<name>` — face furniture and hair, rigged to Head.
- Garment pieces: `<Outfit>_<Slot>` — `Peasant_Body`, `Peasant_Arms`,
  `Peasant_Legs`, `Peasant_Feet`, `Ranger_Body`, `Ranger_Arms`, `Ranger_Legs`,
  `Ranger_Feet`.
- Accessories: `Ranger_Hood`, `Ranger_Pauldrons`, `Ranger_Bracer`,
  `Ranger_Belt_1`, `Ranger_Belt_2`.
- Forbidden anywhere: `Armature.001` (the duplicate armature is deleted, not
  renamed), spaces, dots, duplicate names.

## Per-piece attach checklist (30 seconds each — never skip)
1. Import the piece glTF; it arrives with its own duplicate armature.
2. Select ONLY the piece mesh, then Shift+click `Armature` (mesh first, armature
   last). `Ctrl+P > Armature Deform`. NOT "With Automatic Weights" — the shipped
   weights are correct; automatic recomputation would ruin them.
3. Modifiers tab (blue wrench): delete the OLD Armature modifier — the one
   pointing at the duplicate armature.
4. Outliner: delete the duplicate armature.
5. Pose Mode: bend an arm bone and a leg bone; the piece must follow the body.
   `Ctrl+Z` to undo. Any lag = wrong modifier target or a vertex-group name
   mismatch with the bones.

## Head split (once per body)
Edit Mode on the body mesh, X-ray on (`Alt+Z`), front view (`Numpad 1`),
box-select (`B`) everything above the neck line; rotate (`Numpad 3`) and catch
the back of the head, ears, chin. `P > Selection`. Rename the new object `Head`
(weights came along), rename the remainder `Body_Under`.

## Before every export
- Pose Mode: `A` (select all bones) > Pose > Clear Transform > All. A posed
  export bakes the pose in — classic trap.
- Every object's scale is 1.0 (N panel).

## Export
File > Export > glTF 2.0. Format: glTF Binary (.glb). Name:
`wardrobe_female.glb` / `wardrobe_male.glb`. Every other setting at default —
Quaternius' own GLBs are Blender-made; the defaults are proven for Godot.

## In this repo
    python3 tools/wardrobe_check.py godot/assets/characters/wardrobe/wardrobe_female.glb
Must exit 0 before the GLB is committed. Then import in Godot and run the eye
test: toggle each piece, bend the rig, check FPV and TPV.

## The slot model (the runtime contract)
Slots: head / torso / arms / legs / feet / accessory / hair — one piece per
slot, so conflicts cannot happen by construction. Each piece declares which
whole meshes it `hides` (usually nothing; a closed helmet hides `Head`; a
bodysuit hides `Body_Under`). Mixing pieces within a gender is authoring-free.
Cross-gender ports are manual Blender work — shape around the target part,
Shrinkwrap (Project) to sit on the surface, Data Transfer (Nearest Face
Interpolated, Vertex Groups) for weights. Never Automatic Weights: the "Bone
Heat Weighting failed" error is the sign you took the wrong road.
