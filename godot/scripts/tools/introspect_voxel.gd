## Headless API probe for the pinned voxel extension (v1.7x GDExtension):
## the drift check behind "trust only the pinned version's API" (GDD §13).
## Run: Godot --headless --path godot -s res://scripts/tools/introspect_voxel.gd
extends SceneTree

# -- Config ------

# Classes the world code depends on, newest API first. Extend as needed.
const CLASSES := [
	"VoxelTerrain", "VoxelGeneratorFlat", "VoxelMesherBlocky",
	"VoxelBlockyLibrary", "VoxelBlockyModelCube", "VoxelBlockyModel",
	"VoxelViewer", "VoxelTool", "VoxelRaycastResult", "VoxelGenerator",
	"VoxelLodTerrain", "VoxelBlockyType",
]


## Scan CLASSES against ClassDB; print found/missing and their APIs.
func _init() -> void:
	var missing := 0
	for cls in CLASSES:
		if not ClassDB.class_exists(cls):
			print("MISSING: ", cls)
			missing += 1
			continue
		print("== ", cls)
		for p in ClassDB.class_get_property_list(cls):
			# storage-backed properties only: the ones scenes/code can set
			if p.usage & PROPERTY_USAGE_STORAGE:
				print("   prop ", p.name, " : ", p.type)
		for m in ClassDB.class_get_method_list(cls):
			if m.name.begins_with("_"):
				continue
			print("   func ", m.name, "(", _args(m), ")")
	quit(0 if missing == 0 else 1)


## Compact argument list for one ClassDB method entry.
func _args(m: Dictionary) -> String:
	var parts := []
	for a in m.args:
		parts.append(String(a.name))
	return ", ".join(parts)
