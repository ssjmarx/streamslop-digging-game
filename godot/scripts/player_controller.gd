## The player: a CharacterBody3D with identical legs, a toggleable first/
## third camera, and a state machine fed by the Universal Animation Library.
## DIRT scope: walk, sprint, crouch (hold), jump, mouse look, P camera flip.
extends CharacterBody3D

# -- Config ------

const WALK_SPEED := 4.0
const SPRINT_SPEED := 7.0
const CROUCH_SPEED := 2.5   # the speed the backhoe will drive at, someday. coincidence.
const JUMP_VELOCITY := 4.5
const GRAVITY := 14.0
const MOUSE_SENS := 0.003
const BODY_TURN_SPEED := 12.0   # lerp weight for the body facing (per second)
const ZOOM_BOOM_STEP := 0.5   # meters per wheel notch (third person)
const BOOM_MIN := 1.5
const BOOM_MAX := 8.0
const FOV_STEP := 5.0   # degrees per wheel notch (first person)
const FOV_MIN := 50.0
const FOV_MAX := 90.0
const PITCH_LIMIT := 1.4
const STAND_EYE_HEIGHT := 1.6
const CROUCH_EYE_HEIGHT := 0.9
const STAND_CAPSULE_HEIGHT := 1.8
const CROUCH_CAPSULE_HEIGHT := 1.2
const MODEL_YAW := PI   # gltf guys face +Z; Godot forward is -Z. flip if he moonwalks.
const AVATAR_SCENE := "res://assets/meshes/quaternius/superhero_female/Superhero_Female_FullBody.gltf"
const ANIM_LIBRARY_SCENE := "res://assets/anims/quaternius/UAL1_Standard.glb"
const ANIM_FADE := 0.15
const FP_RUN_SLIDE := 0.4    # meters the camera adds to its base offset while running (FP only)
const FP_CROUCH_SLIDE := 0.4   # same, while crouching; own dial -- the pose is lower
const FP_JUMP_BUMP := 0.15   # slight forward bump while airborne (FP only)
const FP_SLIDE_SPEED := 8.0   # lerp weight for the FP camera slide
const HEAD_BONE := "Head"   # universal rig head; hair pieces rig to this bone
# Piece path -> material kind. Hair keeps the textured look (T_Hair_2
# grayscale strands + brown tint); the standalone brows piece is GONE -- the
# character ships her own 'Eyebrows' mesh, tinted at load (_style_builtins).
const HAIR_PIECES := {
	"res://assets/meshes/quaternius/superhero_female/Hair_Long.gltf": "textured",
}
const HAIR_OFFSET := Vector3.ZERO   # tuning dial if the bind pose sits wrong
const HAIR_COLOR := Color8(94, 64, 42)   # multiplies the grayscale detail map
const BROW_TINT := Color8(70, 48, 32)   # brown tint for the built-in brows mesh
const HAIR_BASE_COLOR_TEXTURE := "res://assets/meshes/quaternius/superhero_female/T_Hair_2_BaseColor.png"
const HAIR_NORMAL_TEXTURE := "res://assets/meshes/quaternius/superhero_female/T_Hair_2_Normal.png"


## Clip names as the importer leaves them (it strips the glb's "_Loop"
## suffix, verified by scripts/tools/probe_ual_anims.gd).
const ANIM_IDLE := "Idle"
const ANIM_JOG := "Jog_Fwd"
const ANIM_SPRINT := "Sprint"
const ANIM_WALK := "Walk"
const ANIM_CROUCH_MOVE := "Crouch_Fwd"
const ANIM_CROUCH_IDLE := "Crouch_Idle"
const ANIM_JUMP := "Jump"

