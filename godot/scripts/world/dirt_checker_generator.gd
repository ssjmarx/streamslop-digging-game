## Two-tone checkerboard dirt -- the DIRT motion aid. The world is a
## WORLD_RADIUS disc centered on spawn, START_DEPTH thick, floor growing
## as she digs (ensure_depth): no bedrock, de-facto infinite depth.
extends VoxelGeneratorScript

# -- Config ------

const TYPE_DIRT_LIGHT := 1
const TYPE_DIRT_DARK := 2
const CHECKER_SIZE := 8
const BLOCK_SIZE := 16
const WORLD_RADIUS := 50   # world-limit ruling: dirt disc at spawn, void beyond
const START_DEPTH := 20.0   # ruling: the disc starts 20m thick; the floor grows as she digs

# -- State ------

var depth_floor := START_DEPTH   # meters of dirt below the surface; grows, never caps


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
			if Vector2(wx, wz).length() > WORLD_RADIUS:
				continue   # beyond the spawn disc: void
			var parity := posmod(
				floori(wx / float(CHECKER_SIZE)) + floori(wz / float(CHECKER_SIZE)), 2)
			var value := TYPE_DIRT_LIGHT if parity == 0 else TYPE_DIRT_DARK
			for y in BLOCK_SIZE:
				var wy := origin_in_voxels.y + y
				if wy < 0 and wy >= lowest:
					out_buffer.set_voxel(value, x, y, z, VoxelBuffer.CHANNEL_TYPE)


## Grows the floor as she approaches it; emit_changed re-generates affected blocks.
func ensure_depth(minimum_depth: float) -> void:
	if minimum_depth > depth_floor:
		depth_floor = minimum_depth
		emit_changed()
