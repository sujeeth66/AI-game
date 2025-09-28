extends SlimeState

class_name SlimeDeathState

func enter() -> void:
	print("[DEBUG] Entering Death state")
	if slime.health <= 0:
		animated_sprite.play("die")
		
		# Give experience to player
		var player = get_tree().get_first_node_in_group("player")
		if player and player.has_method("gain_experience"):
			player.gain_experience(slime.EXPERIENCE_REWARD)
		
		# Wait for death animation and then remove from scene
		await animated_sprite.animation_finished
		slime.queue_free()

func exit() -> void:
	animated_sprite.stop()
