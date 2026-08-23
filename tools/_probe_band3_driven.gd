extends SceneTree

## GATE-D3. Walk Band 3 (the River / Tether Relay) with a real body and record
## what a player actually meets on the way.
##
##   godot --headless --path . --script tools/_probe_band3_driven.gd
##   godot --headless --path . --script tools/_probe_band3_driven.gd -- --reach=25
##
## WHY THIS EXISTS.
##
## The previous D3 round measured this region's cadence ANALYTICALLY: it read
## `data/config/bands/band3_the_river_lock/*.json`, projected every entry onto
## the authored spine and computed gaps between z values. That is arithmetic
## over a config file. It cannot see a cluster that authored fine and then
## spawned nowhere, a harvest node the scatter buried, a prop cluster that
## built on a slope the player never walks past, or a stretch that reads dead
## because the road bends away from content sitting 30m off it. `ralph/lanes/
## COMMON.md` §10.3 asks every lane for "a real driven run through your region,
## not only unit tests", and this is Band 3's.
##
## So this boots the world, drives the REAL `Player` through the REAL
## `player_controller.gd` along Band 3's own reach of the authored spine, and
## every frame asks what is standing near the body -- live wild creature
## bodies from `EncounterDirector`, `Trainers` children, nodes in the
## `harvestable` group, and `Props` cluster nodes -- rather than what a JSON
## file says should be.
##
## The driving loop is `tools/_probe_ow5_walk.gd`'s, deliberately: it is the
## probe that established steering the real body by writing `CameraRig.yaw`
## while holding `move_forward`, and its header explains why a bespoke
## CharacterBody3D walks out of Terrain3D's camera-anchored collision bubble
## and falls through a world that is fine. This does not re-derive any of that.
## What it does not inherit is the wedge-escape machinery: a walk that gets
## stuck here is a finding for D3 to report, not a corridor-length measurement
## to rescue, so a stall is named and stepped over.
##
## Headless on purpose. Nothing here renders; the visual pass is a separate
## tool and a separate critic (`ralph/conventions.md`).
##
## Read the printed summary, not the exit code: Terrain3D aborts on shutdown
## by design (D06).

const SCENE := "res://scenes/world/meadows_playground.tscn"
const CONFIG := "res://data/config/terrain_playground.json"
const MOVEMENT := "res://data/config/movement.json"
const HARVEST_LOGIC := preload("res://scripts/world/harvest_logic.gd")

## Band 3's reach of the corridor, from `ralph/GATE_D_LANE_CONTRACT.md` §1.
const Z_FROM := 3180.0
const Z_TO := 4760.0

## Long enough for the world's deferred build passes (village, warrens, relay,
## scatter, the 155-creature spawn) to finish before anything is measured.
## `_probe_ow5_walk.gd` and `smoke_traversal.gd` both settle 240.
const SETTLE_FRAMES := 240
const RESETTLE_FRAMES := 90

## How close counts as arriving at a spine waypoint. Two metres is inside the
## capsule's own turning behaviour and far under the authored point spacing.
const ARRIVE_M := 2.0

## What counts as "the player meets this". 35m is the reach the previous
## analytical round used, kept so the two numbers are comparable -- and it is
## roughly where a creature body stops being scenery and starts being a thing
## you decide about. `--reach=` overrides it.
var _reach := 35.0

## A stretch of walking with nothing inside `_reach` longer than this is worth
## naming individually rather than only counting.
const DEAD_TRAVEL_REPORT_M := 60.0

## Wedge detection, same shape as the OW5 walk: a body that has gained less
## than this toward its target across this many frames is not walking.
const WEDGE_WINDOW := 90
const WEDGE_PROGRESS_M := 1.5
## A single physics tick longer than this is the world moving the body
## (`river.gd`'s CarveFailsafe chain), not a stride. Never counted as walked.
const TELEPORT_STEP_M := 2.0
const THROUGH_THE_FLOOR := -80.0

var _walk_speed_cfg := 5.0
var _world: Node = null
var _director: Node = null
var _player: CharacterBody3D = null
var _rig: Node3D = null

