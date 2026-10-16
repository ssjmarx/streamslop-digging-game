## Streaming bisect probe: PROBE_MODE env var selects the tree (pure =
## code-built terrain, noplayer = main.tscn sans player, main = the game).
## Run: PROBE_MODE=pure|noplayer|main Godot --headless --path godot res://scenes/testing/probe_terrain.tscn
extends Node

const WARMUP_SECONDS := 6.0

var _main: Node3D
var _elapsed := 0.0
var _sampled := false
var _terrain: VoxelTerrain


## Mode select + boot: build the selected tree under this probe node.
func _ready() -> void:
	var mode := OS.get_environment("PROBE_MODE")
	print("== PROBE_MODE=", mode)
	if mode == "pure":
		_build_pure()
	elif mode == "noplayer":
		_main_without_player()
	else:
		_main = load("res://scenes/main.tscn").instantiate()
		add_child(_main)
		_terrain = _main.get_node("Hole")


## Build terrain + viewer + checker generator in code, no scene dependencies.
func _build_pure() -> void:
	_terrain = VoxelTerrain.new()
	var mesher := VoxelMesherBlocky.new()
	var lib := VoxelBlockyLibrary.new()
	var dirt := VoxelBlockyModelCube.new()
	dirt.color = Color(0.5, 0.35, 0.25)
	lib.add_model(VoxelBlockyModelEmpty.new())
	lib.add_model(dirt)
	lib.bake()
	mesher.library = lib
	var gen := VoxelGeneratorFlat.new()
	gen.height = 0.0
	gen.voxel_type = 1
	_terrain.mesher = mesher
	_terrain.generator = gen
	_terrain.max_view_distance = 256
	add_child(_terrain)
	var viewer := VoxelViewer.new()
	viewer.view_distance = 256
	add_child(viewer)
	print("== pure tree built")


## Main scene with the player freed; a pinned viewer probes streaming.
func _main_without_player() -> void:
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)
	_terrain = _main.get_node("Hole")
	var player := _main.get_node_or_null("Player")
	if player != null:
		player.queue_free()
	var viewer := VoxelViewer.new()
	viewer.view_distance = 256
	add_child(viewer)
	print("== main without player")


## Warm up, then sample voxels + stats once and quit (the streaming proof).
func _process(delta: float) -> void:
	if _sampled or _elapsed < WARMUP_SECONDS:
		_elapsed += delta
		return
	_sampled = true
	print("== has_data_block(0,0,0): ", _terrain.has_data_block(Vector3i(0, 0, 0)))
	if _terrain.generator != null and "channel" in _terrain.generator:
		print("== generator channel: ", _terrain.generator.channel,
			" (blocky mesher wants TYPE=0)")
	print("== stats: ", _terrain.get_statistics())
	var vt := _terrain.get_voxel_tool()
	vt.channel = VoxelBuffer.CHANNEL_TYPE   # always name the channel
	for pos in [Vector3i(0, 1, 0), Vector3i(0, -1, 0), Vector3i(0, -2, 0),
			Vector3i(12, -1, 0), Vector3i(-12, -1, 0),
			Vector3i(40, -1, 0), Vector3i(60, -1, 0)]:
		print("== voxel(%d,%d,%d) = %d" % [pos.x, pos.y, pos.z, vt.get_voxel(pos)])
	get_tree().quit(0)

