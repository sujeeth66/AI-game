extends CharState

class_name JumpState

var JUMP_FORCE = -350  # Reduced from -1000
var JUMP_RELEASE_REDUCTION = 0.5  # Reduce velocity when jump is released
var wall_collided = false

func enter():
	animated_sprite.play("jump")
	_update_sprite_direction()
	character.velocity.y = JUMP_FORCE
	#print("jump applied")
	
	
func physics_update(delta):
	# Get input direction with deadzone
	var input_direction = Input.get_axis("move_left", "move_right")
	
	if character.is_on_wall_only():
		wall_collided = true
	if wall_collided == true:
		if not character.is_on_floor():
			character.velocity = Vector2i(0,20)
		else:
			wall_collided = false
			
	# Only update direction if it's different from current direction
	if input_direction != 0 :
		var new_direction = sign(input_direction)
		if new_direction != 0 and new_direction != sign(direction):
			direction = new_direction
	
	GlobalStates.facing_right = direction > 0
	_update_sprite_direction()
	# Apply movement
	if wall_collided:
		character.velocity.x = 0
	else:
		character.velocity.x = direction * 200 * abs(input_direction)  # Scale by input magnitude
	
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
		if Input.is_action_pressed("jump"):
			state_machine.change_state("jumpstate")
		elif input_direction != 0:  
			state_machine.change_state("runstate")
		else:
			state_machine.change_state("idlestate")

func exit():
	animated_sprite.stop()
