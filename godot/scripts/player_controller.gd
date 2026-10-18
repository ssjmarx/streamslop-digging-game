## The player: a CharacterBody3D with identical legs, a toggleable first/
## third camera, and a state machine fed by the Universal Animation Library.
## VERB scope: swing clip + held shovel (cosmetic only; the dig lives in dig.gd).
extends CharacterBody3D

# -- Tunables (GDD §13: exports are the tuning surface; law numbers stay consts) ------

@export_group("Quake Physics")
## Q3 DEFAULT_GRAVITY 800u, avatar-matched: 1.8m capsule = 56u player = 0.0321 m/u.
@export var gravity := 25.7
## Q3 JUMP_VELOCITY 270u: 1.46m high, 0.68s air -- clears one voxel.
@export var jump_velocity := 8.67
@export_group("Movement")
## Full Q3 run (g_speed 320u x 0.0321 m/u). The default gear.
@export var run_speed := 10.3
## Held walk (V): stealth and roleplay (ruling 2026-10-17).
@export var walk_speed := 1.288
## The player's stealth crouch. The backhoe keeps the old sacred 2.5 (ruling 2026-10-17).
@export var crouch_speed := 0.966

@export_group("Anim Calibration")
## Jog_Fwd reads correct at this scale at this speed (eye-tuned 2026-10-17).
@export var run_anim_ref_speed := 10.3
@export var run_anim_ref_scale := 6.0
## Walk reads correct at this scale at this speed.
@export var walk_anim_ref_speed := 5.15
@export var walk_anim_ref_scale := 1.0
## Crouch_Fwd reads correct at this scale at this speed.
@export var crouch_anim_ref_speed := 2.575
@export var crouch_anim_ref_scale := 0.75
@export var mouse_sens := 0.003
## Lerp weight for the body facing (per second).
@export var body_turn_speed := 12.0
@export_group("Camera Feel")
## Meters per wheel notch (third person).
@export var zoom_boom_step := 0.5
@export var boom_min := 1.5
@export var boom_max := 8.0
## Degrees per wheel notch (first person).
@export var fov_step := 5.0
@export var fov_min := 50.0
@export var fov_max := 90.0
## Upward pitch limit (radians). Down is clamped at -85 via pitch_down_limit_deg.
@export var pitch_limit := 1.4
## Downward pitch limit in degrees (the camera clamps at -85; you may not look past it).
@export var pitch_down_limit_deg := 85.0
@export_group("FP Camera")
## Meters the lens floats ahead of the eye before the collision clamp pulls it back. Live dial.
@export var fp_arm_length := 0.3
## Meters the clamped lens stays from any wall surface (beyond the near plane).
@export var fp_wall_margin := 0.15
## FP near plane: clips geometry too close to the lens cleanly.
@export var fp_near_plane := 0.1
## First person tucks the Head bone and face furniture out of the lens. Live dial.
@export var fp_head_tuck := true:
	set(value):
		fp_head_tuck = value
		_update_head_tuck()
## Head bone scale while tucked (0.001 = a speck).
@export var fp_head_tuck_scale := 0.001
@export_group("Held Shovel")
## Meters blade-to-grip; normalized from the OBJ's AABB. Live dial.
@export var shovel_target_length := 1.1:
	set(value):
		shovel_target_length = value
		_apply_shovel_pose()
## Sit in the fist. Live dial.
@export var shovel_offset := Vector3(0.06, 0.0, 0.12):
	set(value):
		shovel_offset = value
		_apply_shovel_pose()
## Grip along the hand, blade out. Live dial.
@export var shovel_rot_deg := Vector3(-90.0, 0.0, 0.0):
	set(value):
		shovel_rot_deg = value
		_apply_shovel_pose()
