extends RefCounted

## Production-save checkpoint boundaries for `tests/smoke_four_biome_continuous.gd`.
##
## The earned four-biome run is hours long; render.yml caps one run at 150 min.
## These boundaries let the SAME earned run execute in pieces: at each chapter
## handoff the driver writes a production save (`Game.save_game`, the menu Save
## call) and exports it in the `tests/fixtures/earned_saves/checkpoints/<name>/`
## layout (save/ + receipts/<boundary>.json + README.txt). A later process
## resumes with `--resume-from=<dir|name>[:<boundary>]`, loads it through the
## production title's Load list (the earned_chain_runner path), verifies the
## receipt against the loaded party/flags, and continues with the boundary's
## next segment. Pure logic lives here so `tests/test_four_biome_checkpoints.gd`
## can test it without a world.

## Ordered. `reached` is the driver's own `reached` label at that point;
## `next` names the segment the driver runs after resuming there.
const BOUNDARIES := [
	{"name": "hall", "reached": "warden_arena_entered", "next": "warden"},
	{"name": "c1_arrival", "reached": "cloudreach_arrived", "next": "cloudreach"},
	{"name": "stormwood_arrived", "reached": "stormwood_arrived", "next": "stormwood"},
	{"name": "water_arrived", "reached": "water_arrived", "next": "water_opening"},
]
## Slot the checkpoint save is written to and resumed from; the same chain slot
## `tools/earned_saves/earned_chain_runner.gd` uses, so both tools share saves.
const CHECKPOINT_SLOT := 1
const FIXTURE_ROOT := "res://tests/fixtures/earned_saves/checkpoints/"
const RECEIPT_KIND := "four_biome_checkpoint"


static func boundary_names() -> Array:
	var out: Array = []
	for b: Dictionary in BOUNDARIES:
		out.append(b["name"])
	return out


static func boundary_index(name: String) -> int:
	for i in BOUNDARIES.size():
		if BOUNDARIES[i]["name"] == name:
			return i
	return -1


static func next_segment(name: String) -> String:
	var i := boundary_index(name)
	return "" if i < 0 else str(BOUNDARIES[i]["next"])


static func reached_label(name: String) -> String:
	var i := boundary_index(name)
	return "" if i < 0 else str(BOUNDARIES[i]["reached"])


## Parses the checkpoint args out of the user args. Returns
## {resume_source, resume_boundary, stop_at, checkpoint_dir, no_checkpoints,
##  requested, errors}.
static func parse_args(args: PackedStringArray) -> Dictionary:
	var out := {"resume_source": "", "resume_boundary": "", "stop_at": "",
		"checkpoint_dir": "", "no_checkpoints": false, "requested": false, "errors": []}
	for arg: String in args:
		if arg.begins_with("--resume-from="):
			var value := arg.substr("--resume-from=".length())
			# `name:boundary` -- but an absolute Windows path may carry a drive
			# colon, so only a trailing `:<known boundary>` splits.
			var colon := value.rfind(":")
			if colon > 0 and boundary_index(value.substr(colon + 1)) >= 0:
				out["resume_boundary"] = value.substr(colon + 1)
				value = value.substr(0, colon)
			elif colon > 0 and not value.substr(colon + 1).contains("/") \
					and not value.substr(colon + 1).contains("\\"):
				(out["errors"] as Array).append("unknown resume boundary '%s' (known: %s)" % [
					value.substr(colon + 1), ", ".join(boundary_names())])
			out["resume_source"] = value
			out["requested"] = true
			if value.is_empty():
				(out["errors"] as Array).append("--resume-from needs a checkpoint dir or name")
		elif arg.begins_with("--stop-at="):
			out["stop_at"] = arg.substr("--stop-at=".length())
			out["requested"] = true
			if boundary_index(out["stop_at"]) < 0:
				(out["errors"] as Array).append("unknown --stop-at boundary '%s' (known: %s)" % [
					out["stop_at"], ", ".join(boundary_names())])
		elif arg.begins_with("--checkpoint-dir="):
			out["checkpoint_dir"] = arg.substr("--checkpoint-dir=".length())
			out["requested"] = true
			if out["checkpoint_dir"].is_empty():
				(out["errors"] as Array).append("--checkpoint-dir needs a path")
		elif arg == "--no-checkpoints":
			out["no_checkpoints"] = true
	if not str(out["resume_boundary"]).is_empty() and not str(out["stop_at"]).is_empty() \
			and boundary_index(out["stop_at"]) < boundary_index(out["resume_boundary"]):
		(out["errors"] as Array).append("--stop-at=%s is before the resume boundary %s" % [
			out["stop_at"], out["resume_boundary"]])
	if bool(out["no_checkpoints"]) and not str(out["stop_at"]).is_empty():
		(out["errors"] as Array).append("--no-checkpoints cannot be combined with --stop-at")
	return out


