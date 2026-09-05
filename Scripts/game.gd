extends Node

const BOARD_SIZE := 475.0
const SCORE_SIZE := Vector2(260.0, 64.0)
const VOLUME_SIZE := Vector2(282.0, 156.0)
const OVERLAY_LABEL_SIZE := Vector2(280.0, 50.0)
const OVERLAY_BUTTON_SIZE := Vector2(220.0, 56.0)
const GAP := 24.0
const OUTER_MARGIN := 24.0
const WIDE_ASPECT := 1.2
const MIN_SCALE := 0.3
const SHOW_INPUT_DEBUG := true
const BUILD_STAMP := "swipe-debug-1"
const MAX_SCALE := 3.0

var score
var grid
var overlay

var background: Polygon2D
var volume_controls: Control
var overlay_background: Polygon2D
var overlay_label: Label
var overlay_button: Button

var volume_size := VOLUME_SIZE
var board_scale := 1.0
var debug_label: Label = null

func _ready() -> void:
	score = $Score
	grid = $Grid
	overlay = $GameOverOverlay

	background = $Polygon2D
	volume_controls = $VolumeControls
	overlay_background = $GameOverOverlay/Polygon2D
	overlay_label = $GameOverOverlay/Label
	overlay_button = $GameOverOverlay/Button

	for c in [score, volume_controls, overlay_label, overlay_button]:
		c.set_anchors_preset(Control.PRESET_TOP_LEFT)
		c.grow_horizontal = Control.GROW_DIRECTION_END
		c.grow_vertical = Control.GROW_DIRECTION_END

	score.size = SCORE_SIZE
	var volume_minimum := volume_controls.get_combined_minimum_size()
	volume_size = Vector2(
		maxf(VOLUME_SIZE.x, volume_minimum.x),
		maxf(VOLUME_SIZE.y, volume_minimum.y)
	)
	volume_controls.size = volume_size
	overlay_label.size = OVERLAY_LABEL_SIZE
	overlay_button.size = OVERLAY_BUTTON_SIZE

	grid.swipe_blockers = [volume_controls]

	if SHOW_INPUT_DEBUG:
		debug_label = Label.new()
		debug_label.name = "InputDebug"
		debug_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		debug_label.add_theme_font_size_override("font_size", 30)
		debug_label.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))
		debug_label.text = BUILD_STAMP
		add_child(debug_label)
		grid.debug_label = debug_label
		grid.debug_prefix = BUILD_STAMP
		grid.DebugRefresh()

	get_viewport().size_changed.connect(UpdateLayout)
	UpdateLayout()

func UpdateLayout() -> void:
	var vp: Vector2 = get_viewport().get_visible_rect().size

	if vp.x <= 0.0 or vp.y <= 0.0:
		return

	CoverViewport(background, vp)
	CoverViewport(overlay_background, vp)

	if vp.x / vp.y >= WIDE_ASPECT:
		LayoutWide(vp)
	else:
		LayoutTall(vp)

	PlaceOverlay(vp)

	if debug_label != null:
		debug_label.scale = Vector2(board_scale, board_scale)
		debug_label.position = Vector2(GAP, GAP) * board_scale

func LayoutTall(vp: Vector2) -> void:
	var stack_height := SCORE_SIZE.y + GAP + BOARD_SIZE + GAP + volume_size.y

	var s := FitScale(vp, BOARD_SIZE, stack_height)
	var top := (vp.y - stack_height * s) * 0.5

	PlaceScore(Vector2((vp.x - SCORE_SIZE.x * s) * 0.5, top), s)
	PlaceBoard(Vector2((vp.x - BOARD_SIZE * s) * 0.5, top + (SCORE_SIZE.y + GAP) * s), s)
	PlaceVolume(Vector2(
		(vp.x - volume_size.x * s) * 0.5,
		top + (SCORE_SIZE.y + GAP + BOARD_SIZE + GAP) * s
	), s)

func LayoutWide(vp: Vector2) -> void:
	var side_width := maxf(SCORE_SIZE.x, volume_size.x)
	var group_width := BOARD_SIZE + GAP + side_width

	var s := FitScale(vp, group_width, BOARD_SIZE)
	var left := (vp.x - group_width * s) * 0.5
	var top := (vp.y - BOARD_SIZE * s) * 0.5
	var column_left := left + (BOARD_SIZE + GAP) * s

	PlaceBoard(Vector2(left, top), s)
	PlaceScore(Vector2(column_left, top), s)
	PlaceVolume(Vector2(column_left, top + (BOARD_SIZE - volume_size.y) * s), s)

func FitScale(vp: Vector2, content_width: float, content_height: float) -> float:
	return clampf(minf(
		vp.x / (content_width + OUTER_MARGIN * 2.0),
		vp.y / (content_height + OUTER_MARGIN * 2.0)
	), MIN_SCALE, MAX_SCALE)

func PlaceBoard(pos: Vector2, s: float) -> void:
	grid.position = pos
	grid.scale = Vector2(s, s)
	board_scale = s

func PlaceScore(pos: Vector2, s: float) -> void:
	score.position = pos
	score.scale = Vector2(s, s)

func PlaceVolume(pos: Vector2, s: float) -> void:
	volume_controls.position = pos
	volume_controls.scale = Vector2(s, s)

func PlaceOverlay(_vp: Vector2) -> void:
	var s := board_scale
	var board_center: Vector2 = grid.position + Vector2(BOARD_SIZE, BOARD_SIZE) * s * 0.5

	overlay_label.scale = Vector2(s, s)
	overlay_label.position = board_center - Vector2(
		OVERLAY_LABEL_SIZE.x * 0.5,
		OVERLAY_LABEL_SIZE.y + GAP * 0.5
	) * s

	overlay_button.scale = Vector2(s, s)
	overlay_button.position = board_center + Vector2(
		-OVERLAY_BUTTON_SIZE.x * 0.5,
		GAP * 0.5
	) * s

func CoverViewport(poly: Polygon2D, vp: Vector2) -> void:
	poly.polygon = PackedVector2Array([
		Vector2.ZERO,
		Vector2(vp.x, 0.0),
		vp,
		Vector2(0.0, vp.y)
	])

func GameOver() -> void:
	overlay.visible = true

func Restart() -> void:
	grid.Reset()
	score.Reset()
	overlay.visible = false
