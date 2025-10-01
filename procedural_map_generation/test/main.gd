extends Node2D

@onready var tilemap := $TileMapLayer

var map_width := 300
var map_height := 150
var surface_height := 60
var seed := 12345
var map_grid := []
var surface_bottom = -1
var tunnel_top = -1
var min_distance = 100
var best_pos


const GridUtils = preload("res://procedural_map_generation/test/GridUtils.gd")
const TunnelGen = preload("res://procedural_map_generation/test/TunnelGen.gd")
const TunnelConnector = preload("res://procedural_map_generation/test/TunnelConnector.gd")
const TunnelRooms = preload("res://procedural_map_generation/test/TunnelRooms.gd")
const TunnelUtils = preload("res://procedural_map_generation/test/TunnelUtils.gd")
const TilemapDraw = preload("res://procedural_map_generation/test/TileMapDraw.gd")
const RoomAnalyzer = preload("res://procedural_map_generation/test/RoomAnalyzer.gd")

func _ready():
	GridUtils.initialize_empty_grid(map_grid, map_width, map_height)
	GridUtils.generate_surface_layer(map_grid, map_width, map_height, surface_height, seed)

	var tunnel_path = TunnelGen.carve_horizontal_tunnel(map_grid, 80, 300, 7, seed)
	for i in range(2):
		TunnelGen.roughen_tunnel_floor_with_moore(map_grid, map_width, map_height)
	TunnelGen.smooth_tunnel(map_grid, map_width, map_height)

	var closest_pos = TunnelUtils.find_min_surface_tunnel_distance(map_grid, map_width, map_height)
	print("Closest surface-tunnel column at x =", closest_pos)

	TunnelConnector.carve_cave_entrance(map_grid, closest_pos, tunnel_path, map_width, map_height)

	var tunnel_path_2 = TunnelGen.carve_horizontal_tunnel(map_grid, 30, 300, 10, seed)
	var distant_x = TunnelUtils.find_distant_column(closest_pos.x, map_width, seed, 80)
	var tunnel11_y = TunnelUtils.get_tunnel_y_from_path(tunnel_path, distant_x, "floor")

	TunnelConnector.carve_cave_entrance(map_grid, Vector2i(distant_x, tunnel11_y), tunnel_path_2, map_width, map_height)
	
	var room_starts_1 = TunnelRooms.generate_tunnel_rooms(map_grid, tunnel_path, map_width, map_height, seed)
	var room_starts_2 = TunnelRooms.generate_tunnel_rooms(map_grid, tunnel_path_2, map_width, map_height, seed)

	var all_room_starts = room_starts_1 + room_starts_2
	var spawn_pos = find_valid_spawn(map_grid, closest_pos.x, map_height)
	print("spawn_pos:--------------------------------------------",spawn_pos)
	call_deferred("get_player_pos")
	RoomAnalyzer.analyze_and_decorate_rooms(map_grid, all_room_starts, spawn_pos)
	GridUtils.enclose_grid(map_grid, map_width, map_height)

	tilemap.clear()
	TilemapDraw.draw_grid_to_tilemap(tilemap, map_grid, map_width, map_height)
	
	for x in range(-3, 4):
		for y in range(-3, 4):
			tilemap.set_cell(spawn_pos + Vector2i(x,y), 0, Vector2i(1, 15))
			print("spawn_pos")

static func find_valid_spawn(grid: Array, x: int, map_height: int) -> Vector2i:
	for y in range(map_height):
		if grid[y][x] == 0 or grid[y][x] == 2:
			return Vector2i(x, y)
	return Vector2i(x, 0)  # fallback

func get_player_pos():
	print("player_spawn:-----------------------------------",Vector2i(Global.player_position))
