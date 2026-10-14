extends "res://tests/helpers/net_harness.gd"

# peers: 2
# net-timeout-seconds: 1620
## F48#0: a two-peer session runs hub -> homestead crafting -> portal ->
## Master -> feast -> boss -> relic hang, with each player's receipts separate.
##
##   tools/net/run_net_smoke.sh f48_coop_loop
##
## Two real ENet processes, two saved characters, one host world. Each leg is
## the step an existing passing net smoke already plays, here in one session:
##   hub     each player's Satchel Home Key to the Crossing Hall (f49_portal_travel)
##   craft   the host plants a Kitchen + Spice rack by the paid build press; the
##           guest crafts a Small Potion there (smoke_net_homestead_station_craft)
##   portal  host then guest cross the Hall's Meadows biome arch (id home) by its prompt
##   Master  each challenges Orin Stonewake with its chosen creature, wins, and
##           opens the chest for its own recipe (smoke_net_f28_masters)
##   feast   each cooks that recipe at the host's Kitchen and feeds its own
##           ground creature (smoke_net_f28_feast)
##   boss    both fight the Warden; each gets its own key and relic
##           (smoke_net_veridian_relic_key)
##   hang    each Home Keys to the Hall and hangs its own Meadows relic on the
##           Shrine Room pedestal (f49_portal_travel.hang_relic, chooser deferred)
## After each leg: every player's new receipts are its own and paid once, and
## the host's admitted record of the guest agrees. At the end the host saves
## and reloads, the guest leaves and rejoins as its saved character, and
## nothing is duplicated or lost.
## Disclosed fixtures (all before the first admission, as the leg smokes do):
## both peers boot straight into the world; party_grant seeds each home with a
## Lv 10 Terrapup (the feast target at cap 10) and a Lv 40 Bramblebun (the
## Master duellist); seed_opening_complete marks the opening played;
## f28_feast_seed gives each one cook's ingredients (berries 4, rootstone 2,
## attuned_ground 1), the guest the potion's (berries 4, fiber 1) and each
## one Home Key, no recipe (craft_home_key_trip then sets home_key_given). During the run: Kitchen
## Master and feast stances (craft_place_kitchen, f28_stand) and the Warden arena
## (explore_at) are fixture teleports, as in the leg smokes; the Warden fight
## uses win_trainer_battle's enemy_hp_ceiling as smoke_net_veridian_relic_key.
## Peer: tests/helpers/f48_coop_loop_net_peer.gd.
const PEER_SCRIPT := "res://tests/helpers/f48_coop_loop_net_peer.gd"
const MASTER := "master_t1"
const DUELLIST := "bramblebun"
const RECIPE := "Ascension Feast 1 (ground)"
const WARDEN := "warden_aldis"
const BATTLE_FRAMES := 5400
const ENEMY_HP_CEILING := 6.0
const SETTLE := 240

var _ids: Array[String] = ["", ""]
var _port := 0
var _completed := false
var _evidence: Dictionary = {"legs": {}}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	heartbeat_silence_tolerance_s = 240.0
	require_peer_logs_without(["SCRIPT ERROR", "Parse Error", "Invalid call"], "F48 loop peer logs have no script errors")
	if await launch(2, "title"):
		# The seven legs together: the Master smoke's 2400 s, or a longer
		# configured two-peer step budget on a slower host.
		_step_phase_deadline_ms = Time.get_ticks_msec() + maxf(2400.0, float(_budgets.get("smoke_step_budget_s_2peer", 0.0))) * 1000.0
		if await _setup():
			await _loop()
	check(_completed, "the F48 co-op loop ran to its end")
	_write_evidence()
	quit(await finish())


