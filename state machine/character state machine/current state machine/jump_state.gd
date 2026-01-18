extends CharState

class_name JumpState

var JUMP_FORCE = -350  # Reduced from -1000
var JUMP_RELEASE_REDUCTION = 0.5  # Reduce velocity when jump is released

func enter():
	print("entered jump state")
	animated_sprite.play("jump")
	_update_sprite_direction()
	character.velocity.y += JUMP_FORCE

func handle_input(event: InputEvent) -> void:
	var input_direction = Input.get_axis("move_left", "move_right")
	var is_touching_wall = character.wall_ray_cast.is_colliding()
	
	# Wall detection
	if not character.is_on_floor() and character.velocity.y > -10:
		if is_touching_wall :
			print("wall collided")
			state_machine.change_state("wallslidestate")
			return
		else:
			state_machine.change_state("fallstate")
			return
	# Dash
	if Input.is_action_just_pressed("dash") and character.has_stamina(character.STAMINA_DASH_COST):
		state_machine.change_state("dashstate")
		return
			
func physics_update(delta):
	var input_direction = Input.get_axis("move_left", "move_right")

	# Regular horizontal movement
	if input_direction != 0:
		direction = sign(input_direction)
		GlobalStates.facing_right = direction > 0
		_update_sprite_direction()
		character.velocity.x = direction * 200
	else:
		character.velocity.x = 0

	# Variable jump height
	#if not Input.is_action_pressed("jump") and character.velocity.y < 0:
		#character.velocity.y *= JUMP_RELEASE_REDUCTION

	# Landing
	if character.is_on_floor() and !Input.is_action_pressed("jump"):
		if input_direction != 0:
			state_machine.change_state("runstate")
			return
		else:
			state_machine.change_state("idlestate")
			return
	
func exit():
	animated_sprite.stop()
