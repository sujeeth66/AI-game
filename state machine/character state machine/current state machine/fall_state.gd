extends CharState

class_name FallState

func _ready():
	pass
	
# Virtual methods
func enter() -> void:
	print("entered fall state")
	animated_sprite.play("idle")
	
func exit() -> void:
	animated_sprite.stop()
	
func update(delta: float) -> void:
	var input_direction = Input.get_axis("move_left", "move_right")
			
	if character.is_on_floor():
		if Input.is_action_pressed("jump"):
			state_machine.change_state("jumpstate")
		elif input_direction != 0:
			state_machine.change_state("runstate")
			return
		else:
			state_machine.change_state("idlestate")
			return
	elif character.wall_ray_cast.is_colliding() and character.velocity.y > 0:
		state_machine.change_state("wallslidestate")
		return
		
func physics_update(delta: float) -> void:
	var input_direction = Input.get_axis("move_left", "move_right")
	# Update facing direction if there's input
	if input_direction != 0:
		var new_direction = sign(input_direction)
		if new_direction != 0 and new_direction != sign(direction):
			direction = new_direction
			GlobalStates.facing_right = direction > 0
			_update_sprite_direction()
			character.velocity.x = direction * 100
	character.move_and_slide()

func handle_input(event: InputEvent) -> void:
	pass
	
