class_name DialogueBox
extends Control

export(NodePath) var dialogue_rich_text_label_path
export(NodePath) var character_label_path
export(NodePath) var done_indicator_path
export(NodePath) var skip_indicator_path
export(NodePath) var next_button_path
export(NodePath) var blip_sound_path
export(NodePath) var click_sound_path
export(NodePath) var location_controller_path

#onready var config_control = get_parent().owner.get_node("MenuLayer/Config")
#onready var log_control = get_parent().owner.get_node("MenuLayer/Log")

onready var dialogue_rich_text_label: RichTextLabel = get_node(dialogue_rich_text_label_path)
onready var character_label: Label = get_node(character_label_path)
onready var done_indicator: Control = get_node(done_indicator_path)
onready var skip_indicator: Control = get_node(skip_indicator_path)
onready var next_button: Button = get_node(next_button_path)
onready var blip_sound: AudioStreamPlayer = get_node(blip_sound_path)
onready var click_sound: AudioStreamPlayer = get_node(click_sound_path)
onready var location_controller = get_node(location_controller_path)

var dialogue_controller := MainDialogueController

const DEFAULT_DIALOGUE_SPD : float = 31.0

# Timers (all timers are measured in seconds)
const SKIP_DIALOGUE_TIMER_TIME : float = 1.0/30.0

var pause_timer : float = 0

var is_externally_paused : bool = false

var block_log_on_debug : bool = true
var fast_forward_on_skip : bool = true
var skip_fast_forward_spd : float = 5.0

var auto_go_to_next : bool = false
var append_current_block : bool = false
var append_next_block : bool = false

var visible_characters : float = 0.0 # Float to allow for slower speeds

# Timers
var skip_dialogue_timer : float = 0.0

# Note: bbcode_text should only be used when getting text from the dialogue manager itself

func _ready() -> void:
	visible = false

	# Force visibility refresh to prevent size-related bugs
	dialogue_rich_text_label.visible = false
	dialogue_rich_text_label.visible = true

	dialogue_rich_text_label.bbcode_text = get_current_bbcode_text()
	character_label.text = ""
	done_indicator.visible = false
	skip_indicator.visible = false

	next_button.connect("button_up", self, "on_next_pressed")
	dialogue_controller.connect("dialogue_change", self, "handle_new_dialogue")

	set_process(false)
	#visible = true
	yield(get_tree().create_timer(0.75), "timeout")
	set_process(true)
	
	dialogue_controller.go_to_dialogue("START")

func _process(delta: float) -> void:
	# Clamp delta to prevent skipping punctuation slowdown
	delta = clamp(delta, 0, Engine.time_scale * 1.0/60.0)

	var is_keyboard_skip_held := Input.is_key_pressed(KEY_CONTROL) and Input.is_mouse_button_pressed(BUTTON_LEFT)
	var is_gamepad_skip_held := Input.is_action_pressed("skip_dialogue") and (Input.is_action_pressed("next_dialogue") or Input.is_mouse_button_pressed(BUTTON_LEFT))
	var is_skipping : bool = visible and (is_keyboard_skip_held or is_gamepad_skip_held)

	if is_blocked():
		is_skipping = false

	# Quick hack for making time go faster when skipping dialogue
	skip_indicator.visible = false
	Engine.set_time_scale(1)

	if is_externally_paused:
		return

	if is_skipping:
		skip_indicator.visible = true
		if fast_forward_on_skip:
			Engine.set_time_scale(skip_fast_forward_spd)

	if pause_timer > 0:
		done_indicator.visible = false
		pause_timer -= delta
		return

	if dialogue_rich_text_label.visible_characters < dialogue_rich_text_label.text.length():
		done_indicator.visible = false
		tick_dialogue(delta)
	else:
		if auto_go_to_next or (Input.is_action_just_released("next_dialogue") and !is_blocked()):
			auto_go_to_next = false
			on_next_pressed()
		if !auto_go_to_next:
			done_indicator.visible = true

	if is_skipping:
		if skip_dialogue_timer <= 0:
			on_next_pressed(false)
			dialogue_rich_text_label.visible_characters = dialogue_rich_text_label.bbcode_text.length()
			skip_dialogue_timer = SKIP_DIALOGUE_TIMER_TIME * skip_fast_forward_spd

	if skip_dialogue_timer > -1:
		skip_dialogue_timer -= delta

