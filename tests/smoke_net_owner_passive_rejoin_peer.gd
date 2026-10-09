extends "res://tools/net/proof_peer_runner.gd"

## PEER process for `tests/smoke_net_owner_passive_rejoin.gd`. Not a smoke on
## its own: no `# peers:` header, never discovered by CI.
##
## Exactly the proof peer runner plus one read-only probe and one fixture:
##  * probe `op_state`     this peer's owner-passive stream (`local`), and on
##                         the host every stream it holds per character.
##  * step `op_diverge`    FIXTURE (disclosed): before a rejoin, raise one owned
##                         creature's level in this peer's live character -- an
##                         offline portable change (as a solo session's XP).
##  * step `op_hold`       FIXTURE (disclosed): pause (`hold`: true) or resume
##                         this owner's owner-passive send timer, standing in for
##                         "left before its inputs reached the host".
##  * step `op_corrupt`    FIXTURE (disclosed): make the live record invalid for
##                         admission (a creature's hp above its max), so the
##                         host must refuse it under the first-join rules;
##                         `op_corrupt {"restore": true}` puts it back.
##  * step `op_rollback`   FIXTURE (disclosed): stand-in for a restored backup
##                         made before one find -- this peer forgets that
##                         payout (its settled escrow row whose source names
##                         `find`, and `count` of `item` from its satchel).
##  * probe `op_state`     also reports the host's held authority per character
##                         (party levels, item counts) and this peer's counts.


var _corrupt_hp := -1.0
var _tonic_character_dir := ""
var _tonic_request: Dictionary = {}
var _tonic_blocker: Callable
var _tonic_refusal_armed := false
var _tag_request: Dictionary = {}
var _hud_capture_metadata: Dictionary = {}

func _step_boot(args: Dictionary) -> Dictionary:
	var result: Dictionary = await super._step_boot(args)
	if result.get("verdict") == "PASS" and args.get("scene") == "world" \
		and _peer_index == 1 and OS.get_cmdline_user_args().has("--capture-combat-hud") \
		and DisplayServer.get_name() != "headless":
		# Pay the first actual world draw inside this existing boot's budget,
		# before the later authoritative HUD witness. No gameplay step changes.
		var started := Time.get_ticks_msec()
		RenderingServer.force_draw(true, 0.0)
		var elapsed := Time.get_ticks_msec() - started
		result["data"] = (result.get("data", {}) as Dictionary).merged({"hud_world_warmup_ms":elapsed}, true)
		result["detail"] = str(result.get("detail", "")) + "; native world draw warmup %dms" % elapsed
	return result


func _execute_step(msg: Dictionary) -> Dictionary:
	var action := str(msg.get("action", ""))
	if action.begins_with("op_tonic_"):
		return await _tonic_step(action, msg.get("args", {}))
	if action.begins_with("op_tag_"):
		return await _tag_step(action)
	if action == "op_hold":
		var session: Node = root.get_node(^"Game").get_node_or_null(^"Session")
		var service: RefCounted = session.call("_owner_passive_service")
		var hold: bool = (msg.get("args", {}) as Dictionary).get("hold", true) == true
		service.set("_left", 1.0e9 if hold else 0.0)
		return {"verdict": "PASS", "detail": "owner-passive send %s" % ("held" if hold else "resumed"), "frames_used": 0}
	if action == "op_corrupt":
		var member0: RefCounted = root.get_node(^"Game").get("party").call("at", 0)
		if (msg.get("args", {}) as Dictionary).get("restore") == true:
			member0.set("hp", _corrupt_hp)
			return {"verdict": "PASS", "detail": "hp restored to %.1f" % _corrupt_hp, "frames_used": 0}
		_corrupt_hp = float(member0.get("hp"))
		member0.set("hp", float(member0.get("max_hp")) + 50.0)
		return {"verdict": "PASS", "detail": "hp above max on this peer only", "frames_used": 0}
	if action == "op_rollback":
		var args: Dictionary = msg.get("args", {})
		var local: RefCounted = root.get_node(^"Game").get("local")
		var escrow: Dictionary = local.get("satchel_escrow")
		var forgot := 0
		for key: Variant in escrow.keys():
			var row: Variant = escrow[key]
			if row is Dictionary and row.get("kind") == "reward_delivery" and str(row.get("source", "")).contains(str(args.get("find", "?"))):
				escrow.erase(key)
				forgot += 1
		var taken: bool = local.get("inventory").call("remove", str(args.get("item", "")), int(args.get("count", 0))) == true
		return {"verdict": "PASS" if forgot == 1 and taken else "FAIL", "detail": "forgot %d payout row(s), took %d %s: %s" % [forgot, int(args.get("count", 0)), str(args.get("item", "")), str(taken)], "frames_used": 0}
	if action != "op_diverge":
		return await super(msg)
	var game := root.get_node_or_null(^"Game")
	var party: RefCounted = game.get("party") if game != null else null
	var member: RefCounted = party.call("at", 0) if party != null else null
	if member == null:
		return {"verdict": "ERROR", "detail": "no owned creature to diverge"}
	var before := int(member.get("level"))
	member.call("set_level", before + 1, preload("res://scripts/creatures/progression.gd").config())
	return {"verdict": "PASS", "detail": "owned creature 0 level %d -> %d on this peer only" % [before, int(member.get("level"))],
		"frames_used": 0}


func _execute_probe(msg: Dictionary) -> Variant:
	if str(msg.get("what", "")) == "op_tag_state":
		return _tag_state(msg.get("args", {}))
	if str(msg.get("what", "")) != "op_state":
		return await super(msg)
	var game := root.get_node_or_null(^"Game")
	var session: Node = game.get_node_or_null(^"Session") if game != null else null
	if session == null:
		return {"error": "no session"}
	var service: RefCounted = session.call("_owner_passive_service")
	var local: Dictionary = service.get("local")
	var out := {
		"is_host": bool(session.call("is_host")),
		"character_id": str(game.get("local").character_id),
		"local": {
			"armed": not local.is_empty(),
			"id": str(local.get("id", "")),
			"admission_pending": bool(local.get("admission_pending", false)),
			"acked": int(local.get("acked", -1)),
			"sequence": int(local.get("sequence", -1)),
			"error": str(local.get("error", "")),
			"admission_refused": str(local.get("admission_refused", "")),
		},
		"hosts": {},
	}
	out["items"] = _counts((game.get("local").save_data() as Dictionary).get("inventory", []))
	out["levels"] = []
	for member: RefCounted in game.get("party").call("members"): out.levels.append(int(member.get("level")))
	out["authority"] = {}
	out["tonic"] = _tonic_state(game, session)
	out["mastery"] = _mastery_state(game, session)
	out["rejoin_codes"] = (session.get("last_rejoin_admission") as Dictionary).duplicate() if bool(session.call("is_host")) else {}
	if bool(session.call("is_host")):
		var authority: RefCounted = session.get("_character_authority")
		for character: String in authority.get("_records"):
			var held: Dictionary = authority.call("state", character)
			out.authority[character] = {"items": _counts(held.get("inventory", [])),
				"levels": (held.get("party", []) as Array).map(func(c: Dictionary) -> int: return int(c.get("level", 0))),
				"revision": int(authority.call("revision", character))}
	var hosts: Dictionary = service.get("hosts")
	for character: String in hosts:
		var stream: Dictionary = hosts[character]
		out.hosts[character] = {"id": str(stream.get("id", "")), "peer": int(stream.get("peer", 0)),
			"sequence": int((stream.get("cursor", {}) as Dictionary).get("sequence", -1)),
			"departed": stream.get("departed") == true, "error": str(stream.get("error", ""))}
	return out


