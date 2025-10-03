static func initialize_empty_grid(grid: Array, width: int, height: int):
	grid.clear()
	for y in range(height):
		var row := []
		for x in range(width):
			row.append(0 if y >= 86 else 1)
		grid.append(row)

static func generate_surface_layer(grid: Array, width: int, height: int, surface_height: int, seed: int, terrain_type := "plain", cutoff := 0):
	var noise = FastNoiseLite.new()
	noise.seed = seed

	match terrain_type:
		"plain":
			noise.noise_type = FastNoiseLite.TYPE_PERLIN
			noise.frequency = 0.01
		"hilly":
			noise.noise_type = FastNoiseLite.TYPE_PERLIN
			noise.frequency = 0.03
		"dunes":
			noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
			noise.frequency = 0.08
		"peaks":
			noise.noise_type = FastNoiseLite.TYPE_PERLIN
			noise.frequency = 0.05
			# simulate ridges
			# later: normalized = abs(raw)
		"mountains":
			noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
			noise.frequency = 0.04

	for x in range(width):
		var raw = noise.get_noise_2d(x, 0)
		var normalized = clamp((raw * 0.5 + 0.5), 0.0, 1.0)

		# Optional shaping
		if terrain_type == "plain":
			normalized = pow(normalized, 1.5)  # flatten
		elif terrain_type == "peaks":
			normalized = pow(normalized, 0.5)  # exaggerate

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
