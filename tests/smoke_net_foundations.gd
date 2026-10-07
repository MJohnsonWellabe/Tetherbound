extends "res://tests/helpers/net_harness.gd"

# peers: 2

## F16#3: real isolated ENet peers, production split saves and title rejoin.
## Every carrier field is a disclosed nondefault storage fixture. Future
## portal/training/crafting progression is not earned by this witness.
## F43 additionally uses the existing storage_grant stock and sleep fixtures,
## real Halda input, owner-save/ACK and same-ID reload. Materials are disclosed
## stock; this does not claim earned gathering or a campaign route.
const STATE := preload("res://scripts/data/redesign_state.gd")
const DATA := preload("res://scripts/data/redesign_data.gd")

func _initialize() -> void:
	_run()

func _run() -> void:
	# Let Game._ready finish before the harness relinquishes coordinator world
	# ownership; its initialization would otherwise reclaim the unused world.
	await process_frame
	heartbeat_silence_tolerance_s = 150.0
	if not await launch(2, "world", [], {1: ["--joiner"]}):
		quit(await finish())
		return
	var host_hello: Dictionary = (_peers[0] as Dictionary).get("hello", {})
	var guest_hello: Dictionary = (_peers[1] as Dictionary).get("hello", {})
	check(host_hello.get("user_data_dir", "") != guest_hello.get("user_data_dir", ""), "two distinct isolated peer homes")
	var port := int(host_hello.get("enet_port", 0))
	if not await _pass(0, "host", {"port": port}): return
	# The first board must be issued from the pristine shipping world, before
	# the storage fixture replaces the rollover counter with a nondefault six.
	# This is a real host/owner journal path, not a fabricated board carrier.
	var first_morning := await _settled_carrier(0)
	var first_board: Dictionary = first_morning.get("character", {}).get("bounties", {})
	check(first_morning.get("world", {}).get("bounty_day") == 0, "fresh-world bounty counter is still zero; no day advanced")
	check(first_board.get("anchor_day") == 1 and first_board.get("cycle") == 1 \
		and (first_board.get("slots", []) as Array).size() == 3,
		"pristine admission issues exactly three first-day personal bounties through the live adapter")
	if first_board.get("cycle") != 1 or (first_board.get("slots", []) as Array).size() != 3:
		quit(await finish())
		return
	if not await _pass(0, "foundations_state", {"mode": "seed", "marker": 1}): return
	if not await _pass(0, "foundations_state", {"mode": "roundtrip"}): return
	# The host's live runtimes act on the seeded world at once (the Halda board
	# issues its bounty cycle for `bounty_day`, adding `bounties` and a receipt,
	# then autosaves). Baseline the host only once its carrier has settled, so
	# later equality checks compare against the host's own state, not a race.
	var host := await _settled_carrier(0)
	check(_populated(host), "host populated all 8 world / 14 personal / 9 per-creature fields (%s)" % _unpopulated(host))
	# The initial admission must see the exact portable fixture. Replacing it
	# after joining leaves the host's immutable full-owner bounty row stale.
	if not await _pass(1, "foundations_state", {"mode": "seed", "marker": 2, "personal_only": true}): return
	for template: Dictionary in preload("res://scripts/world/bounty_board.gd").config().templates:
		if template.kind == "material_delivery":
			if not await _pass(1, "storage_grant", {"item": template.item, "n": int(template.count)}): return
	if not await _pass(1, "foundations_state", {"mode": "personal_roundtrip"}): return
	if not await _pass(1, "join", {"host": "127.0.0.1", "port": port}): return
	for peer in 2:
		if not await _pass(peer, "expect_peers", {"count": 2}): return
	var guest := await _settled_carrier(1)
	check(_populated(guest), "guest populated every personal and per-creature field")
	check(guest.get("world", {}) == host.get("world", {}), "host snapshot carries all 8 world fields")
	check(guest.get("character", {}) != host.get("character", {}), "personal fixture payloads are distinct")
	var guest_id := str(guest.get("character_id", ""))
	check(not guest_id.is_empty() and guest_id != str(host.get("character_id", "")), "stable host and guest identities differ")
	check(int(host.get("schema", 0)) == 28 and int(guest.get("schema", 0)) == 28, "current schema 28 on both peers")
	check(not str(host.get("world_disk_sha256", "")).is_empty() and not str(guest.get("character_disk_sha256", "")).is_empty(), "production durable files exist")
	var selected: Dictionary = {}
	var board_before: Dictionary = {}
	for morning in 12:
		var board_result := await step(1, "foundations_state", {"mode": "bounty_inspect"})
		check(board_result.get("verdict") == "PASS", "actual guest personal board inspection is ready")
		if board_result.get("verdict") != "PASS":
			quit(await finish())
			return
		board_before = board_result.get("data", {})
		var rows: Array = board_before.get("bounty_view", {}).get("rows", [])
		check(rows.size() == 3, "real host morning issues exactly three personal notices")
		for row: Dictionary in rows:
			if row.get("kind") == "material_delivery" and row.get("paid") != true: selected = row
		if not selected.is_empty(): break
		# Use the existing actual sleep-vote fixtures, never a synthetic clock,
		# row or completion event, to reach another real host-issued morning.
		var day_before: int = int(await probe(0, "day"))
		for peer in 2:
			if not await _pass(peer, "sleep_stand", {}): return
		for peer in 2:
			if not await _pass(peer, "sleep_press", {}): return
		for peer in 2:
			if not await _pass(peer, "wait", {"frames": 120}): return
		check(int(await probe(0, "day")) == day_before + 1, "actual two-peer sleep advances one morning")
		host = await _settled_carrier(0)
		guest = await _settled_carrier(1)
	check(not selected.is_empty(), "a real material notice appears within the bounded actual morning route")
	if selected.is_empty():
		quit(await finish())
		return
	var original_instance: String = selected.instance
	var prompt: Array = board_before.bounty_prompt
	if not await _pass(1, "teleport", {"at": [prompt[0], float(prompt[1]) - 0.9, float(prompt[2]) + 0.5]}): return
	if not await _pass(1, "wait", {"frames": 120}): return
	host = await _settled_carrier(0)
	guest = await _settled_carrier(1)
	var claim := await step(1, "foundations_state", {"mode": "bounty_claim", "instance": original_instance}, 6000)
	check(claim.get("verdict") == "PASS", "physical Halda claim reaches owner BOOL-save and accepted host ACK")
	if claim.get("verdict") != "PASS":
		quit(await finish())
		return
	var paid: Dictionary = claim.get("data", {})
	var expected_inventory := _inventory_counts(guest.get("inventory", []))
	expected_inventory[selected.item] = int(expected_inventory.get(selected.item, 0)) - int(selected.count)
	if expected_inventory[selected.item] == 0: expected_inventory.erase(selected.item)
	for reward: Dictionary in selected.rewards:
		expected_inventory[reward.id] = int(expected_inventory.get(reward.id, 0)) + int(reward.n)
	check(_inventory_counts(paid.get("inventory", [])) == expected_inventory, "exact original material debit and personal rewards, no other item delta")
	check(paid.get("inventory_disk") == paid.get("inventory"), "paid inventory is the exact owner's disk inventory")
	check(paid.get("character_disk_redesign") == paid.get("character"), "paid personal carrier is saved exactly")
	var token := "bounty:%s:%s" % [original_instance, guest_id]
	check(paid.get("character", {}).get("bounty_receipts", []).count(token) == 1 \
		and paid.get("character", {}).get("transaction_receipts", []).count(token) == 1,
		"one original personal claim receipt reaches both canonical receipt lists")
	var accepted := false
	var authority: Dictionary = await _carrier(0)
	for row: Variant in authority.get("reward_deliveries", {}).values():
		if row is Dictionary and row.get("kind") == "creature_training" and row.get("status") == "accepted" \
			and row.get("character_id") == guest_id and row.get("after", {}).get("redesign_character", {}).get("bounty_receipts", []).count(token) == 1 \
			and row.get("after", {}).get("inventory") == paid.get("inventory"): accepted = true
	check(accepted, "host accepted row binds the exact original personal receipt and paid inventory")
	check(authority.get("character") == host.get("character") and authority.get("inventory") == host.get("inventory"), "guest claim changes no host personal carrier or inventory")
	var reopen := await step(1, "foundations_state", {"mode": "bounty_inspect"})
	var paid_notice := false
	for row: Dictionary in reopen.get("data", {}).get("bounty_view", {}).get("rows", []):
		if row.get("instance") == original_instance and row.get("paid") == true: paid_notice = true
	check(paid_notice and reopen.get("data", {}).get("inventory") == paid.get("inventory"), "reopening original paid notice retains one reward with no second debit")
	guest = await _settled_carrier(1)
	if not await _pass(1, "foundations_state", {"mode": "forge_world"}): return
	var host_after_forgery := await _carrier(0)
	check(host_after_forgery.get("world", {}) == host.get("world", {}), "guest forged world never mutates host live state")
	# Content, not bytes: the host's own autosaves rewrite its world file (day,
	# clock), but the persisted redesign carrier must stay the host's -- never
	# the guest's forged `bounty_day` 999.
	var disk_world: Variant = host_after_forgery.get("world_disk_redesign")
	check(disk_world is Dictionary and disk_world == host.get("world", {})
		and float((disk_world as Dictionary).get("bounty_day", 0)) != 999.0,
		"guest world-save refusal preserves host disk world (disk diff %s)"
			% str(_diff_keys(disk_world if disk_world is Dictionary else {}, host.get("world", {}))))
	if not await _pass(1, "leave", {}): return
	if not await _pass(1, "wipe_character", {}): return
	if not await _pass(1, "foundations_state", {"mode": "clear_world"}): return
	var wiped := await _carrier(1)
	check(wiped.get("character", {}) == STATE.defaults("character"), "all personal memory erased before rejoin")
	check(wiped.get("world", {}) == STATE.defaults("world"), "guest world projection erased before rejoin")
	if not await _pass(1, "production_join", {"host": "127.0.0.1", "port": port,
			"returning_route": true, "character": {"character_id": guest_id}}, 6000): return
	for peer in 2:
		if not await _pass(peer, "expect_peers", {"count": 2}): return
	var restored := await _carrier(1)
	var retained := await _carrier(0)
	check(restored.get("character_id", "") == guest_id, "actual title rejoin keeps named portable identity")
	check(restored.get("character", {}) == guest.get("character", {}), "named-ID disk rejoin restores full personal and per-creature payload")
	check(restored.get("inventory") == guest.get("inventory") and restored.get("inventory_disk") == guest.get("inventory"), "same-ID disk rejoin retains exactly the original bounty payment")
	check(restored.get("character", {}).get("bounty_receipts", []).count(token) == 1, "same-ID rejoin cannot award the original bounty twice")
	check(restored.get("world", {}) == host.get("world", {}), "rejoin restores host-authoritative full world payload")
	check(retained.get("character", {}) == host.get("character", {}), "host personal carrier remains its own (diff %s)" % str(_diff_keys(retained.get("character", {}), host.get("character", {}))))
	print("F16 full populated two-peer storage witness; fixtures, direct title join callback, production saves/reload/ENet disclosed")
	quit(await finish())

