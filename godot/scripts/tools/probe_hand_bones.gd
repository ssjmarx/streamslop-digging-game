## Dumps the avatar rig's bone names -- ground truth for attaching held
## props (the shovel) to a hand. Run:
##   Godot --headless --path godot -s res://scripts/tools/probe_hand_bones.gd
extends SceneTree


## Load the avatar scene, print every bone name on its first skeleton, quit clean.
func _init() -> void:
	var scene: PackedScene = load("res://assets/meshes/quaternius/superhero_female/Superhero_Female_FullBody.gltf")
	if scene == null:
		print("probe: avatar scene failed to load")
		quit(1)
		return
	var node: Node = scene.instantiate()
	var skel := _find_skeleton(node)
	if skel == null:
		print("probe: no Skeleton3D under the avatar")
		node.free()
		quit(1)
		return
	print("skeleton: %s bones=%d" % [skel.name, skel.get_bone_count()])
	for i in skel.get_bone_count():
		print("  bone %d: %s" % [i, skel.get_bone_name(i)])
	node.free()
	quit(0)


## First Skeleton3D under the node, depth-first; null when none.
func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	for child in node.get_children():
		var found := _find_skeleton(child)
		if found != null:
			return found
	return null
