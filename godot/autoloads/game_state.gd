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
	{"name": "Snow Shovel", "short": "snow", "radius": 0.0, "cost": 2000},
]

signal shovel_changed

# -- State ------

var dirt := 0
var money := 0
var shovel_tier := 0          # the EQUIPPED shovel; snow (the last rung) digs nothing
var shovel_owned := 0         # the highest owned LADDER rung (0-3); snow is tracked below
var snow_owned := false       # the scam: purchasable anytime, digs nothing
var best_depth := 0.0
var stopwatch_owned := false   # the meta item, $600 once (GDD §6e); runs forever after
var stopwatch_start_frame := 0   # physics frames at control-gain; the HUD reads the delta
var surrender_declined := 0   # hidden. GDD §9. surfaced nowhere.

var wardrobe := {}            # the player's kit; schema lives in player/wardrobe.gd
var view_lens := ""           # the lens holding the world's inputs ("" = free); dig.gd stands down

var _sign := {}               # the stop sign's pose, under the "sign" key
var _dirty := false
var _flush_at_msec := 0


## Boot: read state.json (compat: the legacy file held only the sign's pose).
func _ready() -> void:
	_load()
	DirtBus.dirt_dug.connect(_on_dirt_dug)
	DirtBus.dirt_sold.connect(_on_dirt_sold)


## True while a lens (wardrobe, shop, pour) owns the world's inputs.
func inputs_held() -> bool:
	return view_lens != ""


## Width of the current dig sphere (GDD §3): tiers change width, never swing rate.
func dig_radius() -> float:
	return SHOVELS[shovel_tier]["radius"]


## Dirt and depth arrive over the bus; the file learns them debounced.
func _on_dirt_dug(amount: int, _voxel_pos: Vector3i, depth: float, _by_peer: int) -> void:
	dirt += amount
	best_depth = minf(best_depth, depth)
	touch()


## The sale collapses carried dirt into money at the kiosk (1 dirt = $1, GDD §3).
func _on_dirt_sold(_amount: int, price: int, _by_peer: int) -> void:
	money += price
	dirt = 0
	touch()


## The stopwatch law (§6e): the run starts at control-gain; the pour's end calls this again for the sell's silent zero.
func stopwatch_reset() -> void:
	stopwatch_start_frame = Engine.get_physics_frames()


## Ladder purchase: claim rung `tier` and equip it. Money validated by the caller.
func purchase_shovel(tier: int) -> void:
	shovel_owned = maxi(shovel_owned, tier)
	set_shovel_tier(tier)


## The scam: buyable anytime, digs nothing (ruling: price equal to the pro).
func purchase_snow() -> void:
	snow_owned = true
	set_shovel_tier(SHOVELS.size() - 1)


## Equip any owned shovel; fires the held-viewmodel swap.
func set_shovel_tier(tier: int) -> void:
	shovel_tier = clampi(tier, 0, SHOVELS.size() - 1)
	touch()
	shovel_changed.emit()


## Debug only (restored 2026-10-19): cycle the whole list incl. snow, ownership ignored -- the kiosk is the player path, this is the wrench.
func cycle_shovel_tier(dir: int) -> void:
	set_shovel_tier(wrapi(shovel_tier + dir, 0, SHOVELS.size()))


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
			"shovel_owned": shovel_owned, "snow_owned": snow_owned,
			"best_depth": best_depth, "stopwatch_owned": stopwatch_owned},
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
	shovel_owned = clampi(int(state.get("shovel_owned", 0)), 0, 3)
	snow_owned = bool(state.get("snow_owned", false))
	best_depth = float(state.get("best_depth", 0.0))
	stopwatch_owned = bool(state.get("stopwatch_owned", false))
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
