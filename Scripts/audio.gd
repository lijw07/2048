extends Node

const MOVE_BASE_DB := -6.0
const MERGE_BASE_DB := -3.0

var move_sound: AudioStreamPlayer
var merge_sound: AudioStreamPlayer

func _ready() -> void:
	move_sound = create_player("res://Audio/move.wav", MOVE_BASE_DB)
	merge_sound = create_player("res://Audio/merge.wav", MERGE_BASE_DB)

func create_player(stream_path: String, volume_db: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = load(stream_path)
	player.volume_db = volume_db
	player.max_polyphony = 4
	add_child(player)
	return player

func PlayMove() -> void:
	move_sound.play()

func PlayMerge() -> void:
	merge_sound.play()

func SetMoveVolume(level: float) -> void:
	apply_volume(move_sound, MOVE_BASE_DB, level)

func SetMergeVolume(level: float) -> void:
	apply_volume(merge_sound, MERGE_BASE_DB, level)

func apply_volume(player: AudioStreamPlayer, base_db: float, level: float) -> void:
	level = clampf(level, 0.0, 1.0)
	player.volume_db = -80.0 if level <= 0.0 else base_db + linear_to_db(level)
