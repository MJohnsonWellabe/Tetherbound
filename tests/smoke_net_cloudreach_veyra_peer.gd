extends "res://tools/net/proof_peer_runner.gd"

## Peer process for `tests/smoke_net_cloudreach_veyra_reconnect.gd` (NOT a smoke
## of its own: it declares no `# peers:` header, so CI net discovery skips it).
##
## Exactly the proof peer runner (`tools/net/proof_peer_runner.gd`, itself the
## shared `peer_runner.gd` plus proof steps), with one action and one probe for
## F08 #2. Kept lane-local so the shared runners stay unchanged.
##
## * action `veyra_client_win` -- FIXTURE (disclosed): the guest's Veyra fight
##   is not fought blow by blow. It calls the production Cloudreach director's
##   final-round victory hook, `_record_trainer_defeat(spec)`, with the
##   director's own authored spec -- the one call the inherited final-round win
##   makes. Everything after it (route, wire, host journal, delta) is shipping
##   code. It reads, in the SAME frame (no network packet can land in between),
##   whether this peer's own flag store now says the trainer is beaten.
##   `mode: "base"` is the NEGATIVE CONTROL: it calls main's unfixed client
##   route (`encounter_director.gd::_record_trainer_defeat_for_the_session`,
##   which Cloudreach reached on main) for another trainer, so the same
##   same-frame read is shown to catch a local world-flag write.
## * probe `veyra_state` -- flag reads (merged/world/player), this world's
##   journal rows for a trainer, satchel counts, and whether this peer's own
##   portable character FILE on disk mentions the flag.

const VEYRA := "captain_veyra_storm_anchor"


func _execute_step(msg: Dictionary) -> Dictionary:
	if str(msg.get("action", "")) != "veyra_client_win":
		return await super(msg)
	var before := _physics_count
	var args: Dictionary = msg.get("args", {}) as Dictionary
	# After a rejoin the realm scene may still be rebuilding: wait for its
	# director (bounded), then act in one frame.
	for _i in maxi(0, int(args.get("wait_frames", 0))):
		if _cloudreach_director() != null:
			break
		await physics_frame
	var out := _veyra_client_win(args)
	out["frames_used"] = _physics_count - before
	return out


func _execute_probe(msg: Dictionary) -> Variant:
	if str(msg.get("what", "")) != "veyra_state":
		return await super(msg)
	return _veyra_state((msg.get("args", {}) as Dictionary))


func _cloudreach_director() -> Node:
	if current_scene == null:
		return null
	var direct := current_scene.get_node_or_null(^"EncounterDirector")
	if direct != null and direct.get("trainer_specs") is Dictionary:
		return direct
	return current_scene.find_child("EncounterDirector", true, false)


func _veyra_client_win(args: Dictionary) -> Dictionary:
	var game := root.get_node_or_null(^"Game")
	var director := _cloudreach_director()
	if game == null or director == null or not (director.get("trainer_specs") is Dictionary):
		# FAIL, not ERROR: the harness treats a peer ERROR as fatal, and the
		# checks after this one (journal, satchel, saved files) still stand.
		return {"verdict": "FAIL", "detail": "no Game or no Cloudreach EncounterDirector in scene '%s'"
			% (str(current_scene.name) if current_scene != null else "<none>")}
	var trainer := str(args.get("trainer", VEYRA))
	var spec: Dictionary = (director.get("trainer_specs") as Dictionary).get(trainer, {})
	if spec.is_empty():
		return {"verdict": "ERROR", "detail": "the Cloudreach director has no trainer '%s'" % trainer}
	var flag := str(spec.get("defeat_flag", ""))
	var progression: RefCounted = game.get("progression")
	var world: RefCounted = game.get("world")
	var world_flags: RefCounted = world.get("flags") if world != null else null
	var multi := bool(director.call("_is_multi_peer"))
	var host := bool(director.call("_is_host"))
	var had := bool(progression.call("has", flag))
	var revision_before := int(world_flags.get("revision")) if world_flags != null else -1
	var victories: Array = []
	var listener := func(id: String) -> void: victories.append(id)
	director.connect("trainer_victory", listener)
	var mode := str(args.get("mode", "production"))
	if mode == "base":
		director.call("_record_trainer_defeat_for_the_session", spec)
	else:
		director.call("_record_trainer_defeat", spec)
	director.disconnect("trainer_victory", listener)
	var local_now := bool(progression.call("has", flag))
	var revision_after := int(world_flags.get("revision")) if world_flags != null else -1
	var sent: Dictionary = director.get("_trainer_victories_sent") as Dictionary
	var data := {"trainer": trainer, "flag": flag, "mode": mode, "multi_peer": multi, "host": host,
		"had_flag": had, "local_flag_same_frame": local_now,
		"world_store_writes_same_frame": revision_after - revision_before,
		"sent_to_host": sent.has(trainer), "victory_emits": victories.size()}
	return {"verdict": "PASS" if multi and not host else "FAIL", "data": data,
		"detail": JSON.stringify(data)}


func _veyra_state(args: Dictionary) -> Dictionary:
	var game := root.get_node_or_null(^"Game")
	if game == null:
		return {}
	var trainer := str(args.get("trainer", VEYRA))
	var flag := str(args.get("flag", "captain_veyra_defeated"))
	var world: RefCounted = game.get("world")
	var local: RefCounted = game.get("local")
	var character_id := str(local.get("character_id")) if local != null else ""
	var rows: Array = []
	if world != null:
		for raw: Variant in (world.get("reward_deliveries") as Dictionary).values():
			if raw is Dictionary and str((raw as Dictionary).get("source", "")).begins_with("trainer:%s:" % trainer):
				var row := raw as Dictionary
				rows.append({"source": str(row.get("source", "")), "character_id": str(row.get("character_id", "")),
					"status": str(row.get("status", ""))})
	var file_text := ""
	var file_path := "user://characters/%s/character.json" % character_id
	if not character_id.is_empty() and FileAccess.file_exists(file_path):
		file_text = FileAccess.get_file_as_string(file_path)
	var inventory: RefCounted = game.get("inventory")
	var items: Dictionary = {}
	for item: String in ["coin", "rare_candy"]:
		items[item] = int(inventory.call("count", item)) if inventory != null else -1
	var world_flags: RefCounted = world.get("flags") if world != null else null
	var player_flags: RefCounted = local.get("flags") if local != null else null
	return {
		"character_id": character_id,
		"flag": bool((game.get("progression") as RefCounted).call("has", flag)),
		"world_flag": world_flags != null and bool(world_flags.call("has", flag)),
		"player_flag": player_flags != null and bool(player_flags.call("has", flag)),
		"journal_rows": rows,
		"journal_count": rows.size(),
		"items": items,
		"character_file": file_path,
		"character_file_exists": not file_text.is_empty(),
		"character_file_mentions_flag": file_text.contains(flag),
	}
