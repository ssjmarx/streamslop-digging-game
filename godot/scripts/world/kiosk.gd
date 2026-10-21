## The kiosk -- the loop (GDD §6c). Outside, the whole shop is one interactable;
## inside, the shop view rides a pre-placed camera and a virtual cursor over
## diegetic items. SELL DIRT pours the hole back; a click skips; Esc exits.
extends Node3D

const STOPWATCH_PRICE := 600   # GDD §6e law: $600, tooltip "Stopwatch.", nothing else
const SNOW_COST := 2000        # the scam prices like the pro (ruling 2026-10-19)
const SHOVEL_TOP := 3          # the ladder's top rung; snow lives outside the ladder
const POUR_SECONDS := 6.0      # the pour is locked to six seconds (ruling 2026-10-19)

@export_group("Shop View")
## Mouse-delta to virtual-cursor pixels while the shop view holds the mouse.
@export var cursor_speed := 0.6
@export_group("Pour")
## Height of the overhead pour camera above the hole (the boot spectator's twin).
@export var pour_camera_height := 30.0
## Seconds before the fill starts -- the overhead glide should land first.
@export var pour_lead_seconds := 0.45

var _cursor := Vector2.ZERO      # the virtual cursor's screen point in shop view
var _pouring := false
var _skip_requested := false
var _pour_cam: Camera3D = null   # created per pour, freed on close

@onready var _shop_camera: Camera3D = $ShopCamera


## Boot: world-mode collision from frame one; the Worker's idle; live price tags.
func _ready() -> void:
	_set_shop_collision(false)
	_shopkeeper_idle()
	_refresh_price_tags()


## The shopkeeper's idle: his own pack's clips (UMM names, not UAL); fails safe.
func _shopkeeper_idle() -> void:
	var anim_player := _find_anim_player($Shopkeeper)
	if anim_player == null:
		return
	if anim_player.has_animation("Idle"):
		anim_player.play("Idle")


## Route one eaten click from a clickable (the shop's only front door).
func dispatch(action: String, tier := 0) -> void:
	match action:
		"open":
			if GameState.view_lens == "":
				_open_shop()
		"sell":
			if GameState.view_lens == "shop":
				_begin_sale()
		"buy_tier":
			if GameState.view_lens == "shop":
				_shovel_click(tier)
		"buy_snow":
			if GameState.view_lens == "shop":
				_snow_click()
		"buy_stopwatch":
			if GameState.view_lens == "shop":
				_buy_stopwatch()


## Shop input: mouse deltas steer the virtual cursor; Esc exits; a click mid-pour skips the theater.
func _unhandled_input(event: InputEvent) -> void:
	if GameState.view_lens == "shop":
		if event is InputEventMouseMotion:
			_cursor += event.relative * cursor_speed
			_cursor = _cursor.clamp(Vector2.ZERO, get_viewport().get_visible_rect().size)
		elif event.is_action_pressed("ui_cancel"):
			_close_shop()
			get_viewport().set_input_as_handled()   # one Esc closes the shop; it must not also free the mouse
	elif GameState.view_lens == "pour" and event.is_action_pressed("dig"):
		_skip_requested = true


## The virtual cursor's screen point -- the sight casts its shop ray through it.
func cursor_point() -> Vector2:
	return _cursor


## Enter the shop view: hold inputs, glide to the shop camera, center the cursor, take the greeting.
func _open_shop() -> void:
	GameState.view_lens = "shop"
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		player.enter_lens(_shop_camera)
		player.set_body_visible(false)   # the shop shot is his; he waits outside the frame
	_set_shop_collision(true)
	_cursor = get_viewport().get_visible_rect().size * 0.5
	$UiOpen.play()
	$Shopkeeper/VoiceOpen.play()


## Leave the shop view: release the lens, hand the world (and the body) back.
func _close_shop() -> void:
	GameState.view_lens = ""
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		player.exit_lens()
		player.set_body_visible(true)
	_set_shop_collision(false)
	$UiOpen.play()


## Shop-mode collision swap: the stall eats the cursor in the world; in shop mode it goes pass-through and the products take the ray.
func _set_shop_collision(shop: bool) -> void:
	$StallBody.collision_layer = 0 if shop else 1
	var product_layer := 1 if shop else 0
	for node in [$Shopkeeper/SellZone, $Items/Trowel, $Items/Pro, $Items/Ergonomic, $Items/Snow, $Items/Stopwatch]:
		(node as CollisionObject3D).collision_layer = product_layer


## SELL DIRT: the theater is mandatory, the deletion is the truth (§10); money lands at the last row.
func _begin_sale() -> void:
	if _pouring:
		return
	var carried := GameState.dirt
	if carried <= 0:
		$UiClick.play()   # nothing to sell: the shopkeeper says nothing
		return
	_begin_pour(carried)

# -- Pour (the theater is mandatory; the rate is a safety invariant) ------

