## HUD -- the top-right readout stack (GDD §11): DIRT, $, DEPTH, FPS.
## Labels read live: depth from the player node, the rest from GameState.
## The bottom-center depth meter is retired (2026-10-19).
extends CanvasLayer

@onready var depth_label: Label = $DepthLabel
@onready var dirt_label: Label = $DirtCounter
@onready var money_label: Label = $MoneyLabel
@onready var fps_label: Label = $FpsLabel
@onready var timer_label: Label = $TimerLabel


## Debug tier cycler (restored 2026-10-19): [ and ] step the equipped shovel, snow included; stands down over lenses.
func _unhandled_input(event: InputEvent) -> void:
	if GameState.inputs_held():
		return
	if event.is_action_pressed("shovel_prev"):
		GameState.cycle_shovel_tier(-1)
	elif event.is_action_pressed("shovel_next"):
		GameState.cycle_shovel_tier(1)


## Per frame: DEPTH from the player's y; DIRT, $, FPS from state/engine; the stopwatch joins once owned (mm:ss:ff at 125 Hz).
func _process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player:
		depth_label.text = "DEPTH %.1fm" % player.global_position.y
	dirt_label.text = "DIRT %d" % GameState.dirt
	money_label.text = "$ %d" % GameState.money
	fps_label.text = "FPS %d" % Engine.get_frames_per_second()
	timer_label.visible = GameState.stopwatch_owned
	if GameState.stopwatch_owned:
		var total := maxi(Engine.get_physics_frames() - GameState.stopwatch_start_frame, 0)
		timer_label.text = "%02d:%02d:%03d" % [int(total / 7500.0), int(total / 125.0) % 60, total % 125]


## Boot sequence label (0.0.3 ruling): "loading your hole."
func set_loading(v: bool) -> void:
	($LoadLabel as Label).visible = v
