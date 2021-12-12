extends Node
# Should be set to false on export
var build_cache : bool = false

const BLANK_CONFIG_DICT : Dictionary = {
	"_meta" : {}
}

var config_dict : Dictionary = {}

var music_cache : Dictionary = {}

func _ready():
	if !OS.is_debug_build():
		build_cache = false
	# Determine if shouldn't build cache
	if build_cache:
		# Test if this produces an empty array
		var test_dir : String = "res://spr/backgrounds/"
		var file_names : Array = Utils.list_files_in_directory(test_dir, ".jpg")
		if file_names.empty():
			print("Empty test directory: will not build directory cache")
			build_cache = false

	# Open music cache if release build
	if !OS.is_debug_build() or !build_cache:
		var file : File = File.new()
		file.open("res://music_cache.txt", file.READ)
		music_cache = parse_json(file.get_as_text())
		file.close()

	if build_cache:
		print("BUILD CACHE ENABLED: REMEMBER TO DISABLE BEFORE EXPORT")

	Engine.target_fps = 180

	if OS.get_name() == "HTML5":
		_HTML5_ready()

	if !OS.is_debug_build():
		OS.window_fullscreen = true

	load_config()


func _HTML5_ready():

	pass

func _notification(what):
	if what in [MainLoop.NOTIFICATION_WM_QUIT_REQUEST, MainLoop.NOTIFICATION_CRASH]:
		on_quit(what)
		get_tree().quit() # default behavior

func _input(event):
	if event.is_action_pressed("toggle_fullscreen"):
		OS.window_fullscreen = !OS.window_fullscreen

const CONFIG_DIR : String = "user://config.json"

func load_config():
	var file : File = File.new()
	if !file.file_exists(CONFIG_DIR):
		file.close()
		create_new_blank_config()
		print("New blank config created: No file")
		return

	file.open(CONFIG_DIR, File.READ)

	var json : String = file.get_as_text()

	var parsed_json = parse_json(json)
	if !(parsed_json is Dictionary):
		file.close()
		create_new_blank_config()
		print("New blank config created: Invalid file")
		return

	config_dict = parsed_json
	file.close()

func save_config():
	var file : File = File.new()
	file.open(CONFIG_DIR, File.WRITE)
	file.store_string(JSON.print(config_dict, " "))
	file.close()

func create_new_blank_config():
	var file : File = File.new()
	file.open(CONFIG_DIR, File.WRITE)
	file.store_string(JSON.print(BLANK_CONFIG_DICT, " "))
	file.close()

func on_quit(what : int = -1):
	save_config()
	if OS.is_debug_build() and build_cache:
		# Save music cache
		var file := File.new()
		file.open("res://music_cache.txt", file.WRITE)
		file.store_line(JSON.print(music_cache," "))
		file.close()

	# Print how the game quit
	match what:
		MainLoop.NOTIFICATION_CRASH:
			print("GAME CRASHED: on_quit() performed successfully")
		_:
			print("Game closed successfully.")
