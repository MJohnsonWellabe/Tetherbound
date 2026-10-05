extends RefCounted

## CI segment checkpoints (owner, 2026-10-04: "Break the long parts of ci up").
##
## A long continuous CI chain runs as SEGMENTS. Segment N starts from a real
## save that segment N-1's own run wrote through the production save code at
## its end (`capture_saves`, i.e. `Game.autosave_here()`, or the game's own
## character save), committed under `tests/fixtures/segments/<chain>/<boundary>/`.
##
## The START CONTRACT of every boundary lives here, once. Three checks read it:
##
##  1. the PRODUCER segment's end (`seg_checkpoint`, tools/net/proof_steps_segments.gd):
##     the save it just wrote meets the contract, and its state digest equals the
##     committed checkpoint's (otherwise the checkpoint is STALE: game code now
##     produces something else -- "re-generate checkpoint <boundary> with <cmd>");
##  2. the CONSUMER segment's start (`seg_seed_home` / `seg_contract`): the
##     checkpoint it was handed meets the same contract;
##  3. the HANDOFF check (`tests/test_ci_segment_handoffs.gd`): the committed
##     checkpoint is at the current save VERSION, loads through the production
##     `SaveGame.load_slot`, meets the contract, still matches its manifest
##     digest, and was produced by the producer scenario as it is now.
##
## So segment N-1's end assertion and segment N's start assertion cannot drift.

const FIXTURE_ROOT := "res://tests/fixtures/segments/"
const REGEN_COMMAND := "tools/ci/segments/regen.sh"
const SCHEMA_ROOT := "redesign-v28"
const MANIFEST := "manifest.json"
const RECORD := "segment_checkpoint.json"
const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const WORLD_SAVE := preload("res://scripts/save/world_save.gd")
const CHARACTER_SAVE := preload("res://scripts/save/character_save.gd")
const SAVE_DOCUMENT := preload("res://scripts/save/save_document.gd")
const FORMAT := preload("res://tests/test_save_format.gd")
const ITEM_DB := preload("res://autoload/item_db.gd")
const INVENTORY := preload("res://autoload/inventory.gd")
const PARTY := preload("res://autoload/party.gd")
const PROGRESSION_STATE := preload("res://autoload/progression_state.gd")
const REALM_HEART_STATE := preload("res://autoload/realm_heart_state.gd")
const SPLIT_FIXTURE := preload("res://tests/helpers/split_save_fixture.gd")

const MIDRIDE_DIR := "res://tools/net/proof_scenarios/segments/midride/"
## The two-peer proof runner the F06 scenarios use (raised heartbeat tolerance).
const NET_PROOF_RUNNER := "res://tests/smoke_cloudreach_rejoin_closed_gate_proof.gd"
## tests/smoke_tournament_bracket.gd: --segment=to-semi produces, --segment=final consumes.
const BRACKET_SMOKE := "res://tests/smoke_tournament_bracket.gd"
const MIDRIDE_FIVE := ["meadowhart", "bramblebun", "terrapup", "brooktail", "mudsnout"]

