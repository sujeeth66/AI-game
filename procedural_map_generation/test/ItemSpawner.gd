extends Node

class_name ItemSpawner

static func get_heal_amount(effect: String) -> int:
	if effect.begins_with("heal - "):
		return int(effect.replace("heal - ", ""))
	return 0

static func spawn_chests_in_rooms(room_data: Dictionary, distance_map: Dictionary, tilemap: TileMapLayer, items: Node2D, map_grid: Array, map_width: int, map_height: int) -> void:
	# Preload chest and slime scenes
	var chest_scene = preload("res://scenes/Chest.tscn")
	var slime_scene = preload("res://scenes/slime.tscn")
	
	for room_id in room_data.keys():
		var room = room_data[room_id]
		var coords = room["coords"]
		var distance = room["distance"]
		var tier = room.get("tier", "common")
		
		# Find a valid spawn position using the existing function
		var best_tile := find_flat_spawn_tile(room_id, room_data, distance_map, map_grid, map_width, map_height, tilemap)
		if best_tile == Vector2i(-1, -1):
			#print("Room", room_id, " skipped: no valid spawn tile found for chest")
			continue
			
		# Convert to world position
		var cell_pos = Vector2i(best_tile.x, map_height - best_tile.y)
		var world_pos = tilemap.map_to_local(cell_pos)
		var tier_1_chest = preload("res://textures/tier_1_chest.png")
		var tier_2_chest = preload("res://textures/tier_2_chest.png")
		var tier_3_chest = preload("res://textures/tier_3_chest.png")
		# Create and configure the chest
		var chest = chest_scene.instantiate()
		if tier == "common":
			chest.set("item_texture",tier_1_chest)
		elif tier == "rare":
			chest.set("item_texture",tier_2_chest)
		elif tier == "epic":
			chest.set("item_texture",tier_3_chest)
		# Set properties through the script
		chest.set("room_tier", tier)
		chest.set("room_distance", distance)
		chest.position = world_pos
		
		# Add to scene
		items.add_child(chest)
		
		# Mark the tile (optional, can be used for pathfinding or other systems)
		var cell = tilemap.local_to_map(world_pos)
		tilemap.set_cell( cell, 0, Vector2i(0, 9))
		
		# Spawn 5 slimes around the chest
		spawn_slimes_around_chest(best_tile, tier, coords, map_grid, map_width, map_height, tilemap, items, slime_scene)
		
		#print("Spawned ", tier, " chest at ", world_pos, " in room ", room_id, " (distance: ", distance, ")")
		
static func get_room_tier(distance: float) -> String:
	if distance > 200:
		return "rare"
	elif distance > 100:
		return "uncommon"
	return "common"

static func get_slime_level_for_tier(tier: String) -> int:
	# Map chest tier to slime level
	match tier:
		"common":
			return 1
		"rare":
			return randi_range(2, 3)  # Rare chests get level 2-3 slimes
		"epic":
			return randi_range(4, 5)  # Epic chests get level 4-5 slimes
		_:
			return 1

static func spawn_slimes_around_chest(chest_tile: Vector2i, tier: String, room_coords: Array, map_grid: Array, map_width: int, map_height: int, tilemap: TileMapLayer, parent: Node2D, slime_scene: PackedScene) -> void:
	if not slime_scene:
		print("⚠️ Slime scene is null, cannot spawn slimes")
		return
	
	var slimes_to_spawn = 5
	var slimes_spawned = 0
	var slime_level = get_slime_level_for_tier(tier)
	
	# Find valid spawn positions around the chest within the room
	var valid_positions = find_valid_slime_positions_in_room(chest_tile, room_coords, map_grid, map_width, map_height, slimes_to_spawn)
	
	for tile_pos in valid_positions:
		if slimes_spawned >= slimes_to_spawn:
			break
		
		# Convert tile position to world position
		var cell_pos = Vector2i(tile_pos.x, map_height - tile_pos.y)
		var world_pos = tilemap.map_to_local(cell_pos) + Vector2(8, -24)  # Adjust for slime size
		
		# Instantiate and configure slime
		var slime = slime_scene.instantiate()
		slime.position = world_pos
		slime.debug_mode = false
		
		# Set level based on chest tier
		if slime.has_method("set_level"):
			slime.set_level(slime_level)
		
		parent.add_child(slime)
		slimes_spawned += 1
	
	if slimes_spawned > 0:
		print("Spawned ", slimes_spawned, " level ", slime_level, " slimes around ", tier, " chest")

