extends Node2D

@onready var tilemap := $TileMapLayer

var map_width := 300
var map_height := 100
var surface_height := 60  # top half is surface
var seed := 12345
var map_grid := []
var surface_bottom = -1
var tunnel_top = -1
var min_distance = 100
var best_pos

func _ready():
	initialize_empty_grid()
	generate_surface_layer()
	var tunnel_path = carve_horizontal_tunnel()
	for i in range(2):
		roughen_tunnel_floor_with_moore(map_grid)
	smooth_tunnel(map_grid)
	var closest_pos = find_min_surface_tunnel_distance(map_grid)
	print("Closest surface-tunnel column at x =", closest_pos)
	carve_cave_entrance(map_grid, Vector2i(closest_pos.x,closest_pos.y - 1),tunnel_path)
	#carve_simple_random_walk(map_grid, Vector2i(168,59))
		#carve_simple_random_walk(map_grid,closest_pos)
	tilemap.clear()
	draw_grid_to_tilemap()
	#tilemap.set_cell(grid_to_vector2i(closest_pos.y,closest_pos.x),0,Vector2i(7,0))
	
func grid_to_vector2i(y,x):
	var vector_coords : Vector2i = Vector2i(x,map_height - y)
	return vector_coords

func show_():
	for y in range(map_height - 2, 0, -1):
		print(map_grid[y][1])
		if map_grid[y][1] == 0 and map_grid[y + 1][1] == 1:
			tunnel_top = y
			print("tunnel_top = ",y)
		if y > tunnel_top:
			if map_grid[y][1] == 1 and map_grid[y + 1][1] == 0 :
				surface_bottom = y
				print("surface_bottom = ",y)
		
		if surface_bottom != -1 and tunnel_top != -1:
			if tunnel_top > surface_bottom:
				continue  # tunnel must be below surface
			var distance = surface_bottom - tunnel_top
			if distance < min_distance:
				min_distance = distance
				best_pos = Vector2i(1, surface_bottom)
	print(best_pos)
	print(min_distance)
		
func initialize_empty_grid():
	map_grid.clear()
	for y in range(map_height):
		var row := []
		if y >= 66:
			for x in range(map_width):
				row.append(0)  
			map_grid.append(row)
		elif y < 66:
			for x in range(map_width):
				row.append(1)  
			map_grid.append(row)

func generate_surface_layer(smoothness := 80.0, cutoff := 0):
	var noise = FastNoiseLite.new()
	noise.seed = seed
	noise.frequency = 2.5 / smoothness
	noise.noise_type = FastNoiseLite.TYPE_PERLIN

	for x in range(map_width):
		var raw = noise.get_noise_2d(x, 0)
		var normalized = clamp((raw * 0.5 + 0.5), 0.0, 1.0)
		var surface_y = int(normalized * surface_height) 
		#var count = 0
		#if count == 0:
			#print("surface_y = ",surface_y," map_height = " ,map_height)
		for y in range(surface_y):
			if y > cutoff:
				map_grid[y+55][x] = 1  # fill solid below surface


func carve_horizontal_tunnel(
	start_y :=40,
	length := 200,
	tunnel_width := 16,
	roughness := 0.2,
	curvyness := 0.3,
	max_shift := 2
):
	var y = start_y
	var width = tunnel_width
	var path := []

	for x in range(length):
		var top = clamp(y - width / 2, 1, map_height - 2)
		var bottom = clamp(y + width / 2, top + 1, map_height - 2)

		for ny in range(top, bottom):
			map_grid[ny][x] = 0  # carve tunnel
			path.append(Vector2i(x, ny))

		# Roughness: change tunnel width
		if randf() < roughness:
			width += randi_range(-1, 1)
			width = clamp(width, 15, 25)

		# Curvyness: shift tunnel center
		if randf() < curvyness:
			y += randi_range(-max_shift, max_shift)
			y = clamp(y, 1, map_height - 2)
	return path

func roughen_tunnel_floor_with_moore(grid, seed := 98765):
	var rng = RandomNumberGenerator.new()
	rng.seed = seed

	for x in range(map_width):
		for y in range(0,map_height):
			#print(grid[y][x])
			if grid[y][x] == 0:
				var count = 0
				# Found floor
				#print("roughen_tunnel_floor_with_moore")
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						var nx = clamp(x + dx, 0, map_width - 1)
						var ny = clamp(y + dy, 0, map_height - 1)
						if grid[ny][nx] == 0 :
							count += 1  # erode solid tile
				if count > 4:
					grid[y+1][x] = 0
				break  # move to next column