func _inventory_counts(slots: Array) -> Dictionary:
	var counts := {}
	for slot: Variant in slots:
		if slot is Dictionary and int(slot.get("n", 0)) > 0:
			counts[str(slot.id)] = int(counts.get(str(slot.id), 0)) + int(slot.n)
	return counts

func _pass(peer: int, action: String, args: Dictionary, frames: int = 3000) -> bool:
	var result := await step(peer, action, args, frames)
	var passed := str(result.get("verdict", "")) == "PASS"
	check(passed, "peer %d %s %s: %s" % [peer, action, str(args.get("mode", "")), str(result.get("detail", ""))])
	if not passed: quit(await finish())
	return passed

## Top-level keys whose values differ (one level into `creatures`), so a
## failed equality names what moved.
func _diff_keys(a: Dictionary, b: Dictionary) -> Array:
	var out := []
	for key: Variant in a.keys() + b.keys():
		if out.has(key) or a.get(key) == b.get(key): continue
		if key == "creatures" and a.get(key) is Dictionary and b.get(key) is Dictionary:
			for uid: Variant in (a[key] as Dictionary).keys():
				var ca: Dictionary = (a[key] as Dictionary).get(uid, {})
				var cb: Dictionary = (b[key] as Dictionary).get(uid, {})
				out.append({"creature": uid, "fields": _diff_keys(ca, cb)})
			continue
		out.append({key: [a.get(key), b.get(key)]})
	return out

