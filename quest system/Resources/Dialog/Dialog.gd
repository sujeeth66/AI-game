### Dialog.gd

extends Resource

class_name Dialog

@export var dialogs = {}

# Load dialog data
func load_and_merge_dialogs(base_res_path: String, user_path: String) -> void:
	var merged: Dictionary = {}

	# Load base dialogs from res://
	if FileAccess.file_exists(base_res_path):
		var raw_base := FileAccess.get_file_as_string(base_res_path)
		var parsed_base = JSON.parse_string(raw_base)
		if typeof(parsed_base) == TYPE_DICTIONARY:
			merged = parsed_base

	# Overlay/merge user dialogs from user://
	if FileAccess.file_exists(user_path):
		var raw_user := FileAccess.get_file_as_string(user_path)
		var parsed_user = JSON.parse_string(raw_user)
		if typeof(parsed_user) == TYPE_DICTIONARY:
			for k in parsed_user.keys():
				merged[k] = parsed_user[k] # user overrides base

	dialogs = merged

# Return individual NPC dialogs
func get_npc_dialog(npc_id):
	if dialogs.has(npc_id):
		return dialogs[npc_id]["trees"]
	else:
		return []
