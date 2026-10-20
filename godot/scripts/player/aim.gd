## aim.gd -- the sight. One ray, head origin + camera direction, shared by the
## swing and the instruments: a Kenney crosshair billboard at the hit (#15 in
## range, #16 out) plus a blue seam-glow over voxels the current shovel would take.
extends Node3D

# -- Config (tunables are exports -- GDD §13) ------

@export_group("Aim")
## How far the diagnostic ray reaches: the crosshair may point past the verb.
@export var diagnostic_range := 60.0
## Crosshair world size in meters at the hit point. Live dial.
@export var crosshair_size := 0.35:
	set(value):
		crosshair_size = value
		if _crosshair != null:
			_crosshair.pixel_size = crosshair_size / TEX_SIZE_PX
## Meters the crosshair floats off the surface (z-fight guard).
@export var crosshair_offset := 0.05
## Faint blue for the dig-preview seams. Live dial.
@export var glow_color := Color(0.3, 0.55, 1.0, 0.55):
	set(value):
		glow_color = value
		if _glow_material != null:
			_glow_material.albedo_color = value

const TEX_IN_RANGE := "res://assets/ui/kenney/crosshair-015.png"
const TEX_OUT_RANGE := "res://assets/ui/kenney/crosshair-016.png"
const TEX_SIZE_PX := 64.0
const PREVIEW_BUDGET := 128   # instance cap: ergonomic spheres top out near 52 cells
const half_cell := Vector3(0.5, 0.5, 0.5)   # a voxel cell's center offset from its integer corner
const TYPE_AIR := 0
const TYPE_BEDROCK := 3   # the rim wall: undiggable (must match dirt_checker_generator)

# -- State ------

var swing_range := 10.0   # dig.gd injects its law const; the sight never owns the number
var body: Node   # the player controller; dig.gd injects us
var _last := {}   # last authoritative query; empty on a clean miss
var _hovered: Object = null   # the clickable under the sight; null on a clean miss
var _tex_in: Texture2D
var _tex_out: Texture2D
var _glow_material: StandardMaterial3D
var _preview_mm: MultiMesh

@onready var _crosshair: Sprite3D = $Crosshair
@onready var _preview: MultiMeshInstance3D = $Preview


## Boot: cache textures, size the crosshair, build the seam-glow line mesh.
func _ready() -> void:
	_preview.top_level = true   # instance transforms are world-space; parent rides the player
	_tex_in = load(TEX_IN_RANGE)
	_tex_out = load(TEX_OUT_RANGE)
	_crosshair.pixel_size = crosshair_size / TEX_SIZE_PX
	_crosshair.texture = _tex_out
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _build_edge_mesh()
	mm.instance_count = PREVIEW_BUDGET
	mm.visible_instance_count = 0
	_preview.multimesh = mm
	_preview_mm = mm


## Per physics frame: run the diagnostic ray, park the crosshair, glow the sphere, hover the shop.
func _physics_process(_delta: float) -> void:
	_last = swing_query(diagnostic_range)
	_update_crosshair()
	_update_preview()
	_update_hover()


## The diegetic cursor's hover: the interactable under the sight glows while in range; unglow on leave.
func _update_hover() -> void:
	var target: Object = null
	if not _last.is_empty() and _last.distance <= swing_range and _last.collider.has_method("set_hover"):
		target = _last.collider
	if target == _hovered:
		return
	if _hovered != null:
		_hovered.set_hover(false)
	_hovered = target
	if _hovered != null:
		_hovered.set_hover(true)


