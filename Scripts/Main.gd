extends CenterContainer

enum { STOPPED, PLAYING, PAUSED, STOP, PLAY, PAUSE }
enum { ROTATE_LEFT, ROTATE_RIGHT }

const DISABLED = true
const ENABLED = false
const MIN_AUDIO = -24
const START_POS = 5
const END_POS = 25
const TICK_SPEED = 1.0
const FAST_MULTIPLE = 10
const MAX_LEVEL = 100
const WAIT_TIME = 0.15
const REPEAT_DELAY = 0.05
const FILE_NAME = "user://tetris.json"

var gui
var state = STOPPED
var music_position = 0.0
var grid = []
var cols
var shape: ShapeData
var next_shape: ShapeData
var pos = 0
var count = 0
var bonus = 0


func _ready():
	gui = $Control/GUI
	gui.connect("button_pressed", self, "_button_pressed")
	gui.set_button_states(ENABLED)
	gui.set_button_state("PauseBtn", DISABLED)
	cols = gui.grid.get_columns()
	gui.reset_stats()
	load_game()
	randomize()


func clear_grid():
	grid.clear()
	grid.resize(gui.grid.get_child_count())
	for i in grid.size():
		grid[i] = false
	gui.clear_all_cells()


func move_shape(new_pos, dir = null):
	remove_shape_from_grid()
	dir = rotate(dir)
	var ok = place_shape(new_pos)
	if ok:
		pos = new_pos
	else:
		rotate(dir)
	add_shape_to_grid()
	return ok


func rotate(dir):
	match dir:
		ROTATE_LEFT:
			shape.rotate_left()
			dir = ROTATE_RIGHT
		ROTATE_RIGHT:
			shape.rotate_right()
			dir = ROTATE_LEFT
	return dir


func add_shape_to_grid():
	place_shape(pos, true, false, shape.color)


func remove_shape_from_grid():
	place_shape(pos, true)


func lock_shape_to_grid():
	place_shape(pos, false, true)
	

func place_shape(index, add_tiles = false, lock = false, color = Color(0)):
	var ok = true
	var size = shape.coords.size()
	var offset = shape.coords[0]
	var y = 0
	while y < size and ok:
		for x in size:
			if shape.grid[y][x]:
				var grid_pos = index + (y + offset) * cols + x + offset
				# print(grid_pos)
				if lock:
					grid[grid_pos] = true
				else:
					var gx = index % cols + x + offset
					if gx < 0 or gx >= cols or grid_pos >= grid.size() or grid_pos >= 0 and grid[grid_pos]:
						ok = !ok
						break
					if add_tiles and grid_pos >= 0:
						gui.grid.get_child(grid_pos).modulate = color
		y += 1
	return ok


func _button_pressed(button_name):
	match button_name:
		"NewGameBtn":
			gui.set_button_states(DISABLED)
			gui.set_button_state("PauseBtn", ENABLED)
			_start_game()
		"PauseBtn":
			if state == PLAYING:
				gui.set_button_text("PauseBtn", "Resume")
				state = PAUSED
				pause()
				_music(PAUSE)
			else:
				gui.set_button_text("PauseBtn", "Pause")
				state = PLAYING
				pause(false)
				_music(PLAY)
		"MusicBtn":
			if state == PLAYING:
				if gui.music > MIN_AUDIO:
					_music(PLAY)
				else:
					_music(STOP)
		"SfxBtn":
			if gui.sfx > MIN_AUDIO:
				_sfx(PLAY)
			else:
				_sfx(STOP)
		"AboutBtn":
			gui.set_button_state("AboutBtn", DISABLED)


func _start_game():
	print("New game")
	state = PLAYING
	music_position = 0.0
	_music(PLAY)
	clear_grid()
	gui.reset_stats(gui.high_score)
	new_shape()


func new_shape():
	if next_shape:
		shape = next_shape
	else:
		shape = Blocks.get_shape()
	next_shape = Blocks.get_shape()
	gui.set_next_shape(next_shape)
	pos = START_POS
	add_shape_to_grid()
	normal_drop()
	level_up()


