extends "res://tests/helpers/net_harness.gd"

# peers: 2

## F05 (ACCEPTANCE §6.1; card M4 "relic/key are durable"), two real peers.
##
##   GODOT_BIN=$HOME/godot-bin/godot tools/net/run_net_smoke.sh veridian_relic_key
##
## The Warden's payout is the only source of the Meadows' two chapter rewards:
## `realm_key_cloudreach` (the Cloudreach gate's key) and
## `realm_heart_meadows_earned` (the Heart of the Meadows relic). Both are WORLD
## facts, committed once by the host's encounter rewards
## (scripts/net/encounter_rewards.gd). This smoke plays the real shared Warden
## fight -- no flag is set by hand -- then:
##
##   * both peers' WORLD stores hold the key and the earned Heart;
##   * the GUEST sets the Heart into a real shrine (`submit_place()`, the call
##     the interact prompt makes, which a client submits through the ledger), and
##     both worlds hold it placed;
##   * the HOST activates its personal Heart power; the guest does not -- the
##     power is personal, the relic is the world's;
##   * a production save/reload on the host, and the guest leaves and rejoins by
##     its character id (the returning route);
##   * afterwards, on both peers: key, earned and placed are still the world's;
##     the host's power is still active and the guest's still is not.
##
## Disclosed staging: parties are granted with `party_grant`, both peers are
## placed at the Warden arena with `explore_at`, and the win is driven by
## `win_trainer_battle` (smoke_net_shared_boss.gd's path). The shrine is a real
## `realm_heart_shrine.gd` stood in each process by `heart_bind`, the way the
## world stands the authored one.

const PARTY := ["terrapup", "bramblebun", "trailpup", "mudsnout"]
const WARDEN_TRAINER := "warden_aldis"
const BATTLE_FRAMES := 5400
const ENEMY_HP_CEILING := 6.0
const GUEST_NAME := "Relic Guest"
const KEY_FLAG := "realm_key_cloudreach"
const POLLS := 60

var _port := 0
var _host_id := ""
var _guest_id := ""


func _init_budgets() -> void:
	super._init_budgets()
	_budgets["smoke_step_budget_s_2peer"] = 1500.0
	_budgets["hello_budget_s"] = 360.0


func _initialize() -> void:
	_run()


