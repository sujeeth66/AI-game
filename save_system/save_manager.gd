extends Node

signal save_data_loaded(game_data: Dictionary)
signal save_slots_updated(slots: Array)

const SAVE_FILE_PATH = "user://save_slots.json"
const BASE_ENDPOINT = "http://127.0.0.1:8000"

var http_request: HTTPRequest
var current_slots: Dictionary = {}
var loading_slot: int = -1

func _ready():
	print("SaveManager _ready() starting...")
	
	# Create HTTPRequest node
	http_request = HTTPRequest.new()
	http_request.name = "SaveManagerHTTPRequest"
	add_child(http_request)
	
	# Make sure HTTPRequest can process when game is paused
	http_request.process_mode = Node.PROCESS_MODE_ALWAYS
	
	print("HTTPRequest created and added to scene tree")
	print("HTTPRequest path: ", http_request.get_path())
	
	# Connect the signal
	if not http_request.request_completed.is_connected(_on_http_request_completed):
		http_request.request_completed.connect(_on_http_request_completed)
		print("Connected HTTPRequest signal")
	else:
		print("HTTPRequest signal already connected")
	
	load_save_slots()
	print("SaveManager _ready() completed")

func load_save_slots():
	# First load local slots file
	if FileAccess.file_exists(SAVE_FILE_PATH):
		var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			file.close()
			var json = JSON.new()
			var parse_result = json.parse(json_string)
			if parse_result == OK:
				current_slots = json.data
			else:
				print("Error parsing save slots file")
				current_slots = {}
	else:
		current_slots = {
			"slot_1": {"exists": false, "game_id": 1},
			"slot_2": {"exists": false, "game_id": 2}, 
			"slot_3": {"exists": false, "game_id": 3}
		}
		save_slots_to_file()
	
	# Then sync with Flask backend
	sync_with_backend()

func sync_with_backend():
	print("=== Syncing with Flask backend ===")
	
	# Send GET request to /games endpoint
	var endpoint = BASE_ENDPOINT + "/games"
	var headers = ["Content-Type: application/json"]
	
	print("Requesting games list from: ", endpoint)
	var error = http_request.request(endpoint, headers, HTTPClient.METHOD_GET)
	if error != OK:
		push_error("Failed to sync with backend: " + str(error))
		# Still emit slots_updated with local data
		save_slots_updated.emit(get_slot_info())
	else:
		# Use a special loading value to indicate sync operation
		loading_slot = 0  # Use 0 to indicate sync operation

func get_slot_info() -> Array:
	var slots_info = []
	for i in range(1, 4):
		var slot_key = "slot_" + str(i)
		var slot_data = current_slots.get(slot_key, {"exists": false, "game_id": i})
		slots_info.append({
			"slot_number": i,
			"exists": slot_data.get("exists", false),
			"game_id": int(slot_data.get("game_id", i)),
			"last_played": slot_data.get("last_played", ""),
			"player_level": int(slot_data.get("player_level", 1)),
			"location": slot_data.get("location", "Unknown")
		})
	return slots_info

func test_http_request():
	print("=== Testing HTTP Request Manually ===")
	var test_endpoint = BASE_ENDPOINT + "/game/new"
	var test_headers = ["Content-Type: application/json"]
	var test_payload = {"slot_number": 999, "test": true}
	
	print("Test endpoint: ", test_endpoint)
	print("Test payload: ", test_payload)
	
	var error = http_request.request(test_endpoint, test_headers, HTTPClient.METHOD_POST, JSON.stringify(test_payload))
	if error != OK:
		push_error("Test HTTP request failed: " + str(error))
	else:
		print("Test HTTP request sent successfully")

