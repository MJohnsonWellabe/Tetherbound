extends Node

const RULES := preload("res://scripts/repeatables/alpha_respawns.gd")
var _read: Callable
var _commit: Callable
var _publish: Callable

## Shared world writer supplies atomic before/after CAS + exact bool-save.
## Publishing only instantiates/reattaches the retained host generation; it
## never grants first rewards, changes a story flag or copies a caught UID.
func bind_host(read_host_world: Callable, commit_host_plan: Callable, publish_generation: Callable) -> bool:
	if not read_host_world.is_valid() or not commit_host_plan.is_valid() or not publish_generation.is_valid(): return false
	_read = read_host_world
	_commit = commit_host_plan
	_publish = publish_generation
	return true

func advance(site_id: String) -> Dictionary:
	if RULES.config().get("runtime_enabled") != true or not _read.is_valid(): return {"ok": false, "code": "alpha_producer_not_mounted"}
	var host: Variant = _read.call(site_id)
	if not host is Dictionary or host.get("is_host") != true: return {"ok": false, "code": "host_required"}
	var packet := RULES.retained_spawn(host.redesign_world, site_id)
	if not packet.is_empty():
		return {"ok": _publish.call(site_id, packet) == true, "code": "reattach_retained_generation"}
	var proposal := RULES.spawn(host.redesign_world, site_id, host.world_namespace,
		int(host.world_seconds), host.night, host.weather)
	return _settle(proposal, true)

## Resolution/departure closures must be called from authenticated host
## lifecycle callbacks. Clients have no callable path to these contexts.
func resolve(site_id: String, context: Dictionary) -> Dictionary:
	if RULES.config().get("runtime_enabled") != true or context.get("is_host") != true \
		or context.get("validated_host_resolution") != true: return {"ok": false, "code": "accepted_host_resolution_required"}
	return _settle(RULES.resolve(context.redesign_world, site_id, int(context.generation),
		int(context.world_seconds), context.region_characters, context.outcome), false)

func depart(site_id: String, context: Dictionary) -> Dictionary:
	if RULES.config().get("runtime_enabled") != true or context.get("is_host") != true \
		or context.get("validated_region_transition") != true: return {"ok": false, "code": "accepted_host_departure_required"}
	return _settle(RULES.depart(context.redesign_world, site_id, int(context.generation), context.character_id, context.actual_region), false)

func _settle(proposal: Dictionary, publish: bool) -> Dictionary:
	if proposal.is_empty() or not _commit.is_valid(): return {"ok": false, "code": "alpha_not_eligible"}
	var result: Variant = _commit.call(proposal)
	if not result is Dictionary or result.get("ok") != true or result.get("durable") != true:
		return result if result is Dictionary else {"ok": false, "code": "alpha_world_save_failed"}
	if publish: result.published = _publish.is_valid() and _publish.call(proposal.site_id, proposal.record.spawn_traits) == true
	return result
