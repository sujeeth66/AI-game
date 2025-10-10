# enemy_base.gd (base class for all enemies)
extends CharacterBody2D
class_name BaseEnemy

var enemy_id: String
var chest_id: String = ""  # Empty means not linked to any chest

func _ready():
	# Generate unique ID if not set
	if enemy_id.is_empty():
		enemy_id = "enemy_%s_%s" % [get_instance_id(), Time.get_ticks_msec()]
	
	# Connect death signal
	connect("enemy_died", _on_enemy_died)

func set_chest_assignment(chest_id: String) -> void:
	self.chest_id = chest_id