func tick_dialogue(delta : float) -> void:
	if !dialogue_controller.current_dialogue_block:
		return

	if dialogue_controller.get_current_text().strip_edges() == "" or dialogue_controller.get_current_text().empty():
		on_next_pressed(false, true)
		return

	var tick_amount : float = 1
	# Handle slowing down at punctuation
	var prev_char_index : int = dialogue_rich_text_label.visible_characters
	var prev_char : String = dialogue_rich_text_label.text[prev_char_index - 1]

	match prev_char:
		',':
			tick_amount = 0.1
		';':
			tick_amount = 0.1
		':':
			tick_amount = 0.1
		'.':
			if prev_char_index < dialogue_rich_text_label.text.length() and dialogue_rich_text_label.text[prev_char_index] == ' ':
				tick_amount = 0.04
				
		'-':
			if prev_char_index < dialogue_rich_text_label.text.length() and dialogue_rich_text_label.text[prev_char_index] == ' ':
				tick_amount = 0.04
		'!':
			tick_amount = 0.04
		'?':
			tick_amount = 0.04

	# Special case for not pausing at Mr. and Mrs. and stuff
	# 2 substrings have to be used because for some reason the bottom one doesn't pick up on
	# two letter strings. Yes, this is a hack.
	# TODO: Make this less hacky.
	var prefix_substr3 : String = dialogue_rich_text_label.text.substr(prev_char_index - 3, 3)
	var prefix_substr4 : String = dialogue_rich_text_label.text.substr(prev_char_index - 4, 3)

	# Search for nearby prefixes
	var prefix_found : bool = false
	for prefix in ["Mr", "Mrs", "Mx", "Dr", "Ms", "Sgt", "Lt"]:
		if prefix in prefix_substr3 or prefix in prefix_substr4:
			prefix_found = true

	# Go at normal speed if a prefix is found
	if prefix_found:
		tick_amount = 1

	# Go at normal speed if just starting dialogue
	if visible_characters <= 1:
		tick_amount = 1

	visible_characters += tick_amount * DEFAULT_DIALOGUE_SPD * delta

	var current_char : String = dialogue_rich_text_label.text[int(dialogue_rich_text_label.visible_characters) - 1]
	var next_char : String = dialogue_rich_text_label.text[int(dialogue_rich_text_label.visible_characters)]
	# Play blip
	if dialogue_rich_text_label.visible_characters != int(visible_characters):
		if current_char != ' ':
			blip_sound.play()

	var chars_until_done : int = len(dialogue_rich_text_label.text) - dialogue_rich_text_label.visible_characters
	if next_char == " " and chars_until_done <= 1:
		visible_characters = len(dialogue_rich_text_label.text) + 1


	dialogue_rich_text_label.visible_characters = int(visible_characters)

	# Skip next dialogue if empty
	if dialogue_controller.has_valid_tail() and (dialogue_controller.get_current_text().strip_edges() == "" or dialogue_controller.get_current_text().empty()):
		on_next_pressed()
		return


func on_next_pressed(play_sound := true, force := false) -> void:
	if !force and dialogue_rich_text_label.visible_characters < dialogue_rich_text_label.text.length():
		return

	if dialogue_controller.is_branching:
		return

	var is_previous_dialogue_blank : bool = dialogue_controller.get_current_text() == ""
	var is_previous_appended_to : bool = append_next_block
	var is_previous_auto : bool = auto_go_to_next

	dialogue_controller.go_to_next_dialogue()
	handle_new_dialogue()
	if play_sound and (dialogue_controller.is_branching or !is_previous_dialogue_blank):
		if !is_previous_auto and !is_previous_appended_to:
			click_sound.play(0.01)

func handle_new_dialogue() -> void:
	visible = true
	if dialogue_controller.is_branching: # Keep existing text if branching
		return
		
	if dialogue_controller.current_dialogue_block.empty():
		visible = false
		return

	# Handle individual dialogue logic stuff here
	var extra_data : Dictionary = dialogue_controller.get_current_extra_data()
	# TOP LEFT MESSAGE
	if extra_data.has("Top Left Message"):
		var front_layer : CanvasLayer = get_parent().owner.get_node("FrontLayer")
		var new_text : String = extra_data["Top Left Message"]
		front_layer.get_node("TopLeftBanner/Label").text = new_text
		front_layer.get_node("FrontAnimPlayer").play("top_left_anim")

	# PAUSE TIMER
	# TODO: Maybe don't have it pause when skipping
	if extra_data.has("Pause"):
		var pause_timer_time : String = extra_data["Pause"]
		pause_timer = float(pause_timer_time)

	if append_next_block:
		append_current_block = true
		append_next_block = false

	# COMMANDS
	for command in dialogue_controller.get_commands():
		handle_command(command)

	# Force auto command if text is blank and not branching
	if dialogue_controller.get_current_text() == "" and !dialogue_controller.is_branching:
		auto_go_to_next = true

	# Finally do dialogue box stuff
	if append_current_block:
		dialogue_rich_text_label.bbcode_text += get_current_bbcode_text()
		append_current_block = false
	else:
		visible_characters = 0
		dialogue_rich_text_label.visible_characters = int(visible_characters)
		dialogue_rich_text_label.bbcode_text = get_current_bbcode_text()

	character_label.text = dialogue_controller.current_character
	if character_label.text in ["-", "."]:
		character_label.text = ""

