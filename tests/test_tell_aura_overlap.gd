extends "res://tests/test_case.gd"

## Fights close-1024: the wind-up rim glow (`telegraph.soft_style.tell_aura`,
## tell_style.gd) is one counted overlay per body. Two overlapping wind-ups
## share it, so the second keeps its glow when the first ends, and the glow
## lifts only with the last one. A hit flash (body_glow.gd) landing mid-tell
## still flashes, borrowing the glowing meshes and handing them back.

const STYLE := preload("res://scripts/combat/tell_style.gd")
const BODY_GLOW := preload("res://scripts/vfx/body_glow.gd")
const STYLE_ON := {"tell_aura": 0.3}


class Body extends Node3D:
	var pivot := Node3D.new()

	func _init() -> void:
		add_child(pivot)
		for index in 2:
			var mesh := MeshInstance3D.new()
			mesh.mesh = BoxMesh.new()
			pivot.add_child(mesh)

	func model_pivot() -> Node3D:
		return pivot


func _meshes(body: Body) -> Array:
	return body.pivot.get_children()


func _all_overlaid(body: Body, material: Material) -> bool:
	for mesh: MeshInstance3D in _meshes(body):
		if mesh.material_overlay != material:
			return false
	return true


func test_second_overlapping_wind_up_keeps_the_glow_after_the_first_ends() -> void:
	var body := Body.new()
	var first := STYLE.apply_aura(body, Color("#b16cff"), STYLE_ON)
	assert_true(first == body, "the first wind-up takes the body's meshes")
	var glow: Material = (_meshes(body)[0] as MeshInstance3D).material_overlay
	assert_true(STYLE.is_live_aura(glow), "the overlay is the live tell aura")
	var second := STYLE.apply_aura(body, Color("#b16cff"), STYLE_ON)
	assert_true(second == body, "an overlapping wind-up shares the glow rather than drawing nothing")
	STYLE.clear_aura(first)
	assert_true(_all_overlaid(body, glow), "the second wind-up still glows after the first ends")
	STYLE.clear_aura(second)
	assert_true(_all_overlaid(body, null), "the glow lifts with the last wind-up")
	assert_false(body.has_meta(STYLE.AURA_META))
	body.free()


func test_hit_flash_mid_wind_up_flashes_and_hands_the_glow_back() -> void:
	var body := Body.new()
	var held := STYLE.apply_aura(body, Color("#b16cff"), STYLE_ON)
	var glow: Material = (_meshes(body)[0] as MeshInstance3D).material_overlay
	var flash: Node = BODY_GLOW.attach(body, BODY_GLOW.Mode.FLASH, {"duration": 0.1}, 0.85)
	assert_true(flash != null, "a hit landing mid-tell still flashes the body")
	assert_eq(int(flash.call("mesh_count")), 2, "the flash covers every glowing mesh")
	flash.call("advance", 0.2)
	assert_true(_all_overlaid(body, glow), "the wind-up glow returns once the flash ends")
	# A flash that outlives the wind-up must not restore a dead glow.
	var late: Node = BODY_GLOW.attach(body, BODY_GLOW.Mode.FLASH, {"duration": 0.1}, 0.85)
	STYLE.clear_aura(held)
	late.call("advance", 0.2)
	assert_true(_all_overlaid(body, null), "no glow is left behind after the wind-up ended")
	body.free()


func test_aura_off_takes_nothing() -> void:
	var body := Body.new()
	assert_true(STYLE.apply_aura(body, Color.WHITE, {"tell_aura": 0.0}) == null)
	assert_true(_all_overlaid(body, null))
	body.free()