## Inspect until two reads 120 frames apart agree on the live carrier.
func _settled_carrier(peer: int) -> Dictionary:
	var last := await _carrier(peer)
	for _attempt in 10:
		await step(peer, "wait", {"frames": 120})
		var now := await _carrier(peer)
		if now.get("character", {}) == last.get("character", {}) and now.get("world", {}) == last.get("world", {}):
			return now
		last = now
	return last

func _carrier(peer: int) -> Dictionary:
	var result := await step(peer, "foundations_state", {"mode": "inspect"})
	check(str(result.get("verdict", "")) == "PASS", "peer %d full-carrier inspection succeeds" % peer)
	return result.get("data", {}) as Dictionary

func _populated(payload: Dictionary) -> bool:
	return _unpopulated(payload).is_empty()


## Why a carrier is not fully populated, or "" when it is. Names the first
## field that is missing or still at its default, so a failure says which.
func _unpopulated(payload: Dictionary) -> String:
	var world: Dictionary = payload.get("world", {})
	var personal: Dictionary = payload.get("character", {})
	var schema: Dictionary = DATA.json("res://data/schema/character_state.schema.json")
	var required: Array = schema.get("required", [])
	if world.size() != 8 or required.size() != 14:
		return "sizes world=%d required personal=%d" % [world.size(), required.size()]
	for key: String in world:
		if world[key] == STATE.defaults("world")[key]: return "world.%s at default" % key
	for key: String in required:
		if not personal.has(key): return "character.%s missing" % key
		if personal[key] == STATE.defaults("character")[key]: return "character.%s at default" % key
	# Any further key must be one the schema declares optional (e.g. `bounties`
	# the host's own board issues); nothing undeclared may ride along.
	for key: String in personal:
		if not required.has(key) and not (schema.get("properties", {}) as Dictionary).has(key):
			return "character.%s is not a schema field" % key
	var creatures: Dictionary = personal.get("creatures", {})
	if creatures.size() != 1: return "creatures=%d" % creatures.size()
	var creature: Dictionary = creatures.values()[0]
	var defaults := {"cap_level": 10, "breakthroughs": [], "evolution_choices": {},
		"rolled_traits": [], "taught_traits": {}, "known_moves": [],
		"loadout": {"quick": "", "charged": "", "utility": "", "ultimate": ""},
		"mastery": {}, "best": false}
	for key: String in defaults:
		if not creature.has(key) or creature[key] == defaults[key]: return "creature.%s missing or default" % key
	# The original nine fields remain populated. Require only the exact codec
	# additions used by the live loadout.
	for key: String in ["mastery_receipts", "loadout_revision", "loadout_last_edit"]:
		if not creature.has(key): return "creature.%s missing" % key
	if creature.size() != 12: return "creature has %d fields %s" % [creature.size(), str(creature.keys())]
	if (creature.mastery_receipts as Dictionary).is_empty(): return "creature.mastery_receipts empty"
	return ""
