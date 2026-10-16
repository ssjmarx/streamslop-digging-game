## Main -- boots the DIRT world: flat voxel plain at y=0, sun, sky, one guy.
## The hole is 0.0.2's problem. Terrain generator/mesher/library live as
## scene sub-resources (runtime assignment raced the scheduler once).
extends Node3D

# -- Config ------

const SUN_ROTATION_DEG := Vector3(-50.0, 30.0, 0.0)
const SPAWN_GROUND_AREA := AABB(Vector3(-2, -3, -2), Vector3(4, 4, 4))
const LOADER_FAILSAFE_SECONDS := 15.0
const DEPTH_MARGIN := 20.0   # meters of fresh dirt kept below the player
const RESCUE_DEPTH := 30.0   # falling this far below the surface trips the rescue


## Per frame: keep fresh dirt below her (depth floor) and rescue from the void.
func _physics_process(_delta: float) -> void:
	var player := $Player as CharacterBody3D
	var depth := -player.global_position.y   # positive when below the surface
	if depth > 0.0:
		($Hole as VoxelTerrain).generator.ensure_depth(depth + DEPTH_MARGIN)
	if player.global_position.y < -RESCUE_DEPTH:
		_rescue_player(player)


## Void rescue: snap to spawn, kill velocity, re-run the loading sequence.
func _rescue_player(player: CharacterBody3D) -> void:
	player.velocity = Vector3.ZERO
	player.global_position = Vector3(0.0, 0.1, 0.0)
	_wait_for_spawn_ground()


## Boot: rotate the sun, bake the library, start the loading sequence.
func _ready() -> void:
	($Sun as DirectionalLight3D).rotation_degrees = SUN_ROTATION_DEG
	# scene-loaded libraries may arrive unbaked; bake is idempotent
	var mesher := ($Hole as VoxelTerrain).mesher as VoxelMesherBlocky
	if mesher != null and mesher.library != null:
		mesher.library.bake()
	_wait_for_spawn_ground()


## Loading sequence: physics stays OFF until the spawn column is meshed.
func _wait_for_spawn_ground() -> void:
	var terrain := $Hole as VoxelTerrain
	var player := $Player
	player.set_physics_process(false)
	var waited := 0.0
	while not terrain.is_area_meshed(SPAWN_GROUND_AREA):
		await get_tree().process_frame
		waited += get_process_delta_time()
		if waited >= LOADER_FAILSAFE_SECONDS:
			push_error("loader: spawn ground never meshed after %.0fs -- releasing anyway" % waited)
			break
	print("loader: spawn ground ready after %.1fs" % waited)
	player.on_ground_ready()
