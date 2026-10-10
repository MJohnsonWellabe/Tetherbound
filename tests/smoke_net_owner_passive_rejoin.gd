extends "res://tests/helpers/net_harness.gd"

# peers: 2 -- by hand (two Meadows builds), tools/net/run_net_smoke.sh owner_passive_rejoin

## Owner-passive admission survives a guest rejoin (MULTIPLAYER: co-op after
## any reconnect). Two real ENet peers in the production Meadows scene.
##
## The owner-passive stream carries a guest's care/travel inputs to the host
## and is what every passive-gated guest action (`owner_passive_sync.gd`
## `action_gate`/`gate`/`capture_gate`, e.g. an Altar spend) checkpoints
## against: the host must hold the guest's CURRENT stream and acknowledge it.
##
## 1. Join: the guest's stream is admitted (admission_pending false) and the
##    host holds exactly that stream id for the guest's character.
## 2. Leave + rejoin (plain `leave` then `join`): the guest arms a new stream;
##    the host must drop the departed one and admit the new one, acking it.
## 3. The rejoined guest walks: its recorded inputs are acknowledged by the
##    host under the new stream id (the passive path the gates rely on).
## 3b. Deliver-then-leave (coordinator 2026-10-05, F01 op10/op11): the guest
##    takes a world find (a host-journaled payout it applies and saves) while
##    its owner-passive send is held (fixture: "left before its inputs reached
##    the host"), leaves, and rejoins. It holds every payout this world
##    recorded, so its record is adopted (owner ruling 2026-10-05, "guest wins
##    unless behind"); the host's record has the find, absorbed once.
## 4. Offline change (F18 render 37365638014): the guest leaves, its creature
##    gains a level offline (fixture), and it rejoins. Not behind: the host
##    adopts the guest's record (its levels), no refusal, and a later find pays
##    on both sides.
## 4b. Behind (a restored backup): the guest leaves and forgets that later
##    find (fixture `op_rollback`), and rejoins. Its record lacks a payout this
##    world absorbed, so the held record wins and the guest adopts it: the find
##    is back, its payout row settled, not paid again.
## 5. NEGATIVE CONTROL: an invalid portable record (fixture: hp above max) is
##    refused at the rejoin hello with a reason, never adopted.

const PEER_SCRIPT := "res://tests/smoke_net_owner_passive_rejoin_peer.gd"
const BUILD_BUDGET := 20000
const ADMIT_FRAMES := 600

var _port := 0
var _guest_character := ""
var _tonic_uid := ""
var _tonic_receipt := ""
var _tonic_remaining := 0.0
var _earned_mastery: Dictionary = {}
var _mastery_uid := ""


func _initialize() -> void:
	# Building the Meadows world blocks a peer's heartbeat for minutes on the
	# 4-core container (smoke_net_cloudreach_veyra_reconnect.gd's reason).
	heartbeat_silence_tolerance_s = 420.0
	for arg: String in OS.get_cmdline_user_args():
		if not arg.begins_with("--out="): continue
		var output := arg.trim_prefix("--out=")
		var absolute := ProjectSettings.globalize_path("res://").path_join(output)
		if not output.begins_with("ralph/reports/F24/") or ".." in output \
			or DirAccess.dir_exists_absolute(absolute) or FileAccess.file_exists(absolute):
			push_error("F24 output must be a fresh reports directory")
			quit(1)
			return
		OS.set_environment("TB_NET_OUT_DIR", absolute)
	if OS.get_cmdline_user_args().has("--capture-combat-hud") \
		and (DisplayServer.get_name() == "headless" or OS.get_environment("GITHUB_ACTIONS") != "true" \
			or not OS.get_cmdline_user_args().has("--prove-tag-combo") or OS.get_environment("TB_NET_OUT_DIR").is_empty()):
		push_error("Combat HUD capture requires a native hosted parent, --prove-tag-combo and TB_NET_OUT_DIR")
		quit(1)
		return
	if OS.get_cmdline_user_args().has("--with-fight-camera-units") or OS.get_cmdline_user_args().has("--with-tag-units") \
		or OS.get_cmdline_user_args().has("--with-combat-hud-units") \
		or OS.get_cmdline_user_args().has("--with-shipping-command-units"):
		var selectors := PackedStringArray()
		if OS.get_cmdline_user_args().has("--with-shipping-command-units"):
			selectors.append_array(PackedStringArray(["test_f24_host_commands.gd", "test_move_commit_runtime.gd"]))
		if OS.get_cmdline_user_args().has("--with-tag-units"):
			# Existing files naming either changed production combat script.
			selectors = PackedStringArray([
				"test_actor_vitals_authority.gd", "test_alpha_pins.gd", "test_characterize_flag_keys.gd",
				"test_charger_lunge.gd", "test_client_trainer_victory.gd", "test_combat_aftermath_focus.gd",
				"test_combat_burst.gd", "test_combat_camera_framing_tunables.gd", "test_combat_camera_shoulder.gd",
				"test_combat_camera_top_band.gd", "test_combat_contact_spacing.gd", "test_combat_feedback.gd",
				"test_combat_flee_buffer.gd", "test_combat_mastery_delivery.gd", "test_combat_progression.gd",
				"test_combat_realm_owned_begin.gd", "test_combat_send_out_hold.gd", "test_combat_spaced_camera.gd",
				"test_combat_stagger.gd", "test_combat_tell_swing.gd", "test_combat_vfx.gd",
				"test_combat_wind.gd", "test_creature_gear.gd", "test_creature_history.gd",
				"test_director_card_best_survivability.gd", "test_director_join_snapshot.gd", "test_director_legacy_mirror.gd",
				"test_director_projectile_deployment_binding.gd", "test_enemy_named_attack.gd", "test_engage_offer_surface_distance.gd",
				"test_f21_hit_presentation.gd", "test_f23_live_moves.gd", "test_f24_host_commands.gd",
				"test_fight_camera.gd", "test_foundation_combat_manager_context.gd", "test_foundation_retry_admission.gd",
				"test_guest_idle_combat_authority.gd", "test_guest_master_admission.gd", "test_harness_max_hp.gd",
				"test_hit_feedback.gd", "test_hosted_combat_staging.gd", "test_livewire_cooldowns.gd",
				"test_move_commit_runtime.gd", "test_named_tell_text.gd", "test_named_trainer_wild_clear.gd",
				"test_net_boss_snapshot.gd", "test_net_strike_transaction.gd", "test_orb_passes_your_own_creature.gd",
				"test_portal_director_lookup.gd", "test_practice_engage_priority.gd", "test_process_exit_settlement.gd",
				"test_rematch_solo_admission.gd", "test_remote_rematch_runtime.gd", "test_scale_sensitive_gameplay.gd",
				"test_shared_boss_authored_pipeline.gd", "test_shared_opponent_cue_shape.gd", "test_shared_opponent_presentation.gd",
				"test_shared_wild_host_fight.gd", "test_shiny.gd", "test_stormwood_b_combat_camera_fit.gd",
				"test_stormwood_hosted_combat.gd", "test_stormwood_realm_transition.gd", "test_tournament_network_selection.gd",
				"test_trainer_aftermath_lifetime.gd", "test_trainer_aftermath.gd", "test_trainer_ally_lateral_ranks.gd",
				"test_trainer_rules.gd", "test_trainers_data.gd", "test_tutorial_faint_floor.gd",
				"test_water_encounter_runtime_data.gd", "test_water_guardian_solo_win.gd", "test_water_realm_transition.gd",
				"test_water_tidal_guard_combat.gd", "test_wild_alphas.gd", "test_wild_cluster_body_spacing.gd",
				"test_wild_once.gd", "test_world_verb_input_owner_enforcement.gd"])
		if OS.get_cmdline_user_args().has("--with-fight-camera-units") and not selectors.has("test_fight_camera.gd"):
			selectors.append("test_fight_camera.gd")
		if OS.get_cmdline_user_args().has("--with-combat-hud-units"):
			# Existing files naming the changed combat_hud.gd producer.
			for file: String in ["test_combat_hud_handheld_floors.gd", "test_combat_wind.gd", "test_harness_max_hp.gd",
				"test_hud_presentation_lifecycle.gd", "test_hud_widgets.gd", "test_level_up_announcement.gd",
				"test_motion_prefs.gd", "test_world_verb_input_owner_enforcement.gd", "test_input_device.gd",
				"test_move_commit_runtime.gd",
				"test_input_glyph_rebinding.gd", "test_input_glyph_verbs.gd", "test_prompt_arbiter.gd", "test_stormwood_dynamo.gd"]:
				if not selectors.has(file): selectors.append(file)
		var unit_output: Array = []
		var unit_code := OS.execute(OS.get_executable_path(), PackedStringArray([
			"--headless", "--path", ProjectSettings.globalize_path("res://"), "--audio-driver", "Dummy",
			"--script", "res://tests/run_tests.gd", "--", "--only=" + ",".join(selectors)]), unit_output, true)
		for chunk: Variant in unit_output: print(str(chunk))
		if unit_code != 0:
			quit(unit_code)
			return
	_run()


