extends "res://tools/art_pipeline/capture_creature_clips.gd"

func _run() -> void:
	SPECIES.table()["galecrest"]["placeholder"]["model"] = "res://assets/creatures/tetherbound/galecrest/rebuild/galecrest.glb"
	await super._run()
