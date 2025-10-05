const GridUtils = preload("res://procedural_map_generation/test/GridUtils.gd")
const TunnelGen = preload("res://procedural_map_generation/test/TunnelGen.gd")

static func generate_surface_segment(map_grid, segment: Dictionary, x_cursor: int) -> Dictionary:
	var segment_length = segment["length"]
	var terrain_type = segment["type"]
	var end_x = x_cursor + segment_length
	var last_heights = {}

	if terrain_type == "city":
		last_heights = GridUtils.generate_city_surface(map_grid, x_cursor, segment.get("city_segments", []), 0)
	else:
		last_heights = GridUtils.generate_surface_layer(
			map_grid,
			map_grid.size(),
			map_grid[0].size(),
			segment.get("surface_height", 40),
			segment.get("seed", 0),
			terrain_type,
			x_cursor,
			end_x,
			0,
			segment.get("last_heights", {})
		)

	return {
		"last_heights": last_heights,
		"end_x": end_x
	}

static func generate_underground_segment(map_grid, segment: Dictionary, x_cursor: int) -> Array:
	var tunnels := []
	var ug = segment.get("underground", null)
	if ug == null:
		return tunnels

	var tunnel_count = ug.get("tunnels", 1)
	var depth = ug.get("depth", 60)
	var seed = ug.get("seed", 0)

	for i in range(tunnel_count):
		var start_x = x_cursor + randi() % segment["length"]
		var tunnel = TunnelGen.carve_horizontal_tunnel(map_grid, start_x, segment["length"], depth, seed + i)
		TunnelGen.roughen_tunnel_floor_with_moore(map_grid, map_grid[0].size(), map_grid.size())
		TunnelGen.smooth_tunnel(map_grid, map_grid[0].size(), map_grid.size())
		tunnels.append(tunnel)

	return tunnels

static func compute_map_dimensions(surface_segments: Array, underground : Dictionary, surface_height := 50, tunnel_height := 30, buffer := 20) -> Dictionary:
	var total_width := 0
	for segment in surface_segments:
		total_width += segment.get("length", 100)

	var tunnel_layers := 0
	if underground and underground.has("tunnels"):
		tunnel_layers = underground["tunnels"]

	var total_height := surface_height + (tunnel_layers * tunnel_height) + buffer
	return {
		"width": total_width,
		"height": total_height
	}