func _spawn_peer(i: int, role: String, control_port: int, enet_port: int, scene: String,
		home: String, log_path: String, extra_args: Array) -> int:
	var exe := OS.get_executable_path()
	var args: Array = ["--headless", "--path", ProjectSettings.globalize_path("res://"),
		"--script", PEER_SCRIPT, "--",
		"--role=%s" % role, "--peer=%d" % i,
		"--control-port=%d" % control_port, "--enet-port=%d" % enet_port,
		"--scene=%s" % scene, "TB_NET_RUN_ID=%s" % _run_id]
	if i == 1 and OS.get_cmdline_user_args().has("--capture-combat-hud"):
		args = ["--path", ProjectSettings.globalize_path("res://"),
			"--rendering-method", RenderingServer.get_current_rendering_method(), "--disable-render-loop", "--audio-driver", "Dummy",
			"--resolution", "%dx%d" % [root.size.x, root.size.y]] + args.slice(3)
		args.append_array(["--capture-combat-hud", "--hud-output=" + OS.get_environment("TB_NET_OUT_DIR").path_join("combat-hud")])
		for arg: String in OS.get_cmdline_user_args():
			if arg.begins_with("--preset=") or arg.begins_with("--source-commit=") or arg.begins_with("--low-resolution="):
				args.append(arg)
	if OS.get_cmdline_user_args().has("--without-actor-vitals"):
		args.append("--without-actor-vitals")
	if OS.get_cmdline_user_args().has("--prove-shipping-tether"):
		args.append("--prove-shipping-tether")
	for extra in extra_args:
		args.append(str(extra))
	OS.set_environment("XDG_DATA_HOME", home)
	OS.set_environment("TB_NET_RUN_ID", _run_id)
	OS.set_environment("TB_WORLD_SEED", "0")
	if OS.has_feature("windows"):
		var roaming := home.path_join("AppData/Roaming")
		var local := home.path_join("AppData/Local")
		for directory: String in [roaming, local]:
			if DirAccess.make_dir_recursive_absolute(directory) != OK:
				push_error("Cannot create peer profile directory: " + directory)
				return -1
		OS.set_environment("APPDATA", roaming)
		OS.set_environment("LOCALAPPDATA", local)
		OS.set_environment("USERPROFILE", home)
		var separator := args.find("--")
		args.insert(separator, "--log-file")
		args.insert(separator + 1, log_path)
		return OS.create_process(exe, args)
	var parts: Array[String] = [_shq(exe)]
	for a in args:
		parts.append(_shq(str(a)))
	return OS.create_process("/bin/sh", ["-c", "exec %s >%s 2>&1" % [" ".join(parts), _shq(log_path)]])


func _ok(result: Dictionary, label: String) -> bool:
	var passed := str(result.get("verdict", "")) == "PASS"
	check(passed, "%s -- %s" % [label, str(result.get("detail", ""))])
	return passed


func _state(peer: int) -> Dictionary:
	var value: Variant = await probe(peer, "op_state")
	return value if value is Dictionary else {}


## Wait until the guest's own stream is admitted and the host holds that same
## id for the guest's character, or the budget runs out. Returns the last pair.
func _await_admitted(label: String) -> Dictionary:
	var guest := {}
	var host := {}
	var waited := 0
	while waited <= ADMIT_FRAMES:
		guest = await _state(1)
		host = await _state(0)
		var mine: Dictionary = guest.get("local", {})
		var held: Dictionary = (host.get("hosts", {}) as Dictionary).get(_guest_character, {})
		if not bool(mine.get("admission_pending", true)) and str(held.get("id", "")) == str(mine.get("id", "x")):
			break
		await step(0, "wait", {"frames": 30})
		waited += 30
	print("OP %s guest=%s host_stream=%s" % [label, JSON.stringify(guest.get("local", {})),
		JSON.stringify((host.get("hosts", {}) as Dictionary).get(_guest_character, {}))])
	return {"guest": guest, "host": host}


func _admitted(pair: Dictionary) -> bool:
	var mine: Dictionary = (pair.guest as Dictionary).get("local", {})
	var held: Dictionary = ((pair.host as Dictionary).get("hosts", {}) as Dictionary).get(_guest_character, {})
	return bool(mine.get("armed", false)) and not bool(mine.get("admission_pending", true)) \
		and str(mine.get("error", "")).is_empty() and str(held.get("id", "")) == str(mine.get("id", "")) \
		and not bool(held.get("departed", false))


func _rejoin(label: String) -> bool:
	if not _ok(await step(1, "leave"), "%s: guest leaves" % label):
		return false
	_ok(await step(0, "expect_peers", {"count": 1}), "%s: host sees the guest gone" % label)
	if not _ok(await step(1, "join", {"host": "127.0.0.1", "port": _port}), "%s: guest rejoins" % label):
		return false
	for i in 2:
		_ok(await step(i, "expect_peers", {"count": 2}), "%s: peer %d sees both" % [label, i])
	return true


