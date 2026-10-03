extends RefCounted

## Scheduling only: retain references to the host's immutable event/duty.
## A completed progression reward precedes ordinary hit history only after
## the latest canonical decision is accepted. Pending or unknown decisions
## keep their original order so receipt/owner ACK recovery remains first.
const EVENT := preload("res://scripts/net/foundation_event.gd")
const WORLD := preload("res://autoload/world_state.gd")
const ESSENCE := preload("res://scripts/creatures/essence.gd")
const PROGRESSION := ["master_win", "boss_relic", "combat_round_reward"]

static func ordered(deliveries: Dictionary, namespace_id: String, world_id: String) -> Array[Dictionary]:
	var progression: Array[Dictionary] = []
	var ordinary: Array[Dictionary] = []
	var accepted := {} # Canonical row checks cached only for this scan.
	var absent := {}
	for raw: Variant in deliveries.values():
		if not EVENT.valid(raw, namespace_id, world_id): continue
		for duty: Dictionary in raw.duties:
			var work := {"event": raw, "duty": duty}
			if duty.action in PROGRESSION:
				if not accepted.has(duty.character_id):
					var latest: Variant = deliveries.get(ESSENCE.training_delivery_id(namespace_id, duty.character_id))
					absent[duty.character_id] = latest == null
					accepted[duty.character_id] = WORLD.training_row_valid(latest, namespace_id, world_id) \
						and latest.character_id == duty.character_id and latest.status == "accepted"
				if accepted[duty.character_id] or (duty.action == "combat_round_reward" and absent[duty.character_id]):
					progression.append(work)
					continue
			ordinary.append(work)
	progression.append_array(ordinary)
	return progression
