## ambience.gd -- the world's two ambiences: the meadow above, the grotto below.
## Beds loop always-on, crossfaded by DEPTH (not the sky ray); one-shots fire on
## random timers from the pool your depth earns. The layered kit waits in staging.
extends Node3D

# -- Config (tunables are exports -- GDD §13) ------

@export_group("Ambience")
## Surface bed mix: looped, always running; fades out with depth.
@export var surface_beds: Array[String] = [
	"res://assets/sfx/pixabay/dragon-studio-wind-rustling-grass-339094.mp3",
	"res://assets/sfx/pixabay/zehendrew-birds-chirping-calm-173695.mp3",
	"res://assets/sfx/pixabay/freesound_community-leaves-rustling-14633.mp3",
]
## Underground bed mix: looped, always running; fades in with depth.
@export var underground_beds: Array[String] = [
	"res://assets/sfx/pixabay/freesound_community-low-hum-14645.mp3",
	"res://assets/sfx/pixabay/alex_jauk-cavewind-ambience-271124.mp3",
]
## One-shot pool while shallow (random timer).
@export var surface_oneshots: Array[String] = [
	"res://assets/sfx/pixabay/freesound_community-dove-calling-71793.mp3",
	"res://assets/sfx/pixabay/alex_jauk-distant-owl-hooting-195966.mp3",
	"res://assets/sfx/pixabay/subhamita-cuckoo-sound-effect-01-326777.mp3",
]
## One-shot pool while deep.
@export var underground_oneshots: Array[String] = [
	"res://assets/sfx/pixabay/freesound_community-water-drip-45622.mp3",
	"res://assets/sfx/pixabay/alex_jauk-waterdrops-cave-echo-sounds-230896.mp3",
	"res://assets/sfx/pixabay/freesound_community-rock-in-water-splash-plop-2-88903.mp3",
	"res://assets/sfx/pixabay/the-vampires-monster-bat-chirping-type-1-354288.mp3",
	"res://assets/sfx/pixabay/dragon-studio-bird-wings-463212.mp3",
	"res://assets/sfx/pixabay/freesound_community-mouse-36220.mp3",
]
## Depth over which the surface mix fades into the grotto mix (meters).
@export var blend_depth := 10.0
## Peak bed volume.
@export var bed_volume_db := -22.0
## Peak one-shot volume.
@export var oneshot_volume_db := -16.0
## One-shot dice (seconds).
@export var oneshot_min_gap := 12.0
@export var oneshot_max_gap := 45.0

const SILENT_DB := -60.0

# -- State ------

var _surface_players: Array[AudioStreamPlayer] = []
var _underground_players: Array[AudioStreamPlayer] = []
var _oneshot_player: AudioStreamPlayer
var _oneshot_timer := 0.0
var _shallow := true


## Boot: build the bed players (looped, always-on) and arm the one-shot dice.
func _ready() -> void:
	_build_beds(surface_beds, _surface_players)
	_build_beds(underground_beds, _underground_players)
	_oneshot_player = AudioStreamPlayer.new()
	_oneshot_player.volume_db = oneshot_volume_db
	add_child(_oneshot_player)
	_oneshot_timer = randf_range(oneshot_min_gap, oneshot_max_gap)


## Build the bed players from paths: looped, always-on, silent until the crossfade speaks.
func _build_beds(paths: Array[String], out: Array[AudioStreamPlayer]) -> void:
	for path in paths:
		var bed_stream: AudioStream = load(path)
		if bed_stream == null:
			push_warning("ambience: bed failed to load: " + path)
			continue
		if bed_stream is AudioStreamMP3:
			(bed_stream as AudioStreamMP3).loop = true   # beds run forever
		var player := AudioStreamPlayer.new()
		player.stream = bed_stream
		player.volume_db = SILENT_DB
		add_child(player)
		player.play()
		out.append(player)


## Per physics frame: depth crossfade + one-shot dice.
func _physics_process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		return
	var t: float = clampf(-player.global_position.y / blend_depth, 0.0, 1.0)
	_fade_beds(t)
	_shallow = t < 0.5
	_oneshot_timer -= delta
	if _oneshot_timer <= 0.0:
		_fire_oneshot()
		_oneshot_timer = randf_range(oneshot_min_gap, oneshot_max_gap)


## Bed volumes for this depth: meadow fades down, grotto fades up, t = depth blend.
func _fade_beds(t: float) -> void:
	var surface_level := lerpf(bed_volume_db, SILENT_DB, t)
	var underground_level := lerpf(SILENT_DB, bed_volume_db, t)
	for p in _surface_players:
		p.volume_db = surface_level
	for p in _underground_players:
		p.volume_db = underground_level


## Fire one random shot from the pool this depth earns (shallow meadow, deep grotto).
func _fire_oneshot() -> void:
	var pool := surface_oneshots if _shallow else underground_oneshots
	if pool.is_empty():
		return
	var shot_stream: AudioStream = load(pool[randi() % pool.size()])
	if shot_stream == null:
		return
	_oneshot_player.stream = shot_stream
	_oneshot_player.volume_db = oneshot_volume_db
	_oneshot_player.play()