func _run() -> void:
	if not await launch(2, "title"):
		quit(await finish())
		return
	_step_phase_deadline_ms = Time.get_ticks_msec() + 3600.0 * 1000.0
	var host_commands: bool = OS.get_cmdline_user_args().has("--prove-host-tether-commands")
	var command_setup_peer: int = 0 if host_commands else 1
	for i in 2:
		_ok(await step(i, "op_tonic_candidate"), "tonic: process-local candidate gates before world boot")
		if not _ok(await step(i, "boot", {"scene": "world"}, BUILD_BUDGET), "SETUP: peer %d boots its own Meadows world" % i):
			quit(await finish())
			return
		await step(i, "dismiss_dialogue", {})
		_ok(await step(i, "party_grant", {"species": "terrapup", "level": 8}), "SETUP: peer %d owns a terrapup" % i)
		if (host_commands and i == 0) or (not host_commands and i == 1 \
			and OS.get_cmdline_user_args().has("--prove-tag-combo")):
			_ok(await step(i, "party_grant", {"species":"ripplet", "level":8}), "Tag SETUP: peer %d owns one additional healthy companion before admission" % i)
	_ok(await step(command_setup_peer, "op_tonic_supply"), "tonic: peer %d saves its initial two-item stock before admission" % command_setup_peer)
	if not _ok(await step(0, "host"), "peer 0 hosts"):
		quit(await finish())
		return
	var session: Variant = await probe(0, "session")
	_port = int((session as Dictionary).get("enet_port", 0)) if session is Dictionary else 0
	if not _ok(await step(1, "join", {"host": "127.0.0.1", "port": _port}), "peer 1 joins"):
		quit(await finish())
		return
	for i in 2:
		_ok(await step(i, "expect_peers", {"count": 2}), "peer %d sees both" % i)
		await step(i, "dismiss_dialogue", {"settle": 10})
	_guest_character = str((await _state(1)).get("character_id", ""))
	check(not _guest_character.is_empty(), "the guest has a character id")

	# 1. First join.
	var first := await _await_admitted("first-join")
	check(_admitted(first), "first join: the guest's owner-passive stream is admitted by the host")
	if OS.get_cmdline_user_args().has("--prove-host-tether-snare"):
		# Independent F24#3 fresh-join segment; the default Item/Mastery/rejoin
		# path and its assertions remain below. No failed save is reused.
		if _admitted(first): await _prove_snare(0)
		quit(await finish())
		return
	if OS.get_cmdline_user_args().has("--prove-host-tether-rally"):
		if _admitted(first): await _prove_rally(0)
		quit(await finish())
		return
	if OS.get_cmdline_user_args().has("--prove-host-tether-commands"):
		# F24#0 uses the same first-admitted owner, actual wild encounters and
		# command assertions. Shipping Snare is a separately retained proof.
		if _admitted(first):
			var failed_before: int = failures.size()
			var item_ok: bool = await _tonic_item_original(0)
			if item_ok and failures.size() == failed_before:
				for i in [1, 0]:
					_ok(await step(i, "press", {"action":"combat_run"}), "host Item: peer %d normally leaves the proof fight" % i)
				if failures.size() == failed_before: await _prove_rally(0)
				if failures.size() == failed_before: await _prove_tag_combo(0)
		quit(await finish())
		return
	var first_id := str(((first.guest as Dictionary).get("local", {}) as Dictionary).get("id", ""))
	if not await _tonic_item_original():
		quit(await finish())
		return
	# Mastery settles after a normal wild exit, before testing plain rejoin.
	# The actual Item remains timed; neither exit fabricates a win or reward.
	for i in [1, 0]:
		if not _ok(await step(i, "press", {"action":"combat_run"}), "mastery: normal disengage input exits peer %d's wild fight" % i):
			quit(await finish())
			return
	var mastery_settled := false
	for poll in 30:
		var owner: Dictionary = (await _state(1)).get("mastery", {})
		var held: Dictionary = (await _state(0)).get("mastery", {}).get("held", {}).get(_guest_character, {}).get(_mastery_uid, {})
		if owner.get("disk", {}).get(_mastery_uid, {}) == _earned_mastery and held == _earned_mastery:
			mastery_settled = true
			break
		await step(0, "wait", {"frames":30})
	check(mastery_settled, "mastery: normal exit settles exactly the actual earned uses on owner disk and host")
	print("MASTERY actual exit observation: ", JSON.stringify({"earned":_earned_mastery,
		"owner":(await _state(1)).get("mastery", {}), "host":(await _state(0)).get("mastery", {}),
		"owner_encounter":await probe(1, "encounter"), "host_encounter":await probe(0, "encounter")}))

	# 2. Plain leave + rejoin.
	if not await _rejoin("rejoin"):
		quit(await finish())
		return
	var after := await _await_admitted("after-rejoin")
	var rejoined_id := str(((after.guest as Dictionary).get("local", {}) as Dictionary).get("id", ""))
	check(rejoined_id != first_id and not rejoined_id.is_empty(), "rejoin: the guest armed a new stream")
	check(_admitted(after), "rejoin: the host admitted the rejoined guest's NEW stream (not pending, same id)")
	var rejoin_tonic: Dictionary = (await _state(1)).get("tonic", {})
	var rejoin_remaining := _tonic_seconds(rejoin_tonic)
	check(rejoin_remaining > 0.0 and rejoin_remaining <= _tonic_remaining,
		"tonic: new admitted stream reconciles remaining duration without refreshing the saved Item")
	check(int(rejoin_tonic.get("stock", -1)) == 1, "tonic: rejoin never debits the Item a second time")
	check((rejoin_tonic.get("disk_receipts", []) as Array).has(_tonic_receipt), "tonic: owner disk retains the exact saved Item receipt")
	var rejoin_mastery := {}
	var held_mastery := {}
	for poll in 30:
		rejoin_mastery = (await _state(1)).get("mastery", {})
		held_mastery = (await _state(0)).get("mastery", {}).get("held", {}).get(_guest_character, {}).get(_mastery_uid, {})
		if rejoin_mastery.get("disk", {}).get(_mastery_uid, {}) == _earned_mastery and held_mastery == _earned_mastery: break
		await step(0, "wait", {"frames":30})
	check(rejoin_mastery.get("live", {}).get(_mastery_uid, {}).get("uses") == _earned_mastery.get("uses") \
		and rejoin_mastery.get("live", {}).get(_mastery_uid, {}).get("receipts") == _earned_mastery.get("receipts"),
		"mastery: plain rejoin preserves actual landed uses and never credits an admission replay")
	check(rejoin_mastery.get("disk", {}).get(_mastery_uid, {}) == _earned_mastery and held_mastery == _earned_mastery,
		"mastery: real owner disk and rejoined host hold exactly the earned per-UID mastery")
	print("MASTERY actual rejoin observation: ", JSON.stringify({"earned":_earned_mastery, "owner":rejoin_mastery, "held":held_mastery}))

	# 3. Passive inputs after the rejoin are acknowledged under the new id.
	# Saved mastery legitimately rebases the owner stream. Sample its current
	# admitted identity after settlement before testing additional inputs.
	var walking_stream := await _await_admitted("before-walk")
	check(_admitted(walking_stream), "rejoin: the current post-settlement walking stream is admitted")
	rejoined_id = str(walking_stream.guest.get("local", {}).get("id", ""))
	var before_walk: Dictionary = ((await _state(1)).get("local", {}) as Dictionary)
	await step(1, "stick", {"x": 0.0, "y": -1.0, "frames": 180})
	await step(1, "stick", {"x": 1.0, "y": 0.0, "frames": 120})
	var acked_ok := false
	var walked: Dictionary = {}
	for _i in 20:
		await step(0, "wait", {"frames": 30})
		walked = ((await _state(1)).get("local", {}) as Dictionary)
		# The walking owner records inputs continuously, so the newest few
		# are always in flight: the proof is that the host acknowledges
		# inputs recorded AFTER the rejoin under the new stream id.
		if int(walked.get("acked", 0)) > int(before_walk.get("sequence", 0)) \
				and str(walked.get("id", "")) == rejoined_id and str(walked.get("error", "")).is_empty():
			acked_ok = true
			break
	check(acked_ok, "rejoin: the walking guest's passive inputs are acknowledged by the host (%s -> %s)"
		% [JSON.stringify(before_walk), JSON.stringify(walked)])
	# Natural authored ninety-second timer, not a forged prefix or accelerated clock.
	var expired := false
	for poll in 110:
		await step(1, "wait", {"frames":60})
		var owner_tonic: Dictionary = (await _state(1)).get("tonic", {})
		var host_tonic: Dictionary = (await _state(0)).get("tonic", {})
		var effects: Array = host_tonic.get("projected", {}).get(_guest_character, {}).get(_tonic_uid, {}).get("effects", [])
		if _tonic_seconds(owner_tonic) == 0.0 and effects.is_empty():
			expired = true
			break
	check(expired, "tonic: actual owner passive ticks expire the same effect on guest and host")
	check(_tonic_seconds((await _state(0)).get("tonic", {})) == 0.0, "tonic: the guest command never buffs the other player's creature")
	if not await _rejoin("expired-tonic"):
		quit(await finish())
		return
	check(_admitted(await _await_admitted("expired-tonic")), "tonic: expired receipt rejoins normally")
	check(_tonic_seconds((await _state(1)).get("tonic", {})) == 0.0,
		"tonic: accepting the saved receipt after expiry cannot resurrect its old duration")

	# 3b. Deliver-then-leave.
	var base_items: Dictionary = (await _state(1)).get("items", {})
	_ok(await step(1, "op_hold", {"hold": true}), "deliver-then-leave: FIXTURE the guest's owner-passive send is held")
	# Both peers stand the find, as both run the same world scene: the host's
	# own world says what it holds, so the guest's claim is a journaled payout.
	for i in 2:
		_ok(await step(i, "pickup_stand", {"id": "op_rejoin_find_a", "item": "berries", "realm": "meadows", "count": 3}),
			"deliver-then-leave: peer %d stands the find" % i)
	_ok(await step(1, "pickup_take"), "deliver-then-leave: the guest takes it")
	var paid := false
	for _i in 30:
		await step(0, "wait", {"frames": 30})
		if int(((await _state(1)).get("items", {}) as Dictionary).get("berries", 0)) >= int(base_items.get("berries", 0)) + 3:
			paid = true
			break
	check(paid, "deliver-then-leave: the guest's satchel holds the find (host-journaled payout applied and saved)")
	for _i in 10: await step(0, "wait", {"frames": 30}) # The host accepts the guest's ACK.
	if not await _rejoin("deliver-then-leave"):
		quit(await finish())
		return
	_ok(await step(1, "op_hold", {"hold": false}), "deliver-then-leave: the new stream sends normally")
	var delivered := await _await_admitted("deliver-then-leave")
	check(_admitted(delivered), "deliver-then-leave: the rejoined stream is admitted, not refused")
	var code := str(((await _state(0)).get("rejoin_codes", {}) as Dictionary).get(_guest_character, ""))
	check(code == "readmitted_portable", "deliver-then-leave: holding every payout, the guest's record is adopted (%s)" % code)
	var held: Dictionary = (((await _state(0)).get("authority", {}) as Dictionary).get(_guest_character, {}) as Dictionary)
	check(int((held.get("items", {}) as Dictionary).get("berries", 0)) == int(((await _state(1)).get("items", {}) as Dictionary).get("berries", -1)),
		"deliver-then-leave: the host's held record has the find, from its own row (%s)" % JSON.stringify(held))

	# 4. Offline change.
	if not _ok(await step(1, "leave"), "offline change: guest leaves"):
		quit(await finish())
		return
	_ok(await step(0, "expect_peers", {"count": 1}), "offline change: host sees the guest gone")
	var held_levels: Array = (await _state(1)).get("levels", [])
	_ok(await step(1, "op_diverge"), "offline change: FIXTURE the guest's creature gains a level offline")
	var levels: Array = (await _state(1)).get("levels", [])
	check(levels != held_levels, "offline change: the guest's file now differs (levels %s -> %s)" % [str(held_levels), str(levels)])
	_ok(await step(1, "join", {"host": "127.0.0.1", "port": _port}), "offline change: guest rejoins")
	for i in 2: _ok(await step(i, "expect_peers", {"count": 2}), "offline change: peer %d sees both" % i)
	var changed := await _await_admitted("offline-change")
	check(_admitted(changed), "offline change: the rejoined stream is admitted")
	var changed_code := str(((await _state(0)).get("rejoin_codes", {}) as Dictionary).get(_guest_character, ""))
	check(changed_code == "readmitted_portable", "offline change: not behind, the guest's record is adopted (%s)" % changed_code)
	held = (((await _state(0)).get("authority", {}) as Dictionary).get(_guest_character, {}) as Dictionary)
	check(held.get("levels") == levels, "offline change: the host's record now has the guest's levels (guest %s, host %s)" % [str(levels), JSON.stringify(held)])
	var kept: Dictionary = await _state(1)
	check(kept.get("levels") == levels and str((kept.get("local", {}) as Dictionary).get("admission_refused", "")).is_empty(),
		"offline change: the guest keeps its levels, not refused (guest levels %s, refused '%s')" % [
		str(kept.get("levels")), str((kept.get("local", {}) as Dictionary).get("admission_refused", ""))])
	var before_find: Dictionary = (await _state(1)).get("items", {})
	for i in 2:
		_ok(await step(i, "pickup_stand", {"id": "op_rejoin_find_b", "item": "berries", "realm": "meadows", "count": 2}),
			"offline change: peer %d stands another find" % i)
	_ok(await step(1, "pickup_take"), "offline change: the guest takes it")
	var pays := false
	for _i in 30:
		await step(0, "wait", {"frames": 30})
		var mine_now: Dictionary = (await _state(1)).get("items", {})
		var host_now: Dictionary = ((((await _state(0)).get("authority", {}) as Dictionary).get(_guest_character, {}) as Dictionary).get("items", {}))
		if int(mine_now.get("berries", 0)) == int(before_find.get("berries", 0)) + 2 and int(host_now.get("berries", 0)) == int(mine_now.get("berries", 0)):
			pays = true
			break
	check(pays, "offline change: a later find pays the guest and reaches the host's record (satchel not blocked): guest %s host %s" % [
		JSON.stringify((await _state(1)).get("items", {})),
		JSON.stringify((((await _state(0)).get("authority", {}) as Dictionary).get(_guest_character, {}) as Dictionary))])

	# 4b. Behind: a restored backup made before that find.
	var full: Dictionary = (await _state(1)).get("items", {})
	if not _ok(await step(1, "leave"), "behind: guest leaves"):
		quit(await finish())
		return
	_ok(await step(0, "expect_peers", {"count": 1}), "behind: host sees the guest gone")
	_ok(await step(1, "op_rollback", {"find": "op_rejoin_find_b", "item": "berries", "count": 2}),
		"behind: FIXTURE the guest's file forgets the later find (a backup)")
	_ok(await step(1, "join", {"host": "127.0.0.1", "port": _port}), "behind: guest rejoins")
	for i in 2: _ok(await step(i, "expect_peers", {"count": 2}), "behind: peer %d sees both" % i)
	var behind_code := str(((await _state(0)).get("rejoin_codes", {}) as Dictionary).get(_guest_character, ""))
	check(behind_code == "held_wins", "behind: the host's held record wins (%s)" % behind_code)
	var restored: Dictionary = {}
	for _i in 30:
		restored = await _state(1)
		if int((restored.get("items", {}) as Dictionary).get("berries", 0)) == int(full.get("berries", -1)): break
		await step(0, "wait", {"frames": 30})
	check(int((restored.get("items", {}) as Dictionary).get("berries", 0)) == int(full.get("berries", -1))
		and str((restored.get("local", {}) as Dictionary).get("admission_refused", "")).is_empty(),
		"behind: the guest adopted the held record, the find is back once (%s vs %s)" % [JSON.stringify(restored.get("items", {})), JSON.stringify(full)])
	var behind_admitted := await _await_admitted("behind")
	check(_admitted(behind_admitted), "behind: the stream is admitted after the adoption")
	for _i in 10: await step(0, "wait", {"frames": 30})
	check(int(((await _state(1)).get("items", {}) as Dictionary).get("berries", 0)) == int(full.get("berries", -1)), "behind: the find is never paid a second time")

	if OS.get_cmdline_user_args().has("--prove-tag-combo"):
		await _prove_tag_combo()

	if OS.get_cmdline_user_args().has("--prove-tether-snare"):
		await _prove_snare(1)

	if OS.get_cmdline_user_args().has("--prove-tether-rally"):
		await _prove_rally(1)

	# 5. Negative control: an invalid record is refused, never adopted.
	if not _ok(await step(1, "leave"), "invalid: guest leaves"):
		quit(await finish())
		return
	_ok(await step(0, "expect_peers", {"count": 1}), "invalid: host sees the guest gone")
	_ok(await step(1, "op_corrupt"), "invalid: FIXTURE the guest's record is invalid (hp above max)")
	var refused: Dictionary = await step(1, "join", {"host": "127.0.0.1", "port": _port})
	check(str(refused.get("verdict", "")) != "PASS" and str(refused.get("detail", "")).contains("could not be admitted"),
		"invalid: the rejoin is refused with a reason (%s)" % str(refused.get("detail", "")))
	quit(await finish())


