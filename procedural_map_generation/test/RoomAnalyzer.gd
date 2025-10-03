
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

static func analyze_and_decorate_rooms(grid: Array, room_tiles: Dictionary, player_spawn: Vector2i ,rooms,next_room_id):
	var result = flood_fill_distance(grid, player_spawn)
	var distance_map = result["map"]
	var max_dist = result["max"] - 70

	rooms.clear()
	var room_data := []

	for room_id in room_tiles.keys():
		var region = room_tiles[room_id]
		if region.size() <= 20:
			print("Skipped empty room:", room_id)
			continue

		var center = get_room_center(region)
		var closest_dist = INF
		var closest_point = null

		for pos in region:
			var grid_pos = pos  # adjust if needed
			if distance_map.has(grid_pos):
				var dist = distance_map[grid_pos]
				if dist < closest_dist:
					closest_dist = dist
					closest_point = grid_pos

		if closest_point == null:
			print("No path to room", room_id)
			continue

		var tier := "common"
		if closest_dist > max_dist * 0.96:
			tier = "epic"
		elif closest_dist > max_dist * 0.53:
			tier = "rare"

		room_data.append({
			"id": room_id,
			"coords": region,
			"center": center,
			"tier": tier,
			"distance": closest_dist
		})

		print("Room", room_id, "center:", center, "distance:", closest_dist, "tier:", tier)

	# Sort rooms by distance
	room_data.sort_custom(func(a, b): return a["distance"] < b["distance"])

	# Decorate in order
	for room in room_data:
		var tile_value = loot_tile_for(room["tier"])
		for pos in room["coords"]:
			grid[pos.y][pos.x] = tile_value
		rooms[room["id"]] = room.duplicate()
