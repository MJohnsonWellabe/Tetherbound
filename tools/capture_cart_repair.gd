extends "res://tools/catalogue_survey.gd"

## Cart presentation only: reuse the production-world/camera survey. The second
## pair injects the repaired world flag; these frames are NOT turn-in/save proof.
## godot --path . --rendering-driver opengl3 --resolution 1280x800 \
##   --script tools/capture_cart_repair.gd -- --biome=meadows --output=<fresh-dir>

const CART_STORY := preload("res://scripts/story/story_ledger.gd")
const CART_FLAG := "band1_broken_cart_repaired"


func _load_plan() -> bool:
	if _biome_id != "meadows":
		push_error("The cart capture requires --biome=meadows")
		return false
	_planned.clear()
	for repaired: bool in [false, true]:
		for stand: Dictionary in [
			{"id": "road", "at": [85.0, 1228.0]},
			{"id": "near", "at": [74.0, 1234.0]},
			{"id": "wheel", "at": [76.0, 1239.0], "target": [80.8, 1242.3]},
		]:
			var at: Array = stand.at
			var target: Array = stand.get("target", [80.0, 1240.0])
			var toward := Vector2(float(target[0]) - float(at[0]), float(target[1]) - float(at[1]))
			_planned.append({
				"frame_id": "%s_%s" % ["repaired" if repaired else "broken", stand.id],
				"biome_id": "meadows", "band_id": "band1", "destination_index": 0,
				"destination_display_name": "Coll's cart", "position_xz": at,
				"view_heading_deg": rad_to_deg(atan2(toward.x, toward.y)),
				"time": "day", "repaired_fixture": repaired,
			})
	return true


func _begin_manifest() -> void:
	super._begin_manifest()
	_manifest["fixture_disclosure"] = "Production Meadows, trainer, HUD and camera. Debug travel and clear daylight; second pair injects the cart repaired world flag and calls production restoration. Presentation evidence only, not earned turn-in, travel, save or multiplayer proof."


func _capture_row(row: Dictionary) -> void:
	var cart := _world.get_node_or_null(^"BrokenCart")
	if cart == null:
		_failures.append("The production BrokenCart is missing")
		return
	var game := root.get_node_or_null(^"Game")
	var flags := CART_STORY.world_flags(cart, game)
	if flags == null:
		_failures.append("The world flag store is missing")
		return
	flags.call("set_flag", CART_FLAG, bool(row.repaired_fixture))
	cart.call("restore_progression_from_game", game)
	await super._capture_row(row)
