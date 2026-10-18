## Probes the avatar + outfit meshes for the coverage-culling system: skeleton
## facts, array layouts, per-region dominance, simulated cull counts, and
## per-piece bone weight histograms -- the evidence OUTFIT_COVERAGE is authored from.
extends SceneTree

const AVATAR_SCENE := "res://assets/meshes/quaternius/superhero_female/Superhero_Female_FullBody.gltf"
const OUTFIT_SCENE := "res://assets/characters/outfits/Female_Ranger.gltf"
const BODY_NODE := "Superhero_Female"
## Candidate coverage sets to simulate at strictness 1.0 (fully-covered drops only).
const SIM_SETS := [
	["torso"],
	["torso", "neck", "thigh_l", "thigh_r", "calf_l", "calf_r"],
	["torso", "neck", "arm_l", "arm_r", "hand_l", "hand_r",
		"thigh_l", "thigh_r", "calf_l", "calf_r", "foot_l", "foot_r"],
]
## The region classifier is the production one -- the probe reports through it.
const BodyCull := preload("res://scripts/player/body_cull.gd")


## Load avatar + outfit, print every fact the coverage system relies on, quit clean.
func _initialize() -> void:
	var avatar := (load(AVATAR_SCENE) as PackedScene).instantiate()
	var outfit := (load(OUTFIT_SCENE) as PackedScene).instantiate()
	var skel := _find_skeleton(avatar)
	var oskel := _find_skeleton(outfit)
	print("== skeletons: avatar bones=", skel.get_bone_count(),
		"  outfit bones=", oskel.get_bone_count())
	_dump_body_mesh(avatar, skel)
	print("")
	for piece in _collect_meshes(outfit):
		_dump_piece_weights(piece, oskel)
	avatar.free()
	outfit.free()
	quit(0)


## Body mesh facts: array layout, blend shapes, region dominance, simulated culls.
func _dump_body_mesh(avatar: Node, skel: Skeleton3D) -> void:
	var body := _find_mesh(avatar, BODY_NODE)
	if body == null:
		print("!! body node not found: ", BODY_NODE)
		return
	var mesh := body.mesh
	print("== ", BODY_NODE, ": surfaces=", mesh.get_surface_count(),
		"  blend_shapes=", mesh.get_blend_shape_count())
	var surfaces: Array = []
	for s in mesh.get_surface_count():
		surfaces.append(mesh.surface_get_arrays(s))
		_dump_arrays(s, surfaces[s])
	var bones: PackedInt32Array = surfaces[0][Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = surfaces[0][Mesh.ARRAY_WEIGHTS]
	_dump_region_dominance(bones, weights, skel)
	_dump_sim_culls(surfaces, skel)


## One surface line: which arrays exist and their sizes (-1 = absent).
func _dump_arrays(s: int, arrays: Array) -> void:
	var names := ["vertex", "normal", "tangent", "color", "uv", "uv2", "bones", "weights", "index"]
	var keys := [Mesh.ARRAY_VERTEX, Mesh.ARRAY_NORMAL, Mesh.ARRAY_TANGENT, Mesh.ARRAY_COLOR,
		Mesh.ARRAY_TEX_UV, Mesh.ARRAY_TEX_UV2, Mesh.ARRAY_BONES, Mesh.ARRAY_WEIGHTS, Mesh.ARRAY_INDEX]
	var parts := PackedStringArray()
	for i in keys.size():
		var a: Variant = arrays[keys[i]]
		parts.append("%s=%d" % [names[i], a.size() if a != null else -1])
	print("  s%d: %s" % [s, " ".join(parts)])


## Per-region vertex counts by dominant bone, plus weight-sum sanity bounds.
func _dump_region_dominance(bones: PackedInt32Array, weights: PackedFloat32Array, skel: Skeleton3D) -> void:
	var per_region := {}
	var min_sum := 99.0
	var max_sum := 0.0
	var vcount := bones.size() / 4
	for v in vcount:
		var best := v * 4
		for j in range(v * 4 + 1, v * 4 + 4):
			if weights[j] > weights[best]:
				best = j
		var region := BodyCull.bone_region(skel.get_bone_name(bones[best]))
		per_region[region] = int(per_region.get(region, 0)) + 1
		var sum := 0.0
		for j in range(v * 4, v * 4 + 4):
			sum += weights[j]
		min_sum = minf(min_sum, sum)
		max_sum = maxf(max_sum, sum)
	print("  weight sums: min=%.3f max=%.3f  influences=%d/vertex" % [min_sum, max_sum, bones.size() / vcount])
	var order := per_region.keys()
	order.sort()
	for region in order:
		print("  dominant %s: %d vertices (%.1f%%)" % [
			region if region != "" else "(none)", per_region[region], 100.0 * per_region[region] / vcount])


## Triangle drop counts per candidate coverage set at strictness 1.0.
func _dump_sim_culls(surfaces: Array, skel: Skeleton3D) -> void:
	for regions in SIM_SETS:
		var covered := BodyCull.covered_indices(skel, regions)
		var total := 0
		var dropped := 0
		for arrays in surfaces:
			var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
			var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
			total += idx.size() / 3
			for t in range(0, idx.size(), 3):
				var cov := 0.0
				var all := 0.0
				for k in range(t, t + 3):
					var v := idx[k]
					for j in range(v * 4, v * 4 + 4):
						all += weights[j]
						if covered.has(bones[j]):
							cov += weights[j]
				if cov >= all - 0.0001:
					dropped += 1
		print("  cull %s: %d/%d triangles (%.1f%%)" % [regions, dropped, total, 100.0 * dropped / total])


## Per-piece bone weight histogram: what the piece actually weights onto (top 6).
func _dump_piece_weights(piece: MeshInstance3D, skel: Skeleton3D) -> void:
	var mesh := piece.mesh
	var sums := {}
	var grand := 0.0
	for s in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(s)
		var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		for i in bones.size():
			var bone_name := skel.get_bone_name(bones[i])
			sums[bone_name] = float(sums.get(bone_name, 0.0)) + weights[i]
			grand += weights[i]
	var order := sums.keys()
	order.sort_custom(func(a, b): return float(sums[a]) > float(sums[b]))
	var parts := PackedStringArray()
	for bone_name in order.slice(0, 6):
		parts.append("%s(%s) %.1f%%" % [bone_name, BodyCull.bone_region(bone_name), 100.0 * sums[bone_name] / grand])
	print(piece.name, ": grand=%.1f  top: %s" % [grand, ", ".join(parts)])


## First Skeleton3D under the node, depth-first; null when none.
func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	for child in node.get_children():
		var found := _find_skeleton(child)
		if found != null:
			return found
	return null


## First MeshInstance3D under the node with the given name; null when none.
func _find_mesh(node: Node, mesh_name: String) -> MeshInstance3D:
	if node is MeshInstance3D and String(node.name) == mesh_name:
		return node
	for child in node.get_children():
		var found := _find_mesh(child, mesh_name)
		if found != null:
			return found
	return null


## Depth-first collect of every MeshInstance3D under the node.
func _collect_meshes(node: Node) -> Array:
	var out := []
	if node is MeshInstance3D:
		out.append(node)
	for child in node.get_children():
		out.append_array(_collect_meshes(child))
	return out


