extends CharState

class_name CharIdleState

func enter():
	animated_sprite.play("idle")
	# Ensure the sprite maintains its current facing direction
	_update_sprite_direction()
	#print("Entered idle state")

func handle_input(event: InputEvent):
	# Check for movement input
	var input_direction = Input.get_axis("move_left", "move_right")
	if input_direction != 0:
		# Update direction before changing state
		direction = sign(input_direction)
		GlobalStates.facing_right = direction > 0
		state_machine.change_state("runstate")
		return
		
	# Check for jump input
	if Input.is_action_pressed("jump") and character.is_on_floor():
		state_machine.change_state("jumpstate")
		return
		
	# Check for dash input
	if Input.is_action_pressed("dash"):
		state_machine.change_state("dashstate")
		return

func physics_update(delta: float):
	
	if Input.is_action_pressed("dash") and character.has_stamina(character.STAMINA_DASH_COST) :
		state_machine.change_state("dashstate")
		return
		
	# Apply friction or other physics here
	character.velocity.x = move_toward(character.velocity.x, 0, 10.0)
	character.move_and_slide()

func exit():
	#print("Exiting idle state")
	pass
