@tool
extends Node2D

@export var item_quantity = 1
@export var item_type = ""
@export var item_name = ""
@export var item_texture : Texture
@export var item_effect = ""
var scene_path = "res://inventory/scenes/game_item.tscn"
@onready var item_sprite: Sprite2D = $Sprite2D

var player_in_range = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not Engine.is_editor_hint():
		item_sprite.texture = item_texture
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not Engine.is_editor_hint():
		item_sprite.texture = item_texture
		
	if player_in_range and Input.is_action_just_pressed("interact"):
		pickup_item(item_quantity)
		

func pickup_item(item_quantity):
	var item = {
		"quantity" : item_quantity,
		"item_type" : item_type,
		"item_name" : item_name,
		"item_texture" : item_texture,
		"item_effect" : item_effect,
		"scene_path" : scene_path
	}
	
	if Global.player:
		InventoryGlobal.add_item(item,false)
		self.queue_free()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		body.inventory_canvas.visible = true

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		body.inventory_canvas.visible = false
		
func set_item_data(data):
		item_type = data["item_type"]
		item_name = data["item_name"]
		item_texture = data["item_texture"]
		item_effect = data["item_effect"]

func initiate_items(quantity,name, type, effect, texture):
	item_quantity = quantity
	item_name = name
	item_type = type
	item_effect = effect
	item_texture = texture
