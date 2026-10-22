## One-shot streaming probe for the fill-skip and drill-stall hunt (2026-10-19):
## boots the game, seeds a 1000m diglog, runs fill + drill, and prints mesh /
## data / read-back residency at depth boxes after each pass (headless).
extends SceneTree

const PROBE_DEPTHS := [16, 100, 240, 500, 900]


## Boot: run the probe once the tree exists.
func _initialize() -> void:
	_run()


## Boot the real scene, seed the log, and sample residency at each depth.
func _run() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	await process_frame
	await process_frame
	var main := current_scene
	var terrain: VoxelTerrain = main.get_node("Hole")
	var diglog: Node = main.get_node("Diglog")
	var kiosk: Node = main.get_node("Kiosk")
	print("PROBE: get_block_data available = ", ClassDB.class_has_method("VoxelTerrain", "get_block_data"))
	await _wait_boot(main)
	print("PROBE: boot done")
	var entries: Array[Dictionary] = diglog.read_entries()
	print("PROBE: diglog entries at boot = ", entries.size())
	if entries.size() < 900:
		for y in range(-1, -1000, -1):
			diglog.append_sphere(Vector3(0.0, float(y), 0.0), 2.0)
		main.reload_hole()
		await _wait_boot(main)
		print("PROBE: 1000m diglog seeded and re-booted")
	_check(terrain, "post-boot")
	kiosk.begin_debug_fill()
	await _wait_pour(kiosk)
	print("PROBE: fill done")
	_check(terrain, "post-fill")
	main.dig_debug_hole()
	var t0 := Time.get_ticks_msec()
	while main._drill_active and Time.get_ticks_msec() - t0 < 30000:
		await process_frame
	print("PROBE: drill %s after %.1fs" % ["STILL ACTIVE" if main._drill_active else "finished", float(Time.get_ticks_msec() - t0) / 1000.0])
	_check(terrain, "post-drill")
	print("PROBE: complete")
	quit(0)


## Wait out the boot loader (sequence_active false), with a hard 20s guard.
func _wait_boot(main: Node) -> void:
	var t0 := Time.get_ticks_msec()
	while main._sequence_active and Time.get_ticks_msec() - t0 < 20000:
		await process_frame
	await create_timer(1.0).timeout


## Wait out the pour, with a hard 15s guard.
func _wait_pour(kiosk: Node) -> void:
	var t0 := Time.get_ticks_msec()
	while kiosk._pouring and Time.get_ticks_msec() - t0 < 15000:
		await process_frame


## Mesh / data / read-back residency at five depths, for one labeled pass.
func _check(terrain: VoxelTerrain, label: String) -> void:
	for depth in PROBE_DEPTHS:
		var cell := Vector3i(0, -depth, 0)
		var center := Vector3(0.5, -float(depth), 0.5)
		var area := AABB(center - Vector3(8, 8, 8), Vector3(16, 16, 16))
		var block_pos: Vector3i = terrain.voxel_to_data_block(Vector3i(0, -depth + 8, 0))
		var has_data := terrain.get_block_data(block_pos) != null
		var buffer := VoxelBuffer.new()
		buffer.create(16, 16, 16)
		terrain.generator._generate_block(buffer, block_pos * 16, 0)
		terrain.try_set_block_data(block_pos, buffer)
		var read_back: int = terrain.get_voxel(Vector3i(0, -depth + 8, 0))
		print("PROBE %s @ -%dm: meshed=%s data=%s read_back=%s" % [
			label, depth, terrain.is_area_meshed(area), has_data, read_back])
	print("PROBE: ---", label, " checks done ---")