func _setup() -> bool:
	for peer in 2:
		if not await _pass(peer, "boot", {"scene": "world"}, 30000): return false
		if not await _pass(peer, "party_grant", {"species": "terrapup", "level": 10, "nickname": "Pup"}): return false
		if not await _pass(peer, "party_grant", {"species": DUELLIST, "level": 40}): return false
		if not await _pass(peer, "seed_opening_complete", {}): return false
		var items := {"home_key": 1, "berries": 4, "rootstone": 2, "attuned_ground": 1}
		if peer == 1: items = {"home_key": 1, "berries": 8, "fiber": 1, "rootstone": 2, "attuned_ground": 1}
		if not await _pass(peer, "f28_feast_seed", {"recipes": _initial_feast_recipes(), "items": items}): return false
		var saved: Dictionary = await step(peer, "save_character_here", {})
		if not _ok(saved, "peer %d saved its seeded character" % peer): return false
		_ids[peer] = str((saved.get("data", {}) as Dictionary).get("character_id", ""))
	check(not _ids[0].is_empty() and _ids[0] != _ids[1], "two distinct stable characters %s" % str(_ids))
	if not await _pass(0, "host", {}): return false
	_port = int(((await probe(0, "session")) as Dictionary).get("enet_port", 0))
	if not await _pass(1, "join", {"host": "127.0.0.1", "port": _port,
			"character": {"character_id": _ids[1], "display_name": "Loop Guest"}}, 6000): return false
	for peer in 2:
		if not await _pass(peer, "expect_peers", {"count": 2}): return false
	for peer in 2:
		if not await _pass(peer, "f27_dismiss_modals", {}): return false
	return true


