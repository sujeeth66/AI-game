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
	player = Global.player
	quest_manager = Global.global_quest_manager

func add_item(item,to_hotbar = false):
	var added_to_hotbar = false
	if to_hotbar:
		added_to_hotbar = add_item_to_hotbar(item)
		#inventory_updated.emit()
	if not added_to_hotbar:
		for i in range(inventory.size()):
			if inventory[i] != null and inventory[i]["item_name"] == item["item_name"]:
				inventory[i]["quantity"] += item["quantity"]
				print("from add_item")
				for quest in quest_manager.get_active_quests():
					for objective in quest.objectives:
						if objective.objective_type == "collection" and objective.target_name == item["item_name"] :
							quest.update_objective(quest.quest_id,objective.id, item["quantity"])
							player.update_quest_tracker()
							if quest.is_completed():
								quest_manager.update_quest(quest.quest_id, "completed")
				inventory_updated.emit()
				#print("item added ",inventory)
				return true
			elif inventory[i] == null:
				inventory[i] = item
				print("from add_item")
				for quest in quest_manager.get_active_quests():
					for objective in quest.objectives:
						if objective.objective_type == "collection" and objective.target_name == item["item_name"] :
							quest.update_objective(quest.quest_id,objective.id, item["quantity"])
							player.update_quest_tracker()
							if quest.is_completed():
								quest_manager.update_quest(quest.quest_id, "completed")
				inventory_updated.emit()
				#print("item added ",inventory)
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
