extends "res://tests/helpers/net_harness.gd"

# peers: 2

## F05 CI smoke. MIXED VERIDIAN CHOICES, TWO REAL PROCESSES, UNDER 3 MINUTES.
##
##   GODOT_BIN=$HOME/godot-bin/godot tools/net/run_net_smoke.sh veridian_mixed
##
## Owner rule (CLAUDE.md): every participant in the fight that freed the
## legendary receives their own offer; each who accepts keeps their own; a
## non-participant receives nothing; nobody is offered twice.
##
## The long witness (`smoke_net_veridian_choices.gd` on ralph/f05-coop-veridian)
## fights the real Warden and walks to the prompts, ~10 min. This one skips the
## fight and keeps every rule-bearing path real:
##
##   * the participant journal is written by the host's real `reward_grant`
##     ledger intent (the one the encounter director pays a shared trainer
##     fight with) -- `veridian_fixture`;
##   * `defeated_warden` and `legendary_freed` go through the story ledger
##     (`story_flag`, scope world) on the host and replicate as deltas;
##   * each peer's offer opens by the climax's own stage machine once its
##     player stands in the chamber (teleport to the machine's foot);
##   * each answer is that peer's own `accept_offer()` / `refuse_offer()` --
##     the methods the in-world prompts call -- on its own process;
##   * every `legendary_resolution:*` receipt is written by the game.
##
## Asserted: the guest (accepter) gains exactly one Veridian (4 -> 5) and holds
## `legendary_joined`; the host (refuser) keeps its four and holds
## `legendary_refused`; BOTH worlds hold exactly the accepted/refused/live
## receipts; no herd display on either peer; neither peer is re-offered; and a
## character absent from the journal would be offered nothing.

const PARTY := ["terrapup", "bramblebun", "trailpup", "mudsnout"]
const GUEST_NAME := "Veridian Guest"
const RECEIPT_LIVE := "legendary_resolution:live"
const WORLD_FLAGS := ["defeated_warden", "legendary_freed"]
const POLLS := 40
const NO_REOFFER_POLLS := 4

var _host_id := ""
var _guest_id := ""


func _initialize() -> void:
	_run()