func _loop() -> void:
	var start := await _both("start")
	for peer in 2:
		check(int(start[peer].items.home_key) == 1 and start[peer].feast_recipes.is_empty() and start[peer].relics_held.is_empty() and start[peer].relics_hung.is_empty()
			and int(start[peer].items.tidewake_portal_key) == 0, "peer %d starts with no recipe, relic or key" % peer)

	# 1. Hub: each player's own Home Key trip to the Crossing Hall.
	for peer in 2:
		var trip := await _data(peer, "craft_home_key_trip", {}, 12000)
		if trip.is_empty() or bool(trip.get("skipped", false)): return
		check(str(trip.get("realm", "")) == "meadows", "hub: peer %d arrived at the Crossing Hall" % peer)
	var hub := await _both("hub")
	_leg("hub", start, hub)

	# 2. Homestead crafting: the guest crafts at the host's Kitchen and keeps it.
	var placed := await _data(0, "craft_place_kitchen", {}, 3000)
	if placed.is_empty(): return
	var kitchen := str(placed.kitchen_uid)
	var crafted := await _data(1, "craft_at_host_kitchen", {"kitchen_uid": kitchen}, 3000)
	if crafted.is_empty(): return
	var craft := await _both("craft")
	check(int(craft[1].items.potion_small) == int(hub[1].items.potion_small) + 1
		and int(craft[1].items.berries) == int(hub[1].items.berries) - 4 and int(craft[1].items.fiber) == int(hub[1].items.fiber) - 1,
		"craft: the guest paid berries 4 + fiber 1 and keeps one Small Potion (%s)" % str(craft[1].items))
	check(int(craft[0].items.potion_small) == int(hub[0].items.potion_small) and craft[0].items.berries == hub[0].items.berries,
		"craft: the host's own stock is untouched by the guest's craft (%s)" % str(craft[0].items))
	_leg("craft", hub, craft, "station craft", _station_craft, [1])

	# 3. Portal: host first, then guest, each Home Keys to the Crossing Hall and
	# crosses its Meadows biome arch (portals.json id "home", biome meadows)
	# into the Master's biome.
	var arch_biome := ""
	for row: Dictionary in JSON.parse_string(FileAccess.get_file_as_string("res://data/config/portals.json")).arches:
		if row.id == "home": arch_biome = str(row.biome)
	check(arch_biome == str(preload("res://scripts/creatures/breakthrough.gd").master(MASTER).biome),
		"portal: the crossed arch leads to the Master's biome (%s)" % arch_biome)
	for peer in 2:
		if not await _pass(peer, "loop_home_key", {}, 12000): return
		var through := await _data(peer, "loop_arch_enter", {"arch": "home", "realm": "meadows"}, 12000)
		if through.is_empty(): return
		check(str(through.reply.get("character_id", _ids[peer])) == _ids[peer],
			"portal: peer %d's home arch arrival is its own (%s)" % [peer, str(through.reply)])
	var portal := await _both("portal")
	_leg("portal", craft, portal)
	for peer in 2:
		var arrivals := (portal[peer].receipts as Array).filter(func(r: Variant) -> bool:
			return str(r).begins_with("craft:portal_arrival_travel:") and not (craft[peer].receipts as Array).has(r))
		check(arrivals.size() == 2, "portal: peer %d's own two arrivals (Home Key, arch) were journaled once each (%s)" % [peer, str(arrivals)])

	# 4. Master: each wins its own duel and opens the chest for its own recipe.
	var definition: Dictionary = preload("res://scripts/creatures/breakthrough.gd").master(MASTER)
	var at: Array = definition.position
	for peer in 2:
		if not await _pass(peer, "f28_stand", {"at": [float(at[0]) + 6.0, float(at[2]) + 6.0], "settle": 90}): return
	var site: Dictionary = {}
	for attempt in 30:
		site = await step(0, "f28_site", {"master_id": MASTER})
		if str(site.get("verdict", "")) == "PASS": break
		await step(0, "wait", {"frames": 30})
	if not _ok(site, "host mounted %s" % MASTER): return
	var npc: Array = site.data.master
	var chest: Array = site.data.chest
	for peer in 2:
		if not await _pass(peer, "f27_dismiss_modals", {}): return
		if not await _pass(peer, "f28_stand", {"at": [float(npc[0]) + 2.0, float(npc[2]) + 1.0]}): return
		if not await _pass(peer, "f28_challenge", {"master_id": MASTER, "species": DUELLIST}, 2400): return
		var args := {"budget_frames": 6000}
		if peer == 1: args = {"budget_frames": 6000, "fixture_guest_master": true, "self_hp_topups": false}
		if not await _pass(peer, "win_trainer_battle", args, 6400): return
		await step(peer, "wait", {"frames": SETTLE})
		for poll in 60:
			if ((await _view(peer)).master_wins as Array).has(MASTER): break
			await step(peer, "wait", {"frames": 60})
	for peer in 2:
		if not await _pass(peer, "f27_dismiss_modals", {}): return
		if not await _pass(peer, "move_to", {"x": float(chest[0]) + 2.0, "z": float(chest[2]) + 1.0,
				"close_enough": 1.5, "budget_frames": 1800}, 2200): return
		# A guest's first press can be refused while its duel's owner
		# checkpoints settle (open F28#4 gap); a player presses again.
		for press in 3:
			await _pass(peer, "f28_chest", {"master_id": MASTER, "budget_frames": 3600}, 4000)
			for poll in 20:
				if int((await _view(peer)).feast_recipes.count("feast_t1")) >= 1: break
				await step(peer, "wait", {"frames": 60})
			if int((await _view(peer)).feast_recipes.count("feast_t1")) >= 1: break
	var master := await _both("master")
	for peer in 2:
		check(master[peer].master_wins.count(MASTER) == 1 and master[peer].feast_recipes.count("feast_t1") == 1,
			"Master: peer %d holds one %s win and the feast_t1 recipe once (%s, %s)" % [peer, MASTER, str(master[peer].master_wins), str(master[peer].feast_recipes)])
	_leg("master", portal, master, "Master win", func(r: String, id: String) -> bool: return r.begins_with("master_recipe:%s:%s:win" % [MASTER, id]))
	_leg("master", portal, master, "Master recipe", func(r: String, id: String) -> bool: return r == "master_recipe:%s:%s" % [MASTER, id])

	var feast := await _feast_leg(kitchen, master)
	if feast.is_empty(): return

	# 6. Boss: both fight the Warden; each participant gets its own key and relic.
	for peer in 2:
		await step(peer, "f27_dismiss_modals", {})
		await step(peer, "deploy_creature", {})
	var hold: Variant = await probe(0, "stronghold")
	var markers: Dictionary = (hold as Dictionary).get("markers", {}) as Dictionary if hold is Dictionary else {}
	var arena: Array = markers.get("warden_arena", []) as Array
	check(arena.size() == 3, "the Hall names its Warden arena (%s)" % str(arena))
	if arena.size() != 3: return
	for peer in 2:
		await step(peer, "explore_at", {"at": [float(arena[0]) + (2.0 if peer == 1 else -2.0), float(arena[2]), float(arena[1])], "settle": 60})
	if not await _pass(0, "trainer_battle", {"trainer": WARDEN, "settle": 45}): return
	var record: Variant = await probe(0, "encounter")
	var encounter_id := str((record as Dictionary).get("id", "")) if record is Dictionary else ""
	if not await _pass(1, "join_encounter", {"encounter_id": encounter_id}): return
	if not await _pass(0, "win_trainer_battle", {"budget_frames": BATTLE_FRAMES, "enemy_hp_ceiling": ENEMY_HP_CEILING,
			"self_hp_topups": false}, BATTLE_FRAMES + 900): return
	for peer in 2:
		await step(peer, "wait", {"frames": 120})
		await step(peer, "dismiss_dialogue", {"presses": 40, "settle": 30})
	var boss: Array = []
	for poll in 60:
		boss = await _both("boss")
		if int(boss[0].items.tidewake_portal_key) == 1 and int(boss[1].items.tidewake_portal_key) == 1 \
				and boss[0].relics_held.has("meadows") and boss[1].relics_held.has("meadows"): break
		await step(0, "wait", {"frames": 30})
	for peer in 2:
		check(int(boss[peer].items.tidewake_portal_key) == 1 and boss[peer].relics_held.count("meadows") == 1,
			"boss: peer %d holds its own Tidewake key (x%d) and Meadows relic once (%s)" % [peer, int(boss[peer].items.tidewake_portal_key), str(boss[peer].relics_held)])
	_leg("boss", feast, boss)

	# 7. Relic hang: each Home Keys to the Hall and hangs its own relic.
	for peer in 2:
		await step(peer, "f27_dismiss_modals", {})
		if not await _pass(peer, "loop_home_key", {}, 12000): return
		if not await _pass(peer, "loop_hang_relic", {"biome": "meadows"}, 12000): return
		await step(peer, "wait", {"frames": SETTLE})
	var hung := await _both("hang")
	for peer in 2:
		check(hung[peer].relics_hung.count("meadows") == 1 and hung[peer].receipts.count("relic_hang:meadows:" + _ids[peer]) == 1,
			"hang: peer %d hung its own Meadows relic once (%s)" % [peer, str(hung[peer].relics_hung)])
		check(not hung[peer].receipts.has("relic_hang:meadows:" + _ids[1 - peer]),
			"hang: peer %d's record holds no receipt of the other player's hang" % peer)
	_leg("hang", boss, hung, "relic hang", func(r: String, id: String) -> bool: return r == "relic_hang:meadows:" + id)

	# 8. One save and reload: the host saves and reloads its world; the guest
	# leaves and rejoins as its saved character. Nothing duplicates or vanishes.
	if not await _pass(1, "save_character_here", {}): return
	if not await _pass(0, "save_reload_here", {}, 8000): return
	if not await _pass(1, "leave", {"reason": "player_left"}): return
	if not await _pass(0, "expect_peers", {"count": 1}, 900): return
	if not await _pass(1, "production_join", {"host": "127.0.0.1", "port": _port, "budget_frames": 14000,
			"returning_route": true, "character": {"character_id": _ids[1]}}, 15000): return
	if not await _pass(0, "expect_peers", {"count": 2}, 900): return
	for peer in 2:
		await step(peer, "wait", {"frames": SETTLE})
		await step(peer, "dismiss_dialogue", {"presses": 16, "settle": 30})
	var reloaded := await _both("reloaded")
	for peer in 2:
		for key: String in ["items", "caps", "master_wins", "feast_recipes", "relics_held", "relics_hung", "receipts"]:
			check(str(reloaded[peer].get(key)) == str(hung[peer].get(key)),
				"reload: peer %d's %s unchanged (%s vs %s)" % [peer, key, str(reloaded[peer].get(key)), str(hung[peer].get(key))])
	_completed = true
	print("F48_COOP_LOOP: hub, craft, portal, Master, feast, boss and relic hang across two peers; receipts separate; one save/reload")


