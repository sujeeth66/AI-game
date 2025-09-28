extends Node2D

# Performance monitoring (disabled)
# var performance_monitor = preload("res://scripts/performance_monitor.gd").new()
var last_chunk_build_time = 0.0
var chunk_build_times = []

# Enemy spawning
# Load the slime scene from the root directory where it was copied to
const SLIME_SCENE: PackedScene = preload("res://scenes/slime.tscn")
const MIN_DISTANCE_BETWEEN_SLIMES = 4  # Minimum tiles between slimes
const SPAWN_CHANCE = 0.15  # 15% chance to spawn a slime in a valid position

@onready var terrain_tilemap := $TileMapLayer
@onready var decor_tilemap := $DecorLayer
@onready var chunk_builder1 := preload("res://scripts/terrain_chunks.gd").new()
@onready var chunk_builder2 := preload("res://scripts/special_chunks.gd").new()
@onready var arena_builder := preload("res://scripts/boss_arena_chunk.gd").new()
@onready var http_request := $HTTPRequest

const ENDPOINT := "http://127.0.0.1:8000/generate-map"
var current_point: Vector2i = Vector2i(0, 0)
var jump_height: int = 3  # 🦘 Max vertical step allowed between adjacent tiles

func _ready() -> void:
	# Performance monitor disabled
	# add_child(performance_monitor)
	
	# Set up TileMap collision layers through the TileSet
	if has_node("TileMapLayer"):
		var tile_map_layer = $TileMapLayer
		var tile_set = tile_map_layer.tile_set
		if tile_set:
			# Make sure we have at least one physics layer
			if tile_set.get_physics_layers_count() == 0:
				tile_set.add_physics_layer()
			# Set the collision layer and mask for the first physics layer
			tile_set.set_physics_layer_collision_layer(0, 1)  # Layer 1
			tile_set.set_physics_layer_collision_mask(0, 1)   # Collide with layer 1
			
			# For Godot 4, we need to use the TileSet editor to set up collisions
			# This is a one-time setup that needs to be done in the editor
			# The script will just ensure the layers are set correctly
			print("✅ Configured TileMapLayer physics layers. Make sure to set up tile collisions in the TileSet editor.")
			print("  1. Select the TileMapLayer in the Scene panel")
			print("  2. Click on the 'TileSet' tab in the bottom panel")
			print("  3. Select a tile and add a collision shape in the 'Physics' section")
			print("  4. Repeat for all terrain tiles that should have collision")

	# Load player scene with error checking
	if not player_scene:
		print("⚠️ Player scene not set in inspector, attempting to load directly...")
		player_scene = preload("res://scenes/player.tscn")
		
	if not player_scene:
		push_error("❌ Failed to load player scene! Make sure the path is correct.")
		return

	if http_request:
		http_request.request_completed.connect(_on_request_completed)
		print("📡 HTTPRequest signal connected")
		generate_from_lore("a rugged mountainous terrain with steep slopes and many hills...")
	else:
		push_error("❌ HTTPRequest node not found!")

func generate_from_lore(lore: String) -> void:
	var payload := { "lore": lore }
	var headers := ["Content-Type: application/json"]
	var body := JSON.stringify(payload)

	if not http_request.is_inside_tree():
		push_error("❌ HTTPRequest not in tree")
		return

	var result :int= http_request.request(ENDPOINT, headers, HTTPClient.METHOD_POST, body)
	if result != OK:
		push_error("⚠️ Failed to send request: %s" % result)
	else:
		print("✅ Request sent successfully with lore:\n'%s'" % lore)

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	var request_time = Time.get_ticks_usec()

	if result != HTTPRequest.RESULT_SUCCESS:
		var error_msg = "HTTP Request failed with code: " + str(response_code)
		push_error(error_msg)
		_log_chunk_build_time(request_time, "HTTP Error: " + error_msg)
		return

	var raw_response := body.get_string_from_utf8()
	print("\n📨 Raw server response:\n", raw_response)  # 👈 This is your raw output log

	var json = JSON.new()
	var parse_start = Time.get_ticks_usec()
	var parse_error = json.parse(raw_response)
	var parse_time = (Time.get_ticks_usec() - parse_start) / 1000.0

	if parse_error != OK:
		push_error("JSON Parse Error: " + json.get_error_message())
		_log_chunk_build_time(parse_start, "JSON Parse Error")
		return

	var response = json.get_data()
	_log_chunk_build_time(parse_start, "JSON Parse (%.2fms)" % parse_time)

	if response and response.has("chunks"):
		build_map(response.chunks)
	else:
		push_error("Invalid response format")
		_log_chunk_build_time(request_time, "Invalid Response Format")
