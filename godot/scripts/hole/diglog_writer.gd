## The diglog -- the save file is the hole's entire history (GDD App B): float
## centers + radii, re-derived through the sight's rule on boot. 0.0.3 MEMORY:
## the hole survives a restart, voxel-identically (probe_replay.gd is the proof).
extends Node

const DIGLOG_PATH := "user://hole/diglog.jsonl"

# -- State ------

var _file: FileAccess


## Boot: open the append handle, wipe legacy 0.0.2 floored-"p" logs (dev reset).
func _ready() -> void:
	DirAccess.open("user://").make_dir_recursive("hole")
	_file = FileAccess.open(DIGLOG_PATH, FileAccess.READ_WRITE)
	if _file != null and _is_legacy_schema():
		_file = null   # drop the handle, reopen for write = truncate
		_file = FileAccess.open(DIGLOG_PATH, FileAccess.WRITE)
		print("diglog: legacy 0.0.2 schema wiped -- the hole starts over (dev reset)")
	if _file == null:
		_file = FileAccess.open(DIGLOG_PATH, FileAccess.WRITE)   # a fresh hole's first line
	if _file != null:
		_file.seek_end()


## True if the log's first line uses the old floored "p" key (unreplayable).
func _is_legacy_schema() -> bool:
	if _file == null or _file.get_length() == 0:
		return false
	var pos := _file.get_position()
	_file.seek(0)
	var first := _file.get_line()
	_file.seek(pos)
	return first.contains("\"p\"") and not first.contains("\"c\"")


## Append one float strike center + radius; NOT the floored voxel (breaks replay).
func append_sphere(center: Vector3, radius: float) -> void:
	if _file == null:
		return
	_file.store_line(JSON.stringify({
		"c": [center.x, center.y, center.z],
		"r": radius,
	}))
	_file.flush()


## Read all entries from the diglog. Returns an array of {c: Vector3, r: float}.
func read_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	if not FileAccess.file_exists(DIGLOG_PATH):
		return entries
	var f := FileAccess.open(DIGLOG_PATH, FileAccess.READ)
	if f == null:
		return entries
	while not f.eof_reached():
		var line := f.get_line()
		if line.is_empty():
			continue
		var parsed: Variant = JSON.parse_string(line)
		if parsed is Dictionary and parsed.has("c") and parsed.has("r"):
			var c: Array = parsed["c"]
			entries.append({
				"c": Vector3(c[0], c[1], c[2]),
				"r": parsed["r"],
			})
	return entries
