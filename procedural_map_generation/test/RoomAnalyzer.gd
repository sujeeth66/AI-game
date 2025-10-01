static func flood_fill_region(grid: Array, start: Vector2i) -> Array:
	var visited := {}
	var region := []
	var queue := [start]
	visited[start] = true

	while queue.size() > 0:
		var current = queue.pop_front()
		region.append(current)

		for dir in [Vector2i(0,1), Vector2i(0,-1), Vector2i(1,0), Vector2i(-1,0)]:
			var next = current + dir
			if next.x < 0 or next.x >= grid[0].size() or next.y < 0 or next.y >= grid.size():
				continue
			if visited.has(next):
				continue
			if grid[next.y][next.x] != 2:  # room tile
				continue

			visited[next] = true
			queue.append(next)

	return region

static func get_room_center(region: Array) -> Vector2i:
	var sum_x := 0
	var sum_y := 0
	for pos in region:
		sum_x += pos.x
		sum_y += pos.y
	return Vector2i(sum_x / region.size(), sum_y / region.size())

static func flood_fill_distance(grid: Array, start: Vector2i) -> Dictionary:
	var queue := [start]
	var visited := {}
	var distance := {}
	visited[start] = true
	distance[start] = 0
	var max_dist := 0

	while queue.size() > 0:
		var current = queue.pop_front()
		var dist = distance[current]
		max_dist = max(max_dist, dist)

		for dir in [Vector2i(0,1), Vector2i(0,-1), Vector2i(1,0), Vector2i(-1,0)]:
			var next = current + dir
			if next.x < 0 or next.x >= grid[0].size() or next.y < 0 or next.y >= grid.size():
				continue
			if visited.has(next):
				continue
			if grid[next.y][next.x] != 0 and grid[next.y][next.x] != 2:
				continue

			visited[next] = true
			distance[next] = dist + 1
			queue.append(next)

	return {
		"map": distance,
		"max": max_dist
	}

static func loot_tile_for(tier: String) -> int:
	match tier:
		"common": return 4
		"rare": return 5
		"epic": return 6
		_: return 2

static func analyze_and_decorate_rooms(grid: Array, room_starts: Array, player_spawn: Vector2i):
	var result = flood_fill_distance(grid, player_spawn)
	var distance_map = result["map"]
	var max_dist = result["max"] - 70

	for start in room_starts:
		var region = flood_fill_region(grid, start)
		if region.size() < 30:
			print("Skipped tiny room at:", start, "size:", region.size())
			continue

		var center = get_room_center(region)
		var center_dist = distance_map.get(center, 0)

		var tier := "common"
		if center_dist > max_dist * 0.66:
			tier = "epic"
		elif center_dist > max_dist * 0.33:
			tier = "rare"

		print("Room center:", center)
		print("Region size:", region.size())
		print("Center distance:", center_dist)
		print("Tier:", tier)
		print("---------------------")

		for pos in region:
			grid[pos.y][pos.x] = loot_tile_for(tier)
