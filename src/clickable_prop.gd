extends Area2D

var white_outline_material := preload("res://fx/simple_white_outline.tres").duplicate()

onready var location: Location = owner


# Called when the node enters the scene tree for the first time.
func _ready():
	$Sprite.material = null
	connect("mouse_entered", self, "_on_hover")
	connect("mouse_exited", self, "_on_unhover")
	location.connect("selection_changed", self, "_on_selection_changed")

func _on_hover():
	location.select_prop(name)

	
func _on_unhover():
	location.deselect_prop(name)


func _on_selection_changed():
	if location.get_selected_prop() == name and name != "ded":
		$Sprite.material = white_outline_material
		var thickness: float = $Sprite.texture.get_size().length() / 85 
		$Sprite.material.set_shader_param('line_thickness', thickness)
	else:
		$Sprite.material = null
