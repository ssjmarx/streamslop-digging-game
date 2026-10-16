## HUD -- the depth meter is the largest element; it is the score.
## DIRT scope: DEPTH (reads 0.0 at spawn -- the exit test) and DIRT.
## Both labels read live: depth from the player node, dirt from GameState.
extends CanvasLayer

@onready var depth_label: Label = $DepthMeter
@onready var dirt_label: Label = $DirtCounter


## Per frame: DEPTH from the player's y (0.0 at spawn), DIRT from GameState.
func _process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player:
		depth_label.text = "DEPTH %.1fm" % player.global_position.y
	dirt_label.text = "DIRT %d" % GameState.dirt
