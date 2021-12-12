extends Node

func play_sound(sound_name : String) -> void:
	if !has_node(sound_name):
		push_warning("Sound " + sound_name + " not found in SoundManager.")
		return
	var sound_stream : AudioStreamPlayer = get_node(sound_name)
	sound_stream.bus = "SFX"
	sound_stream.play(0)
