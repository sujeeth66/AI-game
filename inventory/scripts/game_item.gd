@tool
extends Node2D

@export var item_quantity = 1
@export var item_type = ""
@export var item_name = ""
@export var item_texture: CompressedTexture2D
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
		
func pickup_item(item_quantity: int) -> void:
	var item = Item.new(item_name, item_type, item_effect, item_texture, item_quantity, scene_path)
	if Global.player:
		InventoryGlobal.add_item(item, false)
		self.queue_free()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		body.inventory_canvas.visible = true

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		body.inventory_canvas.visible = false
		
func set_item_data(data: Item) -> void:
	item_type = data.item_type
	item_name = data.item_name
	item_texture = data.item_texture
	item_effect = data.item_effect
 
func initiate_items(quantity: int, name: String, type: String, effect: String, texture: Texture) -> void:
	item_quantity = quantity
	item_name = name
	item_type = type
	item_effect = effect
	item_texture = texture
