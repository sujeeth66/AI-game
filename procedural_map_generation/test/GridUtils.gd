static func initialize_empty_grid(grid: Array, width: int, height: int):
	grid.clear()
	for y in range(height):
		var row := []
		for x in range(width):
			row.append(0 if y >= 86 else 1)
		grid.append(row)

static func generate_surface_layer(grid: Array, width: int, height: int, surface_height: int, seed: int, smoothness := 80.0, cutoff := 0):
	var noise = FastNoiseLite.new()
	noise.seed = seed
	noise.frequency = 2.5 / smoothness
	noise.noise_type = FastNoiseLite.TYPE_PERLIN

	for x in range(width):
		var raw = noise.get_noise_2d(x, 0)
		var normalized = clamp((raw * 0.5 + 0.5), 0.0, 1.0)
		var surface_y = int(normalized * surface_height)
		for y in range(surface_y):
			if y > cutoff:
				grid[y + 85][x] = 1

static func enclose_grid(grid: Array, map_width: int, map_height: int):
	for x in range(map_width):
		grid[0][x] = 1  # top border
		grid[map_height - 1][x] = 1  # bottom border

	for y in range(map_height):
		grid[y][0] = 1  # left border
		grid[y][map_width - 1] = 1  # right border
