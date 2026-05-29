extends Node

@export var ui_navigate: AudioStream
@export var ui_select: AudioStream
@export var ui_back: AudioStream
@export var ui_invalid: AudioStream
@export var round_start: AudioStream
@export var round_end: AudioStream
@export var ko_sound: AudioStream
@export var hit_sound: AudioStream
@export var match_win: AudioStream
@export var menu_music: AudioStream
@export var player_hit_sounds: Array[AudioStream] = []
@export var death_grunt: AudioStream

var sfx_player: AudioStreamPlayer = null
var music_player: AudioStreamPlayer = null

func _ready() -> void:
	sfx_player = AudioStreamPlayer.new()
	sfx_player.name = "SfxPlayer"
	sfx_player.bus = "Master"
	add_child(sfx_player)

	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.bus = "Master"
	music_player.volume_db = -6.0
	add_child(music_player)

func play_sfx(stream: AudioStream) -> void:
	if stream == null or sfx_player == null:
		return
	sfx_player.stream = stream
	sfx_player.play()

func play_music(stream: AudioStream, looped: bool = true) -> void:
	if music_player == null:
		return
	if stream == null:
		music_player.stop()
		return
	if music_player.stream == stream and music_player.playing:
		return
	music_player.stream = stream
	if music_player.stream is AudioStreamOggVorbis:
		music_player.stream.loop = looped
	elif music_player.stream is AudioStreamMP3:
		music_player.stream.loop = looped
	elif music_player.stream is AudioStreamWAV:
		music_player.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD if looped else AudioStreamWAV.LOOP_DISABLED
	music_player.play()

func stop_music() -> void:
	if music_player != null:
		music_player.stop()

func play_navigate() -> void:
	play_sfx(ui_navigate)

func play_select() -> void:
	play_sfx(ui_select)

func play_back() -> void:
	play_sfx(ui_back)

func play_invalid() -> void:
	play_sfx(ui_invalid)

func play_round_start() -> void:
	play_sfx(round_start)

func play_round_end() -> void:
	play_sfx(round_end)

func play_ko() -> void:
	play_sfx(ko_sound)

func play_hit() -> void:
	play_sfx(hit_sound)

func play_match_win() -> void:
	play_sfx(match_win)

func play_menu_music() -> void:
	play_music(menu_music)

func play_stream(stream: AudioStream, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	if stream == null:
		return

	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = "Master"
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

func play_random_player_hit() -> void:
	if player_hit_sounds.is_empty():
		return

	var valid_sounds: Array[AudioStream] = []
	for sound in player_hit_sounds:
		if sound != null:
			valid_sounds.append(sound)

	if valid_sounds.is_empty():
		return

	var index: int = randi_range(0, valid_sounds.size() - 1)
	play_sfx(valid_sounds[index])

func play_death_grunt() -> void:
	play_sfx(death_grunt)