## The pour: a checker disk rises from the hole's bottom under the overhead lens; slabs re-emit behind it, hidden.
func _begin_pour(carried: int) -> void:
	_pouring = true
	_skip_requested = false
	GameState.view_lens = "pour"
	var terrain := get_tree().get_first_node_in_group("terrain") as VoxelTerrain
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		player.enter_lens(_make_pour_camera())
	_play_spellcast()
	var generator := terrain.generator
	var block_size: int = generator.BLOCK_SIZE
	var radius: int = generator.WORLD_RADIUS
	# the theater floor: the hole's deepest dug point, never deeper than -100m
	var start_y := -float(generator.depth_floor)
	var diglog_reader := get_tree().get_first_node_in_group("diglog")
	if diglog_reader != null:
		for entry in diglog_reader.read_entries():
			start_y = maxf(start_y, float(entry.c.y) - float(entry.r))
	start_y = maxf(start_y, -100.0)
	var disk := _make_fill_disk(start_y)
	var slab_bottom := -ceili(float(generator.depth_floor) / float(block_size)) * block_size   # slab-aligned bottom
	var by := slab_bottom
	await get_tree().create_timer(pour_lead_seconds).timeout   # the glide lands before the rise starts
	var rise_per_frame := -start_y / (POUR_SECONDS * float(Engine.physics_ticks_per_second))
	while disk.global_position.y < 0.0:
		await get_tree().physics_frame
		if _skip_requested:
			break
		disk.global_position.y = minf(disk.global_position.y + rise_per_frame, 0.0)
		var fill_to := disk.global_position.y
		while by < 0 and float(by + block_size) <= fill_to + 0.001:
			_fill_row(terrain, by, block_size, radius)
			by += block_size
		_lift_waiter(terrain, player, fill_to)
	disk.visible = false
	if _skip_requested:   # the end state must be complete even when skipped
		while by < 0:
			_fill_row(terrain, by, block_size, radius)
			by += block_size
	_lift_waiter(terrain, player, 0.0)
	disk.queue_free()
	# the floor law returns: below START_DEPTH is void again, byte-identical to a fresh boot
	generator.depth_floor = 20
	var slab := slab_bottom
	while slab < 0:
		_fill_row(terrain, slab, block_size, radius)
		slab += block_size
	var diglog := get_tree().get_first_node_in_group("diglog")
	if diglog != null:
		diglog.wipe()
	DirtBus.dirt_sold.emit(carried, carried, 1)
	$Shopkeeper/VoiceSold.play()
	var sign := get_tree().get_first_node_in_group("stop_sign")
	if sign != null:
		sign.materialize(terrain)
	_end_pour()


## The theater disk: checker quads that read as the voxel tops, rising with the fill.
func _make_fill_disk(start_y: float) -> MeshInstance3D:
	var cell := 8   # the checker's size, matching dirt_checker_generator
	var light := Color(0.58, 0.42, 0.29)   # the light dirt's top color
	var dark := Color(0.33, 0.22, 0.14)    # the dark dirt's top color
	var verts := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	var vertex := 0
	for cz in range(-56, 56, cell):
		for cx in range(-56, 56, cell):
			var nearest_x := clampi(0, cx, cx + cell)
			var nearest_z := clampi(0, cz, cz + cell)
			if Vector2(nearest_x, nearest_z).length() > 49.0:
				continue   # stay inside the undiggable rim wall
			var parity := posmod(floori(cx / float(cell)) + floori(cz / float(cell)), 2)
			var color := light if parity == 0 else dark
			for corner in [Vector3(cx, 0, cz), Vector3(cx + cell, 0, cz), Vector3(cx + cell, 0, cz + cell), Vector3(cx, 0, cz + cell)]:
				verts.append(corner)
				colors.append(color)
			indices.append_array([vertex, vertex + 1, vertex + 2, vertex, vertex + 2, vertex + 3])
			vertex += 4
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true   # the terrain's own trick
	mesh.surface_set_material(0, mat)
	var disk := MeshInstance3D.new()
	disk.mesh = mesh
	get_tree().current_scene.add_child(disk)
	disk.global_position = Vector3(0.0, start_y, 0.0)
	return disk


## The pour winds down: leave the overhead lens, hand the world (and the body) back.
func _end_pour() -> void:
	if _pour_cam != null:
		_pour_cam.queue_free()
		_pour_cam = null
	_pouring = false
	GameState.view_lens = ""
	_set_shop_collision(false)
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		player.exit_lens()
		player.set_body_visible(true)
	GameState.stopwatch_reset()   # the sell's silent zero: the run restarts at control
	_refresh_price_tags()


