extends Node3D

## Flag-off F31/F32 Forge actor mounted by the actual station piece.
## A host-owned tap starts one present channel. Physics time pays ONE unit at
## a time through the canonical adapter; no inventory, save or receipt is owned
## here. This transient channel is never serialized or resumed after reload.
## Both injected Callables are trusted host wiring, never request payloads/RPCs:
## reader(actor, uid) -> {world, character, modal_open, in_combat, plot_allowed}.
## commit(plan, host_unit_ticket, actor) -> matched canonical terminal/pending
## verdict. The adapter must revalidate auth/live presence/timing and inventory
## CAS, and durably commit canonical cost/output/receipt together or neither.
## No adapter means no start, debit, output, receipt or false completion.

signal channel_started(recipe_id: String, units: int)
signal channel_stopped(code: String, reason: String)
signal unit_completed(recipe_id: String, completed_units: int)

const RULES_PATH := "res://scripts/world/homestead_refining.gd"
var RULES: Script
const CONFIG_PATH := "res://data/config/stations.json"
const RECIPE_PATH := "res://data/recipes/recipes_forge.json"

var _world: Node3D
var _uid := ""
var _config: Dictionary = {}
var _recipes: Dictionary = {}
var _reader: Callable
var _commit: Callable
var _nonce := ""
var _serial := 0
var _actor: WeakRef
var _recipe_id := ""
var _character_id := ""
var _world_id := ""
var _namespace := ""
var _remaining := 0
var _completed := 0
var _elapsed := 0.0
var _running := false
var _pending: Dictionary = {}


func _ready() -> void:
	# Observe a solo pause so opening a menu cancels the unpaid channel rather
	# than suspending it and silently resuming production after the menu closes.
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_physics_process(false)


## Called only by the owning world/station service after placing this node.
## OFF is checked from the host's actual data file, never a client bool.
func configure(world: Node3D, uid: String, canonical_reader: Callable,
		canonical_commit: Callable) -> Dictionary:
	if _running or not _pending.is_empty():
		return _refusal("busy", "This Forge already has a unit in progress.")
	_world = world
	_uid = uid
	_reader = canonical_reader
	_commit = canonical_commit
	var source := _read(CONFIG_PATH)
	var config: Variant = source.get("forge")
	_config = config.duplicate(true) if config is Dictionary else {}
	_recipes = _read(RECIPE_PATH)
	if ResourceLoader.exists(RULES_PATH): RULES=load(RULES_PATH)
	_nonce = Crypto.new().generate_random_bytes(16).hex_encode()
	if not _enabled():
		return _refusal("disabled", "The Forge is not ready yet.")
	if not _reader.is_valid() or not _commit.is_valid() or _nonce.is_empty():
		return _refusal("unavailable", "The Forge's canonical transaction is unavailable.")
	return {"ok": true}


## Host-only, trusted station opener. No held input or completion claim.
## A second tap cannot append to, replace or queue behind an active channel.
func start_refining(actor: CharacterBody3D, recipe_id: String, amount: int) -> Dictionary:
	if _running or not _pending.is_empty():
		return _refusal("busy", "This Forge already has a unit in progress.")
	if not _enabled() or not _reader.is_valid() or not _commit.is_valid() or _nonce.is_empty():
		return _refusal("unavailable", "The Forge's canonical transaction is unavailable.")
	if amount < 1 or amount > int(_config["maximum_manual_units"]):
		return _refusal("invalid_amount", "Choose a smaller refining amount.")
	_recipe_id = recipe_id
	var plan := _current_plan(actor)
	if not bool(plan.get("ok", false)):
		return plan
	_actor = weakref(actor)
	_character_id = plan["character_id"]
	_world_id = plan["world_id"]
	_namespace = plan["world_namespace"]
	_serial += 1
	_remaining = amount
	_completed = 0
	_elapsed = 0.0
	_running = true
	set_physics_process(true)
	channel_started.emit(recipe_id, amount)
	return {"ok": true, "started": true, "crafted": false}