@export_group("Dig Swing")
## Any UAL clip -- probed inventory (refresh this list if the animation pack swaps;
## probe_ual_anims.gd is the drift-check; has_animation fails safe).
@export_enum("A_TPose", "Crouch_Fwd", "Crouch_Idle", "Dance", "Death01", "Driving", "Fixing_Kneeling", "Hit_Chest", "Hit_Head", "Idle", "Idle_Talking", "Idle_Torch", "Interact", "Jog_Fwd", "Jump", "Jump_Land", "Jump_Start", "PickUp_Table", "Pistol_Aim_Down", "Pistol_Aim_Neutral", "Pistol_Aim_Up", "Pistol_Idle", "Pistol_Reload", "Pistol_Shoot", "Punch_Cross", "Punch_Jab", "Push", "Roll", "Sitting_Enter", "Sitting_Exit", "Sitting_Idle", "Sitting_Talking", "Spell_Simple_Enter", "Spell_Simple_Exit", "Spell_Simple_Idle", "Spell_Simple_Shoot", "Sprint", "Swim_Fwd", "Swim_Idle", "Sword_Attack", "Sword_Idle", "Walk", "Walk_Formal")
var swing_clip := "Sword_Attack"
## Playback speed; the strike should land inside the 0.45s window.
@export var swing_playback_speed := 1.0

# -- Geometry & identity (consts on purpose: structural, or law) ------

const STAND_EYE_HEIGHT := 1.6
const CROUCH_EYE_HEIGHT := 0.9
const STAND_CAPSULE_HEIGHT := 1.8
const CROUCH_CAPSULE_HEIGHT := 1.2
const MODEL_YAW := PI   # gltf guys face +Z; Godot forward is -Z. flip if he moonwalks.
const SWING_LOCK_CAP := 0.45   # mirrors dig.gd's SWING_COOLDOWN: animation never outwaits cadence
const JAB_ONE_IN := 256   # every swing rolls this: 1/N lands a secret Punch_Jab (ruling 2026-10-17)
const AVATAR_SCENE := "res://assets/meshes/quaternius/superhero_female/Superhero_Female_FullBody.gltf"
const ANIM_LIBRARY_SCENE := "res://assets/anims/quaternius/UAL1_Standard.glb"
const ANIM_FADE := 0.15
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
const UAL2_SCENE := "res://assets/animations/ual2/UAL2_Standard.glb"
const OUTFIT_SCENE := "res://assets/characters/outfits/Female_Ranger.gltf"

## Dress the character (0.0.3 ruling: Female Ranger now; full wardrobe is 0.0.7's).
@export var outfit_enabled := true
const HAND_BONE := "hand_r"   # universal rig right hand; the shovel rides it
const SHOVEL_MESH := "res://assets/meshes/quaternius/survival/Shovel.obj"   # OBJ: loads as Mesh, not a scene


## Clip names as the importer leaves them (it strips the glb's "_Loop"
## suffix, verified by scripts/tools/probe_ual_anims.gd).
const ANIM_IDLE := "Idle"
const ANIM_JOG := "Jog_Fwd"   # the run cycle (default gear at Q3 speed); rate = run_anim_speed
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
var jumped := false   # armed by a real jump (space, or a granted dig-jump); falls never arm it
var _pitch_angle := 0.0
var _swing_until_msec := 0   # while set, the swing clip owns the body; locomotion waits
var _shovel: MeshInstance3D   # the attached held shovel; the pose exports apply to it live
var _shovel_diagonal := 0.0   # raw mesh diagonal at attach; scale normalization divides by it
var _hair_pieces: Array[Node] = []   # attached hair pieces; hidden by the FP head tuck
var _eyebrows: MeshInstance3D   # the built-in Eyebrows mesh; hidden by the FP head tuck
var _skeleton: Skeleton3D   # the avatar's skeleton, cached at load
var _head_idx := -1   # the Head bone index; -1 until the avatar loads
var _ghost_skeleton: Skeleton3D   # the shadow ghost's skeleton; mirrors ours per frame
var _avatar_meshes: Array[MeshInstance3D] = []   # the real avatar's meshes; cast_shadow toggles with the tuck

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
	add_to_group("player")   # the HUD reads us by group; nothing set this before 0.0.2 (depth was pinned at 0.0)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	boom.add_excluded_object(get_rid())
	_apply_fp_near_plane()
	_apply_camera_mode()
	_load_avatar()
	set_physics_process(false)   # main.gd's loader re-enables us (dev_log #1)


## Loader handshake: the spawn column is meshed -- physics goes live.
func on_ground_ready() -> void:
	set_physics_process(true)


