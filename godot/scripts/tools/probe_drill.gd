## Drill probe (headless): the 1000m shaft exists only as diglog entries, so the
## generator is the proof -- with the boot pre-grow (Addendum 44) every streamed
## block is born dirt, and below-cutoff shaft cells are born pre-dug (Addendum 40).
extends SceneTree

const DiglogScript := preload("res://scripts/hole/diglog_writer.gd")
const WARMUP := 3.0
const WAIT_CAP := 30.0
const MARGIN := 20
const SHAFT_RADII := 2.0
const SAMPLES := [
	[Vector3i(0, -30, 0), true],    # above the cutoff: dirt until the visual replay carves it
	[Vector3i(3, -30, 0), true],    # ring beside the shaft, same band
	[Vector3i(5, -100, 5), true],   # the old boot-void chasm zone: must be born dirt
	[Vector3i(0, -245, 0), false],  # lazy shaft cell: born pre-dug
	[Vector3i(3, -245, 0), true],   # lazy ring beside the shaft: born dirt
]

var _terrain: VoxelTerrain
var _writer: Node
var _t := 0.0
var _phase := 0   # 0 warmup, 1 assert log+floor, 2 wait for the lazy block, 3 sample


## Build the world, log the canonical shaft, pre-grow the floor -- all before frame one, exactly the boot order the drill depends on.
func _initialize() -> void:
	var hole_dir := DirAccess.open("user://")
	if hole_dir != null:
		hole_dir.remove("hole/diglog.jsonl")
	_terrain = VoxelTerrain.new()
	var mesher := VoxelMesherBlocky.new()
	var lib := VoxelBlockyLibrary.new()
	lib.add_model(VoxelBlockyModelEmpty.new())
	lib.add_model(VoxelBlockyModelCube.new())
	lib.add_model(VoxelBlockyModelCube.new())
	lib.add_model(VoxelBlockyModelCube.new())
	lib.bake()
	mesher.library = lib
	_terrain.generator = load("res://scripts/world/dirt_checker_generator.gd").new()
	_terrain.mesher = mesher
	_terrain.max_view_distance = 256
	root.add_child(_terrain)
	var viewer := VoxelViewer.new()
	viewer.view_distance = 256
	root.add_child(viewer)
	_writer = load("res://scripts/hole/diglog_writer.gd").new()
	root.add_child(_writer)
	# the drill's exact sequence, pre-streaming: reset, append, read back, pre-grow
	_writer.reset()
	for center in DiglogScript.drill_shaft_spheres():
		_writer.append_sphere(center, SHAFT_RADII)
	var entries: Array[Dictionary] = _writer.read_entries()
	DiglogScript.ensure_diglog_depth(_terrain.generator, entries, MARGIN)
	# the boot order also hands the log to the generator (main.gd's REPLAY_CUTOFF)
	_terrain.generator.load_diglog_spheres(entries, -240.0)
	print("== drill probe: %d spheres logged, floor pre-grown to %d" % [entries.size(), _terrain.generator.depth_floor])


## Phased: warmup -> assert log+floor -> wait for the deep block -> sample -> verdict.
func _process(delta: float) -> bool:
	_t += delta
	match _phase:
		0:
			if _t < WARMUP:
				return false
			_phase = 1
			_t = 0.0
		1:
			var entries: Array[Dictionary] = _writer.read_entries()
			var floor_ok: bool = _terrain.generator.depth_floor == 1024
			if entries.size() != 334 or not floor_ok:
				print("== RESULT: FAIL -- %d/334 entries, floor %d/1024" % [entries.size(), _terrain.generator.depth_floor])
				quit(1)
				return true
			print("== log and floor verified; waiting for the lazy block to stream")
			_phase = 2
			_t = 0.0
		2:
			var box := AABB(Vector3(-16.0, -256.0, -16.0), Vector3(32.0, 240.0, 32.0))   # every sampled block, shaft column
			if _terrain.is_area_meshed(box):
				print("== sample column meshed after %.1fs" % _t)
				_phase = 3
				_t = 0.0
			elif _t >= WAIT_CAP:
				print("== RESULT: FAIL -- the sample column never meshed in %.0fs" % WAIT_CAP)
				quit(1)
				return true
		3:
			var vt := _terrain.get_voxel_tool()
			vt.channel = VoxelBuffer.CHANNEL_TYPE   # every read names its channel
			var all_pass := true
			for sample: Array in SAMPLES:
				var pos: Vector3i = sample[0]
				var expect_dirt: bool = sample[1]
				var v := vt.get_voxel(pos)
				var ok: bool = (v != 0) == expect_dirt
				all_pass = all_pass and ok
				print("== voxel(%d,%d,%d)=%d expect %s -> %s" % [
					pos.x, pos.y, pos.z, v, "dirt" if expect_dirt else "air", "PASS" if ok else "FAIL"])
			print("== RESULT: %s" % ("PASS -- the shaft is log-born: dirt everywhere, carved only below the cutoff" if all_pass else "FAIL"))
			quit(0 if all_pass else 1)
			return true
	return false