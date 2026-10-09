extends SceneTree

## Batch driver for tests/smoke_tidewake_named_inworld_c2.gd: runs one fight
## per child process (a fresh world each time) for a seed range and writes
## every child's `TIDEWAKE INWORLD C2 {...}` line to one JSON-lines file, so a
## render.yml headless dispatch can carry a whole (trainer, starter, pilot)
## C2 cell. Evidence driver only; it asserts nothing itself.
##
##   godot --headless --path . --script tests/batch_tidewake_named_inworld_c2.gd -- \
##     --trainer=water_trainer_nerissa --starter=ripplet --policy=READER \
##     --seeds=1-24 [--party-level=43] --out=user://c2/nerissa_ripplet_READER.jsonl
const SMOKE := "res://tests/smoke_tidewake_named_inworld_c2.gd"


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var trainer := "water_trainer_nerissa"
	var starter := "ripplet"
	var policy := "READER"
	var first := 1
	var last := 24
	var level := 43
	var out := "user://c2_inworld.jsonl"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--trainer="): trainer = arg.trim_prefix("--trainer=")
		elif arg.begins_with("--starter="): starter = arg.trim_prefix("--starter=")
		elif arg.begins_with("--policy="): policy = arg.trim_prefix("--policy=")
		elif arg.begins_with("--party-level="): level = int(arg.trim_prefix("--party-level="))
		elif arg.begins_with("--out="): out = arg.trim_prefix("--out=")
		elif arg.begins_with("--seeds="):
			var span := arg.trim_prefix("--seeds=").split("-")
			first = int(span[0])
			last = int(span[1]) if span.size() > 1 else first
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out.get_base_dir()))
	var file := FileAccess.open(out, FileAccess.WRITE)
	var failures := 0
	for seed_value in range(first, last + 1):
		var json := "user://c2_child_%d.json" % seed_value
		var args := PackedStringArray(["--headless", "--path", ProjectSettings.globalize_path("res://"), "--fixed-fps", "60",
			"--script", SMOKE, "--", "--trainer=" + trainer, "--starter=" + starter, "--policy=" + policy,
			"--seed=%d" % seed_value, "--party-level=%d" % level, "--json=" + ProjectSettings.globalize_path(json)])
		var output: Array = []
		var started := Time.get_ticks_msec()
		var code := OS.execute(OS.get_executable_path(), args, output, true)
		var line := ""
		for chunk: Variant in output:
			for row: String in str(chunk).split("\n"):
				if row.begins_with("TIDEWAKE INWORLD C2 "):
					line = row.trim_prefix("TIDEWAKE INWORLD C2 ")
		if line.is_empty():
			failures += 1
			line = JSON.stringify({"trainer": trainer, "starter": starter, "pilot": policy, "seed": seed_value,
				"error": "no result line (exit %d)" % code})
		file.store_line(line)
		file.flush()
		print("BATCH seed=%d exit=%d wall_s=%.0f %s" % [seed_value, code, (Time.get_ticks_msec() - started) / 1000.0, line])
	file.close()
	print("BATCH DONE trainer=%s starter=%s policy=%s seeds=%d-%d missing=%d out=%s" % [trainer, starter, policy, first, last,
		failures, ProjectSettings.globalize_path(out)])
	quit(0 if failures == 0 else 1)
