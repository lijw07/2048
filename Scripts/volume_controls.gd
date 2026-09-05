extends PanelContainer

var audio

func _ready() -> void:
	audio = get_node("../Audio")

	hook_slider("%MoveSlider", audio.SetMoveVolume)
	hook_slider("%MergeSlider", audio.SetMergeVolume)

func hook_slider(path: String, setter: Callable) -> void:
	var slider: HSlider = get_node(path)
	slider.value_changed.connect(setter)
	setter.call(slider.value)
