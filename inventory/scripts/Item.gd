class_name Item
extends RefCounted

var item_name: String
var item_type: String
var item_effect: String
var item_texture: CompressedTexture2D
var quantity: int = 1
var scene_path: String = ""

func _init(name: String, type: String, effect: String, texture: CompressedTexture2D, qty: int = 1, scn_path: String = ""):
	item_name = name
	item_type = type
	item_effect = effect
	item_texture = texture
	quantity = qty
	scene_path = scn_path