## Optional F24 continuation of the same real-peer smoke. Reuse its ordinary
## strike input and proximity setup; never stage a meter, hit, HP or verdict.
func _tag_step(action: String) -> Dictionary:
	var manager: Node = _combat_manager()
	var director: Node = _encounter_director()
	if action == "op_tag_target": return await _tonic_step("op_tonic_target", {})
	if manager == null or director == null or not manager.is_fighting():
		return {"verdict":"FAIL", "detail":"Tag requires the actual live fight"}
	if action == "op_tag_shove":
		# The same existing proximity setup, followed by the actual utility tap.
		var target: Node3D = director.get("_shared_opponent_proxy")
		if target == null: target = director.get("_legacy_mirror")
		var body: Node3D = director.ally_body()
		if target == null or body == null: return {"verdict":"FAIL", "detail":"actual Shove body missing"}
		body.global_position = target.global_position + Vector3(0, 0, 3.0)
		body.face_towards(target.global_position)
		for frame in 15: await physics_frame
		var pressed: Dictionary = await _step_press({"action":"combat_utility"})
		for frame in 90: await physics_frame
		return pressed
	if action == "op_tag_replay":
		if _tag_request.is_empty() or not manager.submit_tether_command(_tag_request):
			return {"verdict":"FAIL", "detail":"same Tag request could not be submitted"}
		for frame in 90: await physics_frame
		return {"verdict":"PASS", "detail":"submitted the same original Tag request again"}
	if action != "op_tag_combo": return {"verdict":"ERROR", "detail":"unknown Tag step"}
	var input: Node = null
	for child: Node in manager.get_children():
		if child.get_script() == preload("res://scripts/ui/tether_command_input.gd"): input = child
	if input == null: return {"verdict":"FAIL", "detail":"actual mounted TetherCommandInput is missing for Tag"}
	var before := _tag_state({})
	var incoming_index := int(manager.call("_next_switchable_index", 1))
	if incoming_index < 0: return {"verdict":"FAIL", "detail":"no actual healthy next owned companion"}
	var incoming: RefCounted = (manager.get("_party") as Array)[incoming_index]
	var attempts: Array[Dictionary] = []
	for hit in 8:
		var target: Node3D = director.get("_shared_opponent_proxy")
		if target == null: target = director.get("_legacy_mirror")
		var body: Node3D = director.ally_body()
		if target == null or body == null or not manager.is_fighting():
			return {"verdict":"FAIL", "detail":"actual Tag target or body lost before earned meter", "data":{"attempts":attempts}}
		body.global_position = target.global_position + Vector3(0, 0, 3.0)
		body.face_towards(target.global_position)
		for frame in 15: await physics_frame
		var meter := float(manager.tether_command_snapshot().get("meter", 0.0))
		var observation: Dictionary = {"attempt":hit + 1, "meter_before":meter,
			"foe_hp_before":float(manager.enemy().hp) if manager.enemy() != null else -1.0}
		attempts.append(observation)
		var strike: Dictionary = await _step_strike({"facing":[0,0,-1], "settle":1})
		var strike_data: Dictionary = strike.get("data", {})
		observation["strike"] = {"verdict":str(strike.get("verdict", "")), "ok":strike_data.get("ok"),
			"code":str(strike_data.get("code", "")), "submitted_action":strike_data.get("submitted_action")}
		observation["meter_after"] = float(manager.tether_command_snapshot().get("meter", 0.0))
		observation["foe_hp_after"] = float(manager.enemy().hp) if manager.enemy() != null else -1.0
		observation["refusal"] = (manager.get("last_encounter_refusal") as Dictionary).duplicate(true)
		# These are local post-input observations, not a claim about a remote host's queues.
		var id: String = str(before.get("encounter_id", ""))
		var host: RefCounted = director.get("_encounter_host")
		var host_local: bool = director.call("_is_host") == true and host != null
		var pending: Dictionary = {"observed_ms":Time.get_ticks_msec(), "host_local":host_local,
			"vitals_pending":director.call("ordinary_actor_vitals_pending", id), "proposals":[], "actors":[]}
		for original: Dictionary in (director.get("_ordinary_actor_vitals_proposals") as Dictionary).values():
			if original.get("encounter_id") != id: continue
			var proposal: Dictionary = original.get("proposal", {})
			pending.proposals.append({"action_id":str(proposal.get("action_id", "")),
				"committed":original.get("committed"), "presented":original.get("presented"),
				"receipt_id":str(proposal.get("settlement_receipt", {}).get("receipt_id", ""))})
		var record: Dictionary = host.call("record", id) if host_local else director.get("_encounter")
		var members: Array = record.get("participants", {}).values()
		members.append_array(record.get("retained_actor_participants", {}).values())
		for member: Dictionary in members:
			for uid: String in member.get("actor_vitals", {}):
				var actor: Dictionary = member.actor_vitals[uid]
				pending.actors.append({"creature_uid":uid, "revision":actor.get("revision"),
					"settled_revision":actor.get("settled_revision")})
		if host_local:
			pending["tether_items"] = []
			for item: Dictionary in host.call("pending_tether_items", id):
				pending.tether_items.append({"peer_id":item.get("peer_id"), "presented":item.get("presented"),
					"sequence":item.get("intent", {}).get("request", {}).get("sequence")})
			pending["actor_vitals"] = []
			for actor: Dictionary in host.call("pending_actor_vitals", id):
				pending.actor_vitals.append({"creature_uid":actor.get("creature_uid"),
					"revision":actor.get("revision"), "settled_revision":actor.get("settled_revision")})
		observation["pending_after_input"] = pending
		if strike.get("verdict") != "PASS":
			strike_data["attempts"] = attempts
			strike["data"] = strike_data
			return strike
		for frame in 180:
			await physics_frame
			var snapshot: Dictionary = manager.tether_command_snapshot()
			observation["meter_after"] = float(snapshot.get("meter", 0.0))
			observation["foe_hp_after"] = float(manager.enemy().hp) if manager.enemy() != null else -1.0
			observation["refusal"] = (manager.get("last_encounter_refusal") as Dictionary).duplicate(true)
			if float(snapshot.get("meter", 0.0)) <= meter: continue
			if float(snapshot.meter) < 40.0: break
			if manager.call("can_switch") != true: continue
			if not input.request("tag_combo"):
				return {"verdict":"FAIL", "detail":"production TetherCommandInput refused Tag request", "data":{"attempts":attempts}}
			_tag_request = preload("res://scripts/combat/tether_commands.gd").intent(str(input.get("_encounter_id")),
				int(snapshot.get("generation", 0)), int(input.get("_sequence")), "tag_combo")
			for settle in 180:
				await physics_frame
				if manager.active_creature() == incoming:
					return {"verdict":"PASS", "detail":"actual earned-meter Tag switched to the next owned companion",
						"data":{"before":before, "after":_tag_state({}), "request":_tag_request,
							"incoming_uid":str(incoming.uid)}}
			return {"verdict":"FAIL", "detail":"Tag did not switch after actual fresh hit",
				"data":{"request":_tag_request, "state":_tag_state({}), "refusal":manager.get("last_encounter_refusal"), "attempts":attempts}}
	return {"verdict":"FAIL", "detail":"eight actual quick attempts did not earn a usable Tag window", "data":{"attempts":attempts}}


