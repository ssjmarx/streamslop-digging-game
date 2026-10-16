## Lists every Voxel* class registered in ClassDB -- the quickest way to see
## what the pinned extension actually ships after a version bump. Run:
##   Godot --headless --path godot -s res://scripts/tools/list_voxel_classes.gd
extends SceneTree

## Print every class whose name starts with "Voxel", then quit clean.
func _init() -> void:
	for c in ClassDB.get_class_list():
		if c.begins_with("Voxel"):
			print(c)
	quit(0)
