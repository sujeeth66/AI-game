extends Control

signal save_selected(slot_number: int)
signal new_game_selected(slot_number: int)

var slot_1_button: Button
var slot_2_button: Button  
var slot_3_button: Button

var slot_1_info: Label
var slot_2_info: Label
var slot_3_info: Label

var slot_1_delete: Button
var slot_2_delete: Button
var slot_3_delete: Button

var save_manager: Node
var slot_buttons: Array[Button] = []
var slot_info_labels: Array[Label] = []
var slot_delete_buttons: Array[Button] = []

func _ready():
	# Make sure the UI is visible by default
	visible = true
	
	# IMPORTANT: Make sure this UI can receive input even when game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	print("SaveSelectUI _ready() starting...")
	print("SaveSelectUI instance path: ", get_path())
	
	# This is the scene instance - always allow it to run
	print("SaveSelectUI is the scene instance, continuing initialization...")
	
	# Wait a frame to ensure all nodes are ready
	await get_tree().process_frame
	
	print("SaveSelectUI _ready() after first frame wait")
	print("SaveSelectUI _ready() called, visible: ", visible)
	print("SaveSelectUI position: ", position)
	print("SaveSelectUI size: ", size)
	print("SaveSelectUI path: ", get_path())
	print("Game paused state: ", get_tree().paused)
	
	# Look for existing SaveManager in multiple locations
	save_manager = get_node_or_null("/root/SaveManager")
	if not save_manager:
		# Look in the main scene hierarchy (most likely location)
		save_manager = get_node_or_null("../../Node/SaveController/SaveManager")
	if not save_manager:
		# Look in the SaveController specifically
		save_manager = get_node_or_null("../../SaveController/SaveManager")
	if not save_manager:
		# Look in parent nodes
		save_manager = get_node_or_null("../../SaveManager")
	if not save_manager:
		# Look in the entire scene tree
		save_manager = find_child("SaveManager", true, false)
	
	if not save_manager:
		push_error("SaveManager not found! Available nodes:")
		print("My path:", get_path())
		print("Parent path:", get_parent().get_path())
		print("Available siblings:", get_parent().get_children())
		print("Available children:", get_children())
		print("Scene tree root:", get_tree().current_scene.get_children())
		return
	
	print("SaveSelectUI found SaveManager: ", save_manager.get_path())
	
	# Wait for save manager to be ready
	if not save_manager.is_node_ready():
		print("Waiting for SaveManager to be ready...")
		await save_manager.ready
		print("SaveManager is now ready")
	
	# Safely get node references
	print("Looking for UI nodes...")
	slot_1_button = get_node_or_null("HBoxContainer/VBoxContainer/Slot1Container/Slot1Button")
	slot_2_button = get_node_or_null("HBoxContainer/VBoxContainer/Slot2Container/Slot2Button")
	slot_3_button = get_node_or_null("HBoxContainer/VBoxContainer/Slot3Container/Slot3Button")
	
	slot_1_info = get_node_or_null("HBoxContainer/VBoxContainer/Slot1Container/Slot1Info")
	slot_2_info = get_node_or_null("HBoxContainer/VBoxContainer/Slot2Container/Slot2Info")
	slot_3_info = get_node_or_null("HBoxContainer/VBoxContainer/Slot3Container/Slot3Info")
	
	slot_1_delete = get_node_or_null("HBoxContainer/VBoxContainer/Slot1Container/Slot1Delete")
	slot_2_delete = get_node_or_null("HBoxContainer/VBoxContainer/Slot2Container/Slot2Delete")
	slot_3_delete = get_node_or_null("HBoxContainer/VBoxContainer/Slot3Container/Slot3Delete")
	
	# Debug: Print what we found
	print("SaveSelectUI nodes found:")
	print("  Slot1Button: ", slot_1_button != null)
	print("  Slot2Button: ", slot_2_button != null)
	print("  Slot3Button: ", slot_3_button != null)
	print("  SaveManager: ", save_manager != null)
	print("  VBoxContainer: ", get_node_or_null("VBoxContainer") != null)
	
	# Check if nodes exist and print warnings
	if not slot_1_button:
		push_error("Slot1Button not found! Check scene structure.")
	if not slot_2_button:
		push_error("Slot2Button not found! Check scene structure.")
	if not slot_3_button:
		push_error("Slot3Button not found! Check scene structure.")
	
	if not save_manager:
		push_error("SaveManager not found!")
		return
	
	print("Setting up arrays and connecting signals...")
	
	# Setup arrays only if buttons exist
	slot_buttons = [slot_1_button, slot_2_button, slot_3_button]
	slot_info_labels = [slot_1_info, slot_2_info, slot_3_info]
	slot_delete_buttons = [slot_1_delete, slot_2_delete, slot_3_delete]
	
	# IMPORTANT: Set buttons to also process when game is paused
	for i in range(3):
		if slot_buttons[i]:
			slot_buttons[i].process_mode = Node.PROCESS_MODE_ALWAYS
		if slot_delete_buttons[i]:
			slot_delete_buttons[i].process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Connect signals only if buttons exist
	for i in range(3):
		if slot_buttons[i]:
			print("Connecting signal for slot ", i + 1, " button: ", slot_buttons[i])
			if not slot_buttons[i].pressed.is_connected(_on_slot_pressed.bind(i + 1)):
				slot_buttons[i].pressed.connect(_on_slot_pressed.bind(i + 1))
				print("Connected signal for slot ", i + 1, " button")
		else:
			print("Slot button ", i + 1, " is null!")
		if slot_delete_buttons[i]:
			if not slot_delete_buttons[i].pressed.is_connected(_on_delete_pressed.bind(i + 1)):
				slot_delete_buttons[i].pressed.connect(_on_delete_pressed.bind(i + 1))
				print("Connected signal for slot ", i + 1, " delete button")
		else:
			print("Slot delete button ", i + 1, " is null!")
	
	# Connect save manager signals (check if not already connected)
	if save_manager and not save_manager.save_slots_updated.is_connected(_on_slots_updated):
		save_manager.save_slots_updated.connect(_on_slots_updated)
		print("Connected save_slots_updated signal")
	if save_manager and not save_manager.save_data_loaded.is_connected(_on_game_loaded):
		save_manager.save_data_loaded.connect(_on_game_loaded)
		print("Connected save_data_loaded signal")
	
	# Wait a bit more for everything to be ready
	await get_tree().process_frame
	
	# Initial update
	print("SaveSelectUI about to update display with SaveManager: ", save_manager != null)
	update_slot_display()
	
	# Make sure it's visible and positioned correctly
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = true
	print("SaveSelectUI final visible state: ", visible)
	print("SaveSelectUI _ready() completed successfully!")

