class_name ChoiceController
extends Node

signal on_branch

var dialogue_controller := MainDialogueController

class Choice:
	var label: String
	var tail_node: String
	
	func _to_string():
		return label + ': ' + tail_node

var choices := []

# Called when the node enters the scene tree for the first time.
func _ready():
	dialogue_controller.connect("prompting_branch", self, "_on_branch")


func _on_branch():
	var choice_names: Array = dialogue_controller.current_choice_names
	var choice_tails: Array = dialogue_controller.current_choice_tails
	assert(!choice_names.empty())
	assert(!choice_tails.empty())
	
	choices = []
	for i in range(choice_tails.size()):
		if !choice_tails[i].empty() and !choice_names[i].empty():
			var choice := Choice.new()
			choice.label = choice_names[i]
			choice.tail_node = choice_tails[i]
			choices.push_back(choice)
	
	print("Branching dialogue: ", choices)
	emit_signal("on_branch", choices)

func select_choice(tail_node: String):
	dialogue_controller.is_branching = false
	dialogue_controller.go_to_dialogue(tail_node)
