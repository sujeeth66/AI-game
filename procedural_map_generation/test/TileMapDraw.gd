static func draw_grid_to_tilemap(tilemap: TileMapLayer, grid: Array, map_width: int, map_height: int):
	for y in range(map_height):
		for x in range(map_width):
			var cell_pos = Vector2i(x, map_height - y )
			match grid[y][x]:
				1:
					tilemap.set_cell(cell_pos, 0, Vector2i(0, 1))  # solid
				2:
					tilemap.set_cell(cell_pos, 0, Vector2i(7, 0))  # cave entrances
				3:
					tilemap.set_cell(cell_pos, 0, Vector2i(0, 4))  # tunnels
				4:
					tilemap.set_cell(cell_pos, 0, Vector2i(0, 15))  # tunnel connector
				5:
					tilemap.set_cell(cell_pos, 0, Vector2i(2, 9))  # tunnel connector
				6:
					tilemap.set_cell(cell_pos, 0, Vector2i(1, 15))  # tunnel connector
				7:
					tilemap.set_cell(cell_pos, 0, Vector2i(5, 4))
