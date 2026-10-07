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
	for hit in 8:
		var target: Node3D = director.get("_shared_opponent_proxy")
		if target == null: target = director.get("_legacy_mirror")
		var body: Node3D = director.ally_body()
		if target == null or body == null or not manager.is_fighting():
			return {"verdict":"FAIL", "detail":"actual Tag target or body lost before earned meter"}
		body.global_position = target.global_position + Vector3(0, 0, 3.0)
		body.face_towards(target.global_position)
		for frame in 15: await physics_frame
		var meter := float(manager.tether_command_snapshot().get("meter", 0.0))
		var strike: Dictionary = await _step_strike({"facing":[0,0,-1], "settle":1})
		if strike.get("verdict") != "PASS": return strike
		for frame in 180:
			await physics_frame
			var snapshot: Dictionary = manager.tether_command_snapshot()
			if float(snapshot.get("meter", 0.0)) <= meter: continue
			if float(snapshot.meter) < 40.0: break
			if manager.call("can_switch") != true: continue
			if not input.request("tag_combo"):
				return {"verdict":"FAIL", "detail":"production TetherCommandInput refused Tag request"}
			_tag_request = preload("res://scripts/combat/tether_commands.gd").intent(str(input.get("_encounter_id")),
				int(snapshot.get("generation", 0)), int(input.get("_sequence")), "tag_combo")
			for settle in 180:
				await physics_frame
				if manager.active_creature() == incoming:
					return {"verdict":"PASS", "detail":"actual earned-meter Tag switched to the next owned companion",
						"data":{"before":before, "after":_tag_state({}), "request":_tag_request,
							"incoming_uid":str(incoming.uid)}}
			return {"verdict":"FAIL", "detail":"Tag did not switch after actual fresh hit",
				"data":{"request":_tag_request, "state":_tag_state({}), "refusal":manager.get("last_encounter_refusal")}}
	return {"verdict":"FAIL", "detail":"eight actual quick attempts did not earn a usable Tag window"}


func _tag_state(args: Dictionary) -> Dictionary:
	var game: Node = root.get_node(^"Game")
	var session: Node = game.get_node(^"Session")
	var director: Node = _encounter_director()
	var manager: Node = _combat_manager()
	var peer := int(args.get("peer", session.local_peer_id()))
	var request: Dictionary = args.get("request", _tag_request)
	var body: Node3D = director.deployed_body_for(peer)
	var id := str(request.get("encounter_id", manager.encounter_id()))
	var original := {}
	var snare := {}
	var rally := {}
	var record: Dictionary = director.get("_encounter")
	if session.is_host():
		var host: RefCounted = director.get("_encounter_host")
		record = host.record(id)
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
	return out


func _tonic_step(action: String, args: Dictionary) -> Dictionary:
	var game: Node = root.get_node(^"Game")
	var session: Node = game.get_node(^"Session")
	match action:
		"op_tonic_candidate":
			# Disclosed process-local candidate gates, before actual world boot.
			# No shipped flag, authored item, HP, meter or timer is modified.
			var commands: Script = preload("res://scripts/combat/tether_commands.gd")
			commands._config = commands.config().duplicate(true)
			for flag: String in ["runtime_enabled", "network_enabled", "ui_enabled"]:
				commands._config.feature_flags[flag] = true
			var math: Script = preload("res://scripts/combat/combat_math.gd")
			math._config = math.config().duplicate(true)
			math._config.actor_vitals.runtime_enabled = true
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
			return await _step_engage_wild({})
		"op_tonic_hits":
			var director: Node = _encounter_director()
			var manager: Node = _combat_manager()
			var command := str(args.get("command_id", "item_throw"))
			var cost := float(preload("res://scripts/combat/tether_commands.gd").config().commands.get(command, {}).get("cost", INF))
			if command not in ["item_throw", "snare", "rally"] or not is_finite(cost):
				return {"verdict":"FAIL", "detail":"unknown authored command cost"}
			for hit in 8:
				var snapshot: Dictionary = manager.tether_command_snapshot()
				if float(snapshot.get("meter", 0.0)) >= cost: break
				if not manager.is_fighting(): return {"verdict":"FAIL", "detail":"fight ended before actual hits filled the command meter"}
				var target: Node3D = director.get("_shared_opponent_proxy")
				if target == null: target = director.get("_legacy_mirror")
				var body: Node3D = director.ally_body()
				if target == null or body == null: return {"verdict":"FAIL", "detail":"actual combat body missing"}
				body.global_position = target.global_position + Vector3(0, 0, 3.0)
				body.face_towards(target.global_position)
				for frame in 15: await physics_frame
				var strike: Dictionary = await _step_strike({"facing":[0,0,-1], "settle":90})
				if strike.get("verdict") != "PASS": return strike
			if float(manager.tether_command_snapshot().get("meter", 0.0)) < cost:
				return {"verdict":"FAIL", "detail":"eight accepted quick attempts did not earn %s meter (%s required)" % [command, cost]}
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
