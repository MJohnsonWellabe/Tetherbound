extends "res://tools/net/proof_peer_runner.gd"

## PEER process for `tests/smoke_net_cloudreach_activity_payoffs.gd` (F07 #1).
## Not a smoke on its own: no `# peers:` header, never discovered by CI.
##
## Exactly the proof peer runner (every shared step and probe) plus five
## Cloudreach-lane steps that READ this peer's own live objects and saved files,
## and three narrow fixtures that stand in for input the harness cannot give.
## Kept in a lane-owned file so `tools/net/peer_runner.gd` stays unchanged.
##
##  * `cr_state`          read-only: world/player flags, the couriers' thanks
##                        offer, satchel potions, aerie markers and rests.
##  * `cr_disk`           read-only: this peer's OWN world and character files.
##  * `cr_report_to_neri` FIXTURE: Neri's report line through the chapter's
##                        real dialogue-effect guard (the solo smoke's seam).
##  * `cr_stand_at_reward` FIXTURE: teleport beside the thanks; reports the
##                        interaction arbiter's live prompt (no press).
##  * `cr_forge_claim`    ADVERSARY: submits the same `reward_grant` the offer
##                        submits, bypassing the offer's own "already claimed"
##                        gate, and reports what the host answered.
##  * `cr_aerie_land`     FIXTURE: stands the trainer on an aerie floor and
##                        emits the local FlyController's `landed` signal as a
##                        Fly touchdown there would (the solo smoke's seam).

const CR_REWARD_ID := "cr_reward_couriers_potions"
const CR_SOURCE := "cloudreach_couriers_thanks"
const CR_CLAIMED := "cloudreach_payout:couriers_thanks"
const CR_REPORT_EFFECT := "cloudreach:side:packs_on_the_wrong_side:report_to_neri"
const CR_WORLD_FLAGS := ["side_stranded_couriers_complete", "side_aerie_high_perches_surveyed",
	"side_aerie_observatory_surveyed", "side_aeries_complete"]
const CR_LEDGER_CLAIM := preload("res://scripts/world/ledger_claim.gd")
const CR_ACTIONS := ["cr_state", "cr_disk", "cr_report_to_neri", "cr_stand_at_reward",
	"cr_forge_claim", "cr_aerie_land"]

var _cr_refusals: Array = []


func _execute_step(msg: Dictionary) -> Dictionary:
	var action := str(msg.get("action", ""))
	if not CR_ACTIONS.has(action):
		return await super(msg)
	var args: Dictionary = msg.get("args", {}) as Dictionary
	var before := _physics_count
	var out: Dictionary
	match action:
		"cr_state":
			out = {"verdict": "PASS", "data": _cr_state()}
		"cr_disk":
			out = {"verdict": "PASS", "data": _cr_disk()}
		"cr_report_to_neri":
			out = _cr_report()
		"cr_stand_at_reward":
			out = await _cr_stand(args)
		"cr_forge_claim":
			out = await _cr_forge(args)
		"cr_aerie_land":
			out = await _cr_aerie(args)
	if not out.has("detail"):
		out["detail"] = JSON.stringify(out.get("data", {}))
	out["frames_used"] = _physics_count - before
	return out


func _cr_game() -> Node:
	return root.get_node_or_null(^"Game")


func _cr_physical() -> Node:
	var scene := current_scene
	var chapter := scene.get_node_or_null(^"CloudreachChapter") if scene != null else null
	return chapter.get("_physical") as Node if chapter != null else null


func _cr_payoffs() -> Node:
	var scene := current_scene
	var runtime := scene.get_node_or_null(^"CloudreachRuntime") if scene != null else null
	return runtime.get("payoffs") as Node if runtime != null else null


func _cr_reward() -> Node:
	var physical := _cr_physical()
	return physical.get_node_or_null(NodePath(CR_REWARD_ID)) if physical != null else null


