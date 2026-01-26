extends Node

var inventory = []
var player : CharacterBody2D
var quest_manager : Node2D

@onready var inventory_slot = preload("res://inventory/scenes/inventory_slot.tscn")

signal inventory_updated

var items: Dictionary = {
	"raw_chicken": Item.new("raw_chicken", "quest_item", "heal - 80", preload("res://textures/raw_chicken.png") as CompressedTexture2D),
	"apple": Item.new("apple", "consumable", "slot_boost - 1", preload("res://textures/apple_icon.png") as CompressedTexture2D),
	"cooked_chicken": Item.new("cooked_chicken", "consumable", "heal - 100", preload("res://textures/cooked_chicken.png") as CompressedTexture2D),
	"raw_beef": Item.new("raw_beef", "consumable", "heal - 150", preload("res://textures/raw_meat.png") as CompressedTexture2D),
	"steak": Item.new("steak", "consumable", "heal - 250", preload("res://textures/cooked_steak.png") as CompressedTexture2D)
}

var hotbar_size = 6
var hotbar_inventory = []

func _ready() -> void:
	inventory.resize(30)
	hotbar_inventory.resize(hotbar_size)
	call_deferred("_refresh_references")
	
func get_item(item_name: String) -> Item:
	return items.get(item_name, null)
	
func _refresh_references():
	if player == null or not is_instance_valid(player):
		player = Global.player
	if quest_manager == null or not is_instance_valid(quest_manager):
		quest_manager = Global.global_quest_manager
		if quest_manager == null :
			quest_manager = Global.global_quest_manager

func _update_quest_progress_for_item(item_name: String, quantity: int) -> void:
	_refresh_references()
	if quest_manager == null:
		push_warning("[InventoryGlobal] Quest manager not ready; quest progress not updated for " + item_name)
		return
	if player == null:
		push_warning("[InventoryGlobal] Player reference missing; quest tracker not refreshed")
		return
	
	var normalized_item_name = item_name#.strip_edges().to_lower()
	#print("[DEBUG] Checking quest progress for item: ", item_name, " (normalized: ", normalized_item_name, ")")
	#print("[DEBUG] quest_manager.get_active_quests() = ",quest_manager.get_active_quests())
	
	for quest in quest_manager.get_active_quests():
		#print("[DEBUG] Checking quest: ", quest.quest_name)
		for objective in quest.objectives:
			if objective.objective_type != "collection":
				continue
				
			var objective_name = objective.target_name#.strip_edges().to_lower()
			#print("[DEBUG] - Objective: ", objective_name, " == ", normalized_item_name, "?")
			
			if objective_name == normalized_item_name:
				#print("[SUCCESS] Found matching objective! Updating quest progress")
				quest.update_objective(quest.quest_id, objective.id, quantity)
				player.update_quest_tracker()
				if quest.is_completed():
					quest_manager.update_quest(quest.quest_id, "completed")
					player.update_quest_tracker()
				return
			else:
				pass#print("[FAILURE]Did Not Find matching objective! Updating quest progress")

func add_item(item: Item, to_hotbar: bool = false) -> bool:
	_refresh_references()
	var added_to_hotbar = false
	if to_hotbar:
		added_to_hotbar = add_item_to_hotbar(item)
	if not added_to_hotbar:
		for i in range(inventory.size()):
			if inventory[i] != null and inventory[i].item_name == item.item_name:
				inventory[i].quantity += item.quantity
				inventory_updated.emit()
				_update_quest_progress_for_item(item.item_name, item.quantity)
				return true
			elif inventory[i] == null:
				inventory[i] = item
				inventory_updated.emit()
				_update_quest_progress_for_item(item.item_name, item.quantity)
				return true
	return false
	
func remove_item(item_name: String) -> bool:
	for i in range(inventory.size()):
		if inventory[i] != null and inventory[i].item_name == item_name:
			inventory[i].quantity -= 1
			if inventory[i].quantity <= 0:
				inventory[i] = null
			inventory_updated.emit()
			return true
	return false
	
func increase_inventory_size(extra_slots):
	inventory.resize(inventory.size() + extra_slots)
	inventory_updated.emit()
	
func create_item(name: String, type: String, effect: String, texture: CompressedTexture2D) -> void:
	var new_item = Item.new(name, type, effect, texture)
	items[new_item.item_name] = new_item
 
func add_item_to_hotbar(item: Item) -> bool:
	for i in range(hotbar_size):
		if hotbar_inventory[i] == null:
			hotbar_inventory[i] = item
			return true
	return false
 
func remove_item_from_hotbar(item_name: String) -> bool:
	for i in range(hotbar_inventory.size()):
		if hotbar_inventory[i] != null and hotbar_inventory[i].item_name == item_name:
			hotbar_inventory[i].quantity -= 1
			if hotbar_inventory[i].quantity <= 0:
				hotbar_inventory[i] = null
			inventory_updated.emit()
			return true
	return false
 
func unassign_hotbar_item(item_name: String) -> bool:
	for i in range(hotbar_inventory.size()):
		if hotbar_inventory[i] != null and hotbar_inventory[i].item_name == item_name:
			hotbar_inventory[i] = null
			inventory_updated.emit()
			return true
	return false
 
func is_item_assigned_to_hotbar(item: Item) -> bool:
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
