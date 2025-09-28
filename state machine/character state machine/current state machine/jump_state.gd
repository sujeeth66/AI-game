extends CharState

class_name JumpState

var JUMP_FORCE = -300  # Reduced from -1000
var JUMP_RELEASE_REDUCTION = 0.5  # Reduce velocity when jump is released
var jump_released = false  # Track if jump button was released
var has_left_ground = false  # Track if character has left the ground

func enter():
	animated_sprite.play("jump")
	_update_sprite_direction()
	character.velocity.y = JUMP_FORCE
	jump_released = false  # Reset jump release tracking
	has_left_ground = false  # Reset ground leaving tracking

func physics_update(delta):
	var input_direction = get_movement_input()
	
	# Handle air movement - always update based on current input
	if input_direction != 0:
		update_direction(input_direction)
		character.velocity.x = input_direction * state_machine.AIR_MOVEMENT_SPEED
	else:
		# No input = stop horizontal movement in air
		character.velocity.x = 0
	
	# Track when character leaves the ground
	if not character.is_on_floor() and not has_left_ground:
		has_left_ground = true
	
	# Reset jump_released when jump button is pressed again
	if Input.is_action_pressed("jump"):
		jump_released = false
	
	# Variable jump height - reduce velocity when jump button is released during upward motion
	if not Input.is_action_pressed("jump") and not jump_released and character.velocity.y < 0:
		character.velocity.y *= JUMP_RELEASE_REDUCTION
		jump_released = true
	
	# Check if landed - only check after character has left the ground
	if character.is_on_floor() and has_left_ground:
		if abs(input_direction) > 0.1:
			state_machine.change_state("runstate")
		else:
			state_machine.change_state("idlestate")

func exit():
	animated_sprite.stop()

func handle_input(event: InputEvent):
	if is_dash_pressed():
		state_machine.change_state("dashstate")
		
