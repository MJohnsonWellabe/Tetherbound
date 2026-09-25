extends SceneTree

## SD17: is the Burrow Warrens a real place you can be inside?
##
##   godot --headless --path . --script tests/smoke_warrens.gd
##   godot --path . --script tests/smoke_warrens.gd -- --guardian-attacks
##
## The unit suite cannot see any of this. A dungeon built from primitive boxes
## either has walls a CharacterBody3D cannot walk through and a floor it can
## stand on, or it is a decorative diorama the player falls through — and the
## only way to tell the two apart is to boot the world, stand in it and push.
##
## What it asserts, in the order the player meets it:
##
##   * the warrens built at all, at its authored world position
##   * the mouth is walkable: the player put down at the entrance ends up
##     standing on the cave floor, not inside a hillside and not falling
##   * the chambers are ENCLOSED: pushing hard at the deepest chamber's far
##     wall does not leave the footprint
##   * no ground comes through any chamber's floor
##   * the whole route -- entrance, mouth, hall, den, branch -- can be WALKED,
##     by the player's own controller, in one go
##   * OWNER-0912: the rebuilt exterior approach is mounted, its measured root
##     shoulders stay outside the clear lane, and the production player's
##     real capsule can walk from the far ruts through the curved throat and
##     back out again
##   * the population is there and the guardian is placed at its own level
##   * the deep branch is blocked before the cleared flag and open after
##   * the Heartstone is obtainable and turns R4.6's evolution item gate on
##   * the clear transition opens exactly once; `--guardian-reward` witnesses
##     the guardian's durable production payout
##   * W07-WARRENS-0904, the ROOM: no ray from any chamber escapes the cave
##     (no daylight leak through a missing wall); the interior-ambient probe
##     exists, is gated to the interior layer, every wall/floor mesh carries
##     that layer and no mound boulder does; a body that walks in takes the
##     layer and loses it on the way out; roots, fungus, litter and haze add
##     no collision and hang above head height in the lanes
##
## The guardian is not FOUGHT here — smoke_combat.gd is the test that pilots a
## real fight, and re-running it against a level-18 Burrowback would be a
## second copy of that coverage plus five minutes of CI. What this proves is
## that the clearing PATH exists and pays once, which is `SD17`'s own done-when.

const SCENE := "res://scenes/world/meadows_playground.tscn"
## CONTENT-0828B. The species' own unscaled size, so the guardian's alpha
## multiplier is checked against the animal rather than against a number
## copied into this file.
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const BURROW_WARRENS := preload("res://scripts/world/burrow_warrens.gd")
const SETTLE_FRAMES := 240
const PUSH_FRAMES := 240
## The walked route (`_the_route_can_be_walked`): how close counts as arrived,
## and how long one leg may take before it has plainly run into something.
const ARRIVED_M := 3.0
const WALK_FRAMES := 600
const GUARDIAN_ATTACK_FRAME_LIMIT := 1200
const MOVE_DB := preload("res://scripts/creatures/move_db.gd")
const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const COMBAT_PILOT := preload("res://tools/combat_pilot.gd")
const EARNED_WARRENS := preload("res://tests/helpers/meadows_earned_warrens_segment.gd")
const GUARDIAN_SAVE_DIR := "user://smoke_warrens_guardian_attacks/"
const VAULT_ACTIVITY_SAVE_DIR := "user://smoke_warrens_vault_activity/"
const VAULT_ACTIVITY_SLOT := 4
const VAULT_ACTIVITY_PARTY := ["terrapup", "trailpup", "bramblebun", "burrowback", "meadowhart"]
const GUARDIAN_REWARD_SAVE_DIR := "user://smoke_warrens_guardian_reward/"
const GUARDIAN_REWARD_SLOT := 4

var _failures: Array[String] = []


func _init() -> void:
	if "--guardian-attacks" in OS.get_cmdline_user_args():
		_run.call_deferred()
	elif "--guardian-reward" in OS.get_cmdline_user_args():
		_run_guardian_reward.call_deferred()
	elif "--vault-activity" in OS.get_cmdline_user_args():
		_run_vault_activity.call_deferred()
	else:
		_run()


func _fail(message: String) -> void:
	_failures.append(message)


func _run() -> void:
	# Keep the focused fight witness wholly opt-in.  In particular, a typo in
	# its mode must fall through to the established geometry sweep rather than
	# silently running a staged fight and calling that the Warrens smoke.
	if "--guardian-attacks" in OS.get_cmdline_user_args():
		await _run_guardian_attacks()
		return
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):
			print("warrens FAIL: --capture-dir requires --guardian-attacks")
			quit(1)
			return
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame

	var player: CharacterBody3D = world.get_node_or_null(^"Player") as CharacterBody3D
	var warrens: Node3D = world.get_node_or_null(^"BurrowWarrens") as Node3D
	if player == null or warrens == null:
		print("warrens FAIL: the scene has no Player or no BurrowWarrens node")
		quit(1)
		return

	var game := root.get_node_or_null(^"/root/Game")
	var progression: RefCounted = game.get("progression") if game != null else null
	var inventory: RefCounted = game.get("inventory") if game != null else null
	if progression == null or inventory == null:
		print("warrens FAIL: no Game autoload with a progression store and an inventory")
		quit(1)
		return
	# A fresh dungeon, whatever a save left behind.
	progression.call("set_flag", "warrens_cleared", false)

	print("warrens stands at %.0f, %.1f, %.0f with chambers %s" % [
		warrens.global_position.x, warrens.global_position.y, warrens.global_position.z,
		", ".join(warrens.call("chamber_ids"))])

	_the_population_and_the_guardian_are_placed(warrens)
	_the_approach_is_not_crowded()
	_the_vault_alpha_reads_as_an_alpha(world, warrens)
	# Everything below is about GEOMETRY, and the residents are aggressive by
	# design: left running they walk into the player, block a push with their
	# own capsule, and eventually start a real fight that takes the camera.
	# smoke_combat.gd is the test that fights; this one holds still.
	_quieten_the_residents(warrens)
	_the_approach_composition_is_mounted_and_clear(player, warrens)
	await _the_approach_can_be_entered_and_exited(world, player, warrens)
	await _the_cave_is_enclosed(world, player, warrens)
	_no_daylight_leaks(world, warrens)
	_the_bank_encloses_every_chamber(world, warrens)
	_the_mouth_arch_is_open(world, warrens)
	await _the_room_has_its_own_dark(player, warrens)
	_the_room_dressing_is_clear_of_the_walk(warrens)
	await _the_branch_is_shut_until_the_guardian_falls(player, warrens, progression)
	await _the_route_can_be_walked(player, warrens, progression)
	_the_heartstone_is_obtainable_and_arms_the_evolution_gate(warrens, inventory, progression)
	_the_clear_transition_happens_once(warrens, inventory, progression)
	await _a_cleared_guardian_does_not_come_back(world, progression)

	print("")
	if _failures.is_empty():
		print("warrens smoke test passed")
		quit(0)
		return
	for line in _failures:
		print("  FAIL: %s" % line)
	quit(1)


## Focused guardian payoff witness. It seeds only the retained five, walks the
## real route from the entrance, lets the aggressive guardian admit combat, and
## uses the existing combat pilot. The payout and its saved no-replay state are
## observed after that production terminal path; no clear flag or reward is
## written by this mode.
func _run_guardian_reward() -> void:
	await process_frame
	var game := root.get_node_or_null(^"/root/Game")
	if game == null:
		_fail("guardian reward: no Game autoload")
		_report_guardian_reward()
		return
	DirAccess.make_dir_recursive_absolute(GUARDIAN_REWARD_SAVE_DIR)
	game.set("save_system", SAVE_GAME.new(GUARDIAN_REWARD_SAVE_DIR))
	game.call("reset_for_new_game")
	var party: RefCounted = game.get("party")
	if party == null:
		_fail("guardian reward: no party")
		_report_guardian_reward()
		return
	party.call("clear")
	for species_id: String in VAULT_ACTIVITY_PARTY:
		var member: RefCounted = SPECIES.spawn(species_id)
		if member == null or not bool(party.call("add", member)):
			_fail("guardian reward: could not seed retained member %s" % species_id)
		else:
			member.call("set_level", 16, _progression_config())
			member.set("hp", member.get("max_hp"))
	var ids := _party_uids(party)
	if ids.size() != 5:
		_fail("guardian reward: fixture party has %d members, expected five" % ids.size())
	if not bool(game.call("save_game", GUARDIAN_REWARD_SLOT)):
		_fail("guardian reward: seeded retained-five identity could not be saved")
		_report_guardian_reward()
		return
	var before := _clear_reward_stock(game.get("inventory") as RefCounted)
	var xp_before := _party_xp(party)
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	current_scene = world
	for _frame in SETTLE_FRAMES:
		await physics_frame
	var player := world.get_node_or_null(^"Player") as CharacterBody3D
	var warrens := world.get_node_or_null(^"BurrowWarrens") as Node3D
	var director := world.get_node_or_null(^"EncounterDirector")
	var manager := world.get_node_or_null(^"CombatManager")
	var rig := world.get_node_or_null(^"CameraRig") as Node3D
	var guardian := warrens.call("guardian") as Node3D if warrens != null else null
	if player == null or warrens == null or director == null or manager == null or rig == null or guardian == null:
		_fail("guardian reward: production world lacks route/combat dependencies")
		_report_guardian_reward()
		return
	if not await director.call("summon_active_creature"):
		_fail("guardian reward: retained party did not deploy its active creature")
	var active: RefCounted = director.call("ally_instance")
	for resident: Node3D in warrens.call("population"):
		resident.set("aggressive", false)
		resident.set_physics_process(false)
	await _put_down(player, warrens.call("marker", "entrance") + Vector3(0.0, 1.5, 0.0))
	for leg: String in ["mouth", "hall"]:
		await _walk_to(player, warrens, warrens.call("marker", leg) as Vector3)
		if not _failures.is_empty():
			_report_guardian_reward()
			return
	await _walk_to(player, warrens, guardian.global_position, ARRIVED_M, manager)
	if not bool(manager.call("is_fighting")) or manager.call("enemy_body") != guardian:
		_fail("guardian reward: walked entrance-to-den route did not naturally admit the Warren Guardian")
		_report_guardian_reward()
		return
	var pilot := COMBAT_PILOT.new(self, manager, director, rig)
	pilot.pilot = COMBAT_PILOT.Pilot.SPACER
	pilot.listen()
	var result: Dictionary = await pilot.fight_to_the_end()
	if str(result.get("outcome", "")) != "won" or bool(manager.call("is_fighting")) or pilot.hits_dealt <= 0:
		_fail("guardian reward: input combat did not defeat the guardian with a landed hit")
		_report_guardian_reward()
		return
	for _frame in 60:
		await physics_frame
	var reward: Dictionary = _clear_reward()
	if not bool((game.get("progression") as RefCounted).call("has", "warrens_cleared")) or not bool(warrens.call("branch_is_open")):
		_fail("guardian reward: real victory did not clear the Warrens and open its branch")
	if not _clear_reward_matches(before, _clear_reward_stock(game.get("inventory") as RefCounted), reward):
		_fail("guardian reward: real victory did not deliver the exact authored coin/item receipt")
	var survivors: Array[int] = []
	for member: RefCounted in party.call("members"):
		if not bool(member.get("fainted")):
			survivors.append(member.get_instance_id())
	if active == null or not EARNED_WARRENS.exact_xp_reward(xp_before, _party_xp(party),
			active.get_instance_id(), survivors, int((guardian.get("instance") as RefCounted).get("level")),
			int(reward.get("xp_bonus", 0)), _progression_config()):
		_fail("guardian reward: real victory did not deliver authored XP to each retained member")
	if _party_uids(party) != ids:
		_fail("guardian reward: victory changed the retained-five creature IDs")
	var after := _clear_reward_stock(game.get("inventory") as RefCounted)
	if not bool(game.call("save_game", GUARDIAN_REWARD_SLOT)) or not bool(game.call("load_game", GUARDIAN_REWARD_SLOT)):
		_fail("guardian reward: production save/load failed")
	elif _party_uids(game.get("party") as RefCounted) != ids or _clear_reward_stock(game.get("inventory") as RefCounted) != after:
		_fail("guardian reward: save/load changed retained IDs or replayed the receipt")
	world.queue_free()
	for _frame in 12:
		await physics_frame
	var rebuilt: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(rebuilt)
	current_scene = rebuilt
	for _frame in SETTLE_FRAMES:
		await physics_frame
	var rebuilt_warrens := rebuilt.get_node_or_null(^"BurrowWarrens") as Node3D
	if rebuilt_warrens == null or rebuilt_warrens.call("guardian") != null \
			or _clear_reward_stock(game.get("inventory") as RefCounted) != after:
		_fail("guardian reward: reload respawned guardian or replayed its receipt")
	if is_instance_valid(rebuilt):
		rebuilt.queue_free()
	_report_guardian_reward()


