## Coverage culler: drops body-mesh triangles whose skin weights lie under worn
## outfit pieces; cached ArrayMesh copies, sources never mutated; no class_name
## (preload it). Bad meshes pass through intact: degrade to overlay, never crash.
extends RefCounted

static var _cache: Dictionary = {}


## Skeleton bone indices (i -> true) whose region group is in `regions`.
static func covered_indices(skeleton: Skeleton3D, regions: Array) -> Dictionary:
	var covered := {}
	for i in skeleton.get_bone_count():
		if bone_region(skeleton.get_bone_name(i)) in regions:
			covered[i] = true
	return covered


## Region group for a universal-rig bone name; "" when unclassified (root).
static func bone_region(bone_name: String) -> String:
	# Granularity: neck split from head (hoods never eat faces); calf from thigh.
	var n := bone_name.to_lower()
	var side := ""
	if n.ends_with("_l"):
		side = "_l"
	elif n.ends_with("_r"):
		side = "_r"
	if n == "pelvis" or n.begins_with("spine"):
		return "torso"
	if n == "head":
		return "head"
	if n.begins_with("neck"):
		return "neck"
	if n.begins_with("clavicle") or n.begins_with("upperarm") or n.begins_with("lowerarm"):
		return "arm" + side
	if n.begins_with("hand") or n.begins_with("index") or n.begins_with("middle") \
			or n.begins_with("pinky") or n.begins_with("ring") or n.begins_with("thumb"):
		return "hand" + side
	if n.begins_with("thigh"):
		return "thigh" + side
	if n.begins_with("calf"):
		return "calf" + side
	if n.begins_with("foot") or n.begins_with("ball"):
		return "foot" + side
	return ""


## Culled copy of `source` under `covered` bones; source never mutated; cached.
static func culled_mesh(source: Mesh, skeleton: Skeleton3D, covered: Dictionary, strictness: float) -> Mesh:
	if covered.is_empty() or source == null or skeleton == null:
		return source
	if source.get_blend_shape_count() > 0:
		push_warning("body_cull: blend shapes unsupported -- mesh left intact")
		return source
	var key := _cache_key(source, covered, strictness)
	if _cache.has(key):
		return _cache[key]
	var out := ArrayMesh.new()
	for s in source.get_surface_count():
		var arrays := source.surface_get_arrays(s)
		if arrays[Mesh.ARRAY_INDEX] == null or arrays[Mesh.ARRAY_BONES] == null \
				or arrays[Mesh.ARRAY_WEIGHTS] == null:
			push_warning("body_cull: surface %d lacks index/skin -- mesh left intact" % s)
			return source
		var kept := _kept_indices(arrays, covered, strictness)
		if kept.is_empty():
			continue
		arrays[Mesh.ARRAY_INDEX] = kept
		out.add_surface_from_arrays(source.surface_get_primitive_type(s), arrays, [], {}, source.surface_get_format(s))
		var mat := source.surface_get_material(s)
		if mat != null:
			out.surface_set_material(out.get_surface_count() - 1, mat)
	if out.get_surface_count() == 0:
		return source
	_cache[key] = out
	return out


## Kept triangle indices: covered weight < strictness x total (1.0 = no holes).
static func _kept_indices(arrays: Array, covered: Dictionary, strictness: float) -> PackedInt32Array:
	# Strictness 1.0 keeps boundary triangles: seams hide under the outfit edge.
	var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	var kept := PackedInt32Array()
	for t in range(0, idx.size(), 3):
		var cov := 0.0
		var total := 0.0
		for k in range(t, t + 3):
			var v := idx[k]
			for j in range(v * 4, v * 4 + 4):
				total += weights[j]
				if covered.has(bones[j]):
					cov += weights[j]
		if cov < total * strictness - 0.0001:
			kept.append(idx[t])
			kept.append(idx[t + 1])
			kept.append(idx[t + 2])
	return kept


## Stable cache key: mesh instance id + sorted covered bones + quantized strictness.
static func _cache_key(source: Mesh, covered: Dictionary, strictness: float) -> String:
	var names := PackedStringArray()
	for i in covered.keys():
		names.append(str(i))
	names.sort()
	return "%d|%s|%.3f" % [source.get_instance_id(), ",".join(names), strictness]


