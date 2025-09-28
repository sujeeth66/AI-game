extends SlimeState

class_name SlimeChaseState

var investigating_last_known: bool = false
var player = Global.player
var investigation_timer: float = 0.0
const MAX_INVESTIGATION_TIME: float = 2.0

func enter() -> void:
	print("[DEBUG] Entering Chase state")
	animated_sprite.play("run")

func update(_delta: float) -> void:
	# If player is too far away, return to idle
	if not player or slime.global_position.distance_to(player.global_position) > slime.CHASE_RADIUS + 700 :
		state_machine.change_state("slimeidlestate")
		return
	
	# If we can see the player, update last known position
	if slime.has_line_of_sight_to_player():
		slime.last_known_player_position = player.global_position
		investigating_last_known = false
	# If we can't see the player and we're not already investigating
	elif not investigating_last_known:
		#slime.last_known_player_position = player.global_position
		investigating_last_known = true

func physics_update(delta: float) -> void:
	
	var player_position = player.global_position
	var direction = sign(player_position.x - slime.global_position.x)
	
	if investigating_last_known:
			state_machine.change_state("slimeinvestigatestate")
			return
			
	# Calculate movement
	slime.velocity.x = direction * slime.RUN_SPEED
	
	# Handle jumping over obstacles
	if slime.is_on_floor():
		if slime.is_on_wall():
			slime.velocity.y = -slime.JUMP_VELOCITY 

	# Check if we can attack the player
	if slime.global_position.distance_to(player_position) <= slime.ATTACK_RADIUS and slime.has_line_of_sight_to_player():
		state_machine.change_state("slimeattackstate")
		return
	
	# Update sprite direction
	if abs(direction) > 0.1:  # Only update direction if we're actually moving
		slime.animated_sprite.flip_h = direction < 0

func exit():
	animated_sprite.stop()

func take_damage(amount: int) -> void:
	slime.health = max(0, slime.health - amount)
	slime.update_health_bar()
	
	if slime.health <= 0:
		state_machine.change_state("slimedeathstate")
	else:
		state_machine.change_state("slimetakedmgstate")
