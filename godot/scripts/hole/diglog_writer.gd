## The diglog -- the save file is the hole's entire history (GDD App B): every
## dirt_dug appends {"p":[x,y,z],"r":radius} to user://hole/diglog.jsonl. 0.0.2
## is the writer only; replay (0.0.3) re-derives cells via aim.targeted_voxels' rule.
extends Node

# -- Config ------

const DIGLOG_PATH := "user://hole/diglog.jsonl"

# -- State ------

var _file: FileAccess


## Boot: open the session-long append handle; create the hole folder on first run.
func _ready() -> void:
	DirAccess.open("user://").make_dir_recursive("hole")
	_file = FileAccess.open(DIGLOG_PATH, FileAccess.READ_WRITE)
	if _file == null:
		_file = FileAccess.open(DIGLOG_PATH, FileAccess.WRITE)   # a fresh hole's first line
	if _file != null:
		_file.seek_end()
	DirtBus.dirt_dug.connect(_on_dirt_dug)


## Append one line per sphere; radius read at handler time (synchronous signal = dig-time tier).
func _on_dirt_dug(_amount: int, voxel_pos: Vector3i, _depth: float, _by_peer: int) -> void:
	if _file == null:
		return
	_file.store_line(JSON.stringify({
		"p": [voxel_pos.x, voxel_pos.y, voxel_pos.z],
		"r": GameState.dig_radius(),
	}))
	_file.flush()
