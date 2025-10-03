extends Node2D

@onready var tilemap := $TileMapLayer

var map_width := 300
var map_height := 150
var surface_height := 60  # top half is surface
var seed := 12345
var map_grid := []
var surface_bottom = -1
var tunnel_top = -1
var min_distance = 100
var best_pos

# Dictionary to store room data
# Key: Room ID (auto-incremented)
# Value: Dictionary with room data including 'coords' (Array of Vector2i) and 'tier' (String)
var rooms := {}
var next_room_id := 0

func _ready():
	initialize_empty_grid(map_grid, map_width, map_height)
	generate_surface_layer(map_grid, map_width, map_height, surface_height, seed,"mountains")
	var tunnel_path = carve_horizontal_tunnel(map_grid, 80, 300, 7, seed)
	
	for i in range(2):
		roughen_tunnel_floor_with_moore(map_grid, map_width, map_height)
	smooth_tunnel(map_grid, map_width, map_height)
	var closest_pos = find_min_surface_tunnel_distance(map_grid, map_width, map_height)
	print("Closest surface-tunnel column at x =", closest_pos)
	carve_cave_entrance(map_grid, Vector2i(closest_pos.x,closest_pos.y ),tunnel_path,map_width,map_height)
	var tunnel_path_2 = carve_horizontal_tunnel(map_grid,30,300,10,seed)
	var distant_x = find_distant_column(closest_pos.x, map_width, seed, 80)
	var tunnel11_y = get_tunnel_y_from_path(tunnel_path, distant_x, "floor")
	carve_cave_entrance(map_grid, Vector2i(distant_x, tunnel11_y),tunnel_path_2,map_width,map_height)

	var room_tiles_1 = generate_tunnel_rooms(map_grid, tunnel_path, map_width, map_height, seed)
	var room_tiles_2 = generate_tunnel_rooms(map_grid, tunnel_path_2, map_width, map_height, seed)
	var all_room_tiles := {}
	for key in room_tiles_1.keys():
		all_room_tiles[key] = room_tiles_1[key]
	for key in room_tiles_2.keys():
		all_room_tiles[key + room_tiles_1.size()] = room_tiles_2[key]
	var spawn_pos = find_valid_spawn(map_grid, closest_pos.x, map_height)
	enclose_grid(map_grid, map_width, map_height)
	analyze_and_decorate_rooms(map_grid, all_room_tiles,Vector2i(spawn_pos.x,map_height - spawn_pos.y))
	print("Start tile value:", map_grid[spawn_pos.y][spawn_pos.x])
	tilemap.clear()
	draw_grid_to_tilemap()
	for x in range(-1,2):
		for y in range(-1,2):
			tilemap.set_cell(spawn_pos,0,Vector2i(0,4))
	print("Start tile value:", map_grid[spawn_pos.y][spawn_pos.x])
	#await visualize_flood_fill_wave_fast(tilemap, map_grid, Vector2i(spawn_pos.x,map_height - spawn_pos.y))

func visualize_flood_fill_wave_fast(tilemap: TileMapLayer, grid: Array, start: Vector2i) -> void:
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
			if grid[next.y][next.x] != 0 and grid[next.y][next.x] != 2 and grid[next.y][next.x] != 4 and grid[next.y][next.x] != 5 and grid[next.y][next.x] != 6:
				continue

			visited[next] = true
			distance[next] = dist + 1
			queue.append(next)

	# Group positions by distance
	var bands := {}
	for pos in distance.keys():
		var dist = distance[pos]
		if not bands.has(dist):
			bands[dist] = []
		bands[dist].append(pos)

	# Draw each band per frame
	var sorted_keys := bands.keys()
	sorted_keys.sort()
	for dist in sorted_keys:
		for pos in bands[dist]:
			tilemap.set_cell(Vector2i(pos.x, map_height - pos.y - 1), 0, Vector2i(5, 4))
		await get_tree().process_frame  # One band per frame


func grid_to_vector2i(y,x):
	var vector_coords : Vector2i = Vector2i(x,map_height - y)
	return vector_coords

func show_():
	for y in range(map_height - 2, 0, -1):
		print(map_grid[y][1])
		if map_grid[y][1] == 0 and map_grid[y + 1][1] == 1:
			tunnel_top = y
			print("tunnel_top = ",y)
		if y > tunnel_top:
			if map_grid[y][1] == 1 and map_grid[y + 1][1] == 0 :
				surface_bottom = y
				print("surface_bottom = ",y)
		
		if surface_bottom != -1 and tunnel_top != -1:
			if tunnel_top > surface_bottom:
				continue  # tunnel must be below surface
			var distance = surface_bottom - tunnel_top
			if distance < min_distance:
				min_distance = distance
				best_pos = Vector2i(1, surface_bottom)
	print(best_pos)
	print(min_distance)
		
func initialize_empty_grid(grid: Array, width: int, height: int):
	grid.clear()
	for y in range(height):
		var row := []
		for x in range(width):
			row.append(0 if y >= 86 else 1)
		grid.append(row)

func generate_surface_layer(grid: Array, width: int, height: int, surface_height: int, seed: int, terrain_type := "plain", cutoff := 0):
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
				
func enclose_grid(grid: Array, map_width: int, map_height: int):
	for x in range(map_width):
		grid[0][x] = 1  # top border
		grid[map_height - 1][x] = 1  # bottom border

	for y in range(map_height):
		grid[y][0] = 1  # left border
		grid[y][map_width - 1] = 1  # right border