## A checkpoint source: an existing absolute/user:// dir, else a name under the
## checkpoint dir, else a name under the repo's earned_saves checkpoints.
static func resolve_source(source: String, checkpoint_dir: String) -> String:
	for candidate: String in [source,
			checkpoint_dir.path_join(source) if not checkpoint_dir.is_empty() else "",
			FIXTURE_ROOT + source]:
		if candidate.is_empty():
			continue
		if DirAccess.dir_exists_absolute(_abs(candidate)) \
				and DirAccess.dir_exists_absolute(_abs(candidate.path_join("save"))):
			return candidate
	return ""


## `--resume-from` serves two checkpoint kinds; this tells them apart by what
## the named directory holds, so one argument is never ambiguous:
## - RESUME_RELOAD_TRANSITION: `checkpoint.json` + `save/`, the Meadows
##   reload-transition checkpoint the smoke's `_reload_transition` writes under
##   user://four_biome_checkpoints/<label>_<pid>/ (resumed by the smoke's
##   `_resume_checkpoint`; stops after the Hall; never closes proof);
## - RESUME_BOUNDARY: a chapter-boundary checkpoint (`receipts/` + `save/`),
##   given as a dir or a bare name `resolve_source` finds.
## A `:<boundary>` suffix, a dir without `checkpoint.json`, or any bare name
## means RESUME_BOUNDARY (its own resolve/receipt checks then apply). A dir
## holding both `checkpoint.json` and `receipts/` without a suffix is refused.
## Returns {kind, error}.
const RESUME_RELOAD_TRANSITION := "reload_transition"
const RESUME_BOUNDARY := "chapter_boundary"
const RELOAD_CHECKPOINT_META := "checkpoint.json"


static func classify_resume(source: String, explicit_boundary: String) -> Dictionary:
	if source.is_empty():
		return {"kind": "", "error": "--resume-from needs a checkpoint dir or name"}
	if not explicit_boundary.is_empty():
		return {"kind": RESUME_BOUNDARY, "error": ""}
	if not FileAccess.file_exists(_abs(source.path_join(RELOAD_CHECKPOINT_META))):
		return {"kind": RESUME_BOUNDARY, "error": ""}
	if DirAccess.dir_exists_absolute(_abs(source.path_join("receipts"))):
		return {"kind": "", "error": ("%s holds both %s (reload-transition checkpoint) and receipts/ "
			+ "(chapter-boundary checkpoint); add :<boundary> to resume it as a chapter boundary") % [
			source, RELOAD_CHECKPOINT_META]}
	return {"kind": RESUME_RELOAD_TRANSITION, "error": ""}


## The boundary to resume a checkpoint at: the explicit one, else the latest
## boundary that has a receipt in receipts/.
static func pick_boundary(checkpoint: String, explicit: String) -> String:
	if not explicit.is_empty():
		return explicit if FileAccess.file_exists(_abs(receipt_path(checkpoint, explicit))) else ""
	var best := ""
	for b: Dictionary in BOUNDARIES:
		if FileAccess.file_exists(_abs(receipt_path(checkpoint, b["name"]))):
			best = b["name"]
	return best


static func receipt_path(checkpoint: String, boundary: String) -> String:
	return checkpoint.path_join("receipts").path_join(boundary + ".json")


static func read_receipt(path: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(_abs(path))
	var parsed: Variant = JSON.parse_string(text)
	return parsed if parsed is Dictionary else {}


static func write_json(path: String, data: Dictionary) -> bool:
	DirAccess.make_dir_recursive_absolute(_abs(path.get_base_dir()))
	var file := FileAccess.open(_abs(path), FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data, "  ", true))
	file.close()
	return true


## Party ids a receipt promises. Accepts this driver's receipts (`party`) and
## `earned_chain_runner.gd` receipts (`party_after`) such as seed4_hall's.
static func receipt_party_ids(receipt: Dictionary) -> Array:
	var rows: Variant = receipt.get("party", receipt.get("party_after", []))
	var out: Array = []
	for row: Variant in (rows if rows is Array else []):
		if row is Dictionary:
			out.append(str((row as Dictionary).get("uid", "")))
	return out


## Flags a receipt promises: this driver records every set flag; a chain
## runner receipt only has the segment's gained flags.
static func receipt_flags(receipt: Dictionary) -> Array:
	var flags: Variant = receipt.get("flags", receipt.get("flags_gained", []))
	return (flags as Array).duplicate() if flags is Array else []


