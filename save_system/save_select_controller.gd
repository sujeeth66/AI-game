extends Node

# This controller manages the save/load system and should be added to your main scene
# or called from your main menu

signal game_started(game_data: Dictionary)

var save_manager: Node
var save_select_ui: Control
var is_initializing: bool = false

func _ready():
	print("SaveController _ready() starting...")
	print("SaveController instance path: ", get_path())
	
	# Check if another SaveController already exists and disable this one if so
	var existing_controller = get_tree().current_scene.find_child("SaveController", true, false)
	if existing_controller and existing_controller != self:
		print("WARNING: Multiple SaveController instances detected! Disabling duplicate: ", get_path())
		set_process(false)
		return
	
	print("SaveController is the primary instance, continuing initialization...")
	# Don't call setup_save_system() here - let initialize_save_system() do it
	
func setup_save_system():
	# Create save manager if it doesn't exist
	if not has_node("SaveManager"):
		save_manager = preload("res://save_system/save_manager.gd").new()
		save_manager.name = "SaveManager"
		add_child(save_manager)
		print("SaveController created SaveManager: ", save_manager.get_path())
	else:
		save_manager = get_node("SaveManager")
		print("SaveController found existing SaveManager: ", save_manager.get_path())
	
	# Connect save manager signals (check if not already connected)
	if not save_manager.save_data_loaded.is_connected(_on_game_data_loaded):
		save_manager.save_data_loaded.connect(_on_game_data_loaded)
	if not save_manager.save_slots_updated.is_connected(_on_slots_updated):
		save_manager.save_slots_updated.connect(_on_slots_updated)
	
	# Create or find save select UI
	setup_save_select_ui()
	
	# Show save select on startup if this is the initial load
	if is_initializing:
		show_save_select()

func setup_save_select_ui():
	# IMPORTANT: Always use the existing SaveSelectUI from the scene
	# Never create a new one since it's already instantiated in main.tscn
	save_select_ui = get_tree().current_scene.get_node_or_null("SaveSelectUI")
	
	if not save_select_ui:
		print("SaveController: ERROR - SaveSelectUI not found in main scene!")
		print("Available nodes in main scene:")
		for child in get_tree().current_scene.get_children():
			print("  - ", child.name, " (", child.get_script(), ")")
		return
	
	print("SaveController: Using SaveSelectUI from main scene: ", save_select_ui.get_path())
	
	# Connect UI signals (check if not already connected)
	if save_select_ui.has_signal("save_selected") and not save_select_ui.save_selected.is_connected(_on_save_selected):
		save_select_ui.save_selected.connect(_on_save_selected)
		print("Connected save_selected signal")
	if save_select_ui.has_signal("new_game_selected") and not save_select_ui.new_game_selected.is_connected(_on_new_game_selected):
		save_select_ui.new_game_selected.connect(_on_new_game_selected)
		print("Connected new_game_selected signal")

func show_save_select():
	if save_select_ui:
		save_select_ui.show_save_select()
		# Pause the game while showing save select
		get_tree().paused = true

func hide_save_select():
	if save_select_ui:
		save_select_ui.hide_save_select()
		# Resume game
		get_tree().paused = false

func _on_save_selected(slot_number: int):
	print("Save selected: ", slot_number)
	hide_save_select()
	# Game data will be loaded by save manager and emitted via save_data_loaded signal

func _on_new_game_selected(slot_number: int):
	print("New game selected: ", slot_number)
	hide_save_select()
	# New game data will be created by save manager and emitted via save_data_loaded signal

func _on_game_data_loaded(game_data: Dictionary):
	print("Game data loaded, starting game...")
	hide_save_select()
	game_started.emit(game_data)
	
	# Here you would typically:
	# 1. Load the map data
	# 2. Spawn NPCs
	# 3. Restore player state
	# 4. Load quests
	# etc.

func _on_slots_updated(slots: Array):
	print("Save slots updated: ", slots)

# Call this function to start the save/load process
func initialize_save_system():
	is_initializing = true
	setup_save_system()

# Call this to save current game state
func save_current_game(slot_number: int, game_data: Dictionary):
	if save_manager:
		save_manager.save_game_data(slot_number, game_data)
