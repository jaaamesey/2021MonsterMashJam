extends Control

var starting := false
var overlay_fade_dir := -1
var seconds_elapsed := 0.0

func _ready():
	$BlackOverlay.visible = true

func _process(delta):
	seconds_elapsed += delta
	$BlackOverlay.modulate.a += overlay_fade_dir * delta
	$BlackOverlay.modulate.a = clamp($BlackOverlay.modulate.a, 0, 1)
	

func _input(event):
	if Input.is_action_just_pressed("start_game") and !starting and seconds_elapsed > 1.4:
		starting = true
		overlay_fade_dir = 1
		$AudioStreamPlayer.play()
		yield(get_tree().create_timer(3), "timeout")
		get_tree().change_scene("res://lvl/main_game.tscn")

