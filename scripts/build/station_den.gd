extends Node3D

## Den care observer, mounted on the actual station. Production grooming uses
## CraftPanel -> Session -> Foundation's one character transaction. The legacy
## detached actor API below cannot produce anything without trusted callbacks.
## reader(actor, uid) supplies authenticated world/character save projections,
## modal_open (another modal)/in_combat/plot_allowed actual bools and received_shed_receipts:
## the canonical service's READ-ONLY projection for the existing shed helper,
## never a new receipt store. commit(plan, ticket, actor) must compose the
## Training care cap/stamp, shed outputs (including an empty-output miss),
## inventory CAS and existing portable receipt in ONE durable transaction.
## This node neither rolls, rewards, stamps care, writes saves nor rests pets.

signal groom_completed(creature_uid: String)
signal groom_refused(reason: String)

const SHED_PATH := "res://scripts/world/shed_drop_rules.gd"
var SHED: Script
const CONFIG_PATH := "res://data/config/stations.json"
const POLICY := preload("res://scripts/build/station_rules.gd")
const CONDITION := preload("res://scripts/creatures/creature_condition.gd")

var _world: Node3D
var _uid := ""
var _config: Dictionary = {}
var _shed: Dictionary = {}
var _reader: Callable
var _commit: Callable
var _pending: Dictionary = {}
var _submission_serial := 0


## The live Den owns its existing rest-bonus observer, never a second Groom
## writer. Leaving both legacy callbacks empty keeps groom() unavailable here.
func configure_rest_observer(world: Node3D, uid: String) -> void:
	_world = world
	_uid = uid
	_config = POLICY.config().get("den", {}).duplicate(true)
	SHED = load(SHED_PATH)
	_reader = Callable()
	_commit = Callable()
	if _enabled(): add_to_group("creature_bed_rest_bonus")


## Trusted world-owner wiring only. Client requests cannot enable the actor.
func configure(world: Node3D, uid: String, canonical_reader: Callable,
		canonical_commit: Callable) -> Dictionary:
	if not _pending.is_empty():
		return _refusal("busy", "The Den is waiting for its canonical grooming result.")
	_world = world
	_uid = uid
	_reader = canonical_reader
	_commit = canonical_commit
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	var block: Variant = parsed.get("den") if parsed is Dictionary else null
	_config = block.duplicate(true) if block is Dictionary else {}
	if ResourceLoader.exists(SHED_PATH): SHED=load(SHED_PATH)
	_shed=SHED.call("read") if SHED != null else {}
	if not _enabled():
		return _refusal("disabled", "The Den is not ready yet.")
	if not _reader.is_valid() or not _commit.is_valid():
		return _refusal("unavailable", "The Den's canonical transaction is unavailable.")
	add_to_group("creature_bed_rest_bonus")
	return {"ok": true}


## One explicit tap, one owned UID. No tick, queue, held action or offline job.
## Inventory room, care cap and the once/day receipt must be revalidated by
## the canonical service at commit, never granted from this detached plan.
func groom(actor: CharacterBody3D, creature_uid: String) -> Dictionary:
	if not _pending.is_empty():
		return _refusal("busy", "The Den is waiting for its canonical grooming result.")
	var plan := _current_plan(actor, creature_uid)
	if not bool(plan.get("ok", false)):
		return plan
	# Same character/UID/day in this world instance always correlates to the
	# same canonical action, across Den nodes, retry and reconnect. The service
	# owns translation from the shed helper's internal receipt identity to its
	# existing durable receipt; no shed:* namespace is saved by this actor.
	var ticket := JSON.stringify([plan["world_namespace"],
		plan["character_id"], plan["host_world_day"], creature_uid]).sha256_text().substr(0,32)
	_pending = {"txn_id": ticket, "character_id": plan["character_id"],
		"world_id": plan["world_id"], "creature_uid": creature_uid}
	_submission_serial += 1
	var submission := _submission_serial
	var raw: Variant = _commit.call(plan.duplicate(true), ticket, actor)
	# A synchronous terminal callback may already settle the ticket and even
	# start a different tap through a signal. Never process its ACK twice.
	if _submission_serial != submission or _pending.get("txn_id") != ticket:
		return {"ok": true, "submitted": true, "completed": false}
	if not raw is Dictionary or not resolve_pending_groom(raw):
		return _refusal("unresolved_commit", "The canonical grooming result is unavailable.")
	return {"ok": true, "submitted": true, "completed": false}


