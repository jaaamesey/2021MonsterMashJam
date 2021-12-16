extends Control

var white_outline_material := preload("res://fx/simple_white_outline.tres").duplicate()

onready var hbox: HBoxContainer = $ColorRect/ScrollContainer/HBoxContainer
onready var inventory_cursor: Control = $InventoryCursor
onready var inventory_tooltip: Label = $InventoryTooltip
onready var inventory_item_template: TextureButton = $ColorRect/ScrollContainer/HBoxContainer/InventoryItemTemplate

var item_name_to_button := {}

# Called when the node enters the scene tree for the first time.
func _ready():
	inventory_tooltip.visible = false
	for child in hbox.get_children():
		hbox.remove_child(child)
	
	MainInventoryController.connect("items_changed", self, "_update_items")
	_update_items({}, MainInventoryController.items)

func _process(_delta: float):
	var cursor_anim_spd := INF
	var selected_item: Dictionary = MainInventoryController.selected_item
	var cursor_target_pos := inventory_cursor.rect_global_position
	if selected_item:
		var selected_button: TextureButton = item_name_to_button[selected_item.name]
		cursor_target_pos.x = selected_button.rect_global_position.x
		selected_button.material = white_outline_material
		var thickness := selected_button.texture_normal.get_size().length() / 85
		selected_button.material.set_shader_param('line_thickness', thickness)

	inventory_cursor.rect_global_position = inventory_cursor.rect_global_position.move_toward(cursor_target_pos, cursor_anim_spd)
func _update_items(_item: Dictionary, items: Array):
	for child in hbox.get_children():
		hbox.remove_child(child)
		
	item_name_to_button = {}

	for item in items:
		var new_item_button := inventory_item_template.duplicate()
		new_item_button.texture_normal = load(item.image_path)
		new_item_button.connect("mouse_entered", self, "_on_item_hovered", [item, new_item_button])
		new_item_button.connect("mouse_exited", self, "_on_item_unhovered", [item, new_item_button])
		new_item_button.connect("pressed", self, "_on_item_selected", [item, new_item_button])
		hbox.add_child(new_item_button)
		item_name_to_button[item.name] = new_item_button
	
func _on_item_hovered(item: Dictionary, item_button: TextureButton):
	inventory_tooltip.visible = true
	inventory_tooltip.text = item.name
	inventory_tooltip.rect_global_position.x = item_button.rect_global_position.x - 48

func _on_item_unhovered(_item: Dictionary, _item_button: TextureButton):
	inventory_tooltip.visible = false
	
func _on_item_selected(item: Dictionary, _item_button: TextureButton):
	for child in hbox.get_children():
		child.material = null
	MainInventoryController.select_item(item)