## Mouse + action routing: rig yaw, both-camera pitch, P flip, wheel zoom, Esc.
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rig.rotate_y(-event.relative.x * mouse_sens)   # mouse yaws the camera rig only
		_pitch_angle = clampf(_pitch_angle - event.relative.y * mouse_sens, -deg_to_rad(pitch_down_limit_deg), pitch_limit)
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
		velocity.y -= gravity * delta
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
		jumped = true
		DirtBus.player_noise.emit(1.4, 1)   # nobody is listening. yet.
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var want_crouch := Input.is_action_pressed("crouch")   # hold, not toggle (ruling)
	if want_crouch != crouching:
		_set_crouch(want_crouch)
	var speed := crouch_speed if crouching else (walk_speed if Input.is_action_pressed("walk") else run_speed)
	var dir := (rig.transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	move_and_slide()
	if is_on_floor():
		jumped = false   # landing disarms; only real jumps (space, dig-jump) arm it
	_update_facing(dir, delta)
	_update_fp_arm()
	_mirror_ghost_skeleton()
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
		mesh_root.rotation.y, target, minf(delta * body_turn_speed, 1.0))



## P flips first/third: cameras swap, body visible in both.
func _toggle_camera() -> void:
	third_person = not third_person
	_apply_camera_mode()


## Wheel: TP cranes the boom 1.5-8m; FP zooms FOV 50-90 (the brow/hair inspector).
func _zoom(direction: float) -> void:
	if third_person:
		boom.spring_length = clampf(
			boom.spring_length - direction * zoom_boom_step, boom_min, boom_max)
	else:
		fp_camera.fov = clampf(
			fp_camera.fov - direction * fov_step, fov_min, fov_max)


## The one place FP/TP state lands: current cameras per mode; body visible in both.
func _apply_camera_mode() -> void:
	fp_camera.current = not third_person
	tp_camera.current = third_person
	_update_head_tuck()


## The FP head tuck: local-view artifact only; per-instance, replication never sees it.
func _update_head_tuck() -> void:
	var tuck: bool = (not third_person) and fp_head_tuck
	if _skeleton != null and _head_idx != -1:
		_skeleton.set_bone_pose_scale(_head_idx, Vector3.ONE * (fp_head_tuck_scale if tuck else 1.0))
	for piece in _hair_pieces:
		piece.visible = not tuck
	if _eyebrows != null:
		_eyebrows.visible = not tuck


## Build the shadow ghost: a second avatar on render layer 2 whose skeleton mirrors ours (head tuck stripped).
func _build_shadow_ghost(avatar: Node3D) -> void:
	var ghost: Node3D = (load(AVATAR_SCENE) as PackedScene).instantiate()
	ghost.name = "ShadowGhost"
	ghost.rotation.y = MODEL_YAW   # the ghost needs the same facing flip as the real avatar
	mesh_root.add_child(ghost)
	var ghost_skeleton := _find_skeleton(ghost)
	if ghost_skeleton == null:
		ghost.queue_free()
		return
	for piece_path in HAIR_PIECES:
		_attach_hair_piece(ghost, piece_path, HAIR_PIECES[piece_path])
	_attach_outfit(ghost)   # the shadow wears clothes too
	var ghost_meshes: Array[MeshInstance3D] = []
	_collect_mesh_instances(ghost, ghost_meshes)
	for mesh_instance in ghost_meshes:
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY   # renders no color; casts always
	_ghost_skeleton = ghost_skeleton


## Mirror the ghost skeleton's poses from the real one, stripping the Head tuck scale (shadow keeps its head).
func _mirror_ghost_skeleton() -> void:
	if _ghost_skeleton == null or _skeleton == null:
		return
	for i in _skeleton.get_bone_count():
		var bone_name := _skeleton.get_bone_name(i)
		_ghost_skeleton.set_bone_pose_position(i, _skeleton.get_bone_pose_position(i))
		_ghost_skeleton.set_bone_pose_rotation(i, _skeleton.get_bone_pose_rotation(i))
		_ghost_skeleton.set_bone_pose_scale(i, Vector3.ONE if bone_name == HEAD_BONE else _skeleton.get_bone_pose_scale(i))


## Register UAL2 as a second library ("ual2/...") so future actions can play its clips.
func _register_ual2(anim_player: AnimationPlayer) -> void:
	var packed: PackedScene = load(UAL2_SCENE)
	if packed == null:
		return
	var temp := packed.instantiate()
	var found := temp.find_children("*", "AnimationPlayer", true, false)
	if found.is_empty():
		temp.free()
		return
	var lib: AnimationLibrary = (found[0] as AnimationPlayer).get_animation_library("")
	if lib != null and not anim_player.has_animation_library("ual2"):
		anim_player.add_animation_library("ual2", lib)
		print("player: UAL2 registered (%d clips under ual2/)" % lib.get_animation_list().size())
	temp.free()