func _prove_tag_combo(commander: int = 1) -> void:
	_ok(await step(0, "deploy_creature"), "Tag: host deploys its same actual owned companion")
	if not _ok(await step(0, "op_tag_target"), "Tag: host normally engages an actual live wild"): return
	var encounter: Dictionary = await probe(0, "encounter")
	_ok(await step(1, "teleport", {"at":encounter.get("opponent_pos", [])}), "Tag: existing proximity setup reaches the actual host fight")
	_ok(await step(1, "deploy_creature"), "Tag: guest deploys its same admitted owned companion")
	if not _ok(await step(1, "join_encounter", {"encounter_id":str(encounter.get("id", ""))}), "Tag: guest joins the exact host encounter"): return
	var owner: Dictionary = await probe(commander, "op_tag_state")
	var commander_character := _guest_character if commander == 1 else str(owner.get("character_id", ""))
	check(not commander_character.is_empty(), "Tag: commander has its actual stable character")
	if commander_character.is_empty(): return
	var peer := int(owner.peer)
	var host_before: Dictionary = await probe(0, "op_tag_state", {"peer":peer})
	var combo: Dictionary = await step(commander, "op_tag_combo")
	if combo.get("verdict") != "PASS":
		var failed_data: Dictionary = combo.get("data", {})
		var failed_request: Dictionary = failed_data.get("request", {})
		print("TAG failed owner observation: ", JSON.stringify(failed_data))
		# A timeout has no returned request; keep the already-observed encounter
		# binding so the existing host probe still retains its live saved proposal.
		var failed_host: Dictionary = await probe(0, "op_tag_state", {"peer":peer,
			"request":failed_request, "character_id":commander_character,
			"encounter_id":str(host_before.get("encounter_id", ""))})
		print("TAG failed host observation: ", JSON.stringify(failed_host))
	if not _ok(combo, "Tag: actual hits earn meter and fresh-hit command switches normally"): return
	var data: Dictionary = combo.data
	var request: Dictionary = data.request
	var args := {"peer":peer, "request":request, "character_id":commander_character}
	var host: Dictionary = await probe(0, "op_tag_state", args)
	var after: Dictionary = await probe(commander, "op_tag_state")
	var observer: Dictionary = await probe(1 - commander, "op_tag_state")
	var original: Dictionary = host.original
	var outcome: Dictionary = original.get("outcome", {})
	var verdict: Dictionary = outcome.get("verdict", {})
	var strikes: Array = verdict.get("delta", {}).get("effect", {}).get("strikes", [])
	check(strikes.size() == 2 and verdict.get("ok") == true, "Tag: host retains one accepted parent with both actual child writes")
	if strikes.size() != 2: return
	check(strikes[0].source_kind == "creature" and strikes[1].source_kind == "creature" \
		and strikes[0].attacker_uid == data.before.deployment.creature_uid and strikes[1].attacker_uid == data.incoming_uid \
		and strikes[0].character_id == commander_character and strikes[1].character_id == commander_character,
		"Tag: both damage events belong to the owner's distinct creatures")
	check(float(strikes[0].actual_hp_debit) > 0.0 and float(strikes[1].actual_hp_debit) > 0.0 \
		and strikes[0].target_hp_after == strikes[1].target_hp_before \
		and host.record.opponent.hp == strikes[1].target_hp_after and verdict.delta.hp == strikes[1].target_hp_after,
		"Tag: both positive actual HP debits form one exact chain and parent final HP")
	check(strikes[0].power_multiplier == 0.5 and strikes[1].power_multiplier == 1.5,
		"Tag: outgoing half quick and incoming full one-and-a-half quick retain authored factors")
	check(after.body_instance == data.before.body_instance and host.body_instance == host_before.body_instance \
		and after.deployment.creature_uid == data.incoming_uid \
		and after.deployment.generation == int(request.generation) + 1,
		"Tag: owner and trusted host recast the same bodies once to the next owned UID")
	check(after.party == data.before.party and after.party.size() <= 5, "Tag: body switch preserves the admitted party without another creature")
	check(after.commands.meter == verdict.delta.tether_commands.meter \
		and host.record.participants.get(str(peer), {}).get("tether_commands", {}) == verdict.delta.tether_commands,
		"Tag: owner and host consume exactly the parent's command meter state")
	for index in 2:
		var strike: Dictionary = strikes[index]
		var issuer := "command:%s:%s:%d:%s:%s:%d" % [request.encounter_id, commander_character,
			int(request.generation), strike.part, strike.attacker_uid, int(strike.generation)]
		check(host.impact_history.get(issuer, {}).get("seen", {}).has(str(int(request.sequence))) \
			and after.impact_history.get(issuer, {}).get("seen", {}).has(str(int(request.sequence))) \
			and observer.impact_history.get(issuer, {}).get("seen", {}).has(str(int(request.sequence))),
			"Tag: owner and joined observer consume the actual %s child impact once" % strike.part)
	check(after.enemy_hp == verdict.delta.hp, "Tag: the owner consumes the parent absolute HP without another debit")
	print("TAG actual family observation: ", JSON.stringify({"owner":after,"host":host,"before":host_before}))
	if OS.get_cmdline_user_args().has("--capture-combat-hud"):
		_ok(await step(commander, "op_tonic_hud_capture", {"name":"after-tag"}), "HUD: actual incoming creature after accepted Tag")
	_ok(await step(commander, "op_tag_replay"), "Tag: submit the same original again")
	var replay: Dictionary = await probe(0, "op_tag_state", args)
	check(replay.original.get("admission", {}) == original.get("admission", {}) \
		and replay.original.get("outcome", {}) == original.get("outcome", {}) \
		and replay.record.opponent.hp == host.record.opponent.hp \
		and replay.record.participants.get(str(peer), {}).get("tether_commands", {}) \
		== host.record.participants.get(str(peer), {}).get("tether_commands", {}),
		"Tag: duplicate submission cannot debit HP or meter or replace the retained parent")
	for i in [1,0]: _ok(await step(i, "press", {"action":"combat_run"}), "Tag: peer %d normally leaves the proof fight" % i)


