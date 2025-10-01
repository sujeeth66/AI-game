static func carve_horizontal_tunnel(grid: Array, start_y: int, length: int, tunnel_width: int, seed: int, roughness := 0.2, curvyness := 0.3, max_shift := 2) -> Array:
	var y = start_y
	var width = tunnel_width
	var path := []

	for x in range(length):
		var top = clamp(y - width / 2, 1, grid.size() - 2)
		var bottom = clamp(y + width / 2, top + 1, grid.size() - 2)
		for ny in range(top, bottom):
			grid[ny][x] = 0
			path.append(Vector2i(x, ny))

		if randf() < roughness:
			width += randi_range(-1, 1)
			width = clamp(width, 15, 25)

		if randf() < curvyness:
			y += randi_range(-max_shift, max_shift)
			y = clamp(y, 1, grid.size() - 2)

	return path

static func roughen_tunnel_floor_with_moore(grid: Array, width: int, height: int, seed := 98765):
	var rng = RandomNumberGenerator.new()
	rng.seed = seed

	for x in range(width):
		for y in range(height):
			if grid[y][x] == 0:
				var count = 0
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						var nx = clamp(x + dx, 0, width - 1)
						var ny = clamp(y + dy, 0, height - 1)
						if grid[ny][nx] == 0:
							count += 1
				if count > 4:
					grid[y + 1][x] = 0
				break

static func smooth_tunnel(grid: Array, width: int, height: int, threshold := 5):
	var new_grid := []
	for y in range(height):
		var row := []
		for x in range(width):
			var solid_neighbors := 0
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					if dx == 0 and dy == 0:
						continue
					var nx = clamp(x + dx, 0, width - 1)
					var ny = clamp(y + dy, 0, height - 1)
					if grid[ny][nx] == 1:
						solid_neighbors += 1
			row.append(1 if solid_neighbors >= threshold else 0)
		new_grid.append(row)

	for y in range(height):
		for x in range(width):
			grid[y][x] = new_grid[y][x]
