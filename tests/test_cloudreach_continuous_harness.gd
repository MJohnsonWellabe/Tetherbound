extends "res://tests/test_case.gd"

const HARNESS_PATH := "res://tests/smoke_cloudreach_continuous.gd"
const OBSERVATORY_SMOKE_PATH := "res://tests/smoke_cloudreach_observatory_join.gd"
const VOSS_SMOKE_PATH := "res://tests/smoke_cloudreach_voss_join.gd"
const SUMMIT_SMOKE_PATH := "res://tests/smoke_cloudreach_summit_road.gd"
const SUMMIT_BIVOUAC_SMOKE_PATH := "res://tests/smoke_cloudreach_summit_bivouac_join.gd"
const CAPTAIN_APPROACH_SMOKE_PATH := "res://tests/smoke_cloudreach_captain_approach.gd"
const WILD_LEASH_SMOKE_PATH := "res://tests/smoke_cloudreach_wild_leash.gd"
const MOBILE_OCCUPANCY_SMOKE_PATH := "res://tests/smoke_cloudreach_mobile_occupancy.gd"
const WATERWARD_OVERLOOK_SMOKE_PATH := "res://tests/smoke_cloudreach_waterward_overlook_join.gd"
const LOWER_FORAGER_SMOKE_PATH := "res://tests/smoke_cloudreach_lower_forager_detour.gd"
const POST_CAMP_SMOKE_PATH := "res://tests/smoke_cloudreach_post_camp_locomotion.gd"
const POST_RELAY_SMOKE_PATH := "res://tests/smoke_cloudreach_post_relay_exit.gd"
const PERSISTENCE_TAIL_SMOKE_PATH := "res://tests/smoke_cloudreach_persistence_tail.gd"
const WORLD_PATH := "res://scripts/world/cloudreach_world.gd"
const SUMMIT_PRESENTATION_PATH := "res://scripts/world/cloudreach_summit_presentation.gd"
const YARDS_PATH := "res://scripts/world/cloudreach_battle_yards.gd"
const DIRECTOR_PATH := "res://scripts/combat/cloudreach_encounter_director.gd"
const SCENE_RUNTIME_PATH := "res://data/config/cloudreach_scene_runtime.json"


func _source() -> String:
	return FileAccess.get_file_as_string(HARNESS_PATH)


func _function_body(source: String, name: String, next_name: String) -> String:
	var start := source.find("func " + name + "(")
	var finish := source.find("func " + next_name + "(", start + 1)
	return source.substr(start, finish - start)


func test_live_combat_uses_shared_input_pilot_and_keeps_lethal_seam_outside_live_branch() -> void:
	var source := _source()
	assert_true(source.contains("--live-combat"), "continuous route has no explicit live-combat mode")
	assert_true(source.contains("BALANCE.InputPilot.new"), "live route drifted from the shared balance InputPilot")
	var battle := _function_body(source, "_battle", "_team_snapshot")
	var live_start := battle.find("if live_combat:", battle.find("await _capture(stage)"))
	var mechanics_start := battle.find("var rounds:=0", live_start)
	var live_branch := battle.substr(live_start, mechanics_start - live_start)
	assert_true(live_branch.contains("combat_pilot.fight_to_the_end()"), "live branch does not drive real combat input")
	assert_true(live_branch.contains("battle_losses.count"), "live branch does not preserve the production loss callback")
	assert_true(live_branch.contains("LIVE_BATTLE_FRAME_LIMIT"), "live branch has no bounded timeout")
	assert_false(live_branch.contains("take_damage"), "live branch contains the mechanics-only lethal seam")
	assert_false(live_branch.contains("_award_victory"), "live branch directly awards victory")
	assert_false(live_branch.contains("_begin_resolve"), "live branch directly selects an outcome")
	assert_true(battle.find("_normal_input_clock(\"live combat from challenge input through outcome")
		< battle.find("await _interact(prompt)"), "normal 1x clock does not begin before challenge input")


func test_live_recovery_is_controller_bed_and_sleep_input_without_direct_heal() -> void:
	var source := _source()
	var recovery := _function_body(source, "_recover_party_through_camp_input", "_injured_party_indices")
	assert_true(recovery.contains("CampCreatureBed"), "live recovery does not use the authored creature bed")
	assert_true(recovery.contains("_tap(\"ui_accept\")"), "live recovery does not assign through controller UI")
	assert_true(recovery.contains("await _interact(rest_prompt"), "live recovery does not use the player rest prompt")
	assert_false(recovery.contains("heal_fully"), "live recovery heals a member directly")
	assert_false(recovery.contains("home_recovery"), "live recovery calls the recovery helper directly")
	assert_false(source.contains("player.global_position ="), "continuous route writes the player's position")