func _physics_process(delta: float) -> void:
	if not _running:
		return
	var actor := _actor.get_ref() as CharacterBody3D if _actor != null else null
	var plan := _current_plan(actor)
	if not bool(plan.get("ok", false)):
		stop_refining(str(plan.get("code", "unavailable")), str(plan.get("reason", "The channel stopped.")))
		return
	if plan["character_id"] != _character_id or plan["world_id"] != _world_id \
			or plan["world_namespace"] != _namespace:
		stop_refining("residency_changed", "The character's world residency changed.")
		return
	# A pending canonical unit is never submitted again here. Keep its ticket
	# until a matched terminal callback; still cancel unpaid remainder on exit.
	if not _pending.is_empty():
		return
	if not is_finite(delta) or delta <= 0.0 or delta > float(_config["maximum_tick_delta_seconds"]):
		stop_refining("tick_interrupted", "The refining channel was interrupted.")
		return
	_elapsed += delta
	var channel: Dictionary = plan["channel"]
	if _elapsed < float(channel["seconds_per_unit"]):
		return
	# Never run a catch-up loop, prepay future units, or count source staging
	# as a completed ingot. One host-generated stable ticket for this unit.
	var ticket := JSON.stringify([_namespace, _world_id, _character_id,
		_uid, _nonce, _serial, _completed + 1]).sha256_text().substr(0,32)
	_pending = {"txn_id": ticket, "character_id": _character_id, "world_id": _world_id}
	_elapsed = 0.0
	var raw: Variant = _commit.call(plan.duplicate(true), ticket, actor)
	# A synchronous adapter may already have delivered its canonical callback.
	# Do not process its returned acknowledgement twice or stop a later channel.
	if _pending.get("txn_id") != ticket:
		return
	if not raw is Dictionary:
		stop_refining("unresolved_commit", "The canonical refining result is unavailable.")
		return # Retain the unresolved ticket; never retry/grant locally.
	if not resolve_pending_unit(raw):
		stop_refining("unresolved_commit", "The canonical refining result is unavailable.")


## Trusted canonical callback only, never @rpc. A rejected/unmatched result
## cannot pay, resume, or print success. Core reconciliation owns late delivery
## after this transient node disappears; the channel never resumes offline.
func resolve_pending_unit(verdict: Dictionary) -> bool:
	if _pending.is_empty():
		return false
	for key: String in ["txn_id", "character_id", "world_id"]:
		if verdict.get(key) != _pending[key]:
			return false
	for key: String in ["ok", "pending", "durable"]:
		if typeof(verdict.get(key)) != TYPE_BOOL:
			return false
	if verdict["pending"] == true:
		return true # Unpaid remainder waits; no completion signal or local yield.
	if verdict["ok"] == true and verdict["durable"] != true:
		stop_refining("unresolved_commit", "The completed unit is waiting for its canonical save.")
		return true # Accepted/unsaved is not refusal; retain the canonical ticket.
	if verdict["ok"] != true:
		_pending = {}
		stop_refining("commit_refused", str(verdict.get("reason", "The unit could not be committed.")))
		return true
	_pending = {}
	_completed += 1
	_remaining = maxi(0, _remaining - 1)
	if not _running or _remaining == 0:
		_running = false
		_remaining = 0
		set_physics_process(false)
	# Settle transient state before an external signal can re-enter this actor.
	unit_completed.emit(_recipe_id, _completed)
	return true


## Already committed units belong to the character. Only the unpaid remainder
## is canceled; an unresolved canonical unit retains its correlation ticket.
func stop_refining(code: String = "cancelled", reason: String = "Refining stopped.") -> void:
	var was_running := _running
	_running = false
	_remaining = 0
	_elapsed = 0.0
	set_physics_process(false)
	if was_running:
		channel_stopped.emit(code, reason)