func _tonic_seconds(state: Dictionary) -> float:
	for owned: Dictionary in state.get("owned", {}).values():
		for buff: Dictionary in owned.get("buffs", []):
			if buff.get("id") == "attack_tonic": return float(buff.get("remaining_s", 0.0))
	return 0.0


func _tonic_item_original(commander: int = 1) -> bool:
	var owner_state: Dictionary = await _state(commander)
	var commander_character := _guest_character if commander == 1 else str(owner_state.get("character_id", ""))
	check(not commander_character.is_empty(), "tonic: commander has its actual stable character")
	if commander_character.is_empty(): return false
	if not _ok(await step(commander, "op_tonic_pouch"), "tonic: production personal pouch assignment saves"): return false
	_ok(await step(0, "deploy_creature"), "tonic: host deploys its actual owned creature")
	if not _ok(await step(0, "op_tonic_target"), "tonic: normal interact opens a real canonical wild fight"): return false
	var encounter: Dictionary = await probe(0, "encounter")
	var id := str(encounter.get("id", ""))
	if id.is_empty():
		check(false, "tonic: actual host encounter identity is required")
		return false
	_ok(await step(1, "teleport", {"at":encounter.get("opponent_pos", [])}), "tonic: existing proximity fixture reaches the shared fight")
	_ok(await step(1, "deploy_creature"), "tonic: guest deploys its same admitted owned creature")
	if not _ok(await step(1, "join_encounter", {"encounter_id":id}), "tonic: guest joins the host's exact record"): return false
	var before_mastery: Dictionary = (await _state(commander)).get("mastery", {}).get("live", {})
	var hits: Dictionary = await step(commander, "op_tonic_hits")
	if hits.get("verdict") != "PASS":
		# Retain the exact live host proposal/journal bindings at this failed
		# return; guest readiness does not expose the host settlement gate.
		var guest: Dictionary = await probe(commander, "op_tag_state")
		var guest_peer := int(guest.get("peer", 0))
		print("TONIC failed hits host observation: ", JSON.stringify(await probe(0,
			"op_tag_state", {"encounter_id":id, "peer":guest_peer})))
		# Existing read-only host probe retains original action/timing/geometry
		# and the actual guest admission. This is post-checkpoint state, never
		# a claim about the strike-time body or a new accepted boundary.
		print("TONIC failed hits host encounter post-checkpoint: ", JSON.stringify(await probe(0,
			"encounter", {"admission_peer_id":guest_peer})))
	if not _ok(hits, "tonic: normal accepted quick hits earn Item meter"): return false
	if OS.get_cmdline_user_args().has("--capture-combat-hud"):
		_ok(await step(commander, "op_tonic_hud_capture", {"name":"earned-command"}), "HUD: actual earned command and creature meters before Item")
	var retained: Array = (await _state(0)).get("mastery", {}).get("retained", {}).get(commander_character, [])
	var seen := {}
	for event: Dictionary in retained:
		var uid := str(event.get("attacker_uid", ""))
		var move := str(event.get("move_id", ""))
		var action := str(event.get("action_id", ""))
		if not before_mastery.has(uid) or seen.has(action) or float(event.get("applied_damage", 0.0)) <= 0.0: continue
		if _mastery_uid.is_empty():
			_mastery_uid = uid
			_earned_mastery = {"uses":before_mastery[uid].uses.duplicate(true), "receipts":before_mastery[uid].receipts.duplicate(true)}
		if uid != _mastery_uid: continue
		seen[action] = true
		if not _earned_mastery.receipts.has(move): _earned_mastery.receipts[move] = []
		if not _earned_mastery.receipts[move].has(action):
			_earned_mastery.receipts[move].append(action)
			# Probe/save JSON counts are floats; Dictionary equality keeps types.
			_earned_mastery.uses[move] = float(_earned_mastery.uses.get(move, 0.0)) + 1.0
	check(not seen.is_empty(), "mastery: actual landed quick hits retain unique creature-owned mastery obligations")
	print("MASTERY actual earned expectation: ", JSON.stringify({"uid":_mastery_uid, "before":before_mastery, "retained":retained, "earned":_earned_mastery}))
	_ok(await step(commander, "op_tonic_clear"), "tonic: existing proximity fixture clears reach while previous actual HP writes settle")
	var ready := false
	for poll in 20:
		var current: Dictionary = (await _state(0)).get("tonic", {}).get("readiness", {}).get(commander_character, {})
		if current.get("admission") == true and current.get("vitals_pending") == false:
			ready = true
			break
		await step(0, "wait", {"frames":30})
	check(ready, "tonic: host confirms the actual previous owner HP saves are settled before writer refusal")
	if not ready: return false
	var pending: Dictionary = await step(commander, "op_tonic_item")
	if not _ok(pending, "tonic: production Item request preserves its original while owner save refuses"): return false
	var guest: Dictionary = (await _state(commander)).get("tonic", {})
	var host: Dictionary = (await _state(0)).get("tonic", {})
	var original: Dictionary = host.get("rows", {}).get(commander_character, {})
	print("TONIC original actual owner/host: ", JSON.stringify({"owner":guest, "host":host}))
	check(original.get("status") == "pending" and not str(original.get("receipt", "")).is_empty(),
		"tonic: host journal retains the precise original awaiting owner TRUE BOOL")
	check(_tonic_seconds(guest) == 0.0 and host.get("projected", {}).get(commander_character, {}).is_empty(),
		"tonic: owner save refusal installs no owner or authoritative effect")
	check(int(guest.get("stock", -1)) == 1 and int(guest.get("disk_stock", -1)) == 2 \
		and guest.get("fenced") == true and not (guest.get("disk_receipts", []) as Array).has(str(original.get("receipt", ""))) \
		and guest.get("saved_result", {}).get("saved") != true,
		"tonic: failed owner save fences the pending debit, keeps disk unchanged and produces no saved result")
	_tonic_receipt = str(original.get("receipt", ""))
	_tonic_uid = str(original.get("uid", ""))
	_ok(await step(commander, "op_tonic_writer", {"block":false}), "tonic: original actual owner writer is restored")
	if not _ok(await step(commander, "op_tonic_retry"), "tonic: retry sends the same original request"): return false
	for poll in 30:
		guest = (await _state(commander)).get("tonic", {})
		host = (await _state(0)).get("tonic", {})
		if guest.get("saved_result", {}).get("saved") == true and host.get("rows", {}).get(commander_character, {}).get("status") == "accepted": break
		await step(0, "wait", {"frames":30})
	check(guest.get("saved_result", {}).get("saved") == true \
		and guest.get("saved_result", {}).get("receipt") == _tonic_receipt,
		"tonic: actual TRUE owner-write BOOL precedes the exact saved result")
	check(int(guest.get("stock", -1)) == 1 and int(guest.get("disk_stock", -1)) == 1 \
		and (guest.get("disk_receipts", []) as Array).has(_tonic_receipt),
		"tonic: real owner disk holds one debit and the original receipt")
	check(host.get("rows", {}).get(commander_character, {}).get("receipt") == _tonic_receipt \
		and host.get("rows", {}).get(commander_character, {}).get("request") == original.get("request"),
		"tonic: retry neither substitutes nor duplicates the accepted original")
	_tonic_remaining = _tonic_seconds(guest)
	check(_tonic_remaining > 0.0 and _tonic_remaining <= 90.0, "tonic: actual saved effect starts its authored timer")
	return _tonic_remaining > 0.0


