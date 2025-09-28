### NPC.gd

extends CharacterBody2D

@export var npc_id: String
@export var npc_name: String

# Dialog vars
@onready var dialog_manager = $DialogManager
@export var dialog_resource: Dialog
var current_state = "start"
var current_branch_index = 0

@export var quests : Array[Quest] = []
var quest_manager : Node2D = null

func _ready():
	# Load dialog data
	dialog_resource.load_from_json("res://quest system/Resources/Dialog/dialog_data.json")
	# Initialize npc ref
	dialog_manager.npc = self
	quest_manager = Global.player.quest_manager
	# Initialize quest manager reference
	
func start_dialog():
	var npc_dialogs = dialog_resource.get_npc_dialog(npc_id)
	if npc_dialogs.is_empty():
		return
	dialog_manager.show_dialog(self)

# Get current branch dialog
func  get_current_dialog():
	var npc_dialogs = dialog_resource.get_npc_dialog(npc_id) 
	if current_branch_index < npc_dialogs.size():
		for dialog in npc_dialogs[current_branch_index]["dialogs"]:
			if dialog["state"] == current_state:
				return dialog
	return null

# Update dialog branch
func set_dialog_tree(branch_index):
	current_branch_index = branch_index
	current_state = "start"

# Update dialog state
func set_dialog_state(state):
	current_state = state

func offer_quest(quest_id: String):
	for quest in quests:
		if quest.quest_id == quest_id and quest.state == "not_started":
			quest.state = "in_progress"
			quest_manager.add_quest(quest)
			return
	
func get_quest_dialog() -> Dictionary:
	print("from get_quest_dialog")
	var active_quests = quest_manager.get_active_quests()
	for quest in active_quests:
		for objective in quest.objectives:
			if objective.target_name == npc_name and objective.objective_type == "talk_to" and not objective.is_completed:
				# Use the quest manager to properly complete the objective
				quest_manager.update_objective(quest.quest_id, objective.id)
				# Let the quest manager handle the completion check
				if quest.is_completed():
					quest_manager.update_quest(quest.quest_id, "completed")
				return {"text": objective.objective_dialog, "options": {"Continue": "exit"}}
	return {"text": "", "options": {}}