## boundary -> {chain, roles: {role -> {producer, peer, contract}}, consumer}.
## `producer` is the scenario whose run writes that role's save (its peer
## `peer`); `consumer` is the segment that starts from the boundary.
## Contract keys (all optional):
##   realm               current realm the save resumes in
##   party_species       exact party species, in party order
##   party_size          exact party size
##   flags_set / flags_unset   progression flags (world and character) loaded
##   items               {item_id: exact count} in the satchel
##   tournament_selection  exact number of registered tournament entrants
##   same_character_as   "<boundary>:<role>": same character id as that checkpoint
const BOUNDARIES := {
	"midride/setup": {
		"chain": "midride",
		"consumer": MIDRIDE_DIR + "s1_ride_a.json",
		"roles": {
			"host": {
				"producer": MIDRIDE_DIR + "s0_setup_host.json", "peer": 0, "runner": NET_PROOF_RUNNER,
				"contract": {"realm": "cloudreach", "party_size": 0,
					"flags_set": ["realm_key_cloudreach"],
					"flags_unset": ["cloudreach_upper_route_unlocked"]},
			},
			"guest": {
				"producer": MIDRIDE_DIR + "s0_setup_guest.json", "peer": 0, "runner": NET_PROOF_RUNNER,
				"contract": {"realm": "cloudreach", "party_species": MIDRIDE_FIVE,
					"flags_set": ["realm_key_cloudreach", "cloudreach_upper_route_unlocked"],
					"flags_unset": ["saddle_fitted_meadowhart"],
					"items": {"saddle": 1}},
			},
		},
	},
	"midride/after_a": {
		"chain": "midride",
		"consumer": MIDRIDE_DIR + "s2_ride_b.json",
		"roles": {
			"host": {
				"producer": MIDRIDE_DIR + "s1_ride_a.json", "peer": 0, "runner": NET_PROOF_RUNNER,
				"contract": {"realm": "cloudreach", "party_size": 0,
					"flags_set": ["realm_key_cloudreach"],
					"flags_unset": ["cloudreach_upper_route_unlocked"]},
			},
			"guest": {
				"producer": MIDRIDE_DIR + "s1_ride_a.json", "peer": 1, "runner": NET_PROOF_RUNNER,
				"contract": {"realm": "cloudreach", "party_species": MIDRIDE_FIVE,
					"flags_set": ["realm_key_cloudreach", "cloudreach_upper_route_unlocked"],
					"same_character_as": "midride/setup:guest"},
			},
		},
	},
	"bracket/after_semi": {
		"chain": "bracket",
		"consumer": BRACKET_SMOKE + " -- --segment=final",
		"roles": {
			"solo": {
				"producer": BRACKET_SMOKE, "peer": 0, "runner": BRACKET_SMOKE,
				"runner_args": ["--segment=to-semi"],
				"contract": {"realm": "meadows", "tournament_selection": 3,
					"flags_set": ["opening:tournament_registered", "tournament_team_ready",
						"tournament_training_ready", "tournament_condition_ready", "tournament_entered",
						"tournament_quarter_won", "tournament_semi_won"],
					"flags_unset": ["tournament_won", "recipe_saddle", "tournament_final_at_ring"]},
			},
		},
	},
	"midride/after_b": {
		"chain": "midride",
		"consumer": MIDRIDE_DIR + "s3_control.json",
		"roles": {
			"host": {
				"producer": MIDRIDE_DIR + "s2_ride_b.json", "peer": 0, "runner": NET_PROOF_RUNNER,
				"contract": {"realm": "cloudreach", "party_size": 0,
					"flags_set": ["realm_key_cloudreach"],
					"flags_unset": ["cloudreach_upper_route_unlocked"]},
			},
			"guest": {
				"producer": MIDRIDE_DIR + "s2_ride_b.json", "peer": 1, "runner": NET_PROOF_RUNNER,
				"contract": {"realm": "cloudreach", "party_species": MIDRIDE_FIVE,
					"flags_set": ["realm_key_cloudreach", "cloudreach_upper_route_unlocked"],
					"same_character_as": "midride/setup:guest"},
			},
		},
	},
}


static func boundary_names() -> Array:
	return BOUNDARIES.keys()


static func role_spec(boundary: String, role: String) -> Dictionary:
	var b: Dictionary = BOUNDARIES.get(boundary, {})
	return (b.get("roles", {}) as Dictionary).get(role, {})


static func checkpoint_dir(boundary: String, role: String) -> String:
	return FIXTURE_ROOT.path_join(boundary).path_join(role)


static func manifest_path(boundary: String) -> String:
	return FIXTURE_ROOT.path_join(boundary).path_join(MANIFEST)


static func regen_hint(boundary: String) -> String:
	return "re-generate checkpoint %s with %s %s" % [boundary, REGEN_COMMAND, boundary]


static func read_manifest(boundary: String) -> Dictionary:
	var path := _abs(manifest_path(boundary))
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


## sha256 of what decides a role's checkpoint: the producer scenario file as it
## is now, plus the role's contract. A change to either means the committed
## checkpoint was made by a different producer.
static func producer_fingerprint(boundary: String, role: String) -> String:
	var spec := role_spec(boundary, role)
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(FileAccess.get_file_as_bytes(_abs(str(spec.get("producer", "")))))
	ctx.update(JSON.stringify(spec.get("contract", {}), "", true).to_utf8_buffer())
	ctx.update(str(spec.get("peer", 0)).to_utf8_buffer())
	return ctx.finish().hex_encode()


