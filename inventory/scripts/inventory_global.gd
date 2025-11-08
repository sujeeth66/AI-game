extends Node

var inventory = []
var player : CharacterBody2D
var quest_manager : Node2D

@onready var inventory_slot = preload("res://inventory/scenes/inventory_slot.tscn")

signal inventory_updated

var items = [
	{"item_type":"quest_item" , "item_name":"raw_chicken" , "item_effect":"heal - 80" , "item_texture":preload("res://textures/raw_chicken.png")},
	{"item_type":"consumable" , "item_name":"apple" , "item_effect":"slot_boost - 1" , "item_texture":preload("res://textures/apple_icon.png")},
	{"item_type":"consumable" , "item_name":"cooked_chicken" , "item_effect":"heal - 100" , "item_texture":preload("res://textures/cooked_chicken.png")},
	{"item_type":"consumable" , "item_name":"raw_beef" , "item_effect":"heal - 150" , "item_texture":preload("res://textures/raw_meat.png")},
	{"item_type":"consumable" , "item_name":"steak" , "item_effect":"heal - 250" , "item_texture":preload("res://textures/cooked_steak.png")}
]

var hotbar_size = 6
var hotbar_inventory = []

func _ready() -> void:
	inventory.resize(30)
	hotbar_inventory.resize(hotbar_size)
	call_deferred("setup_global_variables")
	
func setup_global_variables():
	_refresh_references()

func _refresh_references():
	if player == null or not is_instance_valid(player):
		if "player" in Global:
			player = Global.player
	if quest_manager == null or not is_instance_valid(quest_manager):
		if "global_quest_manager" in Global:
			quest_manager = Global.global_quest_manager
		if quest_manager == null and player != null:
			if player.has_node("QuestManager"):
				quest_manager = player.get_node("QuestManager")

func _update_quest_progress_for_item(item_name: String, quantity: int) -> void:
	_refresh_references()
	if quest_manager == null:
		push_warning("[InventoryGlobal] Quest manager not ready; quest progress not updated for " + item_name)
		return
	if player == null:
		push_warning("[InventoryGlobal] Player reference missing; quest tracker not refreshed")
		return
	
	var normalized_item_name = item_name#.strip_edges().to_lower()
	print("[DEBUG] Checking quest progress for item: ", item_name, " (normalized: ", normalized_item_name, ")")
	print("[DEBUG] quest_manager.get_active_quests() = ",quest_manager.get_active_quests())
	
	for quest in quest_manager.get_active_quests():
		print("[DEBUG] Checking quest: ", quest.quest_name)
		for objective in quest.objectives:
			if objective.objective_type != "collection":
				continue
				
			var objective_name = objective.target_name#.strip_edges().to_lower()
			print("[DEBUG] - Objective: ", objective_name, " == ", normalized_item_name, "?")
			
			if objective_name == normalized_item_name:
				print("[SUCCESS] Found matching objective! Updating quest progress")
				quest.update_objective(quest.quest_id, objective.id, quantity)
				player.update_quest_tracker()
				if quest.is_completed():
					quest_manager.update_quest(quest.quest_id, "completed")
				return
			else:
				print("[FAILURE]Did Not Find matching objective! Updating quest progress")

func add_item(item, to_hotbar = false):
	_refresh_references()

	var added_to_hotbar = false
	if to_hotbar:
		added_to_hotbar = add_item_to_hotbar(item)
	
	if not added_to_hotbar:
		for i in range(inventory.size()):
			if inventory[i] != null and inventory[i]["item_name"] == item["item_name"]:
				inventory[i]["quantity"] += item["quantity"]
				print("[DEBUG] Added to existing stack: ", item["item_name"])
				inventory_updated.emit()
				_update_quest_progress_for_item(item["item_name"], item["quantity"])
				return true
			elif inventory[i] == null:
				inventory[i] = item.duplicate(true)
				print("[DEBUG] Added new item: ", item["item_name"])
				inventory_updated.emit()
				_update_quest_progress_for_item(item["item_name"], item["quantity"])
				return true
	return false
	
func remove_item(item_name):
	for i in range(inventory.size()):
		if inventory[i] != null and inventory[i]["item_name"] == item_name:
			inventory[i]["quantity"] -= 1
			if inventory[i]["quantity"] <= 0:
				inventory[i] = null
			inventory_updated.emit()
			return true
	return false
	
func increase_inventory_size(extra_slots):
	inventory.resize(inventory.size() + extra_slots)
	inventory_updated.emit()
	
	
func create_item(name, type, effect, texture):
	var new_item = {
		"item_name": name,
		"item_type": type,
		"item_effect": effect,
		"item_texture": texture
	}
	items.append(new_item)

func add_item_to_hotbar(item):
	for i in range(hotbar_size):
		if hotbar_inventory[i] == null:
			hotbar_inventory[i] = item
			return true
	return false 

func remove_item_from_hotbar(item_name):
	for i in range(hotbar_inventory.size()):
		if hotbar_inventory[i] != null and hotbar_inventory[i]["item_name"] == item_name:
			if hotbar_inventory[i]["quantity"] <= 0:
				hotbar_inventory[i] = null
			inventory_updated.emit()
			return true
	return false

func unassign_hotbar_item(item_name):
	for i in range(hotbar_inventory.size()):
		if hotbar_inventory[i] != null and hotbar_inventory[i]["item_name"] == item_name:
			hotbar_inventory[i] = null
			inventory_updated.emit()
			return true
	return false

func is_item_assigned_to_hotbar(item):
	return item in hotbar_inventory

func swap_inventory_items(index1,index2):
	if index1 < 0 or index1 > inventory.size() or index2 < 0 or index2 > inventory.size():
		return false
		
	var temp = inventory[index1]
	inventory[index1] = inventory[index2]
	inventory[index2] = temp
	inventory_updated.emit()
	return true

func swap_hotbar_items(index1,index2):
	if index1 < 0 or index1 > hotbar_inventory.size() or index2 < 0 or index2 > hotbar_inventory.size():
		return false
		
	var temp = hotbar_inventory[index1]
	hotbar_inventory[index1] = hotbar_inventory[index2]
	hotbar_inventory[index2] = temp
	inventory_updated.emit()
	return true
