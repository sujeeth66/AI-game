# scripts/enemies/base_enemy.gd
extends CharacterBody2D

class_name BaseEnemy

# Common enemy signals
signal enemy_died(enemy)
signal enemy_damaged(amount)

@export var enemy_id: String
@export var linked_chest_id: String = ""

var is_dead: bool = false

func _ready():
	if enemy_id.is_empty():
		enemy_id = "enemy_%s_%s" % [get_instance_id(), Time.get_ticks_msec()]
	if linked_chest_id.is_empty():
		linked_chest_id = "chest_%s" % get_instance_id()

func take_damage(amount: int) -> void:
	# Implement damage logic
	emit_signal("enemy_damaged", amount)

func die() -> void:
	if is_dead:
		return
	is_dead = true
	emit_signal("enemy_died", self)
	# Add death animation and cleanup
