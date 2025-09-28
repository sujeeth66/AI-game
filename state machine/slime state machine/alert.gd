extends SlimeState

class_name SlimeAlertState

var alert_time: float = 0.0
var player = Global.player

func enter() -> void:
	print("[DEBUG] Entering Alert state")
	animated_sprite.play("alert")

func exit() -> void:
	animated_sprite.stop()

func update(delta: float) -> void:
	alert_time += delta
	
	# After alert animation, decide next action
	if alert_time >= 0.5:  # Adjust time based on your alert animation
		if player and slime.has_line_of_sight_to_player():
			if slime.global_position.distance_to(player.global_position) <= slime.ATTACK_RADIUS:
				state_machine.change_state("slimeattackstate")
			elif slime.global_position.distance_to(player.global_position) <= slime.CHASE_RADIUS:
				state_machine.change_state("slimechasestate")
		else:
			state_machine.change_state("slimeidlestate")

func take_damage(amount: int) -> void:
	slime.health = max(0, slime.health - amount)
	slime.update_health_bar()
	
	if slime.health <= 0:
		state_machine.change_state("slimedeathstate")
	else:
		state_machine.change_state("slimetakedmgstate")
