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

func _init():
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

func build_up_chunk_with_slope(terrain_tilemap: TileMapLayer, decor_tilemap: TileMapLayer, biome: String, start_point: Vector2i, slope: float, distance: int, jump_height: int) -> Dictionary:
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
		var raw_y := prev_y + delta_y
		var clamped_y := int(raw_y)

		var delta = clamped_y - heights[i - 1]
		if abs(delta) > jump_height:
			clamped_y = heights[i - 1] + clamp(delta, -jump_height, jump_height)

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
