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

var materialized := false   # the sign does not exist until main calls materialize()


## Boot: inert -- the scene freezes the body so it never falls pre-materialize.
func _ready() -> void:
	freeze = true


## Called by main AFTER generation + replay: stored pose or fossil spot; freeze iff buried.
func materialize(terrain: VoxelTerrain) -> void:
	if materialized:
		return
	materialized = true
	var stored := GameState.read_key("sign")
	if not stored.is_empty():
		var pos: Array = stored["pos"]
		var quat: Array = stored["quat"]
		global_position = Vector3(pos[0], pos[1], pos[2])
		global_basis = Basis(Quaternion(quat[0], quat[1], quat[2], quat[3]))
	else:
		rotation_degrees = FACE_UP_ROTATION
	_normalize_mesh()
	_build_collision()
	freeze = _intersects_solid(terrain)
	DirtBus.dirt_dug.connect(_on_dirt_dug)
	if freeze:
		print("stop sign: buried again at %s. it waits." % global_position)
	else:
		print("stop sign: free from the start. it says STOP. nothing stops.")


## Save on reveal and on tree exit; the pose lives under GameState's "sign" key.
func _save_state() -> void:
	var q := global_basis.get_rotation_quaternion()
	var p := global_position
	GameState.write_key("sign", {
		"pos": [p.x, p.y, p.z],
		"quat": [q.x, q.y, q.z, q.w],
	})


## Final pose on quit -- last known position wins at next boot.
func _exit_tree() -> void:
	if materialized:
		_save_state()


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
	_save_state()
	print("stop sign: revealed. it says STOP. nothing stops.")


## True if any cell the sign's world AABB overlaps is solid -- it is buried.
func _intersects_solid(terrain: VoxelTerrain) -> bool:
	var vt := terrain.get_voxel_tool()
	vt.channel = VoxelBuffer.CHANNEL_TYPE
	var aabb := _world_aabb()
	for x in range(floori(aabb.position.x), floori(aabb.end.x) + 1):
		for y in range(floori(aabb.position.y), floori(aabb.end.y) + 1):
			for z in range(floori(aabb.position.z), floori(aabb.end.z) + 1):
				if vt.get_voxel(Vector3i(x, y, z)) != TYPE_AIR:
					return true
	return false


## Conservative world box: the mesh AABB's 8 corners through its global transform.
func _world_aabb() -> AABB:
	var aabb := _mesh.get_aabb()
	var xf := _mesh.global_transform
	var mn := Vector3.INF
	var mx := -Vector3.INF
	for i in 8:
		var corner := Vector3(
			aabb.position.x + (aabb.size.x if i & 1 else 0.0),
			aabb.position.y + (aabb.size.y if i & 2 else 0.0),
			aabb.position.z + (aabb.size.z if i & 4 else 0.0))
		var w := xf * corner
		mn = mn.min(w)
		mx = mx.max(w)
	return AABB(mn, mx - mn)


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