func _run() -> void:
	# The guest's returning-route rejoin rebuilds the Meadows (one blocking
	# scene build after hello); the allowance the other scene-changing smokes use.
	heartbeat_silence_tolerance_s = 240.0
	if not await launch(2, "world"):
		quit(await finish())
		return
	_port = int(((_peers[0] as Dictionary).get("hello", {}) as Dictionary).get("enet_port", 0))
	check(_port > 0, "host reported its ENet port (%d)" % _port)
	if _port <= 0:
		quit(await finish())
		return

	# 1. Two saved characters.
	for peer in 2:
		await step(peer, "dismiss_dialogue", {"presses": 40, "settle": 0})
		for species: String in PARTY:
			var granted: Dictionary = await step(peer, "party_grant", {"species": species, "level": 18})
			check(str(granted.get("verdict", "")) == "PASS", "FIXTURE: peer %d received %s" % [peer, species])
	_host_id = str(((await step(0, "save_character_here", {})).get("data", {}) as Dictionary).get("character_id", ""))
	_guest_id = str(((await step(1, "save_character_here", {})).get("data", {}) as Dictionary).get("character_id", ""))
	check(not _host_id.is_empty() and not _guest_id.is_empty() and _host_id != _guest_id,
		"two distinct stable characters (host '%s', guest '%s')" % [_host_id, _guest_id])

	# 2. Session.
	var hosted: Dictionary = await step(0, "host", {"port": _port})
	var joined: Dictionary = await step(1, "join", {"host": "127.0.0.1", "port": _port,
		"character": {"character_id": _guest_id, "display_name": GUEST_NAME}}, 6000)
	check(str(hosted.get("verdict", "")) == "PASS" and str(joined.get("verdict", "")) == "PASS",
		"host hosted and guest joined (%s / %s)" % [str(hosted.get("detail", "")), str(joined.get("detail", ""))])
	if str(hosted.get("verdict", "")) != "PASS" or str(joined.get("verdict", "")) != "PASS":
		quit(await finish())
		return
	await step(1, "dismiss_dialogue", {"presses": 40, "settle": 0})

	# Before the fight: neither reward exists anywhere.
	for peer in 2:
		var heart0: Dictionary = await _heart(peer)
		var key0: Variant = _says(await _story(peer), KEY_FLAG)
		check(not bool(heart0.get("earned_in_world", true)) and key0 != true,
			"peer %d: no key and no earned Heart before the Warden (%s, key %s)" % [peer, str(heart0), str(key0)])

	# 3. The Warden, shared.
	for peer in 2:
		await step(peer, "deploy_creature", {})
	var hold: Variant = await probe(0, "stronghold")
	var markers: Dictionary = (hold as Dictionary).get("markers", {}) as Dictionary if hold is Dictionary else {}
	var arena: Array = markers.get("warden_arena", []) as Array
	check(arena.size() == 3, "the Hall names its Warden arena (%s)" % str(arena))
	if arena.size() != 3:
		quit(await finish())
		return
	for peer in 2:
		await step(peer, "explore_at",
			{"at": [float(arena[0]) + (2.0 if peer == 1 else -2.0), float(arena[2])], "settle": 60})
	var began: Dictionary = await step(0, "trainer_battle", {"trainer": WARDEN_TRAINER, "settle": 45})
	check(str(began.get("verdict", "")) == "PASS", "host challenged the Warden (%s)" % str(began.get("detail", "")))
	if str(began.get("verdict", "")) != "PASS":
		quit(await finish())
		return
	var record: Variant = await probe(0, "encounter")
	var encounter_id := str((record as Dictionary).get("id", "")) if record is Dictionary else ""
	var guest_in: Dictionary = await step(1, "join_encounter", {"encounter_id": encounter_id})
	check(str(guest_in.get("verdict", "")) == "PASS", "guest joined the Warden's own fight")
	var won: Dictionary = await step(0, "win_trainer_battle",
		{"budget_frames": BATTLE_FRAMES, "enemy_hp_ceiling": ENEMY_HP_CEILING}, BATTLE_FRAMES)
	check(str(won.get("verdict", "")) == "PASS", "both peers felled the Warden (%s)" % str(won.get("detail", "")))
	if str(won.get("verdict", "")) != "PASS":
		quit(await finish())
		return
	for peer in 2:
		await step(peer, "wait", {"frames": 120})
		await step(peer, "dismiss_dialogue", {"presses": 40, "settle": 30})

	# 4. The payout: the key and the earned Heart are the WORLD's, on both.
	for peer in 2:
		var ok := false
		var heart: Dictionary = {}
		var key: Variant = null
		for _poll in POLLS:
			heart = await _heart(peer)
			key = _says(await _story(peer), KEY_FLAG)
			if bool(heart.get("earned_in_world", false)) and key == true:
				ok = true
				break
			await step(peer, "wait", {"frames": 10})
		check(ok, "peer %d's WORLD holds the Cloudreach key and the earned Heart after the Warden (%s, key %s)"
			% [peer, str(heart), str(key)])

	# 5. The GUEST places the Heart (a client press, through the ledger).
	var bound_all := true
	for peer in 2:
		var bound: Dictionary = await step(peer, "heart_bind", {"heart": "meadows"})
		bound_all = bound_all and str(bound.get("verdict", "")) == "PASS"
	check(bound_all, "each peer stood a real Meadows shrine")
	var placed: Dictionary = await step(1, "heart_place", {})
	check(str(placed.get("verdict", "")) == "PASS", "the guest set the Heart into the shrine (%s)"
		% str(placed.get("detail", "")))
	for peer in 2:
		var seen := false
		for _poll in POLLS:
			if bool((await _heart(peer)).get("placed_in_world", false)):
				seen = true
				break
			await step(peer, "wait", {"frames": 10})
		check(seen, "peer %d's WORLD holds the Heart placed" % peer)

	# 6. The power is personal: the host wears it, the guest does not.
	var activated: Dictionary = await step(0, "heart_activate", {"heart": "meadows"})
	check(str(activated.get("verdict", "")) == "PASS", "the host activated its Heart power (%s)"
		% str(activated.get("detail", "")))
	await _assert_durable("before reload and rejoin")

	# 7. Host: production save/reload. Guest: leave and rejoin by its id.
	var reloaded: Dictionary = await step(0, "save_reload_here", {})
	check(str(reloaded.get("verdict", "")) == "PASS", "the host completed a production save/reload (%s)"
		% str(reloaded.get("detail", "")))
	var saved: Dictionary = await step(1, "save_character_here", {})
	check(str(saved.get("verdict", "")) == "PASS", "the guest saved its character before leaving")
	await step(1, "leave", {"reason": "player_left"})
	var one: Dictionary = await step(0, "expect_peers", {"count": 1}, 900)
	check(str(one.get("verdict", "")) == "PASS", "the host saw the guest leave")
	var rejoined: Dictionary = await step(1, "production_join",
		{"host": "127.0.0.1", "port": _port, "budget_frames": 6000, "returning_route": true,
		 "character": {"character_id": _guest_id, "display_name": GUEST_NAME}}, 6500)
	check(str(rejoined.get("verdict", "")) == "PASS", "the guest rejoined as '%s' (%s)"
		% [_guest_id, str(rejoined.get("detail", ""))])
	if str(rejoined.get("verdict", "")) != "PASS":
		quit(await finish())
		return
	var two: Dictionary = await step(0, "expect_peers", {"count": 2}, 900)
	check(str(two.get("verdict", "")) == "PASS", "the host is back to two peers")
	for peer in 2:
		await step(peer, "wait", {"frames": 120})
		await step(peer, "dismiss_dialogue", {"presses": 16, "settle": 30})
	for _poll in POLLS:
		var a: Dictionary = await _heart(0)
		var b: Dictionary = await _heart(1)
		if bool(a.get("placed_in_world", false)) and bool(b.get("placed_in_world", false)):
			break
		for peer in 2:
			await step(peer, "wait", {"frames": 10})
	await _assert_durable("after the host's reload and the guest's rejoin")
	quit(await finish())


