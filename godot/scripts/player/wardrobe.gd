## The wardrobe: grammar-driven piece state over the avatar GLB -- pure
## visibility and tint, never geometry. Two tokens = exclusive slot, three-plus
## = free accessory (never arbitrated); fixed meshes always show; color is state.
extends RefCounted

# -- Grammar (mirrored by tools/wardrobe_check.py) ------

const FIXED_NAMES := ["Eyes", "Eyebrows"]
const REGION_WORDS := ["Head", "Body", "Arms", "Legs", "Feet"]
const HAIR_PREFIX := "Hair_"
const HAIR_SLOT := "Hair"
const SLOT_WORDS := ["Body", "Arms", "Legs", "Feet"]

# -- Palette: multiplier-friendly swatches over the grayscale strand maps.
# Brown is the shipped default and the parity color.

const HAIR_COLORS := [
	{"name": "Black", "color": Color("#1e1816")},
	{"name": "Dark brown", "color": Color("#34241a")},
	{"name": "Brown", "color": Color("#5e402a")},
	{"name": "Chestnut", "color": Color("#744c30")},
	{"name": "Auburn", "color": Color("#7a3c26")},
	{"name": "Ginger", "color": Color("#b26030")},
	{"name": "Dark blonde", "color": Color("#9c7c48")},
	{"name": "Blonde", "color": Color("#c8a66a")},
	{"name": "Platinum", "color": Color("#e2cea8")},
	{"name": "Gray", "color": Color("#94908c")},
	{"name": "Silver", "color": Color("#bec2c6")},
	{"name": "White", "color": Color("#eeece6")},
]
const DEFAULT_HAIR := "Brown"
const BROW_DARKEN := 0.75   # brows/lashes ride darker than the hair, always

# -- The default kit: today's character, verbatim -- full Ranger minus the hood.

const DEFAULT_KIT := {
	"slots": {
		"Body": "Ranger_Body", "Arms": "Ranger_Arms", "Legs": "Ranger_Legs",
		"Feet": "Ranger_Feet", "Hair": "Hair_Long",
	},
	"accessories": {
		"Ranger_Acc_Pauldrons": true, "Ranger_Arms_Bracer": true,
		"Ranger_Body_Belt_1": true, "Ranger_Body_Belt_2": true,
		"Ranger_Head_Hood": false,
	},
	"hair": DEFAULT_HAIR,
}

var _slots := {}            # slot word -> worn piece name ("" = bare)
var _accessories := {}      # accessory name -> on/off
var _hair := DEFAULT_HAIR   # swatch name, looked up in HAIR_COLORS
var _roots: Array[Node] = []           # avatar + ghost; both get dressed
var _slot_order: Array[String] = []    # discovery order; the menu reads these
var _accessory_order: Array[String] = []
var _options := {}          # slot word -> Array[String] piece names


## Learn the layout from the avatar and keep both roots for applies.
func setup(avatar: Node, ghost: Node) -> void:
	_roots = [avatar, ghost]
	var meshes: Array[MeshInstance3D] = []
	_collect_meshes(avatar, meshes)
	for mesh in meshes:
		var piece := String(mesh.name)
		if piece in FIXED_NAMES:
			continue
		var slot := _slot_of(piece)
		if slot != "":
			if not _options.has(slot):
				_options[slot] = []
				_slot_order.append(slot)
			if not piece in _options[slot]:
				_options[slot].append(piece)
		elif _is_accessory(piece) and not piece in _accessory_order:
			_accessory_order.append(piece)
			_accessories[piece] = false
	for slot in _slot_order:
		_slots[slot] = ""


## Wear a kit; unknown names degrade to bare/off/default.
func wear(kit: Dictionary) -> void:
	var slots: Dictionary = kit.get("slots", {})
	var accessories: Dictionary = kit.get("accessories", {})
	for slot in _slot_order:
		var want: String = slots.get(slot, "")
		_slots[slot] = want if want in _options[slot] else ""
	for piece in _accessory_order:
		_accessories[piece] = bool(accessories.get(piece, false))
	var hair: String = kit.get("hair", DEFAULT_HAIR)
	_hair = hair if _color_value(hair) != null else DEFAULT_HAIR
	_apply()


## The current kit in the save-file shape; GameState stores this verbatim.
func kit() -> Dictionary:
	return {"slots": _slots.duplicate(), "accessories": _accessories.duplicate(), "hair": _hair}


## -- State API (every mutation re-applies; apply is pure visibility) ------


## Equip a slot piece; the old piece leaves automatically.
func equip(slot: String, piece: String) -> void:
	if not _options.has(slot) or not piece in _options[slot]:
		return
	_slots[slot] = piece
	_apply()