func carve_horizontal_tunnel(grid: Array, start_y: int, length: int, tunnel_width: int, seed: int, roughness := 0.2, curvyness := 0.3, max_shift := 2) -> Array:
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

func roughen_tunnel_floor_with_moore(grid: Array, width: int, height: int, seed := 98765):
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

func smooth_tunnel(grid: Array, width: int, height: int, threshold := 5):
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

func get_tunnel_y_from_path(tunnel_path: Array, x: int, mode := "floor") -> int:
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

func find_distant_column(reference_x: int, map_width: int, seed: int, min_distance := 150) -> int:
	var candidates := []
	for x in range(10, map_width - 10):
		if abs(x - reference_x) >= min_distance:
			candidates.append(x)
	if candidates.size() == 0:
		return -1
	var rng = RandomNumberGenerator.new()
	rng.seed = seed + 999
	return candidates[rng.randi_range(0, candidates.size() - 1)]

func find_min_surface_tunnel_distance(grid: Array, map_width: int, map_height: int) -> Vector2i:
	var min_distance := map_height
	var best_pos := Vector2i(-1, -1)

	for x in range(5, map_width - 5):
		var surface_bottom := -1
		var tunnel_top := -1

		for y in range(map_height - 2, 0, -1):
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

func draw_grid_to_tilemap():
	for y in range(map_height):
		for x in range(map_width):
			var cell_pos = Vector2i(x, map_height - y - 1)
			if map_grid[y][x] == 1:
				tilemap.set_cell(cell_pos, 0, Vector2i(0, 1))  # solid
			elif map_grid[y][x] == 2:#tunnel rooms
				tilemap.set_cell(cell_pos, 0, Vector2i(7, 0))  
			elif map_grid[y][x] == 3:#tunnel 2 entrance
				tilemap.set_cell(cell_pos, 0, Vector2i(8, 0))
			elif map_grid[y][x] == 4:#tunnel 2 entrance
				tilemap.set_cell(cell_pos, 0, Vector2i(0, 9))
			elif map_grid[y][x] == 5:#tunnel 2 entrance
				tilemap.set_cell(cell_pos, 0, Vector2i(2, 9))
			elif map_grid[y][x] == 6:#tunnel 2 entrance
				tilemap.set_cell(cell_pos, 0, Vector2i(1, 15))

func carve_cave_entrance(grid: Array, start: Vector2i, tunnel_path: Array, width: int, height: int, direction_bias := 0.2):
	var pos = start
	var directions = [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]
	var main_direction := Vector2i(0, 1)
	var tunnel_set := {}
	var rng = RandomNumberGenerator.new()
	for p in tunnel_path:
		tunnel_set[str(p)] = true

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

func carve_simple_random_walk(grid: Array, start: Vector2i, steps := 100, direction := Vector2i(1, 0), direction_bias := 0.25) -> Array:
	var pos = start
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var base_directions = [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]

	var carved_positions: Array = []

	for i in range(steps):
		if pos.x < 5 or pos.x >= grid[0].size() - 5 or pos.y < 1 or pos.y >= grid.size() - 1:
			break

		for y in range(-2, 3):
			for x in range(-1, 2):
				var carve_pos = Vector2i(pos.x + x, pos.y + y)
				grid[carve_pos.y][carve_pos.x] = 2
				if not carved_positions.has(carve_pos):
					carved_positions.append(carve_pos)

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

	return carved_positions
	
func generate_tunnel_rooms(grid: Array, tunnel_path: Array, width: int, height: int, seed: int) -> Dictionary:
	var roof_starts := []
	var floor_starts := []
	var room_starts := []
	var room_tiles := {}  # Dictionary to hold room_number: [Vector2i, ...]

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

	var room_index := 0

	for i in range(0, roof_starts.size(), 10):
		if i < roof_starts.size():
			var start = roof_starts[i]
			var dir = Vector2i(-1, -1) if rng.randf() < 0.5 else Vector2i(1, -1)
			room_starts.append(start)
			var carved = carve_simple_random_walk(grid, start, 150, dir)
			room_tiles[room_index] = carved
			room_index += 1

	for i in range(0, floor_starts.size(), 10):
		if i < floor_starts.size():
			var start = floor_starts[i]
			var dir = Vector2i(-1, 1) if rng.randf() < 0.5 else Vector2i(1, 1)
			room_starts.append(start)
			var carved = carve_simple_random_walk(grid, start, 150, dir)
			room_tiles[room_index] = carved
			room_index += 1

	return room_tiles
	
func find_valid_spawn(grid: Array, x: int, map_height: int) -> Vector2i:
	for y in range(map_height):
		if grid[y][x] == 0 or grid[y][x] == 2:
			return Vector2i(x, y)
	return Vector2i(x, 0)  # fallback

func flood_fill_region(grid: Array, start: Vector2i) -> Array:
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
	
func get_room_center(region: Array) -> Vector2i:
	var sum_x := 0
	var sum_y := 0
	for pos in region:
		sum_x += pos.x
		sum_y += pos.y
	return Vector2i(sum_x / region.size(), sum_y / region.size())

func flood_fill_distance(grid: Array, start: Vector2i) -> Dictionary:
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

func loot_tile_for(tier: String) -> int:
	match tier:
		"common": return 4
		"rare": return 5
		"epic": return 6
		_: return 2

func analyze_and_decorate_rooms(grid: Array, room_tiles: Dictionary, player_spawn: Vector2i):
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
		if closest_dist > max_dist * 0.86:
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
