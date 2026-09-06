extends RefCounted

## Stage B Wave 4 lane 4.D. WHAT A BEATEN TRAINER OWES, as plain intents.
##
## `docs/specs/MP_ENCOUNTER_PROTOCOL.md` §7, in one sentence:
##
##     **The world fact happens once. The personal reward happens per
##     participant.**
##
## Those are two different things and this file keeps them two different
## things. `world_facts()` returns the `set_world_flag` intents the victory owes
## the WORLD -- the trainer's `defeat_flag` and any world-scoped reward flag --
## committed once each, so a second peer arriving later finds them beaten
## because that is what the world says.
## `grants()` returns one `reward_grant` per COMPONENT of the payout, each
## addressed to EVERY participant, because a shared victory pays everybody who
## was in it.
##
## ## Pure, for `world_ledger.gd`'s reason
##
## No scene tree, no `Game`, no ledger, no node. This file decides what to ask
## for; `encounter_director.gd` submits it and `world_ledger.gd` decides whether
## it is owed. That split is what lets `tests/test_encounter_rewards.gd` assert
## the arithmetic -- and above all the arithmetic that is NOT done -- against no
## world at all.
##
## ## The one number that is not here
##
## Nothing divides by participant count. §7 is explicit and
## `data/config/multiplayer.json`'s `encounter.reward.divide_by_participants`
## says the same thing where a future edit has to argue with it: a fight that
## pays half as much for having a friend along teaches people to play alone.
## The authored coins, items and `xp_bonus` are what EACH participant is owed.
##
## ## Why one grant per component and not one grant carrying everything
##
## `world_ledger.gd::_reward_grant()` guards a replay with
## `reward_flag(source, peer_id)` -- one receipt per participant per SOURCE.
## It carries one item and one flag. So a trainer paying coins, a potion and a
## realm key is three sources, and each is guarded on its own. The alternative
## -- one source for the whole payout -- means a satchel that was full when the
## coins landed has burnt the receipt for the potion too, and nothing can ever
## pay it. Distinct sources cost one dictionary each and make each half of a
## payout independently owed.
##
## The ids are stable strings (`trainer:<id>:coins`, `trainer:<id>:item:<item>`,
## `trainer:<id>:flag:<flag>`, `trainer:<id>:xp`) because they are written into
## a save as receipt flags. Renaming one re-pays every player who ever beat that
## trainer, so they are treated as durable data and not as an implementation
## detail.

const TRAINERS := preload("res://scripts/world/trainer_npc.gd")
## D99's scope table (`data/progression/flag_scopes.json`), consulted rather
## than guessed at. Every `reward.flags` entry in the shipped trainer table is
## WORLD-scoped today -- `recipe_saddle`, `realm_key_cloudreach`,
## `realm_heart_meadows_earned` -- so all three belong with the world fact and
## are committed once, not once per participant. Routing by the table instead of
## by that observation is what stops the first player-scoped reward flag
## somebody authors from silently becoming a world fact.
const PROGRESSION_STATE := preload("res://autoload/progression_state.gd")


## The trainer id every source below is built from. "" for a spec with no id,
## which `world_facts()`/`grants()` both refuse rather than mint a receipt
## nobody can ever match again.
static func trainer_key(spec: Dictionary) -> String:
	return str(spec.get("id", ""))


## `trainer:<id>:<component>` -- the `source` a `reward_grant` is guarded by.
static func source_for(trainer_id: String, component: String) -> String:
	return "trainer:%s:%s" % [trainer_id, component]


## §7's world half: the facts that happen ONCE, whoever won and however many of
## them there were. The trainer's `defeat_flag` first, then every WORLD-scoped
## entry in their `reward.flags`.
##
## `[]` when the trainer names no `defeat_flag` -- beating them changes nothing
## about the world, which `trainer_npc.gd` already warns about, and a payout
## keyed off an unidentifiable trainer would write `reward::<peer>` receipts
## nothing could ever match again.
##
## Deliberately NOT conditional on a flag already being set: `world_ledger.gd`
## answers that with `code: "noop"` and a committed empty delta, which is the
## correct answer to "somebody already beat them" and is not an error to show a
## player. It is also the whole of §7's second sentence -- a second peer
## arriving later finds the trainer already beaten, because that is what the
## world says.
static func world_facts(spec: Dictionary, realm: String) -> Array:
	var out: Array = []
	var flag := str(spec.get("defeat_flag", ""))
	if flag.is_empty() or realm.is_empty():
		return out
	out.append({"kind": "set_world_flag", "realm": realm, "id": flag})
	for extra: String in TRAINERS.reward_flags(spec):
		if PROGRESSION_STATE.scope_of(extra) == "world":
			out.append({"kind": "set_world_flag", "realm": realm, "id": extra})
	return out


