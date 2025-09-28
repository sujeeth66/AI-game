extends Node2D

@onready var quest_ui: Control = $QuestUI

signal quest_updated(quest_id : String)
signal objective_updated(quest_id : String, objective_id : String)
signal quest_list_updated()

var quests = {}
#var _processing_quests = {}  # Track which quests are being processed to prevent duplicates

func _ready() -> void:
	Global.global_quest_manager = self

func add_quest(quest: Quest):
	quests[quest.quest_id] = quest
	Global.player.update_quest_tracker()
	
	#check if the quest items are already in the inventory
	for objective in quest.objectives:
		if objective.objective_type == "collection" :
			var target_name = objective.target_name
			var target_quantity = objective.required_quantity
			for i in range(InventoryGlobal.inventory.size()):
					if (InventoryGlobal.inventory[i] != null and 
						InventoryGlobal.inventory[i]["item_name"] == target_name ):
						if InventoryGlobal.inventory[i]["quantity"] >= target_quantity:
							objective.is_completed = true
						else:
							objective.collected_quantity = InventoryGlobal.inventory[i]["quantity"]
							
		
	# If the quest is already completed, process it
	if quest.state == "completed":
		remove_quest(quest.quest_id)
	
func remove_quest(quest_id : String):
	print("quest removed",quest_id)
	quests.erase(quest_id)
	quest_list_updated.emit()
	Global.player.update_quest_tracker()

	
func get_quest(quest_id : String) -> Quest:
	return quests.get(quest_id,null)
	
func update_quest(quest_id : String, state : String):
	var quest = quests[quest_id]
	var old_state = quest.state
	
	if old_state == state:
		return
	
	quest.state = state
	
	# Check if all objectives are completed
	var all_completed :bool
	for objective in quest.objectives:
		if not objective.is_completed:
			all_completed = false
			break
	
	if all_completed and state != "completed":
		quest.state = "completed"
		# Process rewards here if needed
	if quest.has_method("process_rewards"):
		quest.process_rewards(quest)
		# Remove the quest from active quests
		remove_quest(quest_id)
		
	
func get_active_quests() -> Array:
	var active_quests = []
	for quest in quests.values():
		if quest.state == "in_progress":
			active_quests.append(quest)
	print("from get_active_quests",active_quests)
	return active_quests
	
func update_objective(quest_id: String, objective_id: String, quantity: int = 1):
	var quest = get_quest(quest_id)
	if quest:
		# Only update if not already completed
		for objective in quest.objectives:
			if objective.id == objective_id and not objective.is_completed:
				# Pass the quantity to the quest's complete_objective
				quest.update_objective(quest.quest_id,objective_id, quantity)
				return  # Exit after handling the first matching objective
