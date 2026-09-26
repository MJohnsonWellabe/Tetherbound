extends "res://tests/smoke_cloudreach_continuous.gd"

## Shared base for the Cloudreach-B witnesses: the unchanged continuous
## normal-input route, plus an OPT-IN declared mid-chapter start and an OPT-IN
## declared end.
##
## `--leg=flight` (DECLARED END): the run stops after the route's last flight,
## the controlled return glide that lands back on the aerie deck -- every Fly
## launch, ring, landing and loaner use of the chapter has happened by then.
## Before stopping it performs the same disk save/reload the full route does at
## its end (world paused around the observation) and requires every persisted
## field of every party member, the exact flag set and the Fly unlock to
## survive it. The grounded counterweight/Voss/Veyra remainder is NOT run.
##
## `--start=aerie` (DISCLOSED FIXTURE, not earned play): Act I is treated as
## already done. The Act I completion flags below are set on the progression
## store as the Cloudreach scene enters the tree (before its _ready builds the
## chapter), three Gale Fiber are granted at the first (skipped) arrival
## gather so the route's own ">= 3 gathered" check holds -- the seeded repair
## never spends them, so they stay in the bag -- and the trainer is placed ONCE
## beside the repaired aerie perch. Every route step before the aerie camp rest is then skipped; from the
## real `_rest("windscar_flight_aerie_camp")` onward the base route runs by
## ordinary input exactly as in a full run (trial, Fly, shrine, counterweight,
## Voss, bivouac, Veyra, relays, overlook, save/reload). The skipped span is
## the arrival road, lower anchors, Senn, the causeway signal and Maela's trial
## battle, so XP from those fights is not earned: the party enters the trial at
## the fixture's level 25. Without `--start` behaviour is the full route.
##
## Precedent: smoke_cloudreach_floor_loop_return.gd / aerie_services.gd use the
## same declared flags-before-build plus single placement fixture.
const ACT_ONE_FLAGS: Array[String] = ["cloudreach_chapter_started", "cloudreach_crisis_learned",
	"storm_anchor_lower_west_mapped", "cloudreach_lower_anchors_investigated",
	"defeated_cloudreach_senn", "causeway_survivors_reconnected",
	"completed_cloudreach_maela_trial_battle", "windscar_aerie_prepared",
	"cloudreach_act_i_complete"]
const AERIE_CAMP := "windscar_flight_aerie_camp"

var start_point := ""
var skipping_to_aerie := false
var skipped_steps: Array[String] = []
var start_record: Dictionary = {}
var finish_done := false
var leg_persistence: Dictionary = {}


func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--start="): start_point = arg.trim_prefix("--start=")
	if start_point == "aerie":
		skipping_to_aerie = true
		node_added.connect(_seed_act_one_on_scene_entry)
	elif not start_point.is_empty():
		push_error("Unknown --start=" + start_point)
	await super._run()


func _seed_act_one_on_scene_entry(node: Node) -> void:
	if node.get_parent() != root or not node.has_node("CloudreachChapter") and node.name != "CloudreachCliffs": return
	node_added.disconnect(_seed_act_one_on_scene_entry)
	for flag: String in ACT_ONE_FLAGS:
		root.get_node("Game").progression.set_flag(flag)


## The first purpose line follows the settled precondition frames: place once.
func _purpose(purpose: String, choice: String) -> void:
	if skipping_to_aerie and start_record.is_empty():
		var repair: Node3D = physical.get_node("aerie_repair/Interactable")
		var at := repair.global_position + Vector3(0, 0.4, 2.0)
		player.global_position = at
		player.velocity = Vector3.ZERO
		last_position = at
		start_record = {"start": "aerie", "placed_at": str(at), "flags_seeded": ACT_ONE_FLAGS,
			"team": _team_snapshot(), "note": "Declared fixture: Act I flags seeded before scene build; single placement beside the aerie repair; route from the aerie camp rest onward is ordinary input"}
		_log("witness_start_state", start_record)
	super._purpose(purpose, choice)


func _skip(kind: String, id: String) -> bool:
	skipped_steps.append(kind + ":" + id)
	return true


func _walk(target: Vector3, radius: float = 0.75, body: CharacterBody3D = null) -> bool:
	if skipping_to_aerie: return _skip("walk", str(target))
	return await super._walk(target, radius, body)


