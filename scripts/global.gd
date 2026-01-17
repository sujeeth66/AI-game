extends Node

# 🌍 Global Variables
var player_position: Vector2 = Vector2.ZERO
var can_move : bool = true

#main.gd
var all_tunnel_tiles := {}
var tunnel_exclusion_sets := []
var surface_tiles = []
var map_height = 0
var map_width = 0

var global_quest_ui : Control
var global_quest_manager : Node2D
var active_quests = {}
var player: CharacterBody2D 
