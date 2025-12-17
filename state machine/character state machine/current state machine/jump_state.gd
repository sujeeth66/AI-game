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
	var input_direction = Input.get_axis("move_left", "move_right")
	var is_touching_wall = character.is_on_wall_only()
	var is_jumping = Input.is_action_pressed("jump")
	var is_jump_just_pressed = Input.is_action_just_pressed("jump")

	# Update drag timer
	if GlobalStates.is_wall_jumping and drag_timer < drag_cooldown:
		GlobalStates.is_wall_jumping = false
	drag_timer += delta

	# Wall detection
	if is_touching_wall and not character.is_on_floor():
		wall_collided = true
		can_wall_jump = true
	else:
		wall_collided = false
		can_wall_jump = false

	# Handle wall jump
	if can_wall_jump and is_jump_just_pressed and wall_jump_timer > wall_jump_cooldown:
		GlobalStates.is_wall_jumping = true
		GlobalStates.jump_count += 1
		wall_jump_timer = 0

		# Flip direction away from wall
		var wall_dir = character.get_last_slide_collision().normal.x
		direction = -sign(wall_dir)

		# Apply wall jump velocity
		character.velocity.x = direction * 250
		character.velocity.y = JUMP_FORCE * 0.8  # Slightly weaker than ground jump

		animated_sprite.play("jump")
		_update_sprite_direction()
		return  # Skip rest of update to preserve jump impulse

	# Regular horizontal movement
	if input_direction != 0:
		direction = sign(input_direction)
		character.velocity.x = direction * 200
	else:
		character.velocity.x = 0

	# Variable jump height
	if not is_jumping and character.velocity.y < 0:
		character.velocity.y *= JUMP_RELEASE_REDUCTION

	# Dash
	if Input.is_action_just_pressed("dash") and character.has_stamina(character.STAMINA_DASH_COST):
		state_machine.change_state("dashstate")
		return

	# Landing
	if character.is_on_floor():
		GlobalStates.jump_count = 0
		if is_jumping:
			state_machine.change_state("jumpstate")
		elif input_direction != 0:
			state_machine.change_state("runstate")
		else:
			state_machine.change_state("idlestate")

	# Apply gravity and movement
	character.move_and_slide()
	wall_jump_timer += delta
	
func exit():
	animated_sprite.stop()
