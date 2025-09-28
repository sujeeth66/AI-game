extends SlimeState

class_name SlimeInvestigateState

var player = Global.player
var search_duration := 25.0
var search_timer := 0.0
var search_phase := 0
var search_direction := -1
var search_radius := 120  # How far to search around the last known position
var search_origin := Vector2.ZERO
var phase_delay := 6.0  # seconds to wait before next phase
var phase_delay_timer := 0.0
var is_waiting := false
var target : Vector2 = Vector2(0,0)
var direction : int = 1
var offset : int = 1
# Called when the state is entered
func enter() -> void:
	print("[DEBUG] Entering Investigate state")
	animated_sprite.play("run")
	search_timer = search_duration
	search_phase = 0
	search_origin = slime.last_known_player_position

# Called when the state is exited
func exit() -> void:
	animated_sprite.stop()

# Called every frame
func update(_delta: float) -> void:
	if not player :
		state_machine.change_state("slimeidlestate")
		return
		
	search_timer -= _delta
	if search_timer <= 0:
		state_machine.change_state("slimeidlestate")
		return

# Called every physics frame
func physics_update(_delta: float) -> void:
	if slime.has_line_of_sight_to_player() and slime.global_position.distance_to(player.global_position) <= slime.CHASE_RADIUS:
		state_machine.change_state("slimechasestate")
		return

	if search_phase == 0:
		# Move toward the last known player position
		var direction = sign(search_origin.x - slime.global_position.x)
		slime.velocity.x = direction * slime.RUN_SPEED

		if abs(slime.global_position.x - search_origin.x) < 4:
			search_phase = 1
			is_waiting = true
			phase_delay_timer = phase_delay
			slime.velocity.x = 0  # Stop moving during wait
	else:
		if is_waiting:
			if phase_delay_timer <= 4 and phase_delay_timer >= 2:
				animated_sprite.play("idle_special")
			phase_delay_timer -= _delta
			slime.velocity.x = 0  # Stay still while waiting
			if phase_delay_timer <= 0:
				is_waiting = false
		else:
			if search_phase == 1:
				offset = search_direction * search_radius
				target = search_origin + Vector2(offset, slime.global_position.y)
				direction = sign(target.x - slime.global_position.x)
			slime.velocity.x = direction * slime.RUN_SPEED
			#print("next phase:phase ",search_phase,"target : ",target)
			#print("distance :",abs(slime.global_position.x - target.x))
			if abs(slime.global_position.x - target.x) < 4:
				search_direction *= -1
				is_waiting = true
				search_phase += 1
				phase_delay_timer = phase_delay
				slime.velocity.x = 0
				#update variables
				offset = search_direction * search_radius
				target = search_origin + Vector2(offset, slime.global_position.y)
				direction = sign(target.x - slime.global_position.x)
	
	# Handle jumping over obstacles
	if slime.is_on_floor() and slime.is_on_wall():
		slime.velocity.y = -slime.JUMP_VELOCITY 

func take_damage(amount: int) -> void:
	slime.health = max(0, slime.health - amount)
	slime.update_health_bar()
	
	if slime.health <= 0:
		state_machine.change_state("slimedeathstate")
	else:
		state_machine.change_state("slimetakedmgstate")
