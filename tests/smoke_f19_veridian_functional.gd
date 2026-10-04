extends "res://tests/smoke_veridian_offer_choice.gd"

func _run() -> void:
	if not preload("res://tests/helpers/f19_functional_offload.gd").configure("veridian_choice_driver"):
		quit(2)
		return
	super._run()
