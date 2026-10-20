## A diegetic shop clickable: a StaticBody3D whose ray hit eats the click and
## dispatches into the kiosk (Addendum 26.2 -- no whiff, no clang). Hover
## glows its meshes via the sight's cursor idiom.
extends StaticBody3D

const GLOW_COLOR := Color(0.3, 0.55, 1.0)   # the sight's seam-glow blue
const GLOW_ENERGY := 0.7

@export_group("Clickable")
## What this buys or does: "open", "sell", "buy_tier", "buy_stopwatch".
@export var action := "open"
## The shovel tier this display sells (buy_tier only).
@export var tier := 0

var _glow_meshes: Array[MeshInstance3D] = []


## Boot: mesh-glow duplicates (emission 0 = untouched), hidden hover labels, collider auto-fitted to the meshes.
func _ready() -> void:
	_collect_meshes(self)
	_fit_collision()
	for mesh_instance in _glow_meshes:
		var node_mat := mesh_instance.material_override
		mesh_instance.material_override = null   # a node override masks surface overrides (the dead trowel glow)
		for i in mesh_instance.mesh.get_surface_count():
			var mat := node_mat if node_mat is StandardMaterial3D else mesh_instance.get_active_material(i)
			if mat is StandardMaterial3D:
				var glow: StandardMaterial3D = mat.duplicate()
				glow.emission_enabled = true
				glow.emission = GLOW_COLOR
				glow.emission_energy_multiplier = 0.0
				mesh_instance.set_surface_override_material(i, glow)
	for child in get_children():
		if child is Label3D:
			child.visible = false   # labels exist for the hover, not the wall (ruling 2026-10-19)


## Auto-fit: the collider box hugs the clickable's meshes, wherever the hand placed them -- hover IS the model.
func _fit_collision() -> void:
	var box := AABB()
	var first := true
	for mesh_instance in _glow_meshes:
		var mesh_box := mesh_instance.global_transform * mesh_instance.mesh.get_aabb()
		box = mesh_box if first else box.merge(mesh_box)
		first = false
	if first:
		return   # nothing to fit under this clickable
	box = box.grow(0.05)   # a hair of forgiveness for the cursor
	for child in get_children():
		if child is CollisionShape3D:
			var shape_node := child as CollisionShape3D
			shape_node.global_position = box.get_center()
			var box_shape := BoxShape3D.new()
			box_shape.size = box.size
			shape_node.shape = box_shape
			return


## The sight's hover: light the emission and show our labels while the cursor holds us.
func set_hover(on: bool) -> void:
	for child in get_children():
		if child is Label3D:
			child.visible = on
	for mesh_instance in _glow_meshes:
		for i in mesh_instance.mesh.get_surface_count():
			var mat := mesh_instance.get_surface_override_material(i)
			if mat is StandardMaterial3D and mat.emission_enabled:
				mat.emission_energy_multiplier = GLOW_ENERGY if on else 0.0


## dig.gd dispatches here on a hit: forward to the kiosk (our ancestor group).
func interact() -> void:
	var kiosk := get_tree().get_first_node_in_group("kiosk")
	if kiosk != null:
		kiosk.dispatch(action, tier)


## Depth-first collect of MeshInstance3D children that carry mesh surfaces.
func _collect_meshes(node: Node) -> void:
	if node is MeshInstance3D and node.mesh != null:
		_glow_meshes.append(node)
	for child in node.get_children():
		_collect_meshes(child)