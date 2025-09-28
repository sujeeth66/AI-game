extends Node

class_name SlimeStateMachine

@export var initial_state: NodePath
var current_state: SlimeState = null
var states: Dictionary = {}
@onready var slime = get_parent()

func _ready() -> void:
	# Wait for owner to be ready
	await owner.ready
	

	# Initialize all states
	for child in get_children():
		if child is SlimeState:
			states[child.name.to_lower()] = child
			child.state_machine = self
			child.slime = owner
			child.animated_sprite = owner.get_node("AnimatedSprite2D")
	
	# Set initial state
	if initial_state:
		var initial_state_name = get_node(initial_state).name.to_lower()
		change_state(initial_state_name)

func _process(delta: float) -> void:
	
	if current_state:
		current_state.update(delta)

func _physics_process(delta: float) -> void:
		# Apply gravity first
	if not slime.is_on_floor():
		slime.velocity.y = slime.velocity.y + slime.GRAVITY * delta
	
	if current_state:
		current_state.physics_update(delta)
		
	slime.move_and_slide()

func change_state(new_state_name) -> void:
	if not new_state_name:
		push_error("State %s not found!" % new_state_name)
		return
	
	# Don't allow state changes if we're in the death state
	if current_state and current_state.get_script() == preload("res://state machine/slime state machine/death.gd"):
		return
		
	# Don't change to the same state
	#commented out so that attack state can be called recursively
	#if current_state and current_state.name.to_lower() == new_state_name.to_lower():
		#return
	
	# Get the new state before making any changes
	var new_state = states.get(new_state_name.to_lower())
	if not new_state:
		push_error("State %s not found in states!" % new_state_name)
		return
	
	print("[DEBUG] State change requested: from ", current_state, " to ", new_state)
	
	# Exit current state
	if current_state:
		print("[DEBUG] Exiting state: ", current_state)
		current_state.exit()
	
	# Change to new state
	current_state = new_state
	print("[DEBUG] Entering state: ", current_state)
	current_state.enter()

func take_damage(amount: int) -> void:
	if current_state:
		current_state.take_damage(amount)
