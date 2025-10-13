extends Node

class_name CharState

# Reference to the state machine and character
@onready var state_machine: CharStateMachine 
@onready var animated_sprite: AnimatedSprite2D = get_parent().get_parent().get_node("body_animated_sprites")
@onready var character: CharacterBody2D = get_parent().get_parent()
@onready var ray_cast: RayCast2D = $"../../RayCast2D"

# Direction management
var direction: float = 1.0  # 1 for right, -1 for left
var last_attack_time: float = 0.0
var attack_cooldown: float = 0.3

func _ready():
	pass
	
# Virtual methods
func enter() -> void:
	pass
	
func exit() -> void:
	pass
	
func update(delta: float) -> void:
	pass
		
func physics_update(delta: float) -> void:
	pass

func handle_input(event: InputEvent) -> void:
	pass
	
# Updates the sprite's facing direction only when it changes
func _update_sprite_direction() -> void:
	if animated_sprite and animated_sprite.flip_h == GlobalStates.facing_right:
		animated_sprite.flip_h = not GlobalStates.facing_right
		#print("Sprite flip updated: ", "facing " + ("right" if GlobalStates.facing_right else "left"), 
			#  " (flip_h: ", not GlobalStates.facing_right, ")")
		ray_cast.target_position = Vector2(50,0) if GlobalStates.facing_right else Vector2(-50,0)
