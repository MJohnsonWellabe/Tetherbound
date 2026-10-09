extends RefCounted

## Coordinator ruling R2: a retained foundation event's duty is settled for a
## character durably, in the world, once that character's training decision
## for it is accepted; and the event row is retired once every duty on it is
## settled. Before this, a duty counted as settled only while its receipt
## survived in the latest training row, so every landed mastery hit and every
## trainer round kept a receipt (and a world row) forever and a long clear
## reached the 4096 receipt cap.
##
## Durable carrier (optional schema key, absent on v28 worlds):
##   redesign_world.retained_settlement[event_delivery_id] = ["<character>|<action>", ...]
## The entry is removed together with its event row when the event retires.

const FIELD := "retained_settlement"
## Only the high-frequency retained kinds are settled and retired; boss relics,
## Master wins, research, bounties, rematches and capture offers keep their
## receipt-based behaviour (their volume is bounded by content).
const SAFE_ACTIONS := ["combat_mastery", "combat_round_reward"]
## Original inventory, night and discovery decisions settle only on real
## accepted owner ACKs; their source identities are never retired/windowed.
const PERSISTENT_ACTIONS := ["ledger_inventory", "rest_complete", "rest_discovery"]
const MAX_KEYS_PER_EVENT := 16


static func key(character_id: String, action: String) -> String:
	return character_id + "|" + action


static func settled_keys(redesign_world: Dictionary, event_id: String) -> Array:
	var all: Variant = redesign_world.get(FIELD, {})
	var row: Variant = all.get(event_id) if all is Dictionary else null
	return (row as Array).duplicate() if row is Array else []


static func duty_settled(redesign_world: Dictionary, event_id: String, duty: Dictionary) -> bool:
	return settled_keys(redesign_world, event_id).has(key(str(duty.get("character_id", "")), str(duty.get("action", ""))))


## The settlement after an accepted training `row`, as [settled keys, retire]:
## retire is true when every duty of `event` is then settled. [] when the row
## does not settle exactly one duty of this event (nothing changes).
static func after_accept(redesign_world: Dictionary, event: Dictionary, row: Dictionary) -> Array:
	var character := str(row.get("character_id", ""))
	var action := str(row.get("action", ""))
	if action not in SAFE_ACTIONS and action not in PERSISTENT_ACTIONS: return []
	var matches := 0
	for duty: Variant in event.get("duties", []):
		if duty is Dictionary and str(duty.get("character_id", "")) == character and str(duty.get("action", "")) == action:
			matches += 1
	if matches != 1: return []
	var keys := settled_keys(redesign_world, str(event.delivery_id))
	var settled := key(character, action)
	if not keys.has(settled):
		if keys.size() >= MAX_KEYS_PER_EVENT: return []
		keys.append(settled)
	var retire := true
	for duty: Variant in event.duties:
		# Original trade/drop identities must survive host restart, where the
		# ledger's transient seen-txn set no longer fences a repeated intent.
		if duty.get("action") == "ledger_inventory": retire = false
		if not str(duty.get("action", "")) in SAFE_ACTIONS \
				or not keys.has(key(str(duty.get("character_id", "")), str(duty.get("action", "")))):
			retire = false
	return [keys, retire]


static func valid(raw: Variant) -> bool:
	if raw == null: return true
	if not raw is Dictionary: return false
	for event_id: Variant in raw:
		if not event_id is String or not (event_id as String).begins_with("foundation_event:") \
				or not raw[event_id] is Array or (raw[event_id] as Array).size() > MAX_KEYS_PER_EVENT: return false
		for entry: Variant in raw[event_id]:
			if not entry is String or not (entry as String).contains("|"): return false
	return true
