extends PanelContainer

var grid
var next
var music = -1
var sfx = -1

var level = 1 setget set_level
var score = 0 setget set_score
var high_score = 0 setget set_high_score
var lines = 0 setget set_lines

signal button_pressed(button_name)


func set_level(value):
	find_node("LevelVal").text = str(value)
	level = value
	
	
func set_score(value):
	find_node("ScoreVal").text = str(value)
	score = value


func set_high_score(value):
	find_node("HighScoreVal").text = "%08d" % value
	high_score = value
	

func set_lines(value):
	find_node("LinesVal").text = str(value)
	lines = value


func reset_stats(_high_score = 0, _score = 0, _lines = 0, _level = 1):
	self.high_score = _high_score
	self.score = _score
	self.lines = _lines
	self.level = _level


func settings(data):
	self.high_score = data.high_score
	find_node("MusicBtn").value = data.music
	find_node("SfxBtn").value = data.sfx


func _ready():
	grid = find_node("Grid")	
	next = find_node("NextShape")
	add_cells(grid, 200)
	clear_all_cells()


func set_next_shape(shape: ShapeData):
	clear_cells(next)
	var i = 0
	for col in shape.coords.size():
		for row in [0, 1]:
			if shape.grid[row][col]:
				next.get_child(i).modulate = shape.color
			i += 1


func add_cells(node, num_of_cells):
	var existing_cells = node.get_child_count()
	
	while existing_cells < num_of_cells:
		node.add_child(node.get_child(0).duplicate())
		existing_cells += 1


func clear_all_cells():
	clear_cells(grid)
	clear_cells(next)


func clear_cells(node):
	for cell in node.get_children():
		cell.modulate = Color(0)


func _on_AboutBtn_button_down():
	$AboutBox.popup_centered()
	emit_signal("button_pressed", "AboutBtn")
	

func _on_PauseBtn_button_down():
	emit_signal("button_pressed", "PauseBtn")


func _on_NewGameBtn_button_down():
	emit_signal("button_pressed", "NewGameBtn")
	

func _on_MusicBtn_value_changed(value):
	music = value
	emit_signal("button_pressed", "MusicBtn")


func _on_SfxBtn_value_changed(value):
	sfx = value
	emit_signal("button_pressed", "SfxBtn")


func set_button_state(button, state):
	find_node(button).set_disabled(state)


func set_button_text(button, text):
	find_node(button).set_text(text)


func _on_AboutBox_popup_hide():
	set_button_state("AboutBtn", false)
	

func set_button_states(playing):
	set_button_state("NewGameBtn", playing)
	set_button_state("AboutBtn", playing)