func test_reports_separate_live_acceptance_from_mechanics_only_evidence_and_exact_reload() -> void:
	var source := _source()
	assert_true(source.contains("\"passed\":route_complete and live_combat"),
		"mechanics-only completion can still be labeled acceptance")
	assert_true(source.contains("mechanics_only_test_lethal"), "legacy lethal evidence is not labeled mechanics-only")
	assert_true(source.contains("party_differences.is_empty()"),
		"final reload does not compare every persisted member field")
	assert_true(source.contains("paused=true") and source.contains("paused=false"),
		"exact persistence observation can race real-time creature condition decay")
	assert_true(source.contains('"persistence_party_diff"'),
		"exact reload failures do not identify the per-member changed fields")
	assert_true(source.contains("_flag_snapshot() == saved_flags"),
		"final reload does not compare the exact flag set")
	assert_true(source.contains("_inventory_snapshot() == saved_inventory"),
		"final reload does not compare occupied inventory slots")
	assert_true(source.contains("not game.can_enter_realm(\"water\")"),
		"Waterward non-entry is not asserted")


func test_observatory_join_uses_thin_crown_and_regression_has_no_post_spawn_warp() -> void:
	var world_source := FileAccess.get_file_as_string(WORLD_PATH)
	assert_true(world_source.contains("\"old_wind_observatory\", \"summit_eyrie_stronghold\""),
		"the tall observatory geology still owns collision")
	assert_true(world_source.contains("\"ObservatoryWalkableCrown\""),
		"the grounded observatory endpoint has no thin crown support")
	var smoke := FileAccess.get_file_as_string(OBSERVATORY_SMOKE_PATH)
	assert_true(smoke.contains("_navigate(Vector3(430.0, 920.0, 4500.0))"),
		"regression does not traverse to the exact failed authored waypoint")
	assert_true(smoke.contains("_physical_action(\"upper_anchor_east\""),
		"regression does not activate the production east anchor")
	assert_false(smoke.contains("player.global_position ="),
		"regression warps after the normal Cloudreach entry")


func test_voss_yard_join_covers_the_route_landing_and_uses_real_input() -> void:
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(SCENE_RUNTIME_PATH))
	var voss: Dictionary={}
	for yard: Dictionary in data.get("battle_yards",[]):
		if str(yard.get("id",""))=="officer_voss_summit_approach":
			voss=yard
	assert_true(float(voss.get("entry_width_m",0.0))>=13.1,
		"Voss connector does not overlap the complete summit-road landing cap")
	var yards_source:=FileAccess.get_file_as_string(YARDS_PATH)
	assert_true(yards_source.contains("spec.get(\"entry_width_m\",5.0)"),
		"battle-yard builder ignores its configured junction width")
	assert_true(yards_source.contains("\"half_width\":entry_width*0.5"),
		"runtime support map disagrees with the physical junction width")
	var smoke:=FileAccess.get_file_as_string(VOSS_SMOKE_PATH)
	assert_true(smoke.contains("yard.get_meta(\"road_entry\")"),
		"focused regression does not begin at the production road endpoint")
	assert_true(smoke.contains("await _walk(body.global_position+Vector3(3,0,0))"),
		"focused regression does not use real stick traversal through the join")
	assert_true(smoke.contains("await _interact(prompt)"),
		"focused regression does not challenge Voss through real input")
	assert_eq(smoke.count("player.global_position="),1,
		"focused regression writes position after its declared initial fixture placement")


func test_summit_join_keeps_tall_geology_visual_and_real_stick_path_supported() -> void:
	var world_source:=FileAccess.get_file_as_string(WORLD_PATH)
	assert_true(world_source.contains("not summit_region"),
		"the tall summit-region erosion still blocks the authored ascent")
	assert_true(world_source.contains("\"SummitWalkableCrown\""),
		"the summit landing does not join the arena approach on a thin support")
	assert_true(world_source.contains("Vector3(side * 18.5, 13.0, centre_z)"),
		"the stronghold's physical throat still overlaps the diagonal road")
	var smoke:=FileAccess.get_file_as_string(SUMMIT_SMOKE_PATH)
	assert_true(smoke.contains("await _walk(target)"),
		"summit regression does not traverse the measured failed direction with real stick")
	assert_eq(smoke.count("player.global_position="),1,
		"summit regression writes position after its declared fixture placement")


