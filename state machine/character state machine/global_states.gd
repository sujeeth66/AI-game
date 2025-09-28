extends Node

var facing_right : bool = true
var fireball_active : bool
var knockback_active : bool = false
var knockback_velocity : float = 0.0
var knockback_duration : float = 0.0

# Function to safely set the fireball state
func set_fireball_active(active: bool) -> void:
	fireball_active = active
	print("Fireball state changed to: ", active)

# Function to check if fireball is active
func is_fireball_active() -> bool:
	return fireball_active

# Function to apply knockback
func apply_knockback(velocity: float, duration: float) -> void:
	knockback_active = true
	knockback_velocity = velocity
	knockback_duration = duration
	print("Knockback applied: velocity=", velocity, " duration=", duration)

# Function to update knockback (called by movement state machine)
func update_knockback(delta: float) -> float:
	if not knockback_active:
		return 0.0
	
	if knockback_duration > 0:
		knockback_duration -= delta
		if knockback_duration <= 0:
			knockback_active = false
			knockback_velocity = 0.0
			print("Knockback ended")
			return 0.0
	
	return knockback_velocity

# Function to check if knockback is active
func is_knockback_active() -> bool:
	return knockback_active
