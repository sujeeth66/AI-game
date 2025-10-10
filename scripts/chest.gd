# chest.gd
extends Area2D
class_name TreasureChest

@export var linked_enemy_ids: Array[String] = []
@export var is_locked := true
@export var chest_id: String = ""

var remaining_enemies: Array[String] = []

func _ready():
	if chest_id.is_empty():
		chest_id = "chest_%s_%s" % [get_instance_id(), Time.get_ticks_msec()]
	
	# Find and track enemies
	for enemy_id in linked_enemy_ids:
		var enemy = find_enemy_by_id(enemy_id)
		if enemy:
			enemy.set_chest_assignment(chest_id)
			remaining_enemies.append(enemy_id)
			if not enemy.is_connected("enemy_died", _on_enemy_died):
				enemy.connect("enemy_died", _on_enemy_died.bind(enemy_id))

func find_enemy_by_id(id: String) -> BaseEnemy:
	# Find enemy by ID in the scene tree
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.enemy_id == id:
			return enemy
	return null

func _on_enemy_died(enemy_id: String):
	if enemy_id in remaining_enemies:
		remaining_enemies.erase(enemy_id)
		if remaining_enemies.size() == 0:
			unlock_chest()
