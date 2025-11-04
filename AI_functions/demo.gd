extends Node

const QuestFactory = preload("res://AI_functions/quest_factory.gd")
const NPCFactory = preload("res://AI_functions/npc_factory.gd")

const ENDPOINT_BASE := "http://127.0.0.1:8000"

var map_main = null
var http_quest: HTTPRequest
var http_npc: HTTPRequest
var http_item: HTTPRequest
var http_placement: HTTPRequest

# Store data between async calls
var quest_data = null
var npc_data = null
var item_data = null
var placement_data = null

func _ready() -> void:
	print("[demo.gd] _ready() running!")
	
	# Create HTTP request nodes
	http_quest = HTTPRequest.new()
	http_npc = HTTPRequest.new()
	http_item = HTTPRequest.new()
	http_placement = HTTPRequest.new()
	
	add_child(http_quest)
	add_child(http_npc)
	add_child(http_item)
	add_child(http_placement)
	
	# Connect signals
	http_quest.request_completed.connect(_on_quest_generated)
	http_npc.request_completed.connect(_on_npc_generated)
	http_item.request_completed.connect(_on_item_generated)
	http_placement.request_completed.connect(_on_placement_generated)
	
	var root = get_tree().current_scene
	var found_map_node = null
	if root and root.has_signal("map_generation_finished"):
		found_map_node = root
	else:
		for n in root.get_children():
			if n.has_signal("map_generation_finished"):
				found_map_node = n
				break
	if found_map_node:
		found_map_node.connect("map_generation_finished", Callable(self, "_on_map_ready"))
		print("[demo.gd] Connected to map_generation_finished signal on: ", found_map_node)
	else:
		print("[demo.gd] Still can't find a map node with map_generation_finished signal! root is: ", root)

func _on_map_ready():
	print("[demo.gd] Map generation finished, starting AI-driven NPC/Quest generation pipeline.")
	# Start the async pipeline: Quest -> NPC -> Placement
	request_quest_generation()

