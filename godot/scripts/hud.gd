## HUD -- the depth meter is the largest element; it is the score.
## VERB scope: DEPTH, DIRT, and the debug SHOVEL readout ([ and ] cycle tiers).
## Labels read live: depth from the player node, dirt from GameState.
extends CanvasLayer

@onready var depth_label: Label = $DepthMeter
@onready var dirt_label: Label = $DirtCounter
@onready var shovel_label: Label = $ShovelLabel


## Debug tier cycler (ruling 2026-10-17): [ and ] step GameState's tier; the kiosk (0.0.4) replaces this.
func _unhandled_input(event: InputEvent) -> void:
	if GameState.wardrobe_open:
		return   # the O-menu owns the inputs
	if event.is_action_pressed("shovel_prev"):
		GameState.cycle_shovel_tier(-1)
	elif event.is_action_pressed("shovel_next"):
		GameState.cycle_shovel_tier(1)


## Per frame: DEPTH from the player's y (0.0 at spawn), DIRT from GameState.
func _process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player:
		depth_label.text = "DEPTH %.1fm" % player.global_position.y
	dirt_label.text = "DIRT %d" % GameState.dirt
	shovel_label.text = "SHOVEL %s" % GameState.SHOVELS[GameState.shovel_tier]["short"]


## Boot sequence label (0.0.3 ruling): "loading your hole."
func set_loading(v: bool) -> void:
	($LoadLabel as Label).visible = v
