extends Node2D

signal ScoreUpdate(additional_points: int)
signal GameOver()
signal Moved()
signal Merged()

var grid: Array = []
var scene_tile: PackedScene

const SWIPE_THRESHOLD := 40.0

var _touch_index: int = -1
var _touch_start: Vector2 = Vector2.ZERO
var _swipe_handled: bool = false

var swipe_blockers: Array = []

var debug_label: Label = null
var debug_prefix: String = ""
var _debug_touches: int = 0
var _debug_drags: int = 0
var _debug_last: String = "-"

func _ready() -> void:
	scene_tile = load("res://Prefabs/tile.tscn")
	grid = _make_empty_grid()
	PopulateStartingTiles()

func _make_empty_grid() -> Array:
	var g := []
	for x in range(4):
		var col := []
		for y in range(4):
			col.append(null)
		g.append(col)
	return g

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_debug_touches += 1
			if _touch_index == -1 and not _PointerOverUI(event.position):
				_touch_index = event.index
				_touch_start = event.position
				_swipe_handled = false
			elif _touch_index != -1:
				_debug_last = "ignored: 2nd finger"
			else:
				_debug_last = "ignored: on UI"
			DebugRefresh()
		elif event.index == _touch_index:
			if not _swipe_handled:
				_TrySwipe(event.position - _touch_start)
			_touch_index = -1
			DebugRefresh()
		return

	if event is InputEventScreenDrag:
		_debug_drags += 1
		if event.index == _touch_index and not _swipe_handled:
			_TrySwipe(event.position - _touch_start)
		DebugRefresh()
		return

	var direction := ""

	if event.is_action_pressed("up"):
		direction = "up"
	elif event.is_action_pressed("down"):
		direction = "down"
	elif event.is_action_pressed("left"):
		direction = "left"
	elif event.is_action_pressed("right"):
		direction = "right"

	if direction != "":
		_Move(direction)

func _PointerOverUI(pos: Vector2) -> bool:
	for c in swipe_blockers:
		if c != null and c.visible:
			var r := Rect2(c.global_position, c.size * c.scale)
			if r.has_point(pos):
				return true
	return false

func _TrySwipe(delta: Vector2) -> void:
	if delta.length() < SWIPE_THRESHOLD:
		_debug_last = "short %.0f,%.0f (need %d)" % [delta.x, delta.y, int(SWIPE_THRESHOLD)]
		return

	_swipe_handled = true

	var direction := ""
	if absf(delta.x) > absf(delta.y):
		direction = "right" if delta.x > 0.0 else "left"
	else:
		direction = "down" if delta.y > 0.0 else "up"

	_debug_last = "SWIPE %s (%.0f,%.0f)" % [direction, delta.x, delta.y]
	_Move(direction)

func DebugRefresh() -> void:
	if debug_label == null:
		return
	var vp: Vector2 = get_viewport().get_visible_rect().size
	debug_label.text = "%s\nvp %d x %d\ntouch %d  drag %d\n%s" % [
		debug_prefix, int(vp.x), int(vp.y), _debug_touches, _debug_drags, _debug_last
	]

func _Move(direction: String) -> void:
	if MoveTiles(direction):
		SpawnRandomTile()

