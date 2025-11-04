extends Node2D

# The scene to spawn (set this in the editor)
@export var slime_scene: PackedScene

# Spawn key (default is 'S' key)
@export var spawn_key: Key = KEY_S

# Cooldown between spawns in seconds
@export var spawn_cooldown: float = 1.0
var can_spawn: bool = true

func _input(event: InputEvent) -> void:
	# Check if the spawn key is pressed and we can spawn
	if event.is_action_pressed("ui_accept") and can_spawn:
		spawn_slime()

func spawn_slime() -> void:
	if not slime_scene:
		push_error("No slime scene assigned to spawner!")
		return
	
	# Create a new instance of the slime
	var new_slime = slime_scene.instantiate()
	
	# Set the slime's position to the spawner's position
	new_slime.global_position = global_position
	new_slime.linked_chest_id = "chest_1"  # Or get this from room data
	# Add the slime to the scene
	get_tree().current_scene.add_child(new_slime)
	
	# Start cooldown
	can_spawn = false
	await get_tree().create_timer(spawn_cooldown).timeout
	can_spawn = true
	
	#print("Spawned new slime at position: ", global_position)
