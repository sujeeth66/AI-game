extends Area2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

@export var speed := 300
@export var direction := Vector2.RIGHT
@export var damage := 25
@export var splash_radius := 40
@export var delay := 0.5

var launched := false
var damage_active := false
var knockback_active := true  # Start with knockback active
var parent_node: Node2D = null
var scene_tree: SceneTree = null  # Store scene tree reference

signal fireball_launched(direction: Vector2)
signal fireball_pressed()

func _ready() -> void:
	# Initial visual effect
	animated_sprite.play("spawn")
	fireball_pressed.emit()
	print("[FIREBALL PRESSED]")
	await animated_sprite.animation_finished

	# Activate motion and damage
	damage_active = true
	animated_sprite.play("move")
	launched = true
	fireball_launched.emit(direction)  # Emit signal when launched

func _process(delta: float) -> void:
	if launched:
		position += direction * speed * delta

func _on_body_entered(body: Node) -> void:
	# Prevent fireball from damaging the player
	if body.is_in_group("player"):
		return
	if body is TileMapLayer:
		print(body)
		# Apply knockback only if knockback is active
		if knockback_active and body.has_method("apply_knockback"):
			var knockback_direction = (body.global_position - global_position).normalized()
			body.apply_knockback(knockback_direction * 400)  # Adjust force as needed

		# Trigger splash damage logic
		damage_active = false
		launched = false
		$CollisionShape2D.call_deferred("set_disabled", true)
		animated_sprite.play("die")

		# Delay to sync with animation
		apply_splash_damage()
		await animated_sprite.animation_finished
		queue_free()
	
	if damage_active and body.has_method("take_damage"):
		body.take_damage(damage)
		print("🔥 Direct hit:", body.name, "for", damage, "damage")

		# Apply knockback only if knockback is active
		if knockback_active and body.has_method("apply_knockback"):
			var knockback_direction = (body.global_position - global_position).normalized()
			body.apply_knockback(knockback_direction * 400)  # Adjust force as needed

		# Trigger splash damage logic
		damage_active = false
		launched = false
		$CollisionShape2D.call_deferred("set_disabled", true)
		animated_sprite.play("die")

		# Delay to sync with animation
		apply_splash_damage()
		await animated_sprite.animation_finished
		queue_free()

func apply_splash_damage() -> void:
	var space_state := get_world_2d().direct_space_state
	var splash_points := 8
	var radius := splash_radius

	for i in range(splash_points):
		var angle := TAU * float(i) / splash_points
		var offset := Vector2(cos(angle), sin(angle)) * radius
		var hit_position := position + offset

		var params := PhysicsPointQueryParameters2D.new()
		params.position = hit_position
		params.collide_with_areas = false
		params.collide_with_bodies = true
		params.collision_mask = collision_mask  # Use your intended bitmask here

		var result: Array[Dictionary] = space_state.intersect_point(params)

		for item in result:
			var node: Node = item.get("collider")
			if node != null and node.has_method("take_damage") and node != self:
				node.take_damage(damage / 2)
				print("💥 Splash hit:", node.name, "for", damage / 2, "damage")

func set_parent(parent: Node2D, tree: SceneTree):
	parent_node = parent
	scene_tree = tree
	
	# Remove from current parent if exists
	if get_parent():
		get_parent().remove_child(self)
	
	# Add as child to parent (not reparent)
	parent.add_child(self)
	
	# Set local position relative to player
	self.position = Vector2(20 if GlobalStates.facing_right else -20, 0)
	
	# Emit signal after parenting
	fireball_pressed.emit()

func launch():
	if launched:
		return
	
	# Remove from player parent
	if get_parent():
		get_parent().remove_child(self)
	
	# Add to scene tree
	scene_tree.current_scene.add_child(self)
	
	# Convert local position to global position
	self.global_position = parent_node.global_position + Vector2(50 if GlobalStates.facing_right else -50, 0)
	
	# Launch fireball
	launched = true
	damage_active = true
	animated_sprite.play("move")
	fireball_launched.emit(direction)
