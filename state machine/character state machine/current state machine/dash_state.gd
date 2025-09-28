extends CharState

class_name DashState

const DASH_SPEED := 800.0
const DASH_DURATION := 0.3  # Increased for better animation visibility
const DASH_COOLDOWN := 0.1  # Reduced cooldown

var dash_timer := 0.0
var cooldown_timer := 0.0
var is_in_cooldown := false

func enter():
	# Use stamina for the dash
	character.use_stamina(character.STAMINA_DASH_COST)
	if character.stamina_bar:
		character.stamina_bar.stamina = character.stamina
	
	dash_timer = DASH_DURATION
	cooldown_timer = 0.0
	is_in_cooldown = false
	
	# Use helper function for direction
	var input_direction = get_movement_input()
	if abs(input_direction) > 0.1:
		update_direction(input_direction)
	
	# Force play dash animation
	play_animation("dash", true)  # Force = true to ensure it plays
	character.velocity.x = DASH_SPEED * (1.0 if GlobalStates.facing_right else -1.0)

func physics_update(delta):
	if dash_timer > 0:
		dash_timer -= delta
		return
	
	# Start cooldown phase
	if not is_in_cooldown:
		is_in_cooldown = true
		# Transition to idle state instead of changing animation
		state_machine.change_state("idlestate")
		return
	
	# Cooldown before allowing state transition
	cooldown_timer += delta
	if cooldown_timer < DASH_COOLDOWN:
		character.velocity.x = move_toward(character.velocity.x, 0, state_machine.FRICTION * 5)
		return
	
	# Dash complete, transition to idle state
	state_machine.change_state("idlestate")

func exit():
	animated_sprite.stop()

func handle_input(event: InputEvent):
	# Prevent other inputs during dash - this is correct for your game design
	pass
