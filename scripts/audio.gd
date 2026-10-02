class_name MindAudio
extends Node
var enabled_sfx := true
var enabled_music := true
var resume_position := 0.0
var music: AudioStreamPlayer
var players: Array[AudioStreamPlayer] = []
var sounds: Dictionary = {}
var cursor := 0
func _ready() -> void:
	for name in ["rotate","button","connect","target","complete"]: sounds[name] = load("res://assets/audio/%s.wav" % name)
	for i in 6:
		var p := AudioStreamPlayer.new(); p.playback_type = AudioServer.PLAYBACK_TYPE_STREAM; p.volume_db = -8; add_child(p); players.append(p)
	music = AudioStreamPlayer.new(); music.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	var stream: AudioStreamWAV = load("res://assets/audio/ambience.wav")
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = int(stream.get_length() * stream.mix_rate)
	music.stream = stream; music.volume_db = -9; add_child(music)
func configure(settings: Dictionary) -> void:
	enabled_sfx = settings.sfx
	enabled_music = settings.music
	if settings.music and DisplayServer.get_name() != "headless" and not music.playing: music.play()
	elif not settings.music: music.stop()
func play(name: String) -> void:
	if not enabled_sfx or not sounds.has(name) or DisplayServer.get_name() == "headless": return
	var p := players[cursor]; cursor = (cursor+1)%players.size(); p.stream = sounds[name]; p.play()
func suspend() -> void:
	resume_position = music.get_playback_position()
	music.stop()
	for p in players: p.stop()
func resume() -> void:
	if enabled_music and not music.playing and DisplayServer.get_name() != "headless": music.play(resume_position)
func release_streams() -> void:
	music.stop(); music.stream = null
	for p in players: p.stop(); p.stream = null
	sounds.clear(); players.clear()

func _exit_tree() -> void:
	release_streams()
