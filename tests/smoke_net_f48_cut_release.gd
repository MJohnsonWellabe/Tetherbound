extends "res://tests/smoke_net_f27_essence_no_dup.gd"

# peers: 2
## F48#1 release slice: a guest's release payout cut at the owner-save edge
## (after its owner file is written, before its ACK) neither duplicates nor
## loses anything.
##
##   tools/net/run_net_smoke.sh f48_cut_release
##
## Same setup as smoke_net_f27_essence_no_dup's release case (its disclosed
## fixtures: party_grant fills the guest's belt with five host-admitted
## creatures before networking, and a caught newcomer is parked on its pending
## seam). The guest releases one through the shipping Team-screen ceremony and
## its process is hard-killed at LedgerRpc's real "after_owner_write_before_ack"
## edge of that essence_release. A fresh process rejoins from disk. Afterwards
## the quoted essence is paid exactly once, one release receipt exists, the
## released creature is gone exactly once, and the host's accepted record
## agrees.

func _run() -> void:
	await process_frame
	heartbeat_silence_tolerance_s = 150.0
	if not await launch(2, "title"):
		quit(await finish())
		return
	_step_phase_deadline_ms = Time.get_ticks_msec() + 2400.0 * 1000.0
	if await _start_session(5):
		await _release_cut()
	print("F48_CUT_RELEASE: %d assertions" % _asserts)
	quit(await finish())


func _release_cut() -> void:
	if not await _pass(1, "f27_dismiss_modals", {}): return
	var before := await _guest()
	var hosted := await _host(_guest_id)
	var released := ""
	if (before.get("party", []) as Array).size() == 5: released = str(before.party[0].uid)
	want(not released.is_empty(), "the guest's belt holds five creatures (%s)" % str(before.get("party")))
	if released.is_empty(): return
	(_peers[1] as Dictionary)["quit_sent"] = true # The guest kills itself at the edge.
	var pid := int((_peers[1] as Dictionary).get("pid", -1))
	await step(1, "f27_ceremony_release", {"index": 0, "nickname": "Kept Newcomer", "cut": "owner_before_ack"}, 6000)
	for _f in 1800:
		await process_frame
		_pump_once()
		if not OS.is_process_running(pid): break
	want(not OS.is_process_running(pid), "the guest process ended")
	var cut_log := FileAccess.get_file_as_string(str((_peers[1] as Dictionary).get("log_path", "")))
	want(cut_log.contains("F48 RELEASE CUT"), "the guest died at the release payout's real owner-save edge (after owner write, before ACK)")
	var payout: Variant = null
	for line: String in cut_log.split("\n"):
		if line.begins_with("F48 RELEASE QUOTE: "): payout = JSON.parse_string(line.trim_prefix("F48 RELEASE QUOTE: "))
	want(payout is Array and not (payout as Array).is_empty(), "the host-admitted creature quoted a payout (%s)" % str(payout))
	if not payout is Array or (payout as Array).is_empty(): return
	var view := await _host(_guest_id)
	want((view.get("row", {}) as Dictionary).get("action") == "essence_release" and (view.get("row", {}) as Dictionary).get("status") == "pending",
		"the host's essence_release row is still pending without the ACK (%s)" % str(view.get("row")))
	# A killed process sends no disconnect: the host holds the dead guest's
	# seat until its ENet timeout (135-180 s) drops the link. Rejoin after that, so the fresh
	# process is not refused as "already connected" and rebuilding its world
	# on every retry.
	if not await _pass(0, "expect_peers", {"count": 1, "budget_s": 300.0}, 20000): return
	if not await _restart_and_rejoin(): return
	var after := await _guest()
	view = await _host(_guest_id)
	for i in 20:
		if (view.get("row", {}) as Dictionary).get("status") == "accepted": break
		await step(0, "wait", {"frames": 30})
		view = await _host(_guest_id)
	for stack: Variant in payout:
		var id := str((stack as Dictionary).get("id", ""))
		want(int(after.items.get(id, 0)) - int(before.items.get(id, 0)) == int((stack as Dictionary).get("n", -1)),
			"#1 release cut: exactly %d %s paid once (%d -> %d)" % [int(stack.n), id, int(before.items.get(id, 0)), int(after.items.get(id, 0))])
	want((after.release_receipts as Array).count("release:" + released) == 1 and (after.release_receipts as Array).size() == (before.release_receipts as Array).size() + 1,
		"#1 release cut: exactly one new release receipt (%s)" % str(after.release_receipts))
	var owned: Array = []
	for member: Variant in after.get("party", []): owned.append(str((member as Dictionary).get("uid", "")))
	want(not owned.has(released) and owned.size() == (before.party as Array).size() - 1,
		"#1 release cut: the released creature left exactly once (%s)" % str(owned))
	want((view.get("row", {}) as Dictionary).get("action") == "essence_release" and (view.get("row", {}) as Dictionary).get("status") == "accepted",
		"the host's row is the accepted essence_release (%s)" % str(view.get("row")))
	want(str(view.get("items")) == str(after.items) and str(view.get("release_receipts")) == str(after.release_receipts),
		"the host's admitted items/receipts equal the guest's (%s / %s)" % [str(view.get("items")), str(view.get("release_receipts"))])
	want(not str(view.get("party")).contains(released) and (view.get("party", []) as Array).size() == (hosted.get("party", []) as Array).size() - 1,
		"the host's admitted party lost exactly the released creature (%s)" % str(view.get("party")))
