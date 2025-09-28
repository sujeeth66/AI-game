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

# Add movement constants
const MOVEMENT_SPEED = 300.0
const AIR_MOVEMENT_SPEED = 250.0
const FRICTION = 100.0

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
	# Apply gravity first
	if not character.is_on_floor():
		character.velocity.y = min(character.velocity.y + GRAVITY * delta, MAX_FALL_SPEED)
	
	# Handle knockback (overrides all other horizontal movement)
	var knockback_vel = GlobalStates.update_knockback(delta)
	if GlobalStates.is_knockback_active():
		character.velocity.x = knockback_vel
	else:
		# Only allow state physics updates if knockback is not active
		if current_state:
			current_state.physics_update(delta)
	
	character.move_and_slide()
	
func _input(event: InputEvent) -> void:
	if current_state:
		current_state.handle_input(event)
	
func can_transition_to(new_state: String) -> bool:
	match new_state:
		"dashstate":
			return character.has_stamina(character.STAMINA_DASH_COST) and not current_state.is_in_cooldown if current_state.has_method("is_in_cooldown") else true
		"jumpstate":
			return character.is_on_floor()
		"runstate":
			return Global.can_move and not GlobalStates.is_fireball_active() and not GlobalStates.is_knockback_active()
		_:
			return true

func change_state(new_state_name: String) -> void:
	if not can_transition_to(new_state_name):
		return
	
	if not states.has(new_state_name):
		print("CharState not found: ", new_state_name)
		return
	
	# Exit current state
	if current_state:
		current_state.exit()
	
	# Change state
	current_state = states.get(new_state_name.to_lower())
	
	# Enter new state
	if current_state:
		current_state.enter()
