class_name Location
extends Control

signal selection_changed

var current_look_direction := "Forward"
var props_under_cursor := []
var can_click_on_prop := false
onready var location_controller: Node = get_parent()

# Called when the node enters the scene tree for the first time.
func _ready():
	$BlackOverlay.color = Color.black
	$TurnAroundButton.connect("pressed", self, "_turn_around")
	_update_look_dir()
	$BlackOverlay/AnimationPlayer.play("fade_in")
	can_click_on_prop = true

func _process(delta):
	for child in $Directions.get_node(current_look_direction).get_node("Pickups").get_children():
		if location_controller.hidden_pickup_names.has(child.name):
			child.visible = false
		
func _input(_event):
	if Input.is_action_just_released("click") and can_click_on_prop and !$TurnAroundButton.pressed:
		var selected_prop = get_selected_prop()
		if selected_prop:
			_on_prop_clicked(selected_prop)

func _turn_around():
	if current_look_direction == "Forward":
		current_look_direction = "Backward"
	else:
		current_look_direction = "Forward"
	
	$TurnAroundButton.disabled = true
	can_click_on_prop = false
	$BlackOverlay/AnimationPlayer.play("fade_out")
	yield(get_tree().create_timer(0.7), "timeout")
	_update_look_dir()
	$BlackOverlay/AnimationPlayer.play("fade_in")
	yield(get_tree().create_timer(0.3), "timeout")
	$TurnAroundButton.disabled = false
	can_click_on_prop = true
	
func _update_look_dir():
	for child in $Directions.get_children():
		child.visible = false
	$Directions.get_node(current_look_direction).visible = true
	props_under_cursor = []

func _on_prop_clicked(selected_prop: String):
	var selected_inventory_item_prefix: String = MainInventoryController.get_selected_item_id()
	var dialogue_to_go_to := selected_inventory_item_prefix + "_" + selected_prop.split('#')[0]

	if MainDialogueController.is_id_valid(dialogue_to_go_to):
		MainDialogueController.go_to_dialogue(dialogue_to_go_to)
	else:
		var fallback := selected_inventory_item_prefix + "_FAIL"
		if MainDialogueController.is_id_valid(fallback):
			MainDialogueController.go_to_dialogue(fallback)
		else:
			MainDialogueController.go_to_dialogue("GEN_FAIL")

func get_selected_prop():
	if props_under_cursor.size() > 0:
		return props_under_cursor[0]
	else:
		return null

func select_prop(name: String):
	props_under_cursor.push_back(name)
	emit_signal("selection_changed")

func deselect_prop(name: String):
	props_under_cursor.erase(name)
	emit_signal("selection_changed")

func exit():
	$TurnAroundButton.disabled = true
	can_click_on_prop = false
	$BlackOverlay/AnimationPlayer.play("fade_out")