func _tag_state(args: Dictionary) -> Dictionary:
	var game: Node = root.get_node(^"Game")
	var session: Node = game.get_node(^"Session")
	var director: Node = _encounter_director()
	var manager: Node = _combat_manager()
	var peer := int(args.get("peer", session.local_peer_id()))
	var request: Dictionary = args.get("request", _tag_request)
	var body: Node3D = director.deployed_body_for(peer)
	var id := str(request.get("encounter_id", args.get("encounter_id", manager.encounter_id())))
	var original := {}
	var snare := {}
	var rally := {}
	var settlement := {}
	var record: Dictionary = director.get("_encounter")
	if session.is_host():
		var host: RefCounted = director.get("_encounter_host")
		record = host.record(id)
		# Detached live host snapshot, not a guest view or a refusal-time claim.
		# Keep every participant's revision debt and unpresented original visible.
		var world: RefCounted = game.get("world")
		var namespace_id := str(world.get("reward_delivery_namespace"))
		var deliveries: Dictionary = world.get("reward_deliveries")
		var bindings: Array[Dictionary] = []
		for retained: Dictionary in (director.get("_ordinary_actor_vitals_proposals") as Dictionary).values():
			if retained.get("encounter_id") != id or retained.get("presented") == true: continue
			var proposal: Dictionary = retained.get("proposal", {})
			bindings.append({"source":"unpresented_proposal",
				"character_id":str(retained.get("binding", {}).get("character_id", "")),
				"creature_uid":str(proposal.get("creature_uid", "")),
				"settlement_receipt":proposal.get("settlement_receipt", {}).duplicate(true),
				"committed":retained.get("committed"), "presented":retained.get("presented")})
		for actor: Dictionary in host.call("pending_actor_vitals", id):
			bindings.append({"source":"actor_revision_debt", "character_id":str(actor.get("character_id", "")),
				"creature_uid":str(actor.get("creature_uid", "")),
				"settlement_receipt":actor.get("settlement_receipt", {}).duplicate(true),
				"revision":actor.get("revision"), "settled_revision":actor.get("settled_revision")})
		for binding: Dictionary in bindings:
			var delivery_id := preload("res://scripts/net/actor_vitals_delivery.gd").delivery_id(
				namespace_id, str(binding.character_id), str(binding.creature_uid))
			var journal: Dictionary = deliveries.get(delivery_id, {})
			binding["world_namespace"] = namespace_id
			binding["delivery_id"] = delivery_id
			binding["journal_present"] = deliveries.has(delivery_id)
			binding["journal_status"] = journal.get("status", "absent")
			binding["journal_receipt"] = journal.get("receipt", {}).duplicate(true)
			binding["journal_receipt_matches"] = not journal.is_empty() \
				and journal.get("receipt", {}) == binding.settlement_receipt
		settlement = {"observed_ms":Time.get_ticks_msec(), "encounter_id":id,
			"scope":"live_host_snapshot_all_participants", "namespace_source":"current_host_world",
			"gate_pending":director.call("_host_actor_settlement_pending", id),
			"pending_item_count":(host.call("pending_tether_items", id) as Array).size(), "bindings":bindings}
		if args.get("snare") == true:
			var wild: Node3D = director.get("_engaged_with")
			var target: RefCounted = wild.get("instance") if is_instance_valid(wild) else null
			var current: bool = target != null and record.get("phase") == "active" \
				and str(target.uid) == record.get("opponent", {}).get("card", {}).get("uid") \
				and int(wild.get_meta(&"tether_body_generation", 0)) == int(record.get("opponent", {}).get("body_generation", -1))
			var bonuses := {}
			if current:
				for participant: int in record.get("participants", {}):
					var character := str(record.participants[participant].get("character_id", ""))
					bonuses[character] = float(director.call("_host_command_catch_bonus", id, participant, wild, record))
			snare = {"observed_ms":Time.get_ticks_msec(), "target_current":current, "target_uid":str(target.uid) if target != null else "",
				"target_generation":int(wild.get_meta(&"tether_body_generation", 0)) if is_instance_valid(wild) else 0,
				"movement_multiplier":float(wild.call("utility_movement_multiplier")) if current else 1.0,
				"status":wild.get_meta(&"tether_snare", {}).duplicate(true) if is_instance_valid(wild) else {},
				"catch_bonuses":bonuses,
				"last_receipt":record.get("participants", {}).get(peer, {}).get("tether_commands", {}).get("last_receipt", {}).duplicate(true)}
		if args.get("rally") == true:
			var now_ms := Time.get_ticks_msec()
			var modifiers := {}
			for participant: int in record.get("participants", {}):
				var character := str(record.participants[participant].get("character_id", ""))
				modifiers[character] = host.call("tether_rally", id, participant, now_ms)
			rally = {"observed_ms":now_ms, "modifiers":modifiers,
				"binding":director.call("_strike_actor_binding", id, peer, body),
				"last_receipt":record.get("participants", {}).get(peer, {}).get("tether_commands", {}).get("last_receipt", {}).duplicate(true)}
		if not request.is_empty() and args.get("snare") != true and args.get("rally") != true:
			var parent := "command:%s:%s:%d:%d" % [id, str(args.get("character_id", game.local.character_id)),
				int(request.generation), int(request.sequence)]
			original = host.move_action_original(id, peer, parent)
	var pos := body.global_position if is_instance_valid(body) else Vector3.ZERO
	var out := {"peer":session.local_peer_id(), "character_id":str(game.local.character_id),
		"encounter_id":str(manager.encounter_id()), "deployment":director.tether_command_deployment(),
		"body_instance":body.get_instance_id() if is_instance_valid(body) else 0, "position":[pos.x,pos.y,pos.z],
		"commands":manager.tether_command_snapshot(), "record":record, "original":original,
		"seen_impacts":(manager.get("_seen_impact_actions") as Dictionary).keys(),
		"impact_history":(manager.get("_seen_impact_actions") as Dictionary).duplicate(true),
		"enemy_hp":float(manager.enemy().hp) if manager.enemy() != null else -1.0,
		"combat_state":manager.state,
		"party":game.party.members().map(func(c: RefCounted) -> String: return str(c.uid))}
	if args.get("snare") == true: out["snare"] = snare
	if args.get("rally") == true: out["rally"] = rally
	if session.is_host(): out["host_settlement_snapshot"] = settlement
	if session.is_host() and args.get("shove") == true:
		var wild: Node3D = director.get("_engaged_with")
		var target: RefCounted = wild.get("instance") if is_instance_valid(wild) else null
		out["shove"] = {"target_uid":str(target.get("uid")) if target != null else "", "encounter_id":id,
			"generation":int(wild.get_meta(&"tether_body_generation", 0)) if is_instance_valid(wild) else 0,
			"receipts":(wild.get("_landed_utility_state") as Dictionary).get("receipts", {}).duplicate(true) \
				if is_instance_valid(wild) else {}}
	return out


