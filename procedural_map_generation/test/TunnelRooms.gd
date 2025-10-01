static func carve_simple_random_walk(grid: Array, start: Vector2i, steps := 100, direction := Vector2i(1, 0), direction_bias := 0.25):
	var pos = start
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var base_directions = [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]

	for i in range(steps):
		if pos.x < 5 or pos.x >= grid[0].size() - 5 or pos.y < 1 or pos.y >= grid.size() - 1:
			break

		for y in range(-2, 3):
			for x in range(-1, 2):
				grid[pos.y + y][pos.x + x] = 2

		var safe_directions := []
		for dir in base_directions:
			var check_pos = pos + dir
			var safe := true
			for offset in range(1, 6):
				var probe = check_pos + dir * offset
				if probe.x < 0 or probe.x >= grid[0].size() or probe.y < 0 or probe.y >= grid.size():
					safe = false
					break
				if grid[probe.y][probe.x] == 0:
					safe = false
					break
			if safe:
				safe_directions.append(dir)

		var dir = direction if rng.randf() < direction_bias and safe_directions.has(direction) else safe_directions[rng.randi_range(0, safe_directions.size() - 1)] if safe_directions.size() > 0 else null
		if dir == null:
			break

		pos += dir
		pos.x = clamp(pos.x, 1, grid[0].size() - 2)
		pos.y = clamp(pos.y, 1, grid.size() - 2)

static func generate_tunnel_rooms(grid: Array, tunnel_path: Array, width: int, height: int, seed: int):
	var roof_starts := []
	var floor_starts := []
	var room_starts := []

	for p in tunnel_path:
		if p.x > 0 and grid[p.y][p.x - 1] == 1:
			if grid[p.y - 1][p.x - 1] == 0:
				roof_starts.append(p)
			if grid[p.y + 1][p.x - 1] == 0:
				floor_starts.append(p)
		elif p.x < width - 1 and grid[p.y][p.x + 1] == 1:
			if grid[p.y - 1][p.x + 1] == 0:
				roof_starts.append(p)
			if grid[p.y + 1][p.x + 1] == 0:
				floor_starts.append(p)

	var rng = RandomNumberGenerator.new()
	rng.seed = seed + 42

	roof_starts.shuffle()
	floor_starts.shuffle()

	for i in range(0, roof_starts.size(), 10):
		if i < roof_starts.size():
			var start = roof_starts[i]
			var dir = Vector2i(-1, -1) if rng.randf() < 0.5 else Vector2i(1, -1)
			room_starts.append(start)  # where each room starts
			carve_simple_random_walk(grid, start, 150, dir)

	for i in range(0, floor_starts.size(), 10):
		if i < floor_starts.size():
			var start = floor_starts[i]
			var dir = Vector2i(-1, 1) if rng.randf() < 0.5 else Vector2i(1, 1)
			room_starts.append(start)  # where each room starts
			carve_simple_random_walk(grid, start, 150, dir)
	return room_starts