func _current_plan(actor: CharacterBody3D) -> Dictionary:
	if is_inside_tree() and get_tree().paused:
		return _refusal("another_modal", "Opening another menu stops refining.")
	if not _enabled() or not is_inside_tree() or not multiplayer.is_server() \
			or not is_instance_valid(_world) or not _world.is_inside_tree() \
			or not _world.has_method("world_realm") or _world.call("world_realm") != "meadows" \
			or not is_instance_valid(actor) or not actor.is_inside_tree() \
			or not _world.is_ancestor_of(self) or not _world.is_ancestor_of(actor) \
			or _world.get_world_3d() == null or get_world_3d() != _world.get_world_3d() \
			or actor.get_world_3d() != _world.get_world_3d():
		return _refusal("wrong_residency", "Refine at your live homestead Forge.")
	if not _reader.is_valid() or not _commit.is_valid():
		return _refusal("unavailable", "The Forge's canonical transaction is unavailable.")
	var raw: Variant = _reader.call(actor, _uid)
	if not raw is Dictionary or not raw.get("world") is Dictionary or not raw.get("character") is Dictionary:
		return _refusal("unavailable", "The character's canonical state is unavailable.")
	for field: String in ["modal_open", "in_combat", "plot_allowed"]:
		if typeof(raw.get(field)) != TYPE_BOOL:
			return _refusal("unavailable", "The character's live station policy is unavailable.")
	if raw["modal_open"] == true:
		return _refusal("another_modal", "Opening another menu stops refining.")
	if raw["in_combat"] == true:
		return _refusal("combat", "Entering combat stops refining.")
	if raw["plot_allowed"] != true:
		return _refusal("needs_homestead", "Refine at the homestead Forge.")
	var plan: Dictionary = RULES.unit_plan(_recipes, _recipe_id, _uid, "meadows", raw["world"], raw["character"])
	if not bool(plan.get("ok", false)):
		return plan
	var world_namespace: Variant = raw["world"].get("reward_delivery_namespace")
	if not world_namespace is String or world_namespace.is_empty():
		return _refusal("unavailable", "The world's canonical transaction identity is unavailable.")
	# Resolve the actual canonical UID again each tick. Index metadata is never
	# identity, and a moved/dismantled/replaced station stops the unpaid channel.
	for row: Variant in raw["world"]["placed_buildings"]:
		if row is Dictionary and row.get("uid") == _uid:
			var at: Array = row["position"]
			var station_at := Vector3(float(at[0]), float(at[1]), float(at[2]))
			if not global_position.is_equal_approx(station_at):
				return _refusal("station_moved", "This Forge no longer matches its world record.")
	var channel: Dictionary = plan["channel"]
	if not actor.global_position.is_finite() or not global_position.is_finite() \
			or actor.global_position.distance_to(global_position) > float(channel["radius_m"]):
		return _refusal("out_of_radius", "Stay beside the Forge to refine.")
	plan["world_namespace"] = world_namespace
	return plan


func _enabled() -> bool:
	return RULES != null and typeof(_config.get("runtime_enabled")) == TYPE_BOOL and _config["runtime_enabled"] == true \
		and _config.get("id") == "forge" and _config.get("realm") == "meadows" \
		and _integer(_config.get("maximum_manual_units"), 1) \
		and _number(_config.get("maximum_tick_delta_seconds")) \
		and float(_config["maximum_tick_delta_seconds"]) > 0.0 \
		and not RULES.manual_channel(_recipes).is_empty()


func _exit_tree() -> void:
	stop_refining("station_left", "Leaving the station stops refining.")


static func _read(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


static func _number(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value))


static func _integer(value: Variant, minimum: int) -> bool:
	return _number(value) and float(value) == float(int(value)) and int(value) >= minimum


static func _refusal(code: String, reason: String) -> Dictionary:
	return {"ok": false, "started": false, "crafted": false, "code": code, "reason": reason}
