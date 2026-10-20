## The wardrobe debug menu (O): slot cyclers, accessory checkboxes, hair
## color. Session UI over the player's wardrobe; every change writes through
## to GameState; while open the mouse is free and dig.gd stands down.
extends CanvasLayer

var _wardrobe: RefCounted = null
var _player: Node = null
var _open := false
var _rows: VBoxContainer = null


## Bound by the player right after the avatar loads -- O does nothing before.
func bind(wardrobe: RefCounted, player: Node) -> void:
	_wardrobe = wardrobe
	_player = player
	layer = 10
	_build()
	visible = false


## O toggles the menu once the avatar has loaded; never over a foreign lens.
func _unhandled_input(event: InputEvent) -> void:
	if _wardrobe != null and event.is_action_pressed("wardrobe_menu"):
		if GameState.view_lens != "" and GameState.view_lens != "wardrobe":
			return   # the shop or the pour owns the lens; O stands down
		_toggle()


## Open/close: free or recapture the mouse; the lens flag holds the world's inputs.
func _toggle() -> void:
	_open = not _open
	visible = _open
	GameState.view_lens = "wardrobe" if _open else ""
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if _open else Input.MOUSE_MODE_CAPTURED
	if _player != null:
		_player.set_dressing_cam(_open)
	if _open:
		_refresh()


## Build the panel once; rows rebuild on every refresh.
func _build() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(12.0, 12.0)
	add_child(panel)
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 4)
	panel.add_child(_rows)


## Rebuild the rows from wardrobe state -- cheap, correct, debug-grade.
func _refresh() -> void:
	if _rows == null:
		return
	for child in _rows.get_children():
		child.queue_free()
	_rows.add_child(_label("WARDROBE -- O closes"))
	for slot in _wardrobe.slot_order():
		var row := HBoxContainer.new()
		row.add_child(_label(slot))
		var prev := _button(" < ")
		prev.pressed.connect(_cycle_slot.bind(slot, -1))
		row.add_child(prev)
		var worn: String = _wardrobe.slot_piece(slot)
		row.add_child(_label("(bare)" if worn == "" else worn))
		var next := _button(" > ")
		next.pressed.connect(_cycle_slot.bind(slot, 1))
		row.add_child(next)
		_rows.add_child(row)
	for piece in _wardrobe.accessory_order():
		var box := CheckBox.new()
		box.text = piece
		box.button_pressed = _wardrobe.accessory_on(piece)
		box.focus_mode = Control.FOCUS_NONE
		box.toggled.connect(_toggle_accessory.bind(piece))
		_rows.add_child(box)
	var hair_row := HBoxContainer.new()
	hair_row.add_child(_label("Hair"))
	var hair_prev := _button(" < ")
	hair_prev.pressed.connect(_cycle_hair.bind(-1))
	hair_row.add_child(hair_prev)
	hair_row.add_child(_label(_wardrobe.hair_color_name()))
	var hair_next := _button(" > ")
	hair_next.pressed.connect(_cycle_hair.bind(1))
	hair_row.add_child(hair_next)
	_rows.add_child(hair_row)


## Menu cycler: step the slot, refresh.
func _cycle_slot(slot: String, dir: int) -> void:
	_wardrobe.cycle_slot(slot, dir)
	_refresh()


## Menu checkbox: flip the accessory, refresh.
func _toggle_accessory(_on: bool, piece: String) -> void:
	_wardrobe.toggle_accessory(piece)
	_refresh()


## Menu cycler: step the swatch, refresh.
func _cycle_hair(dir: int) -> void:
	_wardrobe.cycle_hair(dir)
	_refresh()


## A plain label.
func _label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	return label


## A button that refuses keyboard focus (WASD stays the player's).
func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	return button
