extends AudioStreamPlayer

var starting_volume := -20

func _ready():
	volume_db = starting_volume
	play(0)

func _process(delta):
	volume_db += 10 * delta
	volume_db = clamp(volume_db, starting_volume, 0)

