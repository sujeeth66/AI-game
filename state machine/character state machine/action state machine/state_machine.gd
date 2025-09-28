extends Node
#current
class_name AtkStateMachine

@onready var slash_area: Area2D = get_parent().get_node("slash_area")
@onready var character = get_parent()
@export var initial_state: AtkState
var current_state: AtkState
var states: Dictionary = {}

# ===== ATTACK CONSTANTS =====
const ATTACK_COOLDOWN := 0.3
const ATTACK_REPEAT_DELAY := 0.3
const SLASH_COOLDOWN := 0.3
const FRAME_DELAY := 0.016  # One frame at 60fps

# ===== COMBO CONSTANTS =====
const MAX_COMBO_COUNT := 3
const COMBO_WINDOW := 0.8

# ===== FIREBALL CONSTANTS =====
const FIREBALL_COOLDOWN := 0.01
const MANA_COST := 25.0
const FIREBALL_STOP_DURATION := 0.5
const KNOCKBACK_FORCE := 200.0
const KNOCKBACK_DURATION := 0.2
const FIREBALL_SPAWN_DISTANCE := 20
const PLAYER_BASE_DAMAGE := 20

# ===== ANIMATION CONSTANTS =====
const ANIMATION_OFFSET_X := 18
const SLASH_AREA_OFFSET_X := 38

# ===== DAMAGE CONSTANTS =====
const BASE_DAMAGE := 10
const COMBO_DAMAGE_MULTIPLIER := 5
const FIREBALL_DAMAGE_MULTIPLIER := 1.15

# State transition validation
func can_transition_to(state_name: String) -> bool:
	match state_name:
		"attackstate":
			return not GlobalStates.is_fireball_active()
		"fireballstate":
			return not GlobalStates.is_fireball_active()
		"atkidlestate":
			return true
		_:
			return true

func _ready() -> void:
	# Register all states
	for child in get_children():
		if child is AtkState:
			var state_name = child.name.to_lower()
			states[state_name] = child
			child.state_machine = self
	
	# Set initial state
	if initial_state:
		change_state(initial_state.name.to_lower())
	
func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)
	
func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)
	
func _input(event: InputEvent) -> void:
	if current_state:
		current_state.handle_input(event)
	
func change_state(new_state_name: String) -> void:
	if not states.has(new_state_name):
		return
	
	# Validate transition
	if not can_transition_to(new_state_name):
		return
	
	# Exit current state
	if current_state:
		current_state.exit()
	
	# Change state
	current_state = states.get(new_state_name.to_lower())
	
	# Enter new state
	if current_state:
		current_state.enter()
