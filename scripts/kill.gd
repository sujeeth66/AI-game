extends Area2D

@onready var timer: Timer = $Timer

# Track if we're currently processing a death to prevent multiple triggers
var is_processing_death: bool = false

func _on_body_entered(body: Node) -> void:
	# Only process if we have a valid body with die method and not already processing a death
	if body.has_method("die") and not is_processing_death and not body.is_respawning:
		print("Killzone: Player entered killzone")
		is_processing_death = true
		

		
		# Mark that this is a killzone death and trigger death
		body.is_dying_from_killzone = true
		
		# Ensure the player's position is updated before respawning
		await get_tree().process_frame
		body.die()
		
		# Reset the flag after a short delay to prevent immediate retriggering
		await get_tree().create_timer(1.0).timeout
		is_processing_death = false
