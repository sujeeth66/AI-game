extends Node
class_name LoreManager

@onready var http := HTTPRequest.new()
var save_path := "res://lore_slot1.json"
var slot_id := "slot1"
var current_game_state := {}  # your actual game state here

func _ready():
	add_child(http)
	http.request_completed.connect(_on_lore_response)
	generate_initial_lore()

func generate_initial_lore():
	var history 
	if FileAccess.file_exists(save_path):
		var file := FileAccess.open(save_path, FileAccess.READ)
		var existing_data = JSON.parse_string(file.get_as_text())
		file.close()
		if typeof(existing_data) == TYPE_DICTIONARY and existing_data.has("lore_history"):
			history = existing_data["lore_history"]

	var payload = {
		"slot": slot_id,
		"state": current_game_state,
		"history": history
	}

	var headers := ["Content-Type: application/json"]
	var body := JSON.stringify(payload)
	var result := http.request("http://127.0.0.1:8001/generate-lore", headers, HTTPClient.METHOD_POST, body)

	if result != OK:
		push_error("Lore request failed: %s" % result)

func _on_lore_response(result, response_code, headers, body):
	if response_code != 200:
		push_error("⚠️ Lore AI error: %d" % response_code)
		return

	var data = JSON.parse_string(body.get_string_from_utf8())
	if typeof(data) != TYPE_DICTIONARY:
		push_error("📦 Response not a dictionary.")
		return

	if data.has("fallback_raw"):
		push_error("AI returned fallback_raw instead of structured lore.")
		return

	if not (data.has("lore") and data.has("narrative") and data.has("map")):
		push_error("📦 Missing expected lore keys.")
		return

	save_lore_to_file(data)

func save_lore_to_file(lore_entry: Dictionary):
	var lore_history := []
	if FileAccess.file_exists(save_path):
		var file := FileAccess.open(save_path, FileAccess.READ)
		var existing_data = JSON.parse_string(file.get_as_text())
		file.close()
		if typeof(existing_data) == TYPE_DICTIONARY and existing_data.has("lore_history"):
			lore_history = existing_data["lore_history"]

	lore_history.append(lore_entry)

	var file_data = {
		"lore_history": lore_history,
		"slot": slot_id,
		"world_state": {}  # optional: store evolving world state
	}

	var file := FileAccess.open(save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(file_data, "\t"))
	file.close()
