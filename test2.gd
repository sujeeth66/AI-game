extends Node2D

@onready var tilemap := $TileMapLayer

var map_width := 300
var map_height := 100
var smoothness := 60.0
var seed := 12345
var surface_grid := []
var underground_grid := []

func _ready():
	initialize_empty_grid()
	generate_top_layer(surface_grid, seed, smoothness)
	var tunnel_path = carve_sideways_tunnel(underground_grid)
	#roughen_tunnel_roof(underground_grid)
	#roughen_tunnel_floor_with_moore(underground_grid)  # new floor erosion pass
	#for i in range(2):
		#cleanup_floating_tiles(underground_grid)
	tilemap.clear()
	draw_grid_to_tilemap(surface_grid)
	draw_grid_to_tilemap(underground_grid,map_height-36)

func draw_grid_to_tilemap(grid, y_offset := 0):
	for y in range(map_height):
		for x in range(map_width):
			if grid[y][x] == 1:
				tilemap.set_cell(Vector2i(x, map_height - y - 1 + y_offset), 0, Vector2i(0, 0))

func initialize_empty_grid():
	surface_grid.clear()
	underground_grid.clear()
	for y in range(map_height):
		var surface_row := []
		var underground_row := []
		for x in range(map_width):
			surface_row.append(0)      # surface starts empty
			underground_row.append(1)  # underground starts solid
		surface_grid.append(surface_row)
		underground_grid.append(underground_row)

func generate_top_layer(grid, seed, smoothness := 20.0, cutoff := 35):
	var noise = FastNoiseLite.new()
	noise.seed = seed
	noise.frequency = 2.5 / smoothness
	noise.noise_type = FastNoiseLite.TYPE_PERLIN

	for x in range(map_width):
		var raw = noise.get_noise_2d(x, 0)
		var normalized = clamp((raw * 0.5 + 0.5), 0.0, 1.0)
		var perlin_height = int(normalized * map_height)

		for y in range(perlin_height):
			if y > cutoff:
				grid[y][x] = 1  # mark tile

func carve_sideways_tunnel(
	grid,
	start_y := 70,
	length := 200,
	tunnel_width := 12,
	min_path_width := 8,
	max_path_width := 15,
	roughness := 0.2,
	curvyness := 0.3,
	max_path_change := 2
) -> Array:
	var path := []
	var y = start_y
	var width = tunnel_width

	var roof_noise = FastNoiseLite.new()
	roof_noise.seed = seed + 100
	roof_noise.frequency = 0.5
	roof_noise.noise_type = FastNoiseLite.TYPE_PERLIN

	var floor_noise = FastNoiseLite.new()
	floor_noise.seed = seed + 200
	floor_noise.frequency = 0.05
	floor_noise.noise_type = FastNoiseLite.TYPE_PERLIN

	for x in range(length):
		var roof_offset = int(roof_noise.get_noise_2d(x, 0) * 2.0)
		var floor_offset = int(floor_noise.get_noise_2d(x, 0) * 2.0)

		var top = clamp(y - width / 2 + roof_offset, 1, map_height - 2)
		var bottom = clamp(y + width / 2 + floor_offset, top + 1, map_height - 2)

		for ny in range(top, bottom + 1):
			grid[ny][x] = 0
			path.append(Vector2i(x, ny))

		# Roughness: chance to change tunnel width
		if randf() < roughness:
			width += randi_range(-1, 1)
			width = clamp(width, min_path_width, max_path_width)

		# Curvyness: chance to shift tunnel center
		if randf() < curvyness:
			var shift = randi_range(-max_path_change, max_path_change)
			y += shift
			y = clamp(y, 1, map_height - 2)

	return path

func roughen_tunnel_roof(grid, seed := 54321, max_lift := 3): 
	var noise = FastNoiseLite.new() 
	noise.seed = seed + 2 
	noise.frequency = 0.1 
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	for x in range(map_width):
		for y in range(map_height):		
			if grid[y][x] == 0:			
				# Found ceiling			
				var raw = noise.get_noise_2d(x, 0)			
				var lift = int((raw * 0.5 + 0.5) * max_lift)  # normalize to [0,1]			
				for i in range(1, lift + 1):				
					var ny = clamp(y - i, 0, map_height - 1)				
					grid[ny][x] = 1  # fill with solid				
					print("yoyo")			
				break  # move to next column

func cleanup_floating_tiles(grid, threshold := 5):
	var new_grid := []
	for y in range(map_height):
		var row := []
		for x in range(map_width):
			var count := 0
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					if dx == 0 and dy == 0:
						continue
					var nx = clamp(x + dx, 0, map_width - 1)
					var ny = clamp(y + dy, 0, map_height - 1)
					if grid[ny][nx] == 1:
						count += 1
			# Keep tile only if enough solid neighbors
			if grid[y][x] == 1 and count >= threshold:
				row.append(1)
			else:
				row.append(0)
		new_grid.append(row)
	# Copy back
	for y in range(map_height):
		for x in range(map_width):
			grid[y][x] = new_grid[y][x]

func roughen_tunnel_floor_with_moore(grid, seed := 98765, chance := 0.4):
	var rng = RandomNumberGenerator.new()
	rng.seed = seed

	for x in range(map_width):
		for y in range(map_height - 1, -1, -1):
			if grid[y][x] == 0:
				# Found floor
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						var nx = clamp(x + dx, 0, map_width - 1)
						var ny = clamp(y + dy, 0, map_height - 1)
						if grid[ny][nx] == 1 and rng.randf() < chance:
							grid[ny][nx] = 0  # erode solid tile
				break  # move to next column

func carve_random_walk(
	grid,
	start: Vector2i,
	floor_count := 50,
	directions := [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)],
	bounds := Rect2i(Vector2i(1, 1), Vector2i(map_width - 2, map_height - 2)),
	branch_chance := 0.1,
	max_branch_depth := 20
) -> Array:
	var carved := []
	var pos = start
	var visited := {}
	var steps = 0

	while steps < floor_count:
		if not visited.has(pos):
			grid[pos.y][pos.x] = 0
			carved.append(pos)
			visited[pos] = true
			steps += 1

		# Random direction
		var dir = directions[randi() % directions.size()]
		var next = pos + dir

		# Clamp to bounds
		if bounds.has_point(next):
			pos = next

		# Optional branching
		if randf() < branch_chance and steps < floor_count - max_branch_depth:
			var branch_start = pos
			var branch_steps = randi_range(5, max_branch_depth)
			var branch = carve_random_walk(grid, branch_start, branch_steps, directions, bounds, 0.0, 0)
			carved += branch
			steps += branch.size()

	return carved
