extends SceneTree

## How long a full bake-resolution pass over the heightfield costs, with and
## without the river in the config. Written for SE21 because the first bake
## after the river landed did not finish inside ten minutes, and "the river
## made it slow" needed to be a measurement rather than a guess.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")


func _init() -> void:
	var config: Dictionary = HEIGHTFIELD.load_config()
	_time("with river", config)
	var without := config.duplicate(true)
	without.erase("river")
	_time("without river", without)
	quit(0)


func _time(label: String, config: Dictionary) -> void:
	var field: RefCounted = HEIGHTFIELD.new(config)
	var start := Time.get_ticks_msec()
	var count := 0
	# A quarter of the bake's 512x512 grid, evenly spread over the same world.
	for pz in 256:
		var z := -256.0 + pz * 2.0
		for px in 256:
			field.call("height_at", -256.0 + px * 2.0, z)
			count += 1
	var ms := Time.get_ticks_msec() - start
	print("%-14s %d samples in %d ms -> a 512x512 bake pass is ~%.1fs" % [
		label, count, ms, ms * 4.0 / 1000.0])