## Wear the outfit: reparent its skinned meshes onto our skeleton (same bone names).
func _attach_outfit(avatar: Node) -> void:
	if not outfit_enabled:
		return
	var packed: PackedScene = load(OUTFIT_SCENE)
	if packed == null:
		push_warning("outfit: scene failed to load")
		return
	var skeleton := _find_skeleton(avatar)
	if skeleton == null:
		return
	var temp := packed.instantiate()
	var src_list := temp.find_children("*", "Skeleton3D", true, false)
	if src_list.is_empty():
		push_warning("outfit: no skeleton in source")
		temp.free()
		return
	var src := src_list[0] as Skeleton3D
	if src.get_bone_count() != skeleton.get_bone_count():
		push_warning("outfit: bone count mismatch (%d vs %d) -- skipping" % [src.get_bone_count(), skeleton.get_bone_count()])
		temp.free()
		return
	var host_meshes: Array[MeshInstance3D] = []
	_collect_mesh_instances(avatar, host_meshes)
	var host_layers := 1
	var host_shadow := GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if not host_meshes.is_empty():
		host_layers = host_meshes[0].layers
		host_shadow = host_meshes[0].cast_shadow   # the host's shadow policy (ghost-only shadows)
	var worn := 0
	for child in src.get_children():
		if child is MeshInstance3D:
			var mesh := child.duplicate() as MeshInstance3D
			skeleton.add_child(mesh)
			mesh.skeleton = NodePath("..")   # ride OUR skeleton: Quaternius standard rig, same bone names
			mesh.layers = host_layers
			mesh.cast_shadow = host_shadow
			worn += 1
	print("player: outfit worn (%d meshes)" % worn)
	temp.free()


## Hold-to-crouch: resize the capsule, drop the TP pivot; FP eye height is the slide's job.
func _set_crouch(on: bool) -> void:
	crouching = on
	var shape := collider.shape as CapsuleShape3D
	shape.height = CROUCH_CAPSULE_HEIGHT if on else STAND_CAPSULE_HEIGHT
	collider.position.y = (CROUCH_CAPSULE_HEIGHT if on else STAND_CAPSULE_HEIGHT) * 0.5
	pitch.position.y = CROUCH_EYE_HEIGHT if on else STAND_EYE_HEIGHT
	fp_eye.position.y = CROUCH_EYE_HEIGHT if on else STAND_EYE_HEIGHT   # the FP lens rides the head's height; the slides are gone
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
	_collect_mesh_instances(avatar, _avatar_meshes)
	for mesh in _avatar_meshes:
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF   # the ghost is the shadow's single source of truth (ruling 2026-10-17)
	for piece_path in HAIR_PIECES:
		_attach_hair_piece(avatar, piece_path, HAIR_PIECES[piece_path])
	_attach_outfit(avatar)
	_attach_shovel(avatar)
	var anim_player := _find_anim_player(avatar)
	if anim_player == null:
		anim_player = AnimationPlayer.new()
		avatar.add_child(anim_player)
	if _attach_universal_anims(anim_player) == 0:
		placeholder.visible = true
		return
	_register_ual2(anim_player)
	placeholder.visible = false
	_skeleton = _find_skeleton(avatar)
	_head_idx = _skeleton.find_bone(HEAD_BONE) if _skeleton != null else -1
	_update_head_tuck()
	_build_shadow_ghost(avatar)
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
		_eyebrows = mesh_instance
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
	_hair_pieces.append(piece)
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


## Held shovel: the Survival Pack OBJ on the right hand; AABB-normalized, pose by dials.
func _attach_shovel(avatar: Node) -> void:
	var shovel_mesh: Mesh = load(SHOVEL_MESH)
	if shovel_mesh == null:
		return
	var skeleton := _find_skeleton(avatar)
	if skeleton == null or skeleton.find_bone(HAND_BONE) == -1:
		return
	var attach := BoneAttachment3D.new()
	attach.bone_name = HAND_BONE
	skeleton.add_child(attach)
	var instance := MeshInstance3D.new()
	instance.mesh = shovel_mesh
	var diagonal := shovel_mesh.get_aabb().size.length()
	_shovel_diagonal = diagonal
	_shovel = instance
	attach.add_child(instance)
	_apply_shovel_pose()
	print("shovel: attached to %s (raw mesh diagonal %.2fm)" % [HAND_BONE, diagonal])


