extends "res://tests/helpers/net_harness.gd"

# peers: 2

## F33#3 / owner RD-14: Stormwood's charged ground (the glass sink) is
## host-authoritative and personal, proven across two real processes.
##
##   tools/net/run_net_smoke.sh stormwood_charged_ground
##
## Topology: both peers stand in Stormwood through the real router, the host
## first (the proven tests/smoke_net_session_host_first_realm.gd order), so the
## host's own visible StormwoodLightning node runs _tick_charged_ground over
## its local Player and the guest's remote trainer. Each tick the host alone
## publishes base hits; each receiver applies its own worn gear and the health
## floor to its own vitals (stormwood_lightning.gd _receive_charged_ground).
##
## Scenarios:
##   A  host on the Hollow Crown island (not charged), guest on the sink floor:
##      the guest loses exactly its received base hits, the host nothing.
##   B  guest wears Stormglass: the same host base hits cost it less per hit.
##   C  guest bare at 32 health: it stops at the 30% floor and is not dead.
##   D  swapped: host on the sink floor loses health; the guest, which receives
##      the host-addressed hits too, applies none of them to itself.
##
## DISCLOSED FIXTURES (peer side: tests/helpers/stormwood_charged_ground_net_peer.gd):
## the Stormwood realms smoke's retired-crossing override and replicated key /
## gate world flags; direct stand-and-pin positioning; direct health writes;
## travel gear worn directly on Game.player_equipment; and the host's ordinary
## random strike scheduler parked so a telegraphed glass-sink strike cannot add
## its own damage. The charged-ground tick, publish and receive paths are the
## shipping code, unmodified.

const PEER_SCRIPT := "res://tests/helpers/stormwood_charged_ground_net_peer.gd"
const MEADOWS := "meadows"
const STORMWOOD := "stormwood"
const STORMWOOD_KEY := "realm_key_stormwood"
const SHARED_GATE_FLAG := "realm_gate_stormwood_unlocked"
const REALM_STEP_BUDGET := 10000
const SURGE_CONFIG := "res://data/config/stormwood_surge.json"
## Sink floor (400 m from the sink centre, heightfield floor_y -65): charged.
const CHARGED_XZ := [1100.0, 2700.0]
## Hollow Crown island, north edge (230 m from centre, plateau y 74): not
## charged, and ~50 m clear of the nearest island wild cluster.
const ISLAND_XZ := [700.0, 2930.0]
const MEASURE_FRAMES := 360
const SETTLE_FRAMES := 180
const HEALTH_EPS := 0.05

var _damage := 2.0
var _floor_fraction := 0.3
var _summary: Array[String] = []


func _init_budgets() -> void:
	super._init_budgets()
	# Two realm crossings (~90 s each on a slow runner) plus four measured windows.
	_budgets["smoke_step_budget_s_2peer"] = 900.0


func _initialize() -> void:
	_run()


