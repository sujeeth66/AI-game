
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
			if grid[next.y][next.x] not in [0, 2, 4, 5, 6]:
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

static func analyze_and_decorate_rooms(grid: Array, room_tiles: Dictionary, player_spawn: Vector2i, rooms, next_room_id):
	print("Starting room decoration with", room_tiles.size(), "initial rooms")
	var result = flood_fill_distance(grid, player_spawn)
	var distance_map = result["map"]
	var max_dist = result["max"] - 70

	print("Max distance from player spawn:", max_dist)
	
	rooms.clear()
	var processed_rooms = 0
	var skipped_rooms = 0
	var room_regions = {}  # Will store all room regions we find

	# First, process the existing room tiles
	for room_id in room_tiles.keys():
		var region = room_tiles[room_id]
		if region.size() <= 20:
			print("Skipped small room:", room_id, " size:", region.size())
			skipped_rooms += 1
			continue

		var has_connection = false
		var closest_dist = INF
		var center = get_room_center(region)

		# Check multiple points in the room
		var check_points = [center]
		for i in range(0, min(10, region.size()), max(1, region.size() / 10)):
			check_points.append(region[i])

		for pos in check_points:
			if distance_map.has(pos) and distance_map[pos] > 0:
				has_connection = true
				if distance_map[pos] < closest_dist:
					closest_dist = distance_map[pos]
				break

		if has_connection:
			room_regions[room_id] = {
				"region": region,
				"center": center,
				"distance": closest_dist,
				"is_primary": true  # Mark as primary (from room_tiles)
			}
		else:
			print("Room", room_id, " has no valid connection to player spawn")
			skipped_rooms += 1

	# Second pass: Scan the entire grid for any remaining room tiles (value 2)
	var visited = {}
	var next_room_id_counter = 1000  # Start with a high number to avoid conflicts
	
	for y in range(grid.size()):
		for x in range(grid[0].size()):
			var pos = Vector2i(x, y)
			if grid[y][x] == 2 and not visited.has(pos):
				# Found a room tile that wasn't in room_tiles, flood fill to find the region
				var region = flood_fill_room_region(grid, pos)
				if region.size() > 20:  # Only process if above size threshold
					var center = get_room_center(region)
					var closest_dist = INF
					var has_connection = false
					
					# Check multiple points for connection
					var check_points = [center]
					for i in range(0, min(10, region.size()), max(1, region.size() / 10)):
						check_points.append(region[i])
					
					for check_pos in check_points:
						if distance_map.has(check_pos) and distance_map[check_pos] > 0:
							has_connection = true
							if distance_map[check_pos] < closest_dist:
								closest_dist = distance_map[check_pos]
							break
					
					if has_connection:
						room_regions[next_room_id_counter] = {
							"region": region,
							"center": center,
							"distance": closest_dist,
							"is_primary": false  # Mark as secondary (found by scanning)
						}
						next_room_id_counter += 1
					else:
						print("Found unconnected room at", center, "size:", region.size())
				
				# Mark all positions in this region as visited
				for p in region:
					visited[p] = true

	# Convert room_regions to array and sort by distance
	var sorted_rooms = []
	for room_id in room_regions:
		var room = room_regions[room_id]
		sorted_rooms.append({
			"id": room_id,
			"region": room.region,
			"center": room.center,
			"distance": room.distance,
			"is_primary": room.is_primary
		})
	
	sorted_rooms.sort_custom(func(a, b): return a.distance < b.distance)
	
	# Assign tiers
	var total_rooms = sorted_rooms.size()
	for i in range(total_rooms):
		var room = sorted_rooms[i]
		var tier = "common"
		var distance_ratio = float(i) / total_rooms
		
		if distance_ratio > 0.9:  # Top 10% farthest rooms
			tier = "epic"
		elif distance_ratio > 0.6:  # Next 30% farthest rooms
			tier = "rare"
		
		print("Room ",room.id," at ",room.center," distance: ",room.distance ,"tier: ",tier,"(",i+1,"/",total_rooms,")")
		
		# Update the grid
		var tile_value = loot_tile_for(tier)
		for pos in room.region:
			if pos.y < grid.size() and pos.x < grid[0].size():
				grid[pos.y][pos.x] = tile_value
		
		# Only store primary rooms in the rooms dictionary
		if room.is_primary:
			rooms[room.id] = {
				"id": room.id,
				"coords": room.region,
				"center": room.center,
				"tier": tier,
				"distance": room.distance
			}
		
		processed_rooms += 1

	print("Processed ",processed_rooms," rooms, skipped ",skipped_rooms," rooms")
	return grid

# Helper function to flood fill a room region
static func flood_fill_room_region(grid: Array, start_pos: Vector2i) -> Array:
	var region = []
	var queue = [start_pos]
	var visited = {}
	visited[start_pos] = true
	
	while queue.size() > 0:
		var pos = queue.pop_front()
		region.append(pos)
		
		for dir in [Vector2i(0,1), Vector2i(0,-1), Vector2i(1,0), Vector2i(-1,0)]:
			var next_pos = pos + dir
			if next_pos.x < 0 or next_pos.x >= grid[0].size() or next_pos.y < 0 or next_pos.y >= grid.size():
				continue
			if visited.has(next_pos):
				continue
			if grid[next_pos.y][next_pos.x] != 2:  # Not a room tile
				continue
				
			visited[next_pos] = true
			queue.append(next_pos)
	
	return region
