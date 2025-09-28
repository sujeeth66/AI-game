extends Node
class_name ChunkBuilder1

const BIOMES := {
	"DESERT": { "top": Vector2i(4, 0), "sub": Vector2i(4, 1), "tree": Vector2i(5, 5), "rock": Vector2i(8, 6) },
	"FOREST": { "top": Vector2i(0, 0), "sub": Vector2i(0, 1), "tree": Vector2i(3, 5), "rock": Vector2i(3, 6) },
	"SNOW":   { "top": Vector2i(6, 0), "sub": Vector2i(6, 1), "tree": Vector2i(1, 5), "rock": Vector2i(1, 6) }
}

var noise := FastNoiseLite.new()

func get_eased_slope_and_noise(t: float, slope: float, x: float, y: float, amplitude: float, frequency: float) -> float:
	var ease := sin(t * PI)
	var effective_slope := slope * ease
	var noise_val := noise.get_noise_2d(x * frequency, y * frequency) * amplitude * ease
	return effective_slope + noise_val

func _inidwt():
	noise.noise_type = FastNoiseLite.NoiseType.TYPE_PERLIN
	noise.seed = randi()
	noise.frequency = 0.03

func build_flat_chunk(terrain_tilemap: TileMapLayer, decor_tilemap: TileMapLayer, biome: String, start_point: Vector2i, distance: int) -> Dictionary:
	var tiles = BIOMES.get(biome, BIOMES["DESERT"])
	var log := []
	var last_decor_x := -10
	var height := start_point.y
	var surface_positions: Array[Vector2i] = []

	for x in range(start_point.x, start_point.x + distance):
		var peak := Vector2i(x, height)
		surface_positions.append(peak)  # Add surface position for slime spawning
		var decor_peak := Vector2i(x, height - 1)
		terrain_tilemap.set_cell(peak, 0, tiles["top"])

		for y in range(1, 20):
			terrain_tilemap.set_cell(Vector2i(x, height + y), 0, tiles["sub"])

		if x - last_decor_x > 2:
			var rand := randi() % 100
			if rand < 2:
				decor_tilemap.set_cell(decor_peak, 0, tiles["tree"])
				log.append(" Tree at %s" % peak)
				last_decor_x = x
			elif rand < 4:
				decor_tilemap.set_cell(decor_peak, 0, tiles["rock"])
				log.append(" Rock at %s" % peak)
				last_decor_x = x

	var end_point := Vector2i(start_point.x + distance, height)
	return { 
		"end_point": end_point, 
		"log": log,
		"surface_positions": surface_positions
	}

# Add this helper function to terrain_chunks.gd
func _get_natural_slope(t: float, slope: float, x: float, noise_scale: float = 0.1) -> float:
	# Break the slope into segments
	var segment = int(t * 4.0) / 4.0  # 4 segments
	var segment_t = (t - segment * 4.0) * 4.0  # 0-1 within segment
	
	# Vary the slope slightly for each segment (between 80% and 120% of original)
	var segment_slope = slope * (0.8 + noise.get_noise_1d(segment) * 0.4)
	
	# Use smoothstep for natural easing in/out of segments
	var eased_t = smoothstep(0.0, 1.0, segment_t)
	
	# Add subtle noise that follows the slope direction
	var noise_val = noise.get_noise_2d(x * 0.2, segment * 10) * noise_scale
	
	return (segment + eased_t) * segment_slope + noise_val

func build_up_chunk_with_slope(terrain_tilemap: TileMapLayer, decor_tilemap: TileMapLayer, biome: String, 
							 start_point: Vector2i, slope: float, distance: int, jump_height: int) -> Dictionary:
	var tiles = BIOMES.get(biome, BIOMES["DESERT"])
	var log := []
	var last_decor_x := -10
	var heights := []
	var surface_positions: Array[Vector2i] = []
	
	# Parameters for natural curve
	var base_slope = abs(slope) * 0.5  # Reduced base slope
	var curve_strength = 2.0  # How pronounced the curve is
	var noise_scale = 0.8    # Scale of the noise
	
	print("=== Building slope from (%d, %d) with slope %.2f over %d tiles ===" % 
		  [start_point.x, start_point.y, slope, distance])
	
	# Generate height points with smooth curve
	for i in range(distance + 1):
		var x = start_point.x + i
		var t = float(i) / float(distance)
		
		# Base curve using sine wave for natural slope
		var curve = sin(t * PI * 0.5)  # 0 to 1 over the distance
		var height = start_point.y - int(base_slope * distance * curve * curve_strength)
		
		# Add subtle noise for natural variation
		var noise_val = int(noise.get_noise_2d(x * 0.3, 0) * noise_scale)
		height += noise_val
		
		# Ensure smooth transitions
		if i > 0:
			var prev_height = heights[i-1]
			# Allow small steps up/down but prevent cliffs
			height = clamp(height, prev_height - 1, prev_height + 1)
		
		heights.append(height)
		print("x: %d, t: %.2f, curve: %.2f, height: %d" % [x, t, curve, height])
	
	# Now build the terrain
	for i in range(distance + 1):
		var x = start_point.x + i
		var y = heights[i]
		var peak = Vector2i(x, y)
		surface_positions.append(peak)
		
		# Place the surface tile
		terrain_tilemap.set_cell( peak, 0, tiles["top"])
		print("🌲 Placed TOP tile at: (%d, %d)" % [peak.x, peak.y])
		
		# Fill below with sub tiles (20 tiles down)
		for j in range(1, 20):
			var sub_pos = Vector2i(x, y + j)
			terrain_tilemap.set_cell( sub_pos, 0, tiles["sub"])
		
		# Add decorations (less frequently on slopes)
		if i > 0 and i < distance and (x - last_decor_x) > 3 and randf() < 0.3:
			var decor_peak = Vector2i(x, y - 1)
			var decor_type = "rock" if randf() < 0.7 else "tree"
			decor_tilemap.set_cell( decor_peak, 0, tiles[decor_type])
			log.append(" %s at %s" % [decor_type.capitalize(), peak])
			print("✨ Placed %s at: (%d, %d)" % [decor_type.to_upper(), decor_peak.x, decor_peak.y])
			last_decor_x = x
	
	var end_point = Vector2i(start_point.x + distance, heights[-1])
	print("=== Chunk complete: %d tiles placed from (%d,%d) to (%d,%d) ===" % 
		  [distance + 1, start_point.x, start_point.y, end_point.x, end_point.y])
	
	return { 
		"end_point": end_point, 
		"log": log,
		"surface_positions": surface_positions
	}

