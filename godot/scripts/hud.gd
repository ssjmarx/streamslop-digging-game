## HUD -- the top-right readout stack (GDD §11): DIRT, $, DEPTH, FPS.
## Labels read live: depth from the player node, the rest from GameState.
## The bottom-center depth meter is retired (2026-10-19).
extends CanvasLayer

@onready var depth_label: Label = $DepthLabel
@onready var dirt_label: Label = $DirtCounter
@onready var money_label: Label = $MoneyLabel
@onready var fps_label: Label = $FpsLabel


## Per frame: DEPTH from the player's y, the rest from GameState and the engine.
func _process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player:
		depth_label.text = "DEPTH %.1fm" % player.global_position.y
	dirt_label.text = "DIRT %d" % GameState.dirt
	money_label.text = "$ %d" % GameState.money
	fps_label.text = "FPS %d" % Engine.get_frames_per_second()


## Boot sequence label (0.0.3 ruling): "loading your hole."
func set_loading(v: bool) -> void:
	($LoadLabel as Label).visible = v
