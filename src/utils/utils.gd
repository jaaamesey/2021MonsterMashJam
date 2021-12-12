extends Node

var current_camera = null
#var player = null

var _input_buffer = {}
var _input_buffer_blacklist = []
var _buffering_inputs = false

func _ready():
	pause_mode = PAUSE_MODE_PROCESS
	set_process_input(true)

func _input(event):
	# Buffer inputs if paused
	if _buffering_inputs and (event is InputEventKey or event is InputEventJoypadButton or event is InputEventMouseButton):
		var event_actions = get_actions_from_event(event)
		for action in event_actions:
			_input_buffer[action] = event.pressed



func freeze(seconds, buffer_inputs = true):
	if buffer_inputs:
		_buffering_inputs = true
	get_tree().paused = true
	if seconds == -1:
		return
	yield(get_tree().create_timer(seconds), "timeout")
	get_tree().paused = false
	if buffer_inputs:
		apply_buffered_inputs()
		_buffering_inputs = false


func unfreeze():
	get_tree().paused = false

func freeze_node(node, seconds, buffer_inputs = false):
	if buffer_inputs:
		_buffering_inputs = true
	node.set_process(false)
	node.set_physics_process(false)
	node.set_physics_process_internal(false)
	node.set_process_input(false)

	var node_axis_lock_linear_x
	var node_axis_lock_linear_y
	var node_axis_lock_linear_z

	if node is RigidBody or node is RigidBody2D:
		node_axis_lock_linear_x = node.axis_lock_linear_x
		node_axis_lock_linear_y = node.axis_lock_linear_y
		node_axis_lock_linear_z = node.axis_lock_linear_z
		node.axis_lock_linear_x = true
		node.axis_lock_linear_y = true
		node.axis_lock_linear_z = true
	if seconds == -1:
		return
	yield(get_tree().create_timer(seconds), "timeout")
	node.set_process(true)
	node.set_physics_process(true)
	node.set_physics_process_internal(true)
	node.set_process_input(true)

	if node is RigidBody or node is RigidBody2D:
		node.axis_lock_linear_x = node_axis_lock_linear_x
		node.axis_lock_linear_y = node_axis_lock_linear_y
		node.axis_lock_linear_z = node_axis_lock_linear_z

	if buffer_inputs:
		apply_buffered_inputs()
		_buffering_inputs = false

func unfreeze_node(node):
	node.set_process(true)
	node.set_physics_process(true)
	node.set_physics_process_internal(true)
	node.set_process_input(true)

func shake_camera(amount, duration):
	current_camera.shake(amount, duration)

func get_actions_from_event(event):
	# This returns multiple items because each event can have multiple actions.
	var actions = []
	for action in InputMap.get_actions():
		if InputMap.action_has_event(action, event):
			actions.append(action)
	return actions

func apply_buffered_inputs(apply_release_events = true):
	for event in _input_buffer:
		if _input_buffer_blacklist.has(event) or event.substr(0,2) == "ui":
			# Ignore action event if ui or blacklisted
			# (Note: this is fine because inputs with multiple actions
			# are added to the array per action.)
			continue
		if _input_buffer[event] == true:
			Input.action_press(event, 1.0)
		elif apply_release_events:
			Input.action_release(event)
	_input_buffer.clear()


static func get_distance_between_nodes(a, b):
	if a is Spatial:
		return a.global_transform.origin.distance_to(b.global_transform.origin)
	else: # If Node2D or something
		return a.position.distance_to(b.position)

static func shuffle_list(list):
	var shuffled_list := []
	var index_list := range(list.size())
	for _i in range(list.size()):
		var x := randi() % index_list .size()
		shuffled_list.append(list[index_list[x]])
		index_list.remove(x)
	return shuffled_list

# WARNING: THIS FUNCTION BREAKS ON RELEASE BUILDS FOR NON-TEXT FILES
static func list_files_in_directory(path, extension = "") -> Array:
	var files := []
	var dir := Directory.new()
	dir.open(path)
	dir.list_dir_begin()

	while true:
		var file := dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			if file.ends_with(extension) or extension == "":
				files.append(file)

	dir.list_dir_end()

	return files

static func get_random_line_from_file(file_path : String, allow_blank := false) -> String:
	randomize()
	var file := File.new()
	file.open(file_path, file.READ)

	var line_counter := 0

	# Get number of lines
	while !file.eof_reached():
		line_counter += 1
		file.get_line()

	file.seek(0)

	var random_last_line = randi() % line_counter

	var stored_line : String = ""

	for _i in range(0,random_last_line):
		var line : String = file.get_line().strip_edges()
		if line != "":
			stored_line = line

	if !allow_blank and stored_line == "":
		return get_random_line_from_file(file_path)

	return stored_line
