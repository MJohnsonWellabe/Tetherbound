extends "res://tests/test_case.gd"

## Bug fix pin (13 Nov 2026, G-things-cloudrain-r2): the High Perches court's
## stone apron stood 3 cm above the crown turf and lost the depth test in some
## views, so the court drew as bare grass with compass lines.

const PRESENTATION := preload("res://scripts/world/cloudreach_high_perches_presentation.gd")
## Landmark crowns are built 0.10 m above the landmark origin (cloudreach_world.gd `ledge_y`).
const CROWN_TOP_M := 0.10


func test_apron_top_stands_clear_of_the_crown_turf() -> void:
	var presentation: Node3D = PRESENTATION.new()
	presentation.build({})
	var apron := presentation.get_node("LandingApron") as MeshInstance3D
	var top := apron.position.y + (apron.mesh as CylinderMesh).height * 0.5
	assert_true(top >= CROWN_TOP_M + 0.10, "apron top %.3f clears the turf by 10 cm" % top)
	assert_true(top <= 0.30, "and stays a low step, not a plinth")
	for child: Node in presentation.get_children():
		if str(child.get_meta("high_perches_role", "")) == "wind_compass":
			assert_true((child as Node3D).position.y > top, "%s sits on the apron" % child.name)
	presentation.free()
