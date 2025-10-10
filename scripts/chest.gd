# scripts/objects/chest.gd
extends Area2D
class_name Chest

signal chest_opened(chest)

@export var chest_id: String
@export var required_enemy_ids: Array[String] = []
@export var is_locked: bool = true
@export var loot_table: Array[Dictionary] = [
	{"item": "health_potion", "chance": 0.5, "min": 1, "max": 3},
	{"item": "mana_potion", "chance": 0.5, "min": 1, "max": 3}
]

var remaining_enemies: Array[String] = []
var is_player_in_range: bool = false

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var interaction_prompt: Label = $InteractionPrompt

func _ready() -> void:
	if chest_id.is_empty():
		chest_id = "chest_%s" % get_instance_id()
	
	remaining_enemies = required_enemy_ids.duplicate()
	update_prompt_visibility()
	
	# Connect to existing enemies
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.linked_chest_id == chest_id:
			_connect_to_enemy(enemy)

func _connect_to_enemy(enemy: Node) -> void:
	if not enemy.enemy_died.is_connected(_on_enemy_died):
		enemy.enemy_died.connect(_on_enemy_died)

func _on_enemy_died(enemy: Node) -> void:
	var enemy_id = enemy.enemy_id
	if enemy_id in remaining_enemies:
		remaining_enemies.erase(enemy_id)
		if remaining_enemies.size() == 0:
			unlock()
			if is_player_in_range and Global.player:
				open()

func unlock() -> void:
	is_locked = false
	if animation_player:
		animation_player.play("unlock")
	update_prompt_visibility()

func open() -> void:
	if is_locked or not Global.player:
		return
	
	if animation_player:
		animation_player.play("open")
	emit_signal("chest_opened", self)
	
	# Generate and give loot
	var loot = generate_loot()
	# Add loot to player's inventory
	if Global.player and Global.player.has_method("inventory") and Global.player.inventory.has_method("add_items"):
		Global.player.inventory.add_items(loot)
	
	# Disable interaction
	set_process_input(false)
	if interaction_prompt:
		interaction_prompt.visible = false

func _on_body_entered(body: Node2D) -> void:
	if body == Global.player:
		is_player_in_range = true
		update_prompt_visibility()
		if not is_locked:
			open()

func _on_body_exited(body: Node2D) -> void:
	if body == Global.player:
		is_player_in_range = false
		update_prompt_visibility()

func update_prompt_visibility() -> void:
	if not interaction_prompt:
		return
		
	if is_locked:
		interaction_prompt.text = "Defeat %d enemies to unlock" % remaining_enemies.size()
		interaction_prompt.visible = is_player_in_range
	else:
		interaction_prompt.text = "Press E to open"
		interaction_prompt.visible = is_player_in_range and is_processing_input()

func generate_loot() -> Array:
	var result = []
	for entry in loot_table:
		if randf() <= entry.chance:
			var amount = randi_range(entry.min, entry.max)
			result.append({"item": entry.item, "amount": amount})
	return result

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and is_player_in_range and not is_locked:
		open()