func _tonic_step(action: String, args: Dictionary) -> Dictionary:
	var game: Node = root.get_node(^"Game")
	var session: Node = game.get_node(^"Session")
	match action:
		"op_tonic_candidate":
			if OS.get_cmdline_user_args().has("--capture-combat-hud"):
				if _peer_index != 1 or DisplayServer.get_name() == "headless":
					return {"verdict":"FAIL", "detail":"HUD capture requires the native guest1"}
				var inherited_size := root.size
				_hud_capture_metadata = preload("res://tools/lookdev_capture_bootstrap.gd").prepare(self, "--hud-output=")
				if _hud_capture_metadata.is_empty() or root.size != inherited_size:
					return {"verdict":"FAIL", "detail":"HUD bootstrap refused the preset/source/output or changed the parent resolution"}
				for arg: String in OS.get_cmdline_user_args():
					if arg.begins_with("--hud-output="): _hud_capture_metadata["output"] = arg.trim_prefix("--hud-output=")
				if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(str(_hud_capture_metadata.get("output", "")))) != OK:
					return {"verdict":"FAIL", "detail":"HUD output directory could not be created"}
			var commands: Script = preload("res://scripts/combat/tether_commands.gd")
			var math: Script = preload("res://scripts/combat/combat_math.gd")
			if OS.get_cmdline_user_args().has("--prove-shipping-tether"):
				for flag: String in ["runtime_enabled", "network_enabled", "ui_enabled"]:
					if commands.config().get("feature_flags", {}).get(flag) != true:
						return {"verdict":"FAIL", "detail":"shipping Tether proof requires tracked " + flag}
				var required_actor_vitals := not OS.get_cmdline_user_args().has("--without-actor-vitals")
				if bool(math.config().get("actor_vitals", {}).get("runtime_enabled", false)) != required_actor_vitals:
					return {"verdict":"FAIL", "detail":"shipping Tether proof refuses a local actor-vitals override"}
			else:
				# Existing disclosed mechanics selector only; shipping mode never mutates gates.
				commands._config = commands.config().duplicate(true)
				for flag: String in ["runtime_enabled", "network_enabled", "ui_enabled"]:
					commands._config.feature_flags[flag] = true
				math._config = math.config().duplicate(true)
				math._config.actor_vitals.runtime_enabled = not OS.get_cmdline_user_args().has("--without-actor-vitals")

		"op_tonic_hud_capture":
			var name := str(args.get("name", ""))
			if args.size() != 1 or name not in ["earned-command", "after-tag"] \
				or not OS.get_cmdline_user_args().has("--capture-combat-hud") or _hud_capture_metadata.is_empty() \
				or _peer_index != 1 or DisplayServer.get_name() == "headless":
				return {"verdict":"FAIL", "detail":"HUD capture requires an allowed witness name and prepared native guest1"}
			await process_frame
			# Same on-demand native rendering as the existing proof runner.
			# Its screenshot helper forces two draws after current HUD validation.
			var manager: Node = _combat_manager()
			var director: Node = _encounter_director()
			var hud: Node = director.get_parent().get_node_or_null("CombatHUD") if director != null else null
			var view: Dictionary = manager.new_system_combat_snapshot() if manager != null else {}
			var active: RefCounted = manager.active_creature() if manager != null else null
			var overlay: Control = hud.get("_system_overlay") if hud != null else null
			var ring: Control = overlay.get("_ring") if is_instance_valid(overlay) else null
			if active == null or not game.party.members().has(active) or view.get("active") != true \
				or view.get("creature_uid") != str(active.get("uid")) or not is_instance_valid(overlay) \
				or not overlay.is_visible_in_tree() or overlay.get("_uid") != view.creature_uid \
				or not is_instance_valid(ring) or not ring.is_visible_in_tree() \
				or float(view.get("ultimate_maximum", 0.0)) <= 0.0 \
				or view.get("commands", {}).get("meter") != manager.tether_command_snapshot().get("meter"):
				return {"verdict":"FAIL", "detail":"HUD capture has no visible current-owned-UID authoritative overlay", "data":view}
			var fraction := clampf(float(view.ultimate_meter) / float(view.ultimate_maximum), 0.0, 1.0)
			if not is_equal_approx(float(ring.get("fraction")), fraction):
				return {"verdict":"FAIL", "detail":"HUD ring differs from actual meter"}
			var legacy_readout: Control = hud.get("_ultimate_readout")
			var legacy_meter: Control = hud.get("_ultimate_meter")
			if not is_instance_valid(legacy_readout) or not is_instance_valid(legacy_meter) \
				or legacy_readout.is_visible_in_tree() or legacy_meter.is_visible_in_tree():
				return {"verdict":"FAIL", "detail":"Acknowledged combat overlay still shows duplicate legacy ultimate"}
			var moves: RefCounted = hud.get("_moves")
			var charged_id := str(active.get("move_charged"))
			var cells: Dictionary = overlay.get("_cells")
			var energy_gate: ProgressBar = cells.get("charged", {}).get("cooldown")
			if moves == null or not moves.has(charged_id) or not is_instance_valid(energy_gate):
				return {"verdict":"FAIL", "detail":"Current owned charged move has no energy gate"}
			var charged_cost := float(moves.move(charged_id).get("energy_cost", 100.0))
			var energy := float(active.get("energy"))
			var utility_id := str(active.get("move_utility"))
			if not moves.has(utility_id): return {"verdict":"FAIL", "detail":"Current owned utility has no authored wind cost"}
			var utility_cost := float(moves.move(utility_id).get("wind_cost", 24.0))
			if not is_equal_approx(float(view.slots.utility.get("wind_cost", -1.0)), utility_cost):
				return {"verdict":"FAIL", "detail":"Utility HUD cost differs from authored current owned move"}
			if not energy_gate.is_visible_in_tree() or not is_equal_approx(energy_gate.max_value, charged_cost) \
				or not is_equal_approx(energy_gate.value, clampf(energy, 0.0, charged_cost)):
				return {"verdict":"FAIL", "detail":"Charged energy gate differs from current owned creature resource"}
			var viewport_rect := Rect2(Vector2.ZERO, Vector2(root.size))
			var hud_regions := {"ultimate":ring, "commands":overlay.get("_commands"), "moves":overlay.get("_moves")}
			var region_rects := {}
			for region: String in hud_regions:
				var control: Control = hud_regions[region]
				# The project stretches its 1920x1080 canvas into the native
				# window. Compare window pixels with window pixels, including
				# the canvas layer and stretch transforms.
				var rect: Rect2 = root.get_final_transform() * control.get_global_transform_with_canvas() \
					* Rect2(Vector2.ZERO, control.size)
				region_rects[region] = [rect.position.x, rect.position.y, rect.size.x, rect.size.y]
				if not control.is_visible_in_tree() or not rect.has_area() or not viewport_rect.encloses(rect):
					return {"verdict":"FAIL", "detail":"HUD region is empty or outside viewport: " + region + " " + JSON.stringify(region_rects), "data":region_rects}
			var shot: Dictionary = await PROOF_STEPS.run(self, "screenshot", {"name":"hud-" + name})
			if shot.get("verdict") != "PASS" or shot.get("data", {}).get("captured") != true: return {"verdict":"FAIL", "detail":"HUD screenshot was not captured", "data":shot}
			var graphics := preload("res://scripts/ui/graphics_prefs.gd")
			var receipt := _hud_capture_metadata.merged({"name":name, "snapshot":view,
				"continuous_render_loop":false, "charged_energy":energy, "charged_cost":charged_cost,
				"charged_gate_value":energy_gate.value, "charged_gate_maximum":energy_gate.max_value,
				"region_rects":region_rects,
				"legacy_ultimate_visible":legacy_readout.is_visible_in_tree() or legacy_meter.is_visible_in_tree(),
				"utility_wind_cost":utility_cost,
				"frame":Engine.get_process_frames(), "physics_frame":Engine.get_physics_frames(),
				"viewport":[root.size.x, root.size.y], "renderer":RenderingServer.get_current_rendering_method(),
				"preset":graphics.selected(), "graphics":graphics.values(), "ring_fraction":float(ring.get("fraction")),
				"png":str(shot.data.path)}, true)
			var path := ProjectSettings.globalize_path(str(_hud_capture_metadata.output)).path_join(name + ".json")
			var file := FileAccess.open(path, FileAccess.WRITE)
			if file == null: return {"verdict":"FAIL", "detail":"HUD receipt could not open: " + path}
			file.store_string(JSON.stringify(receipt, "\t"))
			file.flush()
			if file.get_error() != OK: return {"verdict":"FAIL", "detail":"HUD receipt write failed: " + path}
			return {"verdict":"PASS", "detail":"captured actual combat HUD", "data":receipt}
		"op_tonic_supply":
			# The existing smoke already seeds a portable party before admission.
			game.inventory.add("attack_tonic", 2)
			if not game.autosave_here(): return {"verdict":"FAIL", "detail":"initial tonic stock save refused"}
		"op_tonic_pouch":
			var original := {"assignment_id":"op-tonic-pouch", "index":0, "item_id":"attack_tonic"}
			var view: Dictionary = session.homestead_personal_view()
			for poll in 20:
				if not view.is_empty(): break
				for frame in 30: await physics_frame
				view = session.homestead_personal_view()
			if view.is_empty(): return {"verdict":"FAIL", "detail":"current scoped personal pouch view unavailable"}
			var result: Dictionary = session.personal_pouch_submit(original, int(view.registry_revision), session.personal_pouch_scope())
			for frame in 600:
				if game.local.redesign_character.get("tether_pouch", []).has("attack_tonic") \
						and session.retained_training_transaction(["tether_pouch"]).is_empty(): break
				await physics_frame
			if not game.local.redesign_character.get("tether_pouch", []).has("attack_tonic"):
				return {"verdict":"FAIL", "detail":"production pouch assignment did not save: "+str(result)}
		"op_tonic_target":
			var director: Node = _encounter_director()
			var selected: Node3D = null
			var largest := 0.0
			for wild: Node3D in director.get("_wild_creatures"):
				if not is_instance_valid(wild) or not wild.is_inside_tree() or not wild.visible or not wild.is_alive(): continue
				var creature: RefCounted = wild.get("instance")
				if creature != null and float(creature.hp) > largest:
					selected = wild
					largest = float(creature.hp)
			if selected == null: return {"verdict":"FAIL", "detail":"no actual live wild for tonic command"}
			var player: Node3D = _probe.call("player")
			player.global_position = selected.global_position + Vector3(2.0, 0, 0)
			for frame in 6: await physics_frame
			var engage_result: Dictionary = await _step_engage_wild({})
			if session.is_host() and engage_result.get("verdict") != "PASS":
				# Observe the failed preparation where it actually returned. This
				# is a live return-time snapshot, not a prior refusal-time claim.
				var failed_offer: Dictionary = _tag_state({})
				var ally: RefCounted = director.ally_instance()
				var target: RefCounted = selected.get("instance") if is_instance_valid(selected) else null
				failed_offer["engage_stage"] = {"observed_ms":Time.get_ticks_msec(),
					"manager_fighting":_combat_manager().is_fighting(), "trainer_battle_active":director.trainer_battle_active(),
					"ally_present":ally != null, "ally_hp":ally.hp if ally != null else null,
					"ally_fainted":ally.fainted if ally != null else null,
					"selected_body_instance":selected.get_instance_id() if is_instance_valid(selected) else 0,
					"selected_uid":str(target.uid) if target != null else "",
					"selected_visible":selected.visible if is_instance_valid(selected) else false,
					"selected_alive":selected.is_alive() if is_instance_valid(selected) else false,
					"selected_distance":player.global_position.distance_to(selected.global_position) if is_instance_valid(selected) else null,
					"engage_range":director.get("_engage_range")}
				print("TAG/TONIC failed Engage host observation: ", JSON.stringify(failed_offer))
			return engage_result
		"op_tonic_hits":
			var director: Node = _encounter_director()
			var manager: Node = _combat_manager()
			var command := str(args.get("command_id", "item_throw"))
			var slot := str(args.get("slot", "quick"))
			if slot not in ["quick", "charged"]: return {"verdict":"FAIL", "detail":"unsupported ordinary command hit slot"}
			var cost := float(preload("res://scripts/combat/tether_commands.gd").config().commands.get(command, {}).get("cost", INF))
			if command not in ["item_throw", "snare", "rally"] or not is_finite(cost):
				return {"verdict":"FAIL", "detail":"unknown authored command cost"}
			var attempts: Array[Dictionary] = []
			for hit in 8:
				var snapshot: Dictionary = manager.tether_command_snapshot()
				if float(snapshot.get("meter", 0.0)) >= cost: break
				if not manager.is_fighting(): return {"verdict":"FAIL", "detail":"fight ended before actual hits filled the command meter"}
				# The host owns the actual engaged wild; guests use its mirrors.
				var target: Node3D = director.get("_engaged_with") if session.is_host() else director.get("_shared_opponent_proxy")
				if target == null: target = director.get("_legacy_mirror")
				var body: Node3D = director.ally_body()
				if target == null or body == null: return {"verdict":"FAIL", "detail":"actual combat body missing"}
				var strike_facing := Vector3(0, 0, -1)
				if session.is_host():
					# Preserve the disclosed local-authority proximity fixture.
					body.global_position = target.global_position + Vector3(0, 0, 3.0)
					body.face_towards(target.global_position)
					for frame in 15: await physics_frame
					if not is_instance_valid(target) or not is_instance_valid(body):
						return {"verdict":"FAIL", "detail":"actual combat body lost during host preparation"}
					# The live wild can move during preparation. Use its current
					# direction for the ordinary physical input, as the guest does.
					strike_facing = target.call("centre") - body.call("centre")
					strike_facing.y = 0.0
					if strike_facing.is_zero_approx(): strike_facing = body.call("facing")
					strike_facing = strike_facing.normalized()
				else:
					# Local assignment cannot place the admitted host body. Use the
					# existing physical navigator for exactly the same 15 frames.
					_drive_left(0.0, 0.0)
					var rig: Node3D = _probe.call("camera_rig")
					var approach_id := str(manager.encounter_id())
					var active: RefCounted = manager.active_creature()
					var deployment: Dictionary = director.tether_command_deployment().duplicate(true)
					if rig == null or active == null or int(deployment.get("generation", 0)) < 1:
						return {"verdict":"FAIL", "detail":"actual owned approach camera or deployment missing"}
					var approach_uid := str(active.uid)
					var nav = NAVIGATOR.new(self, body, rig, Callable(self, "_drive_left"))
					for frame in 15:
						target = director.get("_shared_opponent_proxy")
						if target == null: target = director.get("_legacy_mirror")
						active = manager.active_creature()
						if not is_instance_valid(target) or not is_instance_valid(body) or director.ally_body() != body \
							or not manager.is_fighting() or str(manager.encounter_id()) != approach_id or active == null \
							or str(active.uid) != approach_uid or director.tether_command_deployment() != deployment:
							_drive_left(0.0, 0.0)
							return {"verdict":"FAIL", "detail":"owned approach body or encounter changed"}
						await nav.step(target.global_position)
					_drive_left(0.0, 0.0)
					if not is_instance_valid(target) or not is_instance_valid(body) or director.ally_body() != body \
						or not manager.is_fighting() or str(manager.encounter_id()) != approach_id \
						or manager.active_creature() == null or str(manager.active_creature().uid) != approach_uid \
						or director.tether_command_deployment() != deployment:
						return {"verdict":"FAIL", "detail":"owned approach changed before physical strike"}
					# Facing remains an ordinary physical-input argument, not the
					# runner's forged/target-aimed strike branch.
					strike_facing = target.call("centre") - body.call("centre")
					strike_facing.y = 0.0
					if strike_facing.is_zero_approx(): strike_facing = body.call("facing")
					strike_facing = strike_facing.normalized()
				# Observe immediately before the existing strike step. Its unchanged
				# readiness wait may precede physical injection; this is not a host queue.
				var id := str(manager.encounter_id())
				var host: RefCounted = director.get("_encounter_host")
				var host_local: bool = director.call("_is_host") == true and host != null
				var pending: Dictionary = {"observed_ms":Time.get_ticks_msec(), "phase":"before_strike_step",
					"host_local":host_local, "host_queues_available":host_local,
					"vitals_pending_local":director.call("ordinary_actor_vitals_pending", id),
					"quick_ready":manager.quick_ready(), "input_available":manager.combat_input_available(),
					"move_awaiting_host":manager.get("_move_awaiting_host"), "proposals":[], "actors":[]}
				for original: Dictionary in (director.get("_ordinary_actor_vitals_proposals") as Dictionary).values():
					if original.get("encounter_id") != id: continue
					var proposal: Dictionary = original.get("proposal", {})
					pending.proposals.append({"action_id":str(proposal.get("action_id", "")),
						"committed":original.get("committed"), "presented":original.get("presented"),
						"receipt_id":str(proposal.get("settlement_receipt", {}).get("receipt_id", ""))})
				var record: Dictionary = host.call("record", id) if host_local else director.get("_encounter")
				pending["actors_scope"] = "host_record" if host_local else "received_record"
				var participants: Array = record.get("participants", {}).values()
				participants.append_array(record.get("retained_actor_participants", {}).values())
				for participant: Dictionary in participants:
					for uid: String in participant.get("actor_vitals", {}):
						var actor: Dictionary = participant.actor_vitals[uid]
						pending.actors.append({"creature_uid":uid, "revision":actor.get("revision"),
							"settled_revision":actor.get("settled_revision")})
				if host_local:
					pending["host_actor_vitals"] = []
					for actor: Dictionary in host.call("pending_actor_vitals", id):
						pending.host_actor_vitals.append({"creature_uid":actor.get("creature_uid"),
							"revision":actor.get("revision"), "settled_revision":actor.get("settled_revision")})
				else:
					pending["host_actor_vitals"] = "unavailable: remote host"
				var observation: Dictionary = {"attempt":hit + 1, "slot":slot, "pending_before_input":pending,
					"meter_before":float(manager.tether_command_snapshot().get("meter", 0.0)),
					"foe_hp_before":float(manager.enemy().hp) if manager.enemy() != null else -1.0,
					"refusal_before":(manager.get("last_encounter_refusal") as Dictionary).duplicate(true)}
				attempts.append(observation)
				print("TONIC_PRE_STRIKE " + JSON.stringify(observation))
				var strike: Dictionary = await _step_strike({"slot":slot, "facing":[strike_facing.x, 0, strike_facing.z], "settle":90})
				var strike_data: Dictionary = strike.get("data", {})
				observation["strike"] = {"verdict":str(strike.get("verdict", "")), "reported_ok":strike_data.get("ok"),
					"code":str(strike_data.get("code", "")), "submitted_action":strike_data.get("submitted_action")}
				observation["meter_after"] = float(manager.tether_command_snapshot().get("meter", 0.0))
				observation["foe_hp_after"] = float(manager.enemy().hp) if manager.enemy() != null else -1.0
				observation["refusal_after"] = (manager.get("last_encounter_refusal") as Dictionary).duplicate(true)
				observation["refusal_unchanged"] = observation.refusal_after == observation.refusal_before
				if strike.get("verdict") != "PASS":
					strike_data["attempts"] = attempts
					strike["data"] = strike_data
					return strike
			if float(manager.tether_command_snapshot().get("meter", 0.0)) < cost:
				print("COMMAND precast observation: ", JSON.stringify({"command":command, "cost":cost, "attempts":attempts}))
				return {"verdict":"FAIL", "detail":"eight accepted %s attempts did not earn %s meter (%s required)" % [slot, command, cost],
					"data":{"command":command, "cost":cost, "attempts":attempts}}
			var hud: Node = director.get_parent().get_node_or_null("CombatHUD")
			var view: Dictionary = manager.new_system_combat_snapshot()
			var active: RefCounted = manager.active_creature()
			if hud == null or not is_instance_valid(hud.get("_system_overlay")) \
				or active == null or view.get("active") != true or view.get("creature_uid") != str(active.get("uid")) \
				or float(view.get("ultimate_meter", 0.0)) <= 0.0 \
				or view.get("commands", {}).get("meter") != manager.tether_command_snapshot().get("meter"):
				return {"verdict":"FAIL", "detail":"actual mounted HUD lacks the current acknowledged creature/command view: "+str(view)}
			var overlay: Control = hud.get("_system_overlay")
			var ring: Control = overlay.get("_ring")
			var expected_fraction := clampf(float(view.ultimate_meter) / float(view.ultimate_maximum), 0.0, 1.0)
			if not overlay.visible or ring == null or not is_equal_approx(float(ring.get("fraction")), expected_fraction):
				return {"verdict":"FAIL", "detail":"actual HUD did not display its acknowledged current-UID ultimate meter"}
		"op_tonic_snare":
			var manager: Node = _combat_manager()
			if not manager.is_fighting() or manager.enemy() == null or float(manager.enemy().hp) <= 0.0:
				return {"verdict":"FAIL", "detail":"Snare requires the same living actual wild target"}
			var input: Node = null
			for child: Node in manager.get_children():
				if child.get_script() == preload("res://scripts/ui/tether_command_input.gd"): input = child
			var before: Dictionary = manager.tether_command_snapshot()
			if input == null or not input.request("snare"):
				return {"verdict":"FAIL", "detail":"production TetherCommandInput refused Snare request"}
			# Observe the exact four values the production input just submitted.
			# Snare has no Item pending_request or Tag action-original journal.
			var request := preload("res://scripts/combat/tether_commands.gd").intent(str(input.get("_encounter_id")),
				int(before.get("generation", 0)), int(input.get("_sequence")), "snare")
			for frame in 90:
				await physics_frame
				var receipt: Dictionary = manager.tether_command_snapshot().get("last_receipt", {})
				if receipt.get("command_id") == "snare" and receipt.get("sequence") == request.sequence:
					return {"verdict":"PASS", "detail":"actual Snare command acknowledged", "data":{"request":request,
						"before":before, "after":_tag_state({"request":request})}}
			return {"verdict":"FAIL", "detail":"Snare lacked an accepted receipt within the existing short step budget",
				"data":{"request":request, "state":_tag_state({"request":request}), "refusal":manager.get("last_encounter_refusal")}}
		"op_tonic_rally":
			var manager: Node = _combat_manager()
			if not manager.is_fighting() or manager.enemy() == null or float(manager.enemy().hp) <= 0.0:
				return {"verdict":"FAIL", "detail":"Rally requires the same living actual wild encounter"}
			var input: Node = null
			for child: Node in manager.get_children():
				if child.get_script() == preload("res://scripts/ui/tether_command_input.gd"): input = child
			var before: Dictionary = manager.tether_command_snapshot()
			if input == null or not input.request("rally"):
				return {"verdict":"FAIL", "detail":"production TetherCommandInput refused Rally request"}
			# Observe the production input's submitted identity; Rally retains its
			# participant receipt, not an Item pending request or Tag journal.
			var request := preload("res://scripts/combat/tether_commands.gd").intent(str(input.get("_encounter_id")),
				int(before.get("generation", 0)), int(input.get("_sequence")), "rally")
			for frame in 90:
				await physics_frame
				var receipt: Dictionary = manager.tether_command_snapshot().get("last_receipt", {})
				if receipt.get("command_id") == "rally" and receipt.get("sequence") == request.sequence:
					return {"verdict":"PASS", "detail":"actual Rally command acknowledged", "data":{"request":request,
						"before":before, "after":_tag_state({"request":request, "rally":true})}}
			return {"verdict":"FAIL", "detail":"Rally lacked an accepted receipt within the existing short step budget",
				"data":{"request":request, "state":_tag_state({"request":request, "rally":true}), "refusal":manager.get("last_encounter_refusal")}}
		"op_tonic_clear":
			# Existing proximity fixture: stop exposing this owned actor to a
			# new enemy hit while the original Item's writer refusal is tested.
			var director: Node = _encounter_director()
			var target: Node3D = director.get("_shared_opponent_proxy")
			var body: Node3D = director.ally_body()
			if target == null or body == null: return {"verdict":"FAIL", "detail":"actual combat body missing"}
			body.global_position = target.global_position + Vector3(0, 0, 18.0)
			for frame in 60: await physics_frame
		"op_tonic_writer":
			var store: RefCounted = game.save_system.characters()
			if args.get("block") == true:
				_tonic_character_dir = str(store.get("_dir"))
				var blocker := "user://op-tonic-write-blocker"
				var file := FileAccess.open(blocker, FileAccess.WRITE)
				if file == null: return {"verdict":"FAIL", "detail":"could not arm actual character-writer refusal"}
				file.store_string("disclosed owner-save refusal fixture")
				file.close()
				store.set("_dir", blocker + "/")
			else:
				store.set("_dir", _tonic_character_dir)
				var ledger: Node = session.get_node("LedgerRpc")
				if _tonic_blocker.is_valid() and ledger.delta_applied.is_connected(_tonic_blocker):
					ledger.delta_applied.disconnect(_tonic_blocker)
				_tonic_blocker = Callable()
		"op_tonic_item":
			var manager: Node = _combat_manager()
			var input: Node = null
			for child: Node in manager.get_children():
				if child.get_script() == preload("res://scripts/ui/tether_command_input.gd"): input = child
			# Let the real owner-passive checkpoint save first. The existing
			# ledger signal observes the exact Item publication synchronously,
			# before its deferred owner apply can reach CharacterSave.write.
			var ledger: Node = session.get_node("LedgerRpc")
			_tonic_refusal_armed = false
			_tonic_blocker = func(delta: Dictionary) -> void:
				if _tonic_refusal_armed: return
				for op: Variant in delta.get("ops", []):
					if not op is Dictionary or op.get("op") != "creature_training_settle": continue
					var row: Dictionary = op.get("delivery", {})
					if row.get("action") != "tether_item" or row.get("status") != "pending" \
						or row.get("character_id") != game.local.character_id \
						or row.get("intent", {}).get("request") != _tonic_request: continue
					var blocked: Dictionary = await _tonic_step("op_tonic_writer", {"block":true})
					_tonic_refusal_armed = blocked.get("verdict") == "PASS"
			ledger.delta_applied.connect(_tonic_blocker)
			if input == null or not input.request("item_throw"):
				return {"verdict":"FAIL", "detail":"production TetherCommandInput refused Item request"}
			_tonic_request = manager.get("_tether_command_view").get("pending_request", {}).duplicate(true)
			for frame in 180: await physics_frame
			print("TONIC actual Item view: ", JSON.stringify(manager.get("_tether_command_view")))
			if not _tonic_refusal_armed:
				return {"verdict":"FAIL", "detail":"exact pending Item never reached the actual owner writer refusal"}
		"op_tonic_retry":
			var manager: Node = _combat_manager()
			if _tonic_request.is_empty() or not manager.submit_tether_command(_tonic_request):
				return {"verdict":"FAIL", "detail":"same original Item retry refused"}
			for frame in 180: await physics_frame
		_:
			return {"verdict":"ERROR", "detail":"unknown tonic step"}
	return {"verdict":"PASS", "detail":action, "data":_tonic_state(game, session)}