func _run() -> void:
	var t0 := Time.get_ticks_msec()
	if not await launch(2, "world"):
		quit(await finish())
		return
	var port := int(((_peers[0] as Dictionary).get("hello", {}) as Dictionary).get("enet_port", 0))
	check(port > 0, "host reported its ENet port (%d)" % port)
	if port <= 0:
		quit(await finish())
		return

	# 1. Two saved characters, four creatures each (room for a fifth).
	for peer in 2:
		await step(peer, "dismiss_dialogue", {"presses": 40, "settle": 0})
		for species: String in PARTY:
			var granted: Dictionary = await step(peer, "party_grant", {"species": species, "level": 18})
			check(str(granted.get("verdict", "")) == "PASS", "FIXTURE: peer %d received %s" % [peer, species])
	_host_id = str(((await step(0, "save_character_here", {})).get("data", {}) as Dictionary).get("character_id", ""))
	_guest_id = str(((await step(1, "save_character_here", {})).get("data", {}) as Dictionary).get("character_id", ""))
	check(not _host_id.is_empty() and not _guest_id.is_empty() and _host_id != _guest_id,
		"two distinct stable characters (host '%s', guest '%s')" % [_host_id, _guest_id])
	if _host_id.is_empty() or _guest_id.is_empty() or _host_id == _guest_id:
		quit(await finish())
		return

	# 2. Session.
	var hosted: Dictionary = await step(0, "host", {"port": port})
	var joined: Dictionary = await step(1, "join", {"host": "127.0.0.1", "port": port,
		"character": {"character_id": _guest_id, "display_name": GUEST_NAME}}, 6000)
	check(str(hosted.get("verdict", "")) == "PASS" and str(joined.get("verdict", "")) == "PASS",
		"host hosted and guest joined (%s / %s)" % [str(hosted.get("detail", "")), str(joined.get("detail", ""))])
	if str(hosted.get("verdict", "")) != "PASS" or str(joined.get("verdict", "")) != "PASS":
		quit(await finish())
		return
	await step(1, "dismiss_dialogue", {"presses": 40, "settle": 0})

	# 3. Fixture on the HOST: journal both as Warden participants, then the
	# Warden's defeat and the freeing as world facts, all through the ledger.
	var fixture: Dictionary = await step(0, "veridian_fixture", {})
	check(str(fixture.get("verdict", "")) == "PASS", "FIXTURE: host journaled both participants (%s)"
		% str(fixture.get("detail", "")))
	for flag: String in WORLD_FLAGS:
		var set_flag: Dictionary = await step(0, "story_flag", {"flag": flag, "scope": "world"})
		check(str(set_flag.get("verdict", "")) == "PASS", "FIXTURE: host set world '%s' (%s)"
			% [flag, str(set_flag.get("detail", ""))])
	var want_participants: Array = [_host_id, _guest_id]
	want_participants.sort()
	for peer in 2:
		var seen: Dictionary = {}
		for _poll in POLLS:
			seen = await _choice(peer)
			var got: Array = (seen.get("participants", []) as Array).duplicate()
			got.sort()
			if got == want_participants and bool(seen.get("freed", false)):
				break
			await step(peer, "wait", {"frames": 10})
		var have: Array = (seen.get("participants", []) as Array).duplicate()
		have.sort()
		check(have == want_participants and bool(seen.get("freed", false)),
			"peer %d sees the freeing and both participants (%s)" % [peer, str(seen)])
		check(int(seen.get("party_size", -1)) == 4 and int(seen.get("veridian_count", -1)) == 0,
			"peer %d starts with four creatures and no Veridian" % peer)
		# NON-PARTICIPANT: the climax's own rule, in this peer's session
		# context, offers a character missing from the journal nothing.
		check(bool(seen.get("climax_found", false)) and not bool(seen.get("stranger_may_receive", true)),
			"peer %d: a non-participant character would be offered nothing" % peer)

	# 4. Both players stand in the chamber; each peer's own offer opens.
	var hold: Variant = await probe(0, "stronghold")
	var markers: Dictionary = (hold as Dictionary).get("markers", {}) as Dictionary if hold is Dictionary else {}
	var foot: Array = markers.get("machine_foot", []) as Array
	check(foot.size() == 3, "the Hall names its machine foot (%s)" % str(foot))
	if foot.size() != 3:
		quit(await finish())
		return
	for peer in 2:
		await step(peer, "teleport", {"at": [float(foot[0]) + (-1.5 if peer == 0 else 1.5),
			float(foot[1]) + 1.0, float(foot[2])], "settle": 10})
	for peer in 2:
		var view: Dictionary = await _drive_to_choice(peer)
		check(bool(view.get("choice_open", false)), "peer %d's own choice opened (%s)" % [peer, str(view)])
		if not bool(view.get("choice_open", false)):
			quit(await finish())
			return

	# 5. Mixed answers, each on its own process.
	var refused: Dictionary = await step(0, "veridian_answer", {"answer": "refuse"})
	check(str(refused.get("verdict", "")) == "PASS", "the host refused its own offer (%s)"
		% str(refused.get("detail", "")))
	var accepted: Dictionary = await step(1, "veridian_answer", {"answer": "accept"})
	check(str(accepted.get("verdict", "")) == "PASS", "the guest accepted its own offer (%s)"
		% str(accepted.get("detail", "")))

	# 6. Outcome. Wait (bounded) for both worlds to converge on the receipts.
	var want: Array = [RECEIPT_LIVE, "legendary_resolution:accepted:%s" % _guest_id,
		"legendary_resolution:refused:%s" % _host_id]
	want.sort()
	for _poll in POLLS:
		var a: Dictionary = await _choice(0)
		var b: Dictionary = await _choice(1)
		if a.get("receipts", []) == want and b.get("receipts", []) == want:
			break
		for peer in 2:
			await step(peer, "wait", {"frames": 8})
	var host: Dictionary = await _choice(0)
	var guest: Dictionary = await _choice(1)
	check(int(guest.get("veridian_count", -1)) == 1 and int(guest.get("party_size", -1)) == 5,
		"the accepter holds exactly one Veridian in a party of five (%s)" % str(guest))
	check(bool(guest.get("joined", false)) and not bool(guest.get("refused", true)),
		"the accepter's personal flag is legendary_joined only")
	check(int(host.get("veridian_count", -1)) == 0 and int(host.get("party_size", -1)) == 4,
		"the refuser's belt is unchanged (%s)" % str(host))
	check(bool(host.get("refused", false)) and not bool(host.get("joined", true)),
		"the refuser's personal flag is legendary_refused only")
	for peer in 2:
		var view: Dictionary = host if peer == 0 else guest
		check(view.get("receipts", []) == want, "peer %d's WORLD holds exactly %s (got %s)"
			% [peer, str(want), str(view.get("receipts", []))])
		check(bool(view.get("healing_found", false)) and not bool(view.get("herd_display", true)),
			"peer %d: no herd display after a mixed answer (healing found %s)"
				% [peer, str(view.get("healing_found", false))])

	# 7. Nobody is offered twice.
	var stages: Array = []
	for _poll in NO_REOFFER_POLLS:
		for peer in 2:
			await step(peer, "dismiss_dialogue", {"presses": 4, "settle": 8})
			var seen: Dictionary = await _choice(peer)
			var tag := "%d:%s" % [peer, str(seen.get("stage", "?"))]
			if not stages.has(tag):
				stages.append(tag)
			if bool(seen.get("pending_catch", false)) or bool(seen.get("may_receive", false)):
				stages.append("%d:still_offered" % peer)
	var reoffered := false
	for tag: String in stages:
		if tag.ends_with(":join") or tag.ends_with(":choice") or tag.ends_with(":freed") \
				or tag.ends_with(":still_offered"):
			reoffered = true
	check(not reoffered, "neither peer was offered the freeing again (stages seen: %s)" % str(stages))
	print("coordinator: veridian_mixed coordinator wall %.1f s" % ((Time.get_ticks_msec() - t0) / 1000.0))
	quit(await finish())


func _drive_to_choice(peer: int) -> Dictionary:
	var last: Dictionary = {}
	for _poll in POLLS:
		last = await _choice(peer)
		if bool(last.get("choice_open", false)):
			return last
		await step(peer, "dismiss_dialogue", {"presses": 8, "settle": 10})
	return last


func _choice(peer: int) -> Dictionary:
	var raw: Variant = await probe(peer, "veridian_choice")
	return raw as Dictionary if raw is Dictionary else {}