func _input(event):
	if event.is_action_pressed("ui_page_up"):
		increase_level()
	if event.is_action_pressed("ui_down"):
		bonus = 2
		soft_drop()
	if event.is_action_released("ui_down"):
		bonus = 0
		normal_drop()
	if event.is_action_pressed("ui_accept"):
		hard_drop()
	if event.is_action_pressed("ui_left"):
		move_left()
		$LeftTimer.start(WAIT_TIME)
	if event.is_action_released("ui_left"):
		$LeftTimer.stop()
	if event.is_action_pressed("ui_right"):
		move_right()
		$RightTimer.start(WAIT_TIME)
	if event.is_action_released("ui_right"):
		$RightTimer.stop()
	if event.is_action_pressed("ui_up"):
		if event.shift:
			move_shape(pos, ROTATE_RIGHT)
		else:
			move_shape(pos, ROTATE_LEFT)
	if event.is_action_pressed("ui_cancel"):
		_game_over()
	if event is InputEventKey:
		get_tree().set_input_as_handled()


func level_up():
	count += 1
	if count % 10 == 0:
		increase_level()


func increase_level():
	if gui.level < MAX_LEVEL:
		gui.level += 1
		$Ticker.set_wait_time(TICK_SPEED / gui.level)


func normal_drop():
	$Ticker.start(TICK_SPEED / gui.level)


func soft_drop():
	$Ticker.stop()
	$Ticker.start(TICK_SPEED / gui.level / FAST_MULTIPLE)


func hard_drop():
	$Ticker.stop()
	$Ticker.start(TICK_SPEED / MAX_LEVEL)


func _game_over():
	gui.set_button_states(ENABLED)
	if PLAY:
		_music(STOP)
	state = STOPPED
	$Ticker.stop()
	save_game()


func add_to_score(rows):
	gui.lines += rows
	var score = 10 * int(pow(2, rows - 1))
	gui.score += score
	update_high_score()


func update_high_score():
	if gui.score > gui.high_score:
		gui.high_score = gui.score


func move_left():
	if pos % cols > 0:
		move_shape(pos - 1)


func move_right():
	if pos % cols < cols - 1:
		move_shape(pos + 1)


func _music(action):
	if gui.music and action == PLAY:
		$MusicPlayer.volume_db = gui.music
		if !$MusicPlayer.is_playing():
			$MusicPlayer.play(music_position)
	else:
		music_position = $MusicPlayer.get_playback_position()
		$MusicPlayer.stop()


func _sfx(action):
	pass


func _on_Ticker_timeout():
	var new_pos = pos + cols
	if move_shape(new_pos):
		gui.score += bonus
		update_high_score()
	else:
		if new_pos <= END_POS:
			_game_over()
		else:
			lock_shape_to_grid()
			check_rows()
			new_shape()


func check_rows():
	var i = grid.size() - 1
	var x = 0
	var rows = 0
	while i >= 0:
		if grid[i]:
			x += 1
			i -= 1
			if x == cols:
				rows += 1
				x = 0
		else:
			i += x
			x = 0
			if rows > 0:
				remove_rows(i, rows)
			rows = 0
			i -= cols


func remove_rows(i, rows):
	add_to_score(rows)
	var num_cells = rows * cols
	for n in num_cells:
		gui.grid.get_child(i + n + 1).modulate = Color(0)
	pause()
	yield(get_tree().create_timer(0.3), "timeout")
	pause(false)
	var to = i + num_cells
	while i >= 0:
		grid[to] = grid[i]
		gui.grid.get_child(to).modulate = gui.grid.get_child(i).modulate
		if i == 0:
			grid[i] = false
			gui.grid.get_child(i).modulate = Color(0)
		i -= 1
		to -= 1


func pause(value = true):
	get_tree().paused = value


func _on_LeftTimer_timeout():
	$LeftTimer.wait_time = REPEAT_DELAY
	move_left()


func _on_RightTimer_timeout():
	$RightTimer.wait_time = REPEAT_DELAY
	move_right()


func save_game():
	var data = {
		"music": gui.music,
		"sfx": gui.sfx,
		"high_score": gui.high_score
	}
	var file = File.new()
	file.open(FILE_NAME, File.WRITE)
	file.store_string(to_json(data))
	file.close()
	

func load_game():
	var file = File.new()
	if file.file_exists(FILE_NAME):
		file.open(FILE_NAME, File.READ)
		var data = parse_json(file.get_as_text())
		print(data)
		gui.settings(data)