# Player scene reference
@export var player_scene: PackedScene
@onready var player = null
static var player_spawn_position: Vector2 = Vector2.ZERO

func _spawn_player(position: Vector2) -> void:
	if not player_scene:
		push_error("❌ Cannot spawn player: player_scene is null")
		return
	
	print("🎮 Attempting to spawn player at: ", position)
	player = player_scene.instantiate()
	add_child(player)
	player.global_position = position
	player_spawn_position = position  # Store the spawn position
		# --- START DEBUG ---
	var tile_map = $TileMapLayer
	print("--- TILEMAP DEBUG ---")
	print("TileMap node: ", tile_map)
	print("TileMap visible: ", tile_map.visible)
	print("TileMap Z-Index: ", tile_map.z_index)
	#print("Used cells: ", tile_map.get_used_cells(0).size())
	
	await get_tree().create_timer(0.1).timeout # Wait a frame for camera to settle
	
	var active_camera = get_viewport().get_camera_2d()
	print("--- CAMERA DEBUG ---")
	print("Active camera: ", active_camera)
	if active_camera:
		print("Camera path: ", active_camera.get_path())
		print("Camera position: ", active_camera.global_position)
		print("Camera zoom: ", active_camera.zoom)
	print("--- END DEBUG ---")
	print("✅ Player spawned successfully at: ", position)

func _log_chunk_build_time(start_time: float, chunk_type: String) -> void:
	var current_time = Time.get_ticks_usec()
	var build_time = (current_time - start_time) / 1000.0  # Convert to ms
	chunk_build_times.append(build_time)
	
	# Keep only last 10 build times
	if chunk_build_times.size() > 10:
		chunk_build_times.pop_front()
	
	# Calculate average
	var total = 0.0
	for time in chunk_build_times:
		total += time
	var avg_time = total / chunk_build_times.size()
	
	print("Built %s chunk in %.2fms (Avg: %.2fms)" % [chunk_type, build_time, avg_time])

