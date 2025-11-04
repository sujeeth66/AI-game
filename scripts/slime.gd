extends BaseEnemy

#region Constants
# Movement
@export var RUN_SPEED: float = 100.0
@export var INVESTIGATE_SPEED : float = 50.0
@export var JUMP_VELOCITY: float = 350.0
@export var GRAVITY: float = 700.0
@export var FRICTION: float = 0.9
# AI
@export var CHASE_RADIUS: float = 800.0
@export var ATTACK_RADIUS: float = 40.0
@export var VISION_ANGLE: float = 90.0  # Field of view in degrees

# Health & Leveling
@export var BASE_HEALTH: int = 100
@export var BASE_DAMAGE: int = 20
@export var EXPERIENCE_REWARD: int = 15

# Item Drops
@export var drop_item_name: String = "Slime Gel"
@export var drop_chance: float = 0.8  # 80% chance to drop
@export var drop_quantity_min: int = 1
@export var drop_quantity_max: int = 2

#region Variables
# State Machine
@onready var state_machine = $SlimeStateMachine

# Stats
var level: int = 1
var health: int = BASE_HEALTH
var max_health: int = BASE_HEALTH
var damage: int = BASE_DAMAGE

# Vision & Pathfinding
@onready var raycast: RayCast2D = $RayCast2D
var total_time :float = 0.0
var last_known_player_position: Vector2
var has_line_of_sight: bool = false
var vision_timer: float = 0.0
const VISION_UPDATE_RATE: float = 0.1
const MAX_JUMP_HEIGHT: float = 64.0  # Maximum height the slime can jump

# Debug
@export var debug_mode: bool = false
#endregion

#region Node References
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collider: CollisionShape2D = $CollisionShape2D2
#endregion

func _ready() -> void:
	super()
	# Set initial stats based on level
	scale_stats_by_level()
	
	call_deferred("_setup_ray_exceptions")
	#raycast.add_exception(player_slash_area)
	# Add to enemies group for potential other systems
	add_to_group("enemies")
	
func _setup_ray_exceptions():
	var player = get_tree().get_first_node_in_group("player")
	var enemy1 = get_tree().get_first_node_in_group("enemies")
	var slash_area = player.get_node("slash_area")
	if player and player is CollisionObject2D:
		raycast.clear_exceptions()
		#raycast.add_exception(player)
		raycast.add_exception(slash_area)
		raycast.add_exception(enemy1)

	else:
		print("Player not found or not a CollisionObject2D")

	
func _process(_delta: float) -> void:
	if debug_mode:
		queue_redraw()

func _physics_process(delta: float) -> void:
	
	if is_dead:
		return
		
	var player = get_tree().get_first_node_in_group("player")
	var distance_to_player = global_position.distance_to(player.global_position)
	
	total_time += delta
	if int(total_time) % 3 == 0 and int(total_time - delta) % 3 != 0:
		if has_line_of_sight:
			print("Player detected! Distance: ", distance_to_player)
		#else:
			#print("lost line of sight")
	# Update vision and LOS
	update_vision(delta)

func _draw() -> void:
	if debug_mode:
		# Draw last known player position (red cross)
		if last_known_player_position != Vector2.ZERO:
			var cross_size = 10.0
			var local_pos = to_local(last_known_player_position)
			draw_line(local_pos - Vector2(cross_size, cross_size), 
				local_pos + Vector2(cross_size, cross_size), 
				Color.RED, 2.0)
			draw_line(local_pos - Vector2(cross_size, -cross_size), 
				local_pos + Vector2(cross_size, -cross_size), 
				Color.RED, 2.0)
		draw_circle(to_local(global_position),CHASE_RADIUS,Color(0,0,1,0.1))
		draw_circle(to_local(global_position),CHASE_RADIUS + 400,Color(1,0,0,0.1))

