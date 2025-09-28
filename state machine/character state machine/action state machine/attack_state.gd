extends AtkState

class_name AttackState

@onready var slash_area: Area2D = get_parent().get_parent().get_node("slash_area")

var combo_timer = 0
var current_combo = 0
var is_slashing
var slash_timer : float = 0.0
var attack_held = false
var frame_delay_timer = 0.0
var overlaps_checked = false

func enter() -> void:
	if is_slashing:
		return
	
	#change slash_area position according to the direction
	slash_area.position = Vector2(0,0) if GlobalStates.facing_right else Vector2(-state_machine.SLASH_AREA_OFFSET_X,0)
	
	update_attack_time()
	direction = Input.get_axis("move_left", "move_right")
	var facing_right = direction > 0  # Default to right if direction is 0
	
	# Start a new combo if enough time has passed since last attack
	if combo_timer <= 0 or current_combo >= state_machine.MAX_COMBO_COUNT:
		current_combo = 0
		
	current_combo += 1
	combo_timer = state_machine.COMBO_WINDOW
	is_slashing = true
	slash_timer = state_machine.SLASH_COOLDOWN
	attack_held = Input.is_action_pressed("attack")
	frame_delay_timer = state_machine.FRAME_DELAY
	overlaps_checked = false
	
	# Enable monitoring before checking for overlaps
	slash_area.monitoring = true
	
	# Play the appropriate combo animation
	var anim_name = "slash" + str(min(current_combo, state_machine.MAX_COMBO_COUNT))
	play_attack_animation(anim_name)
			
func exit() -> void:
	update_attack_time()
	is_slashing = false
	slash_area.monitoring = false
	
func update(delta: float) -> void:
	# Handle frame delay for area overlap checking
	if frame_delay_timer > 0 and not overlaps_checked:
		frame_delay_timer -= delta
		if frame_delay_timer <= 0:
			_check_overlaps()
			overlaps_checked = true
	
	if is_slashing and is_animation_finished():
		_on_attack_animation_finished()
	
	if combo_timer > 0:
		combo_timer -= delta
	
	# Handle attack cooldown for continuous attacks
	if state_machine.ATTACK_COOLDOWN > 0:
		# This will be handled by the individual states
		pass
		
func _check_overlaps():
	# Now check for overlapping bodies/areas
	var overlapping_bodies = slash_area.get_overlapping_bodies()
	var overlapping_areas = slash_area.get_overlapping_areas()
	
	for body in overlapping_bodies:
		_damage_body(body)
	
	for area in overlapping_areas:
		_damage_body(area.get_parent())
		
func _on_attack_animation_finished() -> void:
	is_slashing = false
	slash_area.monitoring = false
	stop_attack_animation()
	change_to_idle()
		
func physics_update(delta: float) -> void:
	if not is_slashing:
		change_to_idle()

func handle_input(event: InputEvent):
	if event.is_action("attack"):
		attack_held = event.pressed

func _damage_body(body: Node2D) -> void:
	if body.has_method("take_damage"):
		var damage = state_machine.BASE_DAMAGE + (state_machine.COMBO_DAMAGE_MULTIPLIER * current_combo)
		body.take_damage(damage)
