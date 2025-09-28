# Additional chunk functions for spawn and end level areas
extends Node
class_name ChunkBuilder2

const BIOMES := {
	"DESERT": { "top": Vector2i(4, 0), "sub": Vector2i(4, 1), "tree": Vector2i(5, 5), "rock": Vector2i(8, 6) },
	"FOREST": { "top": Vector2i(0, 0), "sub": Vector2i(0, 1), "tree": Vector2i(3, 5), "rock": Vector2i(3, 6) },
	"SNOW":   { "top": Vector2i(6, 0), "sub": Vector2i(6, 1), "tree": Vector2i(1, 5), "rock": Vector2i(1, 6) }
}

var noise := FastNoiseLite.new()

func build_spawn_chunk(
	terrain_tilemap: TileMapLayer,
	decor_tilemap: TileMapLayer,
	biome: String,
	start_point: Vector2i,
	distance: int
) -> Dictionary:
	var tiles = BIOMES.get(biome, BIOMES["DESERT"])
	var log := []
	var height := start_point.y
	var surface_positions: Array[Vector2i] = []
	
	# Create a perfectly flat spawn area
	for x in range(start_point.x, start_point.x + distance):
		var current_height = height  # No noise for spawn area
		var surface_pos = Vector2i(x, current_height)
		
		# Add surface position for slime spawning (but spawn chunk won't spawn slimes)
		surface_positions.append(surface_pos)
		
		# Place top tile
		terrain_tilemap.set_cell(surface_pos, 0, tiles["top"])
		
		# Fill below with sub tiles (deeper for spawn area)
		for y in range(1, 10):  # Extra deep floor for spawn area
			terrain_tilemap.set_cell(Vector2i(x, current_height + y), 0, tiles["sub"])
	
	# Add spawn platform in the middle
	var platform_start = start_point.x + (distance / 2) - 3
	for x in range(platform_start, platform_start + 6):
		terrain_tilemap.set_cell(Vector2i(x, height - 2), 0, tiles["top"])
		terrain_tilemap.set_cell(Vector2i(x, height - 1), 0, tiles["sub"])
	
	log.append("🚀 Spawn platform created at x=%d-%d" % [platform_start, platform_start + 5])
	
	# Add boundary markers (visual only)
	for y in range(-3, 1):
		terrain_tilemap.set_cell(Vector2i(start_point.x, height + y), 0, tiles["top"])
		terrain_tilemap.set_cell(Vector2i(start_point.x + distance - 1, height + y), 0, tiles["top"])
	
	# Calculate player spawn position (center of the platform, 3 tiles above)
	var player_spawn_x = (platform_start + (platform_start + 5)) / 2  # Middle of the platform
	var player_spawn_y = height - 5  # 3 tiles above the platform (was -3, changed to -5 to be 3 tiles above)
	
	# Get tile size, default to 16x16 if not available
	var tile_size = Vector2i(16, 16)
	if terrain_tilemap and terrain_tilemap.tile_set:
		tile_size = terrain_tilemap.tile_set.tile_size
	
	print("📏 Tile size: ", tile_size)
	print("📍 Raw spawn position (tile coords): ", Vector2i(player_spawn_x, player_spawn_y))
	
	# Calculate world position (center of the tile)
	var world_spawn_x = player_spawn_x * tile_size.x + tile_size.x / 2
	var world_spawn_y = player_spawn_y * tile_size.y + tile_size.y / 2
	var world_spawn = Vector2(world_spawn_x, world_spawn_y)
	
	print("🌍 World spawn position: ", world_spawn)
	
	log.append("🔵 Spawn chunk created at x=%d-%d" % [start_point.x, start_point.x + distance])
	log.append("👤 Player will spawn at world position: %s" % world_spawn)

	var end_point := Vector2i(start_point.x + distance, height)
	
	# Return player spawn position along with other data
	return {
		"end_point": end_point,
		"player_spawn": world_spawn,
		"log": log,
		"surface_positions": surface_positions
	}

func build_end_level_chunk(
	terrain_tilemap: TileMapLayer,
	decor_tilemap: TileMapLayer,
	biome: String,
	start_point: Vector2i,
	distance: int
) -> Dictionary:
	var tiles = BIOMES.get(biome, BIOMES["DESERT"])
	var log := []
	var height := start_point.y
	var surface_positions: Array[Vector2i] = []
	
	# Create a flat end area with a clear visual indicator
	for x in range(start_point.x, start_point.x + distance):
		var current_height = height  # No noise for end area
		var surface_pos = Vector2i(x, current_height)
		surface_positions.append(surface_pos)  # Add surface position for slime spawning
		
		# Place top tile
		terrain_tilemap.set_cell(surface_pos, 0, tiles["top"])
		
		# Fill below with sub tiles
		for y in range(1, 8):  # Deep floor for end area
			terrain_tilemap.set_cell(Vector2i(x, current_height + y), 0, tiles["sub"])
	
	# Add end level platform in the middle
	var platform_start = start_point.x + (distance / 2) - 4
	for x in range(platform_start, platform_start + 8):
		# Use different tile for the end platform
		terrain_tilemap.set_cell(Vector2i(x, height - 2), 0, tiles["rock"])
		terrain_tilemap.set_cell(Vector2i(x, height - 1), 0, tiles["sub"])
	
	# Add special end-level decorations
	for x in [platform_start - 2, platform_start + 8 + 1]:
		terrain_tilemap.set_cell(Vector2i(x, height - 4), 0, tiles["rock"])
		terrain_tilemap.set_cell(Vector2i(x, height - 3), 0, tiles["rock"])
		terrain_tilemap.set_cell(Vector2i(x, height - 2), 0, tiles["rock"])
		terrain_tilemap.set_cell(Vector2i(x, height - 1), 0, tiles["sub"])
	
	log.append("🏁 End level platform created at x=%d-%d" % [platform_start, platform_start + 7])
	
	# Add boundary markers (visual only)
	for y in range(-3, 1):
		terrain_tilemap.set_cell(Vector2i(start_point.x, height + y), 0, tiles["rock"])
		terrain_tilemap.set_cell(Vector2i(start_point.x + distance - 1, height + y), 0, tiles["rock"])
	
	log.append("🔴 End level chunk created at x=%d-%d" % [start_point.x, start_point.x + distance])

	var end_point := Vector2i(start_point.x + distance, height)
	return { 
		"end_point": end_point, 
		"log": log,
		"surface_positions": surface_positions,
		"end_position": Vector2(platform_start + 4, height - 3)
	}
