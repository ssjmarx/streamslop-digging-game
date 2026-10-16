## Dumps the avatar's geometry: every MeshInstance3D with mesh name, surface
## count, and per-surface material info -- ground truth for the white
## brows/lashes mystery (piece painting? character's textures missing?).
extends SceneTree

const AVATAR_SCENE := "res://assets/meshes/quaternius/superhero_female/Superhero_Female_FullBody.gltf"
const PIECES := {
	"HAIR": "res://assets/meshes/quaternius/superhero_female/Hair_Long.gltf",
	"BROWS": "res://assets/meshes/quaternius/superhero_female/Eyebrows_Female.gltf",
}


## Dump the avatar and each hair piece in turn, then quit clean.
func _initialize() -> void:
	_dump_scene("AVATAR", AVATAR_SCENE)
	for label in PIECES:
		_dump_scene(label, PIECES[label])
	quit(0)


## Load a scene, walk it, and print its mesh/skeleton/material facts.
func _dump_scene(label: String, path: String) -> void:
	var scene: PackedScene = load(path)
	if scene == null:
		print(label, ": LOAD FAILED -- ", path)
		return
	var root := scene.instantiate()
	print("== ", label, " root: ", root.name, " (", root.get_class(), ")")
	_walk(root, 1)
	root.free()


## Recursive walk: meshes with surface+material facts, skeletons with bone counts.
func _walk(node: Node, depth: int) -> void:
	var pad := "  ".repeat(depth)
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		var mesh := mesh_instance.mesh
		if mesh == null:
			print(pad, node.name, " [MeshInstance3D mesh=NULL]")
		else:
			print(pad, node.name, " [MeshInstance3D surfaces=", mesh.get_surface_count(), "]")
			for s in mesh.get_surface_count():
				_describe(pad + "  s%d stored" % s, mesh.surface_get_material(s))
				_describe(pad + "  s%d active" % s, mesh_instance.get_active_material(s))
	elif node is Skeleton3D:
		print(pad, node.name, " [Skeleton3D bones=", (node as Skeleton3D).get_bone_count(), "]")
	else:
		print(pad, node.name, " (", node.get_class(), ")")
	for child in node.get_children():
		_walk(child, depth + 1)


## One material line: name, albedo color, and the bound texture (or none).
func _describe(pad: String, mat: Material) -> void:
	if mat == null:
		print(pad, " material: NULL  <-- renders WHITE")
		return
	var std := mat as StandardMaterial3D
	var info := "'" + mat.resource_name + "'"
	if std != null:
		var tex := std.albedo_texture
		var tex_desc := "none"
		if tex != null:
			tex_desc = tex.resource_path.get_file() if tex.resource_path != "" else "(embedded)"
		info += " | albedo=%s | texture=%s" % [std.albedo_color, tex_desc]
	print(pad, " material: ", info)
