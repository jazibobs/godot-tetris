extends Control

class_name ShapeData

var color: Color
var grid: Array
var coords: Array


func rotate_left():
	_rotate_grid(-1, 1)
	
	
func rotate_right():
	_rotate_grid(1, -1)
	

func _rotate_grid(sign_of_x, sign_of_y):
	var rotated_grid = grid.duplicate(true)
	for x in coords:
		for y in coords:
			var x1 = coords.find(x)
			var y1 = coords.find(y)
			var x2 = coords.find(sign_of_y * y)
			var y2 = coords.find(sign_of_x * x)
			rotated_grid[y1][x1] = grid[y2][x2]
	grid = rotated_grid
