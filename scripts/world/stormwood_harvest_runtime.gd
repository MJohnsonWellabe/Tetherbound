extends Node3D

## Mount-only adapter for Stormwood's authored harvest catalogue. It reuses the
## permanent, ledger-backed HarvestNode path; this file does not add a local
## phase check or alter host authority.

const HARVEST_NODE := preload("res://scripts/world/harvest_node.gd")
const ARCH_BUILD := preload("res://scripts/world/stormwood_arch_build_rules.gd")

const DATA_PATH := "res://data/config/stormwood_harvests.json"
const REALM_ID := "stormwood"
const REGION_PREREQUISITES := {
	"cinder_verge": "",
	"glowmoss_hollows": "",
	"conductor_run": "",
	"hollow_crown": "stormwood:crown_reached",
	"deepwood": "stormwood:rootgate_released",
	"dynamo": "stormwood:rootgate_released",
}

var world: Node3D
var _game: Node
var _flags: RefCounted
var _placements: Dictionary = {}
var _revision := -1
var _event_check_left := 0.0
var _catalogue: Dictionary = {}
var _crown_glass_required := -1


static func read(path: String = DATA_PATH) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


## Shared catalogue identity reaches the host's phase and first-claim rules.
static func authority_contract() -> Dictionary:
	return {
		"intent_kind": "stormwood_harvest",
		"harvest_override": "res://scripts/world/harvest_node.gd::_on_gathered",
		"ledger_override": "res://scripts/net/world_ledger.gd::_stormwood_harvest",
	}


func mount(owner_world: Node3D) -> void:
	world = owner_world
	_catalogue = read()
	_game = get_node_or_null(^"/root/Game")
	_flags = _game.get("progression") if _game != null else null
	add_to_group("progression_restore")
	sync_progression()


func _process(delta: float) -> void:
	if _flags != null and int(_flags.get("revision")) != _revision:
		_revision = int(_flags.get("revision"))
		sync_progression()
	_event_check_left -= delta
	if _flags != null and _event_check_left <= 0.0:
		_event_check_left = 0.5
		if not bool(world.get("simulation_only")) and not _flags.has("stormwood:first_stormglass_gathered"):
			for spec: Dictionary in _catalogue.get("sites", []):
				if str(spec.region_id) == "cinder_verge" and str(spec.item) == "stormglass" and _flags.has("harvest_node:order:" + str(spec.id)):
					world.get_node("StormwoodChapter").emit_event("harvest:verge_stormglass")
					break
		# Crown Stormglass can be claimed before its chapter recipe prerequisite.
		# Reconcile the durable host-ledger claim independently so learning the
		# recipe later cannot leave the ordinary story route dead-ended.
		if not bool(world.get("simulation_only")) \
				and _flags.has("stormwood:arch_recipe_known") \
				and not _flags.has("stormwood:crown_glass_gathered"):
			if _crown_glass_required < 0:
				_crown_glass_required = crown_glass_cost()
			if _crown_glass_required > 0 and claimed_crown_glass(_catalogue, _flags) >= _crown_glass_required:
				world.get_node("StormwoodChapter").emit_event("harvest:crown_grade")


static func crown_glass_cost() -> int:
	for footing: Dictionary in ARCH_BUILD.ARCHES.config().get("footings", []):
		if str(footing.get("fixed_twin", "")) != "e_crown":
			continue
		var at: Array = footing.at
		var total := 0
		for need: Dictionary in ARCH_BUILD.cost(Vector3(float(at[0]), 0.0, float(at[1]))):
			if str(need.id) == "stormglass_crown":
				total += int(need.n)
		return total
	return 0


## This world objective records shared gathering, not one player's current
## inventory. The ledger still grants each yield only to its claiming peer;
## the builder must hold and pay the complete production cost separately.
static func claimed_crown_glass(catalogue: Dictionary, flags: RefCounted) -> int:
	var total := 0
	var seen := {}
	for spec: Dictionary in catalogue.get("sites", []):
		var id := str(spec.get("id", ""))
		if id.is_empty() or seen.has(id) or str(spec.get("grade", "")) != "crown" \
				or str(spec.get("item", "")) != "stormglass_crown" \
				or not flags.has("harvest_node:order:" + id):
			continue
		seen[id] = true
		total += maxi(0, int(spec.get("amount", 0)))
	return total


func restore_progression_from_game(game: Node) -> void:
	_game = game
	_flags = game.get("progression") if game != null else null
	# HarvestNode restores its own flag. Keep pending winners alive until their
	# delta callback settles tool wear and feedback.
	sync_progression()


func sync_progression() -> void:
	if world == null or _game == null or _flags == null:
		return
	_revision = int(_flags.get("revision"))
	var items: RefCounted = _game.get("items")
	for raw: Variant in (_catalogue.get("sites", []) as Array):
		if not (raw is Dictionary):
			continue
		var spec := raw as Dictionary
		var id := str(spec.get("id", ""))
		var item := str(spec.get("item", ""))
		if _placements.has(id) and not is_instance_valid(_placements[id]) and not _flags.has("harvest_node:order:" + id):
			_placements.erase(id)
		if id.is_empty() or item.is_empty() or _placements.has(id):
			continue
		if items == null or not bool(items.call("has", item)):
			continue # The item payload has not been integrated yet.
		var prerequisite := str(REGION_PREREQUISITES.get(str(spec.get("region_id", "")), ""))
		if not prerequisite.is_empty() and not bool(_flags.call("has", prerequisite)):
			continue
		_mount_site(spec)


func _mount_site(spec: Dictionary) -> void:
	var point: Array = spec.get("position", []) as Array
	if point.size() != 2:
		return
	var x := float(point[0])
	var z := float(point[1])
	var node := HARVEST_NODE.new()
	node.name = str(spec.get("id", "StormwoodHarvest"))
	add_child(node)
	node.global_position = Vector3(x, _ground_height(x, z), z)
	node.set_meta("stormwood_harvest_intent", str(spec.get("intent_kind", "")))
	node.set_meta("stormwood_harvest_site", str(spec.id))
	node.set_meta("stormwood_region", str(spec.region_id))
	node.set_meta("stormwood_item", str(spec.item))
	node.setup({
		"item": str(spec.get("item", "")),
		"amount": int(spec.get("amount", 1)),
		"label": "Gather " + str(spec.get("item", "resource")).capitalize(),
		"model": str(spec.get("model", "")),
		"model_scale": float(spec.get("model_scale", 1.0)),
		"order": str(spec.get("id", "")),
		"realm": REALM_ID,
	})
	_placements[str(spec.get("id", ""))] = node


func _ground_height(x: float, z: float) -> float:
	if world != null and world.has_method("ground_height_at"):
		return float(world.call("ground_height_at", x, z))
	return 0.0
