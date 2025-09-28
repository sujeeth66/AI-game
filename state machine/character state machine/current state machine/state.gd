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
		ray_cast.target_position = Vector2(25,0) if GlobalStates.facing_right else Vector2(-25,0)

# Add to base CharState class
func update_direction(input_direction: float) -> void:
	if input_direction != 0:
		var new_direction = sign(input_direction)
		if new_direction != direction:
			direction = new_direction
			GlobalStates.facing_right = direction > 0
			_update_sprite_direction()

func get_movement_input() -> float:
	return Input.get_axis("move_left", "move_right")

func is_jump_pressed() -> bool:
	return Input.is_action_just_pressed("jump") and character.is_on_floor()

func is_dash_pressed() -> bool:
	return Input.is_action_just_pressed("dash") and character.has_stamina(character.STAMINA_DASH_COST)

func play_animation(anim_name: String, force: bool = false) -> void:
	if force or not animated_sprite.is_playing():
		animated_sprite.play(anim_name)

func stop_animation() -> void:
	animated_sprite.stop()