## Each player's own record and the host's admitted record of the guest, which
## must agree with the guest's own.
func _both(label: String) -> Array:
	var host := await _data(0, "loop_receipts", {})
	var guest := await _data(1, "loop_receipts", {})
	var admitted := {}
	for poll in 20:
		admitted = await _data(0, "loop_receipts", {"character_id": _ids[1]})
		if str(admitted.get("receipts")) == str(guest.get("receipts")) and str(admitted.get("items")) == str(guest.get("items")): break
		await step(0, "wait", {"frames": 60})
		guest = await _data(1, "loop_receipts", {})
	check(str(host.get("character_id")) == _ids[0] and str(guest.get("character_id")) == _ids[1], "%s: each record is its own player's" % label)
	for key: String in ["items", "caps", "feast_recipes", "relics_held", "relics_hung", "receipts"]:
		check(str(admitted.get(key)) == str(guest.get(key)),
			"%s: the host's admitted record of the guest agrees on %s (%s vs %s)" % [label, key, str(admitted.get(key)), str(guest.get(key))])
	for side: Dictionary in [host, guest]:
		var receipts: Array = side.get("receipts", [])
		var once := {}
		for r: Variant in receipts: once[str(r)] = true
		check(once.size() == receipts.size(), "%s: %s's receipts hold no duplicate" % [label, str(side.get("character_id"))])
	_evidence.legs[label] = {"host": host, "guest": guest, "host_admitted_guest": admitted}
	return [host, guest]


