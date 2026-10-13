extends "res://tools/earned_saves/tidewake_piece_runner.gd"
## P0 (12 Oct) backlog-save proof: loads a real earned checkpoint that was
## saved with an undrained combat_mastery queue, through the production title,
## then lets the production foundation scans run. Reports per-scan cost (not
## asserted: each scan deliberately re-attempts research), the
## drain, and that every queued landed use reaches the cards. Exits 1 on a
## failure. Never writes a save (quits before the runner's save step).
##   godot --headless --path . --script res://tools/probe_mastery_drain.gd -- \
##     --segment=08_ending --from=res://tests/fixtures/earned_saves/tidewake_07_human_late --out=<new dir>
const FRAME_LIMIT := 1200

func _count() -> Array:
	var w: RefCounted = game.get("world")
	var events := 0
	var mastery := 0
	for id: String in w.reward_deliveries:
		if not id.begins_with("foundation_event:"): continue
		events += 1
		for d: Dictionary in w.reward_deliveries[id].duties:
			if d.action == "combat_mastery": mastery += 1
	return [events, mastery, w.reward_deliveries.size()]

func _uses() -> int:
	var total := 0
	var party: Object = game.get("local").party
	for i in int(party.call("size")):
		var uses: Dictionary = party.call("at", i).get("move_mastery_uses")
		for move: String in uses: total += int(uses[move])
	return total

func _play() -> void:
	var session: Node = game.get("session")
	var start := _count()
	var uses_before := _uses()
	print("PROBE start events/mastery/rows=%s uses=%d" % [str(start), uses_before])
	var last := Time.get_ticks_usec()
	var worst := 0.0
	var drained := -1
	for frame in FRAME_LIMIT:
		await process_frame
		var now := Time.get_ticks_usec()
		worst = maxf(worst, (now - last) / 1000.0)
		last = now
		if frame % 60 == 0:
			print("PROBE f=%d rows=%s worst_ms=%.1f t=%ds" % [frame, str(_count()), worst, (Time.get_ticks_msec() - started_ms) / 1000])
			worst = 0.0
		if _count()[1] == 0:
			drained = frame
			break
	for i in 3: # let the last accepted rows settle on the cards
		await process_frame
	var idle: Array[float] = []
	for i in 3:
		var t := Time.get_ticks_usec()
		session.call("_retry_foundation_events")
		idle.append((Time.get_ticks_usec() - t) / 1000.0)
	var uses_after := _uses()
	print("PROBE drained_at_frame=%d end=%s uses %d -> %d (queued %d) idle_scans_ms=%s" % [drained, str(_count()), uses_before, uses_after, start[1], str(idle)])
	if drained < 0: failures.append("mastery queue did not drain in %d frames" % FRAME_LIMIT)
	# A rank-five move keeps only the receipt; uses never exceed before + queued.
	if uses_after < uses_before or uses_after > uses_before + int(start[1]): failures.append("mastery uses %d -> %d for %d queued" % [uses_before, uses_after, start[1]])
	print("PROBE %s %s" % ["PASS" if failures.is_empty() else "FAIL", str(failures)])
	quit(0 if failures.is_empty() else 1)
