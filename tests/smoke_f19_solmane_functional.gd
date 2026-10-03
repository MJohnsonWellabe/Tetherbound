extends "res://tests/smoke_cloudreach_solmane_offer_choice.gd"

func _run() -> void:
	if not preload("res://tests/helpers/f19_functional_offload.gd").configure("solmane_all_six_choices"):
		quit(2)
		return
	super._run()
