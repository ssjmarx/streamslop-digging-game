## Two-tone checkerboard dirt -- the DIRT motion aid. The diglog materializes
## here: streamed blocks are born pre-dug wherever the log claims spheres --
## the lazy replay (Addendum 40).
extends VoxelGeneratorScript

# -- Config ------

const TYPE_DIRT_LIGHT := 1
const TYPE_DIRT_DARK := 2
const TYPE_BEDROCK := 3   # the rim wall: undiggable, clangs, takes shovel jumps (ruling 2026-10-17)
const CHECKER_SIZE := 8
const BLOCK_SIZE := 16
const WORLD_RADIUS := 50   # world-limit ruling: dirt disc at spawn, void beyond
const START_DEPTH := 20.0   # ruling: the disc starts 20m thick; the floor grows as she digs

# -- State ------

var depth_floor := START_DEPTH   # meters of dirt below the surface; grows, never caps
var _diglog_spheres: Array = []   # {c: Vector3, r: float} -- the hole, materialized into streamed blocks
var _diglog_mutex: Mutex = Mutex.new()


## Adopt the diglog's below-cutoff spheres: streamed blocks are born pre-dug with them.
func load_diglog_spheres(entries: Array[Dictionary], cutoff: float) -> void:
	_diglog_mutex.lock()
	_diglog_spheres = []
	for entry in entries:
		if (entry.c as Vector3).y <= cutoff:
			_diglog_spheres.append(entry)
	_diglog_mutex.unlock()


## Live append (per strike): keeps the in-memory index in step with the file.
func append_diglog_sphere(center: Vector3, radius: float) -> void:
	_diglog_mutex.lock()
	_diglog_spheres.append({"c": center, "r": radius})
	_diglog_mutex.unlock()


## The sale: the hole un-happens for every block that streams afterwards.
func clear_diglog_spheres() -> void:
	_diglog_mutex.lock()
	_diglog_spheres = []
	_diglog_mutex.unlock()


## Fill the TYPE channel: checker dirt below y=0 to the depth floor; void outside the disc.
func _generate_block(out_buffer: VoxelBuffer, origin_in_voxels: Vector3i, lod: int) -> void:
	if lod != 0:
		return
	out_buffer.create(BLOCK_SIZE, BLOCK_SIZE, BLOCK_SIZE)
	var lowest := -int(depth_floor)
	if origin_in_voxels.y >= 0 or origin_in_voxels.y + BLOCK_SIZE <= lowest:
		return   # entirely above ground or entirely below the floor: air
	for x in BLOCK_SIZE:
		for z in BLOCK_SIZE:
			var wx := origin_in_voxels.x + x
			var wz := origin_in_voxels.z + z
			var radial := Vector2(wx, wz).length()
			if radial > WORLD_RADIUS:
				continue   # beyond the spawn disc: void
			var parity := posmod(
				floori(wx / float(CHECKER_SIZE)) + floori(wz / float(CHECKER_SIZE)), 2)
			var value := TYPE_DIRT_LIGHT if parity == 0 else TYPE_DIRT_DARK
			if radial > WORLD_RADIUS - 1.0:
				value = TYPE_BEDROCK   # the rim wall: undiggable black shell (ruling 2026-10-17)
			for y in BLOCK_SIZE:
				var wy := origin_in_voxels.y + y
				if wy < 0 and wy >= lowest:
					out_buffer.set_voxel(value, x, y, z, VoxelBuffer.CHANNEL_TYPE)
	if _diglog_spheres.size() > 0:
		_diglog_erase(out_buffer, origin_in_voxels)


## Erase the diglog's claimed cells from a freshly generated block (the lazy replay's strike rule).
func _diglog_erase(out_buffer: VoxelBuffer, origin_in_voxels: Vector3i) -> void:
	_diglog_mutex.lock()
	for sphere_v in _diglog_spheres:
		var c: Vector3 = sphere_v["c"]
		var radius := ceili(float(sphere_v["r"]))
		var lo_x := maxi(origin_in_voxels.x, floori(c.x) - radius)
		var hi_x := mini(origin_in_voxels.x + BLOCK_SIZE - 1, floori(c.x) + radius)
		var lo_y := maxi(origin_in_voxels.y, floori(c.y) - radius)
		var hi_y := mini(origin_in_voxels.y + BLOCK_SIZE - 1, floori(c.y) + radius)
		var lo_z := maxi(origin_in_voxels.z, floori(c.z) - radius)
		var hi_z := mini(origin_in_voxels.z + BLOCK_SIZE - 1, floori(c.z) + radius)
		if lo_x > hi_x or lo_y > hi_y or lo_z > hi_z:
			continue   # this sphere never touches the block
		for wy in range(lo_y, hi_y + 1):
			for wz in range(lo_z, hi_z + 1):
				for wx in range(lo_x, hi_x + 1):
					var lx := wx - origin_in_voxels.x
					var ly := wy - origin_in_voxels.y
					var lz := wz - origin_in_voxels.z
					if out_buffer.get_voxel(lx, ly, lz, VoxelBuffer.CHANNEL_TYPE) == 0:
						continue   # already air: the log only erases solids
					var cell_center := Vector3(wx + 0.5, wy + 0.5, wz + 0.5)
					if cell_center.distance_to(c) <= float(sphere_v["r"]):
						out_buffer.set_voxel(0, lx, ly, lz, VoxelBuffer.CHANNEL_TYPE)
	_diglog_mutex.unlock()


## Grows the floor as she approaches it, in 16m block steps; returns true when it grew (main.gd then writes the new slice -- see write_floor_blocks).
func ensure_depth(minimum_depth: float) -> bool:
	var next_floor := ceili(minimum_depth / float(BLOCK_SIZE)) * BLOCK_SIZE
	if next_floor > depth_floor:
		depth_floor = next_floor
		return true
	return false