func _party_xp(party: RefCounted) -> Dictionary:
	var out := {}
	for member: RefCounted in party.call("members"):
		out[member.get_instance_id()] = EARNED_WARRENS.total_xp(int(member.get("level")),
			int(member.get("xp")), _progression_config())
	return out


func _clear_reward_matches(before: Dictionary, after: Dictionary, reward: Dictionary) -> bool:
	if int(after.get("coin", 0)) != int(before.get("coin", 0)) + int(reward.get("coins", 0)):
		return false
	for entry: Variant in reward.get("items", []):
		var item: Dictionary = entry as Dictionary
		var id := str(item.get("id", ""))
		if not id.is_empty() and int(after.get(id, 0)) != int(before.get(id, 0)) + int(item.get("count", 0)):
			return false
	return true


func _report_guardian_reward() -> void:
	print("")
	if _failures.is_empty():
		print("warrens guardian reward witness passed")
		quit(0)
		return
	for line in _failures:
		print("  FAIL: %s" % line)
	quit(1)


## Focused optional-vault activity witness. The guardian-clear flag is a
## declared prerequisite fixture; this mode does not replay the campaign or
## fight the required guardian. From the ordinary entrance, it walks every
## authored passage to the open vault, admits and defeats the named Elder
## Trailpup through the existing input combat pilot, takes the Heartstone with
## the production interact action, then proves the once flags and reward remain
## durable across a production save/load.
func _run_vault_activity() -> void:
	await process_frame
	var game := root.get_node_or_null(^"/root/Game")
	if game == null:
		_fail("vault activity: no Game autoload")
		_report_vault_activity()
		return
	DirAccess.make_dir_recursive_absolute(VAULT_ACTIVITY_SAVE_DIR)
	game.set("save_system", SAVE_GAME.new(VAULT_ACTIVITY_SAVE_DIR))
	game.call("reset_for_new_game")
	var party: RefCounted = game.get("party")
	var progression: RefCounted = game.get("progression")
	if party == null or progression == null:
		_fail("vault activity: missing party or progression store")
		_report_vault_activity()
		return
	party.call("clear")
	for species_id: String in VAULT_ACTIVITY_PARTY:
		var member: RefCounted = SPECIES.spawn(species_id)
		if member == null or not bool(party.call("add", member)):
			_fail("vault activity: could not seed fixture member %s" % species_id)
		else:
			member.call("set_level", 13, _progression_config())
			member.set("hp", member.get("max_hp"))
	var initial_uids := _party_uids(party)
	if initial_uids.size() != 5:
		_fail("vault activity: fixture party has %d members, expected five" % initial_uids.size())
	progression.call("set_flag", "warrens_cleared", true)
	if not bool(game.call("save_game", VAULT_ACTIVITY_SLOT)):
		_fail("vault activity: guardian-clear prerequisite could not be saved")
		_report_vault_activity()
		return

	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	current_scene = world
	for _frame in SETTLE_FRAMES:
		await physics_frame
	var player := world.get_node_or_null(^"Player") as CharacterBody3D
	var warrens := world.get_node_or_null(^"BurrowWarrens") as Node3D
	var director := world.get_node_or_null(^"EncounterDirector")
	var manager := world.get_node_or_null(^"CombatManager")
	var rig := world.get_node_or_null(^"CameraRig") as Node3D
	if player == null or warrens == null or director == null or manager == null or rig == null:
		_fail("vault activity: production world lacks Player/Warrens/director/manager/camera")
		_report_vault_activity()
		return
	if not bool(director.call("summon_active_creature")):
		_fail("vault activity: seeded active party member did not deploy")
	var recovery_before := int((game.get("inventory") as RefCounted).call("count", "potion_large"))
	var capture_dir := _vault_capture_dir()
	var elder: Node3D = _vault_elder(warrens)
	if elder == null:
		_fail("vault activity: the authored Elder Trailpup did not spawn")
		_report_vault_activity()
		return
	# Keep the optional route deterministic without suppressing the Elder itself.
	for resident: Node3D in warrens.call("population"):
		if resident != elder:
			resident.set("aggressive", false)
			resident.set_physics_process(false)
	var entrance := warrens.call("marker", "entrance") as Vector3
	await _put_down(player, entrance + Vector3(0.0, 1.5, 0.0))
	# summon_active_creature() ran before the route and initially stood the
	# follower beside the village player. Move the already-deployed body with
	# its trainer before any camera capture or route input, so the follower does
	# not remain outside the Warrens while the trainer enters.
	var ally := director.call("ally_body") as CharacterBody3D
	if ally == null:
		_fail("vault activity: deployed companion body disappeared before route")
	else:
		await _put_down(ally, player.global_position - player.global_basis.z * 2.4 \
				+ player.global_basis.x * 1.2)
	for leg: String in ["mouth", "hall", "den", "vault"]:
		var marker := warrens.call("marker", leg) as Vector3
		if leg == "vault":
			# Hold the ordinary active camera from the den mouth toward the vault
			# before walking the last leg. This optional lure capture records the
			# authored view, while the following walk remains the real input route.
			var to_vault := marker - player.global_position
			to_vault.y = 0.0
			var route_yaw := atan2(-to_vault.x, -to_vault.z)
			rig.set("yaw", route_yaw)
			rig.rotation = Vector3(rig.rotation.x, route_yaw, 0.0)
			for _settle in 30:
				await physics_frame
			await _vault_capture(world, capture_dir, "vault-lure")
			await _walk_to(player, warrens, marker, ARRIVED_M, manager)
		else:
			await _walk_to(player, warrens, marker)
		if not _failures.is_empty():
			_report_vault_activity()
			return
	await _vault_capture(world, capture_dir, "vault-approach")
	# The room marker already presents the Elder's ordinary engage prompt.
	# Walking onto its feet instead selects nearby floor gathering ahead of it.
	if not await _admit_and_fight_vault_elder(player, warrens, elder, director, manager, rig):
		_report_vault_activity()
		return
	if int((game.get("inventory") as RefCounted).call("count", "potion_large")) != recovery_before + 2:
		_fail("vault activity: Elder victory did not pay two retained-team recovery potions")

	var heartstone := warrens.get_node_or_null(^"Heartstone") as Node3D
	if heartstone == null:
		_fail("vault activity: Heartstone was absent after the Elder victory")
	else:
		await _walk_to(player, warrens, heartstone.global_position, 2.0)
		var prompt := heartstone.get_node_or_null(^"Interactable")
		if prompt == null:
			_fail("vault activity: Heartstone has no production Interactable")
		else:
			# Press only once the Heartstone's own prompt wins the arbiter, as a
			# player waits for it: straight after the Elder fight the ally, a
			# catch prompt or the input owner can still hold `interact`. A prompt
			# that never wins is reported as exactly that, not as a pickup fault.
			var arbiter: Node = get_first_node_in_group("interaction_arbiter")
			var pressed := false
			for _frame in 600:
				if warrens.get_node_or_null(^"Heartstone") == null:
					break
				if arbiter != null and arbiter.call("winning_provider") == prompt \
						and bool(arbiter.call("winner").get("actionable", false)):
					Input.action_press("interact")
					await physics_frame
					await physics_frame
					Input.action_release("interact")
					pressed = true
					for _settle in 30:
						await process_frame
					break
				await physics_frame
			if not pressed:
				_fail("vault activity: the Heartstone prompt never won the interaction arbiter; winner=%s owner=%s" % [
					arbiter.call("winner") if arbiter != null else {}, get_first_node_in_group("input_owner")])
			elif warrens.get_node_or_null(^"Heartstone") != null \
					or int((game.get("inventory") as RefCounted).call("count", "heartstone")) < 1 \
					or not bool(progression.call("has", "warrens_heartstone_taken")):
				_fail("vault activity: production Heartstone interaction did not settle its item and flag")
	await _vault_capture(world, capture_dir, "vault-reward")

	if not _party_uids(party).is_empty() and _party_uids(party) != initial_uids:
		_fail("vault activity: Elder/Heartstone activity changed the five owned creature UIDs")
	var once_flag := "warrens_once_elder_trailpup"
	if not bool(progression.call("has", once_flag)):
		_fail("vault activity: Elder victory did not set %s" % once_flag)
	var reward_before := _vault_reward_stock(game)
	if not bool(game.call("save_game", VAULT_ACTIVITY_SLOT)):
		_fail("vault activity: post-activity production save failed")
	if not bool(game.call("load_game", VAULT_ACTIVITY_SLOT)):
		_fail("vault activity: production disk load failed")
	if _party_uids(game.get("party")) != initial_uids:
		_fail("vault activity: save/load did not preserve the same five owned creature UIDs")
	if not bool((game.get("progression") as RefCounted).call("has", once_flag)) \
			or not bool((game.get("progression") as RefCounted).call("has", "warrens_heartstone_taken")):
		_fail("vault activity: save/load lost the Elder or Heartstone once flag")
	if elder != null and bool(elder.call("is_alive")):
		_fail("vault activity: save/load revived the defeated Elder")
	if warrens.get_node_or_null(^"Heartstone") != null:
		_fail("vault activity: save/load recreated the consumed Heartstone")
	var reward_again := _vault_reward_stock(game)
	if bool(warrens.call("grant_clear_reward")) or reward_again != reward_before:
		_fail("vault activity: cleared Warrens paid its reward again")
	if is_instance_valid(world):
		world.queue_free()
	_report_vault_activity()


func _admit_and_fight_vault_elder(_player: CharacterBody3D, _warrens: Node3D,
		elder: Node3D, director: Node, manager: Node, rig: Node3D) -> bool:
	var arbiter: Node = get_first_node_in_group("interaction_arbiter")
	for _frame in 600:
		if bool(manager.call("is_fighting")):
			break
		if arbiter != null and arbiter.call("winning_provider") == director \
				and bool(arbiter.call("winner").get("actionable", false)) \
				and director.call("_engageable") == elder:
			Input.action_press("interact")
			var press := InputEventAction.new()
			press.action = "interact"
			press.pressed = true
			Input.parse_input_event(press)
			await physics_frame
			await physics_frame
			Input.action_release("interact")
			var release := InputEventAction.new()
			release.action = "interact"
			release.pressed = false
			Input.parse_input_event(release)
			await physics_frame
			await physics_frame
		else:
			await physics_frame
	if not bool(manager.call("is_fighting")) or manager.call("enemy_body") != elder:
		_fail("vault activity: ordinary approach never admitted the Elder Trailpup; winner=%s candidate=%s owner=%s" % [
			arbiter.call("winner") if arbiter != null else {}, director.call("_engageable"), get_first_node_in_group("input_owner")])
		return false
	var pilot := COMBAT_PILOT.new(self, manager, director, rig)
	pilot.pilot = COMBAT_PILOT.Pilot.SPACER
	pilot.listen()
	for _frame in 30:
		await physics_frame
	await _vault_capture(_warrens.get_parent(), _vault_capture_dir(), "vault-fight")
	var result: Dictionary = await pilot.fight_to_the_end()
	if bool(manager.call("is_fighting")) or str(result.get("outcome", "")) != "won" \
			or pilot.hits_dealt <= 0:
		_fail("vault activity: input combat did not defeat the Elder with a landed hit")
		return false
	for _frame in 120:
		if get_first_node_in_group("input_owner") == null:
			break
		await physics_frame
	return true


func _vault_elder(warrens: Node3D) -> Node3D:
	for body: Node3D in warrens.call("population"):
		if str(body.get("display_name")) == "Elder Trailpup":
			return body
	return null


func _party_uids(party: RefCounted) -> Array[String]:
	var ids: Array[String] = []
	if party == null:
		return ids
	for member: RefCounted in party.call("members"):
		ids.append(str(member.get("uid")))
	return ids


func _vault_reward_stock(game: Node) -> Dictionary:
	var out := {}
	var inventory: RefCounted = game.get("inventory")
	var reward: Dictionary = _warrens_config().get("clear", {}).get("reward", {})
	out["potion_large"] = int(inventory.call("count", "potion_large"))
	out["heartstone"] = int(inventory.call("count", "heartstone"))
	out["coin"] = int(inventory.call("count", "coin"))
	for entry: Variant in reward.get("items", []):
		var id := str((entry as Dictionary).get("id", ""))
		if id != "":
			out[id] = int(inventory.call("count", id))
	return out


