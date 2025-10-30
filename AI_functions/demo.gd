extends Node

const QuestFactory = preload("res://AI_functions/quest_factory.gd")
const NPCFactory = preload("res://AI_functions/npc_factory.gd")

var map_main = null
func _ready() -> void:
	print("[demo.gd] _ready() running!")
	var root = get_tree().current_scene
	var found_map_node = null
	if root and root.has_signal("map_generation_finished"):
		found_map_node = root
	else:
		for n in root.get_children():
			if n.has_signal("map_generation_finished"):
				found_map_node = n
				break
	if found_map_node:
		found_map_node.connect("map_generation_finished", Callable(self, "_on_map_ready"))
		print("[demo.gd] Connected to map_generation_finished signal on: ", found_map_node)
	else:
		print("[demo.gd] Still can't find a map node with map_generation_finished signal! root is: ", root)

func _on_map_ready():
	print("[demo.gd] Map generation finished, proceeding with NPC creation and placement.")
	var qf = QuestFactory.new()
	var npcf = NPCFactory.new()

	# Create the quest
	var demo_quest = qf.create_quest(
		"quest_demo_collect",
		"Collect Slime Gel",
		"Gather 3 Slime Gels for the alchemist.",
		[
			{"id": "obj_collect_gel", "description": "Collect 3 Slime Gel", "objective_type": "collection", "target_name": "Slime Gel", "required_quantity": 3}
		],
		[
			{"reward_type": "coins", "reward_amount": 75}
		]
	)
	print("[demo.gd] Created demo quest:", demo_quest)

	# Build dialog
	var intro_tree = npcf.build_dialog_tree("intro", [
		npcf.build_dialog_entry("start", "Greetings! Care to help the alchemist?", {"Sure": "offer_quest", "No": "exit"}),
		npcf.build_dialog_entry("offer_quest", "Bring me 3 Slime Gels.", {"Okay": "exit"})
	])
	print("[demo.gd] Built demo dialog tree.")

	# Create NPC from scene
	var npc_scene: PackedScene = load("res://quest system/scenes/NPC.tscn")
	var root = get_tree().current_scene
	print("[demo.gd] Root for NPC:", root)
	var npc = npcf.create_npc(
		npc_scene,
		"npc_demo_alchemist",
		"Alchemist",
		[intro_tree],
		[demo_quest],
		root,
		true,
		"res://quest system/Resources/Dialog/dialog_data.json"
	)
	print("[demo.gd] NPC instance created:", npc)

	# Place the NPC using the global surface_tiles and correct world mapping
	var tilemap = null
	if root.has_node("TileMapLayer"):
		tilemap = root.get_node("TileMapLayer")
		print("[demo.gd] Found TileMapLayer node!")
	else:
		print("[demo.gd] TileMapLayer node NOT found on root!")
		
	var map_height = Global.map_height
	
	if npc and tilemap != null and map_height != null:
		var surf_x = 20  # demo column, can be randomized or set per need
		var ok = npcf.place_npc_on_surface_tile_with_surface_array(npc, surf_x, map_height, tilemap)
		if ok:
			print("[demo.gd] NPC placed on surface_tiles at x=", surf_x)
		else:
			print("[demo.gd] NPC placement on surface_tiles failed at x=", surf_x)
	else:
		print("[demo.gd] Not placing NPC. npc=", npc, ", tilemap=", tilemap, ", map_height=", map_height)
	print("[demo.gd] _on_map_ready complete.")
