extends CharacterBody2D

class_name Player
# ⚡ Resources
const MAX_HEALTH := 1000.0
const HEALTH_REGEN_RATE := 300
const MAX_STAMINA := 1000.0
const STAMINA_REGEN_RATE := 300.0  # per second
const STAMINA_DASH_COST := 40
const MAX_MANA := 1000.0
const MANA_REGEN_RATE := 500.0  # per second

# States
var is_respawning: bool = false

# Resources
var health := MAX_HEALTH
var stamina: float = MAX_STAMINA
var mana: float = MAX_MANA
var is_exhausted: bool = false

var selected_quest 
var coin_amount = 0 

# Respawn
var respawn_timer: float = 0.0

var global_quest_ui


# UI References
@onready var health_bar: ProgressBar = $Camera2D/health_bar
@onready var mana_bar: ProgressBar = $Camera2D/mana_bar
@onready var stamina_bar : ProgressBar = $Camera2D/stamina_bar
@onready var inventory_canvas: CanvasLayer = $inventory_canvas
@onready var inventory_ui: CanvasLayer = $inventory_ui
@onready var inventory_hotbar: CanvasLayer = $InventoryHotbar
@onready var animated_sprite: AnimatedSprite2D = $body_animated_sprites
@onready var ray_cast: RayCast2D = $RayCast2D

@onready var amount: Label = $HUD/Coins/Amount
@onready var quest_tracker: ColorRect = $HUD/QuestTracker
@onready var title: Label = $HUD/QuestTracker/Details/Title
@onready var objectives: VBoxContainer = $HUD/QuestTracker/Details/Objectives
@onready var quest_manager: Node2D = $QuestManager


func _ready() -> void:
	Global.player = self
	QuestGlobal.player = self
	update_quest_tracker()
	update_coins(110)
	global_quest_ui = Global.global_quest_ui
	inventory_hotbar.visible = false
	add_to_group("player")
	selected_quest = global_quest_ui.selected_quest
	print("selected_quest------------player ready",selected_quest.quest_id if selected_quest else 0)
	# Initialize UI elements
	if health_bar:
		health_bar.init_health(MAX_HEALTH)
	if mana_bar:
		mana_bar.init_mana(MAX_MANA)
	if stamina_bar:
		stamina_bar.init_stamina(MAX_STAMINA)

#func _process(delta: float) -> void:
	#quest_manager.get_active_quests()

func _physics_process(delta: float) -> void:
	if _handle_respawn(delta):
		return
	# Regenerate resources
	_regenerate_resources(delta)
	
	# Update global player position for enemies to track
	Global.player_position = global_position

func _regenerate_resources(delta: float) -> void:
	# Mana regeneration
	if mana < MAX_MANA:
		mana = min(mana + MANA_REGEN_RATE * delta, MAX_MANA)
		if mana_bar:
			mana_bar.mana = mana
	
	# Stamina regeneration (only when not exhausted and not using stamina)
	if stamina < MAX_STAMINA and not is_exhausted:
		stamina = min(stamina + STAMINA_REGEN_RATE * delta, MAX_STAMINA)
		if stamina_bar:
			stamina_bar.stamina = stamina
			
		# Reset exhaustion if stamina is sufficiently regenerated
		if stamina > MAX_STAMINA * 0.3:  # 30% of max stamina
			is_exhausted = false

func _handle_respawn(delta: float) -> bool:
	if not is_respawning:
		return false
		
	respawn_timer -= delta
	if respawn_timer <= 0.0:
		respawn()
	return true

func take_damage(amount: int) -> void:
	if is_respawning :
		return
	
	health = max(0, health - amount)
	health_bar.health = health
	
	if health <= 0:
		die()

func die() -> void:
	if is_respawning:
		return
	# Slow down the whole game for dramatic effect
	Engine.time_scale = 0.3
	# Immediately set respawn state and timer
	is_respawning = true
	respawn_timer = 1.0  # 1 second for all deaths (slow-mo)
	# Play death animation for entire respawn duration
	animated_sprite.play("death")
	# Do not call respawn() here. _physics_process will handle it.

func respawn() -> void:
	health = MAX_HEALTH
	velocity = Vector2.ZERO
	health_bar.health = health
	# Get spawn position from 5gen
	var spawn_pos = load("res://scripts/5gen.gd").player_spawn_position
	global_position = spawn_pos
	
	# Restore normal game speed
	Engine.time_scale = 1.0

	# Only now allow future deaths
	is_respawning = false
	
func use_mana(amount: float) -> bool:
	if mana >= amount:
		mana -= amount
		mana_bar.mana = mana  # Update the mana bar
		return true
	return false  # Not enough mana

