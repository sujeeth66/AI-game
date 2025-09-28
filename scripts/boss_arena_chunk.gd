extends Node
class_name BossArenaChunk

const BIOMES = preload("res://scripts/terrain_chunks.gd").BIOMES

# Platform generation parameters
const PLATFORM_LENGTHS = [3, 4]  # Possible platform lengths (3 or 4 tiles)
const PLATFORM_HEIGHT = 1  # Height of each platform (1 tile thin)
const HORIZONTAL_MARGIN = 4  # Space from chunk edges
const PLATFORM_LAYER_HEIGHTS = [2, 5, 8]  # Heights above ground for each layer

var noise = FastNoiseLite.new()

func build_boss_arena_chunk(terrain_tilemap: TileMapLayer, decor_tilemap: TileMapLayer, start_point: Vector2i, distance: int, biome: String) -> Dictionary:
	var tiles = BIOMES.get(biome, BIOMES["DESERT"])
	var log = []
	var noise_amplitude := 0.8  # Even flatter than regular arena
	var noise_frequency := 0.15
	var surface_positions: Array[Vector2i] = []
	
	# Calculate layers and height based on distance
	var layer_info = _calculate_platform_layers(distance)
	var max_layers = layer_info["layers"]
	var max_height = layer_info["max_height"]
	
	# Define height levels for platforms using hardcoded heights (relative to ground)
	var height_levels = []
	for i in range(min(max_layers, len(PLATFORM_LAYER_HEIGHTS))):
		height_levels.append(start_point.y - 1 - PLATFORM_LAYER_HEIGHTS[i])  # -1 because tiles are placed above the coordinate
	
	# Generate terrain floor (fixed at start_point.y)
	for x in range(start_point.x, start_point.x + distance):
		var surface_pos = Vector2i(x, start_point.y)
		surface_positions.append(surface_pos)  # Add surface position for slime spawning
		
		# Place top tile at fixed height (start_point.y)
		terrain_tilemap.set_cell(surface_pos, 0, tiles["top"])
		
		# Fill below with sub tiles (deeper for boss arena)
		for y in range(1, 8):
			terrain_tilemap.set_cell(Vector2i(x, start_point.y + y), 0, tiles["sub"])
		
		# Add slight vertical variation to the terrain surface (cosmetic only)
		if x > start_point.x and x < start_point.x + distance - 1:
			var noise_value = noise.get_noise_1d(x * noise_frequency)
			if abs(noise_value) > 0.7:  # Only apply noticeable variations occasionally
				var height_offset = sign(noise_value)  # -1, 0, or 1
				terrain_tilemap.set_cell(Vector2i(x, start_point.y - 1), 0, tiles["top"])

	# Log the platform generation details
	log.append("🏰 Creating boss arena with %d platform layers (chunk distance: %d, max height: %d)" % [max_layers, distance, max_height])

	# Generate platform positions
	var platforms = _generate_platform_positions(start_point.x, distance, height_levels, max_layers)

	# Draw platforms
	for platform in platforms:
		_draw_platform(terrain_tilemap, decor_tilemap, platform, tiles)
		log.append("🪨 Platform at (%d, %d) width %d" % [platform.x, platform.y, platform.width])

	# Add some decorative elements (rocks only, no trees in boss arena)
	for x in range(start_point.x + 10, start_point.x + distance - 10, 8):
		if randi() % 100 < 20:  # 20% chance for rock
			var rock_pos = Vector2i(x, start_point.y - 1)  # Place rocks just above the floor
			decor_tilemap.set_cell(rock_pos, 0, tiles["rock"])
			log.append("   + Rock at (%d, %d)" % [rock_pos.x, rock_pos.y])

	# Calculate end point based on start point and distance
	var end_point := Vector2i(start_point.x + distance, start_point.y)
	return { 
		"end_point": end_point, 
		"log": log,
		"surface_positions": surface_positions
	}

func _calculate_platform_layers(distance: int) -> Dictionary:
	# Use fixed 3 layers with specific heights
	var max_layers = min(3, len(PLATFORM_LAYER_HEIGHTS))
	var max_height = PLATFORM_LAYER_HEIGHTS[max_layers - 1] if max_layers > 0 else 0
	
	return {
		"layers": max_layers,
		"max_height": max_height + 2  # Add some extra height for safety
	}

func _generate_platform_positions(start_x: int, distance: int, height_levels: Array, layer_count: int) -> Array:
	var platforms = []
	var usable_width = distance - (2 * HORIZONTAL_MARGIN)
	
	# We'll use the pre-calculated height levels from the build function
	# Start from the top layer (index 0) and work down
	
	# Generate pyramid layers from top to bottom
	for layer in range(layer_count):
		var platforms_in_layer = layer_count - layer  # Decrease platforms as we go down
		if platforms_in_layer <= 0 or layer >= height_levels.size():
			break
		
		# Calculate spacing between platforms in this layer
		var platform_length = PLATFORM_LENGTHS[randi() % len(PLATFORM_LENGTHS)]  # Randomly choose 3 or 4
		var total_platform_width = platforms_in_layer * platform_length
		var total_gap = max(0, usable_width - total_platform_width)
		var gap_between = total_gap / (platforms_in_layer + 1) if platforms_in_layer > 1 else 0
		
		# Get the y-position for this layer from height_levels
		var platform_y = height_levels[layer]
		
		# Position platforms in this layer, centered horizontally
		var layer_width = (platforms_in_layer * platform_length) + ((platforms_in_layer - 1) * gap_between)
		var start_x_pos = start_x + ((distance - layer_width) / 2)
		
		for i in range(platforms_in_layer):
			var platform_x = start_x_pos + (i * (platform_length + gap_between))
			
			# Add some slight horizontal variation (except for single-platform layers)
			if platforms_in_layer > 1 and i > 0 and i < platforms_in_layer - 1:
				platform_x += (randi() % 3) - 1  # -1, 0, or 1
			
			platforms.append({
				"x": int(platform_x),
				"y": int(platform_y),
				"width": platform_length,  # Use the randomly chosen length
				"height": PLATFORM_HEIGHT
			})
	
	return platforms
	
	return platforms

func _is_position_valid(platforms: Array, new_x: int, new_width: int, new_y: int, start_x: int, distance: int) -> bool:
	# For pyramid generation, we don't need this check as positions are calculated precisely
	return true

func _draw_platform(terrain_tilemap: TileMapLayer, decor_tilemap: TileMapLayer, platform: Dictionary, tiles: Dictionary) -> void:
	# Draw platform (1 tile thin but multiple tiles long)
	for x in range(platform.width):
		terrain_tilemap.set_cell(Vector2i(platform.x + x, platform.y), 0, tiles["top"])
		# No sub-tiles since it's a floating platform
	
	# Add some decorative elements (20% chance per platform)
	if randi() % 100 < 20:
		var decor_x = platform.x + (platform.width / 2)
		var decor_y = platform.y - 1
		var decor_type = "rock" if randi() % 2 == 0 else "tree"
		decor_tilemap.set_cell(Vector2i(decor_x, decor_y), 0, tiles[decor_type])