func test_summit_loop_side_portals_reach_bivouac_through_real_input() -> void:
	var world_source:=FileAccess.get_file_as_string(WORLD_PATH)
	assert_true(world_source.contains("_build_summit_route_wing(root, side, portal_z)"),
		"solid stronghold wings still cross the bidirectional summit loop")
	assert_true(world_source.contains("PORTAL_CLEAR_HEIGHT"),
		"summit side openings have no explicit controller-height clearance")
	var smoke:=FileAccess.get_file_as_string(SUMMIT_BIVOUAC_SMOKE_PATH)
	assert_true(smoke.contains("await _navigate(camp.global_position)"),
		"summit bivouac regression does not follow the authored production-route graph")
	assert_true(smoke.contains("await _interact(camp.get_node(\"Interactable\"),\"\",false)"),
		"summit bivouac regression does not activate the actual camp prompt")
	assert_eq(smoke.count("player.global_position="),1,
		"summit bivouac regression writes position after its declared fixture placement")


func test_captain_uses_central_arena_approach_after_relocation() -> void:
	var source:=_source()
	var battle:=_function_body(source,"_battle","_team_snapshot")
	assert_true(battle.contains("arena_origin-Vector3(0.0,0.0,50.0)"),
		"captain path does not enter through the production SummitArenaApproach")
	assert_true(battle.find("await _frames(20)") < battle.find("arena_origin+Vector3(3.0,0.0,0.0)"),
		"captain path can retain the reused NPC's pre-threshold position")
	assert_true(source.contains("for exit_point: Vector3 in [finale_origin-Vector3(0.0,0.0,30.0), finale_origin-Vector3(0.0,0.0,50.0), Vector3(100.0,1160.0,5350.0)]"),
		"aftermath route does not leave the arena through its production central approach")
	var smoke:=FileAccess.get_file_as_string(CAPTAIN_APPROACH_SMOKE_PATH)
	assert_true(smoke.contains("for exit_point: Vector3 in [arena_origin-Vector3(0.0,0.0,30.0),arena_origin-Vector3(0.0,0.0,50.0),Vector3(100.0,1160.0,5350.0)]"),
		"captain regression does not prove the central approach in both directions")
	assert_true(smoke.contains("await _interact(prompt)"),
		"captain approach regression does not press the actual challenge")
	assert_eq(smoke.count("player.global_position="),1,
		"captain approach regression writes position after its declared fixture placement")


func test_cloudreach_wild_has_production_residency_leash_and_actual_world_regression() -> void:
	var director:=FileAccess.get_file_as_string(DIRECTOR_PATH)
	assert_true(director.contains("PEACEFUL_LEASH_MARGIN_M"),
		"Cloudreach wild has no bound after physics displacement")
	assert_true(director.contains("engaged or aggressive or not is_alive()"),
		"residency recovery could move an aggressive or combat-owned creature")
	assert_true(director.contains("place_on_ground(home)"),
		"residency recovery does not reuse the validated authored home")
	var smoke:=FileAccess.get_file_as_string(WILD_LEASH_SMOKE_PATH)
	assert_true(smoke.contains("wild.global_position=home+Vector3(30.0,12.0,0.0)"),
		"wild regression does not reproduce a physics displacement beyond residency")
	assert_true(smoke.contains("peaceful_leash_recoveries"),
		"wild regression does not observe the production recovery path")


func test_near_target_mobile_occupancy_is_bounded_and_actual_input_regressed() -> void:
	var source:=_source()
	assert_true(source.contains("travel_arrived_mobile_clearance"),
		"near-target live-body occupancy has no explicit evidenced arrival path")
	assert_true(source.contains("frame-mobile_contact_frame <= 30"),
		"near-target clearance does not require a recent live-body collision")
	assert_true(source.contains("horizontal_distance < maxf(radius, 1.25)"),
		"near-target clearance is not bounded to practical interaction distance")
	var smoke:=FileAccess.get_file_as_string(MOBILE_OCCUPANCY_SMOKE_PATH)
	assert_true(smoke.contains("await _walk(occupied_target,0.4)"),
		"mobile occupancy regression does not use the continuous real-stick walker")
	assert_false(smoke.contains("player.global_position="),
		"mobile occupancy regression writes the player position")