# --- loading a captured save through the production loader -------------------

## Loads a captured save directory (`capture_saves` layout: saves/, worlds/,
## characters/, files optionally `.gz`, under the schema root) through the
## production `SaveGame.load_slot` into a Game stand-in. Returns
## {ok, detail, game, versions, keys}. `work_dir` is a scratch user:// dir.
static func load_captured(from: String, work_dir: String) -> Dictionary:
	from = _abs(from)
	SPLIT_FIXTURE.wipe(work_dir)
	DirAccess.make_dir_recursive_absolute(_abs(work_dir))
	var saves := _schema(from.path_join("saves"))
	var slot := -1
	var slot_file := ""
	var d := DirAccess.open(saves)
	if d != null:
		for entry: String in d.get_files():
			var m := RegEx.create_from_string("^slot_(\\d+)\\.json(\\.gz)?$").search(entry)
			if m != null:
				if slot >= 0:
					return {"ok": false, "detail": "%s holds more than one slot" % saves}
				slot = int(m.get_string(1))
				slot_file = saves.path_join(entry)
	if slot < 0:
		return {"ok": false, "detail": "no saves/slot_N.json under %s" % from}
	var saver: RefCounted = SAVE_GAME.new(work_dir)
	if not _inflate(slot_file, _abs(str(saver.call("slot_path", slot)))):
		return {"ok": false, "detail": "could not copy %s" % slot_file}
	for sub: String in ["worlds", "characters"]:
		_copy_tree(_schema(from.path_join(sub)), _abs(work_dir).path_join(sub))
	var versions := {"slot": _version(slot_file)}
	var keys := {"slot": _keys(slot_file)}
	for f: String in _files(_schema(from.path_join("worlds"))):
		versions["world"] = _version(f)
		keys["world"] = _keys(f)
	for f: String in _files(_schema(from.path_join("characters"))):
		versions["character"] = _version(f)
		keys["character"] = _keys(f)
	var game: RefCounted = new_game_double()
	var ok := bool(saver.call("load_slot", game, slot))
	if not ok:
		return {"ok": false, "game": game, "versions": versions, "keys": keys,
			"detail": "SaveGame.load_slot(%d) refused %s: %s" % [slot, from, str(saver.get("last_load_result"))]}
	return {"ok": true, "game": game, "versions": versions, "keys": keys, "slot": slot,
		"detail": "loaded slot %d from %s" % [slot, from]}


## The `Game` stand-in tests/test_save_format.gd loads saves into.
static func new_game_double() -> RefCounted:
	var game: RefCounted = FORMAT.FakeGame.new()
	game.party = PARTY.new()
	game.inventory = INVENTORY.new(ITEM_DB.new())
	game.progression = PROGRESSION_STATE.new()
	game.realm_hearts = REALM_HEART_STATE.new()
	game.world = SPLIT_FIXTURE.IdHolder.new()
	game.local = FORMAT.FakeLocal.new()
	return game


# --- the contract -------------------------------------------------------------

## Failures (empty = met) of `game` (the live Game, or a loaded stand-in)
## against the boundary role's contract.
static func evaluate(boundary: String, role: String, game: Object) -> Array[String]:
	var out: Array[String] = []
	var spec := role_spec(boundary, role)
	if spec.is_empty():
		out.append("no contract for %s:%s" % [boundary, role])
		return out
	var c: Dictionary = spec.get("contract", {})
	var party: Object = game.get("party")
	var progression: Object = game.get("progression")
	var inventory: Object = game.get("inventory")
	if c.has("realm") and str(game.get("current_realm")) != str(c.realm):
		out.append("realm is '%s', contract wants '%s'" % [str(game.get("current_realm")), str(c.realm)])
	var species := party_species(game)
	if c.has("party_species") and species != (c.party_species as Array):
		out.append("party species %s, contract wants %s" % [str(species), str(c.party_species)])
	if c.has("party_size") and species.size() != int(c.party_size):
		out.append("party size %d, contract wants %d" % [species.size(), int(c.party_size)])
	for flag: String in c.get("flags_set", []):
		if progression == null or not bool(progression.call("has", flag)):
			out.append("flag %s is not set" % flag)
	for flag: String in c.get("flags_unset", []):
		if progression != null and bool(progression.call("has", flag)):
			out.append("flag %s is set" % flag)
	var items: Dictionary = c.get("items", {})
	for id: String in items:
		var n := int(inventory.call("count", id)) if inventory != null else -1
		if n != int(items[id]):
			out.append("satchel holds %d %s, contract wants %d" % [n, id, int(items[id])])
	if c.has("tournament_selection"):
		var picked: Array = party.call("tournament_selection_ids") if party != null else []
		if picked.size() != int(c.tournament_selection):
			out.append("%d registered tournament entrants, contract wants %d" % [picked.size(), int(c.tournament_selection)])
	if c.has("same_character_as"):
		var parts := str(c.same_character_as).split(":")
		var want := str(((read_manifest(parts[0]).get("roles", {}) as Dictionary)
			.get(parts[1], {}) as Dictionary).get("character_id", ""))
		var got := character_id(game)
		if want.is_empty() or got != want:
			out.append("character '%s', contract wants the same character as %s ('%s')"
				% [got, str(c.same_character_as), want])
	return out


