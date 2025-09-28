extends Control

@onready var item_icon: Sprite2D = $InnerBorder/ItemIcon
@onready var item_quantity: Label = $InnerBorder/ItemQuantity
@onready var details_panel: ColorRect = $DetailsPanel
@onready var item_name: Label = $DetailsPanel/ItemName
@onready var item_effect: Label = $DetailsPanel/ItemEffect
@onready var item_type: Label = $DetailsPanel/ItemType
@onready var usage_panel: ColorRect = $UsagePanel
@onready var assign_button: Button = $UsagePanel/AssignButton
@onready var outer_border: ColorRect = $OuterBorder

signal drag_start(slot)
signal drag_end()

var item = null
var slot_index = -1
var is_assigned = false

func _ready() -> void:
	usage_panel.visible = false
	details_panel.visible = false

func set_slot_index(new_index):
	slot_index = new_index

func _on_item_button_mouse_entered() -> void:
	if item != null:
		usage_panel.visible = false
		details_panel.visible = true

func _on_item_button_mouse_exited() -> void:
	details_panel.visible = false
	
func set_empty():
	item_icon.texture = null
	item_quantity.text = ""
	
func set_item(new_item):
	item = new_item
	item_icon.texture = new_item["item_texture"]
	item_quantity.text = str(item["quantity"])
	item_name.text = str(item["item_name"])
	item_type.text = str(item["item_type"])
	#print(item)
	if item["item_effect"] != "":
		item_effect.text = str( "+ " , item["item_effect"])
	else:
		item_effect.text = ""
	update_assignment_status()
	
func _on_drop_button_pressed() -> void:
	if item != null:
		InventoryGlobal.remove_item(item["item_name"])
		InventoryGlobal.remove_item_from_hotbar(item["item_name"])
		usage_panel.visible = false
		
func _on_use_button_pressed() -> void:
	usage_panel.visible = false
	
	if item != null and Global.player and item["item_effect"] != "" :
		Global.player.apply_item_effect(item)
		InventoryGlobal.remove_item(item["item_name"])
		InventoryGlobal.remove_item_from_hotbar(item["item_name"])
	else:
		pass
	
func update_assignment_status():
	is_assigned = InventoryGlobal.is_item_assigned_to_hotbar(item)
	if is_assigned:
		assign_button.text = "Unassign"
	else:
		assign_button.text = "Assign"

func _on_assign_button_pressed() -> void:
	if item != null:
		if is_assigned:
			InventoryGlobal.unassign_hotbar_item(item["item_name"])
			is_assigned = false
		else:
			InventoryGlobal.add_item(item,true)
			is_assigned = true
		update_assignment_status()


func _on_item_button_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			if item != null:
				usage_panel.visible = !usage_panel.visible
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.is_pressed():
				outer_border.modulate = Color(1,1,0)
				drag_start.emit(self)
			else:
				outer_border.modulate = Color(1,1,1)
				drag_end.emit()
