extends "res://tools/capture_cloudreach_frame_matrix.gd"

func _run() -> void:
	SPECIES.table()["galecrest"]["placeholder"]["model"] = "res://assets/creatures/tetherbound/galecrest/rebuild/galecrest.glb"
	await super._run()
