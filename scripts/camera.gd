extends Camera2D

const PAN_SPEED := 600
const ZOOM_SPEED := 0.1
const MIN_ZOOM := 0.1
const MAX_ZOOM := 2.0

var is_active: bool = false
var is_tab_pressed: bool = false

func _process(delta: float) -> void:
	if not is_active:
		return
		
	# Handle camera movement
	var input := Vector2.ZERO
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		input.x += 1
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		input.x -= 1
	if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
		input.y += 1
	if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
		input.y -= 1

	set_global_position(global_position + input.normalized() * PAN_SPEED * delta)

func _input(event):
	# Handle tab key press/release for toggle
	if event is InputEventKey and event.keycode == KEY_TAB:
		if event.pressed and not is_tab_pressed:
			is_tab_pressed = true
			toggle()
		elif not event.pressed:
			is_tab_pressed = false
		get_viewport().set_input_as_handled()
	
	# Only process other inputs if camera is active
	if not is_active:
		return
		
	# Handle mouse wheel zoom
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_camera(-1)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_camera(1)
			get_viewport().set_input_as_handled()

func zoom_camera(direction: int):
	var zoom_factor = 1.0 - (direction * ZOOM_SPEED)
	var new_zoom = zoom * zoom_factor
	# Clamp zoom level
	new_zoom.x = clamp(new_zoom.x, MIN_ZOOM, MAX_ZOOM)
	new_zoom.y = clamp(new_zoom.y, MIN_ZOOM, MAX_ZOOM)
	zoom = new_zoom

# Public functions to control camera state
func enable() -> void:
	is_active = true
	print("Camera enabled")

func disable() -> void:
	is_active = false
	print("Camera disabled")

func toggle() -> void:
	is_active = !is_active
	print("Camera active: ", is_active)