## Trusted terminal callback, never RPC/client evidence. Only matched,
## explicitly durable success emits completion. An unresolved accepted unit
## blocks further taps; reconciliation stays in the canonical service even
## if this node is dismantled or the character leaves.
func resolve_pending_groom(verdict: Dictionary) -> bool:
	if _pending.is_empty():
		return false
	for key: String in ["txn_id", "character_id", "world_id", "creature_uid"]:
		if verdict.get(key) != _pending[key]:
			return false
	for key: String in ["ok", "pending", "durable"]:
		if typeof(verdict.get(key)) != TYPE_BOOL:
			return false
	if verdict["pending"] == true or (verdict["ok"] == true and verdict["durable"] != true):
		return true
	var creature_uid: String = _pending["creature_uid"]
	_pending = {}
	if verdict["ok"] == true:
		groom_completed.emit(creature_uid)
	else:
		groom_refused.emit(str(verdict.get("reason", "Grooming could not be committed.")))
	return true


func _current_plan(actor: CharacterBody3D, creature_uid: String) -> Dictionary:
	if not _enabled() or not _reader.is_valid() or not _commit.is_valid():
		return _refusal("unavailable", "The Den's canonical transaction is unavailable.")
	# Grooming is one immediate tap: the Den's own solo modal may pause the
	# world. The trusted per-character policy rejects OTHER modals below.
	if not is_inside_tree() or not multiplayer.is_server() \
			or not is_instance_valid(_world) or not _world.is_inside_tree() \
			or not _world.has_method("world_realm") or _world.call("world_realm") != "meadows" \
			or not is_instance_valid(actor) or not actor.is_inside_tree() \
			or not _world.is_ancestor_of(self) or not _world.is_ancestor_of(actor) \
			or _world.get_world_3d() == null or get_world_3d() != _world.get_world_3d() \
			or actor.get_world_3d() != _world.get_world_3d():
		return _refusal("wrong_residency", "Groom at your live homestead Den.")
	# Reach is measured where the Den's own prompt is offered, as the host's
	# station check and the Forge's channel do.
	var origin: Vector3 = get_parent().call("interaction_origin") if get_parent() != null and get_parent().has_method("interaction_origin") else global_position
	if not actor.global_position.is_finite() or not origin.is_finite() \
			or actor.global_position.distance_to(origin) > float(_config["radius_m"]):
		return _refusal("out_of_radius", "Stand beside the Den to groom.")
	var raw: Variant = _reader.call(actor, _uid)
	if not raw is Dictionary or not raw.get("world") is Dictionary \
			or not raw.get("character") is Dictionary or not raw.get("received_shed_receipts") is Dictionary:
		return _refusal("unavailable", "The character's canonical grooming state is unavailable.")
	for key: String in ["modal_open", "in_combat", "plot_allowed"]:
		if typeof(raw.get(key)) != TYPE_BOOL:
			return _refusal("unavailable", "The character's live Den policy is unavailable.")
	if raw["modal_open"] == true or raw["in_combat"] == true or raw["plot_allowed"] != true:
		return _refusal("not_available", "Groom outside combat at the homestead Den.")
	var world: Dictionary = raw["world"]
	var character: Dictionary = raw["character"]
	if not _identity(world.get("world_id")) or not _identity(world.get("reward_delivery_namespace")) \
			or not _integer(world.get("day"), 1) or not _identity(character.get("character_id")) \
			or not character.get("party") is Array \
			or not _identity(creature_uid):
		return _refusal("unavailable", "The character's canonical grooming state is unavailable.")
	var owned := _shed_roster(character["party"])
	if owned.is_empty():
		return _refusal("unavailable", "The character's canonical grooming state is unavailable.")
	if not _canonical_den(world.get("placed_buildings")):
		return _refusal("missing_station", "Build a Den at the homestead.")
	var shed: Dictionary = SHED.call("den_groom_candidate",character["character_id"], owned,
		creature_uid, int(world["day"]), world["reward_delivery_namespace"],
		raw["received_shed_receipts"], _shed)
	if not bool(shed.get("ok", false)):
		return _refusal(str(shed.get("code", "unavailable")), "This creature cannot be groomed again yet.")
	return {"ok": true, "station_uid": _uid, "station_id": "den", "realm": "meadows",
		"character_id": character["character_id"], "world_id": world["world_id"],
		"world_namespace": world["reward_delivery_namespace"], "host_world_day": int(world["day"]),
		"creature_uid": creature_uid, "shed_candidate": shed.duplicate(true),
		"requires_atomic_training_care": true, "requires_present_manual_tap": true}