func _cr_state() -> Dictionary:
	var game := _cr_game()
	var world_store: RefCounted = game.call("world_flags") as RefCounted
	var player_store: RefCounted = game.call("player_flags") as RefCounted
	var world := {}
	for flag: String in CR_WORLD_FLAGS:
		world[flag] = world_store != null and bool(world_store.call("has", flag))
	var reward := _cr_reward()
	var payoffs := _cr_payoffs()
	var markers := {}
	var rests := -1
	if payoffs != null:
		rests = int(payoffs.get("aerie_rests"))
		var raw: Dictionary = payoffs.get("markers")
		for id: String in raw:
			markers[id] = (raw[id] as Node3D).visible
	var people := {}
	if payoffs != null:
		var raw_people: Dictionary = payoffs.get("people")
		for id: String in raw_people:
			people[id] = bool((raw_people[id] as Dictionary).get("returned", false))
	var player := _probe.call("player") as Node3D
	var vitals: RefCounted = player.get("vitals") as RefCounted if player != null else null
	var local: RefCounted = game.get("local") as RefCounted
	var session: Node = _session()
	return {
		"realm": str(game.get("current_realm")),
		"scene": str(current_scene.name) if current_scene != null else "",
		"character_id": str(local.get("character_id")) if local != null else "",
		"peer_id": int(session.call("local_peer_id")) if session != null and session.has_method("local_peer_id") else 0,
		"world": world,
		"claimed": player_store != null and bool(player_store.call("has", CR_CLAIMED)),
		"reward_exists": reward != null,
		"offered": reward != null and bool(reward.call("offered")) and (reward as Node3D).visible,
		"claims_paid": int(reward.get("claims_paid")) if reward != null else -1,
		"potions": int((game.get("inventory") as RefCounted).call("count", "potion_small")),
		"markers": markers,
		"aerie_rests": rests,
		"people_returned": people,
		"stamina": float(vitals.get("stamina")) if vitals != null else -1.0,
		"max_stamina": float(vitals.get("max_stamina")) if vitals != null else -1.0,
		"refusals": _cr_refusals.duplicate(),
	}


## This peer's own saved files, read through the game's own savers.
func _cr_disk() -> Dictionary:
	var game := _cr_game()
	var saver: RefCounted = game.get("save_system") as RefCounted
	var worlds_out := {}
	var worlds: RefCounted = saver.call("worlds") as RefCounted
	for id: Variant in (worlds.call("list_ids") as Array):
		var state: Dictionary = worlds.call("state", str(id))
		var flags: Array = ((state.get("flags", {}) as Dictionary).get("flags", []) as Array)
		var held := {}
		for flag: String in CR_WORLD_FLAGS + [CR_CLAIMED]:
			held[flag] = flags.has(flag)
		var recipients: Array = []
		var deliveries: Variant = state.get("reward_deliveries", {})
		if deliveries is Dictionary:
			for key: Variant in (deliveries as Dictionary):
				var row: Variant = (deliveries as Dictionary)[key]
				if row is Dictionary and str((row as Dictionary).get("source", "")) == CR_SOURCE:
					recipients.append({"character_id": str((row as Dictionary).get("character_id", "")),
						"stacks": (row as Dictionary).get("stacks", []),
						"completion_flag": str((row as Dictionary).get("completion_flag", "")),
						"state": str((row as Dictionary).get("state", (row as Dictionary).get("status", "")))})
		worlds_out[str(id)] = {"flags": held, "couriers_deliveries": recipients}
	var characters_out := {}
	var characters: RefCounted = saver.call("characters") as RefCounted
	for id: Variant in (characters.call("list_ids") as Array):
		var state: Dictionary = characters.call("state", str(id))
		var flags: Array = ((state.get("flags", {}) as Dictionary).get("flags", []) as Array)
		var held := {}
		for flag: String in CR_WORLD_FLAGS + [CR_CLAIMED]:
			held[flag] = flags.has(flag)
		var potions := 0
		for stack: Variant in (state.get("inventory", []) as Array):
			if stack is Dictionary and str((stack as Dictionary).get("id", "")) == "potion_small":
				potions += int((stack as Dictionary).get("n", 0))
		characters_out[str(id)] = {"flags": held, "potions": potions}
	return {"worlds": worlds_out, "characters": characters_out}


func _cr_report() -> Dictionary:
	var physical := _cr_physical()
	if physical == null:
		return {"verdict": "ERROR", "detail": "no Cloudreach physical runtime in this scene"}
	var accepted := bool(physical.call("consume_dialogue_effect", CR_REPORT_EFFECT))
	return {"verdict": "PASS" if accepted else "FAIL",
		"detail": "Neri's report effect through the dialogue guard: accepted=%s" % str(accepted)}


