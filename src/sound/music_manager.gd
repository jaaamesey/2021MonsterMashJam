extends AudioStreamPlayer

const MUSIC_BANK_DIR : String = "res://snd/mus/random_music_bank/"

enum {
	SHUFFLE,
	REPEAT,
	ONCE
}

var random_music_bank : Array = []
var current_index : int = 0
var behaviour := SHUFFLE

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# LOAD MUSIC
	# Get file names of random music from folder
	var music_file_names : Array = []
	# Note: you can't list files in a directory on release builds for some reason.
	if OS.is_debug_build() and System.build_cache:
		music_file_names = Utils.list_files_in_directory(MUSIC_BANK_DIR, "ogg")
		System.music_cache["music_file_names"] = music_file_names
	else:
		music_file_names = System.music_cache["music_file_names"]

	# Shuffle song selection on startup
	randomize()
	music_file_names = Utils.shuffle_list(music_file_names)

	# Fill random music bank with array of resources
	random_music_bank.clear()
	for file_name in music_file_names:
		var song_resource : AudioStream = load(MUSIC_BANK_DIR + file_name)
		random_music_bank.append(song_resource)

	# Connect signals
	connect("finished", self, "go_to_next_song")

	# Don't play music until told to
	# (use go_to_next_song() to start when needed)

func _input(_event: InputEvent) -> void:
	# Keyboard audio controls (DEBUG ONLY)
	if !OS.is_debug_build():
		return

	if Input.is_action_just_pressed("skip_song"):
		go_to_next_song()
	if Input.is_action_just_pressed("fade_song_in"):
		fade_in()
	if Input.is_action_just_pressed("fade_song_out"):
		fade_out()

var fade_amt = 0
# TODO: Convert magic numbers to consts
func _process(delta: float) -> void:
	if volume_db < -25:
		volume_db = -100

	volume_db += fade_amt * delta

	# Clamp volume to 1
	if volume_db > 1:
		volume_db = 1
func fade_out(speed : float = 5):
	fade_amt = 25 / -speed

func fade_in(speed : float = 5):
	if volume_db < -18:
		volume_db = -18
	fade_amt = 25 / speed

func pause_music():
	stream_paused = true

func unpause_music():
	stream_paused = false

func play_song(song_name : String, desired_behaviour := REPEAT):
	if !has_node(song_name):
		push_error("Song " + song_name + " not found.")
		return

	var song_stream : AudioStreamPlayer = get_node(song_name)
	stream = song_stream.stream
	play(0)

	behaviour = desired_behaviour

func go_to_next_song() -> void:
	unpause_music()
	if behaviour == ONCE:
		return

	if behaviour == REPEAT:
		play()
		return

	if current_index < random_music_bank.size() - 1:
		current_index += 1
	else:
		current_index = 0
	stream = random_music_bank[current_index]

	play()

func set_behaviour(desired := SHUFFLE):
	behaviour = desired
