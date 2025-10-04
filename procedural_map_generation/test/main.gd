extends Node2D

@onready var tilemap := $TileMapLayer
@onready var items : Node2D = $Items

var map_width := 300
var map_height := 150
var surface_height := 60
var seed := 12345
var map_grid := []
var surface_bottom = -1
var tunnel_top = -1
var min_distance = 100
var best_pos

var rooms := {}
var next_room_id := 0


const GridUtils = preload("res://procedural_map_generation/test/GridUtils.gd")
const TunnelGen = preload("res://procedural_map_generation/test/TunnelGen.gd")
const TunnelConnector = preload("res://procedural_map_generation/test/TunnelConnector.gd")
const TunnelRooms = preload("res://procedural_map_generation/test/TunnelRooms.gd")
const TunnelUtils = preload("res://procedural_map_generation/test/TunnelUtils.gd")
const TilemapDraw = preload("res://procedural_map_generation/test/TileMapDraw.gd")
const RoomAnalyzer = preload("res://procedural_map_generation/test/RoomAnalyzer.gd")

func _ready():
	tilemap.clear()
	GridUtils.initialize_empty_grid(map_grid, map_width, map_height)
	GridUtils.generate_surface_layer(map_grid, map_width, map_height, surface_height, seed)

	var tunnel_path = TunnelGen.carve_horizontal_tunnel(map_grid, 80, 300, 7, seed)
	for i in range(2):
		TunnelGen.roughen_tunnel_floor_with_moore(map_grid, map_width, map_height)
	TunnelGen.smooth_tunnel(map_grid, map_width, map_height)

	var closest_pos = TunnelUtils.find_min_surface_tunnel_distance(map_grid, map_width, map_height)
	#print("Closest surface-tunnel column at x =", closest_pos)

	TunnelConnector.carve_cave_entrance(map_grid, closest_pos, tunnel_path, map_width, map_height)

	var tunnel_path_2 = TunnelGen.carve_horizontal_tunnel(map_grid, 30, 300, 10, seed)
	var distant_x = TunnelUtils.find_distant_column(closest_pos.x, map_width, seed, 80)
	var tunnel11_y = TunnelUtils.get_tunnel_y_from_path(tunnel_path, distant_x, "floor")

	TunnelConnector.carve_cave_entrance(map_grid, Vector2i(distant_x, tunnel11_y), tunnel_path_2, map_width, map_height)
	
	var room_tiles_1 = TunnelRooms.generate_tunnel_rooms(map_grid, tunnel_path, map_width, map_height, seed)
	var room_tiles_2 = TunnelRooms.generate_tunnel_rooms(map_grid, tunnel_path_2, map_width, map_height, seed)
	
	var all_room_tiles := {}
	for key in room_tiles_1.keys():
		all_room_tiles[key] = room_tiles_1[key]
	for key in room_tiles_2.keys():
		all_room_tiles[key + room_tiles_1.size()] = room_tiles_2[key]
	
	var spawn_pos = find_valid_spawn(map_grid, closest_pos.x, map_height)
	GridUtils.enclose_grid(map_grid, map_width, map_height)
	RoomAnalyzer.analyze_and_decorate_rooms(map_grid, all_room_tiles, Vector2i(spawn_pos.x,map_height - spawn_pos.y),rooms,next_room_id)
	
	merge_connected_rooms(rooms)
	var distance_result = RoomAnalyzer.flood_fill_distance(map_grid, Vector2i(spawn_pos.x, map_height - spawn_pos.y))
	var distance_map = distance_result["map"]
	
	TilemapDraw.draw_grid_to_tilemap(tilemap, map_grid, map_width, map_height)
	spawn_items_in_rooms(rooms, 1,distance_map)
	#await visualize_flood_fill_wave_fast(tilemap, map_grid, Vector2i(spawn_pos.x,map_height - spawn_pos.y))
	for x in range(-3, 4):
		for y in range(-3, 4):
			tilemap.set_cell(spawn_pos + Vector2i(x,y), 0, Vector2i(0, 4))

static func find_valid_spawn(grid: Array, x: int, map_height: int) -> Vector2i:
	for y in range(map_height):
		if grid[y][x] == 0 or grid[y][x] == 2:
			return Vector2i(x, y)
	return Vector2i(x, 0)  # fallback

static func get_player_pos():
	print("player_spawn:-----------------------------------",Vector2i(Global.player_position))

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
			tilemap.set_cell(Vector2i(pos.x, map_height - pos.y ), 0, Vector2i(5, 4))
		await get_tree().process_frame  # One band per frame

func get_heal_amount(effect: String) -> int:
	if effect.begins_with("heal - "):
		return int(effect.replace("heal - ", ""))
	return 0

var tier_order = ["common", "rare", "epic"]

func tier_index(tier: String) -> int:
	return tier_order.find(tier)