func _report_vault_activity() -> void:
	print("")
	if _failures.is_empty():
		print("warrens vault activity passed")
		quit(0)
		return
	for line in _failures:
		print("  FAIL: %s" % line)
	quit(1)


func _vault_capture_dir() -> String:
	for arg: String in OS.get_cmdline_user_args():
		if not arg.begins_with("--capture-dir="):
			continue
		if DisplayServer.get_name() == "headless":
			_fail("vault activity: --capture-dir requires a rendered run")
			return ""
		var path := arg.trim_prefix("--capture-dir=")
		if not path.is_absolute_path():
			_fail("vault activity: --capture-dir must be absolute")
			return ""
		if DirAccess.make_dir_recursive_absolute(path) != OK:
			_fail("vault activity: could not create capture directory")
			return ""
		return path
	return ""


func _vault_capture(world: Node, directory: String, label: String) -> void:
	if directory.is_empty():
		return
	await RenderingServer.frame_post_draw
	var image := world.get_viewport().get_texture().get_image()
	var error := image.save_png(directory.path_join("%s.png" % label))
	if error != OK:
		_fail("vault activity: could not save %s capture (%s)" % [label, error_string(error)])


## Focused G-9 runtime witness.  This is intentionally not another campaign
## harness: it boots the production playground and its real Warrens, director,
## manager, player camera and guardian, then watches four attacks and quits.
## The two position writes are declared fixture staging: one starts the fight
## in the den and one moves the target sideways after Earth Fist has committed.
##
## `--guardian-camera-diagnose` only prints the live camera state; it changes no
## placement or assertion. `--guardian-settled-approach` is a comparison mode:
## it starts from the supported hall, outside the guardian's notice range,
## waits for the normal rig to settle there, then makes one input-driven walk
## toward the den. It is still a fixture teleport to the hall, not an earned
## whole-dungeon traversal, and requires ordinary guardian aggression (no direct
## callback) to start the fight.
func _run_guardian_attacks() -> void:
	var game := root.get_node_or_null(^"/root/Game")
	var progression: RefCounted = game.get("progression") if game != null else null
	if progression == null:
		_fail("guardian attacks: no Game progression store")
		_report_guardian_attacks()
		return
	# A real fresh local identity and isolated save root, established after the
	# autoload's deferred-ready boundary and before the world exists.  The fight
	# never resolves, but the production host path still requires an identity.
	game.call("reset_for_new_game")
	game.set("save_system", SAVE_GAME.new(GUARDIAN_SAVE_DIR))
	if not bool(game.call("save_game", 4)):
		_fail("guardian attacks: fresh fixture identity could not be persisted")
		_report_guardian_attacks()
		return
	progression = game.get("progression")

	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	current_scene = world
	for i in SETTLE_FRAMES:
		await physics_frame

	var player := world.get_node_or_null(^"Player") as CharacterBody3D
	var warrens := world.get_node_or_null(^"BurrowWarrens") as Node3D
	var director := world.get_node_or_null(^"EncounterDirector")
	var manager := world.get_node_or_null(^"CombatManager")
	if player == null or warrens == null or director == null or manager == null:
		_fail("guardian attacks: production scene is missing Player, Warrens, director or manager")
		_report_guardian_attacks()
		return
	var guardian := warrens.call("guardian") as Node3D
	if guardian == null:
		_fail("guardian attacks: a fresh production Warrens spawned no guardian")
		_report_guardian_attacks()
		return

	if director.call("ally_instance") == null:
		await director.call("adopt_starter", "terrapup")
	var starter: RefCounted = director.call("ally_instance")
	if starter == null:
		_fail("guardian attacks: the real director could not adopt the declared Terrapup fixture")
		_report_guardian_attacks()
		return
	starter.call("set_level", 12, _progression_config())
	starter.set("hp", starter.get("max_hp"))
	var camera_diagnose := "--guardian-camera-diagnose" in OS.get_cmdline_user_args()
	var settled_approach := "--guardian-settled-approach" in OS.get_cmdline_user_args()

	guardian.global_position = warrens.call("marker", "guardian")
	if settled_approach:
		# The hall resident would be a second aggressive admission route. Leave
		# it visible, but quiet every non-guardian resident for this one control.
		for resident: Node3D in warrens.call("population"):
			if is_instance_valid(resident):
				resident.set("aggressive", false)
				resident.set_physics_process(false)
		var seed_start: Vector3 = warrens.call("marker", "hall")
		var supported_y := float(warrens.call("built_floor_height_at", seed_start.x, seed_start.z))
		if is_nan(supported_y):
			_fail("guardian attacks: settled approach hall start has no Warrens built floor")
			_report_guardian_attacks()
			return
		await _put_down(player, Vector3(seed_start.x, supported_y + 1.2, seed_start.z))
		if not player.is_on_floor() or absf(player.global_position.y - supported_y) > 1.5:
			_fail("guardian attacks: settled approach hall start did not settle on the built floor")
			_report_guardian_attacks()
			return
		var notice := 14.0
		var distance_to_guardian := player.global_position.distance_to(guardian.global_position)
		if distance_to_guardian <= notice:
			_fail("guardian attacks: settled approach hall start is %.1fm inside guardian notice %.1fm" % [distance_to_guardian, notice])
			_report_guardian_attacks()
			return
		print("guardian camera control: seed_start=hall:%s supported_y=%.2f guardian_distance=%.1f; fixture teleport only" % [
			seed_start, supported_y, distance_to_guardian])
		if not await _wait_for_guardian_camera_settle(world, player, 180):
			_fail("guardian attacks: camera did not settle behind the hall start within 180 frames")
			_report_guardian_attacks()
			return
		if camera_diagnose:
			_guardian_camera_diagnosis("settled hall start before approach", world, manager, player, null, guardian)
		var natural := {"announced": false}
		guardian.connect("wants_to_engage", func() -> void:
			natural.announced = true
		)
		var walked := await _walk_to(player, warrens, guardian.global_position, ARRIVED_M, manager)
		if not bool(manager.call("is_fighting")) or not bool(natural.announced):
			_fail("guardian attacks: hall-to-den walk covered %.1fm without guardian natural admission" % walked)
			_report_guardian_attacks()
			return
		print("guardian camera control: guardian naturally admitted after %.1fm input walk" % walked)
	else:
		# Declared fixture placement only: combat itself remains the real
		# aggressive engage path, real manager and real bodies. No controller
		# traversal is claimed by this focused witness.
		player.global_position = warrens.call("marker", "den") + Vector3(0.0, 1.0, 0.0)
		player.velocity = Vector3.ZERO
		if camera_diagnose:
			_guardian_camera_diagnosis("teleported den-adjacent start", world, manager, player, null, guardian)
		director.call("_on_wild_wants_to_engage", guardian)
	for i in 120:
		if bool(manager.call("is_fighting")):
			break
		await physics_frame
	if not bool(manager.call("is_fighting")):
		_fail("guardian attacks: the production aggressive engage route did not open combat")
		_report_guardian_attacks()
		return

	var ally := director.call("ally_body") as Node3D
	if camera_diagnose:
		_guardian_camera_diagnosis("combat formation", world, manager, player, ally, guardian)
	var attacks: Array[Dictionary] = []
	var capture_dir := _guardian_capture_dir()
	var locked_heading := Vector3.ZERO
	var heading_checked := false
	var lock_watch_until_frame := 0
	var physics_hz := float(ProjectSettings.get_setting("physics/common/physics_ticks_per_second", 60.0))
	# Lambdas mutate this one reference. Captured primitive locals are copied by
	# GDScript and would leave the observing loop stuck at zero forever.
	var observed := {
		"strikes": 0,
		"enemy_hits": 0,
		"enemy_misses": 0,
		"pending_capture": false,
		"move_sideways": false,
	}

	guardian.connect("telegraph_started", func(seconds: float) -> void:
		if attacks.size() >= 4:
			return
		var cfg := (guardian.call("combat_config") as Dictionary).duplicate(true)
		attacks.append({
			"seconds": seconds,
			"cfg": cfg,
			"heading": guardian.call("facing"),
			"started_frame": Engine.get_physics_frames(),
		})
		observed.pending_capture = capture_dir != "" and attacks.size() <= 2
		observed.move_sideways = str(cfg.get("move_id", "")) == "earth_fist"
		if camera_diagnose:
			_guardian_strike_diagnosis("telegraph", cfg, guardian, ally)
		if camera_diagnose and attacks.size() <= 2:
			_guardian_camera_diagnosis("%s telegraph" % [str(cfg.get("move_id", "quick"))],
				world, manager, player, ally, guardian)
	)
	guardian.connect("strike_ready", func() -> void:
		if int(observed.strikes) >= 4:
			return
		observed.strikes = int(observed.strikes) + 1
		if int(observed.strikes) <= attacks.size():
			attacks[int(observed.strikes) - 1]["strike_frame"] = Engine.get_physics_frames()
			if camera_diagnose:
				_guardian_strike_diagnosis("strike",
					attacks[int(observed.strikes) - 1].cfg as Dictionary, guardian, ally)
	)
	manager.connect("attack_missed", func(by_player: bool) -> void:
		if not by_player:
			observed.enemy_misses = int(observed.enemy_misses) + 1
	)
	manager.connect("hit_landed", func(on_enemy: bool, _amount: float) -> void:
		if not on_enemy:
			observed.enemy_hits = int(observed.enemy_hits) + 1
	)

	var frames := 0
	var moved_for_attack := -1
	while int(observed.strikes) < 4 and frames < GUARDIAN_ATTACK_FRAME_LIMIT and bool(manager.call("is_fighting")):
		# Survival staging is explicit and cannot defeat or reward the guardian.
		starter.set("hp", starter.get("max_hp"))
		if bool(observed.pending_capture):
			await RenderingServer.frame_post_draw
			var label := "quick" if attacks.size() == 1 else "charged"
			var image := root.get_viewport().get_texture().get_image()
			var error := image.save_png(capture_dir.path_join("guardian_%s_tell.png" % label))
			if error != OK:
				_fail("guardian attacks: could not save the %s tell capture (%s)" % [label, error_string(error)])
			observed.pending_capture = false
		if bool(observed.move_sideways) and moved_for_attack != attacks.size() and not attacks.is_empty():
			var current: Dictionary = attacks.back()
			var tell_frames := int(ceil(float(current.seconds) * physics_hz))
			if Engine.get_physics_frames() - int(current.started_frame) >= tell_frames / 2 + 2:
				locked_heading = guardian.call("facing")
				var lateral := Vector3(-locked_heading.z, 0.0, locked_heading.x).normalized()
				ally.global_position = guardian.global_position + lateral * 4.0
				moved_for_attack = attacks.size()
				observed.move_sideways = false
				# Stay just inside the authored recovery boundary; on the next
				# tick the body is allowed to resume tracking for reposition.
				lock_watch_until_frame = int(current.started_frame) + tell_frames \
					+ int(ceil(float((current.cfg as Dictionary).get("recovery", 0.0)) * physics_hz)) - 2
		if lock_watch_until_frame > 0 and Engine.get_physics_frames() <= lock_watch_until_frame:
			var during_lock: Vector3 = guardian.call("facing")
			if locked_heading.dot(during_lock) < 0.999:
				_fail("guardian attacks: Earth Fist heading changed during its final-half tell/recovery lock")
		await physics_frame
		if lock_watch_until_frame > 0 and Engine.get_physics_frames() > lock_watch_until_frame:
			heading_checked = true
			lock_watch_until_frame = 0
		frames += 1

	if frames >= GUARDIAN_ATTACK_FRAME_LIMIT:
		_fail("guardian attacks: four strikes exceeded the %d-frame ceiling" % GUARDIAN_ATTACK_FRAME_LIMIT)
	if int(observed.strikes) != 4 or attacks.size() != 4:
		_fail("guardian attacks: observed %d telegraphs and %d strikes, expected four of each" % [attacks.size(), int(observed.strikes)])
	else:
		_grade_guardian_attacks(attacks)
	if int(observed.enemy_hits) == 0 or int(observed.enemy_misses) == 0:
		_fail("guardian attacks: real resolution produced %d hit(s) and %d miss(es); expected both" % [int(observed.enemy_hits), int(observed.enemy_misses)])
	else:
		print("guardian attacks resolved through CombatManager: %d hit(s), %d miss(es)" % [int(observed.enemy_hits), int(observed.enemy_misses)])
	if not heading_checked:
		_fail("guardian attacks: no charged tell reached the final-half heading-lock witness")
	_report_guardian_attacks()