func _cr_stand(args: Dictionary) -> Dictionary:
	var reward := _cr_reward() as Node3D
	var player := _probe.call("player") as CharacterBody3D
	if reward == null or player == null:
		return {"verdict": "ERROR", "detail": "no couriers' thanks node or player here"}
	player.global_position = reward.global_position + Vector3(1.0, 0.3, 0.0)
	player.velocity = Vector3.ZERO
	for i in maxi(1, int(args.get("settle", 30))):
		await physics_frame
	var arbiter := current_scene.get_node_or_null(^"InteractionArbiter")
	var prompt := ""
	if arbiter != null:
		arbiter.call("_recompute")
		prompt = str(arbiter.call("prompt"))
	return {"verdict": "PASS", "data": {"prompt": prompt, "offered": bool(reward.call("offered"))},
		"detail": "beside the thanks at %s; prompt '%s'" % [str(reward.global_position), prompt]}


func _cr_forge(args: Dictionary) -> Dictionary:
	var reward := _cr_reward()
	var game := _cr_game()
	if reward == null:
		return {"verdict": "ERROR", "detail": "no couriers' thanks node here"}
	_cr_listen()
	var inventory: RefCounted = game.get("inventory") as RefCounted
	var before := int(inventory.call("count", "potion_small"))
	var refusals_before := _cr_refusals.size()
	var verdict: Dictionary = CR_LEDGER_CLAIM.submit(reward, {
		"kind": "reward_grant", "realm": "cloudreach", "source": CR_SOURCE,
		"item": "potion_small", "count": 2, "flag": CR_CLAIMED,
	})
	for i in maxi(1, int(args.get("settle", 120))):
		await physics_frame
	var code := str(verdict.get("code", ""))
	if _cr_refusals.size() > refusals_before:
		code = str((_cr_refusals.back() as Dictionary).get("code", code))
	var after := int(inventory.call("count", "potion_small"))
	return {"verdict": "PASS", "data": {"ok": bool(verdict.get("ok", false)),
			"pending": bool(verdict.get("pending", false)), "code": code,
			"potions_before": before, "potions_after": after},
		"detail": "forged reward_grant: ok=%s pending=%s final code '%s'; potions %d -> %d"
			% [str(verdict.get("ok", false)), str(verdict.get("pending", false)), code, before, after]}


func _cr_listen() -> void:
	var transport := CR_LEDGER_CLAIM.transport(_cr_reward())
	if transport != null and not transport.is_connected("intent_refused", _cr_on_refused):
		transport.connect("intent_refused", _cr_on_refused)


func _cr_on_refused(kind: String, code: String, _reason: String, _detail: Dictionary) -> void:
	_cr_refusals.append({"kind": kind, "code": code})


func _cr_aerie(args: Dictionary) -> Dictionary:
	var payoffs := _cr_payoffs()
	var player := _probe.call("player") as CharacterBody3D
	if payoffs == null or player == null:
		return {"verdict": "ERROR", "detail": "no Cloudreach payoffs node or player here"}
	var marker := (payoffs.get("markers") as Dictionary).get(str(args.get("id", ""))) as Node3D
	if marker == null:
		return {"verdict": "ERROR", "detail": "no aerie marker '%s'" % str(args.get("id", ""))}
	player.global_position = marker.global_position + Vector3(1.5, 0.2, 0.0)
	player.velocity = Vector3.ZERO
	for i in maxi(1, int(args.get("settle", 40))):
		await physics_frame
	var vitals: RefCounted = player.get("vitals") as RefCounted
	vitals.set("stamina", float(args.get("stamina", 10.0)))
	var rests_before := int(payoffs.get("aerie_rests"))
	var stamina_before := float(vitals.get("stamina"))
	var on_floor := player.is_on_floor()
	var fly: Node = player.get("fly_controller") as Node
	fly.emit_signal("landed", player.global_position, "galewisp")
	await physics_frame
	var landed_at := player.global_position
	var offset := landed_at - marker.global_position
	var data := {"marker_visible": marker.visible, "on_floor": on_floor,
		"at_marker": absf(offset.y) <= 3.0 and Vector2(offset.x, offset.z).length() <= 12.0,
		"landed_at": [landed_at.x, landed_at.y, landed_at.z],
		"rests_before": rests_before, "rests_after": int(payoffs.get("aerie_rests")),
		"stamina_before": stamina_before, "stamina_after": float(vitals.get("stamina")),
		"max_stamina": float(vitals.get("max_stamina"))}
	return {"verdict": "PASS", "data": data, "detail": JSON.stringify(data)}