## Refuses a load whose party or flags do not match the receipt. Returns the
## list of problems; empty means verified.
static func validate(receipt: Dictionary, boundary: String, loaded_party_ids: Array,
		loaded_flags: Array) -> Array:
	var problems: Array = []
	if receipt.is_empty():
		return ["checkpoint receipt is missing or unreadable"]
	var named := str(receipt.get("boundary", receipt.get("segment", "")))
	if named != boundary:
		problems.append("receipt names boundary '%s', expected '%s'" % [named, boundary])
	if receipt.has("passed") and not bool(receipt["passed"]):
		problems.append("receipt records a failed producing run")
	var want := receipt_party_ids(receipt)
	if want.is_empty():
		problems.append("receipt records no party")
	var a := want.duplicate()
	a.sort()
	var b := loaded_party_ids.duplicate()
	b.sort()
	if a != b:
		problems.append("loaded party %s does not match the receipt's party %s" % [str(b), str(a)])
	var missing: Array = []
	for flag: Variant in receipt_flags(receipt):
		if not loaded_flags.has(flag):
			missing.append(flag)
	if not missing.is_empty():
		problems.append("loaded save is missing receipt flags %s" % str(missing))
	return problems


## Key flags recorded separately for a reader: the chapter-handoff flags that
## are set at this boundary (a subset of `flags`, which holds every set flag).
static func key_flags(all_flags: Array) -> Array:
	var out: Array = []
	for flag: Variant in all_flags:
		var s := str(flag)
		if s.contains("warden") or s.contains("veridian") or s.contains("cloudreach") \
				or s.contains("storm") or s.contains("water") or s.contains("realm") \
				or s.contains("chapter") or s.contains("rift") or s.contains("tournament"):
			out.append(s)
	out.sort()
	return out


static func build_receipt(boundary: String, info: Dictionary) -> Dictionary:
	var flags: Array = (info.get("flags", []) as Array).duplicate()
	flags.sort()
	var resumed: Dictionary = info.get("resumed_from", {})
	var fixture_source := str(resumed.get("source", "")).begins_with(FIXTURE_ROOT)
	var statement := "Produced by tests/smoke_four_biome_continuous.gd through earned play only: " \
		+ "no fixture, seeded progress, flag/party/inventory write, teleport or HP pin in the run path."
	if not resumed.is_empty():
		statement += " This piece resumed from checkpoint '%s' at boundary '%s' through the production title Load; its earlier pieces are described by the carried receipts." % [
			resumed.get("source", ""), resumed.get("boundary", "")]
		if fixture_source:
			statement += " That resume source is a repo-stored earned save (tests/fixtures/earned_saves), itself produced by earned play (see its README.txt)."
	return {
		"kind": RECEIPT_KIND,
		"boundary": boundary,
		"reached": reached_label(boundary),
		"next_segment": next_segment(boundary),
		"passed": true,
		"commit": str(info.get("commit", "")),
		"world_seed": int(info.get("world_seed", 0)),
		"world_seed_env": str(info.get("world_seed_env", "")),
		"elapsed_seconds": float(info.get("elapsed_seconds", 0.0)),
		"cumulative_elapsed_seconds": float(info.get("cumulative_elapsed_seconds", 0.0)),
		"realm": str(info.get("realm", "")),
		"player": info.get("player", []),
		"game_day": int(info.get("game_day", 0)),
		"party": info.get("party", []),
		"key_flags": key_flags(flags),
		"flags": flags,
		"flags_total": flags.size(),
		"slot": CHECKPOINT_SLOT,
		"fixtures_used_in_run_path": false,
		"resumed_from": resumed,
		"resume_source_is_repo_fixture": fixture_source,
		"no_fixture_statement": statement,
	}


static func readme_text(name: String, boundary: String, receipt: Dictionary) -> String:
	return ("Four-biome checkpoint '%s' at boundary '%s' (reached=%s), written by\n" % [name, boundary, receipt.get("reached", "")]
		+ "tests/smoke_four_biome_continuous.gd at commit %s, world seed %s.\n\n" % [receipt.get("commit", ""), str(receipt.get("world_seed", 0))]
		+ "save/      = the game's own save directory after Game.save_game(%d) at this\n" % CHECKPOINT_SLOT
		+ "             boundary (slot %d is the chain slot, as in seed4_hall).\n" % CHECKPOINT_SLOT
		+ "receipts/  = per-boundary receipts (party, flags, seed, commit, elapsed).\n\n"
		+ "Resume the earned run from here (next segment: %s):\n" % receipt.get("next_segment", "")
		+ "  godot --headless --path . --script tests/smoke_four_biome_continuous.gd -- \\\n"
		+ "    --resume-from=<this dir>:%s [--stop-at=<boundary>] [--checkpoint-dir=<dir>]\n\n" % boundary
		+ str(receipt.get("no_fixture_statement", "")) + "\n")