## Prints the actual capture camera and the only colliders overlapping its lens.
## This deliberately does not derive an invented "visibility score": arm hit
## length plus named lens contacts lets the rendered control distinguish a
## fixture teleport/follow-lag obstruction from an ordinary room obstruction.
func _guardian_camera_diagnosis(label: String, world: Node, manager: Node,
		player: Node3D, ally: Node3D, guardian: Node3D) -> void:
	var rig := world.get_node_or_null(^"CameraRig") as SpringArm3D
	if rig == null:
		print("guardian camera diag [%s]: no CameraRig" % label)
		return
	var camera := rig.get_node_or_null(^"Camera3D") as Camera3D
	var target := rig.get("_target") as Node
	var clearance := NAN
	if manager != null and manager.has_method("_room_clearance"):
		clearance = float(manager.call("_room_clearance"))
	print("guardian camera diag [%s]: process=%s target=%s rig=%s camera=%s player=%s ally=%s guardian=%s room_clearance=%.2f arm_requested=%.2f arm_hit=%.2f" % [
		label, rig.is_processing(), _guardian_diag_node(target), rig.global_position,
		camera.global_position if camera != null else Vector3.ZERO,
		_guardian_diag_position(player), _guardian_diag_position(ally),
		_guardian_diag_position(guardian), clearance, rig.spring_length, rig.get_hit_length()])
	if camera == null:
		return
	var lens_shape := SphereShape3D.new()
	lens_shape.radius = 0.35
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = lens_shape
	query.transform = Transform3D(Basis(), camera.global_position)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var contacts: Array[String] = []
	for hit: Dictionary in camera.get_world_3d().direct_space_state.intersect_shape(query, 12):
		var collider := hit.get("collider", null) as Node
		contacts.append(_guardian_diag_node(collider))
	print("guardian camera diag [%s]: lens-overlap(0.35m)=%s" % [
		label, "none" if contacts.is_empty() else ", ".join(contacts)])


func _guardian_diag_position(node: Node3D) -> Vector3:
	return node.global_position if node != null and is_instance_valid(node) else Vector3.ZERO


func _guardian_diag_node(node: Node) -> String:
	return str(node.get_path()) if node != null and is_instance_valid(node) else "none"


## The camera witness also records why each real enemy strike can or cannot
## connect. Values come from the captured tell config, not a later AI update.
func _guardian_strike_diagnosis(phase: String, cfg: Dictionary,
		guardian: Node3D, ally: Node3D) -> void:
	if guardian == null or ally == null:
		return
	var to_ally := ally.global_position - guardian.global_position
	to_ally.y = 0.0
	var gap := to_ally.length()
	var facing: Vector3 = guardian.call("facing")
	facing.y = 0.0
	var angle := rad_to_deg(facing.angle_to(to_ally.normalized())) if facing.length() > 0.01 and gap > 0.01 else NAN
	var guardian_radius := float(guardian.call("body_radius")) if guardian.has_method("body_radius") else NAN
	var ally_radius := float(ally.call("body_radius")) if ally.has_method("body_radius") else NAN
	var guardian_grounded: bool = (guardian as CharacterBody3D).is_on_floor() if guardian is CharacterBody3D else false
	var ally_grounded: bool = (ally as CharacterBody3D).is_on_floor() if ally is CharacterBody3D else false
	print("guardian strike diag [%s]: move=%s guardian=%s ally=%s horizontal_gap=%.2f preferred_range=%.2f range=%.2f cone_degrees=%.1f facing_target_angle=%.1f guardian_radius=%.2f ally_radius=%.2f guardian_grounded=%s ally_grounded=%s" % [
		phase, str(cfg.get("move_id", "quick")), guardian.global_position, ally.global_position, gap,
		float(cfg.get("preferred_range", NAN)), float(cfg.get("range", NAN)),
		float(cfg.get("cone_degrees", NAN)), angle, guardian_radius, ally_radius,
		guardian_grounded, ally_grounded])


## The live rig has no snap on an ordinary retarget. Its pivot must arrive at
## the current trainer target before the control begins to walk toward danger.
func _wait_for_guardian_camera_settle(world: Node, player: CharacterBody3D,
		frame_cap: int) -> bool:
	var rig := world.get_node_or_null(^"CameraRig") as SpringArm3D
	if rig == null:
		return false
	for _i in frame_cap:
		var target := rig.get("_target") as Node3D
		var desired := player.global_position + Vector3.UP * float(rig.get("_height"))
		desired += Basis(Vector3.UP, float(rig.get("yaw"))).x * float(rig.get("_shoulder"))
		if target == player and rig.global_position.distance_to(desired) < 0.3:
			return true
		await physics_frame
	return false


func _grade_guardian_attacks(attacks: Array[Dictionary]) -> void:
	var earth: Dictionary = MOVE_DB.new().move("earth_fist")
	if not is_equal_approx(float(earth.get("range", -1.0)), 3.8) \
			or not is_equal_approx(float(earth.get("cone_degrees", -1.0)), 72.0) \
			or not is_equal_approx(float(earth.get("lunge", -1.0)), 6.5):
		_fail("guardian attacks: Earth Fist no longer declares 3.8m / 72deg / 6.5m in MoveDB")
	for index in attacks.size():
		var cfg: Dictionary = attacks[index].cfg
		var charged := str(cfg.get("move_id", "")) == "earth_fist"
		var expected_charged := index % 2 == 1
		if charged != expected_charged:
			_fail("guardian attacks: attack %d was %s; expected %s" % [index + 1,
				"charged" if charged else "quick", "charged" if expected_charged else "quick"])
		var expected_tell := 1.1 if expected_charged else 0.85
		var expected_recovery := 1.2 if expected_charged else 1.1
		if not is_equal_approx(float(attacks[index].seconds), expected_tell) \
				or not is_equal_approx(float(cfg.get("recovery", -1.0)), expected_recovery):
			_fail("guardian attacks: attack %d used tell/recovery %.2f/%.2f, expected %.2f/%.2f" % [
				index + 1, float(attacks[index].seconds), float(cfg.get("recovery", -1.0)),
				expected_tell, expected_recovery])
		if expected_charged:
			for key: String in ["cone_degrees", "lunge"]:
				if not is_equal_approx(float(cfg.get(key, -1.0)), float(earth.get(key, -2.0))):
					_fail("guardian attacks: Earth Fist %s did not come from MoveDB" % key)
			# Body-clearance spacing may only extend named reach; it must never
			# erase Earth Fist's authored 3.8m reach.
			if float(cfg.get("range", 0.0)) < float(earth.get("range", 3.8)):
				_fail("guardian attacks: Earth Fist live reach is shorter than MoveDB range")
		elif not is_equal_approx(float(cfg.get("cone_degrees", -1.0)), 90.0) \
				or not is_equal_approx(float(cfg.get("lunge", -1.0)), 3.4):
			_fail("guardian attacks: quick attack did not retain generic enemy geometry")
		var physics_hz := float(ProjectSettings.get_setting("physics/common/physics_ticks_per_second", 60.0))
		var elapsed := (int(attacks[index].get("strike_frame", 0)) \
			- int(attacks[index].get("started_frame", 0))) / physics_hz
		if absf(elapsed - expected_tell) > 0.15:
			_fail("guardian attacks: attack %d signal interval was %.2fs, expected %.2fs" % [
				index + 1, elapsed, expected_tell])
	print("guardian attack sequence: %s" % ", ".join(attacks.map(func(a: Dictionary) -> String:
		return "C" if str((a.cfg as Dictionary).get("move_id", "")) == "earth_fist" else "Q")))


func _guardian_capture_dir() -> String:
	for arg: String in OS.get_cmdline_user_args():
		if not arg.begins_with("--capture-dir="):
			continue
		if DisplayServer.get_name() == "headless":
			_fail("guardian attacks: --capture-dir requires a rendered, non-headless run")
			return ""
		var path := arg.trim_prefix("--capture-dir=")
		if not path.is_absolute_path():
			_fail("guardian attacks: --capture-dir must be an absolute path")
			return ""
		var error := DirAccess.make_dir_recursive_absolute(path)
		if error != OK:
			_fail("guardian attacks: could not create capture directory (%s)" % error_string(error))
			return ""
		return path
	return ""


func _report_guardian_attacks() -> void:
	print("")
	if _failures.is_empty():
		print("warrens guardian attack witness passed")
		quit(0)
		return
	for line in _failures:
		print("  FAIL: %s" % line)
	quit(1)


## Stand the player in the deepest chamber and push at the far wall. A room
## with no walls lets them out; a room with a floor keeps them off the terrain
## that is now metres overhead.
func _the_cave_is_enclosed(world: Node, player: CharacterBody3D, warrens: Node3D) -> void:
	var den: Vector3 = warrens.call("marker", "den")
	var floor_y := den.y
	await _put_down(player, den + Vector3(0.0, 1.2, 0.0))

	if not player.is_on_floor():
		_fail("the player does not stand on the cave floor in the deepest chamber")
	var resting := player.global_position.y
	if absf(resting - floor_y) > 1.5:
		_fail("the player settled at y=%.2f in the den, but its floor is y=%.2f" % [resting, floor_y])
	var terrain: float = float(world.call("ground_height_at", den.x, den.z))
	print("den floor y=%.2f, player rests at y=%.2f, terrain at the same spot y=%.2f" % [
		floor_y, resting, terrain])
	_no_ground_comes_through_a_floor(world, warrens)

	# Push away from the mouth, i.e. at the far wall of the last chamber.
	var before := player.global_position
	var out := -warrens.global_basis.z  # local -z is back toward the entrance
	var into_the_rock := -out
	await _push(player, into_the_rock)
	var travelled := before.distance_to(player.global_position)
	print("pushed %.1fm into the den's far wall" % travelled)
	if travelled > 12.0:
		_fail("the player walked %.1fm through the deepest chamber's far wall; it is not enclosed" % travelled)
	if player.global_position.y > floor_y + 3.0:
		_fail("the player climbed out of the cave (y=%.1f vs floor %.1f)" % [
			player.global_position.y, floor_y])

	# And the way IN works: dropped outside the mouth, they can walk in.
	var entrance: Vector3 = warrens.call("marker", "entrance")
	await _put_down(player, entrance + Vector3(0.0, 1.5, 0.0))
	var start := player.global_position
	await _push(player, warrens.global_basis.z)
	var mouth: Vector3 = warrens.call("marker", "mouth")
	var reached := player.global_position.distance_to(mouth)
	print("walked %.1fm in from the entrance; %.1fm from the mouth chamber centre" % [
		start.distance_to(player.global_position), reached])
	if reached > 12.0:
		_fail("walking straight in from the entrance never reached the mouth chamber (%.1fm short)" % reached)


## The check that would have caught BAND2-63-WARRENS a whole relocation
## earlier, and did not exist.
##
## What shipped from OW5D was a cave translated onto ground nobody had probed:
## the terrain surface ran THROUGH the hall, the player walked up it and jammed
## against the ceiling, and the den -- guardian, clear flag, heartstone -- was
## unreachable on foot. Every assertion in this file passed, because every one
## of them teleports the player into the chamber it is about.
##
## The rule a cave has to keep is simple and does not care whether it is buried
## in a flank or standing in a knoll of its own: at no point under a chamber
## may the ground be BETWEEN that chamber's floor and its ceiling. Above the
## ceiling is a buried room. Below the floor is a room standing proud on its
## own skirt. In between is a room with a hillside in it.
func _no_ground_comes_through_a_floor(world: Node, warrens: Node3D) -> void:
	var config := _warrens_config()
	var site: Dictionary = config.get("site", {})
	var floor_y: float = warrens.global_position.y + float(site.get("floor_clearance", 0.35))
	var worst := 0.0
	var worst_id := ""
	for entry: Variant in config.get("chambers", []):
		var chamber: Dictionary = entry as Dictionary
		var centre: Array = chamber.get("at", [0.0, 0.0])
		var size: Array = chamber.get("size", [4.0, 4.0])
		var ceiling: float = floor_y + float(chamber.get("height", 4.0))
		for ix in 5:
			for iz in 5:
				var local := Vector3(
					float(centre[0]) + float(size[0]) * (float(ix) / 4.0 - 0.5),
					0.0,
					float(centre[1]) + float(size[1]) * (float(iz) / 4.0 - 0.5))
				var at: Vector3 = warrens.to_global(local)
				var ground := float(world.call("ground_height_at", at.x, at.z))
				if is_nan(ground):
					continue
				# How far INTO the room the ground reaches, if it does at all.
				var into: float = minf(ground - floor_y, ceiling - ground)
				if into > worst:
					worst = into
					worst_id = str(chamber.get("id", ""))
	print("deepest the ground reaches into any chamber: %.2f m%s" % [
		worst, "" if worst_id == "" else " (%s)" % worst_id])
	if worst > 0.35:
		_fail("the ground surfaces %.2fm inside the '%s' chamber; the player will walk up it"
			% [worst, worst_id])