## Clips that must loop at runtime. The importer drops the "_Loop" flag
## with the suffix, so we re-apply it by hand for the whole locomotion
## family -- future milestones get their loops from this list too.
const LOOPERS := [
	"Idle", "Idle_Talking", "Idle_Torch", "Jog_Fwd", "Sprint", "Walk",
	"Walk_Formal", "Crouch_Fwd", "Crouch_Idle", "Jump", "Dance",
	"Driving", "Push", "Sitting_Idle", "Sitting_Talking",
	"Spell_Simple_Idle", "Swim_Fwd", "Swim_Idle", "Sword_Idle",
	"Pistol_Idle",
]


# -- State ------

var third_person := false
var crouching := false
var _pitch_angle := 0.0
var _fp_base_offset := Vector3.ZERO   # captured from the scene: your hand-tuned FP camera position

@onready var rig: Node3D = $Rig
@onready var pitch: Node3D = $Rig/Pitch
@onready var fp_eye: Node3D = $Rig/FP
@onready var fp_camera: Camera3D = $Rig/FP/Camera
@onready var boom: SpringArm3D = $Rig/Pitch/Boom
@onready var tp_camera: Camera3D = $Rig/Pitch/Boom/CameraTP
@onready var mesh_root: Node3D = $Mesh
@onready var placeholder: MeshInstance3D = $Mesh/Placeholder
@onready var collider: CollisionShape3D = $Collision


## Boot: capture base offset, camera modes, avatar + hair; loader holds physics.
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_fp_base_offset = fp_eye.position
	boom.add_excluded_object(get_rid())
	_apply_camera_mode()
	_load_avatar()
	set_physics_process(false)   # main.gd's loader re-enables us (dev_log #1)


## Loader handshake: the spawn column is meshed -- physics goes live.
func on_ground_ready() -> void:
	set_physics_process(true)


## Mouse + action routing: rig yaw, both-camera pitch, P flip, wheel zoom, Esc.
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rig.rotate_y(-event.relative.x * MOUSE_SENS)   # mouse yaws the camera rig only
		_pitch_angle = clampf(_pitch_angle - event.relative.y * MOUSE_SENS, -PITCH_LIMIT, PITCH_LIMIT)
		pitch.rotation.x = _pitch_angle   # TP: the boom pivot orbits the eye
		fp_camera.rotation.x = _pitch_angle   # FP: the camera pitches IN PLACE -- no lever arm
	elif event.is_action_pressed("toggle_camera"):
		_toggle_camera()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom(1.0)   # zoom in
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom(-1.0)   # zoom out
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


