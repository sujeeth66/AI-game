const GridUtils = preload("res://procedural_map_generation/test/GridUtils.gd")
const TunnelGen = preload("res://procedural_map_generation/test/TunnelGen.gd")

static func compute_map_dimensions(surface_segments: Array, underground : Dictionary, surface_height := 50, tunnel_height := 30) -> Dictionary:
	var total_width := 0
	for segment in surface_segments:
		total_width += segment.get("length", 100)

	var tunnel_layers := 0
	if underground and underground.has("tunnels"):
		tunnel_layers = underground["tunnels"]
	var buffer := 25
	if underground["room_shape"] == "flat" :
		print("-------------------------",underground["room_shape"],"-------------------------")
		buffer = 3
	elif underground["room_shape"] == "organic":
		buffer = 20
	var total_height := surface_height + (tunnel_layers * tunnel_height) + (tunnel_layers * buffer)
	return {
		"width": total_width,
		"height": total_height
	}
