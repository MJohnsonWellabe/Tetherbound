extends SceneTree

const HUD := preload("res://scenes/combat/combat_hud.tscn")
const LAYOUT_SMOKE := preload("res://tests/smoke_combat_hud_left_column.gd")
const TOKENS := preload("res://scripts/ui/ui_tokens.gd")
var failures: Array[String] = []


func _init() -> void:
	_run()


func _run() -> void:
	await process_frame
	root.size = Vector2i(1920, 1080)
	var hud := HUD.instantiate()
	root.add_child(hud)
	hud.set_process(false)
	var ally := hud.get_node("Root/AllyPanel") as Control
	var strip := hud.get("_party_strip") as Control
	ally.show()
	strip.call("update_from_party", LAYOUT_SMOKE.PARTY, 0)
	for i in 8:
		await process_frame
	var target: Vector2 = hud.call("_party_strip_position")
	var old_rest := target + Vector2(0.0, 60.0)
	strip.call("set_rest_position", old_rest)
	strip.call("set_pinned", true)
	var tween: Tween = strip.get("_tween")
	tween.pause()
	tween.custom_step(TOKENS.T_PARTY_REVEAL * 0.25)
	var offset := strip.position - old_rest
	var alpha := strip.modulate.a
	_check(offset.y > 0.0 and offset.y < 12.0, "fixture samples a partially completed reveal")
	strip.call("set_rest_position", target)
	_check(strip.position.is_equal_approx(target + offset), "reflow preserves relative reveal offset")
	_check(is_equal_approx(strip.modulate.a, alpha), "reflow preserves alpha")
	_check(strip.get("_tween") == tween and tween.is_valid(), "reflow preserves the existing tween")
	_check(not strip.get_global_rect().intersects(ally.get_global_rect()), "actual panels clear during reveal")
	tween.custom_step(TOKENS.T_PARTY_REVEAL * 0.25)
	_check(strip.position.y > target.y and strip.position.y < target.y + offset.y, "next sample follows the new rest position")
	tween.custom_step(TOKENS.T_PARTY_REVEAL * 0.5 + 0.001)
	_check(strip.position.is_equal_approx(target), "reveal finishes at updated rest within original duration")
	_check(is_equal_approx(strip.modulate.a, 1.0), "reveal finishes fully opaque")
	strip.call("set_rest_position", target)
	_check(strip.position.is_equal_approx(target), "repeated rest update does not drift")
	_check(not strip.get_global_rect().intersects(ally.get_global_rect()), "final actual panels do not overlap")
	print("party strip reflow: roster %s, active plate %s" % [strip.get_global_rect(), ally.get_global_rect()])
	for failure in failures:
		push_error(failure)
	print("PASS: moving rest during reveal preserves animation and clearance" if failures.is_empty() else "FAIL: party strip reflow")
	quit(0 if failures.is_empty() else 1)


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
