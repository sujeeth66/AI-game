extends SlimeState

class_name SlimeTakeDmgState

var damage_timer: float = 0.0
const DAMAGE_STUN_TIME: float = 0.3  # How long to stay in damage state

func enter() -> void:
	print("[DEBUG] Entering Take Damage state")
	animated_sprite.play("take_damage")
	damage_timer = 0.0
	
	# Visual feedback
	var tween = slime.create_tween()
	tween.tween_property(animated_sprite, "modulate", Color.RED, 0.05)
	tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.25)

func exit() -> void:
	animated_sprite.stop()

func update(delta: float) -> void:
	damage_timer += delta
	if damage_timer >= DAMAGE_STUN_TIME:
		# Decide next state based on player position
		var player = get_tree().get_first_node_in_group("player")
		if not player:
			state_machine.change_state("slimeidlestate")
			return
			
		var distance = slime.global_position.distance_to(player.global_position)
		if distance <= slime.ATTACK_RADIUS and slime.has_line_of_sight_to_player():
			state_machine.change_state("slimeattackstate")
		elif distance <= slime.CHASE_RADIUS and slime.has_line_of_sight_to_player():
			state_machine.change_state("slimechasestate")
		else:
			state_machine.change_state("slimeidlestate")

func take_damage(amount: int) -> void:
	# Stack damage but don't reset the timer
	slime.health = max(0, slime.health - amount)
	slime.update_health_bar()
	
	if slime.health <= 0:
		state_machine.change_state("slimedeathstate")