func MoveTiles(direction: String) -> bool:
	var movement_occurred := false

	var is_horizontal := direction == "left" or direction == "right"
	var is_reverse := direction == "up" or direction == "left"

	var merge_coords := {}
	var original_positions := {}

	var points_scored := 0

	for i in range(4):
		var tiles: Array = []

		for j in range(4):
			var x: int = ((3 - j) if is_reverse else j) if is_horizontal else i
			var y: int = i if is_horizontal else ((3 - j) if is_reverse else j)

			if grid[x][y] != null:
				original_positions[grid[x][y]] = Vector2(x, y)
				tiles.append(grid[x][y])
				grid[x][y] = null

		var new_index := 0 if is_reverse else 3

		while tiles.size() > 0:
			var current = tiles.pop_back()
			var next = tiles.back() if tiles.size() > 0 else null
			var merged = null

			if next != null and current.GetValue() == next.GetValue():
				movement_occurred = true

				points_scored += current.GetValue() * 2

				merged = tiles.pop_back()
				current.SetValue(current.GetValue() * 2)

			if is_horizontal:
				grid[new_index][i] = current
				if merged != null:
					merge_coords[merged] = ArrayToTileCoords(Vector2(new_index, i))
			else:
				grid[i][new_index] = current
				if merged != null:
					merge_coords[merged] = ArrayToTileCoords(Vector2(i, new_index))

			new_index += 1 if is_reverse else -1

	for t in original_positions:
		var coords: Vector2 = original_positions[t]
		if grid[int(coords.x)][int(coords.y)] != t:
			movement_occurred = true
			break

	for x in range(4):
		for y in range(4):
			if grid[x][y] != null:
				var t = grid[x][y]
				var tween = t.create_tween()
				tween.tween_property(
					t,
					"position",
					ArrayToTileCoords(Vector2(x, y)),
					0.1
				)

	for t in merge_coords:
		var coords: Vector2 = merge_coords[t]
		var tween = t.create_tween()
		tween.tween_property(t,
							"position",
							coords,
							0.1)
		tween.tween_callback(t.queue_free)

	ScoreUpdate.emit(points_scored)

	if movement_occurred:
		Moved.emit()
	if merge_coords.size() > 0:
		Merged.emit()

	if CheckGameOver():
		GameOver.emit()

	return movement_occurred

func SpawnRandomTile() -> void:
	var spaces: Array = []

	for x in range(4):
		for y in range(4):
			if grid[x][y] == null:
				spaces.append(Vector2i(x, y))

	if spaces.size() > 0:
		var selection := randi_range(0, spaces.size() - 1)
		SpawnTile(spaces[selection].x, spaces[selection].y)

func SpawnTile(x: int, y: int) -> void:
	var new_tile = scene_tile.instantiate()
	new_tile.position = ArrayToTileCoords(Vector2(x, y))

	var spawn4 := randi_range(0, 9)
	var value := 4 if spawn4 > 7 else 2
	new_tile.SetValue(value)

	grid[x][y] = new_tile
	add_child(new_tile)

func ArrayToTileCoords(array_coords: Vector2) -> Vector2:
	return Vector2(array_coords.x * 115 + 15, array_coords.y * 115 + 15)

func PopulateStartingTiles() -> void:
	var tile1coords := Vector2(randi_range(0, 3), randi_range(0, 3))
	var tile2coords := Vector2(randi_range(0, 3), randi_range(0, 3))

	while tile1coords.x == tile2coords.x and tile1coords.y == tile2coords.y:
		tile1coords = Vector2(randi_range(0, 3), randi_range(0, 3))
		tile2coords = Vector2(randi_range(0, 3), randi_range(0, 3))

	var t1 = scene_tile.instantiate()
	t1.position = ArrayToTileCoords(tile1coords)
	t1.SetValue(2)
	add_child(t1)

	var t2 = scene_tile.instantiate()
	t2.position = ArrayToTileCoords(tile2coords)
	t2.SetValue(2)
	add_child(t2)

	grid[int(tile1coords.x)][int(tile1coords.y)] = t1
	grid[int(tile2coords.x)][int(tile2coords.y)] = t2

func CheckGameOver() -> bool:
	for x in range(4):
		for y in range(4):
			if grid[x][y] == null:
				return false
			else:
				var adjacent_positions := [
					Vector2i(x + 1, y),
					Vector2i(x - 1, y),
					Vector2i(x, y + 1),
					Vector2i(x, y - 1),
				]

				for p in adjacent_positions:
					if p.x >= 0 and p.x < 4 and p.y >= 0 and p.y < 4:
						if grid[p.x][p.y] == null:
							return false
						if grid[x][y].GetValue() == grid[p.x][p.y].GetValue():
							return false

	return true

func Reset() -> void:
	for x in range(4):
		for y in range(4):
			if grid[x][y] != null:
				grid[x][y].queue_free()
				grid[x][y] = null

	PopulateStartingTiles()
