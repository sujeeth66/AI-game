extends Node2D

@onready var quest_ui: Control = $QuestUI

signal quest_updated(quest_id : String)
signal objective_updated(quest_id : String, objective_id : String)
signal quest_list_updated()

@onready var quests = Global.active_quests
#var _processing_quests = {}  # Track which quests are being processed to prevent duplicates

func _ready() -> void:
	Global.global_quest_manager = self

# In quest_manager.gd, modify these functions:

func add_quest(quest: Quest):
	print("\n=== ADDING QUEST ===")
	print("Quest ID:", quest.quest_id)
	print("Initial State:", quest.state)
	
	if quest.quest_id in quests:
		print("⚠️ Quest already exists! Current state:", quests[quest.quest_id].state)
		return
	
	quests[quest.quest_id] = quest
	print("✅ Quest added. Current quests:", quests.keys())
	
	# Check existing inventory items
	print("\nChecking existing inventory items...")
	for objective in quest.objectives:
		if objective.objective_type == "collection":
			print("  Objective:", objective.target_name, "required:", objective.required_quantity)
			for i in range(InventoryGlobal.inventory.size()):
				var item = InventoryGlobal.inventory[i]
				if item != null and item.get("item_name") == objective.target_name:
					print("    Found matching item:", item)
					if item.quantity >= objective.required_quantity:
						objective.is_completed = true
						print("    ✅ Objective completed from existing items!")
					else:
						objective.collected_quantity = item.quantity
						print("    ⏳ Partial progress:", objective.collected_quantity, "/", objective.required_quantity)
	
	Global.player.update_quest_tracker()
	quest_list_updated.emit()
	
	# Debug: Print all active quests after adding
	print("\nActive quests after adding:")
	for q in get_active_quests():
		print("  -", q.quest_id, "State:", q.state)
	print("===================\n")

func remove_quest(quest_id: String):
	print("\n=== REMOVING QUEST ===")
	print("Removing quest ID:", quest_id)
	print("Current quests before removal:", quests.keys())
	
	# Print quest state before removal
	if quest_id in quests:
		var quest = quests[quest_id]
		print("Quest state before removal:", quest.state)
		print("Objectives:")
		for obj in quest.objectives:
			print("  -", obj.target_name, "Completed:", obj.is_completed)
	
	quests.erase(quest_id)
	quest_list_updated.emit()
	Global.player.update_quest_tracker()
	
	print("Remaining quests:", quests.keys())
	print("===================\n")
	
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
	if quest.has_method("process_rewards") and quest.state == "completed":
		quest.process_rewards(quest)
		# Remove the quest from active quests
		remove_quest(quest_id)
		
	
func get_active_quests() -> Array:
	var active_quests = []
	print("[GET_ACTIVE_QUESTS] quests = ",quests)
	for quest in quests.values():
		#print("[GET_ACTIVE_QUESTS] ",quest)
		if quest.state == "in_progress":
			active_quests.append(quest)
	#print("from get_active_quests",active_quests)
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