func build_map(chunks: Array) -> void:
	var start_time = Time.get_ticks_usec()
	
	# First pass: Build all chunks and find spawn position
	var has_spawn_chunk = false
	
	for chunk_data in chunks:
		var type :String= chunk_data.get("type", "")
		var biome :String= chunk_data.get("biome", "DESERT")
		var distance := int(chunk_data.get("distance", 128))
		var slope := float(chunk_data.get("slope", 0.0))

		print("\n🧩 Building chunk:")
		print("- Type: %s | Biome: %s | Distance: %d | Slope: %.2f" % [type, biome, distance, slope])

		var chunk := {}
		match type:
			"FlatChunk":
				chunk = chunk_builder1.build_flat_chunk(terrain_tilemap, decor_tilemap, biome, current_point, distance)
			
			"UpSlopeChunk":
				chunk = chunk_builder1.build_up_chunk_with_slope(terrain_tilemap, decor_tilemap, biome, current_point, -slope, distance, jump_height)
			
			"DownSlopeChunk":
				chunk = chunk_builder1.build_down_chunk_with_slope(terrain_tilemap, decor_tilemap, biome, current_point, slope, distance, jump_height)
			
			"ArenaChunk":
				chunk = chunk_builder1.build_arena_chunk(terrain_tilemap, decor_tilemap, biome, current_point, distance)
			
			"BossArenaChunk":
				chunk = arena_builder.build_boss_arena_chunk(terrain_tilemap, decor_tilemap, current_point, distance, biome)
			
			"SpawnChunk":
				chunk = chunk_builder2.build_spawn_chunk(terrain_tilemap, decor_tilemap, biome, current_point, distance)
				if chunk and chunk.has("player_spawn"):
					player_spawn_position = chunk.get("player_spawn", Vector2.ZERO)
					has_spawn_chunk = true
					print("📌 Player spawn position set to: ", player_spawn_position)
			
			"EndLevelChunk":
				chunk = chunk_builder2.build_end_level_chunk(terrain_tilemap, decor_tilemap, biome, current_point, distance)
			
			_:
				push_error("❓ Unknown chunk type: %s" % type)
				continue  # Skip to next chunk if type is unknown

		if chunk and chunk.has("end_point"):
			current_point = chunk.get("end_point", current_point + Vector2i(1, 0))
			print("✅ Chunk ends at: %s" % current_point)
			print("📋 Log:\n" + "\n".join(chunk.get("log", [])))
			
			# Spawn slimes after building chunk if it's not a spawn chunk and has surface positions
			if type != "SpawnChunk" and chunk.has("surface_positions"):
				spawn_slimes(chunk.surface_positions, player_spawn_position)
		else:
			push_error(" Failed to create chunk for type: %s" % type)
	
	# Second pass: Spawn player and handle any post-generation logic
	if has_spawn_chunk and player_spawn_position != Vector2.ZERO:
		_spawn_player(player_spawn_position)
	else:
		push_warning(" No spawn chunk found or invalid spawn position. Player not spawned.")
	
	var total_time = (Time.get_ticks_usec() - start_time) / 1000.0
	print("\n Map generation completed in %.2fms" % total_time)

func spawn_slimes(surface_positions: Array, player_spawn_position: Vector2) -> void:
	if SLIME_SCENE == null:
		print("SLIME_SCENE is null, cannot spawn slimes")
		return

	print("Attempting to spawn slimes for chunk with ", surface_positions.size(), " surface positions")
	
	var player_spawn_tile = terrain_tilemap.local_to_map(player_spawn_position)
	var last_slime_x = -MIN_DISTANCE_BETWEEN_SLIMES
	var slimes_spawned = 0
	
	for pos in surface_positions:
		var tile_pos: Vector2i = Vector2i(pos)
		
		# Skip positions too close to player spawn (reduced from 16 to 8)
		if abs(tile_pos.x - player_spawn_tile.x) < 8:
			continue
			
		# Skip positions too close to the last slime (reduced from 4 to 2)
		if abs(tile_pos.x - last_slime_x) < 2:  # Reduced minimum distance
			continue
		
		# Increased spawn chance from 15% to 30%
		if randf() > 0.01:  
			continue
		
		# Calculate world position (center of tile, adjusted for slime size)
		var world_pos = terrain_tilemap.map_to_local(tile_pos) + Vector2(8, -24)
		
		# Spawn the slime
		var slime = SLIME_SCENE.instantiate()
		slime.debug_mode = true
		slime.position = world_pos
		
		# Calculate enemy level based on distance from spawn
		var distance_from_spawn = abs(tile_pos.x - player_spawn_tile.x)
		var enemy_level = calculate_enemy_level(distance_from_spawn)
		if slime.has_method("set_level"):
			slime.set_level(enemy_level)
		
		add_child(slime)
		last_slime_x = tile_pos.x
		slimes_spawned += 1
		print("Spawned slime at ", world_pos, " (level ", enemy_level, ")")
	
	print("Spawned ", slimes_spawned, " slimes in this chunk")

func calculate_enemy_level(distance: int) -> int:
	"""
	Calculates the enemy level based on distance from spawn.
	
	@param distance: Distance from spawn in tiles
	@return: Enemy level (1-10)
	"""
	# Base level is 1, increases every 20 tiles
	var level = 1 + (distance / 20.0)
	# Cap at level 10
	return min(int(level), 10)
