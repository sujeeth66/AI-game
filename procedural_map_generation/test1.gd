extends Node2D

@onready var tilemap := $TileMapLayer

var random_state := RandomNumberGenerator.new()
var noise_grid = []
var map = {
	"height": 300,
	"width": 100
}

var perlin := FastNoiseLite.new()

func setup_perlin(seed := 123456, octaves := 4, persistence := 0.5, scale := 0.05):
	perlin.seed = seed
	perlin.octaves = octaves
	perlin.persistence = persistence
	perlin.period = 1.0 / scale

func _ready() -> void:
	randomize_with_seed(123456)
	make_noise_grid(55)
	smooth_grid(noise_grid)
	apply_cellular_automaton(noise_grid, 6)
	enforce_minimum_girth(noise_grid, 3 , 5)
	remove_floating_islands(noise_grid, 30)  # removes islands smaller than 50 tiles
	draw_tilemap(noise_grid)

func randomize_with_seed(seed_value):
	var state = RandomNumberGenerator.new()
	state.seed = seed_value
	# Store it globally if needed
	random_state = state


func make_noise_grid(density):
	for y in range(map["height"]):
		var row = []
		for x in range(map["width"]):
			row.append(0)
		noise_grid.append(row)

	for y in range(map["height"]):
		for x in range(map["width"]):
			var random = random_state.randi() % 100 + 1
			if random > density:
				noise_grid[y][x] = 1
			else:
				noise_grid[y][x] = 0

func smooth_grid(grid):
	var temp_grid = []
	for y in range(map["height"]):
		temp_grid.append(grid[y].duplicate())  # deep copy

	for y in range(map["height"]):
		for x in range(map["width"]):
			var wall_neighbors = 0
			for ny in range(y - 1, y + 2):
				for nx in range(x - 1, x + 2):
					if nx == x and ny == y:
						continue
					if is_within_map_bounds(nx, ny):
						if temp_grid[ny][nx] == 1:
							wall_neighbors += 1

			# Smoothing rule: flip isolated walls or floors
			if wall_neighbors < 3:
				grid[y][x] = 0  # too few walls → become floor
			elif wall_neighbors > 5:
				grid[y][x] = 1  # surrounded by walls → stay wall

func apply_cellular_automaton(grid, count):
	for i in range(count):
		var temp_grid = []
		for y in range(map["height"]):
			temp_grid.append(grid[y].duplicate())  # deep copy

		for y in range(map["height"]):
			for x in range(map["width"]):
				var neighbor_wall_count = 0
				for ny in range(y - 1, y + 2):
					for nx in range(x - 1, x + 2):
						if nx == x and ny == y:
							continue
						if is_within_map_bounds(nx, ny):
							if temp_grid[ny][nx] == 0:
								neighbor_wall_count += 1
						else:
							neighbor_wall_count += 1

				if neighbor_wall_count > 4:
					grid[y][x] = 0
				else:
					grid[y][x] = 1

func is_within_map_bounds(x, y):
	return x >= 0 and x < map["width"] and y >= 0 and y < map["height"]

func apply_top_layer(grid, top_min := 10, top_max := 50):
	for x in range(map["width"]):
		var top_y = int(lerp(top_min, top_max, perlin.get_noise_1d(x)))
		for y in range(top_y):
			grid[y][x] = 1  # force wall above top_y

func apply_bottom_layer(grid, bottom_min := 250, bottom_max := 290):
	for x in range(map["width"]):
		var bottom_y = int(lerp(bottom_min, bottom_max, perlin.get_noise_1d(x + 1000)))  # offset for variation
		for y in range(bottom_y + 1, map["height"]):
			grid[y][x] = 1  # force wall below bottom_y

func draw_tilemap(grid):
	for x in range(grid.size()):
		for y in range(grid[x].size()):
			if grid[x][y] == 1:
				tilemap.set_cell(Vector2i(x,y),0,Vector2i(0,0))
			
func label_regions(grid):
	var visited = []
	for y in range(map["height"]):
		visited.append([])
		for x in range(map["width"]):
			visited[y].append(false)

	var regions = []
	for y in range(map["height"]):
		for x in range(map["width"]):
			if grid[y][x] == 1 and not visited[y][x]:
				var region = flood_fill(grid, visited, x, y)
				regions.append(region)
	return regions

func flood_fill(grid, visited, start_x, start_y):
	var region = []
	var queue = [Vector2i(start_x, start_y)]

	while queue.size() > 0:
		var pos = queue.pop_front()
		var x = pos.x
		var y = pos.y

		if not is_within_map_bounds(x, y):
			continue
		if visited[y][x] or grid[y][x] != 1:
			continue

		visited[y][x] = true
		region.append(pos)

		for offset in [Vector2i(0,1), Vector2i(1,0), Vector2i(0,-1), Vector2i(-1,0)]:
			queue.append(pos + offset)

	return region

func remove_floating_islands(grid, min_size):
	var regions = label_regions(grid)
	for region in regions:
		if region.size() < min_size:
			for pos in region:
				grid[pos.y][pos.x] = 0

func enforce_minimum_girth(grid, min_height := 3, min_width := 3):
	enforce_minimum_girth_vertical(grid, min_height)
	enforce_minimum_girth_horizontal(grid, min_width)

func enforce_minimum_girth_vertical(grid, min_height := 3):
	for x in range(map["width"]):
		var open_run = 0
		for y in range(map["height"]):
			if grid[y][x] == 0:
				open_run += 1
			else:
				if open_run > 0 and open_run < min_height:
					# Not enough vertical space — widen it by carving neighbors
					for i in range(y - open_run, y):
						widen_cell(grid, x, i)
				open_run = 0
		# Handle bottom edge
		if open_run > 0 and open_run < min_height:
			for i in range(map["height"] - open_run, map["height"]):
				widen_cell(grid, x, i)

func enforce_minimum_girth_horizontal(grid, min_width := 3):
	for y in range(map["height"]):
		var open_run = 0
		for x in range(map["width"]):
			if grid[y][x] == 0:
				open_run += 1
			else:
				if open_run > 0 and open_run < min_width:
					# Not enough horizontal space — widen it by carving neighbors
					for i in range(x - open_run, x):
						widen_cell(grid, i, y)
				open_run = 0
		# Handle right edge
		if open_run > 0 and open_run < min_width:
			for i in range(map["width"] - open_run, map["width"]):
				widen_cell(grid, i, y)

func widen_cell(grid, x, y):
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			var nx = x + dx
			var ny = y + dy
			if is_within_map_bounds(nx, ny):
				grid[ny][nx] = 0  # carve to floor
