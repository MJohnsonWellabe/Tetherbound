extends "res://tests/test_case.gd"

const FINALE := preload("res://scripts/world/cloudreach_finale_controller.gd")
const FLAGS := preload("res://autoload/progression_state.gd")
const CHAPTER := preload("res://scripts/world/realm_chapter_progression.gd")


func _chapter() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://data/config/cloudreach_chapter.json"))


func _controller(flags: RefCounted) -> Node3D:
	var controller := FINALE.new()
	controller.setup(flags, func(event: String) -> Dictionary:
		return CHAPTER.dispatch(flags, _chapter(), event), Callable(), Callable())
	return controller


func _unlock(flags: RefCounted) -> void:
	for flag: String in FINALE.read_config()["requires_flags"]:
		flags.call("set_flag", flag)


func test_production_win_is_required_and_idempotent() -> void:
	var flags := FLAGS.new()
	var finale := _controller(flags)
	assert_false(finale.encounter_started("captain_veyra_storm_anchor"))
	_unlock(flags)
	assert_false(finale.encounter_won("captain_veyra_storm_anchor"), "Unstarted callback cannot grant victory")
	assert_false(finale.encounter_started("ordinary_trainer"))
	assert_true(finale.encounter_started("captain_veyra_storm_anchor"))
	assert_false(finale.encounter_started("captain_veyra_storm_anchor"))
	assert_eq(finale.phase, "crosswind_command")
	finale.opposition_remaining("captain_veyra_storm_anchor", 2, 3)
	assert_eq(finale.phase, "crosswind_command")
	finale.opposition_remaining("captain_veyra_storm_anchor", 1, 3)
	assert_eq(finale.phase, "anchor_overload")
	finale.opposition_remaining("captain_veyra_storm_anchor", 0, 3)
	assert_false(flags.has("captain_veyra_defeated"), "Zero count is not a production win callback")
	var emitted: Array = []
	finale.captain_defeated.connect(func() -> void: emitted.append("win"))
	assert_true(finale.encounter_won("captain_veyra_storm_anchor"))
	assert_eq(finale.phase, "break_the_eye")
	assert_false(finale.encounter_won("captain_veyra_storm_anchor"))
	assert_eq(emitted, ["win"])
	assert_false(flags.has("storm_anchor_network_disabled"))
	assert_false(flags.has("realm_key_water"))
	finale.free()


func test_save_restores_partial_relays_and_repairs_only_completed_network() -> void:
	var flags := FLAGS.new()
	_unlock(flags)
	flags.set_flag("captain_veyra_defeated")
	var relays: Array = FINALE.read_config()["relays"]
	flags.set_flag(str(relays[0]["flag_id"]))
	var loaded := FLAGS.new()
	loaded.load_data(JSON.parse_string(JSON.stringify(flags.save_data())))
	var finale := _controller(loaded)
	assert_eq(finale.phase, "break_the_eye")
	assert_true(finale.presentation_state()["relays_disabled"]["west"])
	assert_false(finale.presentation_state()["relays_disabled"]["east"])
	assert_false(loaded.has("storm_anchor_network_disabled"))
	for relay: Dictionary in relays:
		loaded.set_flag(str(relay["flag_id"]))
	finale.sync_progression()
	assert_true(loaded.has("storm_anchor_network_disabled"))
	assert_eq(finale.phase, "awaiting_restoration")
	assert_false(finale.presentation_state()["hazards_active"])
	assert_false(loaded.has("cloudreach_winds_restored"), "Relays cannot invent witnessed aftermath")
	assert_false(loaded.has("realm_key_water"))
	loaded.set_flag("cloudreach_winds_restored")
	finale.sync_progression()
	assert_true(finale.presentation_state()["natural_wind_trails"])
	assert_false(finale.presentation_state()["waterward_visible"], "Reward conversation is separate")
	loaded.set_flag("waterward_route_revealed")
	finale.sync_progression()
	assert_true(finale.presentation_state()["waterward_visible"])
	var revision: int = loaded.revision
	finale.sync_progression()
	assert_eq(loaded.revision, revision)
	finale.free()


func test_hazards_rotate_telegraph_and_preserve_three_lee_pockets() -> void:
	var flags := FLAGS.new()
	_unlock(flags)
	var finale := _controller(flags)
	finale.encounter_started("captain_veyra_storm_anchor")
	var centre: Vector3 = finale.position
	assert_eq(finale.hazard_at(centre, 0.5)["wind"], Vector3.ZERO)
	assert_eq(finale.hazard_at(centre, 0.5)["wind_stage"], "telegraph")
	assert_true((finale.hazard_at(centre, 2.0)["wind"] as Vector3).length() > 0.0)
	assert_ne(finale.hazard_at(centre, 2.0)["wind"], finale.hazard_at(centre, 3.0)["wind"])
	assert_eq(finale.hazard_at(centre, 5.0)["wind_stage"], "recovery")
	assert_eq(finale.hazard_at(centre - Vector3.UP * 30, 2.0)["wind"], Vector3.ZERO)
	assert_eq(finale.hazard_at(centre + Vector3.RIGHT * 70, 2.0)["wind"], Vector3.ZERO)
	finale.opposition_remaining("captain_veyra_storm_anchor", 1, 3)
	for lee: Dictionary in finale.config["lee_pockets"]:
		for time: float in [0.0, 2.0, 7.2, 30.0]:
			var sample: Dictionary = finale.hazard_at(centre + FINALE.vec(lee["offset"]), time)
			assert_true(sample["sheltered"])
			assert_eq(sample["wind"], Vector3.ZERO)
			assert_eq(sample["arc"], Vector3.ZERO)
	var angle := deg_to_rad(2.0 * float(finale.config["relay_arc"]["rotation_degrees_per_second"]))
	var arc_position := centre + Vector3(cos(angle), 0, sin(angle)) * 16.0
	assert_true((finale.hazard_at(arc_position, 2.0)["arc"] as Vector3).length() > 0.0)
	assert_eq(finale.hazard_at(arc_position, 0.0)["arc"], Vector3.ZERO)
	finale.free()


func test_older_unearned_save_cannot_infer_a_captain_win_from_relay_flags() -> void:
	var flags := FLAGS.new()
	_unlock(flags)
	for relay: Dictionary in FINALE.read_config()["relays"]:
		flags.set_flag(str(relay["flag_id"]))
	var finale := _controller(flags)
	assert_eq(finale.phase, "dormant")
	assert_false(flags.has("captain_veyra_defeated"))
	assert_false(flags.has("storm_anchor_network_disabled"))
	finale.free()
