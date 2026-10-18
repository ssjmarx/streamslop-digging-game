## Voxel-identical probe (MEMORY exit test): dig K spheres through the shared
## rule + real writer, re-derive on a fresh world, require exact cell sets.
## (Floor growth on replay is probe_depth_floor's job; all spheres sit above -20.)
extends SceneTree

const AimScript := preload("res://scripts/player/aim.gd")

const WARMUP := 3.0
const SETTLE := 4.0
const K := 40
const TIER_RADII := [1.3, 1.75, 2.3]

var _terrain: VoxelTerrain
var _terrain2: VoxelTerrain
var _writer: Node
var _t := 0.0
var _phase := 0   # 0 warmup, 1 dig, 2 settle, 3 replay, 4 settle2, 5 verify
var _dug: Array[Vector3i] = []
var _derived: Array[Vector3i] = []
var _entries: Array[Dictionary] = []


## Build two worlds + the writer; wipe the log for one-session semantics.
func _initialize() -> void:
	# one-session semantics: the real file is append-only history, so the probe starts clean
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
	print("== replay probe: digging %d spheres through the shared rule + writer" % K)


## Phased: warmup -> dig+log -> settle -> fresh world -> replay -> settle -> verdict.
func _process(delta: float) -> bool:
	_t += delta
	match _phase:
		0:
			if _t < WARMUP:
				return false
			_phase = 1
			_t = 0.0
			var vt := _terrain.get_voxel_tool()
			vt.channel = VoxelBuffer.CHANNEL_TYPE
			for i in K:
				var r: float = TIER_RADII[i % 3]
				var c := Vector3(0.5 + float(i % 3) * 0.31, -1.0 - float(i) * 0.22, 0.5 + float(i % 5) * 0.17)
				for cell in AimScript.cells_in_sphere(vt, c, r):
					vt.set_voxel(cell, 0)
					_dug.append(cell)
				_writer.append_sphere(c, r)
			print("== dug %d voxels across %d spheres; replaying on a fresh world" % [_dug.size(), K])
		1:
			if _t < SETTLE:
				return false
			_phase = 2
			_t = 0.0
			var entries: Array[Dictionary] = _writer.read_entries()
			if entries.size() != K:
				print("== RESULT: FAIL -- writer round-trip returned %d/%d entries" % [entries.size(), K])
				quit(1)
				return true
			_terrain2 = VoxelTerrain.new()
			_terrain2.generator = load("res://scripts/world/dirt_checker_generator.gd").new()
			_terrain2.mesher = _terrain.mesher   # same baked library
			_terrain2.max_view_distance = 256
			root.add_child(_terrain2)
			var viewer2 := VoxelViewer.new()
			viewer2.view_distance = 256
			root.add_child(viewer2)
			print("== fresh world up; settling before the replay derives (threaded generation)")
			_entries = entries
		2:
			if _t < SETTLE:
				return false
			_phase = 3
			_t = 0.0
			var vt2 := _terrain2.get_voxel_tool()
			vt2.channel = VoxelBuffer.CHANNEL_TYPE
			for e in _entries:
				for cell in AimScript.cells_in_sphere(vt2, e.c, e.r):
					vt2.set_voxel(cell, 0)
					_derived.append(cell)
			print("== replay derived %d voxels; settling before the verdict" % _derived.size())
		3:
			if _t < SETTLE:
				return false
			_phase = 4
			var vt2 := _terrain2.get_voxel_tool()
			vt2.channel = VoxelBuffer.CHANNEL_TYPE
			var set_a := {}
			for cell in _dug:
				set_a[cell] = true
			var set_b := {}
			for cell in _derived:
				set_b[cell] = true
			var missing := 0
			for cell in _dug:
				if not set_b.has(cell) or vt2.get_voxel(cell) != 0:
					missing += 1
			var extra: int = set_b.size() - (set_a.size() - missing)
			var ok: bool = missing == 0 and extra == 0 and set_a.size() == set_b.size()
			print("== session1 %d cells, replay %d cells, missing %d, extra %d" % [set_a.size(), set_b.size(), missing, extra])
			print("== RESULT: %s" % ("PASS -- the hole survives a restart, voxel-identical" if ok else "FAIL"))
			quit(0 if ok else 1)
			return true
	return false