func has_line_of_sight_to_player() -> bool:
	var player = get_tree().get_first_node_in_group("player")
	#if there is no player node
	if not player:
		has_line_of_sight = false
		print("Player lost (no player found)")
		return false
	
	var distance_to_player = global_position.distance_to(player.global_position)
	# If player is overlapping or very close, assume LOS is valid
	#if the player is too close to the slime(when ray cast length is close to zero,it does not register any collisions)
	if distance_to_player < ATTACK_RADIUS * 0.75:
		has_line_of_sight = true
		last_known_player_position = player.global_position
		return has_line_of_sight

	# Calculate direction to player
	var direction_to_player = raycast.to_local(player.global_position).normalized()
	var can_see = false
	
	# Always use full RAY_LENGTH for consistent detection
	# This prevents the ray from shrinking as player gets closer
	raycast.target_position = raycast.to_local(player.global_position)
	raycast.force_raycast_update()  # Ensure raycast updates this frame
	
	if raycast.is_colliding():
		var hit_position = raycast.get_collision_point()
		var hit_object = raycast.get_collider()
		#print("hit object:",hit_object)
		# Check if we can see the player
		var collider = raycast.get_collider()
		# Only consider it a valid sighting if player is within RAY_LENGTH
		can_see = (collider and collider.is_in_group("player") and 
			distance_to_player <= CHASE_RADIUS)
	#print("can see:",can_see)
	# Update last known position if player is visible
	if can_see:
		last_known_player_position = player.global_position
		has_line_of_sight = true
	else:
		has_line_of_sight = false
	
	return has_line_of_sight


func update_vision(delta: float) -> void:
	vision_timer += delta
	if vision_timer >= VISION_UPDATE_RATE:
		vision_timer = 0.0
		has_line_of_sight = has_line_of_sight_to_player()

func take_damage(amount: int) -> void:
	if is_dead:
		return

	health = max(0, health - amount)
	update_health_bar()
	
	if debug_mode:
		print("Slime took %d damage, %d health remaining" % [amount, health])

	if health <= 0:
		die()
	else:
		# Let the state machine handle the damage state
		if state_machine:
			state_machine.take_damage(amount)

func die() -> void:
	if is_dead:
		return
	super()
	is_dead = true
	velocity = Vector2.ZERO # Stop all movement
	
	# Give experience to player
	var player = get_tree().get_first_node_in_group("player")
	if player and is_instance_valid(player) and player.has_method("gain_experience"):
		player.gain_experience(EXPERIENCE_REWARD)
	
	# Drop items
	drop_items()
	
	# Let the death state handle the rest
	if state_machine:
		state_machine.change_state("slimedeathstate")

func drop_items() -> void:
	# Check if we should drop an item based on drop_chance
	if randf() > drop_chance:
		return
	
	# Find the item in InventoryGlobal
	var item_data = null
	for item in InventoryGlobal.items:
		if item.get("item_name") == drop_item_name:
			item_data = item
			break
	
	if not item_data:
		if debug_mode:
			print("[Slime] ⚠️ Item '", drop_item_name, "' not found in InventoryGlobal.items")
		return
	
	# Determine drop quantity
	var quantity = randi_range(drop_quantity_min, drop_quantity_max)
	
	# Spawn the item at death location
	var item_scene = load("res://inventory/scenes/game_item.tscn")
	if not item_scene:
		if debug_mode:
			print("[Slime] ⚠️ Failed to load game_item scene")
		return
	
	var item_instance = item_scene.instantiate()
	item_instance.initiate_items(
		quantity,
		item_data.get("item_name"),
		item_data.get("item_type"),
		item_data.get("item_effect"),
		item_data.get("item_texture")
	)
	
	# Position slightly above where the slime died
	item_instance.global_position = global_position + Vector2(0, -10)
	
	# Add to scene
	var root = get_tree().current_scene
	var items_node = root.get_node_or_null("Items")
	if not items_node:
		items_node = Node2D.new()
		items_node.name = "Items"
		root.add_child(items_node)
	
	items_node.add_child(item_instance)
	
	if debug_mode:
		print("[Slime] Dropped ", quantity, "x ", drop_item_name)

func set_level(new_level: int) -> void:
	level = new_level
	scale_stats_by_level()
#------------------------------------------------------------------------------
func scale_stats_by_level() -> void:
	max_health = int(BASE_HEALTH * pow(1.1, level - 1))
	health = max_health
	damage = int(BASE_DAMAGE * pow(1.1, level - 1))
	if has_node("LevelLabel"):
		get_node("LevelLabel").text = "Lv. %d" % level

func update_health_bar() -> void:
	var health_ratio = float(health) / float(max_health)
	# Update your health bar UI here
	if has_node("HealthBar"):
		get_node("HealthBar").value = health_ratio * 100  # Assuming 0-100 scale