func start_new_game(slot_number: int):
	var slot_key = "slot_" + str(slot_number)
	loading_slot = slot_number
	
	var endpoint = BASE_ENDPOINT + "/game/new"
	var headers = ["Content-Type: application/json"]
	var payload = {
		"slot_number": slot_number,
		"timestamp": Time.get_unix_time_from_system()
	}
	
	print("Starting new game for slot ", slot_number)
	print("Endpoint: ", endpoint)
	print("Payload: ", payload)
	print("Headers: ", headers)
	
	var error = http_request.request(endpoint, headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
	if error != OK:
		push_error("Failed to start new game: " + str(error))
	else:
		print("HTTP request sent successfully, waiting for response...")

func load_game(slot_number: int):
	var slot_key = "slot_" + str(slot_number)
	if not current_slots.has(slot_key) or not current_slots[slot_key].get("exists", false):
		push_error("No saved game found in slot " + str(slot_number))
		return
	
	loading_slot = slot_number
	var game_id = int(current_slots[slot_key].get("game_id", slot_number))
	var endpoint = BASE_ENDPOINT + "/game/" + str(game_id) + "/load"
	
	print("Loading game from slot ", slot_number, " (game_id: ", game_id, ")")
	var error = http_request.request(endpoint, [], HTTPClient.METHOD_GET)
	if error != OK:
		push_error("Failed to load game: " + str(error))

func _on_http_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	print("=== HTTP Response Received ===")
	print("Result: ", result)
	print("Response Code: ", response_code)
	print("Loading slot: ", loading_slot)
	
	if result != HTTPRequest.RESULT_SUCCESS:
		push_error("HTTP request failed with result: " + str(result))
		return
	
	var response_text = body.get_string_from_utf8()
	print("Response Body: ", response_text)
	
	var json = JSON.new()
	var parse_result = json.parse(response_text)
	
	if parse_result != OK:
		push_error("Failed to parse response JSON")
		return
	
	var response_data = json.data
	print("Parsed Response Data: ", response_data)
	
	if response_code == 200:
		if loading_slot > 0:
			print("Calling handle_game_data_response with loading_slot: ", loading_slot)
			handle_game_data_response(response_data)
		elif loading_slot < 0:
			# This is a DELETE operation
			var slot_number = -loading_slot
			print("DELETE operation successful for slot: ", slot_number)
			print("Response: ", response_data)
			
			# Check if Flask deletion was successful
			if response_data.get("success", false):
				print("Flask backend deletion successful")
				delete_save_locally(slot_number)
			else:
				push_error("Flask backend deletion failed: " + str(response_data.get("error", "Unknown error")))
				# Still delete locally even if backend fails
				delete_save_locally(slot_number)
			
			loading_slot = -1
		elif loading_slot == 0:
			# This is a SYNC operation from /games endpoint
			print("SYNC operation successful")
			print("Games response: ", response_data)
			
			# Update local slots based on backend games
			update_slots_from_backend(response_data)
			loading_slot = -1
		else:
			print("No loading slot set, not handling response")
	else:
		push_error("HTTP request failed with code: " + str(response_code))

func update_slots_from_backend(backend_response: Dictionary):
	print("=== Updating slots from backend ===")
	
	if not backend_response.get("success", false):
		push_error("Backend sync failed: " + str(backend_response.get("error", "Unknown error")))
		save_slots_updated.emit(get_slot_info())
		return
	
	var games = backend_response.get("games", [])
	print("Found games in backend: ", games)
	
	# Reset all slots to not exist
	for i in range(1, 4):
		var slot_key = "slot_" + str(i)
		if current_slots.has(slot_key):
			current_slots[slot_key]["exists"] = false
	
	# Update slots based on backend games
	for game in games:
		var game_id = str(game.get("game_id", 0))
		var slot_number = int(game_id)
		
		# Only handle games for slots 1-3
		if slot_number >= 1 and slot_number <= 3:
			var slot_key = "slot_" + str(slot_number)
			if current_slots.has(slot_key):
				current_slots[slot_key] = {
					"exists": true,
					"game_id": slot_number,
					"last_played": game.get("timestamp", Time.get_unix_time_from_system()),
					"player_level": game.get("player_level", 1),
					"location": game.get("location", "Unknown"),
					"map_data": game.get("map_data", {}),
					"npc_data": game.get("npc_data", {}),
					"quest_data": game.get("quest_data", {})
				}
				print("Updated slot ", slot_number, " from backend")
	
	# Save updated slots to file
	save_slots_to_file()
	
	# Emit update to refresh UI
	save_slots_updated.emit(get_slot_info())
	
	print("=== Backend sync completed ===")

func handle_game_data_response(game_data: Dictionary):
	print("=== handle_game_data_response called ===")
	print("Loading slot: ", loading_slot)
	
	if loading_slot <= 0:
		print("ERROR: loading_slot <= 0, returning")
		return
	
	var slot_key = "slot_" + str(loading_slot)
	print("Slot key: ", slot_key)
	
	# Update slot info with proper type conversion
	current_slots[slot_key] = {
		"exists": true,
		"game_id": int(game_data.get("game_id", loading_slot)),
		"last_played": Time.get_unix_time_from_system(),
		"player_level": int(game_data.get("player_level", 1)),
		"location": str(game_data.get("location", "Unknown")),
		"map_data": game_data.get("map_data", {}),
		"npc_data": game_data.get("npc_data", {}),
		"quest_data": game_data.get("quest_data", {})
	}
	
	print("Updated slot data: ", current_slots[slot_key])
	
	save_slots_to_file()
	print("Saved slots to file")
	
	save_data_loaded.emit(current_slots[slot_key])
	print("Emitted save_data_loaded signal")
	
	loading_slot = -1
	print("Reset loading_slot to -1")
	print("=== handle_game_data_response completed ===")

func save_game_data(slot_number: int, game_data: Dictionary):
	var slot_key = "slot_" + str(slot_number)
	var game_id = int(current_slots.get(slot_key, {}).get("game_id", slot_number))
	
	var endpoint = BASE_ENDPOINT + "/game/" + str(game_id) + "/save"
	var headers = ["Content-Type: application/json"]
	
	# Add timestamp to game data
	game_data["timestamp"] = Time.get_unix_time_from_system()
	
	print("Saving game to slot ", slot_number, " (game_id: ", game_id, ")")
	var error = http_request.request(endpoint, headers, HTTPClient.METHOD_POST, JSON.stringify(game_data))
	if error != OK:
		push_error("Failed to save game: " + str(error))

func save_slots_to_file():
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(current_slots, "\t"))
		file.close()
		print("Save slots data saved to file")
	else:
		push_error("Failed to save slots data to file")

