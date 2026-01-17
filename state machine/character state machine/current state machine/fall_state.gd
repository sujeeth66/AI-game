extends CharState

class_name FallState

func _ready():
	pass
	
# Virtual methods
func enter() -> void:
	pass
	
func exit() -> void:
	pass
	
func update(delta: float) -> void:
	if character.is_on_floor():
		state_machine.change_state("idlestate")
		
func physics_update(delta: float) -> void:
	var input_direction = Input.get_axis("move_left", "move_right")
	character.velocity.x = input_direction * 200
	character.move_and_slide()

func handle_input(event: InputEvent) -> void:
	pass
	