static func find_valid_slime_positions_in_room(center_tile: Vector2i, room_coords: Array, map_grid: Array, map_width: int, map_height: int, max_positions: int) -> Array[Vector2i]:
	var valid_positions: Array[Vector2i] = []
	var search_radius = 10  # Search within 10 tiles of the chest
	
	# Convert room_coords to a set for faster lookup
	var room_tiles_set = {}
	for coord in room_coords:
		var key = str(coord.x) + "," + str(coord.y)
		room_tiles_set[key] = true
	
	# Search in a spiral pattern around the chest
	for radius in range(3, search_radius + 1):
		for angle in range(0, 360, 30):  # Check every 30 degrees
			var rad = deg_to_rad(angle)
			var offset_x = int(cos(rad) * radius)
			var offset_y = int(sin(rad) * radius)
			var check_tile = Vector2i(center_tile.x + offset_x, center_tile.y + offset_y)
			
			# Check if tile is in room and valid for spawning
			var key = str(check_tile.x) + "," + str(check_tile.y)
			if room_tiles_set.has(key) and is_valid_slime_spawn_tile(check_tile, map_grid, map_width, map_height):
				valid_positions.append(check_tile)
				if valid_positions.size() >= max_positions:
					return valid_positions
	
	return valid_positions

static func is_valid_slime_spawn_tile(tile: Vector2i, map_grid: Array, map_width: int, map_height: int) -> bool:
	# Check bounds
	if tile.x < 1 or tile.x >= map_width - 1 or tile.y < 2 or tile.y >= map_height - 1:
		return false
	
	# Check if there's solid ground below and empty space above (2 tiles for slime height)
	if map_grid[tile.y - 1][tile.x] == 1:  # Solid ground below
		if map_grid[tile.y][tile.x] in [4, 5, 6] and map_grid[tile.y + 1][tile.x] in [4, 5, 6]:  # Empty space above
			return true
	
	return false

static func spawn_items_in_rooms(room_data: Dictionary, distance_map: Dictionary, tilemap: TileMapLayer, items: Node2D, map_grid: Array, map_width: int, map_height: int) -> void:
	for room_id in room_data.keys():
		var room = room_data[room_id]
		var coords = room["coords"]
		var distance = room["distance"]
		var valid_cells := []

		var best_tile := find_flat_spawn_tile(room_id, room_data, distance_map, map_grid, map_width, map_height, tilemap)
		if best_tile.y == -1:
			#print("Room", room_id, "skipped: no valid spawn tile found")
			continue
		var cell_pos = Vector2i(best_tile.x, map_height - best_tile.y)
		var world_pos = tilemap.map_to_local(cell_pos)
		valid_cells.append(world_pos)

		if valid_cells.size() == 0:
			#print("Room", room_id, "has no valid floor spawn cells")
			continue

		valid_cells.shuffle()

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
			#print("Room", room_id, "has no matching items for heal threshold", heal_threshold)
			continue

		var item_data = item_pool[randi() % item_pool.size()]
		var quantity = randi() % 5 + 1
		spawn_item(quantity, item_data, valid_cells[0], items)

		var cell = tilemap.local_to_map(valid_cells[0])
		tilemap.set_cell(cell, 0, Vector2i(0, 9))

static func spawn_item(quantity, data, position, items: Node2D) -> void:
	var item_scene = preload("res://inventory/scenes/game_item.tscn")
	var item_instance = item_scene.instantiate()
	item_instance.initiate_items(quantity + 1, data["item_name"], data["item_type"], data["item_effect"], data["item_texture"])
	item_instance.global_position = position
	items.add_child(item_instance)

static func find_flat_spawn_tile(room_id: int, room_data: Dictionary, distance_map: Dictionary, map_grid: Array, map_width: int, map_height: int, tilemap: TileMapLayer) -> Vector2i:
	var best_tile = null
	var max_distance := -1
	var coords = room_data[room_id]["coords"]

	# First pass: look for open platforms
	for pos in coords:
		var x = pos.x
		var y = pos.y

		if is_open_platform(x, y, map_grid, map_width, map_height):
			var grid_pos = Vector2i(x, y)
			if not distance_map.has(grid_pos):
				print("Skipping unreachable tile:", grid_pos)
				tilemap.set_cell(Vector2i(grid_pos.x, grid_pos.y), 0, Vector2i(0, 9))
				continue

			var dist = distance_map[grid_pos]
			if dist > max_distance:
				max_distance = dist
				best_tile = grid_pos

	# If no platform found, fallback to highest-distance solid tile
	if best_tile == null:
		for pos in coords:
			var x = pos.x
			var y = pos.y
			var grid_pos = Vector2i(x, y)

			if not distance_map.has(grid_pos):
				continue
			if map_grid[y-1][x] == 1:  # solid room tile
				var dist = distance_map[grid_pos]
				if dist > max_distance:
					max_distance = dist
					best_tile = grid_pos

	return best_tile if best_tile != null else Vector2i(-1, -1)