func _run() -> void:
	var surge: Variant = JSON.parse_string(FileAccess.get_file_as_string(SURGE_CONFIG))
	var cfg: Dictionary = (surge as Dictionary).get("charged_ground", {}) if surge is Dictionary else {}
	_damage = float(cfg.get("damage_per_tick", 2.0))
	_floor_fraction = float(cfg.get("health_floor_fraction", 0.3))
	check(_damage > 0.0 and _floor_fraction > 0.0, "charged_ground config present (damage %.2f, floor %.2f)" % [_damage, _floor_fraction])

	if not await launch(2, "world"):
		quit(await finish())
		return
	for fixture_peer in 2:
		var legacy: Dictionary = await step(fixture_peer, "legacy_physical_crossings_fixture", {"regression": "stormwood_charged_ground"})
		check(legacy.get("verdict") == "PASS", "peer %d: disclosed retired crossing fixture enabled" % fixture_peer)
		if legacy.get("verdict") != "PASS":
			quit(await finish())
			return

	var hosted: Dictionary = await step(0, "host")
	check(str(hosted.get("verdict", "")) == "PASS", "host starts the real session")
	var session: Variant = await probe(0, "session")
	var joined: Dictionary = await step(1, "join", {
		"host": "127.0.0.1",
		"port": int((session as Dictionary).get("enet_port", 0)) if session is Dictionary else 0,
	})
	check(str(joined.get("verdict", "")) == "PASS", "client joins the host session")
	for peer in 2:
		var peers: Dictionary = await step(peer, "expect_peers", {"count": 2})
		check(str(peers.get("verdict", "")) == "PASS", "peer %d sees both session members" % peer)
	for flag in [STORMWOOD_KEY, SHARED_GATE_FLAG]:
		var committed: Dictionary = await step(0, "story_flag", {"flag": flag, "scope": "world"})
		check(str(committed.get("verdict", "")) == "PASS", "host commits replicated world flag " + flag)
		for peer in 2:
			var visible: Dictionary = await step(peer, "wait_flag", {"flag": flag})
			check(str(visible.get("verdict", "")) == "PASS", "peer %d sees world flag %s" % [peer, flag])

	for peer in 2:
		var crossed: Dictionary = await step(peer, "enter_realm", {"realm": STORMWOOD}, REALM_STEP_BUDGET)
		check(str(crossed.get("verdict", "")) == "PASS",
			"peer %d enters Stormwood through Game.enter_realm (%s)" % [peer, str(crossed.get("detail", ""))])
		if str(crossed.get("verdict", "")) != "PASS":
			quit(await finish())
			return
	for peer in 2:
		var realm: Variant = await probe(peer, "realm")
		check(realm is Dictionary and str((realm as Dictionary).get("current", "")) == STORMWOOD,
			"peer %d current realm is Stormwood" % peer)

	var ticks: Dictionary = await _cstep(0, "charged_host_ticks")
	check(str(ticks.get("verdict", "")) == "PASS" and not bool(ticks.get("simulation_only", true)),
		"host runs a visible (non-shell) StormwoodLightning (%s)" % str(ticks.get("detail", "")))
	var quiet: Dictionary = await _cstep(0, "charged_quiet_strikes")
	check(str(quiet.get("verdict", "")) == "PASS", "disclosed: host random strike scheduler parked")
	for peer in 2:
		var bare: Dictionary = await _cstep(peer, "charged_wear", {"tier": ""})
		check(str(bare.get("verdict", "")) == "PASS" and absf(float(bare.get("terrain_reduction", 1.0))) < 0.001,
			"peer %d wears no terrain gear (%s)" % [peer, str(bare.get("detail", ""))])

	# ---- Scenario A: host-authoritative and personal --------------------------
	if not await _place(1, 0):
		quit(await finish())
		return
	if not await _await_host_ticking("A"):
		quit(await finish())
		return
	var a := await _measure(100.0, 100.0)
	var guest_a: Dictionary = a.guest
	var host_a: Dictionary = a.host
	var serial_span_a := int(a.serial_span)
	var hits_a := int(guest_a.get("hits_mine", 0))
	var drop_a := 100.0 - float(guest_a.get("health", 100.0))
	check(not bool(guest_a.get("in_fight", true)) and not bool(host_a.get("in_fight", true)),
		"A: neither trainer is in a fight (a fight would spare the trainer)")
	check(hits_a >= 3, "A: guest received >= 3 host charged-ground hits in %d frames (got %d, host serial +%d)"
		% [MEASURE_FRAMES, hits_a, serial_span_a])
	check(hits_a >= serial_span_a - 1 and hits_a <= serial_span_a + 1,
		"A: every host tick in the window addressed the guest (%d hits vs serial +%d)" % [hits_a, serial_span_a])
	check(absf(float(guest_a.get("damage_mine", 0.0)) - hits_a * _damage) < HEALTH_EPS,
		"A: host published the config base damage %.2f per hit" % _damage)
	check(absf(drop_a - hits_a * _damage) < HEALTH_EPS and drop_a > 0.0,
		"A: guest health dropped by received hits x damage (%.2f vs %d x %.2f)" % [drop_a, hits_a, _damage])
	check(absf(float(host_a.get("health", 0.0)) - 100.0) < HEALTH_EPS and int(host_a.get("hits_mine", -1)) == 0,
		"A: host on the island is unhurt and never addressed (health %.2f, hits %d)"
			% [float(host_a.get("health", 0.0)), int(host_a.get("hits_mine", -1))])
	check(int(host_a.get("hits_others", 0)) >= 3, "A: host decided the guest's hits locally (%d)" % int(host_a.get("hits_others", 0)))
	_summary.append("A guest -%.1f over %d hits, host -%.1f" % [drop_a, hits_a, 100.0 - float(host_a.get("health", 0.0))])

	# ---- Scenario B: the receiver's own gear ------------------------------
	var worn: Dictionary = await _cstep(1, "charged_wear", {"tier": "stormglass"})
	var reduction := float(worn.get("terrain_reduction", 0.0))
	check(str(worn.get("verdict", "")) == "PASS" and reduction > 0.0,
		"B: guest wears four Stormglass travel pieces (%s)" % str(worn.get("detail", "")))
	var b := await _measure(100.0, 100.0)
	var guest_b: Dictionary = b.guest
	var hits_b := int(guest_b.get("hits_mine", 0))
	var drop_b := 100.0 - float(guest_b.get("health", 100.0))
	check(hits_b >= 3, "B: guest received >= 3 hits (got %d)" % hits_b)
	check(absf(float(guest_b.get("damage_mine", 0.0)) - hits_b * _damage) < HEALTH_EPS,
		"B: host still publishes the bare base damage (gear is applied by the receiver)")
	var per_hit_a := drop_a / maxf(1.0, float(hits_a))
	var per_hit_b := drop_b / maxf(1.0, float(hits_b))
	check(absf(drop_b - hits_b * _damage * (1.0 - reduction)) < HEALTH_EPS,
		"B: guest drop matches hits x damage x (1 - %.2f) (%.2f over %d hits)" % [reduction, drop_b, hits_b])
	check(drop_b > 0.0 and per_hit_b < per_hit_a - 0.1,
		"B: Stormglass drop per hit is smaller than bare (%.2f < %.2f)" % [per_hit_b, per_hit_a])
	_summary.append("B stormglass -%.2f/hit vs bare -%.2f/hit" % [per_hit_b, per_hit_a])

	# ---- Scenario C: never lethal ---------------------------------------
	var unworn: Dictionary = await _cstep(1, "charged_wear", {"tier": ""})
	check(str(unworn.get("verdict", "")) == "PASS", "C: guest removes its gear")
	var c := await _measure(32.0, 100.0)
	var guest_c: Dictionary = c.guest
	var hits_c := int(guest_c.get("hits_mine", 0))
	var floor_hp := float(guest_c.get("max_health", 100.0)) * _floor_fraction
	check(hits_c >= 3 and 32.0 - hits_c * _damage < floor_hp,
		"C: bare hits received would pass the floor (%d hits x %.2f from 32)" % [hits_c, _damage])
	check(absf(float(guest_c.get("health", 0.0)) - floor_hp) < HEALTH_EPS,
		"C: guest health stops at the %.0f%% floor (%.2f vs %.2f)" % [_floor_fraction * 100.0, float(guest_c.get("health", 0.0)), floor_hp])
	check(not bool(guest_c.get("dead", true)), "C: guest is not dead")
	_summary.append("C 32 -> %.2f (floor %.2f) after %d hits" % [float(guest_c.get("health", 0.0)), floor_hp, hits_c])

	# ---- Scenario D: swapped, the host is hit by its own decision ------------
	if not await _place(0, 1):
		quit(await finish())
		return
	var d := await _measure(100.0, 100.0)
	var guest_d: Dictionary = d.guest
	var host_d: Dictionary = d.host
	var hits_d := int(host_d.get("hits_mine", 0))
	var drop_d := 100.0 - float(host_d.get("health", 100.0))
	check(hits_d >= 3, "D: host addressed itself >= 3 hits (got %d, serial +%d)" % [hits_d, int(d.serial_span)])
	check(absf(drop_d - hits_d * _damage) < HEALTH_EPS and drop_d > 0.0,
		"D: host health dropped by its own hits x damage (%.2f vs %d x %.2f)" % [drop_d, hits_d, _damage])
	check(absf(float(guest_d.get("health", 0.0)) - 100.0) < HEALTH_EPS and int(guest_d.get("hits_mine", -1)) == 0,
		"D: guest on the island is unhurt and never addressed (health %.2f, hits %d)"
			% [float(guest_d.get("health", 0.0)), int(guest_d.get("hits_mine", -1))])
	check(int(guest_d.get("hits_others", 0)) >= 3,
		"D: guest received the host-addressed hits (%d) and applied none to itself" % int(guest_d.get("hits_others", 0)))
	_summary.append("D host -%.1f over %d hits, guest -%.1f" % [drop_d, hits_d, 100.0 - float(guest_d.get("health", 0.0))])

	for peer in 2:
		await _cstep(peer, "charged_release")
	print("SMOKE stormwood_charged_ground: %s | %s" % [
		"PASS" if failures.is_empty() else "FAIL (%d)" % failures.size(), "; ".join(_summary)])
	quit(await finish())


