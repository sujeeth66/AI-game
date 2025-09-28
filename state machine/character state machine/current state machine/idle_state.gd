extends CharState

class_name CharIdleState

func enter():
	animated_sprite.play("idle")
	# Ensure the sprite maintains its current facing direction
	_update_sprite_direction()
	#print("Entered idle state")

func handle_input(event: InputEvent):
	if not Global.can_move or GlobalStates.is_knockback_active():
		return
	
	var input_direction = get_movement_input()
	if input_direction != 0:
		update_direction(input_direction)
		state_machine.change_state("runstate")
		return
	
	if is_jump_pressed():
		state_machine.change_state("jumpstate")
		return
	
	if is_dash_pressed():
		state_machine.change_state("dashstate")
		return

func physics_update(delta: float):
	# Check for held movement input (fixes dash->idle transition issue)
	if Global.can_move:
		var input_direction = get_movement_input()
		if input_direction != 0:
			update_direction(input_direction)
			state_machine.change_state("runstate")
			return
	
	# Apply friction
	character.velocity.x = move_toward(character.velocity.x, 0, state_machine.FRICTION)

func exit():
	#print("Exiting idle state")
	pass