## The other half of the same lesson: walk the whole thing, with the player's
## own controller, through the doorways, in one go.
##
## `_push()` below drives `velocity` with `_physics_process` SUSPENDED, which is
## correct for the wall tests it was written for and useless for this one --
## `player_controller.gd::_try_step_up()` is what gets a CharacterBody3D over
## the cave's own doorway sill and it runs in `_physics_process`. So this
## presses the real `move_forward` action and steers by yawing the camera the
## movement is relative to, which is what a player does.
func _the_route_can_be_walked(player: CharacterBody3D, warrens: Node3D,
		progression: RefCounted) -> void:
	var config := _warrens_config()
	var chambers: Dictionary = {}
	for entry: Variant in config.get("chambers", []):
		chambers[str((entry as Dictionary).get("id", ""))] = entry
	await _put_down(player, warrens.call("marker", "entrance") + Vector3(0.0, 1.5, 0.0))
	# The branch door is the one thing on this route that is SUPPOSED to stop
	# the player, and the test above has already proved it does.
	progression.call("set_flag", "warrens_cleared")
	warrens.call("grant_clear_reward")
	var walked := 0.0
	for leg: String in ["mouth", "hall", "den", "vault"]:
		for target: Vector3 in _doorway_then_room(warrens, config, chambers, leg):
			walked += await _walk_to(player, warrens, target)
		var short: float = player.global_position.distance_to(warrens.call("marker", leg))
		if short > 3.5:
			_fail("walking the cave never reached the '%s' chamber (stopped %.1fm short)"
				% [leg, short])
			return
	print("walked the whole cave, entrance to branch chamber: %.0f m" % walked)


## The doorway into a chamber, then the chamber. A passage's side walls overlap
## the chamber wall they cut by `wall_thickness`, leaving a stub inside the room
## at the corner of the doorway; a person steers round it without noticing and a
## straight line into the far room's centre wedges on it.
func _doorway_then_room(warrens: Node3D, config: Dictionary, chambers: Dictionary,
		id: String) -> Array:
	var out: Array = []
	var room: Vector3 = warrens.call("marker", id)
	for entry: Variant in config.get("passages", []):
		var passage: Dictionary = entry as Dictionary
		if str(passage.get("to", "")) != id or not chambers.has(str(passage.get("from", ""))):
			continue
		var a: Array = (chambers[str(passage.get("from", ""))] as Dictionary).get("at", [0.0, 0.0])
		var b: Array = (chambers[id] as Dictionary).get("at", [0.0, 0.0])
		out.append(warrens.to_global(Vector3(
			(float(a[0]) + float(b[0])) * 0.5,
			room.y - warrens.global_position.y,
			(float(a[1]) + float(b[1])) * 0.5)))
	out.append(room)
	return out


## Hold `move_forward` with the camera yawed at `target` until the player is
## within `ARRIVED_M` of it or the budget runs out. Returns metres walked.
func _walk_to(player: CharacterBody3D, warrens: Node3D, target: Vector3,
		arrived_m: float = ARRIVED_M, stop_when_fighting: Node = null) -> float:
	var rig: Node3D = _camera_rig(player)
	var walked := 0.0
	var frames := 0
	Input.action_press("move_forward")
	while frames < WALK_FRAMES:
		if stop_when_fighting != null and bool(stop_when_fighting.call("is_fighting")):
			break
		var to_target := target - player.global_position
		to_target.y = 0.0
		if to_target.length() <= arrived_m:
			break
		if rig != null:
			# camera_rig.gd:239's own convention: the camera sits behind the
			# direction of travel.
			var yaw := atan2(-to_target.x, -to_target.z)
			rig.set("yaw", yaw)
			rig.rotation = Vector3(rig.rotation.x, yaw, 0.0)
		var before := player.global_position
		await physics_frame
		walked += Vector2(player.global_position.x - before.x,
			player.global_position.z - before.z).length()
		frames += 1
	Input.action_release("move_forward")
	if Vector2(player.global_position.x - target.x, player.global_position.z - target.z).length() > arrived_m:
		print("warrens walk stopped: local=%s target=%s velocity=%s floor=%s floor_normal=%s walked=%.2f frames=%d" % [
			warrens.to_local(player.global_position), warrens.to_local(target), player.velocity,
			player.is_on_floor(), player.get_floor_normal(), walked, frames])
		for index in player.get_slide_collision_count():
			var hit := player.get_slide_collision(index)
			var collider := hit.get_collider()
			print("warrens walk collision: %s at=%s normal=%s" % [
				str((collider as Node).get_path()) if collider is Node else str(collider),
				warrens.to_local(hit.get_position()), hit.get_normal()])
	return walked


## OWNER-0912 Tier 2 #5, runtime half. The static identity test proves the new
## data describes an asymmetrical approach; this proves the production build
## actually mounted every authored piece and did not turn any apparently-solid
## dressing into a collider. Bounds are measured after each model's authored
## rotation/scale, in the Warrens' local frame, so a mesh that swings into the
## centre lane fails even when its unrotated `size_m` looked legal in JSON.
func _the_approach_composition_is_mounted_and_clear(player: CharacterBody3D,
		warrens: Node3D) -> void:
	var holder := warrens.get_node_or_null(^"ApproachComposition") as Node3D
	if holder == null:
		_fail("OWNER-0912: the production Warrens built no ApproachComposition")
		return
	if not holder.has_meta("warrens_exterior"):
		_fail("OWNER-0912: ApproachComposition is not mounted as exterior geometry")

	var collision := player.get_node_or_null(^"Collision") as CollisionShape3D
	var capsule := collision.shape as CapsuleShape3D if collision != null else null
	if capsule == null:
		_fail("OWNER-0912: the production Player no longer has its capsule collision shape")
	else:
		print("approach traversal uses production capsule r=%.2fm h=%.2fm" % [
			capsule.radius, capsule.height])

	var cfg: Dictionary = _warrens_config().get("bank", {}).get("approach_composition", {})
	var clear_half := float(cfg.get("clear_half_width_m", 0.0))
	if clear_half <= (capsule.radius if capsule != null else 0.4):
		_fail("OWNER-0912: the configured approach lane does not clear the production capsule")
	var mounted := 0
	# The repaired approach replaced the rejected stretched ribs/windfall with
	# three uniformly scaled root shoulders. Validate the production schema that
	# now mounts instead of silently iterating the retired keys.
	for list_key: String in ["root_shoulders"]:
		for raw: Variant in cfg.get(list_key, []):
			if not raw is Dictionary:
				continue
			var id := str((raw as Dictionary).get("id", ""))
			var piece := holder.get_node_or_null(NodePath(id)) as Node3D
			if piece == null:
				_fail("OWNER-0912: authored approach piece '%s' did not mount" % id)
				continue
			mounted += 1
			if not piece.has_meta("warrens_exterior"):
				_fail("OWNER-0912: approach piece '%s' lost its exterior mount tag" % id)
			if not piece.find_children("*", "CollisionObject3D", true, false).is_empty():
				_fail("OWNER-0912: visual approach piece '%s' added collision in the walk lane" % id)
			var box := warrens.call("_bounds_of", piece) as AABB
			if box.size == Vector3.ZERO:
				_fail("OWNER-0912: mounted approach piece '%s' draws no measurable geometry" % id)
				continue
			var lateral_clear := 0.0 if box.position.x <= 0.0 and box.end.x >= 0.0 \
				else minf(absf(box.position.x), absf(box.end.x))
			if lateral_clear < clear_half:
				_fail("OWNER-0912: rotated approach piece '%s' reaches x=%.2f inside the %.2fm clear lane" % [
					id, lateral_clear, clear_half])

	var ruts := holder.get_node_or_null(^"ApproachRuts") as MeshInstance3D
	if ruts == null or ruts.mesh == null or ruts.mesh.get_surface_count() == 0:
		_fail("OWNER-0912: the two production approach ruts did not mount as geometry")
	elif not ruts.find_children("*", "CollisionObject3D", true, false).is_empty():
		_fail("OWNER-0912: the visual approach ruts unexpectedly carry collision")
	elif not ruts.has_meta("warrens_exterior"):
		_fail("OWNER-0912: the production approach ruts lost their exterior mount tag")
	elif str(ruts.get_meta("warrens_approach_role", "")) != "embedded_wear":
		_fail("OWNER-0912: the production approach ruts are no longer embedded wear")
	print("approach composition: %d solid-looking pieces mounted outside the %.1fm half-lane; ruts=%s" % [
		mounted, clear_half, ruts != null])


## The old ingress check starts at the `entrance` marker, local z=-2: already
## five metres inside the rebuilt throat. Start instead on the far half of the
## 24m ruts, steer the production controller through five samples of the real
## curved throat centreline into the mouth chamber, then reverse the same route.
## No teleport occurs between the roadside start and the completed egress.
func _the_approach_can_be_entered_and_exited(world: Node, player: CharacterBody3D,
		warrens: Node3D) -> void:
	if not warrens.has_method("_throat_curve_offset"):
		_fail("OWNER-0912: the production Warrens exposes no curved-throat centreline")
		return
	var config := _warrens_config()
	var bank: Dictionary = config.get("bank", {})
	var approach: Dictionary = bank.get("approach_composition", {})
	var mouth: Vector3 = warrens.call("marker", "mouth")
	var mouth_local := warrens.to_local(mouth)
	var mouth_spec: Dictionary = {}
	for raw: Variant in config.get("chambers", []):
		if raw is Dictionary and str((raw as Dictionary).get("id", "")) == "mouth":
			mouth_spec = raw as Dictionary
			break
	if mouth_spec.is_empty():
		_fail("OWNER-0912: no mouth chamber data for the approach traversal")
		return
	var mouth_size: Array = mouth_spec.get("size", [])
	var z0 := mouth_local.z - float(mouth_size[1]) * 0.5
	var z_front := z0 - float(bank.get("throat_depth_m", 0.0))
	var z_back := z0 + float(bank.get("throat_overlap_m", 0.0))
	var rut_length := float(approach.get("rut_length_m", 0.0))
	var road_z := z_front - minf(18.0, rut_length * 0.75)
	var road_flat := warrens.to_global(Vector3(0.0, mouth_local.y, road_z))
	var road_ground := float(world.call("ground_height_at", road_flat.x, road_flat.z))
	if is_nan(road_ground):
		_fail("OWNER-0912: the far approach ruts have no production ground")
		return
	await _put_down(player, Vector3(road_flat.x, road_ground + 1.2, road_flat.z))

	var inward: Array[Vector3] = [
		warrens.to_global(Vector3(0.0, mouth_local.y, z_front - 1.0)),
	]
	for t: float in [0.08, 0.30, 0.52, 0.74, 0.96]:
		var z := lerpf(z_front, z_back, t)
		var x := float(warrens.call("_throat_curve_offset", z, z_front, z_back))
		inward.append(warrens.to_global(Vector3(x, mouth_local.y, z)))
	inward.append(mouth)

	var walked := 0.0
	for target: Vector3 in inward:
		walked += await _walk_to(player, warrens, target, 0.75)
		var remaining := Vector2(player.global_position.x - target.x,
			player.global_position.z - target.z).length()
		if remaining > 1.0:
			_fail("OWNER-0912: player capsule stopped %.2fm short during real ingress at local %s" % [
				remaining, warrens.to_local(target)])
			return
	var entered := warrens.to_local(player.global_position)
	if entered.z < z0 + 1.5:
		_fail("OWNER-0912: ingress never carried the player capsule into the mouth chamber (local z %.2f)" % entered.z)

	var outward: Array[Vector3] = inward.duplicate()
	outward.reverse()
	outward.pop_front()
	outward.append(road_flat)
	for target: Vector3 in outward:
		walked += await _walk_to(player, warrens, target, 0.75)
		var remaining := Vector2(player.global_position.x - target.x,
			player.global_position.z - target.z).length()
		if remaining > 1.0:
			_fail("OWNER-0912: player capsule stopped %.2fm short during real egress at local %s" % [
				remaining, warrens.to_local(target)])
			return
	var exited := warrens.to_local(player.global_position)
	if exited.z > z_front - 10.0:
		_fail("OWNER-0912: egress stopped at local z %.2f instead of returning to the roadside ruts" % exited.z)
	if not player.is_on_floor():
		_fail("OWNER-0912: player capsule is unsupported after the Warrens egress")
	if walked < 45.0:
		_fail("OWNER-0912: ingress/egress covered only %.1fm; the out-and-back traversal did not happen" % walked)
	else:
		print("approach ingress/egress: walked %.1fm from local z %.1f through the mouth and back" % [
			walked, road_z])


