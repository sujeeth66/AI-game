static func initialize_empty_grid(grid: Array, width: int, height: int):
	grid.clear()
	for y in range(height):
		var row := []
		for x in range(width):
			row.append(0 if y >= 86 else 1)
		grid.append(row)

static func generate_surface_layer(
	grid: Array,
	width: int,
	height: int,
	surface_height: int,
	seed: int,
	terrain_type := "dunes",
	start_x := 0,
	end_x := width,
	cutoff := 0,
	start_heights := {}
) -> Dictionary:
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
		"mountains":
			noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
			noise.frequency = 0.04

	var final_heights := {}

	for x in range(start_x, end_x):
		var raw = noise.get_noise_2d(x, 0)
		var normalized = clamp((raw * 0.5 + 0.5), 0.0, 1.0)

		# Optional shaping
		if terrain_type == "plain":
			normalized = pow(normalized, 1.5)
		elif terrain_type == "peaks":
			normalized = pow(normalized, 0.5)

		var base_y = int(normalized * surface_height)

		# Smooth transition from previous segment
		if start_heights.has(x):
			var prev_y = start_heights[x]
			var t = float(x - start_x) / max(1, end_x - start_x)
			base_y = int(lerp(prev_y, base_y, t))

		final_heights[x] = base_y

		for y in range(base_y):
			if y > cutoff:
				grid[y + 85][x] = 1

	return final_heights
	
static func enclose_grid(grid: Array, map_width: int, map_height: int):
	for x in range(map_width):
		grid[0][x] = 1  # top border
		grid[map_height - 1][x] = 1  # bottom border

	for y in range(map_height):
		grid[y][0] = 1  # left border
		grid[y][map_width - 1] = 1  # right border

static func generate_city_surface(grid: Array, start_x: int, segment_data: Array, cutoff := 0) -> Dictionary:
	var final_heights := {}
	var x_cursor = start_x

	for segment in segment_data:
		var length = segment["length"]
		var surface_y = segment["height"]  # this is the surface Y coordinate (from top)

		for x in range(x_cursor, x_cursor + length):
			final_heights[x] = surface_y
			for y in range(surface_y):
				if y > cutoff:
					print(surface_y)
					grid[150-y-segment["height"]-25][x] = 1  # fill below surface_y

		x_cursor += length

	return final_heights
