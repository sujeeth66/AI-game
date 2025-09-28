extends AtkState

class_name FireballState

@export var fireball_scene: PackedScene = preload("res://scenes/fireball.tscn")

var fireball_cooldown: float = 0.0
var atk2_pressed: bool = false
var stop_timer: float = 0.0

func enter() -> void:
	# Check both cooldown and mana
	if fireball_cooldown > 0 or !character.use_mana(state_machine.MANA_COST):
		change_to_idle()
		GlobalStates.set_fireball_active(false)
		return
	else:
		GlobalStates.set_fireball_active(true)
	
	# Set cooldown before creating fireball
	fireball_cooldown = state_machine.FIREBALL_COOLDOWN
	stop_timer = state_machine.FIREBALL_STOP_DURATION
	
	# Create a new fireball instance each time
	var fireball = fireball_scene.instantiate()
	
	# Calculate spawn position relative to player
	var player_pos = character.global_position
	var spawn_offset = Vector2(state_machine.FIREBALL_SPAWN_DISTANCE if GlobalStates.facing_right else -state_machine.FIREBALL_SPAWN_DISTANCE, 0)
	
	fireball.position = player_pos + spawn_offset
	fireball.direction = Vector2.RIGHT if GlobalStates.facing_right else Vector2.LEFT
	fireball.get_node("AnimatedSprite2D").flip_h = not GlobalStates.facing_right
	fireball.damage = int(state_machine.PLAYER_BASE_DAMAGE * state_machine.FIREBALL_DAMAGE_MULTIPLIER)
	
	# Add fireball to the scene tree (not the state machine)
	get_tree().current_scene.add_child(fireball)
	
func exit() -> void:
	GlobalStates.set_fireball_active(false)  # Ensure movement is re-enabled

func update(delta: float) -> void:
	# Handle stop duration - player stops during fireball cast
	if stop_timer > 0:
		stop_timer -= delta
	
	# Update cooldown timer
	if fireball_cooldown > 0:
		fireball_cooldown -= delta
		# Only transition back to idle after cooldown is complete
		if fireball_cooldown <= 0:
			change_to_idle()

func physics_update(delta: float) -> void:
	# Don't set velocity.x = 0 during stop period - let knockback system handle it
	pass

func handle_input(event: InputEvent):
	pass