func _camera_rig(player: CharacterBody3D) -> Node3D:
	var named: Variant = player.get("_camera_rig")
	if named is Node3D and is_instance_valid(named as Node3D):
		return named as Node3D
	for child in player.get_parent().get_children():
		if child is Node3D and child.has_method("planar_basis"):
			return child as Node3D
	return null


func _warrens_config() -> Dictionary:
	var file := FileAccess.open("res://data/config/burrow_warrens.json", FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}


func _the_population_and_the_guardian_are_placed(warrens: Node3D) -> void:
	var population: Array = warrens.call("population")
	if population.is_empty():
		_fail("the warrens spawned no wild creatures at all")
	else:
		var aggressive := 0
		for body: Node3D in population:
			if is_instance_valid(body) and bool(body.get("aggressive")):
				aggressive += 1
		print("%d wild creatures inside, %d of them aggressive" % [population.size(), aggressive])
		if aggressive == 0:
			_fail("nothing in the warrens is aggressive; spec Band 2 asks for aggressive Ground creatures")

	var guardian: Node3D = warrens.call("guardian")
	if guardian == null or not is_instance_valid(guardian):
		_fail("no guardian was placed")
		return
	var instance: RefCounted = guardian.get("instance")
	var level := int(instance.get("level")) if instance != null else 0
	print("guardian: %s at level %d, standing at %.0f, %.1f, %.0f" % [
		str(guardian.get("species_id")), level,
		guardian.global_position.x, guardian.global_position.y, guardian.global_position.z])
	# "Outclasses the field" is a RELATIVE claim, so measure it against the
	# field. This was a bare `level < 15` until SH47 retuned the warrens down
	# to sit where a player leaving Band 1 actually is (residents 10-13 -> 9-11,
	# guardian 18 -> 14) and the constant failed a guardian that had in fact
	# got RELATIVELY stronger: 15 was two levels over the old deepest resident,
	# 14 is three over the new one. A magic number here silently pins the
	# dungeon's tuning to whatever it happened to be the day it was written.
	var deepest := 0
	for body: Node3D in population:
		var resident: RefCounted = body.get("instance") if is_instance_valid(body) else null
		if resident != null:
			deepest = maxi(deepest, int(resident.get("level")))
	if level <= deepest:
		_fail("the guardian is level %d and the warrens' own residents reach %d; "
			% [level, deepest] + "it is supposed to outclass the field, not join it")
	var den: Vector3 = warrens.call("marker", "den")
	if guardian.global_position.distance_to(den) > 14.0:
		_fail("the guardian is not in its own chamber")

	# CONTENT-0828B. The owner's complaint was that the descent has no payoff,
	# and CONTENT-0828's answer to it was that the cave HAD an alpha and a
	# prize but the alpha did not READ as one -- it wore the ordinary
	# burrowback texture at a model-only scale, so a roadside duskhush looked
	# more like an alpha than the chapter's boss. Every part of that answer was
	# presentation, and NOTHING asserted any of it: the whole payoff could
	# regress to a big ordinary burrowback and this test would still pass and
	# still print the same line. Asserted against the config rather than
	# against numbers repeated here, so retuning the guardian stays a data edit.
	var spec: Dictionary = _warrens_config().get("guardian", {})
	if not guardian.has_meta("alpha"):
		_fail("the guardian is not marked as an alpha; encounter_director's own "
			+ "field alphas are, and the dungeon boss reading as less of an alpha "
			+ "than a roadside spawn is the defect CONTENT-0828 fixed")
	var want_scale := float(spec.get("scale", 1.0))
	if want_scale > 1.0:
		# The GAMEPLAY size, not the art pivot, and read through the public
		# accessors rather than off `body_scale`. `body_scale` is the
		# BEFORE-populate input field; the guardian is dressed AFTER the
		# director has spawned it, so it goes through
		# `apply_size_multiplier()`, which scales the live `_height`/`_radius`
		# and leaves `body_scale` at 1.0. Asserting the field would have
		# reported a bug that is not there and missed the one that would be.
		#
		# What is actually being asserted: `body_height()`/`body_radius()` are
		# what the capsule, the hit cone's reach and the catch accuracy bonus
		# all read, so if these moved with the silhouette then the fight moved
		# with it too -- and if they did not, the guardian is a big picture over
		# a field-sized body, which `creature_body.gd` calls "the invisible
		# discrepancy PW2 forbids": a swing that visually connects resolving
		# against a body that is not there.
		var look: Dictionary = SPECIES.placeholder(str(guardian.get("species_id")))
		var want_height := float(look.get("height", 0.0)) * want_scale
		if want_height > 0.0 and not is_equal_approx(float(guardian.call("body_height")), want_height):
			_fail("the guardian's body height is %.2f m but its species at %.2fx is %.2f m; "
				% [float(guardian.call("body_height")), want_scale, want_height]
				+ "the silhouette scaled and the capsule, reach and catch odds did not")
	var want_move := str(spec.get("signature_move", ""))
	if want_move != "" and instance != null:
		var charged := str(instance.get("move_charged"))
		if charged != want_move:
			_fail("the guardian's charged move is '%s' but its config asks for '%s'; "
				% [charged, want_move]
				+ "the signature move is what makes this a different fight rather than a longer one")
	print("guardian reads as an alpha: %.2f m tall (species %.2f m), charged move %s" % [
		float(guardian.call("body_height")),
		float(SPECIES.placeholder(str(guardian.get("species_id"))).get("height", 0.0)),
		str(instance.get("move_charged")) if instance != null else "?"])


## OP-0905-10, owner playtest 2026-09-05: "there's too many creatures too
## close inside. There should be 2-3 right before the guardian then the
## alpha." Read against the CONFIG rather than the live population, the same
## reason `_the_population_and_the_guardian_are_placed` above asserts the
## guardian's alpha dressing against `_warrens_config()`: retuning the
## population stays a data edit and this test keeps checking the shape rather
## than numbers copied into this file. Goes red on the pre-fix data (2 in the
## hall, 2 in the warren, 1 more in the den beside the guardian -- 5 residents
## before or beside the boss) and green on the fix (mouth 1 + hall 1 + the
## optional warren branch's 1, den empty but for the guardian).
func _the_approach_is_not_crowded() -> void:
	var spawns: Array = _warrens_config().get("spawns", [])
	var before_den := 0
	var mandatory := 0
	var den_residents := 0
	for entry: Variant in spawns:
		if not entry is Dictionary:
			continue
		var spec: Dictionary = entry as Dictionary
		var chamber := str(spec.get("chamber", ""))
		var count := int(spec.get("count", 1))
		if chamber == "den":
			den_residents += count
		elif chamber == "mouth" or chamber == "hall" or chamber == "warren":
			before_den += count
			if chamber != "warren":
				mandatory += count
	print("residents before the guardian: %d (%d mandatory, warren branch optional); den residents besides the guardian: %d"
		% [before_den, mandatory, den_residents])
	if den_residents > 0:
		_fail("OP-0905-10: the den still holds %d ordinary resident(s) sharing the room with the guardian; "
			% den_residents + "the guardian is supposed to be the one thing standing in it")
	if before_den > 3:
		_fail("OP-0905-10: %d creatures stand between the mouth and the guardian (mouth + hall + the optional warren branch); "
			% before_den + "the owner asked for 2-3")
	if mandatory > 2:
		_fail("OP-0905-10: %d creatures are MANDATORY before the guardian, ignoring the optional warren branch; "
			% mandatory + "the owner asked for 2-3 total including the optional branch, not 2-3 on the main path alone")


## OP-0905-11, owner playtest 2026-09-05: "My alpha looked the exact same as a
## regular trail pup." Trailpup has no authored `_alpha.png` colourway
## (checked: assets/creatures/tetherbound/trailpup/ carries no `*_alpha`
## texture), so before this fix `set_alpha(true)` fell back all the way to the
## `vivid` texture every ordinary trailpup already wears by default
## (creature_body.gd::_refresh_shiny_tint()'s own alpha->vivid fallback) --
## the guardian's alpha dressing (`_dress_the_guardian()`) was never wired to
## anything but the guardian, so the vault's "Elder Trailpup" got a name and
## nothing else. This asserts the fix rather than the mechanism so it goes red
## on the old code: the `alpha` meta, the size the guardian's own check above
## already asserts against config, and a MATERIAL that differs from a plain
## trailpup's — the concrete, code-visible stand-in for "does not look
## identical", since this harness has no way to render and compare pixels.
func _the_vault_alpha_reads_as_an_alpha(world: Node, warrens: Node3D) -> void:
	var alpha_body: Node3D = null
	for body: Node3D in warrens.call("population"):
		if is_instance_valid(body) and str(body.get("display_name")) == "Elder Trailpup":
			alpha_body = body
			break
	if alpha_body == null:
		_fail("OP-0905-11: no 'Elder Trailpup' body found in the vault; cannot check its alpha dressing")
		return

	if not alpha_body.has_meta("alpha"):
		_fail("OP-0905-11: the vault's Elder Trailpup has no `alpha` meta; "
			+ "encounter_director's own field alphas carry one and this dungeon's own guardian does too")

	var alpha_spec: Dictionary = {}
	for entry: Variant in _warrens_config().get("spawns", []):
		if entry is Dictionary and str((entry as Dictionary).get("nickname", "")) == "Elder Trailpup":
			alpha_spec = (entry as Dictionary).get("alpha", {}) as Dictionary
			break
	var want_scale := float(alpha_spec.get("scale", 1.0))
	if want_scale > 1.0:
		var look: Dictionary = SPECIES.placeholder(str(alpha_body.get("species_id")))
		var want_height := float(look.get("height", 0.0)) * want_scale
		if want_height > 0.0 and not is_equal_approx(float(alpha_body.call("body_height")), want_height):
			_fail("OP-0905-11: the vault alpha's body height is %.2f m but its species at %.2fx is %.2f m; "
				% [float(alpha_body.call("body_height")), want_scale, want_height]
				+ "the silhouette scaled and the capsule/reach/catch-odds did not, or the scale was never applied")
		else:
			print("vault alpha stands %.2f m tall against a plain trailpup's %.2f m (%.2fx authored)" % [
				float(alpha_body.call("body_height")), float(look.get("height", 0.0)), want_scale])

	# A material difference from a plain trailpup of the same species, spawned
	# fresh with no alpha dressing at all, standing on the alpha's own ground
	# so `place_on_ground` has real floor under it.
	var director := world.get_node_or_null(^"EncounterDirector")
	if director == null:
		_fail("no EncounterDirector on the world; cannot spawn a control trailpup to compare materials against")
		return
	var control: Node3D = director.call(
		"spawn_wild", "trailpup", alpha_body.global_position, {"parent": warrens, "name": "ControlTrailpupOP0905_11"})
	if control == null:
		_fail("could not spawn a control trailpup to compare the vault alpha's material against")
		return
	var alpha_tinted := _has_tinted_material(alpha_body.get_node_or_null(^"Model"))
	var control_tinted := _has_tinted_material(control.get_node_or_null(^"Model"))
	control.queue_free()
	if not alpha_tinted or control_tinted:
		_fail(("OP-0905-11: the vault alpha's coat material does not read as different from a plain trailpup's " +
			"(alpha tinted=%s, control tinted=%s); trailpup has no `_alpha` colourway, so set_alpha() alone falls " +
			"back to the same 'vivid' texture an ordinary trailpup already wears") % [alpha_tinted, control_tinted])
	else:
		print("vault alpha's coat material is tinted; a freshly spawned plain trailpup's is not")


## Recursively looks for a surface override material tagged by
## `burrow_warrens.gd::_tint_node()` (`_alpha_coat_tint`) -- the concrete,
## checkable trace of the coat-tint lever `_dress_alpha()` applies for a
## species with no authored alpha colourway.
func _has_tinted_material(node: Node) -> bool:
	if node == null:
		return false
	if node is MeshInstance3D:
		var instance := node as MeshInstance3D
		var mesh: Mesh = instance.mesh
		for surface in (mesh.get_surface_count() if mesh != null else 0):
			var material := instance.get_active_material(surface)
			if material != null and str(material.resource_name).ends_with("_alpha_coat_tint"):
				return true
	for child in node.get_children():
		if _has_tinted_material(child):
			return true
	return false


