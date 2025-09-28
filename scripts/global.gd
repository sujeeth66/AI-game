extends Node

# 🌍 Global Variables
var player_position: Vector2 = Vector2.ZERO
var can_move : bool = true

var global_quest_ui : Control
var global_quest_manager : Node2D
var player: CharacterBody2D 

var max_health: int = 1000
var current_health: int = max_health

# 🔋 Player Resources
var current_stamina: float = 100.0
var max_stamina: float = 100.0
var current_mana: float = 100.0
var max_mana: float = 100.0


func _ready() -> void:
	Engine.max_fps = 30  # Or 60, or whatever you want
	# Create UI scene
	call_deferred("_init_health_bar")
	
func _init_health_bar():
	var health_bar = player.health_bar
