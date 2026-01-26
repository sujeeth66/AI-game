extends Node2D

@onready var quest_ui: Control = $QuestUI

signal quest_updated(quest_id : String)
signal objective_updated(quest_id : String, objective_id : String)
signal quest_list_updated()

@onready var quests = Global.active_quests

func _ready() -> void:
	Global.global_quest_manager = self

func add_quest(quest: Quest):
	if quest.quest_id in quests:
		print("⚠️ Quest already exists! Current state:", quests[quest.quest_id].state)
		return
	
	quests[quest.quest_id] = quest
	print("✅ Quest added. Current quests:", quests.keys())
	
	# Check existing inventory items
	for objective in quest.objectives:
		if objective.objective_type == "collection":
			for i in range(InventoryGlobal.inventory.size()):
				var item = InventoryGlobal.inventory[i]
				if item != null and item.get("item_name") == objective.target_name:
					if item.quantity >= objective.required_quantity:
						objective.is_completed = true
					else:
						objective.collected_quantity = item.quantity
						
	Global.player.update_quest_tracker()
	quest_list_updated.emit()

func remove_quest(quest_id: String):
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
	if quest.has_method("process_rewards") and quest.state == "completed":
		quest.process_rewards(quest)
		remove_quest(quest_id)
		
	
func get_active_quests() -> Array:
	var active_quests = []
	for quest in quests.values():
		if quest.state == "in_progress":
			active_quests.append(quest)
	return active_quests
	
func update_objective(quest_id: String, objective_id: String, quantity: int = 1):
	var quest = get_quest(quest_id)
	if quest:
		# Only update if not already completed
		for objective in quest.objectives:
			if objective.id == objective_id and not objective.is_completed:
				quest.update_objective(quest.quest_id,objective_id, quantity)