## Stand `charged_peer` on the sink floor and `island_peer` on the island,
## assert what shipping rules call each spot, then let replication settle.
func _place(charged_peer: int, island_peer: int) -> bool:
	var on_charged: Dictionary = await _cstep(charged_peer, "charged_stand", {"x": CHARGED_XZ[0], "z": CHARGED_XZ[1]})
	check(str(on_charged.get("verdict", "")) == "PASS" and bool(on_charged.get("charged", false))
		and bool(on_charged.get("contact", false)),
		"peer %d stands in contact with charged ground (%s)" % [charged_peer, str(on_charged.get("detail", ""))])
	var on_island: Dictionary = await _cstep(island_peer, "charged_stand", {"x": ISLAND_XZ[0], "z": ISLAND_XZ[1]})
	check(str(on_island.get("verdict", "")) == "PASS" and not bool(on_island.get("charged", true)),
		"peer %d stands on the island, not charged ground (%s)" % [island_peer, str(on_island.get("detail", ""))])
	# Let the host's view of the guest's trainer catch up with both moves, so
	# no tick in the next window is decided from a stale replicated position.
	await step(0, "wait", {"frames": SETTLE_FRAMES})
	return bool(on_charged.get("charged", false)) and not bool(on_island.get("charged", true))


## The host's tick only advances its serial when somebody is hit. Wait (with
## a bound) for the first one, so the measured windows start from a live tick.
func _await_host_ticking(label: String) -> bool:
	var first: Dictionary = await _cstep(0, "charged_host_ticks")
	var start := int(first.get("serial", 0))
	for i in 30:
		await step(0, "wait", {"frames": 60})
		var now: Dictionary = await _cstep(0, "charged_host_ticks")
		if int(now.get("serial", 0)) > start:
			check(true, "%s: host charged-ground tick is live (serial %d -> %d)" % [label, start, int(now.get("serial", 0))])
			return true
	check(false, "%s: host charged-ground serial never advanced in 30 s (stuck at %d)" % [label, start])
	return false


## Reset both peers' health (and their received-hit counters, in the same
## frame), wait MEASURE_FRAMES, then read both peers and the host's serial.
func _measure(guest_health: float, host_health: float) -> Dictionary:
	await _cstep(1, "charged_set_health", {"value": guest_health})
	await _cstep(0, "charged_set_health", {"value": host_health})
	var before: Dictionary = await _cstep(0, "charged_host_ticks")
	await step(1, "wait", {"frames": MEASURE_FRAMES})
	var after: Dictionary = await _cstep(0, "charged_host_ticks")
	var guest: Dictionary = await _cstep(1, "charged_health")
	var host: Dictionary = await _cstep(0, "charged_health")
	print("charged window: guest %s | host %s" % [str(guest.get("detail", "")), str(host.get("detail", ""))])
	return {"guest": guest, "host": host,
		"serial_span": int(after.get("serial", 0)) - int(before.get("serial", 0))}


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



## A charged_* step's values arrive under data; flatten them for the checks.
func _cstep(peer: int, action: String, args := {}, budget: int = -1) -> Dictionary:
	var result: Dictionary = await step(peer, action, args, budget)
	var flat := result.duplicate(true)
	if result.get("data") is Dictionary:
		flat.merge(result.data, true)
	return flat
