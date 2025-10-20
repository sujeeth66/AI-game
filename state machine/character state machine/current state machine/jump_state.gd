extends CharState

class_name JumpState

var JUMP_FORCE = -350  # Reduced from -1000
var JUMP_RELEASE_REDUCTION = 0.5  # Reduce velocity when jump is released
var wall_collided = false
var can_wall_jump = false
var jump_limit = 7
var wall_jump_timer = 0
var wall_jump_cooldown = 0.8
var drag_timer = 0
var drag_cooldown = 2.0

func enter():
	animated_sprite.play("jump")
	_update_sprite_direction()
	character.velocity.y = JUMP_FORCE
	#print("jump applied")
	wall_collided = false
	wall_jump_timer = 0
	drag_timer = 0
	
	
func physics_update(delta):
	# Get input direction with deadzone
	var input_direction = Input.get_axis("move_left", "move_right")
	
	if GlobalStates.is_wall_jumping and drag_timer < drag_cooldown:
		GlobalStates.is_wall_jumping = false
		
	drag_timer += delta
	
	if character.is_on_wall_only():
		wall_collided = true
		
	if wall_collided == true:
		if not character.is_on_floor() :
			if not GlobalStates.is_wall_jumping :
				character.velocity = Vector2i(0,20)
			else:
				character.velocity.x = direction * 200 * abs(input_direction)
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
	if wall_collided :
		if not GlobalStates.is_wall_jumping:
			character.velocity.x = 0
		else:
			pass
		can_wall_jump = true
	else:
		can_wall_jump = false
		character.velocity.x = direction * 200 * abs(input_direction)  # Scale by input magnitude
	
	# Variable jump height - if jump button is released early, reduce upward velocity
	if not Input.is_action_pressed("jump") and character.velocity.y < 0:
		character.velocity.y *= JUMP_RELEASE_REDUCTION
	
	# Only allow dashing if we have enough stamina
	if Input.is_action_just_pressed("dash") and character.has_stamina(character.STAMINA_DASH_COST):
		state_machine.change_state("dashstate")
		return
	#print(wall_jump_timer)
	if  wall_jump_timer > wall_jump_cooldown :
		if can_wall_jump and GlobalStates.jump_count < jump_limit and Input.is_action_pressed("jump"):
			GlobalStates.is_wall_jumping = true
			GlobalStates.jump_count += 1
			state_machine.change_state("jumpstate")
	wall_jump_timer += delta
	
	# Check if landed
	if character.is_on_floor():
		GlobalStates.jump_count = 0
		if Input.is_action_pressed("jump"):
			state_machine.change_state("jumpstate")
		elif input_direction != 0:  
			state_machine.change_state("runstate")
		else:
			state_machine.change_state("idlestate")
	
	character.move_and_slide()
	
func exit():
	animated_sprite.stop()