static func party_species(game: Object) -> Array:
	var out: Array = []
	var party: Object = game.get("party")
	if party != null:
		for m: Variant in (party.call("members") as Array):
			out.append(str((m as Object).get("species_id")))
	return out


static func character_id(game: Object) -> String:
	var local: Variant = game.get("local")
	return str((local as Object).get("character_id")) if local != null else ""


## The state digest freshness compares: what a checkpoint resumes as, minus
## the volatile parts a re-run legitimately changes (ids, clocks, poses).
## Document versions and key sets are in it, so a format change shows.
static func summary(loaded: Dictionary) -> Dictionary:
	var game: Object = loaded.get("game")
	var party: Array = []
	var members: Array = (game.get("party") as Object).call("members") if game != null else []
	for m: Variant in members:
		party.append("%s@%d" % [str((m as Object).get("species_id")), int((m as Object).get("level"))])
	var flags: Array = ((game.get("progression") as Object).call("all_set") as Array).duplicate() if game != null else []
	flags = flags.map(func(f: Variant) -> String: return str(f))
	flags.sort()
	var items: Array = []
	var inventory: Object = game.get("inventory") if game != null else null
	if inventory != null:
		var counts := {}
		for i in int(inventory.call("slot_count")):
			var stack: Variant = inventory.call("stack_at", i)
			if stack is Dictionary and not (stack as Dictionary).is_empty():
				var id := str((stack as Dictionary).get("id", ""))
				if not id.is_empty():
					counts[id] = int(counts.get(id, 0)) + int((stack as Dictionary).get("n", (stack as Dictionary).get("count", 0)))
		for id: String in counts:
			items.append("%s:%d" % [id, int(counts[id])])
	items.sort()
	return {"versions": loaded.get("versions", {}), "keys": loaded.get("keys", {}),
		"realm": str(game.get("current_realm")) if game != null else "",
		"party": party, "flags": flags, "items": items}


static func digest(summary_value: Dictionary) -> String:
	return JSON.stringify(summary_value, "", true).sha256_text()


## Every reason the committed checkpoint of `boundary:role` cannot be trusted;
## empty = fresh. Each reason names the regeneration command.
## `dir` / `row` override the committed checkpoint and its manifest row (the
## handoff test's deliberately stale copies use them).
static func staleness(boundary: String, role: String, work_dir: String, dir := "",
		row: Dictionary = {}) -> Array[String]:
	var out: Array[String] = []
	var hint := regen_hint(boundary)
	if row.is_empty():
		row = (read_manifest(boundary).get("roles", {}) as Dictionary).get(role, {})
	if dir.is_empty():
		dir = checkpoint_dir(boundary, role)
	if row.is_empty():
		out.append("%s:%s has no manifest row: %s" % [boundary, role, hint])
		return out
	if str(row.get("producer_fingerprint", "")) != producer_fingerprint(boundary, role):
		out.append("%s:%s was produced by a different producer scenario/contract than the current one: %s"
			% [boundary, role, hint])
	var loaded := load_captured(dir, work_dir)
	var versions: Dictionary = loaded.get("versions", {})
	var want_versions := {"slot": SAVE_GAME.VERSION, "world": WORLD_SAVE.VERSION, "character": CHARACTER_SAVE.VERSION}
	for doc: String in want_versions:
		if int(versions.get(doc, -1)) != int(want_versions[doc]):
			out.append("%s:%s %s document is version %d, this build saves %d: %s"
				% [boundary, role, doc, int(versions.get(doc, -1)), int(want_versions[doc]), hint])
	if not bool(loaded.get("ok", false)):
		out.append("%s:%s does not load through the production loader (%s): %s"
			% [boundary, role, str(loaded.get("detail", "")), hint])
		return out
	var got := digest(summary(loaded))
	if got != str(row.get("digest", "")):
		out.append("%s:%s files no longer match their manifest digest (hand-edited or partially regenerated): %s"
			% [boundary, role, hint])
	return out


