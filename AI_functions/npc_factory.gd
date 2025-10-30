extends Node

const Dialog = preload("res://quest system/Resources/Dialog/Dialog.gd")
const Quest = preload("res://quest system/Resources/Quest/Quest.gd")
## Factory helpers for creating/configuring NPCs compatible with `quest system/scripts/npc.gd`.

## create_npc
## - npc_scene_or_node: PackedScene or Node (instance of your NPC scene that uses npc.gd)
## - npc_id / npc_name: identifiers used by dialog and objectives
## - dialog_trees: Dictionary matching dialog_data.json structure per NPC (trees array)
## - quests: Array of Quest resources to attach to this NPC
## - parent: optional parent to add the NPC to the scene tree


func create_npc(
		npc_scene_or_node,
		npc_id: String,
		npc_name: String,
		dialog_trees: Array,
		quests: Array = [],
		parent: Node = null,
		persist_dialog_to_json: bool = true,
		dialog_json_path: String = "res://quest system/Resources/Dialog/dialog_data.json"
	) -> Node:
	var npc
	if npc_scene_or_node is PackedScene:
		npc = npc_scene_or_node.instantiate()
	else:
		npc = npc_scene_or_node

	# Basic identity
	if "npc_id" in npc:
		npc.npc_id = npc_id
	if "npc_name" in npc:
		npc.npc_name = npc_name

	# Link quests
	link_quests_to_npc(npc, quests)

	# Dialog resource setup
	var dialog_res: Dialog = Dialog.new()
	var dialogs_dict := {
		npc_id: {
			"name": npc_name,
			"trees": dialog_trees
		}
	}
	dialog_res.dialogs = dialogs_dict
	if "dialog_resource" in npc:
		npc.dialog_resource = dialog_res

	# Persist dialog to the shared JSON so npc.gd load_from_json keeps it consistent
	if persist_dialog_to_json:
		upsert_npc_dialog_in_json(npc_id, npc_name, dialog_trees, dialog_json_path)

	# Add to parent if provided
	if parent:
		parent.call_deferred("add_child", npc)

	return npc


func link_quests_to_npc(npc: Node, quests: Array) -> void:
	if npc and "quests" in npc:
		var filtered: Array[Quest] = []
		for q in quests:
			if q is Quest:
				filtered.append(q)
		npc.quests = filtered


## Merge or insert NPC dialog data into the shared JSON file used by Dialog.gd
## Expected JSON top-level format:
## { "<npc_id>": { "name": "<npc_name>", "trees": [ ... ] }, ... }
func upsert_npc_dialog_in_json(npc_id: String, npc_name: String, dialog_trees: Array, json_path: String) -> void:
	var existing: Dictionary = {}
	if FileAccess.file_exists(json_path):
		var raw := FileAccess.get_file_as_string(json_path)
		if raw and raw.length() > 0:
			var parsed = JSON.parse_string(raw)
			if typeof(parsed) == TYPE_DICTIONARY:
				existing = parsed

	var npc_entry := {
		"name": npc_name,
		"trees": dialog_trees
	}
	existing[npc_id] = npc_entry

	var json_text := JSON.stringify(existing, "\t")
	var file := FileAccess.open(json_path, FileAccess.WRITE)
	if file:
		file.store_string(json_text)
		file.flush()
		file.close()


## Convenience: build a simple dialog tree structure
## Example result to pass as a tree:
## { "branch_name": "intro", "dialogs": [ {"state": "start", "text": "Hello", "options": {"Bye": "exit"}} ] }
func build_dialog_tree(branch_name: String, dialogs: Array) -> Dictionary:
	return {
		"branch_name": branch_name,
		"dialogs": dialogs
	}


## Convenience: build a dialog entry
## state: e.g., "start", "offer_quest", "exit"
## options: Dictionary of text->next_state
func build_dialog_entry(state: String, text: String, options: Dictionary) -> Dictionary:
	return {
		"state": state,
		"text": text,
		"options": options
	}


# --- Placement utilities ---
# All now explicitly require tilemap argument!

