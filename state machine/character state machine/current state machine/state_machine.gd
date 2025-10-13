extends Node
#current
class_name CharStateMachine

@onready var character = get_parent()
@export var initial_state: CharState
var current_state: CharState
var states: Dictionary = {}

# Physics properties
var GRAVITY = 800
var MAX_FALL_SPEED = 1000

func _ready() -> void:
	# Register all states
	for child in get_children():
		if child is CharState:
			var state_name = child.name.to_lower()  # Keep the full state name (e.g., 'idlestate')
			states[state_name] = child
			child.state_machine = self
	
	# Set initial state
	if initial_state:
		change_state(initial_state.name.to_lower())
	
func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)
	
func _physics_process(delta: float) -> void:
	
	# Apply gravity
	if not character.is_on_floor():
		character.velocity.y = min(character.velocity.y + GRAVITY * delta, MAX_FALL_SPEED)
		
	if current_state:
		current_state.physics_update(delta)
	
func _input(event: InputEvent) -> void:
	if current_state:
		current_state.handle_input(event)
	
func change_state(new_state_name: String) -> void:
	# Don't allow state changes if fireball is active
	if GlobalStates.is_fireball_active():
		return
		
	if not states.has(new_state_name):
		print("CharState not found: ", new_state_name)
		return
	
	# Exit current state
	if current_state:
		current_state.exit()
	
	# Change state
	#print("Changing state from %s to %s" % [current_state.name if current_state else "none", new_state_name])
	current_state = states.get(new_state_name.to_lower())
	
	# Enter new state
	if current_state:
		current_state.enter()
