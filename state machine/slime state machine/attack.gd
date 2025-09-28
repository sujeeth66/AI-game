extends SlimeState

class_name SlimeAttackState

var attack_done: bool = false
var attack_cooldown: bool = false
var current_animation_playing: String = ""
var timeout_timer: SceneTreeTimer = null

func enter() -> void:
	print("[DEBUG] Entering Attack state")
	if slime.is_dead:
		state_machine.change_state("slimedeathstate")
		return
		
	attack_done = false
	current_animation_playing = "attack"
	animated_sprite.play(current_animation_playing)
	
	# Connect to animation signals
	animated_sprite.animation_finished.connect(_on_animation_finished)
	animated_sprite.frame_changed.connect(_on_frame_changed)
	
	# Safety timeout in case animation gets stuck
	timeout_timer = get_tree().create_timer(1.5)
	timeout_timer.timeout.connect(_on_attack_timeout, CONNECT_ONE_SHOT)

func physics_update(delta : float) -> void:
	slime.velocity.x = 0
	pass

func exit() -> void:
	# Disconnect all signals
	if animated_sprite.frame_changed.is_connected(_on_frame_changed):
		animated_sprite.frame_changed.disconnect(_on_frame_changed)
	if animated_sprite.animation_finished.is_connected(_on_animation_finished):
		animated_sprite.animation_finished.disconnect(_on_animation_finished)
	
	# Cancel the timeout timer
	timeout_timer = null
	
	attack_done = false
	attack_cooldown = false
	current_animation_playing = ""

func _on_frame_changed() -> void:
	#print("[DEBUG] Attack frame changed to: ", animated_sprite.frame)
	if current_animation_playing == "attack" and animated_sprite.frame == 2:  # Assuming frame 2 is the attack frame
		_deal_damage()

func _on_animation_finished() -> void:
	print("[DEBUG] Animation finished for: ", current_animation_playing)
	if current_animation_playing == "attack" and not attack_done:
		_handle_attack_complete()

func _on_attack_timeout() -> void:
	print("[DEBUG] Attack timeout triggered")
	if not attack_done:
		_handle_attack_complete()

func _handle_attack_complete() -> void:
	if attack_done:
		print("[DEBUG] Attack already done, returning")
		return
		
	attack_done = true
	print("[DEBUG] Attack marked as done")
	
	# Make sure we're not in the middle of changing states
	if not is_instance_valid(slime) or slime.is_queued_for_deletion():
		print("[DEBUG] Slime is invalid or queued for deletion")
		return
	
	var player = get_tree().get_first_node_in_group("player")
	if not is_instance_valid(player) or not player.is_inside_tree():
		print("[DEBUG] Player not found or not in tree, changing to Idle")
		state_machine.change_state("slimeidlestate")
		return

	var distance_to_player = slime.global_position.distance_to(player.global_position)
	var can_see_player = slime.has_line_of_sight_to_player()
	print("[DEBUG] Distance to player: ", distance_to_player, ", Can see player: ", can_see_player, ", Attack cooldown: ", attack_cooldown)
	
	if distance_to_player <= slime.ATTACK_RADIUS and can_see_player and not attack_cooldown:
		attack_cooldown = true
		print("[DEBUG] Attack cooldown set to 2 seconds")
		await get_tree().create_timer(2.0).timeout
		attack_cooldown = false
		print("[DEBUG] Attack cooldown expired")
		
		if is_instance_valid(slime) and not slime.is_queued_for_deletion() and not slime.is_dead:
			print("[DEBUG] Changing to Attack state again")
			state_machine.change_state("slimeattackstate")
	elif distance_to_player <= slime.CHASE_RADIUS * 1.5 and can_see_player:
		print("[DEBUG] Changing to Chase state")
		state_machine.change_state("slimechasestate")
	else:
		print("[DEBUG] Changing to Idle state")
		state_machine.change_state("slimeidlestate")

func _deal_damage() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if is_instance_valid(player) and player.has_method("take_damage"):
		if slime.global_position.distance_to(player.global_position) <= slime.ATTACK_RADIUS:
			player.take_damage(slime.damage)

func take_damage(amount: int) -> void:
	if slime.is_dead:
		return
		
	slime.health = max(0, slime.health - amount)
	slime.update_health_bar()
	
	if slime.health <= 0:
		slime.is_dead = true
		state_machine.change_state("slimedeathstate")
	else:
		var hit_tween = slime.create_tween()
		hit_tween.tween_property(animated_sprite, "modulate", Color.RED, 0.1)
		hit_tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.1)