func _tonic_state(game: Node, session: Node) -> Dictionary:
	var owned := {}
	for member: RefCounted in game.party.members():
		owned[str(member.uid)] = {"buffs":member.active_buffs.duplicate(true),
			"attack_scale":member.buff_scale("attack"), "instance":member.get_instance_id()}
	var rows := {}
	for row: Dictionary in game.world.reward_deliveries.values():
		if row.get("action") == "tether_item":
			rows[str(row.character_id)] = {"receipt":row.receipt, "status":row.status,
				"request":row.intent.request.duplicate(true), "uid":row.intent.effect.creature_uid}
	var projected := {}
	var readiness := {}
	if session.is_host():
		var authority: RefCounted = session.get("_character_authority")
		for character: String in authority.get("_records"):
			projected[character] = authority.tether_tonic_projection(character)
		var director: Node = _encounter_director()
		var manager: Node = _combat_manager()
		if director != null and manager != null:
			var record: Dictionary = director.encounter_record()
			for peer: Variant in record.get("participants", {}):
				var character := str(record.participants[peer].character_id)
				readiness[character] = {"admission":session._tether_item_admission_ready(int(peer)),
					"vitals_pending":director.ordinary_actor_vitals_pending(str(record.get("encounter_id", "")))}
	var store: RefCounted = game.save_system.characters() if _tonic_character_dir.is_empty() \
		else preload("res://scripts/save/character_save.gd").new(_tonic_character_dir)
	var saved: Dictionary = store.read(str(game.local.character_id))
	return {"owned":owned, "rows":rows, "projected":projected, "readiness":readiness, "stock":game.inventory.count("attack_tonic"),
		"disk_stock":_counts(saved.get("inventory", [])).get("attack_tonic", 0),
		"disk_receipts":saved.get("redesign_character", {}).get("transaction_receipts", []),
		"saved_result":session.get("_tether_item_saved_result").get("result", {}).duplicate(true),
		"retry":session.get("_owner_training_retry").get("saved", false), "fenced":session.owns_input()}