func delete_save(slot_number: int):
	var slot_key = "slot_" + str(slot_number)
	if current_slots.has(slot_key):
		var game_id = int(current_slots[slot_key].get("game_id", slot_number))
		
		print("Deleting save data for slot ", slot_number, " (game_id: ", game_id, ")")
		
		# Send DELETE request to Flask backend
		var endpoint = BASE_ENDPOINT + "/game/" + str(game_id)
		var headers = ["Content-Type: application/json"]
		
		print("Sending DELETE request to: ", endpoint)
		var error = http_request.request(endpoint, headers, HTTPClient.METHOD_DELETE)
		if error != OK:
			push_error("Failed to delete game: " + str(error))
			# Still delete locally even if HTTP fails
			delete_save_locally(slot_number)
		else:
			# Wait for HTTP response before deleting locally
			loading_slot = -slot_number  # Use negative to indicate delete operation
	else:
		print("No save data found in slot ", slot_number)

func delete_save_locally(slot_number: int):
	var slot_key = "slot_" + str(slot_number)
	if current_slots.has(slot_key):
		current_slots[slot_key] = {"exists": false, "game_id": slot_number}
		save_slots_to_file()
		save_slots_updated.emit(get_slot_info())
		print("Deleted save data locally for slot ", slot_number)
