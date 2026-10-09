extends SceneTree

## Batch driver for tests/smoke_tidewake_named_inworld_c2.gd: runs one fight
## per child process (a fresh world each time) for a seed range and writes
## every child's `TIDEWAKE INWORLD C2 {...}` line to one JSON-lines file, so a
## render.yml headless dispatch can carry a whole (trainer, starter, pilot)
## C2 cell. Evidence driver only; it asserts nothing itself.
##
##   godot --headless --path . --script tests/batch_tidewake_named_inworld_c2.gd -- \
##     --trainer=water_trainer_nerissa --starter=ripplet --policy=READER \
##     --seeds=1-24 [--party-level=<override>] [--gear-tier=<tier>] [--gear-upgrade=0..3] \
##     --out=user://c2/nerissa_ripplet_READER.jsonl
const SMOKE := "res://tests/smoke_tidewake_named_inworld_c2.gd"
const GEAR := preload("res://tests/helpers/f33_gear_fixture.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	# Optional affected logic precedes the same original world fight; a failed
	# unit child must stop this proof rather than produce a collector success.
	if OS.get_cmdline_user_args().has("--with-reward-owner-units"):
		var selectors := PackedStringArray([
			"test_actor_vitals_authority.gd", "test_altar_essence_quote_bridge.gd", "test_autosave_fallback.gd",
			"test_cloudreach_no_legendary_offer.gd", "test_f18_arrival_lifecycle.gd", "test_f19_boss_delivery.gd",
			"test_f19_participant_delivery.gd", "test_f24_host_commands.gd", "test_forward_camp.gd",
			"test_foundation_combat_manager_context.gd", "test_foundation_resource_save.gd", "test_foundation_retry_admission.gd",
			"test_guest_idle_combat_authority.gd", "test_multiplayer_identity_0912.gd", "test_ordinary_actor_vitals_recovery.gd",
			"test_original_starter_guest_commit.gd", "test_owner_passive_sync.gd", "test_portal_director_lookup.gd",
			"test_portal_request_expiry.gd", "test_prepared_training_owner_identity.gd", "test_rematch_solo_admission.gd",
			"test_session_physical_timeout.gd", "test_session_reconnect_reservation.gd", "test_session_snapshot.gd",
			"test_session_transport.gd", "test_starter_install.gd", "test_station_reach_origin.gd", "test_steam_lobby.gd",
			"test_stormwood_realm_transition.gd", "test_tm_teach_transaction.gd", "test_training_guard_lifetime.gd",
			"test_water_encounter_runtime_data.gd"])
		var unit_output: Array = []
		var unit_code := OS.execute(OS.get_executable_path(), PackedStringArray([
			"--headless", "--path", ProjectSettings.globalize_path("res://"), "--audio-driver", "Dummy",
			"--script", "res://tests/run_tests.gd", "--", "--only=" + ",".join(selectors)]), unit_output, true)
		for chunk: Variant in unit_output: print(str(chunk))
		if unit_code != 0:
			quit(unit_code)
			return
	var trainer := "water_trainer_nerissa"
	var starter := "ripplet"
	var policy := "READER"
	var first := 1
	var last := 24
	var level_arg := ""
	var out := "user://c2_inworld.jsonl"
	var gear: Dictionary = GEAR.from_args()
	var gear_label: String = GEAR.label(str(gear.tier), int(gear.upgrade))
	var gear_args := PackedStringArray()
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--trainer="): trainer = arg.trim_prefix("--trainer=")
		elif arg.begins_with("--starter="): starter = arg.trim_prefix("--starter=")
		elif arg.begins_with("--policy="): policy = arg.trim_prefix("--policy=")
		elif arg.begins_with("--party-level="): level_arg = arg
		elif arg.begins_with("--gear-tier=") or arg.begins_with("--gear-upgrade="): gear_args.append(arg)
		elif arg.begins_with("--out="): out = arg.trim_prefix("--out=")
		elif arg.begins_with("--seeds="):
			var span := arg.trim_prefix("--seeds=").split("-")
			first = int(span[0])
			last = int(span[1]) if span.size() > 1 else first
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out.get_base_dir()))
	var file := FileAccess.open(out, FileAccess.WRITE)
	var failures := 0
	var child_failures := 0
	for seed_value in range(first, last + 1):
		var json := "user://c2_child_%d.json" % seed_value
		var args := PackedStringArray(["--headless", "--path", ProjectSettings.globalize_path("res://"), "--fixed-fps", "60",
			"--script", SMOKE, "--", "--trainer=" + trainer, "--starter=" + starter, "--policy=" + policy,
			"--seed=%d" % seed_value, "--json=" + ProjectSettings.globalize_path(json)])
		# The child owns its authored default. Forward an override only when
		# actually supplied, rather than silently replacing it with legacy L43.
		if not level_arg.is_empty(): args.append(level_arg)
		args.append_array(gear_args)
		var output: Array = []
		var started := Time.get_ticks_msec()
		var code := OS.execute(OS.get_executable_path(), args, output, true)
		if code != 0: child_failures += 1
		var line := ""
		for chunk: Variant in output:
			for row: String in str(chunk).split("\n"):
				if row.begins_with("TIDEWAKE INWORLD C2 "):
					line = row.trim_prefix("TIDEWAKE INWORLD C2 ")
		if line.is_empty():
			failures += 1
			line = JSON.stringify({"trainer": trainer, "starter": starter, "pilot": policy, "seed": seed_value,
				"gear": gear_label,
				"error": "no result line (exit %d)" % code})
		file.store_line(line)
		file.flush()
		print("BATCH seed=%d exit=%d wall_s=%.0f %s" % [seed_value, code, (Time.get_ticks_msec() - started) / 1000.0, line])
	file.close()
	print("BATCH DONE trainer=%s starter=%s policy=%s seeds=%d-%d missing=%d failed_children=%d out=%s gear=%s" % [trainer, starter, policy, first, last,
		failures, child_failures, ProjectSettings.globalize_path(out), gear_label])
	quit(0 if failures == 0 and child_failures == 0 else 1)