## Place NPC on surface using a precomputed array of surface tile positions (Array[Vector2i]).
## - origin_x: reference tile X (e.g., player tile x)
## - distance: desired horizontal tile distance from origin
## - tile_size: world pixels per tile
## - tilemap: TileMap node for conversion
func place_npc_on_surface_from_tiles(npc: Node2D, surface_tiles: Array, origin_x: int, distance: int, tile_size: int, tilemap) -> bool:
	print("[DEBUG] place_npc_on_surface_from_tiles CALLED, tilemap:", tilemap)
	if not npc or surface_tiles.is_empty() or not tilemap:
		print("[DEBUG] NPC placement failed: npc valid? ", npc != null, ", surface_tiles empty? ", surface_tiles.is_empty(), ", tilemap valid? ", tilemap != null)
		return false
	var target_x := origin_x + distance
	var best := _find_closest_by_x(surface_tiles, target_x)
	if best == null:
		print("[DEBUG] place_npc_on_surface_from_tiles: No surface tile found for target_x=", target_x)
		return false
	# Convert grid tile to map (cell) pos for world conversion
	var cell_pos = Vector2i(best.x, tilemap.get_parent().map_height - best.y)
	var world_pos = tilemap.map_to_local(cell_pos)
	npc.position = world_pos
	print("[DEBUG] Placed NPC at tile (", best.x, ",", best.y, ") map cell = ", cell_pos, " position = ", npc.position)
	return true

## Place NPC on surface computed from a 0/1 grid (1 = solid/ground, 0 = air), using top-most solid per column.
## - grid: Array[Array[int]] shaped [height][width] or [y][x] as used in test grid utils
## - map_height: total rows
## - origin_x: reference tile x
## - distance: desired horizontal offset
## - tile_size: pixels per tile
## - tilemap: TileMap node for coordinate conversion
func place_npc_on_surface_from_grid(npc: Node2D, grid: Array, map_height: int, origin_x: int, distance: int, tile_size: int, tilemap) -> bool:
	print("[DEBUG] place_npc_on_surface_from_grid CALLED, tilemap:", tilemap)
	if not npc or grid.is_empty() or not tilemap:
		print("[DEBUG] NPC grid placement failed: npc valid? ", npc != null, ", grid empty? ", grid.is_empty(), ", tilemap valid? ", tilemap != null)
		return false
	var width = grid[0].size()
	var surface := _compute_surface_from_grid(grid, width, map_height)
	print("[DEBUG] Computing surface from grid for NPC placement. surface tiles count:", surface.size())
	return place_npc_on_surface_from_tiles(npc, surface, origin_x, distance, tile_size, tilemap)

## Convenience: place relative to player if available (and tilemap).
func place_npc_near_player_on_tiles(npc: Node2D, surface_tiles: Array, distance: int, tile_size: int, tilemap) -> bool:
	print("[DEBUG] place_npc_near_player_on_tiles CALLED, tilemap:", tilemap)
	var origin_x := 0
	if Global and Global.player:
		origin_x = int(floor(Global.player.position.x / max(1, tile_size)))
	return place_npc_on_surface_from_tiles(npc, surface_tiles, origin_x, distance, tile_size, tilemap)

## Place NPC at visual ground using global surface_tiles array.
## surf_x = desired column; map_height = map tile height; tilemap = map TileMap node.
func place_npc_on_surface_tile_with_surface_array(npc: Node2D, surf_x: int, map_height: int, tilemap) -> bool:
	var surface_tiles = Global.surface_tiles
	print("[npc_factory] Placing NPC at surf_x=", surf_x, ", map_height=", map_height, ", tilemap=", tilemap)
	if surf_x >= 0 and surf_x < surface_tiles.size() and tilemap and surface_tiles[surf_x].y != -1:
		var surf_pos = surface_tiles[surf_x] # Vector2i(x, y)
		var cell_pos = Vector2i(surf_pos.x, surf_pos.y )
		var world_pos = tilemap.map_to_local(cell_pos)
		npc.position = world_pos
		print("[npc_factory] NPC placed at surface tile:", surf_pos, " cell_pos:", cell_pos, " world_pos:", world_pos)
		return true
	else:
		print("[npc_factory] Invalid surface tile placement for surf_x=", surf_x, ", tilemap=", tilemap, ", map_height=", map_height, ", surface_tile=", surface_tiles[surf_x] if surf_x < surface_tiles.size() else "out of range")
		return false


func _find_closest_by_x(positions: Array, target_x: int) -> Vector2i:
	var best = null
	var best_dist := 1e9
	for p in positions:
		var px = (p.x if p is Vector2i else int(p[0]))
		var dist = abs(px - target_x)
		if dist < best_dist:
			best_dist = dist
			best = (p if p is Vector2i else Vector2i(px, int(p[1])))
	return best


func _compute_surface_from_grid(grid: Array, width: int, height: int) -> Array[Vector2i]:
	var surface: Array[Vector2i] = []
	# grid[y][x] with 1 as ground in your test utilities
	for x in range(width):
		var top_y := -1
		for y in range(height):
			var val := int(grid[y][x])
			if val == 1:
				top_y = y
		if top_y >= 0:
			# convert from grid row to tile coords: y is already tile row
			surface.append(Vector2i(x, top_y))
	return surface