func spawn_items_in_rooms(room_data: Dictionary, count_per_room : int, distance_map: Dictionary):
	for room_id in room_data.keys():
		var room = room_data[room_id]
		var coords = room["coords"]
		var distance = room["distance"]
		var valid_cells := []

		var best_tile := find_flat_spawn_tile(room_id,room_data,distance_map)
		var cell_pos = Vector2i(best_tile.x, map_height - best_tile.y )
		var world_pos = tilemap.map_to_local(cell_pos)
		valid_cells.append(world_pos)

		if valid_cells.size() == 0:
			print("Room", room_id, "has no valid floor spawn cells")
			continue

		valid_cells.shuffle()

		# Healing threshold based on distance
		var heal_threshold := 100
		if distance > 200:
			heal_threshold = 150
		elif distance > 100:
			heal_threshold = 120

		var item_pool := []
		for item in InventoryGlobal.items:
			if get_heal_amount(item["item_effect"]) >= heal_threshold:
				item_pool.append(item)

		if item_pool.size() == 0:
			print("Room", room_id, "has no matching items for heal threshold", heal_threshold)
			continue

		var item_data = item_pool[randi() % item_pool.size()]
		var quantity = randi() % 5 + 1
		spawn_item(quantity, item_data, valid_cells[0])

		var cell = tilemap.local_to_map(valid_cells[0])
		tilemap.set_cell(cell, 0, Vector2i(0, 9))
		#print("Spawned", item_data["item_name"], "x", quantity, "in room", room_id)

func spawn_item(quantity,data,position):
	var item_scene = preload("res://inventory/scenes/game_item.tscn")
	var item_instance = item_scene.instantiate()
	item_instance.initiate_items(quantity+1,data["item_name"],data["item_type"],data["item_effect"],data["item_texture"])
	#print(quantity+1,data["item_name"],data["item_type"],data["item_effect"],data["item_texture"])
	item_instance.global_position = position
	items.add_child(item_instance)
	
func merge_connected_rooms(input_rooms: Dictionary):
	var merged := {}
	var visited := {}
	var room_groups := []

	for room_id in input_rooms.keys():
		var tile_set = input_rooms[room_id]["coords"]
		input_rooms[room_id]["tile_set"] = tile_set

	for room_id in input_rooms.keys():
		if visited.has(room_id):
			continue

		var group := []
		var queue := [room_id]
		visited[room_id] = true

		while queue.size() > 0:
			var current = queue.pop_front()
			group.append(current)

			for other_id in input_rooms.keys():
				if visited.has(other_id):
					continue
				if rooms_touch(input_rooms[current]["coords"], input_rooms[other_id]["coords"]):
					queue.append(other_id)
					visited[other_id] = true

		# Merge group
		var merged_coords := []
		var max_distance := 0
		var best_tier := "common"
		for id in group:
			merged_coords += input_rooms[id]["coords"]
			max_distance = max(max_distance, input_rooms[id]["distance"])
			if tier_index(input_rooms[id]["tier"]) > tier_index(best_tier):
				best_tier = input_rooms[id]["tier"]

		# Overwrite rooms dict
		var new_id := merged.size()
		merged[new_id] = {
			"id": new_id,
			"coords": merged_coords,
			"distance": max_distance,
			"tier": best_tier
		}
	rooms = merged
	
func rooms_touch(coords_a: Array, coords_b: Array) -> bool:
	var set_b := {}
	for p in coords_b:
		set_b[Vector2i(p.x, p.y)] = true

	for p in coords_a:
		for dir in [Vector2i(0,1), Vector2i(0,-1), Vector2i(1,0), Vector2i(-1,0)]:
			var neighbor = Vector2i(p.x, p.y) + dir
			if set_b.has(neighbor):
				return true
	return false

func find_flat_spawn_tile(room_id: int, room_data: Dictionary, distance_map: Dictionary) -> Vector2i:
	var best_tile = null
	var max_distance := -1
	var coords = room_data[room_id]["coords"]

	for pos in coords:
		var x = pos.x
		var y = pos.y

		if y >= 3 and x > 0 and x < map_width - 1:
			if map_grid[y - 1][x] == 1 and map_grid[y - 1][x - 1] == 1 and map_grid[y - 1][x + 1] == 1 and map_grid[y - 1][x + 2] == 1 and map_grid[y - 1][x - 2] == 1:
				if map_grid[y][x] in [4,5,6] and map_grid[y + 1][x] in [4,5,6] and map_grid[y + 2][x] in [4,5,6]:
					var grid_pos = Vector2i(x, y)
					if not distance_map.has(grid_pos):
						print("Skipping unreachable tile:", grid_pos)
						tilemap.set_cell(Vector2i(grid_pos.x,grid_pos.y),0,Vector2i(0,9))
						continue
					var dist = distance_map[grid_pos]
					if dist > max_distance:
						max_distance = dist
						best_tile = Vector2i(x, y)

	return best_tile if best_tile != null else count_()

var count = 0
var x = -1
func count_():
	if count < 100:
		var position = Vector2i(x,-1)
		print("count_")
		x += 1
		count+= 1
		return position
	
