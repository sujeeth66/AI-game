extends SlimeState

class_name SlimeIdleState

var idle_time: float = 0.0
var next_idle_action_time: float = 2.0

func enter() -> void:
	print("[DEBUG] Entering Idle state")
	animated_sprite.play("idle")
	idle_time = 0.0
	next_idle_action_time = randf_range(1.0, 3.0)

func exit() -> void:
	animated_sprite.stop()

func update(delta: float) -> void:
	idle_time += delta
	
	# Random idle actions
	if idle_time >= next_idle_action_time:
		# Small chance to play a special idle animation
		if randf() < 0.3:
			animated_sprite.play("idle_special")
			await animated_sprite.animation_finished
			animated_sprite.play("idle")
		
		next_idle_action_time = randf_range(2.0, 5.0)
		idle_time = 0.0
	
	# Check for player detection with LOS
	var player = get_tree().get_first_node_in_group("player")
	if player and slime.global_position.distance_to(player.global_position) <  slime.CHASE_RADIUS:
		if slime.has_line_of_sight_to_player():
			state_machine.change_state("slimealertstate")

func physics_update(delta: float) -> void:
	if not slime.velocity.x == 0 :
		slime.velocity.x = 0

func take_damage(amount: int) -> void:
	slime.health = max(0, slime.health - amount)
	slime.update_health_bar()
	
	if slime.health <= 0:
		state_machine.change_state("slimedeathstate")
	else:
		state_machine.change_state("slimetakedmgstate")