# TODO: Move command handling code out of dialogue box
func handle_command(command : String):
	command = command.strip_edges()
	# Get parameters
	var regex : RegEx = RegEx.new()
	var regex_str : String = "\\((.*)\\)"
	regex.compile(regex_str)
	var regex_match : RegExMatch = regex.search(command)
	var parameters : Array = []
	if regex_match != null:
		parameters = regex_match.strings[1].split(",")
		for param in parameters:
			param = param.strip_edges()
	# Remove parameters from command
	command = command.split("(")[0]
	command = handle_aliases(command)
	# Finally match the command
	match command:
		"hide": # hide(time, pause = true)
			visible = false
			if len(parameters) != 0:
				var hide_time: float = float(parameters[0])
				if len(parameters) < 2: # If no second parameter, make it true.
					parameters.append("true")
				# Pause if not specified and a longer pause timer is not already active
				if pause_timer < hide_time + 0.5 and parameters[1] == "true":
					pause_timer = hide_time + 0.5
				# Make visible after period of time
				yield(get_tree().create_timer(hide_time), "timeout")
				visible = true
		"show":
			visible = true
		"auto":
			auto_go_to_next = true
		"append":
			append_current_block = true
		"auto_append_next": # Same as having this block have auto and the next having append. A very useful shortcut.
			auto_go_to_next = true
			append_next_block = true
		"set": # Used to set custom variables. TODO: Allow these to be used
			dialogue_controller.variable_dict[parameters[0]] = parameters[1]
		"increment":
			if len(parameters) < 2:
				parameters.append("1")
			var initial : String = dialogue_controller.variable_dict[parameters[0]]
			var output : float = float(initial) + float(parameters[1])
			dialogue_controller.variable_dict[parameters[0]] = output
		"decrement":
			if len(parameters) < 2:
				parameters.append("1")
			var initial : String = dialogue_controller.variable_dict[parameters[0]]
			var output : float = float(initial) - float(parameters[1])
			dialogue_controller.variable_dict[parameters[0]] = output

		"go_to":
			dialogue_controller.go_to_dialogue(str(parameters[0]))

		"set_checkpoint":
			if len(parameters) < 1:
				dialogue_controller.variable_dict["checkpoint"] = dialogue_controller.get_current_id()
			else:
				dialogue_controller.variable_dict["checkpoint"] = parameters[0]

		"game_over":
			if !dialogue_controller.variable_dict.has("checkpoint"):
				dialogue_controller.variable_dict["checkpoint"] = "START"
			visible = false
			dialogue_controller.go_to_dialogue(dialogue_controller.variable_dict["checkpoint"])
			Engine.time_scale = 0
			pause_timer += 2
			yield(get_tree().create_timer(2), "timeout")
			visible = true
			Engine.time_scale = 1
		"fade_out_music":
			if len(parameters) == 0:
				MusicManager.fade_out()
			else:
				MusicManager.fade_out(float(parameters[0]))
		"fade_in_music":
			if len(parameters) == 0:
				MusicManager.fade_in()
			else:
				MusicManager.fade_in(float(parameters[0]))
		"play_sound":
			SoundManager.play_sound(parameters[0])
		"play_music":
			MusicManager.play_song(parameters[0])
		"set_music_behaviour":
			var behaviour : int = MusicManager.SHUFFLE
			if parameters.empty():
				parameters.append("shuffle")
			match parameters[0].to_lower():
				"shuffle":
					behaviour = MusicManager.SHUFFLE
				"once":
					behaviour = MusicManager.ONCE
				"repeat":
					behaviour = MusicManager.REPEAT

			MusicManager.set_behaviour(behaviour)
		"move_to":
			var location_name: String = parameters[0]
			location_controller.move_to(location_name)
		"take":
			var object_name: String = parameters[0]
			var inventory_name: String = parameters[1]
			var already_has_item := false
			for item in MainInventoryController.items:
				if item.name == inventory_name:
					already_has_item = true
			
			if !already_has_item:
				MainInventoryController.add_item({ name=inventory_name, image_path=("res://spr/props/" + object_name + ".png") })
				location_controller.hide_pickup(object_name)
		"hide_obj":
			var object_name: String = parameters[0]
			location_controller.hide_pickup(object_name)
		"show_obj":
			var object_name: String = parameters[0]
			location_controller.show_pickup(object_name)
		_:
			push_warning("Unimplemented command: " + command)

func handle_aliases(command : String):
	match command:
		"play_song":
			return "play_music"
		"fade_music_in":
			return "fade_in_music"
		"fade_music_out":
			return "fade_out_music"
		"add":
			return "increment"
		"subtract":
			return "decrement"

	return command

func get_current_bbcode_text() -> String:
	return dialogue_controller.get_current_text()

func is_blocked() -> bool: # Returns whether or not input is blocked by something else
	return false
	#if (!OS.is_debug_build() || block_log_on_debug):# && log_control.visible:
	#	return true
	#return config_control.visible