static func is_open_platform(x: int, y: int, map_grid: Array, map_width: int, map_height: int) -> bool:
	if y < 3 or x < 2 or x >= map_width - 2:
		return false

	if map_grid[y - 1][x] != 1:
		return false
	if map_grid[y][x] not in [4,5,6] or map_grid[y + 1][x] not in [4,5,6] or map_grid[y + 2][x] not in [4,5,6]:
		return false

	for offset in [-2, -1, 1, 2]:
		var side_x = x + offset
		if map_grid[y - 1][side_x] != 1:
			return false
		if map_grid[y][side_x] not in [4,5,6] or map_grid[y + 1][side_x] not in [4,5,6] or map_grid[y + 2][side_x] not in [4,5,6]:
			return false

	return true

static func spawn_boss_reward(tilemap: TileMapLayer, items: Node2D, map_grid: Array, map_width: int, map_height: int, tunnels: int):
	var spawn_pos_tile
	if tunnels % 2 == 0:
		spawn_pos_tile = Vector2i(map_width-10,map_height-20)
	else:
		spawn_pos_tile = Vector2i(10,map_height-20)
		
	var heal_threshold := 100
	var item_pool := []
	for item in InventoryGlobal.items:
		if get_heal_amount(item["item_effect"]) >= heal_threshold:
			item_pool.append(item)

	if item_pool.size() == 0:
		print("Room has no matching items for heal threshold", heal_threshold)
	var spawn_pos = tilemap.map_to_local(spawn_pos_tile)
	print(spawn_pos)
	
	var item_data = item_pool[randi() % item_pool.size()]
	var quantity = randi() % 5 + 1
	spawn_item(quantity, item_data, spawn_pos, items)
	
	tilemap.set_cell(spawn_pos_tile, 0, Vector2i(0, 9))

# Remove static keyword
func spawn_chest_in_room(room_tiles: Dictionary, room_data: Dictionary, parent_node: Node) -> void:
	if room_tiles.is_empty():
		return
	
	var chest_scene = preload("res://scenes/chest.tscn")
	var chest = chest_scene.instantiate()
	
	# Find a suitable position in the room
	var floor_tiles = []
	for pos in room_tiles:
		if is_floor_tile(pos, parent_node):  # Check if it's a floor tile
			floor_tiles.append(pos)
	
	if floor_tiles.is_empty():
		return
	
	# Convert tile position to world position
	var tile_pos = floor_tiles[randi() % floor_tiles.size()]
	var world_pos = parent_node.map_to_world(tile_pos)
	
	# Position the chest
	chest.position = world_pos
	chest.setup_from_room(room_data)
	
	# Link enemies in this room to the chest
	var enemies_in_room = get_enemies_in_room(room_tiles, parent_node)
	for enemy in enemies_in_room:
		if enemy.has_method("set_linked_chest"):
			enemy.set_linked_chest(chest.chest_id)
			chest.required_enemy_ids.append(enemy.enemy_id)
	
	parent_node.add_child(chest)

# Helper function to check if a tile is a floor tile
func is_floor_tile(pos: Vector2, parent_node: Node) -> bool:
	# Adjust these based on your tile IDs
	var floor_tile_id = 0  # Your floor tile ID
	return parent_node.get_cell_source_id(0, pos) == floor_tile_id

# Get enemies in the specified room
func get_enemies_in_room(room_tiles: Dictionary, parent_node: Node) -> Array:
	var enemies_in_room = []
	var enemy_nodes = parent_node.get_tree().get_nodes_in_group("enemies")
	
	for enemy in enemy_nodes:
		var enemy_tile_pos = parent_node.world_to_map(enemy.global_position)
		if room_tiles.has(enemy_tile_pos):
			enemies_in_room.append(enemy)
	
	return enemies_in_room