## Exports `save_dir` into `<checkpoint_dir>/<name>/` in the earned_saves
## layout, carrying `carried` receipts (boundary -> dict) plus this one.
static func export_checkpoint(save_dir: String, checkpoint_dir: String, name: String,
		boundary: String, receipt: Dictionary, carried: Dictionary) -> String:
	var out := checkpoint_dir.path_join(name)
	if DirAccess.dir_exists_absolute(_abs(out)):
		remove_tree(out)
	if not copy_tree(save_dir, out.path_join("save")):
		return ""
	for other: String in carried:
		if other != boundary and not write_json(receipt_path(out, other), carried[other]):
			return ""
	if not write_json(receipt_path(out, boundary), receipt):
		return ""
	var file := FileAccess.open(_abs(out.path_join("README.txt")), FileAccess.WRITE)
	if file == null:
		return ""
	file.store_string(readme_text(name, boundary, receipt))
	file.close()
	return out


## The earned_saves layout check: README.txt, save/slot_<n>.json, save/worlds,
## save/characters, receipts/<boundary>.json.
static func layout_problems(checkpoint: String, boundary: String) -> Array:
	var problems: Array = []
	for path: String in [checkpoint.path_join("README.txt"),
			checkpoint.path_join("save").path_join("slot_%d.json" % CHECKPOINT_SLOT),
			receipt_path(checkpoint, boundary)]:
		if not FileAccess.file_exists(_abs(path)):
			problems.append("missing " + path)
	for dir: String in ["worlds", "characters"]:
		if not DirAccess.dir_exists_absolute(_abs(checkpoint.path_join("save").path_join(dir))):
			problems.append("missing save/" + dir)
	return problems


## Receipts already in a checkpoint's receipts/ (boundary/segment -> dict).
static func read_all_receipts(checkpoint: String) -> Dictionary:
	var out := {}
	var dir := checkpoint.path_join("receipts")
	for file: String in DirAccess.get_files_at(_abs(dir)):
		if file.ends_with(".json"):
			out[file.get_basename()] = read_receipt(dir.path_join(file))
	return out


## Commit of the running tree: TB_COMMIT_SHA wins (a caller that knows better),
## then `git rev-parse HEAD`, then the .git HEAD file (worktree-aware).
static func commit_sha() -> String:
	var env := OS.get_environment("TB_COMMIT_SHA").strip_edges()
	if not env.is_empty():
		return env
	var output: Array = []
	var project := ProjectSettings.globalize_path("res://")
	if OS.execute("git", ["-C", project, "rev-parse", "HEAD"], output, true) == 0 and not output.is_empty():
		var sha := str(output[0]).strip_edges()
		if sha.length() == 40:
			var status: Array = []
			if OS.execute("git", ["-C", project, "status", "--porcelain", "--untracked-files=no"], status, true) == 0 \
					and not status.is_empty() and not str(status[0]).strip_edges().is_empty():
				return sha + "-dirty"
			return sha
	return _sha_from_git_dir(project.path_join(".git"))


static func _sha_from_git_dir(git: String) -> String:
	if FileAccess.file_exists(git):
		var pointer := FileAccess.get_file_as_string(git).strip_edges()
		if pointer.begins_with("gitdir:"):
			git = pointer.substr(7).strip_edges()
	var head := FileAccess.get_file_as_string(git.path_join("HEAD")).strip_edges()
	if not head.begins_with("ref:"):
		return head
	var ref := head.substr(4).strip_edges()
	for base: String in [git, git.path_join("..").path_join("..")]:
		var value := FileAccess.get_file_as_string(base.path_join(ref)).strip_edges()
		if value.length() == 40:
			return value
	return "unknown"


static func copy_tree(from: String, to: String) -> bool:
	if DirAccess.make_dir_recursive_absolute(_abs(to)) != OK:
		return false
	for file: String in DirAccess.get_files_at(_abs(from)):
		if DirAccess.copy_absolute(_abs(from.path_join(file)), _abs(to.path_join(file))) != OK:
			return false
	for sub: String in DirAccess.get_directories_at(_abs(from)):
		if not copy_tree(from.path_join(sub), to.path_join(sub)):
			return false
	return true


static func remove_tree(path: String) -> void:
	for file: String in DirAccess.get_files_at(_abs(path)):
		DirAccess.remove_absolute(_abs(path.path_join(file)))
	for sub: String in DirAccess.get_directories_at(_abs(path)):
		remove_tree(path.path_join(sub))
	DirAccess.remove_absolute(_abs(path))


static func _abs(path: String) -> String:
	return ProjectSettings.globalize_path(path) if path.contains("://") else path