func request_quest_generation():
	print("[demo.gd] Requesting quest generation from AI...")
	var payload = {
		"context": "fantasy world with slimes",
		"npc_type": "alchemist"
	}
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify(payload)
	var error = http_quest.request(ENDPOINT_BASE + "/generate-quest", headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		push_error("[demo.gd] Failed to send quest generation request: ", error)

func _on_quest_generated(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	print("[demo.gd] Quest response received - Result: ", result, " Code: ", response_code)
	
	if result != HTTPRequest.RESULT_SUCCESS:
		push_error("[demo.gd] Quest generation request failed: ", response_code)
		return
	
	# Log the raw response for debugging
	var raw_response = body.get_string_from_utf8()
	print("[demo.gd] Raw quest response: ", raw_response)
	
	if raw_response.is_empty():
		push_error("[demo.gd] Empty response from quest endpoint")
		return
	
	var json = JSON.new()
	var parse_error = json.parse(raw_response)
	if parse_error != OK:
		push_error("[demo.gd] Failed to parse quest JSON. Error code: ", parse_error)
		push_error("[demo.gd] Error message: ", json.get_error_message())
		push_error("[demo.gd] Error line: ", json.get_error_line())
		return
	
	quest_data = json.get_data()
	print("[demo.gd] Quest generated: ", quest_data.get("quest_name"))
	
	# Now request item generation for quest objectives
	request_item_generation()

func request_item_generation():
	print("[demo.gd] Requesting item generation from AI...")
	# Get the first collection objective's target
	var objectives = quest_data.get("objectives", [])
	var target_item = "Slime Gel"
	for obj in objectives:
		if obj.get("objective_type") == "collection":
			target_item = obj.get("target_name", "Slime Gel")
			break
	
	var payload = {
		"item_name": target_item,
		"context": "quest item needed for alchemist"
	}
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify(payload)
	var error = http_item.request(ENDPOINT_BASE + "/generate-item", headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		push_error("[demo.gd] Failed to send item generation request: ", error)

func _on_item_generated(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	print("[demo.gd] Item response received - Result: ", result, " Code: ", response_code)
	
	if result != HTTPRequest.RESULT_SUCCESS:
		push_error("[demo.gd] Item generation request failed: ", response_code)
		return
	
	var raw_response = body.get_string_from_utf8()
	print("[demo.gd] Raw item response: ", raw_response)
	
	if raw_response.is_empty():
		push_error("[demo.gd] Empty response from item endpoint")
		return
	
	var json = JSON.new()
	var parse_error = json.parse(raw_response)
	if parse_error != OK:
		push_error("[demo.gd] Failed to parse item JSON. Error code: ", parse_error)
		push_error("[demo.gd] Error message: ", json.get_error_message())
		push_error("[demo.gd] Error line: ", json.get_error_line())
		return
	
	item_data = json.get_data()
	print("[demo.gd] Item generated: ", item_data.get("item_name"))
	
	# Create item in InventoryGlobal if it doesn't exist
	create_item_if_not_exists()
	
	# Now request NPC generation
	request_npc_generation()

func create_item_if_not_exists():
	var item_name = item_data.get("item_name")
	var exists = false
	
	# Check if item already exists
	for item in InventoryGlobal.items:
		if item.get("item_name") == item_name:
			exists = true
			print("[demo.gd] Item '", item_name, "' already exists in items list")
			break
	
	if not exists:
		# Load or create texture
		var texture_path = item_data.get("item_texture_path", "res://icon.svg")
		var texture = null
		if ResourceLoader.exists(texture_path):
			texture = load(texture_path)
		else:
			print("[demo.gd] ⚠️ Texture not found at '", texture_path, "', using default")
			texture = load("res://icon.svg")
		
		# Create the item
		InventoryGlobal.create_item(
			item_name,
			item_data.get("item_type", "quest_item"),
			item_data.get("item_effect", "none"),
			texture
		)
		print("[demo.gd] ✅ Created new item: '", item_name, "'")
	
	# Spawn items on the map
	spawn_items_on_map()

func spawn_items_on_map():
	print("[demo.gd] Spawning items on the map...")
	var root = get_tree().current_scene
	var items_node = root.get_node_or_null("Items")
	
	if not items_node:
		print("[demo.gd] ⚠️ Items node not found, creating one")
		items_node = Node2D.new()
		items_node.name = "Items"
		root.add_child(items_node)
	
	var tilemap = root.get_node_or_null("TileMapLayer")
	if not tilemap:
		print("[demo.gd] ⚠️ TileMapLayer not found, cannot spawn items")
		return
	
	var spawn_count = item_data.get("spawn_count", 5)
	var map_width = Global.map_width if "map_width" in Global else 500
	var map_height = Global.map_height if "map_height" in Global else 100
	var surface_tiles = Global.surface_tiles if "surface_tiles" in Global else []
	
	if surface_tiles.is_empty():
		print("[demo.gd] ⚠️ No surface tiles available for spawning")
		return
	
	# Get item texture
	var texture_path = item_data.get("item_texture_path", "res://icon.svg")
	var texture = load(texture_path) if ResourceLoader.exists(texture_path) else load("res://icon.svg")
	
	# Spawn items at random valid locations
	var item_scene = load("res://inventory/scenes/game_item.tscn")
	var spawned = 0
	var max_attempts = spawn_count * 3
	var attempts = 0
	
	while spawned < spawn_count and attempts < max_attempts:
		attempts += 1
		var random_x = randi_range(50, surface_tiles.size() - 50)
		if random_x >= surface_tiles.size():
			continue
		
		var surface_pos = surface_tiles[random_x]
		if surface_pos.y == -1:
			continue
		
		var world_pos = tilemap.map_to_local(surface_pos)
		
		var item_instance = item_scene.instantiate()
		item_instance.initiate_items(
			1,
			item_data.get("item_name"),
			item_data.get("item_type"),
			item_data.get("item_effect"),
			texture
		)
		item_instance.global_position = world_pos
		items_node.add_child(item_instance)
		spawned += 1
	
	print("[demo.gd] ✅ Spawned ", spawned, " items on the map")

func request_npc_generation():
	print("[demo.gd] Requesting NPC generation from AI...")
	var payload = {
		"context": "needs to give quest about collecting slime gel",
		"location": "forest area"
	}
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify(payload)
	var error = http_npc.request(ENDPOINT_BASE + "/generate-npc", headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		push_error("[demo.gd] Failed to send NPC generation request: ", error)

func _on_npc_generated(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	print("[demo.gd] NPC response received - Result: ", result, " Code: ", response_code)
	if result != HTTPRequest.RESULT_SUCCESS:
		push_error("[demo.gd] NPC generation request failed: ", response_code)
		return
	
	var raw_response = body.get_string_from_utf8()
	print("[demo.gd] Raw NPC response: ", raw_response)
	
	if raw_response.is_empty():
		push_error("[demo.gd] Empty response from NPC endpoint")
		return

	var json = JSON.new()
	var parse_error = json.parse(raw_response)
	if parse_error != OK:
		push_error("[demo.gd] Failed to parse NPC JSON. Error code: ", parse_error)
		push_error("[demo.gd] Error message: ", json.get_error_message())
		push_error("[demo.gd] Error line: ", json.get_error_line())
		return
	
	npc_data = json.get_data()
	print("[demo.gd] NPC generated: ", npc_data.get("npc_name"))
	
	# Now request placement
	request_npc_placement()

func request_npc_placement():
	print("[demo.gd] Requesting NPC placement from AI...")
	var payload = {
		"map_width": Global.map_width if "map_width" in Global else 500,
		"map_height": Global.map_height if "map_height" in Global else 100,
		"surface_tiles": [],  # Could send subset of surface data
		"npc_type": npc_data.get("npc_type", "generic")
	}
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify(payload)
	var error = http_placement.request(ENDPOINT_BASE + "/place-npc", headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		push_error("[demo.gd] Failed to send placement request: ", error)

func _on_placement_generated(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	print("[demo.gd] Placement response received - Result: ", result, " Code: ", response_code)
	if result != HTTPRequest.RESULT_SUCCESS:
		push_error("[demo.gd] Placement request failed: ", response_code)
		return
	
	var raw_response = body.get_string_from_utf8()
	print("[demo.gd] Raw placement response: ", raw_response)
	
	if raw_response.is_empty():
		push_error("[demo.gd] Empty response from placement endpoint")
		return
	
	var json = JSON.new()
	var parse_error = json.parse(raw_response)
	if parse_error != OK:
		push_error("[demo.gd] Failed to parse placement JSON. Error code: ", parse_error)
		push_error("[demo.gd] Error message: ", json.get_error_message())
		push_error("[demo.gd] Error line: ", json.get_error_line())
		return
	
	placement_data = json.get_data()
	print("[demo.gd] Placement determined at x=", placement_data.get("placement_x"))
	
	# Now we have all data, create and place the NPC
	create_and_place_npc()

func create_and_place_npc():
	print("[demo.gd] Creating NPC with AI-generated data...")
	var qf = QuestFactory.new()
	var npcf = NPCFactory.new()
	
	# Create quest from AI data
	var demo_quest = qf.create_quest(
		quest_data.get("quest_id"),
		quest_data.get("quest_name"),
		quest_data.get("quest_description"),
		quest_data.get("objectives", []),
		quest_data.get("rewards", [])
	)
	print("[demo.gd] Created quest from AI data:", demo_quest)
	
	# Build dialog trees from AI data
	var dialog_trees = npc_data.get("dialog_trees", [])
	print("[demo.gd] Using AI-generated dialog trees")
	
	# Create NPC from scene
	var npc_scene: PackedScene = load("res://quest system/scenes/NPC.tscn")
	var root = get_tree().current_scene
	var npc = npcf.create_npc(
		npc_scene,
		npc_data.get("npc_id"),
		npc_data.get("npc_name"),
		dialog_trees,
		[demo_quest],
		root,
		true
	)
	print("[demo.gd] NPC instance created:", npc)

	# Load or create texture
	# NOTE: Create res://textures/slime_gel.png or it will use default icon
	var texture_path = "res://textures/slime_gel.png"
	var texture = null
	if ResourceLoader.exists(texture_path):
		texture = load(texture_path)
	else:
		print("[demo.gd] ⚠️ Texture not found at '", texture_path, "', using placeholder")
	
	# Try to find any existing item texture as fallback
	if ResourceLoader.exists("res://textures/raw_chicken.png"):
		texture = load("res://textures/raw_chicken.png")
	else:
		texture = load("res://icon.svg")

	
	# Place the NPC using AI-determined position
	var tilemap = null
	if root.has_node("TileMapLayer"):
		tilemap = root.get_node("TileMapLayer")
		print("[demo.gd] Found TileMapLayer node!")
	else:
		print("[demo.gd] TileMapLayer node NOT found on root!")
	
	var map_height = Global.map_height
	
	if npc and tilemap != null and map_height != null:
		var surf_x = placement_data.get("placement_x", 200)
		print("[demo.gd] Placing NPC at AI-suggested position x=", surf_x)
		var ok = npcf.place_npc_on_surface_tile_with_surface_array(npc, surf_x, map_height, tilemap)
		if ok:
			print("[demo.gd] ✅ NPC placed successfully at x=", surf_x, " (reasoning: ", placement_data.get("reasoning"), ")")
		else:
			print("[demo.gd] ❌ NPC placement failed at x=", surf_x)
	else:
		print("[demo.gd] Not placing NPC. npc=", npc, ", tilemap=", tilemap, ", map_height=", map_height)
	
	print("[demo.gd] AI-driven NPC generation pipeline complete!")