## The one aim ray: head origin + camera direction; in shop view it is the virtual cursor's ray from the shop camera.
func swing_query(range_m: float) -> Dictionary:
	var camera := get_viewport().get_camera_3d()
	if camera == null or body == null:
		return {}
	var from: Vector3 = body.aim_origin()
	var dir: Vector3 = -camera.global_transform.basis.z
	if GameState.view_lens == "shop":
		var kiosk := get_tree().get_first_node_in_group("kiosk")
		if kiosk != null:
			var pt: Vector2 = kiosk.cursor_point()
			from = camera.project_ray_origin(pt)
			dir = camera.project_ray_normal(pt)
	var query := PhysicsRayQueryParameters3D.create(from, from + dir * range_m)
	query.exclude = [body.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return {}
	return {
		"position": hit.position,
		"normal": hit.normal,
		"distance": from.distance_to(hit.position),
		"collider": hit.collider,
		"radius": (get_node_or_null("/root/GameState") as Node).dig_radius(),   # width defined HERE, once; runtime lookup so -s probes compile
	}


## The one rule, static so the replayer derives exactly what the sight erases.
static func cells_in_sphere(vt: VoxelTool, center: Vector3, radius: float) -> Array[Vector3i]:
	var cell := Vector3i(floori(center.x), floori(center.y), floori(center.z))
	var out: Array[Vector3i] = []
	var reach := ceili(radius)
	for x in range(cell.x - reach, cell.x + reach + 1):
		for y in range(cell.y - reach, cell.y + reach + 1):
			for z in range(cell.z - reach, cell.z + reach + 1):
				if out.size() >= PREVIEW_BUDGET:
					return out   # budget cap: ergonomic spheres top out near 52 cells
				var cell_center := Vector3(x + 0.5, y + 0.5, z + 0.5)
				if cell_center.distance_to(center) > radius:
					continue   # outside the strike sphere
				var v: int = vt.get_voxel(Vector3i(x, y, z))
				if v == TYPE_AIR or v == TYPE_BEDROCK:
					continue   # air: nothing to take; bedrock: the rim wall refuses
				out.append(Vector3i(x, y, z))
	return out


## Swing-time targeting: the sight's terrain through the shared static rule.
func targeted_voxels(center: Vector3, radius: float) -> Array[Vector3i]:
	var terrain := _find_terrain()
	if terrain == null:
		return []
	var vt := terrain.get_voxel_tool()
	vt.channel = VoxelBuffer.CHANNEL_TYPE   # every read names its channel
	return cells_in_sphere(vt, center, radius)


## Crosshair: #15 in swing range, #16 otherwise; parks at the ray end on a miss; hidden during the pour.
func _update_crosshair() -> void:
	if GameState.view_lens == "pour":
		_crosshair.visible = false
		return
	var in_range: bool = not _last.is_empty() and _last.distance <= swing_range
	_crosshair.texture = _tex_in if in_range else _tex_out
	if _last.is_empty():
		var camera := get_viewport().get_camera_3d()
		var dir := -camera.global_transform.basis.z
		_crosshair.global_position = body.aim_origin() + dir * diagnostic_range
	else:
		_crosshair.global_position = _last.position + _last.normal * crosshair_offset
	_crosshair.visible = true


## Glow: live, per frame, exactly the targeting array; hidden during the pour with the crosshair.
func _update_preview() -> void:
	if GameState.view_lens == "pour":
		_preview.visible = false
		return
	var in_range: bool = not _last.is_empty() and _last.distance <= swing_range
	_preview.visible = in_range
	if not in_range:
		return
	var count := 0
	for cell in targeted_voxels(_last.position, _last.radius):
		_preview_mm.set_instance_transform(count, Transform3D(Basis.IDENTITY, Vector3(cell) + half_cell))
		count += 1
	_preview_mm.visible_instance_count = count


## The terrain is found by group, not by owner -- this node outlives scenes.
func _find_terrain() -> VoxelTerrain:
	return get_tree().get_first_node_in_group("terrain") as VoxelTerrain


## A unit cube's 12 edges as a line mesh, inflated 0.001 so seams never z-fight.
func _build_edge_mesh() -> ArrayMesh:
	var lo := -0.5005
	var hi := 0.5005
	var corners := [
		Vector3(lo, lo, lo), Vector3(hi, lo, lo), Vector3(hi, lo, hi), Vector3(lo, lo, hi),
		Vector3(lo, hi, lo), Vector3(hi, hi, lo), Vector3(hi, hi, hi), Vector3(lo, hi, hi),
	]
	var edges := [[0, 1], [1, 2], [2, 3], [3, 0], [4, 5], [5, 6], [6, 7], [7, 4], [0, 4], [1, 5], [2, 6], [3, 7]]
	var verts := PackedVector3Array()
	for edge in edges:
		verts.append(corners[edge[0]])
		verts.append(corners[edge[1]])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	_glow_material = StandardMaterial3D.new()
	_glow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_glow_material.albedo_color = glow_color
	mesh.surface_set_material(0, _glow_material)
	return mesh
