# DialogueController
# ------------------------------------
# Handles loading dialogue from poopliga/json files and provides methods for
# moving forward and branching in dialogue, as well as getting dialogue data.

# Despite being treated as a Singleton in most cases, other parallel
# instances of this class could also be run without issue.

class_name DialogueController

extends Node

signal dialogue_change
signal prompting_branch

var dialogue_dictionary : Dictionary = {}
var current_dialogue_block : Dictionary = {}

var current_character : String = "" # Stored in memory to prevent empty strings from changing character

var current_choice_names : Array = []
var current_choice_tails : Array = []

var is_branching : bool = false

var past_dialogue_str : String = "" # Formats all past dialogue as a script

var variable_dict : Dictionary = {} # For setting and getting custom dialogue variables

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	dialogue_dictionary = load_dialogue_dictionary("res://txt/test_dialogue.poopliga")
	current_dialogue_block = dialogue_dictionary["START"]

# A function that just tests out the current dialogue in the command line. Useful for debugging.
func test_dialogue():
	var i : int = 0
	while i < dialogue_dictionary.size():
		go_to_next_dialogue()

		if is_branching:
			for choice_idx in range(current_choice_tails.size()):
				if current_choice_tails[choice_idx] != "":
					print(str(choice_idx) + " | " + current_choice_names[choice_idx] + " : " + current_choice_tails[choice_idx])
		print(get_current_character() + ": " + get_current_text())
		i += 1

# Goes to the next dialogue, as defined by the data of the current dialogue block.
# Will return an error if there is no data available or if not currently in dialogue.
func go_to_next_dialogue():
	# Initial error check
	if current_dialogue_block.empty():
		push_warning("ERROR: Can't go to next dialogue because current dialogue does not exist.")
		return

	# Clear choice data
	current_choice_names = []
	current_choice_tails = []

	# Finally set the current dialogue block to the next
	var next_id : String = current_dialogue_block["tail"]
	if next_id.empty():
		push_warning("End of dialogue!")
		return
	go_to_dialogue(next_id)

# Goes to the dialogue of a certain id. Returns an error if block does not exist.
func go_to_dialogue(id : String):
	# Error checks
	if is_branching:
		push_warning("ERROR: Can't go to next dialogue because dialogue is branching.")
		return

	if !dialogue_dictionary.has(id):
		push_warning("ERROR: Dialogue with id " + current_dialogue_block["tail"] + " could not be found")
		return

	var previous_block : Dictionary = current_dialogue_block
	current_dialogue_block = dialogue_dictionary[id]

	# Handle branch block stuff
	var block_extra_data : Dictionary = current_dialogue_block["data"]
	# If branch block (i.e. if branch data is found), get branch data and signify that it's time to branch
	# TODO: Implement stuff here for putting logic in branches instead of words
	if block_extra_data.has("tails") and block_extra_data.has("choices"):
		current_choice_names = block_extra_data["choices"]
		current_choice_tails = block_extra_data["tails"]

		# Print errors if any tails are invalid (empty just means they aren't shown)
		for t in current_choice_tails:
			var tail : String = str(t)
			if tail != "" and !dialogue_dictionary.has(tail):
				push_warning("ERROR: Branch block contains invalid tail ID: " + tail)
		is_branching = true
		emit_signal("prompting_branch")
		return

	# Handle regular old dialogue blocks
	is_branching = false # Can't branch on a regular dialogue block

	# Update character
	var previous_character : String = current_character
	if current_dialogue_block["char"] != "":
		current_character = current_dialogue_block["char"]

	# Handle any necessary text replacements
	# Restore text to original if already replaced
	if current_dialogue_block.has("raw_text"):
		current_dialogue_block["text"] = current_dialogue_block["raw_text"]

	var bracket_pos : int = current_dialogue_block["text"].find("<")
	if bracket_pos != -1:
		# Store original text before replacing
		current_dialogue_block["raw_text"] = current_dialogue_block["text"]
		handle_text_replacement(bracket_pos)

	# Handle storing to log
	# WORKAROUND FOR APPEND COMMAND
	# If block set to append, append instead of the other stuff
	var append_to_current : bool = false

	# Check previous block for auto_append_next and current_block for append
	for command in get_commands(previous_block):
		if command == "auto_append_next":
			append_to_current = true

	if !append_to_current: # If not already appending
		for command in get_commands():
			if command == "append":
				append_to_current = true

	if append_to_current:
		past_dialogue_str += current_dialogue_block["text"]
	else:
		# Store character name if not blank
		var char_str : String = ""

		if current_character != previous_character:
			if current_character in ["-", "."]:
				char_str = "\n  \n"
			else:
				char_str = "\n" + current_character.to_upper() + "\n"

		var spacer : String = "\n\n"
		if past_dialogue_str == "":
			spacer = ""
		past_dialogue_str += spacer + char_str + current_dialogue_block["text"]
		if past_dialogue_str.ends_with("\n"):
			past_dialogue_str = past_dialogue_str.strip_edges()

	emit_signal("dialogue_change")

func handle_text_replacement(start_pos : int = 0):
	var text : String = current_dialogue_block["text"]
	var regex := RegEx.new()
	regex.compile("<(.*?)>")
	var matches : Array = regex.search_all(text, start_pos)
	for m in matches:
		var to_replace : String = m.strings[0]
		current_dialogue_block["text"] = text.replace(to_replace, get_text_replacement(to_replace))

func get_text_replacement(to_replace : String) -> String:
	match to_replace:
		"<RANDOM_BILL_NAME>":
			return Utils.get_random_line_from_file("res://txt/bill_names.txt")
		_:
			push_warning("WARNING: No text replacement implemented for " + to_replace)
			return to_replace

func get_commands(block : Dictionary = current_dialogue_block) -> Array:
	var output : Array = []
	var extra_data : Dictionary = block["data"]

	if extra_data.has("command"):
		var commands : Array = extra_data["command"].split(";")
		for command in commands:
			command = command.strip_edges()
			if command != "":
				output.append(command)
	return output

# Returns a dialogue dictionary from a poopliga/json file.
# Allows either a String path or File as a parameter.
func load_dialogue_dictionary(file) -> Dictionary:
	# Allow function to be called with file path instead of file itself
	# if called with string
	if file is String:
		var file_to_get : File = File.new()
		file_to_get.open(file, File.READ)
		# Finally make file an actual file instead of a path string
		file = file_to_get

	# Load json as dictionary
	var dict = parse_json(file.get_as_text())
	file.close()
	return dict

# Getters
func get_current_text() -> String:
	return current_dialogue_block["text"]

# Returns the current character. Passing a value of true will make it return
# the actual character data from the current dialogue block, which can be
# blank. Leave the parameters empty unless you know what you are doing.
func get_current_character(get_from_block_data : bool = false) -> String:
	if get_from_block_data:
		return current_dialogue_block["char"]
	return current_character

func get_current_id():
	return current_dialogue_block["key"]

func get_current_extra_data() -> Dictionary:
	return current_dialogue_block["data"]

func get_var(key : String):
	if variable_dict.has(key):
		return variable_dict[key]
	return null

func set_var(key : String, value):
	variable_dict[key] = value

func has_var(key : String):
	if variable_dict.has(key) and variable_dict[key] != "":
		return true
	return false

func has_valid_tail() -> bool:
	return dialogue_dictionary.has(current_dialogue_block["tail"])

func is_end_of_dialogue() -> bool:
	return current_dialogue_block["tail"].empty()