func build_down_chunk_with_slope(terrain_tilemap: TileMapLayer, decor_tilemap: TileMapLayer, biome: String, start_point: Vector2i, slope: float, distance: int, jump_height: int) -> Dictionary:
	var tiles = BIOMES.get(biome, BIOMES["DESERT"])
	var log := []
	var last_decor_x := -10
	var heights := [start_point.y]
	var amplitude := 26.0
	var frequency := 0.5
	var surface_positions: Array[Vector2i] = []

	for i in range(1, distance):
		var x := start_point.x + i
		var prev_y := float(heights[i - 1])
		var t := float(i) / float(distance)

		var delta_y := get_eased_slope_and_noise(t, slope, x, prev_y, amplitude, frequency)
		var raw_y := prev_y - delta_y
		var clamped_y := int(raw_y)

		var delta = clamped_y - heights[i - 1]
		if abs(delta) > jump_height:
			clamped_y = heights[i - 1] - clamp(delta, jump_height, -jump_height)

		heights.append(clamped_y)

	var final_peak := start_point
	for i in range(distance):
		var x := start_point.x + i
		var y = heights[i]
		var peak := Vector2i(x, y)
		surface_positions.append(peak)  # Add surface position for slime spawning
		var decor_peak := Vector2i(x, y - 1)
		final_peak = peak

		terrain_tilemap.set_cell(peak, 0, tiles["top"])
		for j in range(1, 20):
			terrain_tilemap.set_cell(Vector2i(x, y + j), 0, tiles["sub"])

		if x - last_decor_x > 2:
			var rand := randi() % 100
			if rand < 2:
				decor_tilemap.set_cell(decor_peak, 0, tiles["tree"])
				log.append(" Tree at %s" % peak)
				last_decor_x = x
			elif rand < 4:
				decor_tilemap.set_cell(decor_peak, 0, tiles["rock"])
				log.append(" Rock at %s" % peak)
				last_decor_x = x

	return { 
		"end_point": final_peak, 
		"log": log,
		"surface_positions": surface_positions
	}

func build_arena_chunk(terrain_tilemap: TileMapLayer, decor_tilemap: TileMapLayer, biome: String, start_point: Vector2i, distance: int) -> Dictionary:
	var tiles = BIOMES.get(biome, BIOMES["DESERT"])
	var log := []
	var height := start_point.y
	var noise_amplitude := 1.5  # Small noise for slight variations
	var noise_frequency := 0.2
	var surface_positions: Array[Vector2i] = []
	
	# Create a flat base with slight noise
	for x in range(start_point.x, start_point.x + distance):
		# Add slight vertical variation using noise
		var noise_offset = int(noise.get_noise_2d(x * noise_frequency, 0) * noise_amplitude)
		var current_height = height + noise_offset
		var peak = Vector2i(x, current_height)
		
		# Add surface position for slime spawning
		surface_positions.append(peak)
		
		# Place top tile with slight variation
		terrain_tilemap.set_cell(peak, 0, tiles["top"])
		
		# Fill below with sub tiles
		for y in range(1, 5):  # Fixed depth of 5 tiles for arena floor
			terrain_tilemap.set_cell(Vector2i(x, current_height + y), 0, tiles["sub"])
	
	# Add some decorative elements (fewer than regular chunks)
	for x in range(start_point.x + 5, start_point.x + distance - 5, 5):
		if randi() % 100 < 20:  # 20% chance for decoration
			var deco_type = "rock" if randi() % 2 == 0 else "tree"
			var deco_pos = Vector2i(x, height - 1 + int(noise.get_noise_2d(x * 0.1, 0) * 2))
			decor_tilemap.set_cell(deco_pos, 0, tiles[deco_type])
			log.append(" %s at %s" % [deco_type.capitalize(), deco_pos])

	var end_point := Vector2i(start_point.x + distance, height)
	return { 
		"end_point": end_point, 
		"log": log,
		"surface_positions": surface_positions
	}

func build_boss_arena_chunk(terrain_tilemap: TileMapLayer, decor_tilemap: TileMapLayer, biome: String, start_point: Vector2i, distance: int) -> Dictionary:
	var boss_arena_chunk = preload("res://scripts/boss_arena_chunk.gd").new()
	return boss_arena_chunk.build_boss_arena_chunk(terrain_tilemap, decor_tilemap, start_point, distance,biome)
