extends RefCounted

## F02 (ACCEPTANCE §6.1): "The solo, two-loss and four-character ledgers are
## solvent ... Measure WORLD §3.1 route spacing and A7 on that same route."
##
## Observer only: reads live state on the continuous earned route and never
## drives play, writes state or moves anything. The smoke starts it with
## `--route-ledger`; without that flag nothing here runs.
##
## What it records:
## - A ledger receipt at every stage the smoke reaches (its `reached` label):
##   game seconds, walked path metres, every inventory stack and the party.
## - Beats, each once: a fight starting, a wild body first coming within
##   BEAT_RADIUS_M, a new interaction offer the player could take, a new
##   progression flag. Scenery that repeats does not reset anything (A7).
## - A7: the longest run of *active travel* (moving, not fighting) with no beat.
## - WORLD §3.1: walked-path gaps between consecutive beats; a gap over
##   WINDOW_M means some 250 m window had no beat within 40 m.
##
## Limits, stated rather than hidden: a vista/landmark reveal is not detected,
## so every gap reported is an upper bound on the real one; the walker is the
## harness, not a person, so its detours and waits are its own.
const BEAT_RADIUS_M := 40.0
const WINDOW_M := 250.0
const SPACING_MIN_M := 150.0
const A7_LIMIT_S := 120.0
const SAMPLE_S := 0.5
## Metres per sample below which the player counts as standing still.
const MOVING_M := 0.25
## A jump this large in one sample is a reload/respawn placement, not walking.
const DISCONTINUITY_M := 30.0

var _tree: SceneTree
var _stage_of: Callable
var _running := false
var _file: FileAccess
var _t := 0.0
var _since_sample := 0.0
var _path_m := 0.0
var _last_pos := Vector3.INF
var _stage := ""
var _fighting := false
var _active_gap_s := 0.0
## Total active-travel seconds so far, stamped on every beat so the strict
## A7 gap between any two beats can be computed after the run.
var _active_total_s := 0.0
var _active_gap_start := {}
var _worst_gap := {"seconds": 0.0}
var _a7_violations: Array = []
var _seen_wilds := {}
var _seen_offers := {}
var _flags := {}
var _discontinuities := 0
var beats: Array = []
var ledger: Array = []


func start(tree: SceneTree, stage_of: Callable, output_path: String) -> bool:
	if FileAccess.file_exists(output_path):
		return false
	_file = FileAccess.open(output_path, FileAccess.WRITE)
	if _file == null:
		return false
	_tree = tree
	_stage_of = stage_of
	_running = true
	_write({"kind": "contract", "beat_radius_m": BEAT_RADIUS_M, "window_m": WINDOW_M,
		"spacing_min_m": SPACING_MIN_M, "a7_limit_s": A7_LIMIT_S, "sample_s": SAMPLE_S,
		"beats": ["fight_started", "wild_within_radius (first time per body)",
			"offer (first time per provider+prompt)", "flag_set"],
		"not_detected": ["vista/landmark reveal"], "gaps_are_upper_bounds": true})
	_seed_flags()
	tree.physics_frame.connect(_observe)
	return true


func stop() -> Dictionary:
	if _running and _tree != null and _tree.physics_frame.is_connected(_observe):
		_tree.physics_frame.disconnect(_observe)
	if _running:
		_close_gap()
		_receipt("stop")
	_running = false
	var summary := summary()
	if _file != null:
		_write(summary)
		_file.flush()
		_file = null
	return summary


## F02#5 solvency over the per-stage ledger rows, per PROGRESSION §6 as read
## for this lane (ralph/reports/MEADOWS-PAYOFFS/earned-bridge, 2026-09-27):
## - reserve (PROGRESSION.md §6 emergency reserve): before each gauntlet stage
##   the player can field two basic heals, carried or affordable,
##   `potion_small + floor(coin / potion_price) >= 2`;
## - two-loss: restocking to the SYSTEMS §"Target supply policy" basket after
##   two losses (4 small potions, 2 revives) is affordable from the coin held,
##   `coin >= potion_price * max(0, 4 - P) + revive_price * max(0, 2 - R)`.
##   The loss basket is this lane's derived assumption (the docs define no coin
##   cost per loss) and is reported as such;
## - repeated wilds: no wild body fought twice (fight_started beats).
## Four-character shared-node depletion is NOT computed here (it needs the
## route's harvest node totals or a four-peer run) and says so.
const RESERVE_STAGES := ["rested_team", "tournament_won", "south_bridge_crossed",
	"warrens_cleared_and_exited", "relay_disabled_and_mill_crossed", "warden_arena_entered"]
