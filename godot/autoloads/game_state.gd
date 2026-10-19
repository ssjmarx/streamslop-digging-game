## GameState -- everything persistent that is not the hole itself: dirt, money,
## tier, best depth, the wardrobe kit, the sign pose, and user://hole/state.json
## (graduated 0.0.4 pt3; legacy sign-only files read compat; degrade, never crash).
extends Node

const SAVE_PATH := "user://hole/state.json"
const SAVE_DEBOUNCE_SEC := 2.0   # dirt moves every swing; the flush does not

# -- Catalog ------

const SHOVELS := [
	{"name": "Plastic Toy Shovel", "short": "toy", "radius": 1.3, "cost": 0},
	{"name": "Garden Trowel", "short": "trowel", "radius": 1.7, "cost": 250},
	{"name": "Pro Shovel 3000", "short": "regular", "radius": 2.3, "cost": 2000},
	{"name": "Ergonomic Shovel", "short": "ergonomic", "radius": 2.3, "cost": 25000},
]

# -- State ------

var dirt := 0
var money := 0
var shovel_tier := 0
var best_depth := 0.0
var surrender_declined := 0   # hidden. GDD §9. surfaced nowhere.

var wardrobe := {}            # the player's kit; schema lives in player/wardrobe.gd
var wardrobe_open := false    # the O-menu holds the mouse; dig.gd stands down

var _sign := {}               # the stop sign's pose, under the "sign" key
var _dirty := false
var _flush_at_msec := 0


## Boot: read state.json (compat: the legacy file held only the sign's pose).
func _ready() -> void:
	_load()
	DirtBus.dirt_dug.connect(_on_dirt_dug)


## Width of the current dig sphere (GDD §3): tiers change width, never swing rate.
func dig_radius() -> float:
	return SHOVELS[shovel_tier]["radius"]


## Debug only (ruling 2026-10-17): step the tier by dir (-1/+1), clamped; the kiosk (0.0.4) replaces it.
func cycle_shovel_tier(dir: int) -> void:
	shovel_tier = clampi(shovel_tier + dir, 0, SHOVELS.size() - 1)
	touch()


## Dirt and depth arrive over the bus; the file learns them debounced.
func _on_dirt_dug(amount: int, _voxel_pos: Vector3i, depth: float, _by_peer: int) -> void:
	dirt += amount
	best_depth = minf(best_depth, depth)
	touch()


## The menu writes the whole kit on every change; saved immediately.
func set_wardrobe(kit: Dictionary) -> void:
	wardrobe = kit
	save_now()


## Key-scoped read for props that persist inside our file (the sign).
func read_key(key: String) -> Dictionary:
	return _sign.duplicate() if key == "sign" else {}


## Write a reserved key (the sign) and flush immediately.
func write_key(key: String, data: Dictionary) -> void:
	if key == "sign":
		_sign = data
	save_now()


## Mark dirty; the flush is debounced (SAVE_DEBOUNCE_SEC).
func touch() -> void:
	_dirty = true
	_flush_at_msec = Time.get_ticks_msec() + int(SAVE_DEBOUNCE_SEC * 1000.0)


## Debounced flush of dirty state.
func _process(_delta: float) -> void:
	if _dirty and Time.get_ticks_msec() >= _flush_at_msec:
		save_now()


## Serialize state + wardrobe + sign; the write is full and immediate.
func save_now() -> void:
	_dirty = false
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("game_state: could not write %s" % SAVE_PATH)
		return
	f.store_string(JSON.stringify({
		"state": {"dirt": dirt, "money": money, "shovel_tier": shovel_tier,
			"best_depth": best_depth},
		"wardrobe": wardrobe,
		"sign": _sign,
	}))


## Compat read: the graduated shape or the legacy sign-only file; never crash.
func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if not (parsed is Dictionary):
		return
	var data: Dictionary = parsed
	var state: Dictionary = _dict_of(data, "state")
	dirt = int(state.get("dirt", 0))
	money = int(state.get("money", 0))
	shovel_tier = clampi(int(state.get("shovel_tier", 0)), 0, SHOVELS.size() - 1)
	best_depth = float(state.get("best_depth", 0.0))
	wardrobe = _dict_of(data, "wardrobe")
	if data.has("sign") and data["sign"] is Dictionary:
		_sign = data["sign"]
	elif data.has("pos") and data.has("quat"):
		var pos: Array = data["pos"]
		var quat: Array = data["quat"]
		if pos.size() >= 3 and quat.size() >= 4:
			_sign = {"pos": pos, "quat": quat}   # legacy: the sign was the whole file


## Dictionary-typed key read; non-dicts degrade to empty.
func _dict_of(data: Dictionary, key: String) -> Dictionary:
	var value: Variant = data.get(key, {})
	return value if value is Dictionary else {}