## A leg's new receipts: each names its own player (its character, or one of
## its own creatures) and never the other player or theirs, and
## is in that player's record only; with `matches`, exactly one new receipt of
## that kind for each player in `payers` (none for the others).
func _leg(label: String, before: Array, after: Array, kind: String = "", matches: Callable = Callable(), payers: Array = [0, 1]) -> void:
	var fresh: Array = []
	for peer in 2:
		var added: Array = (after[peer].receipts as Array).filter(func(r: Variant) -> bool: return not (before[peer].receipts as Array).has(r))
		fresh.append(added)
		print("F48 LOOP %s: peer %d new receipts %s" % [label, peer, str(added)])
		var own: Array = [_ids[peer]] + (after[peer].caps as Dictionary).keys()
		var theirs: Array = [_ids[1 - peer]] + (after[1 - peer].caps as Dictionary).keys()
		for r: Variant in added:
			check(own.any(func(id: Variant) -> bool: return str(r).contains(str(id)))
				and not theirs.any(func(id: Variant) -> bool: return str(r).contains(str(id))),
				"%s: peer %d's new receipt names its own character or creature only (%s)" % [label, peer, str(r)])
		if matches.is_valid():
			var hits := added.filter(func(r: Variant) -> bool: return matches.call(str(r), _ids[peer]))
			var want := 1 if payers.has(peer) else 0
			check(hits.size() == want, "%s: peer %d gained %d new %s receipt(s), wanted %d (%s)" % [label, peer, hits.size(), kind, want, str(hits)])
	for r: Variant in fresh[0]:
		check(not (after[1].receipts as Array).has(r), "%s: the host's new receipt %s is not in the guest's record" % [label, str(r)])
	for r: Variant in fresh[1]:
		check(not (after[0].receipts as Array).has(r), "%s: the guest's new receipt %s is not in the host's record" % [label, str(r)])


## A station craft's receipt (the Kitchen's potion or feast): craft:<crafter>:<craft id>,
## not the host's paid build placements (craft:<owner>:homestead_build:...).
func _station_craft(r: String, id: String) -> bool:
	return r.begins_with("craft:%s:" % id) and r.trim_prefix("craft:%s:" % id).is_valid_hex_number()


## One feast panel press, pressed again (as a player would, twice at most)
## when the host refused it because the record moved under the open panel.
func _feast_press(peer: int, action: String, kitchen: String, button: String) -> Dictionary:
	var out := {}
	for attempt in 3:
		out = await _data(peer, action, {"kitchen_uid": kitchen, "button": button}, 2400)
		print("F48 LOOP %s peer %d attempt %d: %s" % [action, peer, attempt, JSON.stringify(out)])
		var moved := false
		for answer: Variant in out.get("completed", []):
			if answer is Dictionary and answer.get("code") == "source_or_revision_changed": moved = true
		if not moved: break
		await step(peer, "wait", {"frames": 120})
	return out


func _view(peer: int) -> Dictionary:
	return await _data(peer, "loop_receipts", {})


func _data(peer: int, action: String, args: Dictionary, budget: int = 1800) -> Dictionary:
	var result := await step(peer, action, args, budget)
	if not _ok(result, "peer %d %s %s" % [peer, action, JSON.stringify(result.get("data", {})).left(600)]): return {}
	return result.get("data", {})


func _pass(peer: int, action: String, args: Dictionary, budget: int = -1) -> bool:
	return _ok(await step(peer, action, args, budget), "peer %d %s" % [peer, action])


