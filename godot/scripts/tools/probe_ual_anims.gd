## One-off probe: how does the pinned importer actually name the UAL
## animations (strips "_Loop" suffixes, drops loop flags)? Kept as the
## reference for animation-pack swaps.
extends SceneTree

## Load the UAL glb and dump its libraries + animation names.
func _init() -> void:
	var scene: PackedScene = load("res://assets/anims/quaternius/UAL1_Standard.glb")
	if scene == null:
		print("UAL LOAD FAILED")
		quit(1)
		return
	var node := scene.instantiate()
	var ap := _find_anim_player(node)
	if ap == null:
		print("NO ANIM PLAYER; tree follows:")
		_dump(node, 0)
		quit(1)
		return
	print("LIBRARIES: ", ap.get_animation_library_list())
	var names := ap.get_animation_list()
	print("COUNT: ", names.size())
	for n in names:
		print("ANIM: '", n, "'")
	quit(0)


## First AnimationPlayer under the given node, depth-first; null when none.
func _find_anim_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var found := _find_anim_player(child)
		if found != null:
			return found
	return null


## Recursive tree dump (name + class), used when no player is found.
func _dump(node: Node, depth: int) -> void:
	print("  ".repeat(depth), node.name, " (", node.get_class(), ")")
	for child in node.get_children():
		_dump(child, depth + 1)