## Every point of interest standing in the band when the walk starts:
## {kind, id, pos}. Built from the live scene, never from the config.
var _interest: Array = []
## Ids already met, so one creature standing next to the road is one meeting
## and not four hundred frames of them.
var _met := {}
## Ordered log of meetings: {kind, id, at_m, pos}.
var _events: Array = []
## Dead stretches longer than DEAD_TRAVEL_REPORT_M: {from_m, to_m, len, pos}.
var _dead: Array = []
## Filled by `_drive`, read by `_report`.
var _walk := {}
## Wild bodies inside the band at boot. Counted, never snapshotted -- see
## `_collect_interest`.
var _wild_standing := 0
## Closest the driven body ever got to each wild creature, keyed by instance
## id. "11 of 155 met" is a number that can mean the region is empty near the
## road or that the probe is broken, and those need telling apart: a
## distribution of closest approaches says which. Cheap to keep -- it is the
## distance the reach check already computes.
var _wild_closest := {}


func _init() -> void:
	_run()


func _parse_args() -> void:
	for a in OS.get_cmdline_user_args():
		var parts := a.split("=", true, 1)
		var key := parts[0].lstrip("-")
		var val := parts[1] if parts.size() > 1 else ""
		match key:
			"reach": _reach = float(val)


func _load_json(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	return parsed if parsed is Dictionary else {}


## The authored spine clipped to Band 3, shared band joins dropped.
func _spine_points() -> Array[Vector2]:
	var cfg := _load_json(CONFIG)
	var trail: Dictionary = cfg.get("trail", {})
	var out: Array[Vector2] = []
	for band in trail.get("bands", []):
		for p in band.get("points", []):
			var v := Vector2(float(p[0]), float(p[1]))
			if v.y < Z_FROM or v.y > Z_TO:
				continue
			if out.is_empty() or out[out.size() - 1].distance_to(v) > 0.01:
				out.append(v)
	return out


func _run() -> void:
	_parse_args()
	var move_cfg := _load_json(MOVEMENT)
	_walk_speed_cfg = float((move_cfg.get("locomotion", {}) as Dictionary).get("walk_speed", 5.0))

	print("=== GATE-D3 driven run: Band 3, the River / Tether Relay ===")
	print("z %.0f -> %.0f   reach %.0fm   walk_speed(cfg) %.2f m/s" % [
		Z_FROM, Z_TO, _reach, _walk_speed_cfg])

	var boot_start := Time.get_ticks_msec()
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame
	print("world booted and settled in %.1fs" % ((Time.get_ticks_msec() - boot_start) / 1000.0))

	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	_director = _world.get_node_or_null(^"EncounterDirector")
	if _player == null or _rig == null or _director == null:
		print("PROBE FAIL: scene is missing Player, CameraRig or EncounterDirector")
		quit(1)
		return

	_collect_interest()
	_report_objectives()

	var points := _spine_points()
	if points.size() < 2:
		print("PROBE FAIL: the z window selects %d spine points" % points.size())
		quit(1)
		return
	print("\nspine: %d authored points in the band, (%.0f, %.0f) -> (%.0f, %.0f)" % [
		points.size(), points[0].x, points[0].y,
		points[points.size() - 1].x, points[points.size() - 1].y])

	await _drive(points)
	_report()
	_report_objectives_after_victory()
	quit(0)


## ------------------------------------------------------- what is standing here

## Walk the live scene, not the config. Anything inside the band's z window
## that a player could stop for goes in the list with the kind it is, because
## "you meet something every 40m" is a different regional experience depending
## on whether the somethings are all the same kind.
func _collect_interest() -> void:
	var kinds := {}

	# Wild bodies are NOT snapshotted here, and the first version of this probe
	# was wrong because it did them the same way as everything else. They roam:
	# `wild_creature.gd` walks them around their cluster the whole time the
	# world is running, and this walk is nearly seven minutes of simulated
	# time. Against frozen boot positions the run reported meeting 11 of 155
	# creatures -- a measurement of how far they had wandered from where they
	# spawned, not of what the player passed. They are re-read live every
	# frame in `_drive` instead; only their COUNT is taken here.
	_wild_standing = 0
	for wild in _director.call("wild_creatures"):
		var body := wild as Node3D
		if body == null:
			continue
		if body.global_position.z >= Z_FROM and body.global_position.z <= Z_TO:
			_wild_standing += 1
	kinds["wild (live, roaming)"] = _wild_standing

	var trainers: Node = _world.get_node_or_null(^"Trainers")
	if trainers != null:
		for child in trainers.get_children():
			var n := child as Node3D
			if n != null and n.global_position.z >= Z_FROM and n.global_position.z <= Z_TO:
				_add_interest("trainer", str(n.name), n.global_position, kinds)

	# Two different things wear the `harvestable` group and conflating them
	# makes this whole probe useless. `harvest_node.gd` is an AUTHORED
	# gatherable -- a placed spot in `bands/<band>/harvest.json`, the thing
	# prompt 64 asks a region to have. `vegetation_harvest_point.gd` is a
	# pickable bolted onto a SCATTERED bush or tree, and there are thousands
	# of them everywhere in the corridor. Counting the second as content
	# would report zero dead travel in an empty field.
	for node in _world.get_tree().get_nodes_in_group(HARVEST_LOGIC.GROUP):
		var h := node as Node3D
		if h == null:
			continue
		var p2 := h.global_position
		if p2.z < Z_FROM or p2.z > Z_TO:
			continue
		var script_path := ""
		var scr: Script = h.get_script() as Script
		if scr != null:
			script_path = scr.resource_path
		var kind := "scatter_pick" if script_path.ends_with("vegetation_harvest_point.gd") else "harvest"
		_add_interest(kind, "%s@%d" % [h.name, h.get_instance_id()], p2, kinds)

	var props: Node = _world.get_node_or_null(^"Props")
	if props != null:
		for cluster in props.get_children():
			var c := cluster as Node3D
			if c == null:
				continue
			# A cluster's own transform can sit at the origin while its pieces
			# stand in the band; use the mean of the pieces when there are any.
			var centre := _cluster_centre(c)
			if centre.z >= Z_FROM and centre.z <= Z_TO:
				_add_interest("prop", str(c.name), centre, kinds)

	print("\nstanding in the band, from the LIVE scene:")
	for k in kinds.keys():
		print("  %-9s %d" % [k, kinds[k]])
	if _interest.is_empty():
		print("  nothing at all -- the walk below will be one long dead stretch")


func _cluster_centre(cluster: Node3D) -> Vector3:
	var sum := Vector3.ZERO
	var n := 0
	for piece in cluster.get_children():
		var p := piece as Node3D
		if p != null:
			sum += p.global_position
			n += 1
	return cluster.global_position if n == 0 else sum / float(n)


func _add_interest(kind: String, id: String, pos: Vector3, kinds: Dictionary) -> void:
	_interest.append({"kind": kind, "id": id, "pos": pos})
	kinds[kind] = int(kinds.get(kind, 0)) + 1


## The region's legibility test: from the tracked objective alone, can a player
## who has just walked out of the Warrens read what they are in Band 3 to do?
##
## Read from the real `/root/Game` autoload -- `quest_log.gd` against
## `progression`, the same pair that fills `objective_text` on the HUD -- and
## read at the state a player actually ARRIVES in, not at a fresh save. A
## fresh save tracks "Catch your first wild creature", which tells you nothing
## about this region and is an artefact of booting the sandbox scene rather
## than anything a player at z=3180 would ever see.
## Every main-chain flag up to and including the Warrens, in
## `data/progression/objectives.json` order. Setting only the last two is not
## the arrival state: `quest_log.gd` tracks the FIRST unfinished entry, so a
## run that skips the opening still reports "Catch your first wild creature"
## and tells you nothing about this region.
const ARRIVAL_FLAGS := [
	"opening:beat:road", "road_gate_open", "tournament_team_ready",
	"tournament_training_ready", "home_materials_gathered", "home_built",
	"creature_bed_built", "player_slept_at_home", "tournament_entered",
	"tournament_won", "south_bridge_open", "warrens_cleared",
]
## What the relay actually pays, in the order `smoke_relay.gd` proves they
## land: beat the captain, free Sela, shut the console down, gear the mill.
const VICTORY_FLAGS := ["relay_captain_defeated", "captive_rescued",
	"relay_disabled", "mill_crossing_restored"]


func _game() -> Node:
	return root.get_node_or_null(^"/root/Game")


func _tracked() -> String:
	var game := _game()
	if game == null:
		return "(no /root/Game autoload)"
	var progression: Object = game.get("progression")
	var quest_log: Object = game.get("quest_log")
	if progression == null or quest_log == null:
		return "(Game has no progression/quest_log)"
	return str(quest_log.call("tracked_text", progression))


func _set_flags(flags: Array) -> void:
	var game := _game()
	if game == null:
		return
	var progression: Object = game.get("progression")
	if progression == null:
		return
	for flag in flags:
		progression.call("set_flag", str(flag))


func _report_objectives() -> void:
	print("\nobjective line, as the HUD would show it:")
	print("  fresh save            : %s" % _tracked())
	_set_flags(ARRIVAL_FLAGS)
	print("  arriving from Warrens : %s" % _tracked())


## Does beating the relay change what the objective says, or does the player
## walk out of the region being told the same thing they walked in on?
func _report_objectives_after_victory() -> void:
	print("\nobjective line after the relay is beaten (flags set directly, no fight):")
	for flag in VICTORY_FLAGS:
		_set_flags([flag])
		print("  +%-24s -> %s" % [flag, _tracked()])


## ------------------------------------------------------------------ the walk

func _drive(points: Array[Vector2]) -> void:
	var start := Vector3(points[0].x, 0.0, points[0].y)
	start.y = float(_world.call("ground_height_at", start.x, start.z)) + 1.0
	_player.global_position = start
	_player.velocity = Vector3.ZERO
	_rig.global_position = start
	for i in RESETTLE_FRAMES:
		await physics_frame

	var walked := 0.0
	var frames := 0
	var idx := 1
	var prev := _player.global_position
	var teleports := 0
	var teleported := 0.0
	var stalls := 0
	## Which waypoint the last stall was targeting, so the same one is not
	## retried forever.
	var stalled_at_idx := -1
	## Ground handed over by a stall. Never counted as walked, and reported,
	## because a cadence figure that quietly credits skipped ground is a lie.
	var skipped := 0.0
	var last_meeting_m := 0.0
	var window_frames := 0
	var window_target_dist := Vector2(prev.x, prev.z).distance_to(points[idx])

	Input.action_press("move_forward")
	var run_start := Time.get_ticks_msec()

	while idx < points.size():
		var pos := _player.global_position
		var target := points[idx]
		var to_target := Vector2(target.x - pos.x, target.y - pos.z)

		if to_target.length() <= ARRIVE_M:
			idx += 1
			if idx >= points.size():
				break
			window_frames = 0
			window_target_dist = Vector2(pos.x, pos.z).distance_to(points[idx])
			continue

		_rig.set("yaw", atan2(-to_target.x, -to_target.y))
		await physics_frame
		frames += 1

		var now := _player.global_position
		var step := Vector2(now.x - prev.x, now.z - prev.z).length()
		if step > TELEPORT_STEP_M:
			teleported += step
			teleports += 1
		elif step > 0.001:
			walked += step
		prev = now

		if now.y < THROUGH_THE_FLOOR:
			print("  FELL THROUGH THE WORLD at (%.0f, %.0f), y=%.0f" % [now.x, now.z, now.y])
			break

		# What is within reach right now. Everything met at once is logged at
		# once: a picket standing beside a herd is a single moment for the
		# player and the report should read that way.
		var met_here := false

		# The roamers, read where they actually are this frame.
		for wild in _director.call("wild_creatures"):
			var body := wild as Node3D
			if body == null:
				continue
			var wid := "wild@%d" % body.get_instance_id()
			var d := now.distance_to(body.global_position)
			_wild_closest[wid] = minf(float(_wild_closest.get(wid, INF)), d)
			if _met.has(wid):
				continue
			if d > _reach:
				continue
			_met[wid] = true
			_events.append({"kind": "wild", "id": wid, "at_m": walked,
				"pos": body.global_position})
			met_here = true

		for item: Dictionary in _interest:
			# Cheap z reject first. There are a couple of thousand candidates
			# and ~19,000 frames in this walk; a float compare before the
			# dictionary lookup and the square root is what keeps that a
			# minute rather than an hour.
			var item_pos: Vector3 = item["pos"]
			if absf(item_pos.z - now.z) > _reach:
				continue
			if _met.has(item["id"]):
				continue
			if now.distance_to(item_pos) > _reach:
				continue
			_met[item["id"]] = true
			_events.append({"kind": item["kind"], "id": item["id"], "at_m": walked, "pos": item["pos"]})
			# Scatter pickables are counted and reported, but they do not end a
			# dead stretch: walking past a gatherable bush is not the region
			# giving you something to do, and if it counted, no region on the
			# corridor could ever measure dead travel at all.
			if str(item["kind"]) != "scatter_pick":
				met_here = true
		if met_here:
			var gap := walked - last_meeting_m
			if gap >= DEAD_TRAVEL_REPORT_M:
				_dead.append({"from_m": last_meeting_m, "to_m": walked, "len": gap, "pos": now})
			last_meeting_m = walked

		window_frames += 1
		if window_frames >= WEDGE_WINDOW:
			var dist_now := Vector2(now.x, now.z).distance_to(points[idx])
			if window_target_dist - dist_now < WEDGE_PROGRESS_M:
				# Not a corridor measurement to rescue -- a D3 finding. Name it,
				# step over it, and keep the cadence honest by not crediting the
				# skipped ground as walked.
				stalls += 1
				# Step to the waypoint it was HEADING FOR, not the one past it.
				# The first version advanced `idx` before teleporting, so a
				# stall at the Hess picket jumped the body from the approach
				# road straight to (280, 3900) -- over the top of the entire
				# relay compound, which then reported as 185m of dead travel
				# with Orrin, Dell, Vance and the relay yard never sampled.
				# Only if the SAME waypoint stalls twice is it given up on.
				if stalled_at_idx == idx:
					idx += 1
					if idx >= points.size():
						break
				stalled_at_idx = idx
				print("  STALL at (%.1f, %.1f) heading for (%.0f, %.0f): "
					% [now.x, now.z, points[idx].x, points[idx].y]
					+ "floor=%s wall=%s -- stepping to that waypoint (%.1fm not walked)"
					% [_player.is_on_floor(), _player.is_on_wall(),
						Vector2(now.x, now.z).distance_to(points[idx])])
				skipped += Vector2(now.x, now.z).distance_to(points[idx])
				var skip := Vector3(points[idx].x, 0.0, points[idx].y)
				skip.y = float(_world.call("ground_height_at", skip.x, skip.z)) + 1.0
				_player.global_position = skip
				_player.velocity = Vector3.ZERO
				_rig.global_position = skip
				for i in RESETTLE_FRAMES:
					await physics_frame
				prev = _player.global_position
			window_frames = 0
			window_target_dist = Vector2(now.x, now.z).distance_to(points[idx])

	Input.action_release("move_forward")

	# The tail: ground walked after the last thing met is dead travel too, and
	# it is the stretch a player remembers, because it is the one they leave on.
	var tail := walked - last_meeting_m
	if tail >= DEAD_TRAVEL_REPORT_M:
		_dead.append({"from_m": last_meeting_m, "to_m": walked, "len": tail,
			"pos": _player.global_position})

	_walk = {
		"walked": walked, "frames": frames, "stalls": stalls, "skipped": skipped,
		"teleports": teleports, "teleported": teleported,
		"seconds": (Time.get_ticks_msec() - run_start) / 1000.0,
		"end": _player.global_position,
	}


## ---------------------------------------------------------------- the report

func _report() -> void:
	print("\n=== WALK ===")
	print("physics frames driven   : %d" % int(_walk.get("frames", 0)))
	print("wall clock              : %.1f min" % (float(_walk.get("seconds", 0.0)) / 60.0))
	print("WALKED path length      : %.1f m" % float(_walk.get("walked", 0.0)))
	print("  = %.1f min at walk_speed %.1f m/s" % [
		float(_walk.get("walked", 0.0)) / _walk_speed_cfg / 60.0, _walk_speed_cfg])
	print("moved BY THE WORLD      : %.1f m over %d teleports (never counted as walked)" % [
		float(_walk.get("teleported", 0.0)), int(_walk.get("teleports", 0))])
	print("stalls stepped over     : %d  (%.1f m handed over, never counted as walked)" % [
		int(_walk.get("stalls", 0)), float(_walk.get("skipped", 0.0))])
	var end: Vector3 = _walk.get("end", Vector3.ZERO)
	print("end position            : (%.1f, %.1f, %.1f)" % [end.x, end.y, end.z])

	var by_kind := {}
	for e: Dictionary in _events:
		by_kind[e["kind"]] = int(by_kind.get(e["kind"], 0)) + 1
	print("\n=== MET WHILE WALKING (within %.0fm of the driven body) ===" % _reach)
	for k in by_kind.keys():
		print("  %-9s %d" % [k, by_kind[k]])
	var standing := {"wild": _wild_standing}
	for item: Dictionary in _interest:
		standing[item["kind"]] = int(standing.get(item["kind"], 0)) + 1
	print("  -- of what stands in the band:")
	for k in standing.keys():
		print("     %-9s %d standing, %d met (%.0f%%)" % [
			k, standing[k], int(by_kind.get(k, 0)),
			100.0 * float(int(by_kind.get(k, 0))) / maxf(1.0, float(standing[k]))])

	print("\n=== HOW CLOSE THE WALK CAME TO EACH WILD CREATURE ===")
	var buckets := [15.0, 25.0, 35.0, 50.0, 75.0, 100.0, 150.0, 250.0]
	var counts := {}
	for b in buckets:
		counts[b] = 0
	var beyond := 0
	for wid in _wild_closest.keys():
		var d: float = _wild_closest[wid]
		var placed := false
		for b in buckets:
			if d <= float(b):
				counts[b] = int(counts[b]) + 1
				placed = true
				break
		if not placed:
			beyond += 1
	var running := 0
	for b in buckets:
		running += int(counts[b])
		print("  within %5.0f m : %3d   (cumulative %3d of %d)" % [
			b, int(counts[b]), running, _wild_closest.size()])
	print("  further away  : %3d" % beyond)

	print("\n=== CADENCE (in walked metres from the band's south edge) ===")
	print("  scatter pickables are counted above but not listed -- there are thousands,")
	print("  they are corridor-wide, and none of them is this region's authored content.")
	var prev_m := 0.0
	for e: Dictionary in _events:
		if str(e["kind"]) == "scatter_pick":
			continue
		print("  %7.1f m  (+%5.1f)  %-8s %-28s at z=%.0f" % [
			e["at_m"], float(e["at_m"]) - prev_m, e["kind"], e["id"], (e["pos"] as Vector3).z])
		prev_m = float(e["at_m"])

	print("\n=== DEAD TRAVEL (stretches over %.0fm with nothing within reach) ===" % DEAD_TRAVEL_REPORT_M)
	var longest := 0.0
	for d: Dictionary in _dead:
		longest = maxf(longest, float(d["len"]))
		print("  %.1f m  from %.1f m to %.1f m  (ends near z=%.0f)" % [
			d["len"], d["from_m"], d["to_m"], (d["pos"] as Vector3).z])
	if _dead.is_empty():
		print("  none")
	print("LONGEST DEAD-TRAVEL INTERVAL: %.1f m  (%.1f s at walk_speed %.1f)" % [
		longest, longest / _walk_speed_cfg, _walk_speed_cfg])