## Frame physics: gravity, crouch state, movement, facing, FP slide, animation.
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		DirtBus.player_noise.emit(1.4, 1)   # nobody is listening. yet.
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var want_crouch := Input.is_action_pressed("crouch")   # hold, not toggle (ruling)
	if want_crouch != crouching:
		_set_crouch(want_crouch)
	var speed := CROUCH_SPEED if crouching else (SPRINT_SPEED if Input.is_action_pressed("sprint") else WALK_SPEED)
	var dir := (rig.transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	move_and_slide()
	_update_facing(dir, delta)
	_update_fp_camera_slide(dir.length_squared() > 0.0001, delta)
	_update_animation(dir.length_squared() > 0.01)


## Body facing: TP faces movement (atan2(-x,-z); unnegated = backwards), FP faces the rig; lerped.
func _update_facing(dir: Vector3, delta: float) -> void:
	var target := 0.0
	if third_person:
		if dir.length_squared() < 0.0001:
			return
		target = atan2(-dir.x, -dir.z)
	else:
		target = rig.rotation.y
	mesh_root.rotation.y = lerp_angle(
		mesh_root.rotation.y, target, minf(delta * BODY_TURN_SPEED, 1.0))



## P flips first/third: cameras swap, body visible in both.
func _toggle_camera() -> void:
	third_person = not third_person
	_apply_camera_mode()


## Wheel: TP cranes the boom 1.5-8m; FP zooms FOV 50-90 (the brow/hair inspector).
func _zoom(direction: float) -> void:
	if third_person:
		boom.spring_length = clampf(
			boom.spring_length - direction * ZOOM_BOOM_STEP, BOOM_MIN, BOOM_MAX)
	else:
		fp_camera.fov = clampf(
			fp_camera.fov - direction * FOV_STEP, FOV_MIN, FOV_MAX)


## The one place FP/TP state lands: current cameras per mode; body visible in both.
func _apply_camera_mode() -> void:
	fp_camera.current = not third_person
	tp_camera.current = third_person


## Hold-to-crouch: resize the capsule, drop the TP pivot; FP eye height is the slide's job.
func _set_crouch(on: bool) -> void:
	crouching = on
	var shape := collider.shape as CapsuleShape3D
	shape.height = CROUCH_CAPSULE_HEIGHT if on else STAND_CAPSULE_HEIGHT
	collider.position.y = (CROUCH_CAPSULE_HEIGHT if on else STAND_CAPSULE_HEIGHT) * 0.5
	pitch.position.y = CROUCH_EYE_HEIGHT if on else STAND_EYE_HEIGHT
	DirtBus.player_noise.emit(0.4 if on else 1.0, 1)   # GDD §14: do not document. do not ask.

# -- Avatar (loads at runtime; the scene carries only the capsule) ------

## Instance the avatar, style built-ins, attach hair, bind the UAL library; bald+capsule on failure.
func _load_avatar() -> void:
	var avatar_scene: PackedScene = load(AVATAR_SCENE)
	if avatar_scene == null:
		placeholder.visible = true
		return
	var avatar := avatar_scene.instantiate()
	avatar.rotation.y = MODEL_YAW
	mesh_root.add_child(avatar)
	_style_builtins(avatar)
	for piece_path in HAIR_PIECES:
		_attach_hair_piece(avatar, piece_path, HAIR_PIECES[piece_path])
	var anim_player := _find_anim_player(avatar)
	if anim_player == null:
		anim_player = AnimationPlayer.new()
		avatar.add_child(anim_player)
	if _attach_universal_anims(anim_player) == 0:
		placeholder.visible = true
		return
	placeholder.visible = false
	anim_player.play(ANIM_IDLE, ANIM_FADE)


## First AnimationPlayer under the node, depth-first; null when none.
func _find_anim_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var found := _find_anim_player(child)
		if found != null:
			return found
	return null


## Tint the built-in Eyebrows mesh brown+texture (MI_Hair_2 grayscale reads white untinted).
func _style_builtins(avatar: Node) -> void:
	var meshes: Array[MeshInstance3D] = []
	_collect_mesh_instances(avatar, meshes)
	for mesh_instance in meshes:
		if mesh_instance.name != "Eyebrows":
			continue
		var mat := StandardMaterial3D.new()
		mat.albedo_color = BROW_TINT
		mat.albedo_texture = load(HAIR_BASE_COLOR_TEXTURE)
		mat.roughness = 1.0
		for surface in mesh_instance.mesh.get_surface_count():
			mesh_instance.set_surface_override_material(surface, mat)


## BoneAttachment3D on Head + rest-inverse transform; material by kind; bald on failure.
func _attach_hair_piece(avatar: Node, piece_path: String, kind: String) -> void:
	var hair_material := _make_hair_material(kind)
	var piece_scene: PackedScene = load(piece_path)
	if piece_scene == null:
		return
	var skeleton := _find_skeleton(avatar)
	if skeleton == null:
		return
	var head_idx := skeleton.find_bone(HEAD_BONE)
	if head_idx == -1:
		return
	var piece := piece_scene.instantiate()
	piece.transform = skeleton.get_bone_global_rest(head_idx).affine_inverse()
	piece.position += HAIR_OFFSET
	var attach := BoneAttachment3D.new()
	attach.bone_name = HEAD_BONE
	skeleton.add_child(attach)
	attach.add_child(piece)
	var meshes: Array[MeshInstance3D] = []
	_collect_mesh_instances(piece, meshes)
	var surfaces := 0
	for mesh_instance in meshes:
		mesh_instance.material_override = hair_material   # node-level: covers every surface
		surfaces += mesh_instance.mesh.get_surface_count()
	print("hair: %s attached -- meshes=%d surfaces tinted=%d" % [
		piece_path.get_file(), meshes.size(), surfaces])


## First Skeleton3D under the node, depth-first; null when none.
func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	for child in node.get_children():
		var found := _find_skeleton(child)
		if found != null:
			return found
	return null


## Depth-first collect of every MeshInstance3D under the piece.
func _collect_mesh_instances(node: Node, out: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		out.append(node)
	for child in node.get_children():
		_collect_mesh_instances(child, out)


## Piece material by kind: "textured" = T_Hair_2 maps + HAIR_COLOR tint; "flat" = BROW_TINT only.
func _make_hair_material(kind: String) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	if kind == "textured":
		material.albedo_color = HAIR_COLOR
		material.albedo_texture = load(HAIR_BASE_COLOR_TEXTURE)
		material.normal_enabled = true
		material.normal_texture = load(HAIR_NORMAL_TEXTURE)
	else:
		material.albedo_color = BROW_TINT
	material.roughness = 1.0
	return material


## Merge all UAL clips into the avatar's default library, re-loop LOOPERS; returns bound count.
func _attach_universal_anims(anim_player: AnimationPlayer) -> int:
	var ual_scene: PackedScene = load(ANIM_LIBRARY_SCENE)
	if ual_scene == null:
		return 0
	var ual := ual_scene.instantiate()
	var ual_player := _find_anim_player(ual)
	if ual_player == null:
		ual.queue_free()
		return 0
	var lib: AnimationLibrary
	if anim_player.has_animation_library(""):
		lib = anim_player.get_animation_library("")
	else:
		lib = AnimationLibrary.new()
		anim_player.add_animation_library("", lib)
	var bound := 0
	for full_name in ual_player.get_animation_list():
		var anim_name := full_name.get_slice("/", full_name.get_slice_count("/") - 1)
		var anim := ual_player.get_animation(full_name)
		if anim_name in LOOPERS:
			anim.loop_mode = Animation.LOOP_LINEAR
		if not lib.has_animation(anim_name):
			lib.add_animation(anim_name, anim)
			bound += 1
	ual.queue_free()
	return bound


## FP only: sole writer of the eye node -- base x/z, crouch eye height, run/crouch/airborne slide on z.
func _update_fp_camera_slide(moving: bool, delta: float) -> void:
	var extra := 0.0
	if moving:
		extra = FP_RUN_SLIDE
	elif crouching:
		extra = FP_CROUCH_SLIDE
	if not is_on_floor():
		extra += FP_JUMP_BUMP
	var target := Vector3(
		_fp_base_offset.x,
		CROUCH_EYE_HEIGHT if crouching else _fp_base_offset.y,
		_fp_base_offset.z - extra)
	fp_eye.position = fp_eye.position.lerp(target, minf(delta * FP_SLIDE_SPEED, 1.0))


## Pick the clip from state (idle/jog/sprint/crouch/jump) and crossfade; no-op without the library.
func _update_animation(moving: bool) -> void:
	var anim_player := _find_anim_player(mesh_root)
	if anim_player == null or not anim_player.has_animation(ANIM_IDLE):
		return
	var next := ANIM_IDLE
	if not is_on_floor():
		next = ANIM_JUMP
	elif crouching:
		next = ANIM_CROUCH_MOVE if moving else ANIM_CROUCH_IDLE
	elif moving:
		next = ANIM_SPRINT if Input.is_action_pressed("sprint") else ANIM_JOG
		if not anim_player.has_animation(next):
			next = ANIM_WALK
	if anim_player.current_animation != next and anim_player.has_animation(next):
		anim_player.play(next, ANIM_FADE)
