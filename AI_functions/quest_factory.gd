extends Node

const Quest = preload("res://quest system/Resources/Quest/Quest.gd")
const Objectives = preload("res://quest system/Resources/Quest/Objectives.gd")
const Rewards = preload("res://quest system/Resources/Quest/Rewards.gd")

## Factory helpers for building Quest resources compatible with the existing quest system

func create_quest(
		quest_id: String,
		quest_name: String,
		quest_description: String,
		objectives_input: Array, # Array of Dictionaries for objectives
		rewards_input: Array # Array of Dictionaries for rewards
	) -> Quest:
	var quest: Quest = Quest.new()
	quest.quest_id = quest_id
	quest.quest_name = quest_name
	quest.quest_description = quest_description
	quest.state = "not_started"
	quest.objectives = _build_objectives_array(objectives_input)
	quest.rewards = _build_rewards_array(rewards_input)
	return quest


func register_quest_with_manager(quest: Quest) -> void:
	if Global and Global.global_quest_manager and Global.global_quest_manager.has_method("add_quest"):
		Global.global_quest_manager.add_quest(quest)


func _build_objectives_array(objectives_input: Array) -> Array[Objectives]:
	var built: Array[Objectives] = []
	for o in objectives_input:
		if typeof(o) == TYPE_DICTIONARY:
			built.append(_build_objective(o))
		elif o is Objectives:
			built.append(o)
	return built


func _build_rewards_array(rewards_input: Array) -> Array[Rewards]:
	var built: Array[Rewards] = []
	for r in rewards_input:
		if typeof(r) == TYPE_DICTIONARY:
			built.append(_build_reward(r))
		elif r is Rewards:
			built.append(r)
	return built


func _build_objective(data: Dictionary) -> Objectives:
	var obj: Objectives = Objectives.new()
	obj.id = data.get("id", _gen_id())
	obj.description = data.get("description", "")
	obj.target_name = data.get("target_name", "")
	obj.objective_type = data.get("objective_type", "collection") # "collection" | "talk_to"
	obj.objective_dialog = data.get("objective_dialog", "")
	obj.required_quantity = int(data.get("required_quantity", 0))
	obj.collected_quantity = int(data.get("collected_quantity", 0))
	obj.is_completed = bool(data.get("is_completed", false))
	return obj


func _build_reward(data: Dictionary) -> Rewards:
	var rw: Rewards = Rewards.new()
	rw.reward_type = data.get("reward_type", "coins") # "coins" | "item" (engine handles supported)
	rw.reward_amount = int(data.get("reward_amount", 1))
	# If your Rewards.gd grows (e.g., item fields), you can attach via set if present
	for k in ["reward_item_name", "reward_item_type", "reward_item_effect", "reward_item_texture"]:
		if data.has(k):
			rw.set(k, data[k])
	return rw


func _gen_id() -> String:
	return str(Time.get_unix_time_from_system()) + "_" + str(randi() % 100000)
