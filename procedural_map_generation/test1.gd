extends Node2D

@onready var tilemap := $TileMapLayer

var map = {
	"height" = 300,
	"width" = 100
}

func _ready() -> void:
	make_noise_grid(60)
	
func make_noise_grid(density):
	var noise_grid = [map.height][map.width]
	for i in range(map.height):
		for j in range(map.width):
			var random = randi() % 100 + 1
			if random > density:
				tilemap.set_cell(Vector2i(i,j),0,Vector2i(0,0))
				noise_grid[i][j] = 1
			else:
				tilemap.erase_cell(Vector2i(i,j))
				noise_grid[i][j] = 0

func apply_cellular_automaton(grid,count):
	for i in range(count):
		var temp_grid = grid
		for j in range(map.height):
			for k in range(map.width):
				var neighbor_wall_count = 0
				for y in range(j-1,j+1):
					for x in range(k-1,k+1):
						if is_within_map_bounds(x,y):
							if y != j or x != k:
								if temp_grid[y][x] == 0:
									neighbor_wall_count += 1
						else:
							neighbor_wall_count += 1
				if neighbor_wall_count > 4:
					tilemap.erase_cell(Vector2i(j,k))
				else:
					tilemap.set_cell(Vector2i(j,k),0,Vector2i(0,0))
						

func is_within_map_bounds(x,y):
	if x < map.height:
		if y < map.width:
			return true
		else:
			return false
