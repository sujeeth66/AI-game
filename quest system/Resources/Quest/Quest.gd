extends Resource

class_name Quest

@export var quest_id : String
@export var quest_name : String
@export var quest_description : String
@export var state : String = "not_started"
@export var unlock_id : String
@export var objectives : Array[Objectives] = []
@export var rewards : Array[Rewards] = []

func is_completed() -> bool:
	for objective in objectives:
		if not objective.is_completed:
			return false
	print("QUEST COMPLETED:", quest_name, " (ID:", quest_id, ") - All objectives complete")
	return true
	
func update_objective(quest_id : String , objective_id : String, quantity : int = 1):
	print("quest:update_objective")
	for objective in objectives:
		if objective.id == objective_id:
			if objective.objective_type == "collection":
				objective.collected_quantity += quantity
				Global.player.update_quest_tracker()
				if objective.collected_quantity >= objective.required_quantity:
					objective.is_completed = true
					Global.player.update_quest_tracker()
			elif objective.objective_type == "talk_to":
				objective.is_completed = true
				Global.player.update_quest_tracker()
			break
		
func process_rewards(quest:Quest):
	for reward in quest.rewards:
		match reward.reward_type:
			"coins":
				print(reward.reward_amount)
				Global.player.update_coins(reward.reward_amount)
			"item":
				var item_data = {
					"item_name": reward.reward_item_name,
					"item_type": reward.reward_item_type,
					"item_effect": reward.reward_item_effect,
					"item_texture": load(reward.reward_item_texture) if reward.has("reward_item_texture") else null,
					"quantity": reward.reward_amount
				}
				if InventoryGlobal and InventoryGlobal.has_method("add_item"):
					InventoryGlobal.add_item(item_data)
				# Experience system is currently disabled
				# Uncomment to enable experience:
				# add_experience(reward.reward_amount)
				
			_:
				pass  # Unknown reward type, just ignore
				
	# Clear selected quest if it's the one being completed
	var active_quests = Global.global_quest_manager.get_active_quests()
	print("==========",Global.global_quest_ui.selected_quest,"=============",quest.quest_id,"============",active_quests)
	if Global.global_quest_ui.selected_quest == quest:
		print("Global.global_quest_ui.selected_quest ----------------set to null")
		Global.global_quest_ui.selected_quest = null
		
	# Remove quest and update tracker
	Global.player.update_quest_tracker()
	Global.global_quest_manager.remove_quest(quest.quest_id)
	print("quesst removed===================")
	Global.player.update_quest_tracker()
	print("=== REWARDS PROCESSED ===\n")
