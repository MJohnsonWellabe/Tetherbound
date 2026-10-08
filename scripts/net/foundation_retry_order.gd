extends RefCounted

## Scheduling only: retain references to the host's immutable event/duty.
## Completed progression and research precede ordinary hit history only after
## the latest canonical decision is accepted. Pending or unknown decisions
## keep their original order so receipt/owner ACK recovery remains first.
const EVENT := preload("res://scripts/net/foundation_event.gd")
const WORLD := preload("res://autoload/world_state.gd")
const ESSENCE := preload("res://scripts/creatures/essence.gd")
const PROGRESSION := ["master_win", "boss_relic", "combat_round_reward", "wild_defeat_share", "research_event"]

static func ordered(deliveries: Dictionary, namespace_id: String, world_id: String) -> Array[Dictionary]:
	var progression: Array[Dictionary] = []
	var ordinary: Array[Dictionary] = []
	var inventory: Array[Dictionary] = []
	var accepted := {} # Canonical row checks cached only for this scan.
	var absent := {}
	for raw: Variant in deliveries.values():
		if not EVENT.valid(raw, namespace_id, world_id): continue
		for duty: Dictionary in raw.duties:
			var work := {"event": raw, "duty": duty}
			if duty.action == "ledger_inventory":
				inventory.append(work)
				continue
			if duty.action in PROGRESSION:
				if not accepted.has(duty.character_id):
					var latest: Variant = deliveries.get(ESSENCE.training_delivery_id(namespace_id, duty.character_id))
					absent[duty.character_id] = latest == null
					accepted[duty.character_id] = WORLD.training_row_valid(latest, namespace_id, world_id) \
						and latest.character_id == duty.character_id and latest.status == "accepted"
				if accepted[duty.character_id] or (duty.action in ["combat_round_reward", "wild_defeat_share"] and absent[duty.character_id]):
					progression.append(work)
					continue
			ordinary.append(work)
	# Save dictionaries may load in key order. Original transfer/drop sequence
	# orders their owner halves even when several are waiting behind one BOOL.
	inventory.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.duty.intent.source_sequence) < int(b.duty.intent.source_sequence))
	inventory.append_array(progression)
	inventory.append_array(ordinary)
	return inventory
