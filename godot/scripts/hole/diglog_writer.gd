## The diglog -- the save file is the hole's entire history (GDD App B): float
## centers + radii, re-derived through the sight's rule on boot; selling wipes
## it. Deep holes materialize lazily: the generator consults the log as blocks stream.
extends Node

signal appended(center: Vector3, radius: float)
signal wiped

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
		_file = FileAccess.open(DIGLOG_PATH, FileAccess.WRITE)   # a fresh hole's first line (lazy: a wiped log stays gone until a dig lands)
	if _file == null:
		return
	_file.store_line(JSON.stringify({
		"c": [center.x, center.y, center.z],
		"r": radius,
	}))
	_file.flush()
	appended.emit(center, radius)


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


## The truth, after the theater (§6c): close the handle and delete the file -- the hole un-happens; the next dig lazily reopens, so a wiped log stays GONE (the 0.0.5 exit test) while post-sale digs still log (Addendum 46).
func wipe() -> void:
	if _file != null:
		_file.close()
		_file = null
	var dir := DirAccess.open("user://hole")
	if dir != null and dir.file_exists("diglog.jsonl"):
		dir.remove("diglog.jsonl")
		wiped.emit()
		print("diglog: wiped -- the hole is pristine again")


## The drill's re-arm (Addendum 44): truncate and reopen the append handle in the same call -- the sale never appends after wiping, the drill does.
func reset() -> void:
	if _file != null:
		_file.close()
	_file = FileAccess.open(DIGLOG_PATH, FileAccess.WRITE)   # WRITE mode truncates
	if _file != null:
		_file.seek_end()
	wiped.emit()
	print("diglog: reset -- the next append starts a fresh hole")


## The drill's canonical shaft (Addendum 44): every third cell row from the surface to -1000 on the (0.5, *, 0.5) axis -- pure log data, the exact set the old carve wrote. Static so main and the probe log the identical set.
static func drill_shaft_spheres() -> Array[Vector3]:
	var out: Array[Vector3] = []
	for yy in range(0, -1001, -3):
		out.append(Vector3(0.5, float(yy) + 0.5, 0.5))
	return out


## The boot pre-grow (Addendum 44): the floor learns the log's full depth BEFORE any block streams -- a block generated below the floor is born air, and the boot viewer reaches 256m down (the deep boot-void chasm). Static for the probe; an empty log keeps START_DEPTH, exactly a fresh hole.
static func ensure_diglog_depth(generator, entries: Array[Dictionary], margin: int) -> bool:
	var deepest := 0.0
	for entry in entries:
		deepest = maxf(deepest, -(entry.c as Vector3).y)
	if deepest <= 0.0:
		return false
	return generator.ensure_depth(deepest + float(margin))
