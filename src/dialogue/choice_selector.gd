extends Control


var choice_controller := MainChoiceController

onready var choice_button_template: Button = $VBoxContainer/ButtonTemplate

# Called when the node enters the scene tree for the first time.
func _ready():
	visible = false
	$VBoxContainer.remove_child(choice_button_template)
	choice_controller.connect("on_branch", self, "_on_branch")

func _on_branch(choices: Array):
	for child in $VBoxContainer.get_children():
		$VBoxContainer.remove_child(child)

	for choice in choices:
		var button := choice_button_template.duplicate()
		button.get_node("Label").text = choice.label
		button.visible = true
		$VBoxContainer.add_child(button)
		button.connect("pressed", self, "_on_choice_selected", [choice.tail_node, button])
	$AnimationPlayer.play("fade_in_choices")

func _on_choice_selected(tail_node: String, _button: Button):
	for button in $VBoxContainer.get_children():
		button.disconnect("pressed", self, "_on_choice_selected")

	owner.get_node("Sounds/click").play()
	$AnimationPlayer.play("fade_out_choices")
	yield(get_tree().create_timer(0.5), "timeout")
	choice_controller.select_choice(tail_node)
