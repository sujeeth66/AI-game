extends Node2D

@onready var tilemap = $TileMapLayer
@onready var items: Node2D = $Items

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#get_window().mode = Window.MODE_FULLSCREEN
	#spawn_random_items(5)
	return
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("1"):
		spawn_random_items(1)


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
	
