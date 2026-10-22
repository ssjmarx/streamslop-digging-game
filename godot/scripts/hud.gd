## HUD -- the top-right readout stack (GDD §11): DIRT, $, DEPTH, FPS.
## Labels read live: depth from the player node, the rest from GameState.
## The bottom-center depth meter is retired (2026-10-19).
extends CanvasLayer

@onready var depth_label: Label = $DepthLabel
@onready var dirt_label: Label = $DirtCounter
@onready var money_label: Label = $MoneyLabel
@onready var fps_label: Label = $FpsLabel
@onready var timer_label: Label = $TimerLabel

var _dirt_shown := 0
var _money_shown := 0
var _sale_dirt_target := 0
var _sale_money_target := 0
var _sale_dirt_rate := 0.0
var _sale_money_rate := 0.0
var _sale_until_msec := 0
var _sale_active := false


## Debug tier cycler (restored 2026-10-19): [ and ] step the equipped shovel, snow included; stands down over lenses.
func _unhandled_input(event: InputEvent) -> void:
	if GameState.inputs_held():
		return
	if event.is_action_pressed("shovel_prev"):
		GameState.cycle_shovel_tier(-1)
	elif event.is_action_pressed("shovel_next"):
		GameState.cycle_shovel_tier(1)


## The sale theater (ruling 2026-10-19): the counts lerp toward the payout over the pour's duration; the real state lands when the disk reaches the rim.
func begin_sale_display(dirt_from: int, payout: int, seconds: float) -> void:
	_dirt_shown = float(dirt_from)
	_money_shown = float(GameState.money)
	_sale_dirt_target = 0
	_sale_money_target = GameState.money + payout
	_sale_dirt_rate = absf(float(_sale_dirt_target - _dirt_shown) / maxf(seconds, 0.1))
	_sale_money_rate = absf(float(_sale_money_target - _money_shown) / maxf(seconds, 0.1))
	_sale_until_msec = Time.get_ticks_msec() + int(seconds * 1500.0)   # buffer past the disk's arrival
	_sale_active = true


## Per frame: DEPTH from the player's y; DIRT/$ lerp toward targets (linear during a sale, exponential otherwise); FPS from the engine.
func _process(_delta: float) -> void:
	var delta := get_process_delta_time()
	var target_dirt := GameState.dirt
	var target_money := GameState.money
	var landed: bool = GameState.dirt == _sale_dirt_target and GameState.money >= _sale_money_target
	if _sale_active and (landed or Time.get_ticks_msec() >= _sale_until_msec):
		_sale_active = false   # the state landed; the display is already there (or the window expired: show the truth)
	if _sale_active:
		target_dirt = _sale_dirt_target
		target_money = _sale_money_target
		_dirt_shown = move_toward(_dirt_shown, _sale_dirt_target, _sale_dirt_rate * delta)
		_money_shown = move_toward(_money_shown, _sale_money_target, _sale_money_rate * delta)
	else:
		_dirt_shown = _chase(_dirt_shown, float(target_dirt), delta)
		_money_shown = _chase(_money_shown, float(target_money), delta)
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player:
		depth_label.text = "DEPTH %.1fm" % player.global_position.y
	dirt_label.text = "DIRT %d" % int(round(_dirt_shown))
	money_label.text = "$ %d" % int(round(_money_shown))
	fps_label.text = "FPS %d" % Engine.get_frames_per_second()
	timer_label.visible = GameState.stopwatch_owned
	if GameState.stopwatch_owned:
		var total := maxi(Engine.get_physics_frames() - GameState.stopwatch_start_frame, 0)
		timer_label.text = "%02d:%02d:%03d" % [int(total / 7500.0), int(total / 125.0) % 60, total % 125]


## Exponential chase toward a display target; snaps when it is a rounding hair away.
func _chase(shown: float, target: float, delta: float) -> float:
	var out := lerpf(shown, target, 1.0 - exp(-6.0 * delta))
	if absf(out - target) < 0.5:
		return target
	return out


## Boot sequence label (0.0.3 ruling): "loading your hole."
func set_loading(v: bool) -> void:
	($LoadLabel as Label).visible = v
