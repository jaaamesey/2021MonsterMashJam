extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	MainDialogueController.go_to_dialogue("END")

func _process(delta):
	print(MainDialogueController.current_dialogue_block)
	if !MainDialogueController.current_dialogue_block or MainDialogueController.current_dialogue_block.empty() or MainDialogueController.current_dialogue_block["key"] == "THE_END":
		$EndScreen.visible = true
