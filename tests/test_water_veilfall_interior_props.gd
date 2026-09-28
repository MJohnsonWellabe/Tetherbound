extends "res://tests/test_case.gd"

## F14#1: the Veilfall rooms named for pumps and sluices show Codex's pump
## station and sluice gates, and the Heart Chamber its authored banners
## (water_veilfall.json `interior_props`, water_veilfall.gd). Presentation
## only: every gate and pump control still exists with its flag.

const RULES := "res://data/config/water_veilfall.json"
const SCRIPT := "res://scripts/world/water_veilfall.gd"


func _rules() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(RULES))


func test_every_placed_scene_is_installed_with_its_contract_nodes() -> void:
	var props: Dictionary = _rules().interior_props
	assert_true(bool(props.enabled))
	var pump := load(str(props.pump_station.scene)) as PackedScene
	assert_ne(pump, null, "pump station installed")
	var banner := load(str(props.heart_banner.scene)) as PackedScene
	assert_ne(banner, null, "heart banner installed")
	for width: String in (props.sluice_gates.by_width as Dictionary):
		var gate := load(str(props.sluice_gates.by_width[width])) as PackedScene
		assert_ne(gate, null, "sluice gate %s installed" % width)
		if gate != null:
			var built := gate.instantiate()
			assert_ne(built.get_node_or_null(^"FixedFrame"), null, "%s has FixedFrame" % width)
			assert_ne(built.get_node_or_null(^"GateLeaf"), null, "%s has GateLeaf" % width)
			built.free()


func test_props_cover_the_real_gates_and_pump_controls() -> void:
	var rules := _rules()
	var widths: Dictionary = rules.interior_props.sluice_gates.by_width
	for gate: Dictionary in rules.gates:
		assert_true(widths.has(str(int(float(gate.width_m)))), "a sluice gate for %s" % gate.id)
	var ids: Array = []
	for control: Dictionary in rules.controls:
		ids.append(str(control.id))
	for id: Variant in rules.interior_props.pump_station.controls:
		assert_true(ids.has(str(id)), "%s is a real control" % id)
	assert_eq((rules.interior_props.heart_banner.placements as Array).size(), 2, "one banner per chamber wall")


func test_placement_keeps_colliders_prompts_and_gate_state() -> void:
	var source := FileAccess.get_file_as_string(SCRIPT)
	var start := source.find("func _place_pump_station")
	var finish := source.find("func _box(")
	assert_true(start > 0 and finish > start)
	var placement := source.substr(start, finish - start)
	for word: String in ["collision_layer", "queue_free", "set_flag", "_prompt(", "StaticBody3D.new"]:
		assert_false(placement.contains(word), "prop placement touches no %s" % word)
