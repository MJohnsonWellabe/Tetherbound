extends "res://scripts/combat/encounter_director.gd"

## Reuses production deployment, host encounter authority, catches and rewards.
## Only the authored population and realm-specific admission rules differ.
const CATALOGUE := preload("res://scripts/combat/stormwood_encounter_catalogue.gd")
var population_ready := false

func _init() -> void:
	default_starter = ""

func spawns_config() -> Dictionary:
	if _spawns_cfg.is_empty():
		_spawns_cfg = CATALOGUE.wild_config("calm")
	return _spawns_cfg

func _spawn_creatures() -> void:
	await super._spawn_creatures()
	population_ready = true
	print("STORMWOOD ENCOUNTERS READY wild=", _wild_creatures.size())

func can_challenge(spec: Dictionary) -> bool:
	if str(spec.get("id", "")) == "captain_marrow_dynamo_core":
		var dynamo := get_parent().get_node_or_null("StormwoodDynamo")
		if dynamo == null or not dynamo.has_method("arena_ready") or not bool(dynamo.call("arena_ready")):
			return false
	for flag: String in spec.get("requires_flags", []):
		if not _progression().has(flag):
			return false
	return super.can_challenge(spec)

func _wander_target_clear_of_road(at: Vector3) -> bool:
	var world := get_parent()
	var height := float(world.call("ground_height_at", at.x, at.z))
	if not is_finite(height) or height < 0:
		return false
	# The Crown's discontinuity is a real boundary for wildlife as well as
	# trainers. A short step must not wander over the Glass Sink's rim.
	return absf(height - at.y) < 6.0