func _ok(result: Dictionary, label: String) -> bool:
	var passed := str(result.get("verdict", "")) == "PASS"
	check(passed, "%s: %s" % [label, str(result.get("detail", ""))])
	return passed


func _write_evidence() -> void:
	if _run_dir.is_empty(): return
	_evidence["failures"] = failures.duplicate()
	var file := FileAccess.open(_run_dir.path_join("F48_COOP_LOOP.json"), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(_evidence, "\t"))
		file.close()


func _spawn_peer(i: int, role: String, control_port: int, enet_port: int, scene: String,
		home: String, log_path: String, extra_args: Array) -> int:
	var args := ["--headless", "--path", ProjectSettings.globalize_path("res://")]
	if _is_windows():
		args.append_array(["--log-file", log_path])
	args.append_array(["--script", PEER_SCRIPT, "--", "--role=" + role, "--peer=%d" % i,
		"--control-port=%d" % control_port, "--enet-port=%d" % enet_port, "--scene=" + scene,
		"TB_NET_RUN_ID=" + _run_id])
	for extra: Variant in extra_args:
		args.append(str(extra))
	OS.set_environment("XDG_DATA_HOME", home)
	if _is_windows():
		OS.set_environment("APPDATA", home)
	OS.set_environment("TB_NET_RUN_ID", _run_id)
	OS.set_environment("TB_WORLD_SEED", OS.get_environment("TB_NET_WORLD_SEED") if not OS.get_environment("TB_NET_WORLD_SEED").is_empty() else "0")
	if _is_windows():
		return OS.create_process(OS.get_executable_path(), args)
	var parts: Array[String] = [_shq(OS.get_executable_path())]
	for arg: Variant in args:
		parts.append(_shq(str(arg)))
	return OS.create_process("/bin/sh", ["-c", "exec %s >%s 2>&1" % [" ".join(parts), _shq(log_path)]])


func _feast_leg(kitchen: String, master: Array) -> Array:
	# 5. Feast: each cooks at the host's Kitchen and feeds its own Terrapup.
	var station := await _data(1, "f28_station_at", {"kitchen_uid": kitchen}, 1200)
	if station.is_empty(): return []
	for peer in 2:
		if not await _pass(peer, "f27_dismiss_modals", {}): return []
		# The Kitchen stance craft_at_host_kitchen uses (a disclosed fixture
		# teleport): an ordinary walk from the Master stalls against the
		# Spice rack outside the station's interaction radius.
		if not await _pass(peer, "f28_stand", {"at": [float(station.at[0]) + 1.6, float(station.at[2]) + 1.6], "settle": 120}): return []
		var cooked := await _feast_press(peer, "f28_cook", kitchen, RECIPE)
		check(cooked.get("pressed") == true, "feast: peer %d's Kitchen panel offers %s (%s)" % [peer, RECIPE, str(cooked.get("labels", []))])
		await step(peer, "f27_dismiss_modals", {})
		var fed := await _feast_press(peer, "f28_feed", kitchen, "Pup · ")
		check(fed.get("pressed") == true, "feast: peer %d fed its own Pup (%s)" % [peer, str(fed.get("message", ""))])
		await step(peer, "wait", {"frames": SETTLE})
	var feast := await _both("feast")
	for peer in 2:
		var pup := await _data(peer, "f28_feast_view", {})
		var spent := {}
		for id: String in ["berries", "rootstone", "attuned_ground", "feast_t1_ground"]:
			spent[id] = int(master[peer].items[id]) - int(feast[peer].items[id])
		check(spent == {"berries": 4, "rootstone": 2, "attuned_ground": 1, "feast_t1_ground": 0}
			and int(pup.get("party", {}).get("terrapup", {}).get("cap_level", -1)) == 20,
			"feast: peer %d spent one cook's cost, fed the feast, and its Pup's cap is 20 (spent %s; %s)" % [peer, str(spent), str(pup.get("party", {}).get("terrapup"))])
	_leg("feast", master, feast, "feast cook", _station_craft)
	_leg("feast", master, feast, "feast feed", func(r: String, _id: String) -> bool: return r.begins_with("feast_feed:"))

	return feast


func _initial_feast_recipes() -> Array:
	return []
