## dig.gd -- THE VERB. One button, forever: the sight's ray (aim.gd) -> terrain =
## erase sphere (tier width only) + dirt + clang; prop = impulse + clang, no dirt;
## miss = whiff; airborne dirt hits grant dig-jump. The 0.0.9 seam lands in strike().
extends Node3D

# -- Config (law is const; tunables are exports -- GDD §13) ------

const DIG_RANGE := 5.0   # Appendix B const (ruling 2026-10-17: 10 -> 5). forever.
const SWING_COOLDOWN := 0.45   # seconds. never tuned, never upgraded, never buffed.
const CHAIN_GRACE := 0.1   # seconds beyond the cooldown that still count as spam-chain

@export_group("Dig Feel")
## Upward grant when a jump-armed airborne swing hits dirt (Q3 jump = 8.67).
@export var dig_jump_velocity := 8.67
## Impulse on physics props (the stop sign): delta-v = power / mass.
@export var knock_power := 50.0
## Physics frames between the FIRST click of a chain and its strike; follow-ups
## cancel into each other instantly. Fighting-game startup (ruling 2026-10-17).
@export var startup_frames := 9

# -- State ------

var _cooldown := 0.0
var _pending_frames := -1   # >=0: physics frames left before a chain's first strike resolves
var _last_swing_msec := -100000   # far past: the session's first click pays startup

@onready var _body: Node = get_parent()   # the player CharacterBody3D; duck-typed on purpose
@onready var _aim: Node = $Aim   # the sight: one ray shared by the swing and the instruments
@onready var _diglog: Node = get_tree().get_first_node_in_group("diglog")   # the save file's writer
@onready var _clang: AudioStreamPlayer3D = $Clang
@onready var _dig_sfx: AudioStreamPlayer = $HitDig
@onready var _whiff: AudioStreamPlayer = $Whiff


## Boot: the sight learns the law range from its owner (one source of truth).
func _ready() -> void:
	_aim.swing_range = DIG_RANGE
	_aim.body = _body


## Per physics frame: cooldown + startup countdown; LMB chains swings at the frozen cadence.
func _physics_process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	if _pending_frames >= 0:
		_pending_frames -= 1
		if _pending_frames < 0:
			_resolve_swing()   # the windup is paid: the chain's first strike lands
		return   # no new swings while the startup window runs
	if _cooldown == 0.0 and Input.is_action_pressed("dig"):
		_swing()


## One swing: clip starts now -- startup on the first click of a chain; follow-ups cancel into the hit.
func _swing() -> void:
	_cooldown = SWING_COOLDOWN
	_body.play_swing()
	var now := Time.get_ticks_msec()
	if now - _last_swing_msec <= int((SWING_COOLDOWN + CHAIN_GRACE) * 1000.0):
		_resolve_swing()   # chain follow-up: cancels into the hit
	elif startup_frames <= 0:
		_resolve_swing()
	else:
		_pending_frames = startup_frames   # pay the windup
	_last_swing_msec = now


## The strike itself: ONE sight query, first hit wins -- the DigAuthority shape.
func _resolve_swing() -> void:
	var hit: Dictionary = _aim.swing_query(DIG_RANGE)
	if hit.is_empty():
		_whiff.play()
	elif hit.collider is RigidBody3D:
		_knock_prop(hit)
	elif hit.collider is VoxelTerrain:
		_strike(hit)
	else:
		_whiff.play()


## Props take the point impulse and the clang (GDD §8: one audio to rule them all); no dirt.
func _knock_prop(hit: Dictionary) -> void:
	_clang.play()
	var prop := hit.collider as RigidBody3D
	if prop.freeze:
		return   # the fossil refuses until the dirt has let go of it
	prop.apply_impulse(-Vector3(hit.normal) * knock_power, hit.position - prop.global_position)


## Strike: erase exactly the sight's targeting array; dirt count is exact; dig-jump lands here.
func _strike(hit: Dictionary) -> void:
	_dig_sfx.play()
	_clang.play()
	var terrain := hit.collider as VoxelTerrain
	var cells: Array[Vector3i] = _aim.targeted_voxels(hit.position, hit.radius)
	var vt := terrain.get_voxel_tool()
	vt.channel = VoxelBuffer.CHANNEL_TYPE   # every write names its channel
	for cell in cells:
		vt.set_voxel(cell, 0)
	var amount := cells.size()
	var depth: float = hit.position.y   # negative below the surface, like a scoreboard
	GameState.dirt += amount
	GameState.best_depth = minf(GameState.best_depth, depth)
	DirtBus.dirt_dug.emit(amount, _floor_voxel(hit.position), depth, 1)
	DirtBus.depth_changed.emit(depth, 1)
	_diglog.append_sphere(hit.position, hit.radius)
	if not _body.is_on_floor() and _body.jumped:
		_body.velocity.y = maxf(_body.velocity.y, dig_jump_velocity)   # flight is bounded by dirt
		_body.notify_dig_jump()   # a dig-jump is a jump: the chain arms the next one


## Floor the hit point onto the voxel grid: bus + diglog positions stay integral.
func _floor_voxel(p: Vector3) -> Vector3i:
	return Vector3i(floori(p.x), floori(p.y), floori(p.z))
