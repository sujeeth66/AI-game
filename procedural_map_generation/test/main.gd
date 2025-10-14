extends Node2D

@onready var tilemap := $TileMapLayer
@onready var items : Node2D = $Items
@onready var item_spawner = $ItemSpawner  # Make sure ItemSpawner is a child node

var map_width 
var map_height 
var surface_height := 65
var seed := 12345
var map_grid := []
var surface_bottom = -1
var tunnel_top = -1
var min_distance = 100
var best_pos
var terrain_change = []
var rooms := {}
var next_room_id := 0
var level_plan = {
	"surface": {
		"type": "forest",
		"segments": [
			{ "type": "city", "length": 300 },
			#{ "type": "forest", "length": 100 },
			#{ "type": "mountains", "length": 80 }
		]
	},
	"underground": {
		"type": "caves",
		"tunnels": 0,
		"room_shape": "organic"
	}
}
var city_segments = [
	{ "type": "road", "length": 40, "height":45 },
	{ "type": "building", "length": 40, "height":40 },
	{ "type": "park", "length": 60, "height":45 },
	{ "type": "building", "length": 40, "height":65 },
	{ "type": "road", "length": 6, "height":40 },
	{ "type": "road", "length": 60, "height":60 }
]

const GridUtils = preload("res://procedural_map_generation/test/GridUtils.gd")
const TunnelGen = preload("res://procedural_map_generation/test/TunnelGen.gd")
const TunnelConnector = preload("res://procedural_map_generation/test/TunnelConnector.gd")
const TunnelRooms = preload("res://procedural_map_generation/test/TunnelRooms.gd")
const TunnelUtils = preload("res://procedural_map_generation/test/TunnelUtils.gd")
const TilemapDraw = preload("res://procedural_map_generation/test/TileMapDraw.gd")
const RoomAnalyzer = preload("res://procedural_map_generation/test/RoomAnalyzer.gd")
const ItemSpawner = preload("res://procedural_map_generation/test/ItemSpawner.gd")
const MapGen = preload("res://procedural_map_generation/test/MapGeneration.gd")

