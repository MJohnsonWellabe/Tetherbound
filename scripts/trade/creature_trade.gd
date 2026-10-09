extends RefCounted

## D39 (OF31). Oskar's creature swap: his one for your one.
##
## Owner: "Make the villagers so I can trade with them. Creatures and
## materials..." The owner chose SWAPS over purchases, and the choice is what
## makes this safe against CLAUDE.md's two hardest rules at once:
##
##   * "Player can own only five creatures total." A swap is `remove_at()` then
##     `add()`, in that order, in one function, with no path between them that
##     can return early. The party size is IDENTICAL before and after -- so a
##     full party stays five and cannot become six, and no cap check is needed
##     at all beyond the one `party.add()` already owns. There is no code here
##     that can produce a sixth creature.
##   * "Trainer-owned creatures cannot be caught." Nothing here catches
##     anything. No orb is thrown, no catch math runs, `game_state.pending_catch`
##     is never touched. Oskar HANDS his creature over; the rule is about
##     capture and is left exactly as it was.
##
## The one extra rule is this file's own: you cannot trade away your last
## creature. An empty party is a soft-lock in everything but name (nothing to
## fight with, nothing to send out, and no way back except catching one with a
## fainted-free party you no longer have), and the owner asked for a trade, not
## a way to lose the game in a conversation.
##
## Nodeless, static, and seeded. The offer is a pure function of the day and the
## config, so re-opening the panel cannot re-roll a better creature, and
## tests/test_trade.gd can check the invariants without a scene.

const CREATURE_INSTANCE := preload("res://scripts/creatures/creature_instance.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")

## Why a swap was refused. "" means it went through.
const OK := ""
const REFUSED_NO_OFFER := "no_offer"
const REFUSED_BAD_SLOT := "bad_slot"
const REFUSED_LAST_CREATURE := "last_creature"
const REFUSED_NO_ROOM := "no_room"
const REFUSED_TAKEN := "already_taken"


static func trader(config: Dictionary, trader_id: String) -> Dictionary:
	var traders: Variant = config.get("creature_traders", {})
	if typeof(traders) != TYPE_DICTIONARY:
		return {}
	var entry: Variant = (traders as Dictionary).get(trader_id, {})
	return entry as Dictionary if typeof(entry) == TYPE_DICTIONARY else {}


static func offers(config: Dictionary, trader_id: String) -> Array:
	var raw: Variant = trader(config, trader_id).get("offers", [])
	return raw as Array if typeof(raw) == TYPE_ARRAY else []


## Which offer stands on `day`, as an index into `offers()`.
##
## Day 1 is the first offer; `rotation_days` days later it is the second, and
## the list wraps forever. Integer arithmetic only -- no rng, no state, no
## "last rolled on" field to save -- so the same day always shows the same
## creature on every load of the same save.
static func offer_index(config: Dictionary, trader_id: String, day: int) -> int:
	var list := offers(config, trader_id)
	if list.is_empty():
		return -1
	var rotation := maxi(1, int(trader(config, trader_id).get("rotation_days", 1)))
	var period := int(floor(float(maxi(1, day) - 1) / float(rotation)))
	return period % list.size()


## The standing offer on `day`: `{ species, level, index, period }`, or {} when
## the trader has no offers at all.
static func offer_for_day(config: Dictionary, trader_id: String, day: int) -> Dictionary:
	var index := offer_index(config, trader_id, day)
	if index < 0:
		return {}
	var raw: Variant = offers(config, trader_id)[index]
	if typeof(raw) != TYPE_DICTIONARY:
		return {}
	var entry := raw as Dictionary
	var rotation := maxi(1, int(trader(config, trader_id).get("rotation_days", 1)))
	return {
		"species": str(entry.get("species", "")),
		"level": maxi(1, int(entry.get("level", 1))),
		"index": index,
		"period": int(floor(float(maxi(1, day) - 1) / float(rotation))),
	}