## Live-apply the shovel pose: the Held Shovel setters call this; no-op without a shovel.
func _apply_shovel_pose() -> void:
	if _shovel == null:
		return
	_shovel.position = shovel_offset
	_shovel.rotation_degrees = shovel_rot_deg
	if _shovel_diagonal > 0.001:
		_shovel.scale = Vector3.ONE * (shovel_target_length / _shovel_diagonal)


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


## FP camera collision: cast from the BODY CENTER along the view direction -- eye-origin rays fail inside walls.
func _update_fp_arm() -> void:
	var origin := global_position + Vector3(0.0, fp_eye.position.y, 0.0)
	var forward := -fp_eye.global_transform.basis.z
	var total := absf(fp_eye.position.z) + fp_arm_length
	var to := origin + forward * total
	var query := PhysicsRayQueryParameters3D.create(origin, to, -1, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	var reach := fp_arm_length
	if hit:
		var wall_dist: float = origin.distance_to(hit.position)
		reach = maxf(wall_dist - absf(fp_eye.position.z) - fp_wall_margin, 0.0)
	fp_camera.position = Vector3(0.0, 0.0, -reach)


## Boot: the FP near plane is wider than default so geometry clips cleanly.
func _apply_fp_near_plane() -> void:
	fp_camera.near = fp_near_plane


## The ray origin for the verb's sight: the head, crouch-aware by construction.
func aim_origin() -> Vector3:
	return fp_eye.global_position


## One cosmetic swing: chosen clip at export speed; 1-in-256 is a secret Punch_Jab.
func play_swing() -> void:
	var clip := swing_clip
	if randi_range(1, JAB_ONE_IN) == 1:
		clip = "Punch_Jab"
	var anim_player := _find_anim_player(mesh_root)
	if anim_player == null or not anim_player.has_animation(clip):
		return
	var anim := anim_player.get_animation(clip)
	var lock := minf(anim.length / maxf(swing_playback_speed, 0.01), SWING_LOCK_CAP)
	_swing_until_msec = Time.get_ticks_msec() + int(lock * 1000.0)
	anim_player.speed_scale = swing_playback_speed
	anim_player.play(clip, ANIM_FADE)
	anim_player.seek(0.0)


## dig.gd calls this on a granted dig-jump: a dig-jump is a jump (the chain law).
func notify_dig_jump() -> void:
	jumped = true


## Pick the clip from state (run/walk/crouch/jump) and crossfade; no-op without the library.
func _update_animation(moving: bool) -> void:
	var anim_player := _find_anim_player(mesh_root)
	if anim_player == null or not anim_player.has_animation(ANIM_IDLE):
		return
	if Time.get_ticks_msec() < _swing_until_msec:
		return   # a swing owns the body until its clip ends
	var next := ANIM_IDLE
	if not is_on_floor():
		next = ANIM_JUMP
	elif crouching:
		next = ANIM_CROUCH_MOVE if moving else ANIM_CROUCH_IDLE
	elif moving:
		next = ANIM_WALK if Input.is_action_pressed("walk") else ANIM_JOG
		# the Sprint clip is retired; Jog_Fwd is the run cycle
	if anim_player.current_animation != next and anim_player.has_animation(next):
		anim_player.play(next, ANIM_FADE)
	anim_player.speed_scale = _gear_scale(next, Vector2(velocity.x, velocity.z).length())


## Dynamic cadence: scale = ref_scale x speed / ref_speed per clip (vojtechstruhar.com technique); acceleration-ready.
func _gear_scale(clip: String, speed: float) -> float:
	if clip == ANIM_WALK:
		return walk_anim_ref_scale * speed / walk_anim_ref_speed
	if clip == ANIM_JOG:
		return run_anim_ref_scale * speed / run_anim_ref_speed
	if clip == ANIM_CROUCH_MOVE:
		return crouch_anim_ref_scale * speed / crouch_anim_ref_speed
	return 1.0
