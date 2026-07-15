extends Control

var value_label: Label

func _ready() -> void:
	value_label = $Panel/ScoreValue

func AddToScore(additional_value: int) -> void:
	var current_value := int(value_label.text)
	var new_value := current_value + additional_value
	value_label.text = str(new_value)

func Reset() -> void:
	value_label.text = str(0)