func test_mobile_contact_tangent_arc_and_post_camp_motion_are_regressed() -> void:
	var source:=_source()
	assert_true(source.contains("three-point real-stick tangent arc; mirrored retry; no position write"),
		"mobile obstruction handling is not a multi-waypoint tangent arc")
	assert_true(source.contains("for side_try in 2:") and \
		source.contains("preferred_side if side_try==0 else -preferred_side"),
		"mobile tangent arc has no opposite-side retry")
	assert_true(source.find("var is_mobile:=collider is CharacterBody3D") < \
		source.find("if is_mobile or absf(hit.get_normal().y) < 0.8:"),
		"steep mobile contacts are still discarded by the static-wall filter")
	var lower:=FileAccess.get_file_as_string(LOWER_FORAGER_SMOKE_PATH)
	assert_true(lower.contains('find_child("lower_cliff_foragers_0"'),
		"lower regression does not use the exact production route occupant")
	assert_true(lower.contains("_sidestep_mobile_blocker"),
		"lower regression does not prove the tangent arc with real stick")
	var post_camp:=FileAccess.get_file_as_string(POST_CAMP_SMOKE_PATH)
	assert_true(post_camp.contains("_recover_party_through_camp_input"),
		"post-camp regression does not use actual bed/rest recovery")
	assert_true(post_camp.contains('player.set("_deflect_left",-1.0/60.0)'),
		"post-camp regression does not pin the observed expired deflect state")
	assert_true(post_camp.contains('find_child("summit_watch_0"'),
		"post-camp regression does not reproduce the exact production occupant")


func test_post_relay_crown_housing_preserves_visible_prop_and_central_exit() -> void:
	var presentation:=FileAccess.get_file_as_string(SUMMIT_PRESENTATION_PATH)
	assert_true(presentation.contains('if str(relay.id) != "crown":'),
		"crown relay housing collision still blocks the sole authored approach")
	var smoke:=FileAccess.get_file_as_string(POST_RELAY_SMOKE_PATH)
	assert_true(smoke.contains('runtime.finale.phase=="awaiting_restoration"'),
		"post-relay regression is not in the completed production phase")
	assert_true(smoke.contains('get_node("SummitArenaPresentation/InstalledRelayMount_crown")'),
		"post-relay regression does not preserve the visible relay housing")
	assert_true(smoke.contains("Vector3(100.0,1160.0,5420.0)") and \
		smoke.contains("Vector3(100.0,1160.0,5350.0)"),
		"post-relay regression does not walk the exact central exit")
	assert_eq(smoke.count("player.global_position="),1,
		"post-relay regression writes position after its declared fixture placement")


func test_exact_persistence_tail_freezes_observation_and_logs_field_differences() -> void:
	var smoke:=FileAccess.get_file_as_string(PERSISTENCE_TAIL_SMOKE_PATH)
	assert_true(smoke.contains("paused=true") and smoke.contains("paused=false"),
		"persistence regression permits live condition decay during comparison")
	assert_true(smoke.contains("_party_persistence_differences(before,after)"),
		"persistence regression does not report exact per-member field changes")
	assert_true(smoke.contains("game.party.size()==5"),
		"persistence regression does not enforce the five-member party")


func test_waterward_overlook_join_uses_thin_crown_and_real_input() -> void:
	var world_source:=FileAccess.get_file_as_string(WORLD_PATH)
	assert_true(world_source.contains('"summit_eyrie_stronghold", "waterward_overlook"'),
		"the tall Waterward landmark geology still owns collision")
	assert_true(world_source.contains('"OverlookWalkableCrown"'),
		"the Waterward route endpoint has no thin crown support")
	var smoke:=FileAccess.get_file_as_string(WATERWARD_OVERLOOK_SMOKE_PATH)
	assert_true(smoke.contains("await _walk(target)"),
		"Waterward regression does not traverse the exact authored edge with real stick")
	assert_true(smoke.contains('_pickup("cr_pickup_waterward_rare_candy")'),
		"Waterward regression does not exercise the authored pickup footprint")
	assert_true(smoke.contains('_talk("warden_aila","cloudreach_chapter_complete",false)'),
		"Waterward regression does not exercise the relocated Warden reward footprint")
	assert_true(smoke.contains('not game.can_enter_realm("water")'),
		"Waterward regression does not prove future-realm non-entry")
	assert_eq(smoke.count("player.global_position="),1,
		"Waterward regression writes position after its declared fixture placement")