func _navigate(target: Vector3) -> bool:
	if skipping_to_aerie: return _skip("navigate", str(target))
	return await super._navigate(target)


func _interact(prompt: Node3D, flag: String = "", approach: bool = true) -> bool:
	if skipping_to_aerie: return _skip("interact", flag)
	return await super._interact(prompt, flag, approach)


func _arrival_gather(id: String, item: String) -> bool:
	if skipping_to_aerie:
		# The seeded repair already consumed the fiber; satisfy the route's
		# own ">= 3 gathered" precondition without a second repair.
		if game.inventory.count("gale_fiber") < 3: game.inventory.add("gale_fiber", 3 - game.inventory.count("gale_fiber"))
		return _skip("gather", id)
	return await super._arrival_gather(id, item)


func _talk(id: String, flag: String, navigate: bool = true) -> bool:
	if skipping_to_aerie: return _skip("talk", id)
	return await super._talk(id, flag, navigate)


func _physical_action(id: String, flag: String, navigate: bool = true) -> bool:
	if skipping_to_aerie: return _skip("physical", id)
	return await super._physical_action(id, flag, navigate)


func _pickup(id: String) -> bool:
	if skipping_to_aerie: return _skip("pickup", id)
	return await super._pickup(id)


func _battle(id: String) -> bool:
	if skipping_to_aerie: return _skip("battle", id)
	return await super._battle(id)


## The aerie camp rest is the first real step of an aerie start.
func _rest(id: String) -> bool:
	if skipping_to_aerie and id == AERIE_CAMP:
		skipping_to_aerie = false
		for tick in 60:
			if player.is_on_floor(): break
			await _frames(1)
		_log("witness_start_resume", {"skipped_steps": skipped_steps.size(), "on_floor": player.is_on_floor(), "position": str(player.global_position)})
	elif skipping_to_aerie:
		return _skip("rest", id)
	return await super._rest(id)


## The flight leg ends after the return-glide landing on the aerie deck.
func _return_to_aerie() -> bool:
	var ok: bool = await super._return_to_aerie()
	if not ok or leg != "flight": return ok
	await _frames(30)
	paused = true
	var before := _party_persistence_snapshot()
	var flags_before := _flag_snapshot()
	var save_ok: bool = game.save_game(0)
	var load_ok: bool = save_ok and game.load_game(0)
	var after := _party_persistence_snapshot()
	var differences := _party_persistence_differences(before, after)
	paused = false
	leg_persistence = {"save_ok": save_ok, "load_ok": load_ok, "differences": differences,
		"party_size_after": game.party.members().size(), "flags_equal": _flag_snapshot() == flags_before,
		"fly_unlocked_after": _has("fly_traversal_unlocked")}
	_log("witness_leg_persistence", leg_persistence)
	if not _require(save_ok and load_ok, "Flight leg: disk save and reload completed"): return false
	if not _require(differences.is_empty(), "Flight leg: every persisted field of every member survived reload"): return false
	if not _require(_flag_snapshot() == flags_before and _has("fly_traversal_unlocked"), "Flight leg: exact flag set and Fly unlock survived reload"): return false
	_log("leg_complete", {"leg": leg, "team": _team_snapshot(), "inventory": _inventory_snapshot(), "flags": _flag_snapshot().size()})
	completed_route = true
	_finish()
	return false


## `_finish` can be reached twice when a declared leg ends inside a route step
## (the step returns and the base route calls `_finish` again). Report once.
func _finish_already_done() -> bool:
	if finish_done: return true
	finish_done = true
	return false


func _start_state_label() -> String:
	if start_point == "aerie":
		return "DECLARED aerie fixture (--start=aerie): committed completed-Meadows fixture party, Act I flags seeded before scene build, single placement beside the aerie repair; ordinary input from the aerie camp rest onward"
	if not from_save.is_empty():
		return "earned save " + from_save
	return "committed completed-Meadows fixture (smoke_cloudreach_continuous default; earned c1_arrival save not yet available)"


## Aerie-start evidence never overwrites a full-route run's evidence.
func _witness_dir(base: String) -> String:
	return base + ("/aerie-start" if start_point == "aerie" else "")