func _ready():
	tilemap.clear()
	var dims = MapGen.compute_map_dimensions(level_plan["surface"]["segments"], level_plan["underground"], surface_height, 30)
	map_width = dims["width"]
	map_height = dims["height"]
	print("map width and height: ",map_width,",",map_height)
	GridUtils.initialize_empty_grid(map_grid, map_width, map_height,surface_height)
	var x_cursor = 0
	var last_heights = {}
	
	for segment in level_plan["surface"]["segments"]:
		var segment_length = segment["length"]
		var terrain_type = segment["type"]
		var end_x = x_cursor + segment_length

		if terrain_type == "city":
			print("city----------------------")
			last_heights = GridUtils.generate_city_surface(map_grid,map_height,surface_height, x_cursor, city_segments, 0)
			var city_total_length = 0
			for seg in city_segments:
				city_total_length += seg["length"]
			x_cursor += city_total_length
		else:
			last_heights = GridUtils.generate_surface_layer(
				map_grid,
				map_width,
				map_height,
				surface_height,
				seed,
				terrain_type,
				x_cursor,
				end_x,
				0,
				last_heights
			)
			x_cursor = end_x
		terrain_change.append(x_cursor)
	
	var ug = level_plan["underground"]
	var tunnel_y_start =  25  # start carving below surface
	var tunnel_paths := []
	var tunnel_y = tunnel_y_start  * 50
	if ug["tunnels"] != 0:
		for i in range(ug["tunnels"]):
			if ug["room_shape"] == "flat":
				tunnel_y = tunnel_y_start + i * 25
			elif ug["room_shape"] == "organic":
				tunnel_y = tunnel_y_start + i * 50
			
			var tunnel_path = TunnelGen.carve_horizontal_tunnel(
				map_grid, tunnel_y, map_width, 10, seed, 0.2, 0.3, 2,10, ug["room_shape"]
			)
			print("tunnel made")
			tunnel_paths.append(tunnel_path)
		
		var last_entrance_x = 0
		var closest_pos = TunnelUtils.find_min_surface_tunnel_distance(map_grid, map_width, map_height)
		var spawn_pos = find_valid_spawn(map_grid, closest_pos.x, map_height)
		var previous_tunnel_path = null
		for i in range(tunnel_paths.size() - 1, -1, -1):
			var tunnel_path = tunnel_paths[i]
			if previous_tunnel_path == null:
				# First tunnel: carve from surface
				TunnelConnector.carve_cave_entrance(map_grid, closest_pos, tunnel_path, map_width, map_height)
				last_entrance_x = closest_pos.x
			else:
				# Subsequent tunnels: carve from previous tunnel
				var distant_x = TunnelUtils.find_distant_column(last_entrance_x, map_width, seed, 80)
				last_entrance_x = distant_x
				var upper_y = TunnelUtils.get_tunnel_y_from_path(previous_tunnel_path, distant_x, "floor")
				if upper_y == -1:
					print("Entrance skipped: no upper tunnel at x =", distant_x)
					continue

				TunnelConnector.carve_cave_entrance(map_grid, Vector2i(distant_x, upper_y), tunnel_path, map_width, map_height)
			# Update previous tunnel reference
			previous_tunnel_path = tunnel_path
		if ug["room_shape"] == "flat":
			ItemSpawner.spawn_boss_reward(tilemap,items,map_grid,map_width,map_height,ug["tunnels"])
		else:
			var all_room_tiles := {}
			for tunnel_path in tunnel_paths:
				var room_tiles = TunnelRooms.generate_tunnel_rooms(map_grid, tunnel_path, map_width, map_height, seed)
				for key in room_tiles.keys():
					all_room_tiles[key + all_room_tiles.size()] = room_tiles[key]
			
			RoomAnalyzer.analyze_and_decorate_rooms(map_grid, all_room_tiles, Vector2i(spawn_pos.x,map_height - spawn_pos.y),rooms,next_room_id)
			merge_connected_rooms(rooms)
			
		var distance_result = RoomAnalyzer.flood_fill_distance(map_grid, Vector2i(spawn_pos.x, map_height - spawn_pos.y))
		var distance_map = distance_result["map"]
		#ItemSpawner.spawn_items_in_rooms(rooms, distance_map, tilemap, items, map_grid, map_width, map_height)
		# Spawn chests in rooms instead of individual items
		ItemSpawner.spawn_chests_in_rooms(rooms, distance_map, tilemap, items, map_grid, map_width, map_height)
		#await visualize_flood_fill_wave_fast(tilemap, map_grid, Vector2i(spawn_pos.x,map_height - spawn_pos.y))
		#print("Processed ",processed_rooms," rooms, skipped ",skipped_rooms," rooms")
		#print("Room ",room.id," at ",room.center," distance: ",room.distance ,"tier: ",tier,"(",i+1,"/",total_valid,")")
		for x in range(1):
			for y in range(1):
				tilemap.set_cell(spawn_pos + Vector2i(x,y), 0, Vector2i(0, 4))
				tilemap.set_cell(Vector2i(closest_pos.x,150-closest_pos.y), 0, Vector2i(5, 4))

	GridUtils.enclose_grid(map_grid, map_width, map_height)
	TilemapDraw.draw_grid_to_tilemap(tilemap, map_grid, map_width, map_height)
	
	for i in terrain_change:
		tilemap.set_cell(Vector2i(i,10),0,Vector2i(0,9))
		tilemap.set_cell(Vector2i(i,11),0,Vector2i(0,9))
		tilemap.set_cell(Vector2i(i,12),0,Vector2i(0,9))
		tilemap.set_cell(Vector2i(i,13),0,Vector2i(0,9))
		tilemap.set_cell(Vector2i(i,14),0,Vector2i(0,9))
	
	

func __ready():
	tilemap.clear()
	GridUtils.initialize_empty_grid(map_grid, map_width, map_height,surface_height)
	#GridUtils.generate_surface_layer(map_grid, map_width, map_height, surface_height, seed)

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
	ItemSpawner.spawn_items_in_rooms(rooms, distance_map, tilemap, items, map_grid, map_width, map_height)
	#await visualize_flood_fill_wave_fast(tilemap, map_grid, Vector2i(spawn_pos.x,map_height - spawn_pos.y))
	for x in range(-3, 4):
		for y in range(-3, 4):
			tilemap.set_cell(spawn_pos + Vector2i(x,y), 0, Vector2i(0, 4))

static func find_valid_spawn(grid: Array, x: int, map_height: int) -> Vector2i:
	for y in range(map_height):
		if grid[y][x] == 0 or grid[y][x] == 2:
			print("cave or room",y)
			return Vector2i(x, 6)
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
			if grid[next.y][next.x] != 0 and grid[next.y][next.x] != 2 and grid[next.y][next.x] != 4 and grid[next.y][next.x] != 5 and grid[next.y][next.x] != 6 and grid[next.y][next.x] != 7:
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


func tier_index(tier: String) -> int:
	var tier_order = ["common", "rare", "epic"]
	return tier_order.find(tier)