## §7's personal half: every component of this trainer's authored payout, each
## addressed to every participant.
##
## `participants` is the encounter record's own participant list. Duplicates are
## dropped -- a peer that appears twice is one peer, and paying it twice is the
## exact failure `reward_flag()` exists to prevent, so it is not left to the
## ledger to notice.
##
## Returns `[]` for a trainer with no payout at all, which is most of the table:
## the ordinary per-creature XP the fight already paid is what those trainers
## are worth, and an empty array is the honest description of that.
static func grants(spec: Dictionary, realm: String, participants: Array) -> Array:
	var out: Array = []
	var trainer_id := trainer_key(spec)
	if trainer_id.is_empty() or realm.is_empty():
		return out
	var peers := unique_peers(participants)
	if peers.is_empty():
		return out

	var coins := TRAINERS.reward_coins(spec)
	if coins > 0:
		out.append(_grant(realm, source_for(trainer_id, "coins"), peers, "coin", coins, ""))

	for entry: Variant in TRAINERS.reward_items(spec):
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var item := str((entry as Dictionary).get("id", ""))
		var count := int((entry as Dictionary).get("count", 1))
		if item.is_empty() or count <= 0:
			continue
		out.append(_grant(realm, source_for(trainer_id, "item:" + item), peers, item, count, ""))

	# Only the flags D99 calls PERSONAL. A world-scoped reward flag is part of
	# `world_facts()` above and granting it per participant would write the same
	# world fact once per player, which is the duplication §7's first sentence
	# exists to forbid.
	for flag: String in TRAINERS.reward_flags(spec):
		if PROGRESSION_STATE.scope_of(flag) == "world":
			continue
		out.append(_grant(realm, source_for(trainer_id, "flag:" + flag), peers, "", 0, flag))

	# The XP receipt carries no item and no flag on purpose. XP cannot be an
	# op: a peer's party is its own (D100) and the host has never seen it, so
	# the host cannot add a level to somebody else's creature and must not
	# pretend to. What the ledger gives back is `paid` -- the participants who
	# had not been paid yet -- and that list is who the host then TELLS, so each
	# peer applies the bonus to its own party. The receipt is the guard; the
	# announcement is the payment.
	if TRAINERS.reward_xp_bonus(spec) > 0:
		out.append(_grant(realm, source_for(trainer_id, "xp"), peers, "", 0, ""))

	return out


## The flat `xp_bonus` EACH participant is owed. Not divided, not shared, not
## scaled by how many people turned up (§7).
static func xp_bonus(spec: Dictionary) -> int:
	return maxi(0, TRAINERS.reward_xp_bonus(spec))


## Is `grant` the XP component -- the one a peer has to apply itself?
static func is_xp_grant(grant: Dictionary, trainer_id: String) -> bool:
	return str(grant.get("source", "")) == source_for(trainer_id, "xp")


## The participants, de-duplicated, in the order they were handed over. Ints,
## because the record's `participants` keys arrive as whatever the transport
## made of them and a peer id that is a float compares unequal to itself as a
## dictionary key.
static func unique_peers(participants: Array) -> Array:
	var out: Array = []
	for raw: Variant in participants:
		var id := int(raw)
		if id != 0 and not out.has(id):
			out.append(id)
	return out


static func _grant(realm: String, source: String, peers: Array, item: String,
		count: int, flag: String) -> Dictionary:
	var intent := {
		"kind": "reward_grant",
		"realm": realm,
		"source": source,
		# A copy, never the caller's array: the caller is holding the encounter
		# record's participant list and a grant that aliased it would rewrite
		# the fight when somebody edited a payout.
		"peers": peers.duplicate(),
	}
	if not item.is_empty() and count > 0:
		intent["item"] = item
		intent["count"] = count
	if not flag.is_empty():
		intent["flag"] = flag
	return intent