const RESERVE_HEALS := 2
const LOSS_POTIONS := 4
const LOSS_REVIVES := 2


static func solvency(rows: Array, beat_list: Array, potion_price: int, revive_price: int) -> Dictionary:
	var stages: Array = []
	var reserve_ok := true
	var two_loss_ok := true
	var worst := {}
	for raw: Variant in rows:
		var row := raw as Dictionary
		if not RESERVE_STAGES.has(str(row.get("stage", ""))):
			continue
		var items: Dictionary = row.get("items", {})
		var coin := int(items.get("coin", 0))
		var potions := int(items.get("potion_small", 0))
		var revives := int(items.get("revive", 0))
		var heals := potions + (coin / potion_price if potion_price > 0 else 0)
		var restock := potion_price * maxi(0, LOSS_POTIONS - potions) + revive_price * maxi(0, LOSS_REVIVES - revives)
		var margin := coin - restock
		var entry := {"stage": row["stage"], "coin": coin, "potion_small": potions, "revive": revives,
			"reserve_heals": heals, "reserve_ok": heals >= RESERVE_HEALS,
			"two_loss_restock": restock, "two_loss_margin": margin}
		stages.append(entry)
		reserve_ok = reserve_ok and heals >= RESERVE_HEALS
		two_loss_ok = two_loss_ok and margin >= 0
		if worst.is_empty() or margin < int(worst["two_loss_margin"]):
			worst = entry
	var fought := {}
	var repeated: Array = []
	for raw: Variant in beat_list:
		var beat := raw as Dictionary
		if str(beat.get("kind", "")) != "fight_started" or not str(beat.get("detail", "")).begins_with("Wild_"):
			continue
		var name := str(beat["detail"])
		if fought.has(name) and not repeated.has(name):
			repeated.append(name)
		fought[name] = true
	return {"stages": stages, "reserve_ok": reserve_ok and not stages.is_empty(),
		"two_loss_ok": two_loss_ok and not stages.is_empty(), "two_loss_worst": worst,
		"two_loss_basket": {"potion_small": LOSS_POTIONS, "revive": LOSS_REVIVES, "assumption": true},
		"wilds_fought": fought.size(), "repeated_wilds": repeated,
		"four_character": "not computed: needs route harvest totals or a four-peer run"}


## Strict beat reading for WORLD §3.1 and A7 ("repeated scenery does not reset
## the clock"). A resource verb repeated along the road (every tree offers
## Chop), a door and the creature controls are not a meaningful sight,
## encounter or decision; a wild body counts only as the first of its species
## seen. Fights, story flags and every other offer (a person, a trainer, a
## TM, a craft or rest spot, a gate) count. Reported beside the loose reading.
const REPEATED_VERBS := ["Chop", "Gather", "Pick up", "Mine", "Strip meadow grass",
	"Gather deadwood", "Prise loose stones", "Prise out rootstone", "Pick berries",
	"Open Door", "Close Door"]
const CONTROL_PREFIXES := ["Put ", "Call out ", "Change Creature"]


static func strict_beats(beat_list: Array) -> Array:
	var out: Array = []
	var species_seen := {}
	for raw: Variant in beat_list:
		var beat := raw as Dictionary
		var kind := str(beat.get("kind", ""))
		var detail := str(beat.get("detail", ""))
		if kind == "offer":
			if REPEATED_VERBS.has(detail) or detail.begins_with("Engage "):
				continue
			var control := false
			for prefix: String in CONTROL_PREFIXES:
				control = control or detail.begins_with(prefix)
			if control:
				continue
		elif kind == "wild_within_radius":
			var species := detail.get_slice(" ", 1)
			if species_seen.has(species):
				continue
			species_seen[species] = true
		out.append(beat)
	return out


## A7 over strict beats: the active-travel seconds between consecutive strict
## beats (each beat carries the running active-travel total).
static func strict_a7(strict: Array, limit_s: float) -> Dictionary:
	var worst := {"seconds": 0.0}
	var violations: Array = []
	for i in range(1, strict.size()):
		var a: Dictionary = strict[i - 1]
		var b: Dictionary = strict[i]
		var gap := float(b.get("active_s", 0.0)) - float(a.get("active_s", 0.0))
		var row := {"seconds": snappedf(gap, 0.1), "from": a.get("detail", a.get("kind")),
			"to": b.get("detail", b.get("kind")), "stage": b.get("stage", ""),
			"from_pos": a.get("pos"), "to_pos": b.get("pos")}
		if gap > float(worst["seconds"]):
			worst = row
		if gap > limit_s:
			violations.append(row)
	return {"longest": worst, "violations": violations}