func use_stamina(amount: float) -> bool:
	if stamina >= amount and not is_exhausted:
		stamina -= amount
		if stamina_bar:
			stamina_bar.stamina = stamina
		if stamina <= 0:
			is_exhausted = true
		return true
	return false

func has_stamina(amount: float) -> bool:
	return stamina >= amount and not is_exhausted
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		inventory_ui.visible = !inventory_ui.visible
		get_tree().paused = !get_tree().paused
		
	
	if Global.can_move:
		if event.is_action_pressed("interact"):
			var target = ray_cast.get_collider()
			if target != null:
				var target_parent = target.get_parent()
				if target.is_in_group("NPC"):
					inventory_hotbar.visible = false
					Global.can_move = false
					target.start_dialog()
					check_quest_objectives(target.npc_id,"talk_to")
				
	if event.is_action_pressed("quest_menu"):
		global_quest_ui.show_hide_quest_log()
				
# In player.gd
func check_quest_objectives(target_name: String, objective_type: String, quantity: int = 1):
	print("from check_quest_objectives")
	# Check all active quests
	for quest in quest_manager.get_active_quests():
		for objective in quest.objectives:
			if (objective.target_name == target_name and 
				objective.objective_type == objective_type and 
				not objective.is_completed):
				
				
				# Pass the quantity to the quest manager
				quest_manager.update_objective(quest.quest_id, objective.id, quantity)
				#quest_item.quest_item_collected(quest,objective.id, quantity)
				
				# Update UI if this is the selected quest
				if selected_quest and selected_quest.quest_id == quest.quest_id:
					update_quest_tracker()

	
func heal(amount: int) -> void:
	health = min(health + amount, MAX_HEALTH)
	if health_bar:
		health_bar.health = health  # Explicitly update the health bar

func apply_item_effect(item: Dictionary) -> void:
	var effect_data = item.get("item_effect", "").strip_edges()
	
	if effect_data.is_empty():
		return
		
	var parts = effect_data.split("-", false, 1)
	
	if parts.size() != 2:
		return
	
	var effect_type = parts[0].strip_edges()
	var effect_value = parts[1].strip_edges()
	
	if not effect_value.is_valid_int():
		return
		
	var value = effect_value.to_int()
	
	match effect_type:
		"heal":
			heal(value)
			
		"slot_boost":
			InventoryGlobal.increase_inventory_size(value)
		_:
			pass

func use_hotbar_item(slot_index):
	if slot_index < InventoryGlobal.hotbar_inventory.size():
		var item = InventoryGlobal.hotbar_inventory[slot_index]
		if item != null:
			apply_item_effect(item)
			item["quantity"] -= 1
			if item["quantity"] <= 0:
				InventoryGlobal.hotbar_inventory[slot_index] = null
				InventoryGlobal.remove_item(item["item_name"])
			InventoryGlobal.inventory_updated.emit()
			
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		for i in range(InventoryGlobal.hotbar_size):
			if Input.is_action_just_pressed("hotbar_" + str(i + 1)):
				use_hotbar_item(i)
				break

func apply_knockback(knockback_force: Vector2) -> void:
	# Apply knockback using the GlobalStates system
	var direction_multiplier = 1 if knockback_force.x > 0 else -1
	GlobalStates.apply_knockback(abs(knockback_force.x) * direction_multiplier, 0.3)  # 0.3 second duration

func update_coins(coins_gained):
	if amount:
		amount.text = str(coin_amount + coins_gained)
		coin_amount = coin_amount + coins_gained
		
func update_quest_tracker():
	print("from update_quest_tracker")
	var active_quests = quest_manager.get_active_quests()
	
	# If selected quest is null or no longer active, select the first available quest
	if selected_quest == null or not active_quests.has(selected_quest):
		if not active_quests.is_empty():
			selected_quest = active_quests[0]
			# Update the quest UI's selected quest as well
			if Global.global_quest_ui:
				Global.global_quest_ui.selected_quest = selected_quest
			print("selected_quest------------from update_quest_tracker", selected_quest.quest_id if selected_quest else "null")
		else:
			selected_quest = null
			if Global.global_quest_ui:
				Global.global_quest_ui.selected_quest = null

	if selected_quest != null:
		quest_tracker.visible = true
		title.text = selected_quest.quest_name
		
		for child in objectives.get_children():
			objectives.remove_child(child)
			child.queue_free()
			
		for objective in selected_quest.objectives:
			var label = Label.new()
			label.text = objective.description + "(" + str(objective.collected_quantity) + "/" + str(objective.required_quantity) + ")"
			if objective.is_completed:
				label.add_theme_color_override("font_color",Color(0,1,0))
			else:
				label.add_theme_color_override("font_color",Color(1,0,0))
			objectives.add_child(label)
	else:
		quest_tracker.visible = false
