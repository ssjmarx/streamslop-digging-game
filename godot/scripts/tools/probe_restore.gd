## Restore probe (headless): dig five spheres at known spots through the real
## rule, sell through the real kiosk, and require the world to come back
## voxel-exact -- carved cells solid again, controls untouched, diglog GONE.
extends SceneTree

const SETTLE_FRAMES := 1200   # boot sequence + loading, before digging
const POLL_PHYSICS_FRAMES := 1500   # a pour runs ~6.5s on physics ticks; 25s margin
const SPOT_RADIUS := 1.3   # the toy shovel's width: tiers widen, never deepen
const CARVE_SPOTS := [Vector3(10, -2, 10), Vector3(-15, -3, 20), Vector3(30, -5, -10), Vector3(5, -8, 30), Vector3(-30, -4, -30)]
const CONTROL_SPOTS := [Vector3(44, -3, 0), Vector3(0, -6, -45), Vector3(20, -2, 20), Vector3(-10, -7, 40), Vector3(-44, -2, -4)]

var _kiosk: Node
var _diglog: Node


## Boot: run once the tree exists.
func _initialize() -> void:
	_run()


## Boot the scene, dig the spots, sell, and verify the pristine revert.
func _run() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	for i in SETTLE_FRAMES:
		await process_frame
	_kiosk = get_first_node_in_group("kiosk")
	_diglog = get_first_node_in_group("diglog")
	var state = root.get_node("GameState")
	var terrain := get_first_node_in_group("terrain") as VoxelTerrain
	var vt := terrain.get_voxel_tool()
	vt.channel = VoxelBuffer.CHANNEL_TYPE   # every read and write names its channel
	var aim: GDScript = load("res://scripts/player/aim.gd")   # lazy: aim.gd names autoloads, unresolvable at --script load time
	var carved: Array[Vector3i] = []
	for spot: Vector3 in CARVE_SPOTS:
		var cells: Array[Vector3i] = aim.cells_in_sphere(vt, spot, SPOT_RADIUS)
		for cell in cells:
			vt.set_voxel(cell, 0)
			carved.append(cell)
		_bus().dirt_dug.emit(cells.size(), Vector3i(int(spot.x), int(spot.y), int(spot.z)), spot.y, 1)
	for spot: Vector3 in CONTROL_SPOTS:
		var c := Vector3i(int(spot.x), int(spot.y), int(spot.z))
		if vt.get_voxel(c) == 0:
			_verdict("control spot %s was not solid before the sale" % str(c))
			return
	if carved.is_empty():
		_verdict("no cells carved -- the spots were not on dirt")
		return
	if state.dirt <= 0:
		_verdict("dirt did not accrue over the bus")
		return
	print("== dug %d cells across %d spots; dirt=%d; selling" % [carved.size(), CARVE_SPOTS.size(), state.dirt])
	_kiosk._begin_sale()
	for i in POLL_PHYSICS_FRAMES:
		await physics_frame
		if not _kiosk._pouring:
			break
	if _kiosk._pouring:
		_verdict("the pour never ended")
		return
	for i in 10:
		await process_frame   # let the pour's last writes settle
	var missing := 0
	for cell in carved:
		if vt.get_voxel(cell) == 0:
			missing += 1
	var controls_gone := 0
	for spot: Vector3 in CONTROL_SPOTS:
		if vt.get_voxel(Vector3i(int(spot.x), int(spot.y), int(spot.z))) == 0:
			controls_gone += 1
	var log_gone: bool = not FileAccess.file_exists("user://hole/diglog.jsonl")
	var entries: Array[Dictionary] = _diglog.read_entries()
	print("== after sale: %d/%d carved cells restored, %d controls lost, log gone=%s, entries=%d" % [
		carved.size() - missing, carved.size(), controls_gone, log_gone, entries.size()])
	var ok: bool = missing == 0 and controls_gone == 0 and log_gone and entries.is_empty()
	_verdict("" if ok else "restore mismatch (missing=%d, controls_gone=%d, log_gone=%s)" % [missing, controls_gone, log_gone])


## The bus by runtime lookup: autoload names don't compile at --script load time.
func _bus() -> Node:
	return root.get_node("DirtBus")


## Print the verdict and exit.
func _verdict(fail: String) -> void:
	print("== RESULT: %s" % ("PASS -- the sale restores the hole voxel-exact and the log is gone" if fail == "" else "FAIL -- " + fail))
	quit(0 if fail == "" else 1)