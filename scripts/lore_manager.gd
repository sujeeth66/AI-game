#class_name LoreManager

var lore_history : Array = []
var tracked_world_state : Dictionary = {}
var retained_quests : Array = []

func build_prompt() -> String:
	var prompt = "Continue the game story using previous lore, world state, and retained quests.\n"
	prompt += "Previous lore:\n" + str(lore_history)
	prompt += "\nWorld state:\n" + str(tracked_world_state)
	prompt += "\nRetained quests:\n" + str(retained_quests)
	prompt += "\nMake sure to reflect past player actions, including contradictions to prophecies or fate."
	return prompt
	
	
func save_lore(path : String):
	var data = {
		"lore_history": lore_history,
		"world_state": tracked_world_state,
		"retained_quests": retained_quests
	}
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()