func _assert_durable(when: String) -> void:
	for peer in 2:
		var heart: Dictionary = await _heart(peer)
		var key: Variant = _says(await _story(peer), KEY_FLAG)
		check(key == true, "%s: peer %d's WORLD holds the Cloudreach key" % [when, peer])
		check(bool(heart.get("earned_in_world", false)) and bool(heart.get("placed_in_world", false)),
			"%s: peer %d's WORLD holds the Heart earned and placed (%s)" % [when, peer, str(heart)])
		var want_active := "meadows" if peer == 0 else ""
		check(str(heart.get("active", "?")) == want_active,
			"%s: peer %d's personal Heart power is '%s' (got '%s')"
				% [when, peer, want_active, str(heart.get("active", "?"))])


func _heart(peer: int) -> Dictionary:
	var raw: Variant = await probe(peer, "realm_heart", {"heart": "meadows"})
	return raw as Dictionary if raw is Dictionary else {}


func _story(peer: int) -> Variant:
	return await probe(peer, "story", {"world_flags": [KEY_FLAG], "player_flags": []})


func _says(story: Variant, flag: String) -> Variant:
	if story is not Dictionary:
		return null
	var world: Variant = (story as Dictionary).get("world", {})
	if world is not Dictionary or not (world as Dictionary).has(flag):
		return null
	return bool((world as Dictionary)[flag])