## Same Snare guards for the original guest proof and bounded host mode.
## No catch roll, status refresh, HP, meter or timer grant.
func _prove_snare(commander: int) -> void:
	for attempt in 1:
		if not _ok(await step(0, "deploy_creature"), "Snare: host deploys its same admitted companion"): break
		if not _ok(await step(0, "op_tonic_target"), "Snare: host normally engages an actual live wild"): break
		var encounter: Dictionary = await probe(0, "encounter")
		if not _ok(await step(1, "teleport", {"at":encounter.get("opponent_pos", [])}), "Snare: existing proximity setup reaches the host fight"): break
		if not _ok(await step(1, "deploy_creature"), "Snare: guest deploys its same admitted companion"): break
		if not _ok(await step(1, "join_encounter", {"encounter_id":str(encounter.get("id", ""))}), "Snare: guest joins the exact host encounter"): break
		var owner: Dictionary = await probe(commander, "op_tag_state", {"request":{}})
		var commander_character := str(owner.get("character_id", ""))
		check(not commander_character.is_empty(), "Snare: commander has its actual stable character")
		var peer := int(owner.peer)
		check(float(owner.commands.get("meter", -1.0)) == 0.0, "Snare: fresh admitted encounter starts with zero command meter")
		var hit_slot := "charged" if OS.get_cmdline_user_args().has("--charged-command-hits") else "quick"
		if not _ok(await step(commander, "op_tonic_hits", {"command_id":"snare", "slot":hit_slot}), "Snare: ordinary %s hits earn the authored cost within eight attempts" % hit_slot): break
		var args := {"peer":peer, "character_id":commander_character, "request":{}, "snare":true}
		var before: Dictionary = await probe(0, "op_tag_state", args)
		var cost := float(preload("res://scripts/combat/tether_commands.gd").config().commands.snare.cost)
		var commands_before: Dictionary = before.record.get("participants", {}).get(str(peer), {}).get("tether_commands", {})
		check(float(commands_before.get("meter", -1.0)) >= cost and before.record.get("phase") == "active" \
			and before.record.get("kind") == "wild" and float(before.record.get("opponent", {}).get("hp", 0.0)) > 0.0,
			"Snare: trusted host has earned meter and the same living admitted wild before the request")
		var cast: Dictionary = await step(commander, "op_tonic_snare")
		print("SNARE actual request observation: ", JSON.stringify(cast))
		if not _ok(cast, "Snare: production TetherCommandInput request receives its accepted host receipt"): break
		var request: Dictionary = cast.data.request
		args.request = request
		var host: Dictionary = await probe(0, "op_tag_state", args)
		var observed: Dictionary = host.snare
		var receipt: Dictionary = observed.get("last_receipt", {})
		var status: Dictionary = host.record.get("opponent", {}).get("tether_snare", {})
		var commands_after: Dictionary = host.record.get("participants", {}).get(str(peer), {}).get("tether_commands", {})
		var parent := "command:%s:%s:%d:%d" % [request.encounter_id, commander_character, int(request.generation), int(request.sequence)]
		check(receipt.get("command_committed") == true and receipt.get("command_id") == "snare" \
			and receipt.get("action_id") == parent and receipt.get("encounter_id") == request.encounter_id \
			and receipt.get("character_id") == commander_character and receipt.get("attacker_uid") == owner.deployment.creature_uid \
			and receipt.get("generation") == request.generation and receipt.get("sequence") == request.sequence,
			"Snare: host retains the exact commander's accepted original receipt and deployment")
		check(request.generation == owner.deployment.generation and request.encounter_id == before.encounter_id \
			and host.body_instance == before.body_instance and cast.data.after.party == owner.party,
			"Snare: request preserves the admitted encounter, companion and body")
		check(float(commands_before.get("meter", -1.0)) - float(commands_after.get("meter", -1.0)) == cost \
			and cast.data.before.get("meter") == commands_before.get("meter") \
			and cast.data.after.commands.get("meter") == commands_after.get("meter"),
			"Snare: owner and trusted host observe exactly one authored command-meter debit")
		check(host.record.get("phase") == "active" and float(host.record.opponent.get("hp", 0.0)) > 0.0 \
			and host.record.opponent.get("card", {}).get("uid") == before.record.opponent.get("card", {}).get("uid") \
			and host.record.opponent.get("body_generation") == before.record.opponent.get("body_generation") \
			and host.record.opponent.get("hp") == before.record.opponent.get("hp") \
			and cast.data.after.enemy_hp == host.record.opponent.get("hp"),
			"Snare: the same living target loses no HP from the command")
		check(observed.get("target_current") == true and status.get("kind") == "snare" and status.get("character_id") == commander_character \
			and status.get("target_uid") == host.record.opponent.get("card", {}).get("uid") \
			and status.get("target_generation") == host.record.opponent.get("body_generation") \
			and observed.get("target_uid") == status.get("target_uid") \
			and observed.get("target_generation") == status.get("target_generation") \
			and observed.get("status") == status and int(status.get("until_ms", 0)) > int(observed.get("observed_ms", 0)) \
			and float(observed.get("movement_multiplier", 1.0)) > 0.0 and float(observed.get("movement_multiplier", 1.0)) < 1.0,
			"Snare: unexpired admitted target status reaches the actual wild movement consumer")
		check(float(observed.get("catch_bonuses", {}).get(commander_character, 0.0)) > 0.0 \
			and status.get("catch_grants", {}).has(commander_character),
			"Snare: actual host catch reader increases only the commander's stable-character chance")
		check(observed.get("catch_bonuses", {}).size() == 2, "Snare: host catch reader observes both actual participants")
		for character: String in observed.get("catch_bonuses", {}):
			if character == commander_character: continue
			check(float(observed.catch_bonuses[character]) == 0.0 and not status.get("catch_grants", {}).has(character),
				"Snare: participant without its own grant receives no catch bonus")
		print("SNARE actual host observation: ", JSON.stringify({"request":request, "before":before, "host":host}))
		for i in [1, 0]: _ok(await step(i, "press", {"action":"combat_run"}), "Snare: peer %d normally leaves the proof fight" % i)