## Freeze the residents where they stand — physics off, aggression off. NOT
## hidden and NOT freed: the warrens reads "the guardian is gone" partly from
## the body being invisible (that is the caught path), and hiding it here
## would clear the dungeon before the door test has asked anything.
func _quieten_the_residents(warrens: Node3D) -> void:
	var bodies: Array = warrens.call("population").duplicate()
	var guardian: Node3D = warrens.call("guardian")
	if guardian != null:
		bodies.append(guardian)
	for body: Node3D in bodies:
		if not is_instance_valid(body):
			continue
		body.set("aggressive", false)
		body.set_physics_process(false)


## The one door in the cave, tested the only way that means anything: walk at
## it. Blocked while the guardian stands, open once the flag is set.
func _the_branch_is_shut_until_the_guardian_falls(player: CharacterBody3D, warrens: Node3D,
		progression: RefCounted) -> void:
	if bool(warrens.call("branch_is_open")):
		_fail("the deep branch was already open before the guardian fell")

	var den: Vector3 = warrens.call("marker", "den")
	var vault: Vector3 = warrens.call("marker", "vault")
	var toward_vault := (vault - den).normalized()
	await _put_down(player, den + Vector3(0.0, 1.2, 0.0))
	await _push(player, toward_vault)
	var blocked_at := player.global_position.distance_to(vault)
	print("pushed at the shut branch door; ended %.1fm from the vault" % blocked_at)
	if blocked_at < 3.0:
		_fail("the player reached the branch chamber with the door still shut")

	# Clear it the way beating the guardian clears it.
	if not bool(warrens.call("grant_clear_reward")):
		_fail("clearing the warrens for the first time reported nothing happened")
	if not bool(progression.call("has", "warrens_cleared")):
		_fail("clearing the warrens did not set its SB9 flag")
	if not bool(warrens.call("branch_is_open")):
		_fail("the branch door did not lift once the warrens was cleared")

	await _put_down(player, den + Vector3(0.0, 1.2, 0.0))
	await _push(player, toward_vault)
	var open_at := player.global_position.distance_to(vault)
	print("pushed at the open branch door; ended %.1fm from the vault" % open_at)
	if open_at > 4.0:
		_fail("the branch is still impassable after clearing (%.1fm from the vault)" % open_at)


func _the_heartstone_is_obtainable_and_arms_the_evolution_gate(warrens: Node3D,
		inventory: RefCounted, progression: RefCounted) -> void:
	var holder := warrens.get_node_or_null(^"Heartstone")
	if holder == null:
		_fail("no Heartstone in the branch chamber")
		return
	var prompt := holder.get_node_or_null(^"Interactable")
	if prompt == null:
		_fail("the Heartstone has no interaction; it cannot be picked up")
		return
	prompt.emit_signal("activated")
	for i in 4:
		await process_frame
	if int(inventory.call("count", "heartstone")) < 1:
		_fail("taking the Heartstone did not put one in the satchel")
	if not bool(progression.call("has", "warrens_heartstone_taken")):
		_fail("taking the Heartstone set no flag; a reload would mint a second")

	# R4.6's gate, now with a real source: the shipped config names the item,
	# and the pure-logic check agrees the party can spend it.
	var cfg: Dictionary = _progression_config()
	var item_id := str(cfg.get("evolution", {}).get("mudsnout", {}).get("item_id", ""))
	print("evolution catalyst in the shipped config: '%s'" % item_id)
	if item_id != "heartstone":
		_fail("progression.json's mudsnout evolution wants '%s', not the Heartstone this dungeon drops" % item_id)


func _the_clear_transition_happens_once(warrens: Node3D, inventory: RefCounted,
		progression: RefCounted) -> void:
	# The real guardian terminal path delivers the clear payout through durable
	# encounter receipts before its once flag is set. This public helper only
	# preserves the world transition used by the geometry fixture; it must never
	# bypass that path by adding to a local satchel.
	progression.call("set_flag", "warrens_cleared", false)
	var before := _clear_reward_stock(inventory)

	if not bool(warrens.call("grant_clear_reward")):
		_fail("the first clear did not change the world state")
	if _clear_reward_stock(inventory) != before:
		_fail("grant_clear_reward bypassed the guardian's durable receipt and changed the local satchel")

	if bool(warrens.call("grant_clear_reward")):
		_fail("clearing the warrens a second time changed the world state")
	if _clear_reward_stock(inventory) != before:
		_fail("a second clear moved the satchel")
	if not bool(progression.call("has", "warrens_cleared")):
		_fail("the cleared flag did not survive the second call")


func _clear_reward_stock(inventory: RefCounted) -> Dictionary:
	var stock := {"coin": int(inventory.call("count", "coin"))}
	for entry: Variant in _clear_reward().get("items", []):
		var id := str((entry as Dictionary).get("id", ""))
		if not id.is_empty():
			stock[id] = int(inventory.call("count", id))
	return stock


## WARRENS-ONCE, owner playtest 2026-09-03 item 9: "After I fight it and
## catch it or kill it I shouldn't get another chance." `_the_story_reward_
## pays_once` above already proves the STORY payout is once-only; this is the
## other half -- that the guardian itself does not spawn a second time once
## the dungeon rebuilds, which is what "leave and come back" or a reload
## actually does to this scene. Builds a SECOND `BurrowWarrens` against the
## real, already-cleared `/root/Game` progression store this whole test has
## been writing to, reusing the same `world` and `EncounterDirector` the
## first one stands in (`playground_world.gd::_build_burrow_warrens()`'s own
## wiring), and the mechanism under test
## (`encounter_director.gd::spawn_wild()`'s `once_id` gate) has to refuse the
## guardian outright.
func _a_cleared_guardian_does_not_come_back(world: Node, progression: RefCounted) -> void:
	if not bool(progression.call("has", "warrens_cleared")):
		_fail("the warrens was not left cleared; the once-only check below proves nothing")
		return
	var director := world.get_node_or_null(^"EncounterDirector")
	if director == null:
		_fail("no EncounterDirector on the world; the once-only check cannot spawn a second warrens")
		return
	var second: Node3D = BURROW_WARRENS.new()
	second.name = "BurrowWarrensOnceCheck"
	world.add_child(second)
	var built := bool(second.call("build", world, null, null, director))
	if not built:
		_fail("a second Burrow Warrens would not even build")
	else:
		var guardian: Variant = second.call("guardian")
		if guardian != null:
			_fail("the guardian spawned again in a cave that is already cleared; "
				+ "the owner's 'I shouldn't get another chance' is not held")
		else:
			print("second build of a cleared warrens spawned no guardian, as it should not")
	second.queue_free()


## --- harness ---------------------------------------------------------------

## What each reward item's count was before the payout, keyed by item id.
var _before: Dictionary = {}


## The clear reward as the dungeon's own config declares it. Read here rather
## than duplicated as literals so retuning the payout stays a data edit.
func _clear_reward() -> Dictionary:
	var file := FileAccess.open("res://data/config/burrow_warrens.json", FileAccess.READ)
	if file == null:
		_fail("burrow_warrens.json will not open")
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		_fail("burrow_warrens.json did not parse as an object")
		return {}
	return ((parsed as Dictionary).get("clear", {}) as Dictionary).get("reward", {}) as Dictionary


func _put_down(player: CharacterBody3D, at: Vector3) -> void:
	player.global_position = at
	player.velocity = Vector3.ZERO
	for i in 40:
		await physics_frame


## Hold a direction for a fixed budget of physics frames. The player's own
## movement is camera-relative, so this drives the body directly rather than
## through input actions — the question here is about walls, not about the
## input map (smoke_input.gd owns that).
##
## The controller's own `_physics_process` is suspended for the length of the
## push. Leaving it running means two `move_and_slide()` calls per frame with
## two different velocities — the controller's own (zero, no input) and this
## one's — and the last writer wins at random, which showed up as a push that
## travelled 1.4m through an open doorway. Gravity is applied here instead so
## the body still rides the floor rather than skating off a step.
func _push(player: CharacterBody3D, direction: Vector3) -> void:
	var flat := Vector3(direction.x, 0.0, direction.z).normalized()
	player.set_physics_process(false)
	for i in PUSH_FRAMES:
		player.velocity.x = flat.x * 4.0
		player.velocity.z = flat.z * 4.0
		player.velocity.y = 0.0 if player.is_on_floor() else player.velocity.y - 0.5
		player.move_and_slide()
		await physics_frame
	player.set_physics_process(true)


func _progression_config() -> Dictionary:
	var file := FileAccess.open("res://data/config/progression.json", FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}


## --- W07-WARRENS-0904: the room ----------------------------------------------

const INTERIOR_LAYER_BIT := 1 << 11  # `interior_ambient.layer` 12


## Every horizontal ray from every chamber's eye height must end on the cave
## within 60 m. A ray that reaches the meadow found a missing wall -- which is
## what a frame of daylight at the end of a corridor looks like.
func _no_daylight_leaks(world: Node, warrens: Node3D) -> void:
	var space := (world as Node3D).get_world_3d().direct_space_state
	var leaks := 0
	var checked := 0
	# Bodies are not walls: the trainer and the residents are cast through.
	var exclude: Array[RID] = []
	for body in world.find_children("*", "CharacterBody3D", true, false):
		exclude.append((body as CharacterBody3D).get_rid())
	# The mouth is OPEN on purpose: rays within 45 degrees of the way out are
	# allowed to leave (the spine mouth-hall-den is one straight sightline to
	# daylight, by design); every other direction must end on the cave.
	var way_out: Vector3 = (warrens.global_transform.basis * Vector3(0.0, 0.0, -1.0)).normalized()
	for id: String in warrens.call("chamber_ids"):
		var eye: Vector3 = warrens.call("marker", id) + Vector3.UP * 1.7
		for step in 24:
			var angle := TAU * float(step) / 24.0
			for pitch: float in [0.0, 0.35]:
				var dir := Vector3(sin(angle) * cos(pitch), sin(pitch), cos(angle) * cos(pitch))
				if Vector3(dir.x, 0.0, dir.z).normalized().dot(way_out) > cos(deg_to_rad(45.0)):
					continue
				var query := PhysicsRayQueryParameters3D.create(eye, eye + dir * 60.0)
				query.exclude = exclude
				var hit := space.intersect_ray(query)
				checked += 1
				var collider: Node = hit.get("collider", null) as Node
				if hit.is_empty() or collider == null or not warrens.is_ancestor_of(collider):
					leaks += 1
					if leaks <= 12:
						_fail("a ray from '%s' at yaw %.0f pitch %.2f left the cave (%s)" % [
							id, rad_to_deg(angle), pitch,
							"no hit" if hit.is_empty() else str(collider.get_path())])
	print("daylight leak check: %d rays, %d leaks" % [checked, leaks])


## OP-0905-09. The old mound never claimed to enclose anything -- the cave's
## own boxes did that job. The new earth bank claims to, chamber by chamber
## (`burrow_warrens.gd::_build_bank()`'s own `_bank_chamber_bumps()`), so this
## proves the claim from OUTSIDE the geometry rather than trusting the print
## line: a ray straight up from every chamber's own marker must hit something
## that belongs to the warrens (the bank, an earth cap, or a ceiling slab) --
## never open sky -- before it travels a very generous 200m.
func _the_bank_encloses_every_chamber(world: Node, warrens: Node3D) -> void:
	var space := (world as Node3D).get_world_3d().direct_space_state
	var exclude: Array[RID] = []
	for body in world.find_children("*", "CharacterBody3D", true, false):
		exclude.append((body as CharacterBody3D).get_rid())
	var checked := 0
	for id: String in warrens.call("chamber_ids"):
		var at: Vector3 = warrens.call("marker", id)
		var query := PhysicsRayQueryParameters3D.create(at, at + Vector3.UP * 200.0)
		query.exclude = exclude
		var hit := space.intersect_ray(query)
		checked += 1
		var collider: Node = hit.get("collider", null) as Node
		if hit.is_empty() or collider == null or not warrens.is_ancestor_of(collider):
			_fail("chamber '%s' is not enclosed: a ray straight up from its own marker reached open sky" % id)
	print("bank enclosure check: %d chambers, all covered from directly above" % checked)