## Cycle a slot for the menu; "" (bare) is always the first option.
func cycle_slot(slot: String, dir: int) -> void:
	var options: Array = [""] + _options.get(slot, [])
	var i := options.find(_slots.get(slot, ""))
	_slots[slot] = options[(i + dir + options.size()) % options.size()] if i != -1 else ""
	_apply()


## Flip an accessory; accessories stack, never arbitrated.
func toggle_accessory(piece: String) -> void:
	if not _accessories.has(piece):
		return
	_accessories[piece] = not _accessories[piece]
	_apply()


## Set the swatch by name; unknown names are ignored.
func set_hair(name: String) -> void:
	if _color_value(name) == null:
		return
	_hair = name
	_apply()


## Step through the palette by dir.
func cycle_hair(dir: int) -> void:
	var i := 0
	for j in HAIR_COLORS.size():
		if HAIR_COLORS[j]["name"] == _hair:
			i = j
			break
	_hair = HAIR_COLORS[(i + dir + HAIR_COLORS.size()) % HAIR_COLORS.size()]["name"]
	_apply()


## -- Read access for the menu ------


## Slot words in discovery order -- the menu's row order.
func slot_order() -> Array[String]:
	return _slot_order


## Piece names for a slot, discovery order.
func slot_options(slot: String) -> Array:
	return _options.get(slot, [])


## The worn piece name for a slot ("" = bare).
func slot_piece(slot: String) -> String:
	return _slots.get(slot, "")


## Accessory names in discovery order.
func accessory_order() -> Array[String]:
	return _accessory_order


## Whether an accessory is worn.
func accessory_on(piece: String) -> bool:
	return _accessories.get(piece, false)


## The current swatch name.
func hair_color_name() -> String:
	return _hair


## All swatch names, palette order.
func hair_color_names() -> Array:
	var out: Array = []
	for entry in HAIR_COLORS:
		out.append(entry["name"])
	return out


## -- Internals ------


## The whole wardrobe lands as visibility + tint. Roots: avatar + ghost.
func _apply() -> void:
	for root in _roots:
		if root == null or not is_instance_valid(root):
			continue
		var meshes: Array[MeshInstance3D] = []
		_collect_meshes(root, meshes)
		for mesh in meshes:
			var piece := String(mesh.name)
			if piece in FIXED_NAMES:
				continue
			if piece in REGION_WORDS:
				mesh.visible = _slots.get(piece, "") == ""   # occupied slot hides its skin
				continue
			var slot := _slot_of(piece)
			if slot != "":
				mesh.visible = _slots.get(slot, "") == piece
			elif _is_accessory(piece):
				mesh.visible = _accessories.get(piece, false)
		_style(meshes)


## Slot word for a piece name; "" when the name is not a slot piece.
func _slot_of(piece: String) -> String:
	if piece.begins_with(HAIR_PREFIX):
		return HAIR_SLOT
	var parts := piece.split("_")
	if parts.size() == 2 and parts[1] in SLOT_WORDS:
		return parts[1]
	return ""


## Accessory test: not fixed, not hair, three or more tokens (the arity law).
func _is_accessory(piece: String) -> bool:
	if piece in FIXED_NAMES or piece.begins_with(HAIR_PREFIX):
		return false
	return piece.split("_").size() >= 3


## Tint Hair_* with the swatch and Eyebrows with it darkened; materials recolor in place.
func _style(meshes: Array[MeshInstance3D]) -> void:
	var hair: Color = _color_value(_hair)
	var brow: Color = hair * BROW_DARKEN
	for mesh in meshes:
		var piece := String(mesh.name)
		var is_hair := piece.begins_with(HAIR_PREFIX)
		if not is_hair and piece != "Eyebrows":
			continue
		var tint := hair if is_hair else brow
		if mesh.mesh == null:
			continue
		for s in mesh.mesh.get_surface_count():
			var mat := mesh.get_surface_override_material(s)
			if mat == null:
				var src := mesh.mesh.surface_get_material(s)
				if src == null:
					continue
				mat = src.duplicate()
				mesh.set_surface_override_material(s, mat)
			mat.albedo_color = tint


## Swatch name -> Color; null when unknown.
func _color_value(name: String) -> Variant:
	for entry in HAIR_COLORS:
		if entry["name"] == name:
			return entry["color"]
	return null


## Depth-first collect of every MeshInstance3D under the node.
func _collect_meshes(node: Node, out: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		out.append(node)
	for child in node.get_children():
		_collect_meshes(child, out)
