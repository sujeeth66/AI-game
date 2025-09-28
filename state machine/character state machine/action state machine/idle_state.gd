extends AtkState

class_name AtkIdleState

var attack_held = false
var fireball_held = false

func enter():
	attack_held = Input.is_action_pressed("attack")
	# Reset any attack-specific state here
	if attack_animations:
		attack_animations.visible = false

func handle_input(event: InputEvent):
	# Check for attack input with cooldown
	if event.is_action("attack"):
		attack_held = event.pressed
		if event.pressed and can_attack():  # Only trigger on press, not release
			state_machine.change_state("attackstate")
		
	if event.is_action("atk2") and event.pressed and can_attack():  # Only trigger on press, not release
		state_machine.change_state("fireballstate")

func update(delta: float):
	# Check for attack input with cooldown, including held inputs
	if attack_held and can_attack():
		state_machine.change_state("attackstate")

func exit():
	pass
