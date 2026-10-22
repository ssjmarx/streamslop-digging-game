## Probes the depth-floor machinery (GDD §4: infinite dirt down): carve an edit,
## grow the floor via main.gd's surgical write_floor_blocks, and require BOTH new
## dirt AND a surviving hole. emit_changed and generator-reassign both failed probe.
extends SceneTree

const WARMUP := 3.0
const SETTLE := 4.0
const SAMPLES := [Vector3i(0, -15, 0), Vector3i(0, -25, 0), Vector3i(0, -40, 0), Vector3i(0, -55, 0), Vector3i(0, -95, 0), Vector3i(0, -105, 0), Vector3i(0, -115, 0), Vector3i(5, -3, 5)]
const CARVED := Vector3i(5, -3, 5)   # an edit that must survive regeneration (holes persist)

var _terrain: VoxelTerrain
var _gen: VoxelGeneratorScript
var _main_script: GDScript   # lazy: main.gd names autoloads, unresolvable at --script load time
var _t := 0.0
var _sampled := false
var _grew := false


## Build terrain + the real checker generator, like the game does in code.
func _initialize() -> void:
	_terrain = VoxelTerrain.new()
	var mesher := VoxelMesherBlocky.new()
	var lib := VoxelBlockyLibrary.new()
	lib.add_model(VoxelBlockyModelEmpty.new())
	lib.add_model(VoxelBlockyModelCube.new())
	lib.add_model(VoxelBlockyModelCube.new())
	lib.add_model(VoxelBlockyModelCube.new())   # index 3: the generator's rim-wall bedrock
	lib.bake()
	mesher.library = lib
	_gen = load("res://scripts/world/dirt_checker_generator.gd").new()
	_terrain.generator = _gen
	_terrain.mesher = mesher
	_terrain.max_view_distance = 256
	root.add_child(_terrain)
	var viewer := VoxelViewer.new()
	viewer.view_distance = 256
	root.add_child(viewer)
	print("== depth probe: floor starts at -20; target -100 via write_floor_blocks")


## Warm up, carve, grow 20 -> 100 surgically, settle, sample once, quit.
func _process(delta: float) -> bool:
	_t += delta
	if _sampled:
		return false
	if _t < WARMUP + SETTLE:
		return false
	if not _grew:
		_grew = true
		print("== carve at (5,-3,5), ensure_depth(100), surgical write 20 -> 100")
		var vt := _terrain.get_voxel_tool()
		vt.channel = VoxelBuffer.CHANNEL_TYPE
		vt.do_sphere(Vector3(5, -3, 5), 1.0)
		var old_floor: int = _gen.depth_floor
		_gen.ensure_depth(100.0)
		if _main_script == null:
			_main_script = load("res://scripts/main.gd")   # by warmup the autoload globals exist, so main.gd compiles
		_main_script.write_floor_blocks(_terrain, old_floor, _gen.depth_floor)
		_t = 0.0   # settle timer restarts: give the remesh its SETTLE seconds
		return false
	_sampled = true
	print("== floor now at %d; sampled after settle" % _gen.depth_floor)
	var vt := _terrain.get_voxel_tool()
	vt.channel = VoxelBuffer.CHANNEL_TYPE   # every read names its channel
	var all_pass := true
	for pos: Vector3i in SAMPLES:
		var v := vt.get_voxel(pos)
		var expect_dirt: bool = pos.y >= -_gen.depth_floor and pos != CARVED
		var ok: bool = (v != 0) == expect_dirt
		all_pass = all_pass and ok
		print("== voxel(%d,%d,%d)=%d expect %s -> %s" % [
			pos.x, pos.y, pos.z, v, "dirt" if expect_dirt else "air", "PASS" if ok else "FAIL"])
	print("== RESULT: %s" % ("PASS -- infinite down works, holes persist" if all_pass else "FAIL"))
	quit(0 if all_pass else 1)
	return true
