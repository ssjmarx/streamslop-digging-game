## Overworld music, Minecraft-style: not always on. A random Pixabay track plays
## in full, fades its last 10s, then 1-3 minutes of silence -- and the runtime
## low-pass bus muffles by the dirt overhead (dug out the sky, music returns).
extends AudioStreamPlayer

# -- Config (tunables are exports -- GDD §13) ------

@export_group("BGM")
## The playlist; each cycle picks one at random (no immediate repeats).
@export var tracks: Array[String] = [
	"res://assets/music/pixabay/melodigne-exploration-310024.mp3",
	"res://assets/music/pixabay/alexgrohl-being-friendly-exploration-242687.mp3",
	"res://assets/music/noncombat/chill_lofi.ogg",
	"res://assets/music/noncombat/birds_lofi_chill.mp3",
	"res://assets/music/noncombat/calm_currents.mp3",
	"res://assets/music/noncombat/sunset_plains.ogg",
]
## Fade length; completes at the track's natural end if that comes first.
@export var fade_seconds := 10.0
## Silence bounds between tracks (seconds, randomized).
@export var silence_min_seconds := 60.0
@export var silence_max_seconds := 180.0
## Audible wallpaper, never a soundtrack.
@export var surface_db := -14.0
## Open-sky cutoff: effectively unfiltered.
@export var open_cutoff_hz := 20000.0
## Fully muffled: the whole ceiling of dirt between you and the sky.
@export var muffled_cutoff_hz := 500.0
## Dirt cells overhead that saturate the muffle.
@export var max_occlusion_cells := 6
## Cutoff approach speed (lerp fraction per second).
@export var filter_speed := 6.0

const SILENT_DB := -60.0
const TYPE_AIR := 0   # must match dirt_checker_generator
const BUS_NAME := "BGM"
const half_cell := Vector3(0.5, 0.5, 0.5)   # a voxel cell's center offset from its corner

enum State { SILENCE, PLAYING, FADING }

# -- State ------

var _filter: AudioEffectLowPassFilter
var _state: State = State.SILENCE
var _timer := 0.0
var _silence_total := 0.0
var _fade_start := 0.0
var _cutoff := 20000.0
var _last_track := -1


## Boot: build the BGM bus + low-pass effect, then start the cycle in silence.
func _ready() -> void:
	_filter = AudioEffectLowPassFilter.new()
	_filter.cutoff_hz = muffled_cutoff_hz
	var bus_index := AudioServer.bus_count
	AudioServer.add_bus()
	AudioServer.set_bus_name(bus_index, BUS_NAME)
	AudioServer.set_bus_send(bus_index, "Master")
	AudioServer.add_bus_effect(bus_index, _filter)
	bus = BUS_NAME
	volume_db = SILENT_DB
	_enter_silence()


## Per physics frame: state machine + steer the cutoff toward the muffle it earns.
func _physics_process(delta: float) -> void:
	_tick(delta)
	_update_filter(delta)


## The cycle: silence waits out its dice, a track plays and fades, repeat.
func _tick(delta: float) -> void:
	_timer += delta
	match _state:
		State.SILENCE:
			if _timer >= _silence_total:
				_start_track()
		State.PLAYING:
			if _timer >= _fade_start + fade_seconds:
				_enter_silence()   # fade complete (or natural end): true silence
			elif _timer >= _fade_start:
				volume_db = lerpf(surface_db, SILENT_DB, clampf((_timer - _fade_start) / fade_seconds, 0.0, 1.0))
			else:
				volume_db = lerpf(SILENT_DB, surface_db, clampf(_timer / fade_seconds, 0.0, 1.0))


## Pick a random track (no immediate repeats), anchor the fade, play.
func _start_track() -> void:
	if tracks.is_empty():
		return   # an empty playlist is a vow of silence
	var index := randi() % tracks.size()
	if tracks.size() > 1 and index == _last_track:
		index = (index + 1) % tracks.size()
	_last_track = index
	var track_stream: AudioStream = load(tracks[index])
	if track_stream == null:
		push_warning("bgm: track failed to load: " + tracks[index])
		_enter_silence()
		return
	if track_stream is AudioStreamMP3:
		(track_stream as AudioStreamMP3).loop = false   # the scheduler owns the clock
	self.stream = track_stream
	_fade_start = maxf(track_stream.get_length() - fade_seconds, 0.0)   # the whole track, then the tail
	_state = State.PLAYING
	_timer = 0.0
	volume_db = SILENT_DB
	play()


## Fade complete: true silence until the dice say otherwise.
func _enter_silence() -> void:
	stop()
	_state = State.SILENCE
	_timer = 0.0
	_silence_total = randf_range(silence_min_seconds, silence_max_seconds)
	volume_db = SILENT_DB


## Per physics frame: steer the cutoff toward the muffle the dirt overhead earns.
func _update_filter(delta: float) -> void:
	var occlusion := _dirt_overhead()
	var t := clampf(float(occlusion) / float(max_occlusion_cells), 0.0, 1.0)
	var target := muffled_cutoff_hz * pow(open_cutoff_hz / muffled_cutoff_hz, 1.0 - t)
	_cutoff = lerpf(_cutoff, target, clampf(filter_speed * delta, 0.0, 1.0))
	_filter.cutoff_hz = _cutoff


## Dirt cells in the column straight above the player's head, capped -- dug-out shafts read zero.
func _dirt_overhead() -> int:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	var terrain := get_tree().get_first_node_in_group("terrain") as VoxelTerrain
	if player == null or terrain == null:
		return 0
	var head := player.global_position
	var vt := terrain.get_voxel_tool()
	vt.channel = VoxelBuffer.CHANNEL_TYPE   # every read names its channel
	var count := 0
	for y in range(floori(head.y), 0):
		if count >= max_occlusion_cells:
			return count
		if vt.get_voxel(Vector3i(floori(head.x), y, floori(head.z))) != TYPE_AIR:
			count += 1
	return count
