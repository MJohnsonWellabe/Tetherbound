extends "res://tests/smoke_four_biome_continuous.gd"

func _run() -> void:
	if not preload("res://tests/helpers/f19_functional_offload.gd").configure("full_fresh_campaign"):
		quit(2)
		return
	super._run()