func _input(event):
	# Test button presses with keyboard (for debugging)
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_1:
			print("Manual trigger: Slot 1")
			_on_slot_pressed(1)
		elif event.keycode == KEY_2:
			print("Manual trigger: Slot 2")
			_on_slot_pressed(2)
		elif event.keycode == KEY_3:
			print("Manual trigger: Slot 3")
			_on_slot_pressed(3)
		elif event.keycode == KEY_T:
			print("Manual HTTP test")
			if save_manager and save_manager.has_method("test_http_request"):
				save_manager.test_http_request()

func _on_slot_pressed(slot_number: int):
	print("Slot button pressed: ", slot_number)
	if not save_manager:
		print("SaveManager is null, cannot handle slot press")
		return
		
	var slot_info = save_manager.get_slot_info()[slot_number - 1]
	print("Slot info: ", slot_info)
	if slot_info.exists:
		print("Loading game from slot ", slot_number)
		save_manager.load_game(slot_number)
	else:
		print("Starting new game in slot ", slot_number)
		save_manager.start_new_game(slot_number)

func _on_delete_pressed(slot_number: int):
	if not save_manager:
		print("SaveManager is null, cannot handle delete")
		return
		
	var slot_info = save_manager.get_slot_info()[slot_number - 1]
	if slot_info.exists:
		# Show confirmation dialog (for now just delete)
		save_manager.delete_save(slot_number)

func _on_slots_updated(slots: Array):
	update_slot_display()

func _on_game_loaded(game_data: Dictionary):
	print("Game loaded successfully: ", game_data)
	var active_slot = int(game_data.get("game_id", 1))
	save_selected.emit(active_slot)
	# Hide save select UI and start game
	visible = false

func update_slot_display():
	if not save_manager:
		print("SaveManager is null, cannot update display")
		return
		
	var slots_info = save_manager.get_slot_info()
	
	for i in range(3):
		var slot_info = slots_info[i]
		var button = slot_buttons[i]
		var info_label = slot_info_labels[i]
		var delete_button = slot_delete_buttons[i]
		delete_button.text = "Delete Save File"
		if button and info_label and delete_button:
			if slot_info.exists:
				button.text = "Load Game " + str(slot_info.slot_number)
				
				# Format last played date
				var last_played_str = ""
				if str(slot_info.last_played) != "":
					var datetime = Time.get_datetime_dict_from_unix_time(float(slot_info.last_played))
					last_played_str = "%02d/%02d/%d %02d:%02d" % [
						datetime.month, datetime.day, datetime.year, 
						datetime.hour, datetime.minute
					]
				
				info_label.text = "Level %d - %s\nLast played: %s\nLocation: %s" % [
					slot_info.player_level, 
					"Game ID: " + str(slot_info.game_id),
					last_played_str,
					slot_info.location
				]
				delete_button.visible = true
			else:
				button.text = "New Game " + str(slot_info.slot_number)
				info_label.text = "Empty Slot"
				delete_button.visible = false
		else:
			push_warning("Some UI nodes are missing for slot " + str(i + 1))

func show_save_select():
	visible = true
	update_slot_display()

func hide_save_select():
	visible = false