## The actual creature standing behind the offer.
##
## `species_definition` is the entry out of data/creatures/species.json (the
## caller has it; this file deliberately does not read game data). The
## individuality and trait rolls are drawn from a stream seeded on the trader,
## the species and the ROTATION PERIOD -- so the creature you are shown when you
## open the panel is the same creature you get when you confirm, and the same
## one again if you close the panel and think about it over lunch. Rolling per
## call would make "look again" a slot machine.
static func offered_creature(
	offer: Dictionary, species_definition: Dictionary, trader_id: String,
	progression_config: Dictionary = {}
) -> RefCounted:
	if offer.is_empty() or species_definition.is_empty():
		return null
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s|%s|%d" % [trader_id, str(offer.get("species", "")), int(offer.get("period", 0))])
	var ivs: Array = [rng.randf(), rng.randf(), rng.randf()]
	var traits: Array = [rng.randf()]
	var creature: RefCounted = CREATURE_INSTANCE.from_species(
		str(offer.get("species", "")), species_definition, -1.0, {}, ivs, traits
	)
	if creature == null:
		return null
	# Levelled through the real progression path rather than by writing `level`
	# and leaving the stats at level 1 -- `set_level` recomputes from base stats
	# (D30), which is the same call a level-up makes. An empty config would
	# quietly collapse growth to base stats, so the real one is loaded (it is
	# cached statically) when a caller does not hand one in.
	var cfg := progression_config if not progression_config.is_empty() else PROGRESSION.config()
	creature.call("set_level", int(offer.get("level", 1)), cfg)
	creature.hp = creature.max_hp
	return creature


## --- the transaction ------------------------------------------------------------

## Give `party`'s creature at `give_index` to the trader and take `incoming` in
## its place. Returns "" on success, or a REFUSED_* reason.
##
## The order is remove-then-add and that is load-bearing: with a full party of
## five, adding first would hit `party.add()`'s cap and refuse, and any "make
## room first" version of this would be a five-cap check written a second time
## somewhere else. Removing first means the cap is never even approached -- the
## party is at four for the width of two statements and back to five after.
static func swap(party: RefCounted, give_index: int, incoming: RefCounted) -> String:
	if incoming == null:
		return REFUSED_NO_OFFER
	if party == null:
		return REFUSED_BAD_SLOT
	var outgoing: RefCounted = party.call("at", give_index)
	if outgoing == null:
		return REFUSED_BAD_SLOT
	# CLAUDE.md caps the party at five; nothing caps it at one, so this rule is
	# stated here explicitly rather than assumed.
	if int(party.call("size")) <= 1:
		return REFUSED_LAST_CREATURE

	party.call("remove_at", give_index)
	if not bool(party.call("add", incoming)):
		# Unreachable: a slot was just freed. Put the player's creature back
		# rather than leaving them one short of what they started with.
		party.call("add", outgoing)
		return REFUSED_NO_ROOM
	return OK


## The progression flag that records "this offer has already been taken".
##
## One swap per rotation period, and the reason is roster laundering: without
## it, a player standing in front of Oskar could hand over all five of their
## creatures one after another and walk out with five copies of whatever the
## day's offer is. Nothing about the five-cap breaks if they do -- the party is
## five either way -- but a village trade that quietly replaces your whole team
## in one conversation is not what the owner asked for. Keyed by PERIOD rather
## than by day so the flag and the offer rotate together.
##
## A flat flag id in `autoload/progression_state.gd`, the same store the road
## gate and Tam's handover already write to (D43). A handful of these over a
## 3-4 hour chapter (D42) is a handful of short strings in the save.
static func swap_flag(trader_id: String, period: int) -> String:
	return "%s_swap_taken_%d" % [trader_id, period]


static func refusal_text(reason: String) -> String:
	match reason:
		REFUSED_TAKEN:
			return "Today's trade is already done. Come back when the offer changes."
		REFUSED_NO_OFFER:
			return "There is nothing on offer today."
		REFUSED_BAD_SLOT:
			return "Pick one of your own creatures first."
		REFUSED_LAST_CREATURE:
			return "Not your last one. You would be walking out of here alone."
		REFUSED_NO_ROOM:
			return "That trade cannot be made."
		OK:
			return ""
		_:
			return "That trade cannot be made."
