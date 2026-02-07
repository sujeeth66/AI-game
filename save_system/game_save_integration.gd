extends Node

# This script should be attached to your main scene (main.tscn)
# It integrates the save/load system with your existing game

signal save_system_ready
signal start_map_generation

var save_controller: Node
var is_game_started: bool = false
var current_game_data: Dictionary = {}
var main_script: Node

func _ready():
	# Get reference to the main script
	main_script = get_parent()
	
	# Don't let main.gd start immediately - we'll control it
	if main_script and main_script.has_method("_ready"):
		# We'll call main_script.start_generation() when ready
		pass
	
	setup_save_system()

func setup_save_system():
	# Create save controller
	save_controller = preload("res://save_system/save_select_controller.gd").new()
	save_controller.name = "SaveController"
	add_child(save_controller)
	
	# Connect signals
	save_controller.game_started.connect(_on_game_started)
	
	# Initialize save system and show save select
	save_controller.initialize_save_system()
	
	# Pause game until save is selected
	get_tree().paused = true

func _on_game_started(game_data: Dictionary):
	print("Game started with data: ", game_data)
	current_game_data = game_data
	is_game_started = true
	
	# Resume game
	get_tree().paused = false
	
	# Initialize game with loaded data
	initialize_game_with_data(game_data)
	
	# NOW start the map generation in main.gd
	if main_script and main_script.has_method("start_map_generation_from_save"):
		main_script.start_map_generation_from_save(game_data)
	elif main_script and main_script.has_method("_ready"):
		# Fallback: call the original _ready logic
		main_script._ready()
	
	save_system_ready.emit()

func initialize_game_with_data(game_data: Dictionary):
	# Set global variables that main.gd might use
	if game_data.has("map_data"):
		var map_data = game_data["map_data"]
		Global.map_width = map_data.get("width", 800)
		Global.map_height = map_data.get("height", 600)
		print("Set map dimensions from save: ", Global.map_width, "x", Global.map_height)
	
	# Load NPC data if available
	if game_data.has("npc_data"):
		var npc_data = game_data["npc_data"]
		print("Loading NPCs: ", npc_data.keys())
		# NPCs will be spawned by the demo.gd after map generation
	
	# Load quest data if available
	if game_data.has("quest_data"):
		var quest_data = game_data["quest_data"]
		print("Loading quests: ", quest_data)
		# Restore quest state
	
	# Load player stats if available
	if game_data.has("player_stats"):
		var player_stats = game_data["player_stats"]
		print("Loading player stats: ", player_stats)
		# Update player stats
		var player = get_node_or_null("../Player")
		if player:
			# Update player health, mana, coins, etc.
			pass

func save_current_game():
	if not is_game_started or not save_controller:
		return
	
	# Collect current game data
	var game_data = collect_game_data()
	
	# Save to the appropriate slot (you might want to track which slot is active)
	var active_slot = int(current_game_data.get("game_id", 1))
	save_controller.save_current_game(active_slot, game_data)

func collect_game_data() -> Dictionary:
	var game_data = {
		"game_id": int(current_game_data.get("game_id", 1)),
		"timestamp": Time.get_unix_time_from_system(),
		"player_level": 1,  # Get from player
		"location": "Current Location",  # Get from game
		"map_data": {},
		"npc_data": {},
		"quest_data": {},
		"player_stats": {}
	}
	
	# Collect map data
	game_data["map_data"] = {
		"width": Global.get("map_width"),
		"height": Global.get("map_height"),
		"biome": Global.get("map_biome")
	}
	
	# Collect NPC data
	# Iterate through NPCs in the scene and save their states
	
	# Collect quest data
	var quest_manager = Global.get("global_quest_manager")
	if quest_manager:
		game_data["quest_data"] = {
			"active_quests": [],
			"completed_quests": []
		}
	
	# Collect player stats
	var player = get_node_or_null("../Player")
	if player:
		game_data["player_stats"] = {
			"health": 100,  # Get from player
			"max_health": 100,
			"mana": 50,
			"max_mana": 50,
			"coins": 0
		}
	
	return game_data

func _input(event):
	# Auto-save on specific key press (e.g., F5)
	if event.is_action_pressed("ui_accept") and Input.is_key_pressed(KEY_F5):
		save_current_game()
		print("Game saved!")