func _canonical_den(records: Variant) -> bool:
	if _uid.is_empty() or not records is Array:
		return false
	var canonical := POLICY.record(POLICY.config(),records,_uid)
	if canonical.get("ok") != true or canonical.record.id != "den": return false
	if absf(wrapf(rad_to_deg(global_rotation.y)-float(canonical.record.yaw_deg),-180,180)) > 0.01: return false
	var found := false
	for row: Variant in records:
		if not row is Dictionary or row.get("uid") != _uid:
			continue
		if found or row.get("id") != "den" or row.get("realm", "meadows") != "meadows":
			return false
		var position: Variant = row.get("position")
		if not position is Array or position.size() != 3:
			return false
		for coordinate: Variant in position:
			if not _number(coordinate):
				return false
		if not global_position.is_equal_approx(Vector3(float(position[0]), float(position[1]), float(position[2]))):
			return false
		found = true
	return found

## Called only by the existing ordinary sleep completion after its one rest
## credit. The attachment extends that credit; it never grants another one.
func on_creature_bed_rest_completed(creature: RefCounted, bed_index: int) -> void:
	if not _enabled() or creature == null or not is_inside_tree() \
		or not is_instance_valid(_world) or not _world.is_inside_tree(): return
	var game := get_node_or_null(^"/root/Game")
	if game == null or game.get("world") == null: return
	var cfg := POLICY.config()
	var records: Array = game.get("placed_buildings")
	var source := POLICY.record(cfg,records,_uid)
	if source.get("ok") != true or source.index != bed_index or not _canonical_den(records): return
	var tier := POLICY.effective_tier(cfg,records,_uid)
	if tier.get("ok") != true: return
	var party: RefCounted = game.get("party")
	if party == null or not party.call("members").has(creature): return
	var condition := CONDITION.config()
	var bonus := float(cfg.den.comfort_bonus_per_tier)*int(tier.effective_tier)
	var happiness: Dictionary = condition.get("happiness",{})
	creature.set("rested_seconds_left",float(creature.get("rested_seconds_left"))*(1.0+bonus))
	creature.set("happiness",clampf(float(creature.get("happiness"))+float(happiness.get("on_rest_completed",0.0))*bonus,0.0,float(happiness.get("max",100.0))))


## PlayerState.save_data() uses SaveGame._party_to_array(): species_id is the
## canonical field. The reviewed shed helper accepts species, so translate
## ONLY these validated trusted fields into fresh detached helper rows.
## Never mutate the portable roster or accept its incidental species alias.
static func _shed_roster(party: Array) -> Array:
	if party.is_empty() or party.size() > 5:
		return []
	var seen := {}
	var projected: Array = []
	for row: Variant in party:
		if not row is Dictionary or not _identity(row.get("uid")) or not _identity(row.get("species_id")) \
				or seen.has(row["uid"]):
			return []
		seen[row["uid"]] = true
		projected.append({"uid": row["uid"], "species": row["species_id"]})
	return projected


func _enabled() -> bool:
	return SHED != null and typeof(_config.get("runtime_enabled")) == TYPE_BOOL and _config["runtime_enabled"] == true \
		and _config.get("id") == "den" and _config.get("realm") == "meadows" \
		and _number(_config.get("radius_m")) and float(_config["radius_m"]) > 0.0


static func _identity(value: Variant) -> bool:
	return value is String and not value.strip_edges().is_empty()


static func _number(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value))


static func _integer(value: Variant, minimum: int) -> bool:
	return _number(value) and float(value) == float(int(value)) and int(value) >= minimum


static func _refusal(code: String, reason: String) -> Dictionary:
	return {"ok": false, "submitted": false, "completed": false, "code": code, "reason": reason}


## Read-only frozen night operand, derived from this same mounted canonical Den.
func qualified_night_comfort_bonus(bed_index: int) -> float:
	if not _enabled() or not is_inside_tree() or not is_instance_valid(_world) or not _world.is_inside_tree(): return 0.0
	var game := get_node_or_null(^"/root/Game")
	if game == null or game.get("world") == null: return 0.0
	var cfg := POLICY.config()
	var records: Array = game.get("placed_buildings")
	var source := POLICY.record(cfg, records, _uid)
	if source.get("ok") != true or source.index != bed_index or not _canonical_den(records): return 0.0
	var tier := POLICY.effective_tier(cfg, records, _uid)
	return float(cfg.den.comfort_bonus_per_tier) * int(tier.effective_tier) if tier.get("ok") == true else 0.0
