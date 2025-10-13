extends CharState

class_name RunState

const RUN_SPEED = 200.0
const ACCELERATION = 20.0
const DECELERATION = 40.0

func enter():
	animated_sprite.play("run")
	# Ensure the sprite's facing direction is correct
	_update_sprite_direction()
	#print("Entered run state")

func handle_input(event: InputEvent):
	if Input.is_action_pressed("jump") and character.is_on_floor() :
		state_machine.change_state("jumpstate")
		return
		
func physics_update(delta: float):
	# Don't process movement if we're in the middle of a dash or fireball is active
	if (state_machine.current_state is DashState and !state_machine.current_state.is_in_cooldown) or \
	   GlobalStates.is_fireball_active():
		print(GlobalStates.is_fireball_active())
		# Apply friction or other physics here
		character.velocity.x = move_toward(character.velocity.x, 0, 10.0)
		animated_sprite.play("default")
		return
	else:
		animated_sprite.play("run")
	
	# Get input direction
	var input_direction = Input.get_axis("move_left", "move_right")
	
	# Update facing direction if there's input
	if input_direction != 0:
		var new_direction = sign(input_direction)
		if new_direction != 0 and new_direction != sign(direction):
			direction = new_direction
			GlobalStates.facing_right = direction > 0
			_update_sprite_direction()
	
	# Handle movement
	var target_speed = input_direction * RUN_SPEED
	var acceleration = ACCELERATION if sign(character.velocity.x) == sign(target_speed) else DECELERATION
	
	character.velocity.x = move_toward(character.velocity.x, target_speed, acceleration * delta * 60)
	character.move_and_slide()
	
	# Check for dash input at the end of physics update
	if Input.is_action_pressed("dash") and character.has_stamina(character.STAMINA_DASH_COST) :
		state_machine.change_state("dashstate")
		return
	
	# Transition to idle if not moving
	if input_direction == 0 :
		state_machine.change_state("idlestate")

func exit():
	animated_sprite.stop()
	#print("Exiting run state")
