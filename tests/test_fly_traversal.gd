extends "res://tests/test_case.gd"

const FLY := preload("res://scripts/player/fly_controller.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PARTY := preload("res://autoload/party.gd")
const PROGRESSION := preload("res://autoload/progression_state.gd")
const SAVE_FIXTURE := preload("res://tests/test_save_format.gd")

class FlyGame extends Node:
	var party: RefCounted = PARTY.new()
	var progression: RefCounted = PROGRESSION.new()
	var current_realm := "cloudreach"
	var realm_hearts: RefCounted = null


class FlyHearts extends RefCounted:
	var power: Dictionary = {}

	func active_power() -> Dictionary:
		return power.duplicate(true)

var fly: Node
var game: Node


func before_each() -> void:
	fly = FLY.new()
	game = FlyGame.new()
	fly._game = game
	fly.config = JSON.parse_string(FileAccess.get_file_as_string(FLY.CONFIG_PATH))


func after_each() -> void:
	fly.free()
	game.free()


func test_deliberate_relocation_forgets_old_anchor_without_granting_a_new_one() -> void:
	fly.safe_anchor = Vector3(900, 1020, 2700)
	fly.safe_realm = "cloudreach"
	fly._anchor_host_granted = true
	var old_request: int = fly._anchor_request_id
	fly._anchor_pending = true
	fly._anchor_pending_claim = fly.safe_anchor
	fly._anchor_pending_is_landing = true
	fly._anchor_pending_for = 0.2
	fly.clear_recovery_anchor()
	assert_eq(fly.safe_anchor, Vector3.INF)
	assert_eq(fly.safe_realm, "")
	assert_false(fly._anchor_host_granted)
	assert_false(fly._anchor_pending)
	assert_eq(fly._anchor_pending_claim, Vector3.INF)
	assert_false(fly._anchor_pending_is_landing)
	assert_eq(fly._anchor_pending_for, 0.0)
	fly.apply_anchor_verdict(true, Vector3(900, 1020, 2700), "ok", "old landing", old_request)
	assert_eq(fly.safe_anchor, Vector3.INF, "a late pre-teleport host answer stays invalid")
	fly.apply_anchor_verdict(false, Vector3.ZERO, "refused", "old rejection", old_request)
	assert_eq(fly._anchor_refusals, 0, "an old rejection cannot recover or deny the relocated player")
	assert_false(fly.recover_to_anchor("stale pre-teleport landing"))
	assert_false(game.progression.has("fly_traversal_unlocked"))
	fly.apply_anchor_verdict(true, Vector3(-340, 830, 3970), "ok", "current landing", fly._anchor_request_id)
	assert_eq(fly.safe_anchor, Vector3(-340, 830, 3970), "a current host verdict can establish the new landing")
	assert_true(fly._anchor_host_granted)
	var replacement := FLY.new()
	replacement._game = game
	assert_ne(replacement._anchor_request_id, fly._anchor_request_id,
		"a replacement scene controller must not reuse the old controller's token")
	replacement.apply_anchor_verdict(true, fly.safe_anchor, "ok", "old scene reply", fly._anchor_request_id)
	assert_eq(replacement.safe_anchor, Vector3.INF)
	replacement.free()


func test_owned_active_healthy_carrier_is_preferred_without_sixth_slot() -> void:
	assert_eq(fly.eligible_creature(), null)
	for i in 4:
		assert_true(game.party.add(SPECIES.spawn("bramblebun")))
	var bird: RefCounted = SPECIES.spawn("galecrest")
	assert_true(game.party.add(bird))
	assert_eq(fly.eligible_creature(), null, "owned but inactive bird is ineligible")
	assert_eq(fly.owned_carrier(), bird, "the five's carrier is known even while it is not out")
	assert_true(game.party.set_active(4))
	assert_eq(fly.eligible_creature(), bird)
	assert_eq(game.party.size(), 5)
	assert_false(game.party.add(SPECIES.spawn("galecrest")), "no hidden sixth slot")
	bird.fainted = true
	game.progression.set_flag("fly_traversal_unlocked")
	assert_ne(fly.eligible_creature(), bird, "a fainted owned carrier is never used")
	# A five whose only carrier is unwell keeps the loaner's safety net, so a
	# carrier that faints on a flight-only shelf cannot strand the trainer.
	var net: RefCounted = fly.eligible_creature()
	assert_ne(net, null, "an unwell carrier leaves Maela's loaner in Cloudreach")
	assert_false((game.party.members() as Array).has(net), "mentor loaner is not secretly owned")
	bird.fainted = false
	bird.resting = true
	assert_ne(fly.eligible_creature(), bird, "a resting owned carrier is never used")
	game.progression.set_flag("cloudreach_chapter_complete")
	assert_eq(fly.eligible_creature(), null, "past the loaner's chapter nothing carries")
	assert_eq(fly.carrier_refusal(), "Galecrest needs to recover before it can carry you.", "the refusal names the unwell carrier")


func test_full_non_fly_party_gets_transient_maela_carrier_for_trial_and_unlock() -> void:
	for species: String in ["bramblebun", "mudsnout", "terrapup", "brooktail", "sparkit"]:
		assert_true(game.party.add(SPECIES.spawn(species)))
	assert_eq(game.party.size(), 5)
	assert_eq(fly.eligible_creature(), null, "loaner is unavailable before Maela's trial")
	fly.set_trial_authorization(AABB(Vector3(-10, 0, -10), Vector3(20, 40, 20)))
	var trial_carrier: RefCounted = fly.eligible_creature()
	assert_ne(trial_carrier, null)
	assert_eq(str(trial_carrier.species_id), "galecrest")
	assert_false((game.party.members() as Array).has(trial_carrier))
	assert_eq(game.party.size(), 5)
	fly.set_trial_authorization(AABB())
	game.progression.set_flag("fly_traversal_unlocked")
	assert_eq(fly.eligible_creature(), trial_carrier, "same transient carrier remains available after unlock")
	game.current_realm = "meadows"
	assert_eq(fly.eligible_creature(), null, "Cloudreach loaner cannot cross realms")


func test_restrictions_are_swept_and_three_dimensional() -> void:
	game.progression.set_flag("fly_traversal_unlocked")
	fly.register_restriction("upper", AABB(Vector3(10, 0, -5), Vector3(2, 50, 10)), "upper_open")
	assert_false(fly._restricted_reason(Vector3(0, 20, 0), Vector3(30, 20, 0)).is_empty(), "fast flight must not tunnel through a gate")
	assert_true(fly._restricted_reason(Vector3(0, 60, 0), Vector3(30, 60, 0)).is_empty(), "finite authored volumes have explicit extents")
	game.progression.set_flag("upper_open")
	assert_true(fly._restricted_reason(Vector3(0, 20, 0), Vector3(30, 20, 0)).is_empty())


## F06 review M3: a volume that closes around a flyer whose anchor fails its
## ground ray used to zero the flyer's velocity every frame, forever. The
## guard carries it out along the shortest horizontal way out of the union of
## closed volumes -- never down, never while outside, never stuck in a pocket
## where one box's nearest face leads into the next.
func test_flyer_trapped_in_closed_volumes_is_carried_out_not_hung() -> void:
	game.progression.set_flag("fly_traversal_unlocked")
	fly.register_restriction("stair", AABB(Vector3(0, 0, 0), Vector3(40, 100, 40)), "stair_open")
	var inside := Vector3(30, 50, 20)
	var out: Vector3 = fly.sealed_exit(inside)
	assert_almost_eq(out.x, 10.76, 0.02, "nearest edge is +x, 10 m plus the 0.75 m body clearance")
	assert_almost_eq(out.y, 0.0, 0.0001, "never vertical")
	assert_almost_eq(out.z, 0.0, 0.02)
	var dt := 1.0 / 60.0
	var escape: Vector3 = fly.sealed_escape_velocity(inside, dt)
	assert_almost_eq(escape.length(), 8.0, 0.001, "carried at half glide speed")
	assert_eq(fly.sealed_exit(Vector3(-20, 50, 20)), Vector3.ZERO, "outside every closed volume the guard grants nothing")
	assert_eq(fly.sealed_escape_velocity(Vector3(-20, 50, 20), dt), Vector3.ZERO)
	# A second volume overlapping the first's nearest face: the way out is no
	# longer +z, which leads 80 m deeper, but +/-x across both.
	fly.register_restriction("crown", AABB(Vector3(0, 0, 38), Vector3(40, 100, 82)), "stair_open")
	var pocket := Vector3(20, 50, 36)
	var way: Vector3 = fly.sealed_exit(pocket)
	assert_almost_eq(absf(way.x), 20.75, 0.03, "exit across both volumes, not into the second one (%s)" % way)
	var position := pocket
	var frames := 0
	while fly.sealed_exit(position) != Vector3.ZERO and frames < 60 * 10:
		position += fly.sealed_escape_velocity(position, dt) * dt
		frames += 1
	assert_true(frames < 60 * 4, "carried out of the union in %.2f s" % (float(frames) / 60.0))
	assert_almost_eq(position.y, pocket.y, 0.0001, "and never lowered onto what the volumes seal")
	game.progression.set_flag("stair_open")
	assert_eq(fly.sealed_exit(inside), Vector3.ZERO, "an opened volume holds nobody")


func test_trial_authorization_does_not_unlock_fly_or_allow_leaving_trial() -> void:
	fly.set_trial_authorization(AABB(Vector3(-10, 0, -10), Vector3(20, 50, 20)))
	assert_false(fly._unlocked())
	assert_true(fly._restricted_reason(Vector3(0, 5, 0), Vector3(1, 6, 0)).is_empty())
	assert_false(fly._restricted_reason(Vector3(0, 5, 0), Vector3(30, 6, 0)).is_empty())
	assert_false(game.progression.has("fly_traversal_unlocked"))


func test_airborne_save_load_uses_ground_anchor_and_preserves_stamina_and_active_slot() -> void:
	var fixture: RefCounted = SAVE_FIXTURE.new()
	fixture.before_each()
	var written: RefCounted = fixture._game(false)
	written.current_realm = "cloudreach"
	written.party.add(SPECIES.spawn("bramblebun"))
	written.party.add(SPECIES.spawn("galecrest"))
	written.saved_player_pose = {"realm": "cloudreach", "position": [0, 120, 0], "model_yaw": 0, "camera_yaw": 0, "camera_pitch": 0, "traversal": {"version": 1, "mode": "climb", "realm": "cloudreach", "safe_anchor": [2, 4, 6], "velocity": [0, 18, 0], "stamina_fraction": 0.34, "active_index": 1}}
	assert_true(fixture.saver.save(written, 1))
	var restored: RefCounted = fixture._game(false)
	assert_true(fixture.saver.load_slot(restored, 1))
	assert_almost_eq(float(restored.saved_player_pose.position[1]), 4.08, 0.001)
	assert_eq(restored.party.active_index(), 1)
	assert_almost_eq(float(restored.get_meta("pending_fly_load").stamina_fraction), 0.34, 0.001)
	assert_true(fixture.saver.load_slot(written, 1), "same-object reload also restores safely")
	assert_almost_eq(float(written.saved_player_pose.position[1]), 4.08, 0.001)
	fixture.after_each()


func test_invalid_airborne_anchor_rejects_pose_and_v17_migration_preserves_rewards() -> void:
	var fixture: RefCounted = SAVE_FIXTURE.new()
	fixture.before_each()
	var pose := {"position": [0, 100, 0], "model_yaw": 0, "camera_yaw": 0, "camera_pitch": 0, "traversal": {"version": 1, "mode": "glide", "realm": "meadows", "safe_anchor": [], "velocity": [0, 0, 0], "stamina_fraction": 0.5}}
	assert_true(fixture.saver._sanitise_player_pose(pose).is_empty())
	var migrated: Dictionary = fixture.saver._migrate_v17({"version": 17, "progression": {"fly_traversal_unlocked": true}, "realm_hearts": {"active": "meadows"}})
	assert_eq(migrated.version, 18)
	assert_eq(migrated.progression, {"fly_traversal_unlocked": true})
	assert_eq(migrated.realm_hearts, {"active": "meadows"})
	fixture.after_each()


func test_skyborne_cost_helper_covers_launch_glide_and_climb_without_exceeding_base_costs() -> void:
	var ordinary := {}
	var skyborne := {"fly_stamina_multiplier": 0.0}
	assert_almost_eq(FLY.adjusted_stamina_cost(8.0, ordinary), 8.0, 0.0001, "ordinary launch cost")
	assert_almost_eq(FLY.adjusted_stamina_cost(1.0, ordinary), 1.0, 0.0001, "ordinary glide cost")
	assert_almost_eq(FLY.adjusted_stamina_cost(1.6, ordinary), 1.6, 0.0001, "ordinary climb cost")
	assert_almost_eq(FLY.adjusted_stamina_cost(18.0, ordinary), 18.0, 0.0001, "ordinary launch minimum")
	assert_almost_eq(FLY.adjusted_stamina_cost(8.0, skyborne), 0.0, 0.0001, "Skyborne launch cost")
	assert_almost_eq(FLY.adjusted_stamina_cost(1.0, skyborne), 0.0, 0.0001, "Skyborne glide cost")
	assert_almost_eq(FLY.adjusted_stamina_cost(1.6, skyborne), 0.0, 0.0001, "Skyborne climb cost")
	assert_almost_eq(FLY.adjusted_stamina_cost(18.0, skyborne), 0.0, 0.0001, "Skyborne launch minimum")
	assert_almost_eq(FLY.stamina_cost_multiplier({"fly_stamina_multiplier": -1.0}), 0.0, 0.0001)
	assert_almost_eq(FLY.stamina_cost_multiplier({"fly_stamina_multiplier": 2.0}), 1.0, 0.0001)


func test_flight_stamina_multiplier_reads_only_this_players_active_relic() -> void:
	var hearts := FlyHearts.new()
	game.realm_hearts = hearts
	assert_almost_eq(fly._flight_stamina_multiplier(), 1.0, 0.0001)
	hearts.power = {"fly_stamina_multiplier": 0.0}
	assert_almost_eq(fly._flight_stamina_multiplier(), 0.0, 0.0001)
	hearts.power = {}
	assert_almost_eq(fly._flight_stamina_multiplier(), 1.0, 0.0001, "switching away restores ordinary Fly costs")



## Owned-carrier Fly (Cloudreach follow-on): the Galewisp starter gains Fly at
## the Cloudreach unlock (CREATURES §7), never before; Maela's trial keeps her
## loaner for it; after the unlock the Galewisp carries and no loaner stands in.
func test_galewisp_starter_gains_fly_at_the_unlock_without_a_sixth_slot() -> void:
	var wisp: RefCounted = SPECIES.spawn("galewisp")
	assert_true(game.party.add(wisp))
	for species: String in ["bramblebun", "mudsnout", "terrapup", "brooktail"]:
		assert_true(game.party.add(SPECIES.spawn(species)))
	assert_true(game.party.set_active(0))
	assert_false(fly.carrier_qualifies("galewisp"), "no Fly before the Cloudreach unlock")
	assert_eq(fly.eligible_creature(), null, "and no carrier at all outside the trial")
	fly.set_trial_authorization(AABB(Vector3(-10, 0, -10), Vector3(20, 40, 20)))
	var trial_carrier: RefCounted = fly.eligible_creature()
	assert_ne(trial_carrier, null, "Maela's trial still has her loaner")
	assert_ne(trial_carrier, wisp, "the starter does not carry before its promise opens")
	assert_false((game.party.members() as Array).has(trial_carrier), "the loaner is never owned")
	fly.set_trial_authorization(AABB())
	game.progression.set_flag("fly_traversal_unlocked")
	assert_true(fly.carrier_qualifies("galewisp"))
	assert_eq(fly.eligible_creature(), wisp, "after the unlock the owned Galewisp carries")
	assert_eq(game.party.size(), 5, "no sixth creature appears")
	game.progression.set_flag("cloudreach_chapter_complete")
	assert_eq(fly.eligible_creature(), wisp, "the promise outlives the loaner's chapter")


## After the unlock a five holding a qualifying carrier that is not out gets no
## loaner: the player sends their own carrier out (launch_blockers names it).
## Maela's trial is the one place the loaner still serves such a five.
func test_an_owned_carrier_that_is_not_out_gets_no_loaner_after_the_unlock() -> void:
	for species: String in ["bramblebun", "mudsnout", "terrapup", "brooktail"]:
		assert_true(game.party.add(SPECIES.spawn(species)))
	var bird: RefCounted = SPECIES.spawn("galecrest")
	assert_true(game.party.add(bird))
	assert_true(game.party.set_active(0))
	game.progression.set_flag("fly_traversal_unlocked")
	assert_eq(fly.owned_carrier(), bird)
	assert_eq(fly.eligible_creature(), null, "no loaner while the five hold their own carrier")
	assert_eq(fly.carrier_refusal(), "Send out Galecrest to fly.", "the refusal names the carrier to send out")
	fly.set_trial_authorization(AABB(Vector3(-10, 0, -10), Vector3(20, 40, 20)))
	var trial_carrier: RefCounted = fly.eligible_creature()
	assert_ne(trial_carrier, null, "the trial keeps Maela's loaner")
	assert_false((game.party.members() as Array).has(trial_carrier))
	fly.set_trial_authorization(AABB())
	assert_true(game.party.set_active(4))
	assert_eq(fly.eligible_creature(), bird, "sent out, the owned bird carries")
	assert_eq(game.party.size(), 5)
	var spare: RefCounted = SPECIES.spawn("galecrest")
	game.party.remove_at(3)
	assert_true(game.party.add(spare))
	bird.fainted = true
	assert_eq(fly.owned_carrier(), spare, "a healthy carrier on the bench is named before a fainted one")
	assert_eq(fly.eligible_creature(), null, "and while it is healthy there is still no loaner")
	assert_eq(fly.carrier_refusal(), "Send out Galecrest to fly.")


## A five with no qualifying carrier still gets the loaner after the unlock
## (the design's deadlock guard), and the Galewisp starter before the unlock
## does not count as a carrier for that rule.
func test_a_five_without_a_carrier_keeps_the_loaner_until_the_chapter_ends() -> void:
	for species: String in ["galewisp", "bramblebun", "mudsnout", "brooktail", "sparkit"]:
		assert_true(game.party.add(SPECIES.spawn(species)))
	assert_eq(fly.owned_carrier(), null, "before the unlock the Galewisp is not yet a carrier")
	game.progression.set_flag("fly_traversal_unlocked")
	assert_ne(fly.owned_carrier(), null, "after it, it is")
	var others := PARTY.new()
	game.party = others
	for species: String in ["bramblebun", "mudsnout", "terrapup", "brooktail", "sparkit"]:
		assert_true(game.party.add(SPECIES.spawn(species)))
	var loaner: RefCounted = fly.eligible_creature()
	assert_ne(loaner, null, "a non-flying five keeps Maela's loaner after the unlock")
	assert_false((game.party.members() as Array).has(loaner))
	game.progression.set_flag("cloudreach_chapter_complete")
	assert_eq(fly.eligible_creature(), null, "until the chapter completes")


## Galewisp's carrier art grips the trainer with its lower legs and flaps its
## two-segment wings (upper -> tip), the same shared builder remotes use.
func test_galewisp_carrier_art_builds_with_grip_bones_and_flapping_wings() -> void:
	var capability: Dictionary = SPECIES.fly_capability("galewisp")
	assert_true(bool(capability.get("can_carry", false)))
	var art: Node3D = FLY.make_carrier_art(capability)
	assert_ne(art, null, "the Galewisp model loads as a carrier")
	if art == null:
		return
	var rig: Skeleton3D = FLY.carrier_skeleton(art)
	assert_ne(rig, null)
	if rig != null:
		for bone: String in capability.get("grip_bones", []):
			assert_true(rig.find_bone(bone) >= 0, "grip bone " + bone)
		var upper := rig.find_bone("wing_upper_l")
		var before := rig.get_bone_pose_rotation(upper)
		FLY.pose_carrier_wings(rig, capability, 0.1)
		assert_false(rig.get_bone_pose_rotation(upper).is_equal_approx(before), "the upper wing moves")
	art.free()


## F06#3: the loaner path never adds or loses an owned creature, and a sealed
## wind route stops a loaner flight exactly as it stops an owned carrier.
func test_the_loaner_can_never_join_the_party_even_with_room() -> void:
	for species: String in ["bramblebun", "mudsnout", "terrapup", "brooktail"]:
		assert_true(game.party.add(SPECIES.spawn(species)))
	game.progression.set_flag("fly_traversal_unlocked")
	var loaner: RefCounted = fly.eligible_creature()
	assert_ne(loaner, null, "a five without a carrier gets Maela's loaner after the unlock")
	var before: Array = (game.party.members() as Array).duplicate()
	assert_false(game.party.add(loaner), "the party refuses Maela's loaner even with a free slot")
	assert_eq(game.party.members(), before, "the four owned creatures are unchanged")
	assert_true(game.party.add(SPECIES.spawn("sparkit")), "an ordinary creature still fills the free slot")
	assert_eq(game.party.size(), 5)


func test_a_sealed_route_stops_a_loaner_flight_like_an_owned_one() -> void:
	game.progression.set_flag("fly_traversal_unlocked")
	var loaner: RefCounted = fly.eligible_creature()
	assert_ne(loaner, null)
	fly._creature = loaner
	fly.register_restriction("upper", AABB(Vector3(10, 0, -5), Vector3(2, 50, 10)), "upper_open")
	assert_false(fly._restricted_reason(Vector3(0, 20, 0), Vector3(30, 20, 0)).is_empty(),
		"the loaner does not carry the trainer through a closed gate")
	game.progression.set_flag("upper_open")
	assert_true(fly._restricted_reason(Vector3(0, 20, 0), Vector3(30, 20, 0)).is_empty(), "the opened route lets it pass")
