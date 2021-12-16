extends Node

signal items_changed

var items := []
var selected_item = null # Dictionary

func _ready():
	add_item({name="Magnifying Glass", image_path="res://spr/props/magnifying_glass.png"})
	
	for i in range(100):
		add_item({name="Rope#" + str(i), image_path="res://spr/util/ekans.png"})
		
	selected_item = items[0]

func add_item(item: Dictionary):
	items.push_back(item)
	emit_signal("items_changed", item, items)

func select_item(item: Dictionary):
	selected_item = item

func get_selected_item_id():
	if !selected_item: return "M" # Default to magnifying glass
	match selected_item.name.split('#')[0]:
		"Magnifying Glass":
			return "M"
		"Rope":
			return "R"
	push_warning("Could not find ID for item " + str(selected_item.name))
	return "M"
