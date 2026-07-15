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
	add_child(player)
	return player

# Called when tiles slide on a valid move.
func PlayMove() -> void:
	move_sound.play()

# Called when two tiles combine into a doubled tile.
func PlayMerge() -> void:
	merge_sound.play()

# The following take a linear 0..1 level (1 = the sound's default loudness,
# 0 = muted) and are driven by the volume UI sliders.
func SetMoveVolume(level: float) -> void:
	apply_volume(move_sound, MOVE_BASE_DB, level)

func SetMergeVolume(level: float) -> void:
	apply_volume(merge_sound, MERGE_BASE_DB, level)

func apply_volume(player: AudioStreamPlayer, base_db: float, level: float) -> void:
	level = clampf(level, 0.0, 1.0)
	player.volume_db = -80.0 if level <= 0.0 else base_db + linear_to_db(level)
