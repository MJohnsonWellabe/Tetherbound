extends RefCounted

## Which of the things around the player gets the one prompt line.
##
## Pure, static, no nodes — so the rule can be tested without booting a world.
## `interaction_arbiter.gd` is the node that gathers the offers and applies this
## to them; everything interesting about the decision is here.
##
## There is exactly ONE prompt line on screen, deliberately. Grandpa, three
## starters standing a metre apart, a wild pal and every resource node M8 adds
## all want it, and a HUD that stacks four of them is a HUD nobody reads. So
## somebody has to choose, and this is the choosing.
##
## An offer is a plain Dictionary rather than a class so a provider can build one
## without importing anything:
##
##   {"label": "Talk to Grandpa", "distance": 2.4, "priority": 0, "actionable": true}
##
## `label` says what pressing the button does, in the imperative. `distance` is
## metres from the player. `priority` breaks the tie in favour of something other
## than proximity, and `actionable` is false for a line that is a statement
## rather than an offer ("Your pal is out of the fight") — those draw without a
## button glyph and pressing the button does nothing.

## The button glyph, gamepad first. Controller is the primary input
## (CLAUDE.md), so the pad's button is named before the keyboard's.
const BUTTON_HINT := "[X] / [E]"

## Between the glyph and the verb. Three spaces, matching the string this
## replaced in encounter_director._update_prompt(), so no existing prompt moves
## on screen when arbitration goes in.
const GAP := "   "


## The winning offer, or an empty Dictionary when nothing is on offer.
##
## Highest priority first, then nearest, then first registered. Priority before
## distance on purpose: proximity is the right default and is what the player
## intuits, but a status line about the pal at their heels has no meaningful
## distance at all and still has to beat a creature nine metres away.
static func choose(offers: Array) -> Dictionary:
	var index := choose_index(offers)
	return {} if index < 0 else offers[index] as Dictionary


## The winner's index in the array, or -1.
##
## The node needs the index rather than the value: it keeps a parallel array of
## which provider made which offer, and two providers can legitimately produce
## identical Dictionaries — three starters at the same distance answering
## "Choose Terrapup"/"Choose Ripplet" differ, but a pair of berry bushes side by
## side would not. Godot compares Dictionaries by value, so looking the winner
## up with `find()` would pick whichever equal one came first.
static func choose_index(offers: Array) -> int:
	var best := -1
	var best_priority := 0
	var best_distance := 0.0
	for i in offers.size():
		var entry: Variant = offers[i]
		if not entry is Dictionary:
			continue
		var offer: Dictionary = entry
		if str(offer.get("label", "")) == "":
			continue
		var priority := int(offer.get("priority", 0))
		var distance := float(offer.get("distance", 0.0))
		if best < 0 or priority > best_priority or (priority == best_priority and distance < best_distance):
			best = i
			best_priority = priority
			best_distance = distance
	return best


## The line to draw for an offer. Empty string for no offer, so the caller can
## assign it to a Label unconditionally.
static func format(offer: Dictionary) -> String:
	var label := str(offer.get("label", ""))
	if label == "":
		return ""
	if not bool(offer.get("actionable", true)):
		return label
	return "%s%s%s" % [BUTTON_HINT, GAP, label]


## Can the player press the button on this offer right now?
static func is_actionable(offer: Dictionary) -> bool:
	return str(offer.get("label", "")) != "" and bool(offer.get("actionable", true))


## Build an offer. Convenience for providers, and the one place the default
## values are written down.
static func offer(label: String, distance: float, priority: int = 0, actionable: bool = true) -> Dictionary:
	return {
		"label": label,
		"distance": distance,
		"priority": priority,
		"actionable": actionable,
	}
