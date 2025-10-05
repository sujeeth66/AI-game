
static func get_tunnel_y_from_path(tunnel_path: Array, x: int, mode := "floor") -> int:
	var candidates := []
	for p in tunnel_path:
		if p.x == x:
			candidates.append(p.y)

	if candidates.size() == 0:
		return -1

	if mode == "floor":
		return candidates.min()
	elif mode == "roof":
		return candidates.max()
	else:
		var sum := 0
		for y in candidates:
			sum += y
		return int(sum / candidates.size())

static func find_distant_column(reference_x: int, map_width: int, seed: int, min_distance := 150) -> int:
	var candidates := []
	for x in range(10, map_width - 10):
		if abs(x - reference_x) >= min_distance:
			candidates.append(x)
	if candidates.size() == 0:
		return -1
	var rng = RandomNumberGenerator.new()
	rng.seed = seed + 999
	return candidates[rng.randi_range(0, candidates.size() - 1)]

static func find_min_surface_tunnel_distance(grid: Array, map_width: int, map_height: int) -> Vector2i:
	var min_distance := map_height
	var best_pos := Vector2i(-1, -1)

	for x in range(5, map_width - 5):
		var surface_bottom := -1
		var tunnel_top := -1

		for y in range(map_height - 15, 0, -1):
			if surface_bottom == -1 and grid[y][x] == 1 and grid[y + 1][x] == 0:
				surface_bottom = y
			elif surface_bottom != -1 and tunnel_top == -1 and grid[y][x] == 0 and grid[y + 1][x] == 1:
				tunnel_top = y

			if surface_bottom != -1 and tunnel_top != -1:
				if tunnel_top > surface_bottom:
					continue
				var distance = surface_bottom - tunnel_top
				if distance < min_distance:
					min_distance = distance
					best_pos = Vector2i(x, surface_bottom)
				break

	return best_pos