func summary() -> Dictionary:
	var gaps := spacing_gaps(beats)
	var over: Array = []
	var lengths: Array = []
	for gap: Dictionary in gaps:
		lengths.append(float(gap["metres"]))
		if float(gap["metres"]) > WINDOW_M:
			over.append(gap)
	lengths.sort()
	return {"kind": "summary", "game_seconds": snappedf(_t, 0.1), "path_m": snappedf(_path_m, 0.1),
		"beats": beats.size(), "discontinuities": _discontinuities,
		"a7_longest_active_gap": _worst_gap, "a7_violations": _a7_violations,
		"spacing_median_m": snappedf(float(lengths[lengths.size() / 2]), 0.1) if not lengths.is_empty() else -1.0,
		"spacing_over_window": over, "stages": ledger.size(),
		"solvency": solvency(ledger, beats, _price("potion_small"), _price("revive")),
		"strict": _strict_summary()}


func _strict_summary() -> Dictionary:
	var strict := strict_beats(beats)
	var gaps := spacing_gaps(strict)
	var over: Array = []
	var lengths: Array = []
	for gap: Dictionary in gaps:
		lengths.append(float(gap["metres"]))
		if float(gap["metres"]) > WINDOW_M:
			over.append(gap)
	lengths.sort()
	return {"beats": strict.size(),
		"spacing_median_m": snappedf(float(lengths[lengths.size() / 2]), 0.1) if not lengths.is_empty() else -1.0,
		"spacing_over_window": over, "a7": strict_a7(strict, A7_LIMIT_S)}


static func _price(item_id: String) -> int:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/trade.json"))
	var dearest := 0
	if parsed is Dictionary:
		for raw: Variant in ((parsed as Dictionary).get("vendors", {}) as Dictionary).values():
			var goods: Dictionary = (raw as Dictionary).get("goods", {})
			if goods.has(item_id):
				dearest = maxi(dearest, int((goods[item_id] as Dictionary).get("buy", 0)))
	return dearest


## Walked-path distance between consecutive beats. Pure, so a unit test can
## hold the arithmetic without a world.
static func spacing_gaps(beat_list: Array) -> Array:
	var out: Array = []
	for i in range(1, beat_list.size()):
		var a: Dictionary = beat_list[i - 1]
		var b: Dictionary = beat_list[i]
		out.append({"metres": snappedf(float(b["path_m"]) - float(a["path_m"]), 0.1),
			"from": a["kind"], "to": b["kind"], "stage": b["stage"],
			"from_pos": a["pos"], "to_pos": b["pos"]})
	return out