## Same Rally guards for the original guest proof and fresh host mode.
## The guest remains the actual non-caster bonus control.
func _prove_rally(commander: int) -> void:
	for _attempt in 1:
		if not _ok(await step(0, "deploy_creature"), "Rally: host deploys its same admitted companion"): break
		if not _ok(await step(0, "op_tonic_target"), "Rally: host normally engages an actual live wild"): break
		var encounter: Dictionary = await probe(0, "encounter")
		if not _ok(await step(1, "teleport", {"at":encounter.get("opponent_pos", [])}), "Rally: existing proximity setup reaches the host fight"): break
		if not _ok(await step(1, "deploy_creature"), "Rally: guest deploys its same admitted companion"): break
		if not _ok(await step(1, "join_encounter", {"encounter_id":str(encounter.get("id", ""))}), "Rally: guest joins the exact host encounter"): break
		var owner: Dictionary = await probe(commander, "op_tag_state", {"request":{}})
		var commander_character := str(owner.get("character_id", ""))
		check(not commander_character.is_empty(), "Rally: commander has its actual stable character")
		var peer := int(owner.peer)
		check(float(owner.commands.get("meter", -1.0)) == 0.0, "Rally: fresh admitted encounter starts with zero command meter")
		if float(owner.commands.get("meter", -1.0)) != 0.0: break
		if not _ok(await step(commander, "op_tonic_hits", {"command_id":"rally"}), "Rally: ordinary quick hits earn the authored cost within eight attempts"): break
		var args := {"peer":peer, "character_id":commander_character, "request":{}, "rally":true}
		var before: Dictionary = await probe(0, "op_tag_state", args)
		var row: Dictionary = preload("res://scripts/combat/tether_commands.gd").config().commands.rally
		var cost := float(row.cost)
		var commands_before: Dictionary = before.record.get("participants", {}).get(str(peer), {}).get("tether_commands", {})
		var ready: bool = float(commands_before.get("meter", -1.0)) >= cost and before.record.get("phase") == "active" \
			and before.record.get("kind") == "wild" and float(before.record.get("opponent", {}).get("hp", 0.0)) > 0.0
		check(ready, "Rally: trusted host has earned meter and the same living admitted wild before the request")
		if not ready: break
		var cast: Dictionary = await step(commander, "op_tonic_rally")
		print("RALLY actual request observation: ", JSON.stringify(cast))
		if not _ok(cast, "Rally: production TetherCommandInput request receives its accepted host receipt"): break
		var request: Dictionary = cast.data.request
		args.request = request
		var host: Dictionary = await probe(0, "op_tag_state", args)
		var observed: Dictionary = host.rally
		var receipt: Dictionary = observed.get("last_receipt", {})
		var commands_after: Dictionary = host.record.get("participants", {}).get(str(peer), {}).get("tether_commands", {})
		var parent := "command:%s:%s:%d:%d" % [request.encounter_id, commander_character, int(request.generation), int(request.sequence)]
		check(receipt.get("command_committed") == true and receipt.get("command_id") == "rally" \
			and receipt.get("action_id") == parent and receipt.get("encounter_id") == request.encounter_id \
			and receipt.get("character_id") == commander_character and receipt.get("attacker_uid") == owner.deployment.creature_uid \
			and receipt.get("generation") == request.generation and receipt.get("sequence") == request.sequence,
			"Rally: host retains the exact commander's accepted original receipt and deployment")
		check(request.generation == owner.deployment.generation and request.encounter_id == before.encounter_id \
			and observed.get("binding") == before.rally.get("binding") \
			and observed.get("binding", {}).get("character_id") == commander_character \
			and observed.get("binding", {}).get("creature_uid") == owner.deployment.creature_uid \
			and observed.get("binding", {}).get("deployment_generation") == request.generation \
			and host.body_instance == before.body_instance and cast.data.after.body_instance == owner.body_instance \
			and cast.data.after.deployment == owner.deployment and cast.data.after.party == owner.party,
			"Rally: request preserves the admitted encounter, companion, body and party")
		check(float(commands_before.get("meter", -1.0)) - float(commands_after.get("meter", -1.0)) == cost \
			and cast.data.before.get("meter") == commands_before.get("meter") \
			and cast.data.after.commands.get("meter") == commands_after.get("meter"),
			"Rally: owner and trusted host observe exactly one authored command-meter debit")
		check(host.record.get("phase") == "active" and float(host.record.opponent.get("hp", 0.0)) > 0.0 \
			and host.record.opponent.get("card", {}).get("uid") == before.record.opponent.get("card", {}).get("uid") \
			and host.record.opponent.get("body_generation") == before.record.opponent.get("body_generation") \
			and host.record.opponent.get("hp") == before.record.opponent.get("hp") \
			and cast.data.after.enemy_hp == host.record.opponent.get("hp"),
			"Rally: the same living target loses no HP from the trainer's command")
		var own: Dictionary = observed.get("modifiers", {}).get(commander_character, {})
		check(int(commands_after.get("rally_until_ms", 0)) > int(observed.get("observed_ms", 0)) \
			and float(own.get("damage", 1.0)) > 1.0 and float(own.get("wind_regen", 1.0)) > 1.0 \
			and is_equal_approx(float(own.get("damage", 1.0)), float(row.damage_multiplier)) \
			and is_equal_approx(float(own.get("wind_regen", 1.0)), float(row.wind_regen_multiplier)),
			"Rally: unexpired actual host readers return the commander's authored damage and wind bonuses")
		check(observed.get("modifiers", {}).size() == 2, "Rally: host readers observe both actual participants")
		for character: String in observed.get("modifiers", {}):
			var baseline: Dictionary = before.rally.get("modifiers", {}).get(character, {})
			check(baseline.get("damage") == 1.0 and baseline.get("wind_regen") == 1.0, "Rally: participant had no bonus before this request")
			if character == commander_character: continue
			var other: Dictionary = observed.modifiers[character]
			check(other.get("damage") == 1.0 and other.get("wind_regen") == 1.0, "Rally: other participant receives neither bonus")
		print("RALLY actual host observation: ", JSON.stringify({"request":request, "before":before, "host":host}))
		for i in [1, 0]: _ok(await step(i, "press", {"action":"combat_run"}), "Rally: peer %d normally leaves the proof fight" % i)
