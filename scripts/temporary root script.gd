extends Node2D

@onready var tilemap := $TileMapLayer
@onready var ground_layer := $TileMapLayer
@onready var decor_layer := $DecorLayer
@onready var items : Node2D = $Items
const WIDTH := 512
const HEIGHT := 128
const SURFACE_HEIGHT := 64
const TILE_SIZE := 16

var noise := FastNoiseLite.new()

func _ready():
	setup_noise()
	generate_terrain()
	generate_caves()

func setup_noise():
	noise.seed = randi()
	noise.frequency = 0.01
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.fractal_octaves = 4
	noise.fractal_gain = 0.5

func generate_terrain():
	for x in range(WIDTH):
		var height = int(noise.get_noise_1d(x) * 10.0 + SURFACE_HEIGHT)
		for y in range(HEIGHT):
			var tile_id := get_tile_for_position(x, y, height)
			if tile_id != -1:
				ground_layer.set_cell(Vector2i(x,y),0, Vector2i(0,0))

		# Decor pass (e.g., grass, trees)
		if randf() < 0.05:
			decor_layer.set_cell(Vector2i(x, height - 1),0, Vector2i(0,1))

func get_tile_for_position(x: int, y: int, surface_y: int) -> int:
	if y == surface_y:
		return 0  # Grass tile
	elif y > surface_y and y < surface_y + 6:
		return 1  # Dirt tile
	elif y >= surface_y + 6:
		return 2  # Stone tile
	return -1  # Empty

func get_decor_tile(x: int, y: int) -> int:
	return 3  # Example: flower or tree tile

func spawn_random_items(count):
	var attempts = 0
	var spawned_count = 0
	
	# Get all used cells from the tilemap
	var used_cells = tilemap.get_used_cells()  # 0 is the layer index
	
	# Convert cells to world positions
	var valid_positions = []
	for cell in used_cells:
		var pos = tilemap.map_to_local(cell)
		pos -= Vector2(-20,20)  # Move position up by 1 unit
		valid_positions.append(pos)
	
	# Shuffle the positions to get random ones
	valid_positions.shuffle()
	
	while spawned_count < count and attempts < 10 and valid_positions.size() > 0:
		if valid_positions.size() > 0:
			var spawn_position = valid_positions.pop_front()
			spawned_count += 1
			spawn_item(randi() % 5,InventoryGlobal.items[randi() % InventoryGlobal.items.size()],spawn_position)
		else:
			break
		attempts += 1
	
	return spawned_count  # Return how many items were actually spawned

func spawn_item(quantity,data,position):
	var item_scene = preload("res://inventory/scenes/game_item.tscn")
	var item_instance = item_scene.instantiate()
	item_instance.initiate_items(quantity+1,data["item_name"],data["item_type"],data["item_effect"],data["item_texture"])
	print(quantity+1,data["item_name"],data["item_type"],data["item_effect"],data["item_texture"])
	item_instance.global_position = position
	items.add_child(item_instance)
	
func generate_caves():
	for i in range(20):  # Number of cave seeds
		var start_x = randi() % WIDTH
		var start_y = SURFACE_HEIGHT + randi() % (HEIGHT - SURFACE_HEIGHT)
		carve_cave(Vector2i(start_x, start_y), 12, 60)

func carve_cave(start: Vector2i, strength: int, steps: int):
	var pos = start
	for i in range(steps):
		for dx in range(-strength, strength):
			for dy in range(-strength, strength):
				var dist = Vector2(dx, dy).length()
				if dist < strength:
					ground_layer.erase_cell(Vector2i(pos.x + dx, pos.y + dy))  # Clear tile
		pos += Vector2i(randi() % 3 - 1, randi() % 3 - 1)
		strength = max(4, strength - 1)
