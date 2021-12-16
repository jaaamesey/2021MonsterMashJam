extends CanvasLayer

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
	