## END of a producer segment: `dir` holds the save it just wrote through the
## production save code. It must load, meet the boundary role's contract and,
## unless TB_SEGMENT_REGEN=1 (tools/ci/segments/regen.sh), reproduce the
## committed checkpoint's state digest; otherwise the checkpoint is STALE.
## Writes `segment_checkpoint.json` (the record regen.sh installs) into `dir`.
## Returns {verdict, detail, data}.
static func check_produced(boundary: String, role: String, dir: String, work_dir: String) -> Dictionary:
	var loaded := load_captured(dir, work_dir)
	if not bool(loaded.get("ok", false)):
		return {"verdict": "FAIL", "detail": "the save this segment wrote does not load: %s" % str(loaded.get("detail", ""))}
	var failures := evaluate(boundary, role, loaded.game)
	var summary_value := summary(loaded)
	var got := digest(summary_value)
	var record := {"boundary": boundary, "role": role, "digest": got, "summary": summary_value,
		"character_id": character_id(loaded.game),
		"producer_fingerprint": producer_fingerprint(boundary, role),
		"contract_failures": failures}
	var out := FileAccess.open(_abs(dir).path_join(RECORD), FileAccess.WRITE)
	if out != null:
		out.store_string(JSON.stringify(record, " ", true))
		out.close()
	if not failures.is_empty():
		return {"verdict": "FAIL", "detail": "segment end misses %s:%s contract: %s" % [boundary, role, "; ".join(failures)],
			"data": record}
	if OS.get_environment("TB_SEGMENT_REGEN") == "1":
		return {"verdict": "PASS", "detail": "REGEN: recorded %s:%s digest %s in %s" % [boundary, role, got.left(12), dir],
			"data": record}
	var row: Dictionary = (read_manifest(boundary).get("roles", {}) as Dictionary).get(role, {})
	if str(row.get("digest", "")) != got:
		return {"verdict": "FAIL", "detail": "STALE checkpoint %s:%s: this run produced state %s but the committed checkpoint is %s (%s); %s"
			% [boundary, role, got.left(12), str(row.get("digest", "<none>")).left(12),
				JSON.stringify(summary_value), regen_hint(boundary)], "data": record}
	return {"verdict": "PASS", "detail": "segment end meets %s:%s contract and reproduces the committed checkpoint (%s)"
		% [boundary, role, got.left(12)], "data": record}


## Start of a consumer segment, before it uses the committed checkpoint: fresh
## (see `staleness`) and its loaded state meets the contract. {verdict, detail}.
static func check_start(boundary: String, role: String, work_dir: String) -> Dictionary:
	var stale := staleness(boundary, role, work_dir)
	if not stale.is_empty():
		return {"verdict": "FAIL", "detail": "STALE checkpoint: " + "; ".join(stale), "data": {"stale": stale}}
	var loaded := load_captured(checkpoint_dir(boundary, role), work_dir)
	var failures := evaluate(boundary, role, loaded.game)
	return {"verdict": "PASS" if failures.is_empty() else "FAIL",
		"detail": ("checkpoint %s:%s is fresh and meets its start contract (%s)" % [boundary, role, loaded.detail])
			if failures.is_empty() else "checkpoint %s:%s misses its contract: %s" % [boundary, role, "; ".join(failures)],
		"data": {"failures": failures, "character_id": character_id(loaded.game)}}


