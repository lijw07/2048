extends Polygon2D

var value: int = 0
var tilecolor: Color
var label: Label

func _ready() -> void:
	PlaySpawnAnimation()
	UpdateLabel()

func GetValue() -> int:
	return value

func SetValue(new_value: int) -> void:
	value = new_value
	UpdateLabel()
	UpdateColor()

func PlaySpawnAnimation() -> void:
	scale = Vector2(0, 0)
	position = position + Vector2(50, 50)

	var scale_anim := create_tween()
	var position_anim := create_tween()

	scale_anim.tween_property(self, "scale", Vector2(1, 1), 0.2)
	position_anim.tween_property(self, "position", position - Vector2(50, 50), 0.2)

func UpdateColor() -> void:
	match value:
		2: tilecolor = Color("eee3da")
		4: tilecolor = Color("eddfc8")
		8: tilecolor = Color("f2b178")
		16: tilecolor = Color("f59562")
		32: tilecolor = Color("f57c5f")
		64: tilecolor = Color("f65e3a")
		128: tilecolor = Color("edcf73")
		256: tilecolor = Color("edcc61")
		512: tilecolor = Color("edc750")
		1024: tilecolor = Color("edc53e")
		2048: tilecolor = Color("edc22d")

	color = tilecolor

func UpdateLabel() -> void:
	label = $Label
	label.text = str(value)
