extends CharState

class_name RunState

func enter():
	animated_sprite.play("run")
	# Ensure the sprite's facing direction is correct
	_update_sprite_direction()
	#print("Entered run state")

func handle_input(event: InputEvent):
	if is_jump_pressed():
		state_machine.change_state("jumpstate")
		return
		
	if is_dash_pressed():
		state_machine.change_state("dashstate")
		return

func physics_update(delta: float):
	if not Global.can_move or GlobalStates.is_fireball_active():
		character.velocity.x = 0  # Instant stop
		play_animation("idle")
		return
	
	var input_direction = get_movement_input()
	
	if input_direction != 0:
		update_direction(input_direction)
		play_animation("run")
		
		# Instant movement - no acceleration/deceleration
		character.velocity.x = input_direction * state_machine.MOVEMENT_SPEED
	else:
		# Transition to idle state - let idle handle the stopping logic
		state_machine.change_state("idlestate")

func exit():
	animated_sprite.stop()
	#print("Exiting run state")
