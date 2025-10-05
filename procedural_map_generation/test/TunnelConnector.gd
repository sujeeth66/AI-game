
static func carve_cave_entrance(grid: Array, start: Vector2i, tunnel_path: Array, width: int, height: int, direction_bias := 0.2):
	var pos = start
	var directions = [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]
	var main_direction := Vector2i(0, 1)
	var tunnel_set := {}
	var rng = RandomNumberGenerator.new()
	for p in tunnel_path:
		tunnel_set[str(p)] = true
	print("cave entrance")
	var max_steps := 300
	var steps := 0

	while steps < max_steps:
		for y in range(-1, 2):
			for x in range(-2, 3):
				var nx = pos.x + x
				var ny = pos.y + y
				if nx >= 0 and nx < width and ny >= 0 and ny < height:
					grid[ny][nx] = 0

		for y in range(-1, 2):
			for x in range(-1, 2):
				var check_pos = pos + Vector2i(x, y)
				if tunnel_set.has(str(check_pos)):
					return

		var dir = main_direction if rng.randf() < direction_bias else directions[rng.randi_range(0, directions.size() - 1)]
		pos -= dir
		pos.x = clamp(pos.x, 1, width - 2)
		pos.y = clamp(pos.y, 1, height - 2)
		steps += 1