## The shopkeeper is also the only elevator: a body inside the disc rises with the fill line (§6f).
func _lift_waiter(terrain: VoxelTerrain, player: Node, line_top: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	var p: Vector3 = player.global_position
	if Vector2(p.x, p.z).length() > float(terrain.generator.WORLD_RADIUS):
		return   # outside the disc the shopkeeper owes nobody a lift
	if p.y < line_top:
		player.global_position.y = line_top
		player.velocity = Vector3(player.velocity.x, 0.0, player.velocity.z)


## Re-emit one data-block row from the generator: behind the line the world is pristine (the main.gd shape).
func _fill_row(terrain: VoxelTerrain, by: int, block_size: int, radius: int) -> void:
	var generator := terrain.generator
	var start := -ceili(float(radius) / float(block_size)) * block_size
	for bz in range(start, radius, block_size):
		for bx in range(start, radius, block_size):
			var nearest_x := clampi(0, bx, bx + block_size)
			var nearest_z := clampi(0, bz, bz + block_size)
			if Vector2(nearest_x, nearest_z).length() > float(radius):
				continue   # the block cannot touch the disc
			var buffer := VoxelBuffer.new()
			buffer.create(block_size, block_size, block_size)
			generator._generate_block(buffer, Vector3i(bx, by, bz), 0)
			if not terrain.try_set_block_data(terrain.voxel_to_data_block(Vector3i(bx, by, bz)), buffer):
				push_warning("pour: try_set_block_data failed at %s" % Vector3i(bx, by, bz))


## The overhead pour shot: the boot spectator's twin, above the hole looking down.
func _make_pour_camera() -> Camera3D:
	_pour_cam = Camera3D.new()
	add_child(_pour_cam)
	_pour_cam.global_position = Vector3(0.0, pour_camera_height, 0.01)
	_pour_cam.look_at(Vector3.ZERO, Vector3.FORWARD)
	return _pour_cam

## The theater: Spell clips on UAL rigs, the UMM Interact as the stand-in; a bare placeholder fails safe.
func _play_spellcast() -> void:
	var anim_player := _find_anim_player($Shopkeeper)
	if anim_player == null:
		return
	if anim_player.has_animation("Spell_Simple_Enter"):
		anim_player.play("Spell_Simple_Enter")
		if anim_player.has_animation("Spell_Simple_Idle"):
			anim_player.queue("Spell_Simple_Idle")
	elif anim_player.has_animation("Interact"):
		anim_player.play("Interact")


## A shovel display click: buy the next ladder rung, or re-equip an owned one for free.
func _shovel_click(tier: int) -> void:
	if tier <= GameState.shovel_owned:
		GameState.set_shovel_tier(tier)   # owned: equip for free
		$UiClick.play()
		return
	if tier != GameState.shovel_owned + 1 or tier > SHOVEL_TOP:
		return   # locked until you own the rung below; the ladder never reaches snow
	var cost: int = GameState.SHOVELS[tier]["cost"]
	if GameState.money < cost:
		return
	GameState.money -= cost
	GameState.purchase_shovel(tier)
	$UiClick.play()
	_refresh_price_tags()


## The meta scam: pro money, buys anytime, digs nothing -- and the shopkeeper does not care.
func _snow_click() -> void:
	if GameState.snow_owned:
		GameState.set_shovel_tier(GameState.SHOVELS.size() - 1)   # re-equip your mistake
		$UiClick.play()
		return
	if GameState.money < SNOW_COST:
		return
	GameState.money -= SNOW_COST
	GameState.purchase_snow()
	$UiClick.play()
	_refresh_price_tags()


## The meta item: $600, tooltip "Stopwatch." That is the whole tooltip (§6e).
func _buy_stopwatch() -> void:
	if GameState.stopwatch_owned or GameState.money < STOPWATCH_PRICE:
		return
	GameState.money -= STOPWATCH_PRICE
	GameState.stopwatch_owned = true
	GameState.touch()
	$UiClick.play()
	_refresh_price_tags()


## Price tags read live state: owned shovels and the watch read PURCHASED (the weapon wheel owns swapping later).
func _refresh_price_tags() -> void:
	var trowel: Dictionary = GameState.SHOVELS[1]
	var pro: Dictionary = GameState.SHOVELS[2]
	var ergo: Dictionary = GameState.SHOVELS[3]
	$Items/Trowel/Price.text = _shovel_tag(GameState.shovel_owned >= 1, trowel)
	$Items/Pro/Price.text = _shovel_tag(GameState.shovel_owned >= 2, pro)
	$Items/Ergonomic/Price.text = _shovel_tag(GameState.shovel_owned >= 3, ergo)
	$Items/Snow/Price.text = "PURCHASED" if GameState.snow_owned else "SNOW SHOVEL -- $%d" % SNOW_COST
	$Items/Stopwatch/Price.text = "PURCHASED" if GameState.stopwatch_owned \
			else "STOPWATCH -- $%d" % STOPWATCH_PRICE


## A shovel tag: PURCHASED when owned, otherwise the name and price.
func _shovel_tag(owned: bool, shovel: Dictionary) -> String:
	if owned:
		return "PURCHASED"
	return "%s -- $%d" % [shovel["name"], shovel["cost"]]


## First AnimationPlayer under the node, depth-first; null when none.
func _find_anim_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var found := _find_anim_player(child)
		if found != null:
			return found
	return null