func smooth_tunnel(grid, threshold := 5):
	var new_grid := []
	for y in range(map_height):
		var row := []
		for x in range(map_width):
			var solid_neighbors := 0
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					if dx == 0 and dy == 0:
						continue
					var nx = clamp(x + dx, 0, map_width - 1)
					var ny = clamp(y + dy, 0, map_height - 1)
					if grid[ny][nx] == 1:
						solid_neighbors += 1
			# Smooth based on neighbor majority
			if solid_neighbors >= threshold:
				row.append(1)
			else:
				row.append(0)
		new_grid.append(row)

	# Copy back
	for y in range(map_height):
		for x in range(map_width):
			grid[y][x] = new_grid[y][x]

func find_min_surface_tunnel_distance(grid) -> Vector2i:
	var min_distance := map_height
	var best_pos := Vector2i(-1, -1)

	for x in range(5, map_width - 5):
		var surface_bottom := -1
		var tunnel_top := -1

		for y in range(map_height - 2, 0, -1):  # top-down
			if surface_bottom == -1 and grid[y][x] == 1 and grid[y + 1][x] == 0:
				surface_bottom = y
			elif surface_bottom != -1 and tunnel_top == -1 and grid[y][x] == 0 and grid[y + 1][x] == 1:
				tunnel_top = y

			if surface_bottom != -1 and tunnel_top != -1:
				if tunnel_top > surface_bottom:
					continue  # tunnel must be below surface
				var distance = surface_bottom - tunnel_top
				if distance < min_distance:
					min_distance = distance
					best_pos = Vector2i(x, surface_bottom )
				break

	return best_pos

func draw_grid_to_tilemap():
	for y in range(map_height):
		for x in range(map_width):
			var cell_pos = Vector2i(x, map_height - y - 1)
			if map_grid[y][x] == 1:
				tilemap.set_cell(cell_pos, 0, Vector2i(0, 0))  # solid
			#else:
				#tilemap.set_cell(cell_pos, 0, Vector2i(1, 0))  # air (optional debug tile)

func is_preexisting_air(grid, pos: Vector2i, visited: Dictionary) -> bool:
	return grid[pos.y][pos.x] == 0 and not visited.has(pos)

func carve_cave_entrance(grid, start: Vector2i, tunnel_path: Array,direction_bias:=0.2):
	var pos = start
	var directions = [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]
	var main_direction := Vector2i(0, 1)
	var tunnel_set := {}
	var rng = RandomNumberGenerator.new()
	for p in tunnel_path:
		tunnel_set[str(p)] = true

	var max_steps := 300
	var steps := 0

	while steps < max_steps:
		print(steps)
		print(pos)
		# Check if we've reached the tunnel
		for y in range(-1, 2):
			for x in range(-1, 2):
				var check_pos = pos + Vector2i(x, y)
				if tunnel_set.has(str(check_pos)):
					return  # connected

		# Carve 3x3 area
		for y in range(-1, 2):
			for x in range(-2, 3):
				var nx = pos.x + x
				var ny = pos.y + y
				if nx >= 0 and nx < map_width and ny >= 0 and ny < map_height:
					grid[ny][nx] = 0
		
		var dir: Vector2i
		if rng.randf() < direction_bias:
			dir = main_direction
		else:
			dir = directions[rng.randi_range(0, directions.size() - 1)]
		
		
		pos -= dir
		pos.x = clamp(pos.x, 1, map_width - 2)
		pos.y = clamp(pos.y, 1, map_height - 2)
		steps += 1
		
func carve_simple_random_walk(grid,start: Vector2i,steps := 100):
	var pos = start
	var rng = RandomNumberGenerator.new()
	rng.seed = seed

	var directions = [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]

	for i in range(steps):
		if pos.x < 1 or pos.x >= map_width - 1 or pos.y < 1 or pos.y >= map_height - 1:
			break

		for y in range(-1,2,1):
			for x in range(-1,2,1):
				grid[pos.y+y][pos.x+x] = 0

		var dir: Vector2i
		dir = directions[rng.randi_range(0, directions.size() - 1)]

		pos += dir
		pos.x = clamp(pos.x, 1, map_width - 2)
		pos.y = clamp(pos.y, 1, map_height - 2)
