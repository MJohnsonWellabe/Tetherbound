extends Node

## Opt-in production observation. Never writes Game, saves, host journals or ACKs.
## Snapshots expose net stock only: they are not durable transaction evidence.
## ROOT may attach this node to an ordinary route, or use the title-screen runner.
const CURVE_PATH := "res://data/config/chapter_curve.json"
var output_path := ""
var run_id := ""
var _file: FileAccess
var _started_ms := 0
var _last_snapshot := ""
var _last_character := ""
var _curve: Dictionary = {}
var _timer := 0.0
var _stopped := false


func start(path: String, identity: String) -> bool:
	if _file != null or path.is_empty() or identity.is_empty(): return false
	# Refuse overwrite: a second capture must never destroy the first witness.
	if FileAccess.file_exists(path): return false
	_file = FileAccess.open(path, FileAccess.WRITE)
	if _file == null: return false
	output_path = path
	run_id = identity
	_started_ms = Time.get_ticks_msec()
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CURVE_PATH))
	if parsed is Dictionary: _curve = parsed
	_write({"kind": "start", "scope": "live local state observations; no durable ACK certification",
		"wall_time_unix": Time.get_unix_time_from_system(),
		"curve_sha256": FileAccess.get_sha256(CURVE_PATH),
		"shortcuts": "not inferred; operator must disclose fixture starts, teleports and injected state"})
	return true


func _process(delta: float) -> void:
	if _file == null or _stopped: return
	_timer += delta
	if _timer < 1.0: return
	_timer = 0.0
	sample()


func _write(row: Dictionary) -> void:
	if _file == null or _stopped: return
	row["schema_version"] = 1
	row["run_id"] = run_id
	row["elapsed_ms"] = Time.get_ticks_msec() - _started_ms
	_file.store_line(JSON.stringify(row))
	_file.flush()
	if _file.get_error() != OK:
		push_error("F47 capture write failed; observations incomplete: " + output_path)
		_stopped = true


## Operator annotations are explicitly unverified; they cannot grant a reward.
func mark(label: String, detail: String = "") -> void:
	sample()
	_write({"kind": "annotation", "label": label, "detail": detail,
		"scope": "operator annotation; not host authority or owner evidence"})


func sample() -> void:
	var game := get_node_or_null("/root/Game")
	if game == null: return
	var local: Variant = game.get("local")
	if local == null: return
	var character := str(local.get("character_id"))
	var inventory: Variant = local.get("inventory")
	var party: Variant = local.get("party")
	if character.is_empty() or inventory == null or party == null: return
	var stock: Dictionary = {}
	for index: int in int(inventory.call("slot_count")):
		var stack: Dictionary = inventory.call("stack_at", index)
		if stack.is_empty(): continue
		var id := str(stack.get("id", ""))
		stock[id] = int(stock.get(id, 0)) + int(stack.get("n", 0))
	var members: Array = []
	for creature: Variant in party.call("members"):
		members.append({"uid": str(creature.get("uid")), "species_id": str(creature.get("species_id")),
			"type": str(creature.get("creature_type")), "secondary_type": str(creature.get("secondary_type")),
			"level": int(creature.get("level")), "xp": int(creature.get("xp")),
			"hp": float(creature.get("hp")), "max_hp": float(creature.get("max_hp")),
			"fainted": bool(creature.get("fainted"))})
	var personal: Variant = local.get("redesign_character")
	var receipts: Variant = personal.get("transaction_receipts", []) if personal is Dictionary else []
	var biome := str(local.get("realm"))
	if biome == "water": biome = "tidewake"
	var band := "unavailable"
	var position: Variant = null
	var scene := get_tree().current_scene
	var player := scene.get_node_or_null("Player") as Node3D if scene != null else null
	if player != null:
		position = [player.global_position.x, player.global_position.y, player.global_position.z]
		if biome == "meadows":
			for region: Dictionary in _curve.get("regions", []):
				if player.global_position.z < float(region.z_to):
					band = str(region.id)
					break
	# No radius-based band inference for islands/cliffs/storm routes.
	var row := {"kind": "snapshot", "character_id": character, "biome": biome, "band": band,
		"stock": stock, "party": members, "position": position,
		"receipts_sha256": JSON.stringify(receipts).sha256_text(), "receipt_count": receipts.size(),
		"durable_ACK_verified": false}
	var world: Variant = game.get("world")
	if world != null:
		row["world_id"] = str(world.get("world_id"))
		row["world_day"] = int(world.get("day"))
	# Hash before including the clock. A quiet route still gets a stop timestamp.
	var signature := JSON.stringify(row).sha256_text()
	if signature == _last_snapshot and character == _last_character: return
	_last_snapshot = signature
	_last_character = character
	_write(row)


func stop(reason: String = "operator_stop") -> void:
	if _file == null or _stopped: return
	sample()
	_write({"kind": "stop", "reason": reason, "normal_clear_verified": false})
	_stopped = true
	_file.close()


func _exit_tree() -> void:
	stop("observer_exit")
