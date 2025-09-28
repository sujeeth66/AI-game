extends Node

class_name AtkState

# Reference to the state machine and character
@onready var state_machine: AtkStateMachine 
@onready var attack_animations : AnimatedSprite2D = get_parent().get_parent().get_node("AttackAnimations")
@onready var character: CharacterBody2D = get_parent().get_parent()
var direction = 1
var last_attack_time: float = 0.0

func _ready():
	pass
	
func enter() -> void:
	pass
	
func exit() -> void:
	pass
	
func update(delta: float) -> void:
	pass
		
func physics_update(delta: float) -> void:
	pass

func handle_input(event: InputEvent):
	pass

# Helper function to handle state transitions consistently
func change_to_idle():
	state_machine.change_state("atkidlestate")

# Helper function to check if enough time has passed since last attack
func can_attack() -> bool:
	var current_time = Time.get_ticks_msec()
	return (current_time - last_attack_time) > (state_machine.ATTACK_COOLDOWN * 1000)

# Helper function to update last attack time
func update_attack_time():
	last_attack_time = Time.get_ticks_msec()

# Helper function to check if animation is finished
func is_animation_finished() -> bool:
	return attack_animations and not attack_animations.is_playing()

# Helper function to stop and hide attack animations
func stop_attack_animation():
	if attack_animations:
		attack_animations.visible = false
		attack_animations.stop()

# Helper function to play attack animation
func play_attack_animation(anim_name: String):
	if attack_animations:
		attack_animations.visible = true
		attack_animations.position = Vector2(state_machine.ANIMATION_OFFSET_X, 0) if GlobalStates.facing_right else Vector2(-state_machine.ANIMATION_OFFSET_X, 0)
		attack_animations.flip_h = not GlobalStates.facing_right
		
		if attack_animations.sprite_frames and attack_animations.sprite_frames.has_animation(anim_name):
			attack_animations.play(anim_name)
		else:
			if attack_animations.sprite_frames and attack_animations.sprite_frames.has_animation("slash1"):
				attack_animations.play("slash1")

# Helper function to apply knockback
func apply_knockback(force: float, direction_multiplier: int = 1):
	if is_instance_valid(character):
		character.velocity.x = force * direction_multiplier