func _observe() -> void:
	var dt := 1.0 / float(Engine.physics_ticks_per_second)
	_t += dt
	_since_sample += dt
	if _since_sample < SAMPLE_S:
		return
	var step := _since_sample
	_since_sample = 0.0
	var stage := str(_stage_of.call()) if _stage_of.is_valid() else ""
	if stage != _stage:
		_stage = stage
		_receipt(stage)
	var world := _tree.current_scene
	var game := _tree.root.get_node_or_null(^"Game")
	if world == null or game == null:
		return
	var player := world.get_node_or_null(^"Player") as Node3D
	if player == null:
		return
	var pos := player.global_position
	var moved := 0.0
	if _last_pos != Vector3.INF:
		moved = Vector2(pos.x - _last_pos.x, pos.z - _last_pos.z).length()
		if moved > DISCONTINUITY_M:
			_discontinuities += 1
			moved = 0.0
	_last_pos = pos
	_path_m += moved

	var combat := world.get_node_or_null(^"CombatManager")
	var fighting := combat != null and bool(combat.call("is_fighting"))
	if fighting and not _fighting:
		var enemy: Variant = combat.call("enemy_body")
		_beat("fight_started", str((enemy as Node).name) if enemy is Node else "", pos)
	_fighting = fighting

	var encounter := world.get_node_or_null(^"EncounterDirector")
	if encounter != null:
		var wilds: Variant = encounter.get("_wild_creatures")
		for wild: Variant in (wilds if wilds is Array else []):
			if not is_instance_valid(wild) or not (wild as Node3D).visible:
				continue
			var body := wild as Node3D
			if not bool(body.call("is_alive")) or body.global_position.distance_to(pos) > BEAT_RADIUS_M:
				continue
			var key := str(body.get_path())
			if not _seen_wilds.has(key):
				_seen_wilds[key] = true
				_beat("wild_within_radius", "%s %s" % [body.name, str(body.get("species_id"))], pos)

	var arbiter := _tree.get_first_node_in_group(&"interaction_arbiter")
	if arbiter != null and bool(arbiter.call("enabled")):
		var prompt := str(arbiter.call("prompt")).strip_edges()
		var provider: Variant = arbiter.call("winning_provider")
		if not prompt.is_empty() and is_instance_valid(provider) and provider is Node:
			# Glyph markup varies with the device; the words are the offer.
			var words := prompt.substr(prompt.rfind("]") + 1).strip_edges()
			var key := "%s|%s" % [str((provider as Node).get_path()), words]
			if not _seen_offers.has(key):
				_seen_offers[key] = true
				_beat("offer", words, pos)

	var progression: RefCounted = game.get("progression")
	if progression != null:
		for flag: Variant in progression.call("all_set"):
			if not _flags.has(flag):
				_flags[flag] = true
				_beat("flag_set", str(flag), pos)

	if not fighting and moved >= MOVING_M:
		if _active_gap_s == 0.0:
			_active_gap_start = {"t": snappedf(_t, 0.1), "path_m": snappedf(_path_m, 0.1), "pos": _v(pos), "stage": _stage}
		_active_gap_s += step
		_active_total_s += step


func _beat(kind: String, detail: String, pos: Vector3) -> void:
	_close_gap()
	beats.append({"kind": kind, "detail": detail, "t": snappedf(_t, 0.1),
		"path_m": snappedf(_path_m, 0.1), "active_s": snappedf(_active_total_s, 0.1),
		"pos": _v(pos), "stage": _stage})
	_write({"kind": "beat", "beat": beats.back()})


func _close_gap() -> void:
	if _active_gap_s <= 0.0:
		return
	var gap := {"seconds": snappedf(_active_gap_s, 0.1), "start": _active_gap_start,
		"end_t": snappedf(_t, 0.1), "end_path_m": snappedf(_path_m, 0.1)}
	if _active_gap_s > float(_worst_gap["seconds"]):
		_worst_gap = gap
	if _active_gap_s > A7_LIMIT_S:
		_a7_violations.append(gap)
	_active_gap_s = 0.0


func _receipt(stage: String) -> void:
	var game := _tree.root.get_node_or_null(^"Game")
	var items := {}
	var party: Array = []
	if game != null:
		var inventory: RefCounted = game.get("inventory")
		if inventory != null:
			for i in int(inventory.call("slot_count")):
				var stack: Dictionary = inventory.call("stack_at", i)
				if stack.is_empty():
					continue
				var id := str(stack.get("id", ""))
				items[id] = int(items.get(id, 0)) + int(stack.get("n", 0))
		var members: RefCounted = game.get("party")
		if members != null:
			for i in int(members.call("size")):
				var c: Variant = members.call("at", i)
				if c != null:
					party.append({"species": str(c.get("species_id")), "level": int(c.get("level")),
						"xp": int(c.get("xp")), "hp": snappedf(float(c.get("hp")), 0.1)})
	var row := {"kind": "ledger", "stage": stage, "t": snappedf(_t, 0.1),
		"path_m": snappedf(_path_m, 0.1), "beats": beats.size(),
		"a7_longest_so_far_s": _worst_gap["seconds"], "items": items, "party": party}
	ledger.append(row)
	_write(row)
	print("ROUTE LEDGER ", JSON.stringify(row))


func _seed_flags() -> void:
	var game := _tree.root.get_node_or_null(^"Game")
	var progression: RefCounted = game.get("progression") if game != null else null
	if progression != null:
		for flag: Variant in progression.call("all_set"):
			_flags[flag] = true


func _v(p: Vector3) -> Array:
	return [snappedf(p.x, 0.1), snappedf(p.y, 0.1), snappedf(p.z, 0.1)]


func _write(row: Dictionary) -> void:
	if _file != null:
		_file.store_line(JSON.stringify(row))