## The mouth is a real cut, not a wall with a hole painted on it: a ray from
## 12m in front of the mouth, at roughly eye height, aimed at the mouth
## chamber's own floor marker must travel almost the whole distance before it
## hits anything -- if the earth bank's own dug face or throat blocks it
## early, the arch is not actually open.
func _the_mouth_arch_is_open(world: Node, warrens: Node3D) -> void:
	var space := (world as Node3D).get_world_3d().direct_space_state
	var exclude: Array[RID] = []
	for body in world.find_children("*", "CharacterBody3D", true, false):
		exclude.append((body as CharacterBody3D).get_rid())
	var mouth: Vector3 = warrens.call("marker", "mouth")
	var approach: Vector3 = warrens.to_global(Vector3(0.0, 1.6, warrens.to_local(mouth).z - 12.0))
	var ground := float(world.call("ground_height_at", approach.x, approach.z)) if world.has_method("ground_height_at") else NAN
	var origin: Vector3 = approach if is_nan(ground) else Vector3(approach.x, ground + 1.6, approach.z)
	var target := mouth + Vector3.UP * 1.0
	var full := origin.distance_to(target)
	var query := PhysicsRayQueryParameters3D.create(origin, target)
	query.exclude = exclude
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		print("mouth arch check: clear line from %.1fm out straight to the mouth chamber" % full)
		return
	var collider: Node = hit.get("collider", null) as Node
	var hit_distance := origin.distance_to(hit.get("position", origin))
	if hit_distance < full - 2.0:
		_fail("the mouth arch is blocked %.1fm short of the mouth chamber by %s" % [
			full - hit_distance, "no collider" if collider == null else str(collider.get_path())])
	else:
		print("mouth arch check: reached %.1fm of %.1fm before hitting %s" % [
			hit_distance, full, "nothing" if collider == null else str(collider.get_path())])


func _has_layer(node: Node) -> bool:
	return node is GeometryInstance3D and ((node as GeometryInstance3D).layers & INTERIOR_LAYER_BIT) != 0


func _geometry_under(node: Node, out: Array[GeometryInstance3D]) -> void:
	if node is GeometryInstance3D:
		out.append(node as GeometryInstance3D)
	for child in node.get_children():
		_geometry_under(child, out)


func _the_room_has_its_own_dark(player: CharacterBody3D, warrens: Node3D) -> void:
	var probe: ReflectionProbe = warrens.get_node_or_null(^"InteriorAmbient") as ReflectionProbe
	if probe == null:
		_fail("no InteriorAmbient probe under the warrens; the room is lit by the meadow's sky")
		return
	if not probe.interior or probe.ambient_mode != ReflectionProbe.AMBIENT_COLOR:
		_fail("InteriorAmbient is not an interior constant-colour probe")
	if probe.reflection_mask != INTERIOR_LAYER_BIT:
		_fail("InteriorAmbient affects mask %d, not the interior layer alone" % probe.reflection_mask)
	if probe.ambient_color.get_luminance() > 0.2:
		_fail("InteriorAmbient's ambient is not dark (%s)" % probe.ambient_color.to_html(false))
	for id: String in warrens.call("chamber_ids"):
		var m: Vector3 = warrens.call("marker", id)
		var local: Vector3 = probe.to_local(m)
		if absf(local.x) > probe.size.x * 0.5 or absf(local.z) > probe.size.z * 0.5 or absf(local.y) > probe.size.y * 0.5:
			_fail("chamber '%s' lies outside the InteriorAmbient box" % id)

	# The interior carries the layer; the outside does not.
	var interior_named: Array[GeometryInstance3D] = []
	var exterior_named: Array[GeometryInstance3D] = []
	for holder_name: String in ["InteriorRock", "Roots", "Fungus", "Haze", "FloorLitter", "DenBones"]:
		var holder: Node = warrens.get_node_or_null(NodePath(holder_name))
		if holder == null:
			continue
		for piece in holder.get_children():
			# The root fringe over the mouth hangs outside, tagged so.
			if piece.has_meta("warrens_exterior"):
				_geometry_under(piece, exterior_named)
			else:
				_geometry_under(piece, interior_named)
	var mound: Node = warrens.get_node_or_null(^"Mound")
	if mound != null:
		_geometry_under(mound, exterior_named)
	# OP-0905-09: the mound was replaced by one earth-bank mesh plus its own
	# mouth dressing -- same exterior-layer promise, new node names.
	for holder_name: String in ["Bank", "BankMouth", "SiteSkirt", "WarrenHoles",
			"BankRoots", "ClawScrapes", "CrestTrees", "AccentBoulders", "SpoilMounds", "MoundGrowth"]:
		var bank_holder: Node = warrens.get_node_or_null(NodePath(holder_name))
		if bank_holder != null:
			_geometry_under(bank_holder, exterior_named)
	for child in warrens.get_children():
		if str(child.name).begins_with("ExteriorEarthSkin"):
			_geometry_under(child, exterior_named)
	if interior_named.size() < 20 or exterior_named.size() < 20:
		_fail("too little geometry to judge layering (%d interior, %d exterior)" % [
			interior_named.size(), exterior_named.size()])
	var unlayered := 0
	for g in interior_named:
		if not _has_layer(g):
			unlayered += 1
	var leaked := 0
	for g in exterior_named:
		if _has_layer(g):
			leaked += 1
	if unlayered > 0:
		_fail("%d interior meshes do not carry the interior layer" % unlayered)
	if leaked > 0:
		_fail("%d mound/skin meshes carry the interior layer and would go dark in the sun" % leaked)
	# The chamber walls and floors themselves: the direct MeshInstance3D
	# children that are not tagged exterior.
	var walls_unlayered := 0
	var walls := 0
	for child in warrens.get_children():
		if child is MeshInstance3D and not child.has_meta("warrens_exterior"):
			walls += 1
			if not _has_layer(child):
				walls_unlayered += 1
	if walls < 20 or walls_unlayered > 0:
		_fail("chamber walls/floors: %d of %d lack the interior layer" % [walls_unlayered, walls])

	# A body that walks in takes the layer, and loses it walking out.
	var player_geometry: Array[GeometryInstance3D] = []
	_geometry_under(player, player_geometry)
	if player_geometry.is_empty():
		_fail("the player has no geometry to layer")
		return
	await _put_down(player, warrens.call("marker", "hall") + Vector3(0.0, 1.0, 0.0))
	await physics_frame
	var inside_on := 0
	for g in player_geometry:
		if _has_layer(g):
			inside_on += 1
	if inside_on != player_geometry.size():
		_fail("inside the hall only %d of %d player meshes carry the interior layer" % [
			inside_on, player_geometry.size()])
	await _put_down(player, warrens.call("marker", "entrance") + Vector3(0.0, 1.0, 0.0))
	await physics_frame
	var outside_on := 0
	for g in player_geometry:
		if _has_layer(g):
			outside_on += 1
	if outside_on != 0:
		_fail("back outside, %d player meshes still carry the interior layer" % outside_on)
	print("interior ambient: probe ok, %d interior / %d exterior meshes checked, player layer %d -> %d" % [
		interior_named.size(), exterior_named.size(), inside_on, outside_on])


func _the_room_dressing_is_clear_of_the_walk(warrens: Node3D) -> void:
	var floor_y: float = (warrens.call("marker", "hall") as Vector3).y
	var counts := {}
	for holder_name: String in ["Roots", "Fungus", "Haze", "FloorLitter"]:
		var holder: Node = warrens.get_node_or_null(NodePath(holder_name))
		if holder == null:
			_fail("no '%s' holder under the warrens" % holder_name)
			continue
		var bodies := holder.find_children("*", "CollisionObject3D", true, false)
		if not bodies.is_empty():
			_fail("'%s' added %d collision objects; the dressing must not block the walk" % [
				holder_name, bodies.size()])
		var geometry: Array[GeometryInstance3D] = []
		_geometry_under(holder, geometry)
		counts[holder_name] = geometry.size()
	if int(counts.get("Roots", 0)) < 8:
		_fail("only %d root meshes; the mid-layer is missing" % int(counts.get("Roots", 0)))
	if int(counts.get("Fungus", 0)) < 20:
		_fail("only %d fungus meshes" % int(counts.get("Fungus", 0)))
	# The authored haze deliberately has four pools, rather than the retired
	# false ceiling shafts and doorway cap. Validate the configuration's mount
	# count instead of restoring rejected geometry to satisfy a fixed floor.
	var expected_haze := 0
	for card: Dictionary in _warrens_config().get("haze", {}).get("cards", []):
		expected_haze += 2 if str(card.get("kind", "pool")) == "shaft" else 1
	if expected_haze == 0 or int(counts.get("Haze", 0)) != expected_haze:
		_fail("haze mounted %d cards; authored configuration requires %d" % [
			int(counts.get("Haze", 0)), expected_haze])

	# Check real mesh triangles, not empty corners of a rotated AABB. Wall
	# roots may extend below head height behind a passage wall; clip those
	# triangles to the authored passage width before measuring clearance.
	var roots: Node = warrens.get_node_or_null(^"Roots")
	if roots != null:
		var low := 0
		var specs: Array = _warrens_config().get("roots", {}).get("pieces", [])
		for piece in roots.get_children():
			if piece.has_meta("warrens_exterior"):
				continue
			var index := int(str(piece.name).trim_prefix("Root_"))
			var spec: Dictionary = specs[index] if index < specs.size() else {}
			var lowest := _root_walk_lowest(warrens, piece, spec)
			if lowest < floor_y + 1.9:
				low += 1
				_fail("root '%s' hangs to %.2f m above the floor inside the walk" % [
					piece.name, lowest - floor_y])
			print("root clearance %s: %.3fm above floor in walk" % [piece.name, lowest - floor_y])
		print("roots: %d pieces, %d too low" % [roots.get_child_count(), low])

	var fungus: Node = warrens.get_node_or_null(^"Fungus")
	if fungus != null:
		var lights := fungus.find_children("*", "OmniLight3D", true, false)
		if lights.size() < 6:
			_fail("fungus clusters carry %d lights; they are meant to be the passage beacons" % lights.size())
		var glowing := 0
		var dull := 0
		for mi in fungus.find_children("*", "MeshInstance3D", true, false):
			var instance := mi as MeshInstance3D
			var material: Material = instance.get_active_material(0) if instance.mesh != null else null
			if material is BaseMaterial3D and (material as BaseMaterial3D).emission_enabled:
				glowing += 1
			else:
				dull += 1
		if dull > 0:
			_fail("%d fungus meshes do not glow" % dull)
		print("fungus: %d glowing meshes, %d lights" % [glowing, lights.size()])

	var haze: Node = warrens.get_node_or_null(^"Haze")
	if haze != null:
		for mi in haze.find_children("*", "MeshInstance3D", true, false):
			var material := (mi as MeshInstance3D).material_override as BaseMaterial3D
			if material == null or material.shading_mode != BaseMaterial3D.SHADING_MODE_UNSHADED \
					or material.blend_mode != BaseMaterial3D.BLEND_MODE_ADD:
				_fail("haze card '%s' is not an unshaded additive card" % mi.name)
				break


func _root_walk_lowest(warrens: Node3D, piece: Node, spec: Dictionary) -> float:
	var axis := -1
	var centre := 0.0
	var half_width := INF
	var between: Array = spec.get("between", [])
	if between.size() == 2:
		for passage: Dictionary in _warrens_config().get("passages", []):
			if str(passage.get("from", "")) == str(between[0]) and str(passage.get("to", "")) == str(between[1]):
				var a := warrens.to_local(warrens.call("marker", str(between[0])))
				var b := warrens.to_local(warrens.call("marker", str(between[1])))
				axis = 0 if absf(a.x - b.x) < absf(a.z - b.z) else 2
				centre = (a[axis] + b[axis]) * 0.5
				half_width = float(passage.get("width", 0.0)) * 0.5
	var lowest := INF
	for mi: MeshInstance3D in piece.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null:
			continue
		for surface in mi.mesh.get_surface_count():
			var arrays := mi.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			var count := indices.size() if not indices.is_empty() else vertices.size()
			for start in range(0, count, 3):
				var triangle: Array[Vector3] = []
				for corner in 3:
					var vertex := vertices[indices[start + corner] if not indices.is_empty() else start + corner]
					triangle.append(warrens.to_local(mi.global_transform * vertex))
				if axis >= 0:
					triangle = _clip_root_polygon(triangle, axis, centre - half_width, true)
					triangle = _clip_root_polygon(triangle, axis, centre + half_width, false)
				for vertex: Vector3 in triangle:
					lowest = minf(lowest, warrens.to_global(vertex).y)
	return lowest


func _clip_root_polygon(points: Array[Vector3], axis: int, limit: float,
		keep_above: bool) -> Array[Vector3]:
	var out: Array[Vector3] = []
	if points.is_empty():
		return out
	var previous := points.back() as Vector3
	var previous_inside := previous[axis] >= limit if keep_above else previous[axis] <= limit
	for point: Vector3 in points:
		var inside := point[axis] >= limit if keep_above else point[axis] <= limit
		if inside != previous_inside:
			out.append(previous.lerp(point, (limit - previous[axis]) / (point[axis] - previous[axis])))
		if inside:
			out.append(point)
		previous = point
		previous_inside = inside
	return out
