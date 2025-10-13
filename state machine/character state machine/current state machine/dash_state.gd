extends CharState

class_name DashState

const DASH_SPEED := 600.0
const DASH_DURATION := 0.2
const DASH_COOLDOWN := 0.2

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
	
	# Only change direction if there's significant input
	var input_direction = Input.get_axis("move_left", "move_right")
	if abs(input_direction) > 0.1:
		direction = sign(input_direction)
		GlobalStates.facing_right = direction > 0
		_update_sprite_direction()
	
	animated_sprite.play("dash")
	character.velocity.x = DASH_SPEED * (1.0 if GlobalStates.facing_right else -1.0)

func physics_update(delta):
	if dash_timer > 0:
		dash_timer -= delta
		character.move_and_slide()
		return
	
	# Start cooldown
	is_in_cooldown = true
	
	# Cooldown before allowing state transition
	cooldown_timer += delta
	if cooldown_timer < DASH_COOLDOWN:
		character.velocity.x = move_toward(character.velocity.x, 0, 50.0)
		character.move_and_slide()
		return
	
	# Dash complete, transition to appropriate state
	var input_direction = Input.get_axis("move_left", "move_right")
	if abs(input_direction) > 0.1:
		state_machine.change_state("runstate")
	else:
		state_machine.change_state("idlestate")

func exit():
	animated_sprite.stop()
