extends Node

var score
var grid
var overlay

func _ready() -> void:
	score = $Score
	grid = $Grid
	overlay = $GameOverOverlay

func GameOver() -> void:
	overlay.visible = true

func Restart() -> void:
	grid.Reset()
	score.Reset()
	overlay.visible = false