func _mastery_state(game: Node, session: Node) -> Dictionary:
	var live := {}
	for member: RefCounted in game.party.members():
		live[str(member.uid)] = {"move":member.move_quick,
			"uses":member.move_mastery_uses.duplicate(true), "receipts":member.move_mastery_receipts.duplicate(true)}
	var saved: Dictionary = game.save_system.characters().read(str(game.local.character_id)) if _tonic_character_dir.is_empty() \
		or game.save_system.characters().get("_dir") == _tonic_character_dir else {}
	var disk := {}
	for card: Dictionary in saved.get("party", []):
		disk[str(card.uid)] = {"uses":card.get("move_mastery_uses", {}), "receipts":card.get("move_mastery_receipts", {})}
	var held := {}
	var retained := {}
	for row: Dictionary in game.world.reward_deliveries.values():
		if row.get("kind") != "foundation_event": continue
		for duty: Dictionary in row.get("duties", []):
			if duty.get("action") != "combat_mastery": continue
			var character := str(duty.character_id)
			if not retained.has(character): retained[character] = []
			retained[character].append(duty.context.outcome.duplicate(true))
	if session.is_host():
		var authority: RefCounted = session.get("_character_authority")
		for character: String in authority.get("_records"):
			held[character] = {}
			for card: Dictionary in authority.state(character).get("party", []):
				held[character][str(card.uid)] = {"uses":card.get("move_mastery_uses", {}), "receipts":card.get("move_mastery_receipts", {})}
	return {"live":live, "disk":disk, "held":held, "retained":retained}


static func _counts(slots: Variant) -> Dictionary:
	var out := {}
	if slots is Array:
		for slot: Variant in slots:
			if slot is Dictionary and not str(slot.get("id", "")).is_empty():
				out[str(slot.id)] = int(out.get(str(slot.id), 0)) + int(slot.get("n", 0))
	return out
