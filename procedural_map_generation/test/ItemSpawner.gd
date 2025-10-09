extends Node

class_name ItemSpawner

static func get_heal_amount(effect: String) -> int:
	if effect.begins_with("heal - "):
		return int(effect.replace("heal - ", ""))
	return 0

static func spawn_items_in_rooms(room_data: Dictionary, count_per_room: int, distance_map: Dictionary, tilemap: TileMapLayer, items: Node2D, map_grid: Array, map_width: int, map_height: int) -> void:
	for room_id in room_data.keys():
		var room = room_data[room_id]
		var coords = room["coords"]
		var distance = room["distance"]
		var valid_cells := []

		var best_tile := find_flat_spawn_tile(room_id, room_data, distance_map, map_grid, map_width, map_height, tilemap)
		if best_tile.y == -1:
			print("Room", room_id, "skipped: no valid spawn tile found")
			continue
		var cell_pos = Vector2i(best_tile.x, map_height - best_tile.y)
		var world_pos = tilemap.map_to_local(cell_pos)
		valid_cells.append(world_pos)

		if valid_cells.size() == 0:
			print("Room", room_id, "has no valid floor spawn cells")
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
			print("Room", room_id, "has no matching items for heal threshold", heal_threshold)
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
			if map_grid[y][x] == 2:  # solid room tile
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
