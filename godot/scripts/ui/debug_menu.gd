## The debug menu (~): three wrenches. Built in code like the wardrobe menu; a
## lens holds inputs while open, and each action closes the menu after it runs.
## Not player-facing: this ships in the build but only the tilde ever opens it.
extends CanvasLayer

var _open := false


## Boot: build the panel hidden; the tilde toggles it.
func _ready() -> void:
	layer = 10
	visible = false   # the docstring promises hidden; a bare CanvasLayer defaults visible
	var panel := PanelContainer.new()
	panel.position = Vector2(12.0, 12.0)
	add_child(panel)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 4)
	panel.add_child(rows)
	rows.add_child(_label("DEBUG -- ~ closes"))
	rows.add_child(_button("DIG 1000M HOLE", _dig))
	rows.add_child(_button("FILL HOLE (WAITER TEST)", _fill))
	rows.add_child(_button("RESET PROGRESSION", _reset))


## The tilde toggles the menu; never over a foreign lens; Esc closes too.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_menu"):
		if GameState.view_lens == "" or GameState.view_lens == "debug":
			_toggle()
	elif _open and event.is_action_pressed("ui_cancel"):
		_toggle()


## Open/close: the mouse frees for the buttons; a lens holds the world's inputs.
func _toggle() -> void:
	_open = not _open
	visible = _open
	GameState.view_lens = "debug" if _open else ""
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if _open else Input.MOUSE_MODE_CAPTURED


## Dig the 1000m shaft (main owns the strike machinery); close so you can fall in.
func _dig() -> void:
	var main := get_tree().current_scene
	if main != null and main.has_method("dig_debug_hole"):
		main.dig_debug_hole()
	_toggle()


## Run the fill theater without the sale: the point is the waiter lift.
func _fill() -> void:
	var kiosk := get_tree().get_first_node_in_group("kiosk")
	if kiosk != null:
		kiosk.begin_debug_fill()
	_toggle()


## Wipe money, dirt, and item ownership.
func _reset() -> void:
	GameState.reset_progression()
	_toggle()


## A plain label.
func _label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	return label


## A button that refuses keyboard focus (the keyboard stays the player's).
func _button(text: String, handler: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(handler)
	return button