extends CharState

class_name JumpState

var JUMP_FORCE = -250  # Reduced from -1000
var JUMP_RELEASE_REDUCTION = 0.5  # Reduce velocity when jump is released

func enter():
	animated_sprite.play("jump")
	_update_sprite_direction()
	character.velocity.y = JUMP_FORCE
	#print("jump applied")
	
	
func physics_update(delta):
	# Get input direction with deadzone
	var input_direction = Input.get_axis("move_left", "move_right")
	
	# Only update direction if it's different from current direction
	if input_direction != 0:
		var new_direction = sign(input_direction)
		if new_direction != 0 and new_direction != sign(direction):
			direction = new_direction
			GlobalStates.facing_right = direction > 0
			_update_sprite_direction()
	
	# Apply movement
	character.velocity.x = direction * 100 * abs(input_direction)  # Scale by input magnitude
	
	# Variable jump height - if jump button is released early, reduce upward velocity
	if not Input.is_action_pressed("jump") and character.velocity.y < 0:
		character.velocity.y *= JUMP_RELEASE_REDUCTION
	
	character.move_and_slide()
	
	# Only allow dashing if we have enough stamina
	if Input.is_action_just_pressed("dash") and character.has_stamina(character.STAMINA_DASH_COST):
		state_machine.change_state("dashstate")
		return
	
	# Check if landed
	if character.is_on_floor():
		if input_direction != 0:  
			state_machine.change_state("runstate")
		else:
			state_machine.change_state("idlestate")

func exit():
	animated_sprite.stop()
