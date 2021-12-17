class_name LocationController
extends CanvasLayer

var hidden_pickup_names := []

func move_to(location_name: String):
	var prev_location: Location = get_child(0)
	var facing_direction := prev_location.current_look_direction
	prev_location.exit()
	yield(get_tree().create_timer(0.7), "timeout")
	var new_location: Location = load("res://lvl/" + location_name).instance()
	new_location.current_look_direction = facing_direction
	yield(get_tree().create_timer(0.2), "timeout")
	add_child(new_location)
	prev_location.queue_free()

func hide_pickup(name: String):
	hidden_pickup_names.push_back(name)

func show_pickup(name: String):
	hidden_pickup_names.erase(name)
