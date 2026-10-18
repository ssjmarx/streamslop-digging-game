## The stop sign: a physics prop buried face-up 10m under spawn (ruling
## 2026-10-17), frozen like a fossil until dug free (the §6f pattern, early),
## then knockable forever by dig.gd's ray. Says STOP. Stops nothing.
extends RigidBody3D

# -- Config ------

const FACE_UP_ROTATION := Vector3(-90.0, 0.0, 0.0)   # the model faces +Z; -90 about X aims it at the sky
const TYPE_AIR := 0   # TYPE-channel value of empty (library index 0 in main.tscn)

@export_group("Stop Sign")
## Meters, post-to-octagon-top: normalized from the OBJ's AABB.
@export var target_height := 2.4
## dirt_dug events within this range trigger a voxel probe.
@export var reveal_check_radius := 3.0
## Meters above the sign we sample for open air.
@export var face_probe_up := 1.6

@onready var _mesh: MeshInstance3D = $Mesh


## Boot: face-up, freeze, normalize the mesh, box collider from the AABB, arm the reveal gate.
func _ready() -> void:
	rotation_degrees = FACE_UP_ROTATION
	freeze = true
	_normalize_mesh()
	_build_collision()
	DirtBus.dirt_dug.connect(_on_dirt_dug)


## O(1) near-last-erase gate: only digs near the sign trigger a voxel probe.
func _on_dirt_dug(_amount: int, voxel_pos: Vector3i, _depth: float, _by_peer: int) -> void:
	if not freeze:
		return
	if Vector3(voxel_pos).distance_to(global_position) > reveal_check_radius:
		return
	_check_reveal()


## Unfreeze once the column above the face is open air -- the dirt let go.
func _check_reveal() -> void:
	var terrain := get_tree().get_first_node_in_group("terrain") as VoxelTerrain
	if terrain == null:
		return
	var vt := terrain.get_voxel_tool()
	vt.channel = VoxelBuffer.CHANNEL_TYPE   # every read names its channel (dev_log #1)
	var probe_center := global_position + Vector3(0.0, face_probe_up, 0.0)
	for offset in [Vector3.ZERO, Vector3(0.8, 0, 0), Vector3(-0.8, 0, 0), Vector3(0, 0, 0.8), Vector3(0, 0, -0.8)]:
		if vt.get_voxel(_floor_voxel(probe_center + offset)) != TYPE_AIR:
			return
	freeze = false
	print("stop sign: revealed. it says STOP. nothing stops.")


## OBJ props arrive at arbitrary export scale: normalize the mesh to life size.
func _normalize_mesh() -> void:
	var aabb := _mesh.get_aabb()
	if aabb.size.y > 0.001:
		_mesh.scale = Vector3.ONE * (target_height / aabb.size.y)


## One box from the scaled AABB, in body space; slop physics -- it is a sign.
func _build_collision() -> void:
	var aabb := _mesh.get_aabb()
	var shape := BoxShape3D.new()
	shape.size = aabb.size * _mesh.scale * 0.9
	var collider := CollisionShape3D.new()
	collider.shape = shape
	collider.position = aabb.get_center() * _mesh.scale
	add_child(collider)


## Floor to the voxel grid for TYPE-channel reads.
func _floor_voxel(p: Vector3) -> Vector3i:
	return Vector3i(floori(p.x), floori(p.y), floori(p.z))
