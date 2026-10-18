## Main -- boots the DIRT world: flat voxel plain at y=0, sun, sky, one guy.
## The hole is 0.0.2's problem. Terrain generator/mesher/library live as
## scene sub-resources (runtime assignment raced the scheduler once).
extends Node3D

# -- Config ------

const SUN_ROTATION_DEG := Vector3(-50.0, 30.0, 0.0)
const SPAWN_GROUND_AREA := AABB(Vector3(-2, -3, -2), Vector3(4, 4, 4))
const LOADER_FAILSAFE_SECONDS := 15.0

@export_group("Depth Floor")
## Meters of fresh dirt kept below the player; the floor grows ahead of her.
@export var depth_margin := 20.0
## The rescue fires this far BELOW THE GENERATOR FLOOR, not below y=0 -- the
## absolute rule made digging past -30m impossible the moment a hole existed
## (found by playtest, 2026-10-17). Deliberate void dives still rescue.
@export var rescue_below_floor := 15.0
## Outside the disc there is no floor: falling this far below the rim rescue-picks you up.
@export var void_rescue_depth := 20.0


## Per frame: grow the floor ONLY inside the disc; rescue below the FLOOR, or fast outside it (the void).
func _physics_process(_delta: float) -> void:
	var player := $Player as CharacterBody3D
	var terrain := $Hole as VoxelTerrain
	var depth := -player.global_position.y   # positive when below the surface
	var inside_disc: bool = Vector2(player.global_position.x, player.global_position.z).length() <= float(terrain.generator.WORLD_RADIUS)
	if depth > 0.0 and inside_disc:
		var old_floor: int = terrain.generator.depth_floor
		if terrain.generator.ensure_depth(depth + depth_margin):
			write_floor_blocks(terrain, old_floor, terrain.generator.depth_floor)
	var rim_rescue: bool = not inside_disc and player.global_position.y < -void_rescue_depth
	var floor_rescue: bool = player.global_position.y < -(terrain.generator.depth_floor + rescue_below_floor)
	if rim_rescue or floor_rescue:
		_rescue_player(player)


## Surgical floor-grow: write the newly-dirtied slice as data blocks; the only grow-path that keeps holes (see probe_depth_floor.gd).
static func write_floor_blocks(terrain: VoxelTerrain, old_floor: int, new_floor: int) -> void:
	var generator := terrain.generator
	var size := 16   # the checker generator's block size; data blocks are 1:1 with these
	var radius: int = generator.WORLD_RADIUS
	var start := -ceili(float(radius) / float(size)) * size   # first block overlapping the disc
	for oy in range(-new_floor, -old_floor, size):
		for oz in range(start, radius, size):
			for ox in range(start, radius, size):
				var nearest_x := clampi(0, ox, ox + size)
				var nearest_z := clampi(0, oz, oz + size)
				if Vector2(nearest_x, nearest_z).length() > float(radius):
					continue   # block cannot touch the disc: the generator fills only air there
				var buffer := VoxelBuffer.new()
				buffer.create(size, size, size)
				generator._generate_block(buffer, Vector3i(ox, oy, oz), 0)
				if not terrain.try_set_block_data(terrain.voxel_to_data_block(Vector3i(ox, oy, oz)), buffer):
					push_warning("floor: try_set_block_data failed at %s" % Vector3i(ox, oy, oz))


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
