extends CharState

class_name WallSlideState

var wall_jump_timer = 0
var wall_jump_cooldown = 0.4

func enter() -> void:
	animated_sprite.play("jump")
	_update_sprite_direction()
	print("wall_slide_entered")
	
func exit() -> void:
	animated_sprite.stop()
	
func update(delta: float) -> void:
	wall_jump_timer += delta
	if Input.is_action_just_pressed("jump") :
		wall_jump_timer = 0
		state_machine.change_state("jumpstate")
		return
		
	var input_direction = Input.get_axis("move_left", "move_right")
	
	if input_direction != 0:
		GlobalStates.facing_right = input_direction > 0 
		_update_sprite_direction()
		pass
	pass
		
func physics_update(delta: float) -> void:
	if character.wall_ray_cast.is_colliding():
		var collider = character.wall_ray_cast.get_collider()
		#print("[wall_slide_state]",collider.name)
	character.velocity.y = 25
	
	if character.is_on_floor():
		state_machine.change_state("idlestate")
		return


func handle_input(event: InputEvent) -> void:
	pass