## A SOLO producer's capture: the production files of one save slot (the slot
## document and the world and character its split locator names) copied from
## user:// into `dst` in the `capture_saves` layout. {ok, detail}.
static func capture_slot(slot: int, dst: String) -> Dictionary:
	var user := OS.get_user_data_dir()
	var slot_file := user.path_join("saves").path_join(SCHEMA_ROOT).path_join("slot_%d.json" % slot)
	if not FileAccess.file_exists(slot_file):
		return {"ok": false, "detail": "no production save at %s" % slot_file}
	var locator: Variant = _parse(slot_file).get(SAVE_GAME.SPLIT_LOCATOR_KEY)
	if not (locator is Dictionary):
		return {"ok": false, "detail": "slot %d has no split locator" % slot}
	dst = _abs(dst)
	SPLIT_FIXTURE.wipe(dst)
	var pairs := [[slot_file, dst.path_join("saves").path_join(SCHEMA_ROOT).path_join(slot_file.get_file())]]
	var copied := 0
	for p: Array in pairs:
		DirAccess.make_dir_recursive_absolute(str(p[1]).get_base_dir())
		if DirAccess.copy_absolute(str(p[0]), str(p[1])) == OK:
			copied += 1
	for sub: String in ["worlds", "characters"]:
		var id := str((locator as Dictionary).get("world_id" if sub == "worlds" else "character_id", ""))
		if id.is_empty():
			return {"ok": false, "detail": "slot %d locator names no %s" % [slot, sub]}
		copied += _copy_tree(user.path_join(sub).path_join(SCHEMA_ROOT).path_join(id),
			dst.path_join(sub).path_join(SCHEMA_ROOT).path_join(id))
	return {"ok": copied >= 3, "detail": "captured %d production files of slot %d into %s" % [copied, slot, dst]}


## A SOLO consumer's start: the committed checkpoint copied into this process's
## user:// (inflated), where `Game.load_game` reads it. Returns the files copied.
static func seed_user(boundary: String, role: String) -> int:
	var src := _abs(checkpoint_dir(boundary, role))
	var copied := 0
	for sub: String in ["saves", "worlds", "characters"]:
		copied += _copy_tree(src.path_join(sub), OS.get_user_data_dir().path_join(sub))
	return copied


# --- files --------------------------------------------------------------------

static func _abs(path: String) -> String:
	return ProjectSettings.globalize_path(path) if path.begins_with("res://") or path.begins_with("user://") else path


static func _schema(dir: String) -> String:
	return dir.path_join(SCHEMA_ROOT) if DirAccess.dir_exists_absolute(dir.path_join(SCHEMA_ROOT)) else dir


static func _text(path: String) -> String:
	var bytes := FileAccess.get_file_as_bytes(path)
	if path.ends_with(".gz"):
		bytes = bytes.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP)
	return bytes.get_string_from_utf8()


static func _inflate(from: String, to: String) -> bool:
	DirAccess.make_dir_recursive_absolute(to.trim_suffix(".gz").get_base_dir())
	var out := FileAccess.open(to.trim_suffix(".gz"), FileAccess.WRITE)
	if out == null:
		return false
	out.store_string(_text(from))
	out.close()
	return true


static func _copy_tree(from: String, to: String) -> int:
	var dir := DirAccess.open(from)
	if dir == null:
		return 0
	DirAccess.make_dir_recursive_absolute(to)
	var copied := 0
	for file: String in dir.get_files():
		if _inflate(from.path_join(file), to.path_join(file)):
			copied += 1
	for sub: String in dir.get_directories():
		copied += _copy_tree(from.path_join(sub), to.path_join(sub))
	return copied


static func _files(dir: String) -> Array[String]:
	var out: Array[String] = []
	var d := DirAccess.open(dir)
	if d == null:
		return out
	for f: String in d.get_files():
		if f.ends_with(".json") or f.ends_with(".json.gz"):
			out.append(dir.path_join(f))
	for sub: String in d.get_directories():
		out.append_array(_files(dir.path_join(sub)))
	return out


static func _parse(path: String) -> Dictionary:
	var parsed: Variant = SAVE_DOCUMENT.parse(_text(path))
	return parsed if parsed is Dictionary else {}


static func _version(path: String) -> int:
	return int(_parse(path).get("version", -1))


static func _keys(path: String) -> Array:
	var k: Array = _parse(path).keys()
	k.sort()
	return k
