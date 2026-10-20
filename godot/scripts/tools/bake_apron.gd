## One-shot baker for the apron (2026-10-19): the ring is LEVEL GEOMETRY now --
## real nodes in main.tscn referencing the saved resources, so corey can see and
## hand-edit it. Run headless: Godot --headless --path godot --script res://scripts/tools/bake_apron.gd
extends SceneTree

const WORLD_RADIUS := 50.0   # the disc law, verbatim from dirt_checker_generator
const APRON_WIDTH := 5.0     # the doughnut extends this far beyond the rim
const INNER_EPS := 0.05      # the inner loop rides this far UNDER the voxel boundary
const MESH_PATH := "res://scenes/world/apron_mesh.tres"
const SHAPE_PATH := "res://scenes/world/apron_shape.tres"


## Bake the doughnut: the hole is the voxel disc's EXACT silhouette; save mesh + trimesh shape as text resources.
func _initialize() -> void:
	var loop := _boundary_loop()
	if loop.size() < 100:
		print("bake_apron: FAIL -- boundary loop too small (%d points)" % loop.size())
		quit(1)
		return
	var mesh := _build_ring(loop)
	var mesh_err := ResourceSaver.save(mesh, MESH_PATH)
	var shape := mesh.create_trimesh_shape()
	var shape_err := ResourceSaver.save(shape, SHAPE_PATH)
	var radii: Array[float] = []
	for point in loop:
		radii.append(point.length())
	print("bake_apron: loop %d pts, inner r %.2f..%.2f; mesh -> %s (%s), shape -> %s (%s)" % [
		loop.size(), radii.min(), radii.max(),
		MESH_PATH, error_string(mesh_err), SHAPE_PATH, error_string(shape_err)])
	quit()


## The painted-cell test, verbatim from dirt_checker_generator (corner within WORLD_RADIUS = disc).
func _painted(cx: int, cz: int) -> bool:
	return Vector2(cx, cz).length() <= WORLD_RADIUS


## The disc's exact silhouette: walk the painted-cell union's boundary edges (solid on the left, CCW) into one closed lattice loop.
func _boundary_loop() -> Array[Vector2]:
	var edges := {}
	for cz in range(-51, 51):
		for cx in range(-51, 51):
			if not _painted(cx, cz):
				continue
			if not _painted(cx, cz - 1):
				_add_edge(edges, Vector2i(cx, cz), Vector2i(cx + 1, cz))          # bottom: +x
			if not _painted(cx + 1, cz):
				_add_edge(edges, Vector2i(cx + 1, cz), Vector2i(cx + 1, cz + 1))  # right: +z
			if not _painted(cx, cz + 1):
				_add_edge(edges, Vector2i(cx + 1, cz + 1), Vector2i(cx, cz + 1))  # top: -x
			if not _painted(cx - 1, cz):
				_add_edge(edges, Vector2i(cx, cz + 1), Vector2i(cx, cz))          # left: -z
	var loop: Array[Vector2] = []
	var start: Vector2i = edges.keys()[0]
	var prev := start
	var current: Vector2i = edges[start][0]
	loop.append(Vector2(start))
	var guard := edges.size() * 2 + 8
	while current != start and guard > 0:
		guard -= 1
		loop.append(Vector2(current))
		var incoming := current - prev
		var options: Array = edges[current]
		var next: Vector2i
		if options.size() == 1:
			next = options[0]
		else:
			var left := Vector2i(-incoming.y, incoming.x)   # leftmost turn keeps the outer silhouette at pinches
			next = left if left in options else (incoming if incoming in options else -left)
		prev = current
		current = next
	return loop


## Register one directed boundary edge (from -> to) in the walk table.
func _add_edge(edges: Dictionary, from: Vector2i, to: Vector2i) -> void:
	if not edges.has(from):
		edges[from] = []
	edges[from].append(to)


## The doughnut: inner vertices ride INNER_EPS under the silhouette; outer vertices 5m beyond them radially; CW-from-above winding.
func _build_ring(loop: Array[Vector2]) -> ArrayMesh:
	var count := loop.size()
	var verts := PackedVector3Array()
	var uvs := PackedVector2Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	for i in count:
		var v := loop[i]
		var n := v.normalized()
		var inner := v - n * INNER_EPS
		var outer := n * (v.length() + APRON_WIDTH)
		verts.append(Vector3(inner.x, 0.0, inner.y))
		verts.append(Vector3(outer.x, 0.0, outer.y))
		uvs.append(Vector2(float(i) / float(count), 0.0))
		uvs.append(Vector2(float(i) / float(count), 1.0))
		normals.append(Vector3.UP)
		normals.append(Vector3.UP)
	for i in count:
		var a := i * 2
		var b := ((i + 1) % count) * 2
		indices.append_array([a, a + 1, b, a + 1, b + 1, b])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	var ring := ArrayMesh.new()
	ring.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.58, 0.42, 0.29)   # matched to the light checker dirt
	ring.surface_set_material(0, mat)
	return ring