extends Camera2D

const PAN_SPEED := 600



func _process(delta: float) -> void:
	var input := Vector2.ZERO
	#print("📸 Camera processing")  # This should show in output
	# Arrow keys and WASD movement
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		input.x += 1
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		input.x -= 1
	if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
		input.y += 1
	if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
		input.y -= 1

	set_global_position(global_position + input.normalized() * PAN_SPEED * delta)
