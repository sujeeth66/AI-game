static func initialize_empty_grid(grid: Array, width: int, height: int, surface_height: int):
	grid.clear()
	for y in range(height):
		var row := []
		for x in range(width):
			row.append(0 if y >= height - surface_height else 1)
		grid.append(row)

static func generate_surface_layer(
	grid: Array,
	width: int,
	height: int,
	surface_height: int,
	seed: int,
	terrain_type,
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
			if (y + 85) >= 0 and (y + 85) < grid.size():
				if x >= 0 and x < grid[y + 85].size():
					grid[y + (height - surface_height - 1)][x] = 1

	return final_heights

static func generate_city_surface(grid: Array,map_height:int, start_x: int, segment_data: Array, cutoff := 0) -> Dictionary:
	var final_heights := {}
	var x_cursor = start_x

	for segment in segment_data:
		var length = segment["length"]
		var segment_height: int
		if segment.has("height"):
			segment_height = segment["height"]
			print("--------------------------------height got-",segment_height)
		else:
			segment_height = get_default_city_height(segment["type"])

		for x in range(x_cursor, x_cursor + length):
			final_heights[x] = segment_height
			for y in range(map_height):
				if (y + 85) >= 0 and (y + 85) < grid.size():
					if x >= 0 and x < grid[y + 85].size():
						grid[segment_height-y-56][x] = 1  # fill below surface_y

		x_cursor += length

	return final_heights

static func enclose_grid(grid: Array, map_width: int, map_height: int):
	for x in range(map_width):
		grid[0][x] = 1  # top border
		grid[map_height - 1][x] = 1  # bottom border

	for y in range(map_height):
		grid[y][0] = 1  # left border
		grid[y][map_width - 1] = 1  # right border

static func get_default_city_height(segment_type: String) -> int:
	match segment_type:
		"road": return 28
		"building": return 25
		"park": return 26
		_: return 27  # fallback
