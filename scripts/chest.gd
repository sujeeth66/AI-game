# scripts/chest.gd
extends Area2D
class_name Chest

signal chest_opened(chest)

@export var chest_id: String
@export var required_enemy_ids: Array[String] = []
@export var is_locked: bool = true
@export var room_tier: String = "common"
@export var room_distance: float = 0.0

var remaining_enemies: Array[String] = []
var player_in_range: bool = false
var is_animating: bool = false
var is_opened: bool = false

@onready var closed_sprite: Sprite2D = $Sprite2D
@onready var open_animation: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_prompt: Label = $Label
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	if chest_id.is_empty():
		chest_id = "chest_%s" % get_instance_id()
	
	remaining_enemies = required_enemy_ids.duplicate()
	update_visuals()
	
	# Connect to existing enemies
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.has_method("get_linked_chest_id") and enemy.get_linked_chest_id() == chest_id:
			_connect_to_enemy(enemy)

func _process(delta: float) -> void:
	if player_in_range and Input.is_action_just_pressed("interact"):
		if is_locked and remaining_enemies.size() == 0:
			await unlock()
		elif not is_locked and not is_opened:
			open()

func setup_from_room(room_data: Dictionary) -> void:
	room_tier = room_data.get("tier", "common")
	room_distance = room_data.get("distance", 0.0)

func _connect_to_enemy(enemy: Node) -> void:
	if enemy.has_signal("enemy_died") and not enemy.enemy_died.is_connected(_on_enemy_died):
		enemy.enemy_died.connect(_on_enemy_died.bind(enemy))

func update_visuals() -> void:
	if not closed_sprite or not open_animation:
		return
		
	closed_sprite.visible = !is_animating and !is_opened
	open_animation.visible = is_animating or is_opened
	if is_opened and open_animation.has_animation("opened"):
		open_animation.play("opened")

func _on_enemy_died(enemy: Node) -> void:
	var enemy_id = enemy.get_enemy_id() if enemy.has_method("get_enemy_id") else str(enemy.get_instance_id())
	if enemy_id in remaining_enemies:
		remaining_enemies.erase(enemy_id)
		if remaining_enemies.size() == 0:
			await unlock()
			if player_in_range and Global.player:
				open()

func unlock() -> void:
	is_locked = false
	if has_node("UnlockParticles"):
		$UnlockParticles.emitting = true
	await get_tree().create_timer(0.5).timeout
	update_prompt_visibility()

func open() -> void:
	if is_animating or is_locked or is_opened or not Global.player:
		return
	
	is_animating = true
	update_visuals()
	
	if open_animation and open_animation.sprite_frames.has_animation("open"):
		open_animation.play("open")
		await open_animation.animation_finished
	
	emit_signal("chest_opened", self)
	distribute_loot()
	is_opened = true
	is_animating = false
	
	update_prompt_visibility()

func distribute_loot() -> void:
	var loot = generate_loot()
	for item_data in loot:
		var item = {
			"item_name": item_data.item_name,
			"item_type": item_data.item_type,
			"item_effect": item_data.item_effect,
			"item_texture": item_data.item_texture,
			"quantity": item_data.amount
		}
		InventoryGlobal.add_item(item)
		print("Added to inventory: ", item.item_name, " x", item.quantity)

func generate_loot() -> Array:
	var result = []
	var available_items = get_items_for_tier(room_tier, room_distance)
	
	# Adjust number of items based on distance
	var item_count = 1
	if room_distance > 100:
		item_count = 2
	if room_distance > 200:
		item_count = 3
	
	for i in range(item_count):
		if available_items.size() > 0:
			var item = available_items[randi() % available_items.size()]
			result.append({
				"item_name": item.item_name,
				"item_type": item.item_type,
				"item_effect": item.item_effect,
				"item_texture": item.item_texture,
				"amount": 1
			})
	
	return result

func get_items_for_tier(tier: String, distance: float) -> Array:
	var filtered_items = []
	var min_heal = 0
	
	# Adjust item quality based on distance
	if distance > 200:
		min_heal = 120
	elif distance > 100:
		min_heal = 80
	
	for item in InventoryGlobal.items:
		var heal_amount = get_heal_amount(item.get("item_effect", ""))
		if heal_amount >= min_heal:
			if tier == "common" and heal_amount <= 100:
				filtered_items.append(item)
			elif tier == "uncommon" and heal_amount > 100 and heal_amount <= 200:
				filtered_items.append(item)
			elif tier == "rare" and heal_amount > 200:
				filtered_items.append(item)
			elif tier == "epic":
				filtered_items.append(item)
	
	return filtered_items

func get_heal_amount(effect: String) -> int:
	if effect.begins_with("heal - "):
		return int(effect.replace("heal - ", ""))
	return 0

func _on_area_2d_body_entered(body: Node2D) -> void:
	print("player entered")
	if body.is_in_group("player"):
		player_in_range = true
		print("player entered")
		update_prompt_visibility()

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		update_prompt_visibility()

func update_prompt_visibility() -> void:
	if not interaction_prompt or is_animating or is_opened:
		if interaction_prompt:
			interaction_prompt.visible = false
		return
		
	if is_locked and remaining_enemies.size() > 0:
		interaction_prompt.text = "Defeat %d enemies to unlock" % remaining_enemies.size()
		interaction_prompt.visible = player_in_range
	elif is_locked:
		interaction_prompt.text = "Press E to unlock"
		interaction_prompt.visible = player_in_range
	else:
		interaction_prompt.text = "Press E to open"
		interaction_prompt.visible = player_in_range and not is_opened
