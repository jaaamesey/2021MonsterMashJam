class_name ChoiceManagerOld
extends Control

# NOTE: Cactus game only supports 2 or 3 choices per branch for design reasons.
# Obviously this class can be rewritten in the future to support more.
const MAX_CHOICES : int = 3

onready var dbox: DialogueBox = owner.get_node("FrontUI/DialogueBox")
onready var dbox_anim_player : AnimationPlayer = get_parent().get_node("DialogueBoxAnimationPlayer")
onready var all_choice_buttons : Array = [$TopChoice, $MiddleChoice, $BottomChoice]

# The index for this trio of variables really, really matters. They are very tightly coupled.
# It's a bit weird but it's the most simple way I could think of.
var available_choice_names : Array = [] # Stores the actual available choices
var available_choice_tails : Array = [] # (i.e. no empty or invalid ones)
var available_choice_buttons : Array = [] # Stores refs to the buttons dedicated for each choice.

var prev_focus : Control = null

func _ready() -> void:
	# Pass reference to self to DialogueManager
	#DialogueManager.choice_manager = self

	# Connect signals for choice buttons
	for choice in all_choice_buttons:
		var choice_btn : Button = choice.get_node("Button")
		choice_btn.connect("focus_entered", self, "on_choice_button_focus", [choice_btn.get_parent()])
		choice_btn.connect("mouse_entered", self, "on_choice_button_focus", [choice_btn.get_parent()])
		choice_btn.connect("pressed", self, "on_choice_button_pressed", [choice_btn.get_parent()])

func _process(delta: float) -> void:
	if !DialogueManager.is_branching:
		visible = false
		return

	var default_choice : Button =  all_choice_buttons[1].get_node("Button")
	if available_choice_buttons.size() == 3:
		default_choice = all_choice_buttons[0].get_node("Button")
	if default_choice.get_focus_owner() == null:
		# Ensure there is always focus
		default_choice.grab_focus()
		
	# Scale button text appropriately if there is an overflow
	for button in available_choice_buttons:
		var label : Label = button.get_node("Label")
		var font : DynamicFont = label.get("custom_fonts/font")
		
		font.size = 24
		font.extra_spacing_top = 0
		
		var text_h_size : int = label.get_combined_minimum_size().x
		if text_h_size > 475:
			var new_font_size = int((-6.0/211.0) * text_h_size + 7498.0/211.0)
			new_font_size = clamp(new_font_size, 16, 24)
			font.size = new_font_size
			if font.size < 18:
				font.extra_spacing_top = 4


# Mouse/key hover - purely cosmetic
func on_choice_button_mouse_hover(choice_btn) -> void:
	choice_btn.grab_click_focus()

func on_choice_button_focus(choice_btn) -> void:
	if dbox.is_blocked():
		return
	for c in all_choice_buttons:
		c.color = "060606"
		var label : Label = c.get_node("Label")
		label.set("custom_colors/font_color", "ffffff")
	choice_btn.color = "ffffff"
	var label : Label = choice_btn.get_node("Label")
	label.set("custom_colors/font_color", "060606")

	if prev_focus != choice_btn:
		$Sounds/hover.play()
	prev_focus = choice_btn

func on_choice_button_pressed(choice_btn) -> void:
	if dbox.is_blocked():
		return
	$Sounds/click.play()
	dbox_anim_player.play_backwards(dbox_anim_player.current_animation)
	yield(get_tree().create_timer(0.6), "timeout")
	var chosen_index : int = -1
	for i in range(available_choice_names.size()):
		if available_choice_buttons[i] == choice_btn:
			chosen_index = i
			break
	var tail_to_go_to : String = available_choice_tails[chosen_index]
	DialogueManager.current_choice_names = []
	DialogueManager.current_choice_tails = []
	DialogueManager.is_branching = false
	DialogueManager.go_to_dialogue(tail_to_go_to)

	var dialogue_box : DialogueBox = get_parent().get_node("DialogueBox")
	dialogue_box.handle_new_dialogue()

func prompt_choices() -> void:
	# Clear available choices and UI refs before adding to array
	available_choice_names.clear()
	available_choice_tails.clear()
	available_choice_buttons.clear()

	for i in range(DialogueManager.current_choice_names.size()):
		var c_name : String = DialogueManager.current_choice_names[i]
		var c_tail : String = DialogueManager.current_choice_tails[i]
		if c_name.strip_edges() != "" and DialogueManager.dialogue_dictionary.has(c_tail):
			# Both name and tail are valid
			# Only append if not exceeding limit. Otherwise, throw error and ignore.
			if available_choice_names.size() < MAX_CHOICES:
				available_choice_names.append(c_name)
				available_choice_tails.append(c_tail)
			else:
				var error_msg := "ERROR: Exceeded limit of " + str(MAX_CHOICES) + "choices. "
				error_msg += "\n Ignoring combo " + c_name + " | " + c_tail
				push_warning(error_msg)

		elif c_name.strip_edges() != "" or c_tail.strip_edges() != "":
			# This error is pushed if one part of the name/tail combo is missing.
			# If it is invalid on both sides, it is just assumed empty, and no
			# error will occur.
			var error_msg := "ERROR: Invalid name/tail combo: " + c_name + " | " + c_tail
			error_msg += "\nWill ignore."
			push_warning(error_msg)

	# Data for valid choices has now been stored
	# Throw error and return if empty (only need to check one array)
	if available_choice_names.empty():
		push_warning("ERROR: No valid choices for this branch. This is very bad.")
		return

	# Handle UI based on how many choices there are
	# Get UI button refs
	var is_invalid_choice_count : bool = false
	match available_choice_names.size():
		2:
			# Will use only MiddleChoice and BottomChoice
			available_choice_buttons.append($MiddleChoice)
			available_choice_buttons.append($BottomChoice)

			$MiddleChoice.get_node("Button").focus_neighbour_top = $MiddleChoice.get_node("Button").get_path()
			$MiddleChoice.get_node("Button").focus_previous = $MiddleChoice.get_node("Button").get_path()
		3:
			available_choice_buttons.append($TopChoice)
			available_choice_buttons.append($MiddleChoice)
			available_choice_buttons.append($BottomChoice)

			$MiddleChoice.get_node("Button").focus_neighbour_top = $TopChoice.get_node("Button").get_path()
			$MiddleChoice.get_node("Button").focus_previous = $TopChoice.get_node("Button").get_path()

		_:
			# Can't handle anything else for design and UI reasons. Return if this is the case.
			push_warning("ERROR: Interface not implemented for choice count of " + str(available_choice_names.size()))
			is_invalid_choice_count = true

	if is_invalid_choice_count:
		return

	# Update button stuff for each available choice
	for i in range(available_choice_names.size()):
		var c_name : String = available_choice_names[i]
		var c_button : Control = available_choice_buttons[i]

		c_button.get_node("Label").text = c_name


	# Finally play open choices animation
	dbox_anim_player.play("open_choices_" + str(available_choice_names.size()))
