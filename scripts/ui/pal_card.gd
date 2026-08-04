extends RefCounted

## How a pal is put into words, in one place, so two screens cannot describe the
## same creature differently.
##
## This was the private half of `party_screen.gd` until M5's release ceremony
## needed the same paragraph. It is LIFTED rather than copied for `ui_style.gd`'s
## reason about the colours it holds: each line here is an answer to a measured
## complaint — the trait is named once and not twice, the verdict is a word and
## not a ratio, the star count is a count and never a float — and a second copy
## would drift away from the complaint that produced it.
##
## It matters more here than it did for colours. The ceremony asks the player to
## compare six pals and lose one forever; if the party menu calls a pal
## "Promising" and the release screen calls the same pal something else, the
## player has been given two different reasons and one irreversible button.
##
## Nothing here draws, holds state or touches a node. Statics over an Object,
## because every caller reads a pal out of `scripts/pals/`, which is another
## agent's file — see `_number` below for what that costs and why it is worth it.
##
## ONE DIRECTION ONLY, exactly as `party_screen.gd` says: the UI may ask the data
## layer what a trait is called; the data layer must never ask the UI anything.

const STYLE := preload("res://scripts/ui/ui_style.gd")

## What a trait is CALLED. Read-only.
const TRAITS := preload("res://scripts/pals/pal_traits.gd")

## The words for an overall appraisal, worst to best.
##
## Words rather than a number, because GAME_DESIGN.md §11 says appraisal is shown
## "through stars/bars, not exact IV numbers", and because "Promising" is
## something you can feel about a creature in a way that 0.62 is not.
const VERDICTS := ["Poor", "Ordinary", "Promising", "Excellent", "Exceptional"]

## Keys whose display name is not just the key capitalised.
const KEY_NAMES := {
	"hp": "HP",
	"max_hp": "HP",
	"atk": "Attack",
	"attack": "Attack",
	"def": "Defence",
	"defence": "Defence",
	"defense": "Defence",
	"iv": "Quality",
	"overall": "Overall",
}


# -------------------------------------------------------------- reading a pal

## Read a number off something that may not have it.
##
## Every property a screen reads belongs to another agent's file. A missing one
## comes back as null, and `int(null)` and `float(null)` are runtime errors —
## which would take a menu that is 95% correct and turn it into a red screen. A
## wrong-looking number is a bug report; a crash in a menu is an evening. In the
## release ceremony it is worse than an evening: the screen the player cannot
## leave is the screen that must never fall over.
static func number(target: Object, key: String, fallback: float) -> float:
	if target == null:
		return fallback
	var value: Variant = target.get(key)
	if value is int or value is float:
		return float(value)
	return fallback


## The name to show. `display()` is the pal's own answer to "nickname if set,
## else species name" and no screen second-guesses it — a menu that re-derived
## the name would be the place a nickname stopped showing up.
static func display_of(member: Object) -> String:
	if member == null:
		return "?"
	if member.has_method("display"):
		return str(member.call("display"))
	var fallback := str(member.get("display_name"))
	return fallback if fallback != "" and fallback != "<null>" else "?"


## The species' own name — "Bramblit" — or "" when it is the same string the
## heading already shows. `species_id` is `starter_ground`, an id that belongs in
## a data file and not on a screen.
static func species_of(member: Object) -> String:
	if member == null:
		return ""
	var species_name := str(member.get("display_name"))
	if species_name == "" or species_name == "<null>":
		return ""
	return species_name


## The trait, in words.
##
## Asks the trait table directly rather than humanising `trait_id`, so a row and
## the appraisal panel beside it cannot end up calling the same trait two
## different things. `pal_traits.gd` caches its table in a static, so a handful
## of lookups a frame is a handful of dictionary reads.
##
## The humanised id survives as the fallback for a trait that is in a pal but not
## in the table, which is a data bug that should still leave a readable screen.
static func trait_of(member: Object) -> String:
	if member == null:
		return "no trait"
	var id := str(member.get("trait_id"))
	if id == "" or id == "<null>":
		return "no trait"
	if TRAITS.has(id):
		var named := str(TRAITS.display_name(id))
		if named != "":
			return named
	return humanise(id)


static func is_down(member: Object) -> bool:
	if member == null:
		return false
	if member.get("fainted") == true:
		return true
	return number(member, "hp", 1.0) <= 0.0


## The appraisal payload, or an empty Dictionary for a pal that has none. Guarded
## rather than called directly for `number()`'s reason.
static func appraisal_of(member: Object) -> Dictionary:
	if member == null or not member.has_method("appraisal"):
		return {}
	var data: Variant = member.call("appraisal")
	return data if data is Dictionary else {}


# ------------------------------------------------------------------ the words

## The whole right-hand panel for one pal: species, vitals, then the appraisal.
##
## Returned as lines rather than as one string so a caller can put something of
## its own between them — the ceremony marks which of the six is the newcomer —
## without having to split a paragraph back apart.
static func detail_lines(member: Object) -> Array[String]:
	var lines: Array[String] = []
	if member == null:
		return lines
	# The SPECIES name, and only when a nickname is hiding it. Showing it under a
	# pal that has no nickname would just repeat the heading.
	var species_name := species_of(member)
	if species_name != "" and species_name != display_of(member):
		lines.append("[color=#%s]%s[/color]" % [STYLE.INK_DIM, species_name])
	lines.append(vitals_line(member))
	# The trait is NOT repeated here — `appraisal_lines` states it once, with the
	# description that says what it does. It was in both places and read as the
	# screen stuttering.
	lines.append("")
	lines.append_array(appraisal_lines(member))
	return lines


## Level and health, the one line every screen shows about a pal.
static func vitals_line(member: Object) -> String:
	return "[b]Level %d[/b]        %d / %d HP" % [
		int(number(member, "level", 1.0)),
		roundi(number(member, "hp", 0.0)),
		roundi(number(member, "max_hp", 1.0)),
	]


## The appraisal, as a verdict and a short list of bars.
##
## The data layer decides what an appraisal contains; this only decides how to
## say it. That split is deliberate — what makes a pal good is a design question
## that belongs in `scripts/pals/`, and a formatter that hard-codes the four
## stats it knows about is one that silently drops the fifth.
##
## Assembled from `appraisal_stat_lines` and `trait_lines` rather than written out
## again, so the single-column panel the party menu draws and the two-column one
## the release ceremony draws cannot word the same pal differently. The output is
## unchanged, line for line, from when this was one function.
static func appraisal_lines(member: Object) -> Array[String]:
	var lines := appraisal_stat_lines(member)
	if member == null or not member.has_method("appraisal") or appraisal_of(member).is_empty():
		# The "no appraisal" and "not appraised yet" cases are one line and nothing
		# after it: there is no trait block to put under a pal we cannot read.
		return lines
	lines.append("")
	lines.append_array(trait_lines(member))
	return lines


## The verdict and the per-stat star rows. What the pal IS.
##
## The top half of `appraisal_lines`, split out so a caller with two columns to
## fill can put this in one of them. It keeps the two "we cannot appraise this"
## answers, because a column that renders as nothing at all reads as a bug.
static func appraisal_stat_lines(member: Object) -> Array[String]:
	if member == null or not member.has_method("appraisal"):
		return ["[color=#%s]No appraisal available for this one.[/color]" % STYLE.INK_DIM]
	var appraisal := appraisal_of(member)
	if appraisal.is_empty():
		return ["[color=#%s]Not appraised yet.[/color]" % STYLE.INK_DIM]

	var lines: Array[String] = []

	# The overall verdict, from the appraisal's own rating rather than from an
	# average this formatter computes. The data layer decides what a pal is worth;
	# this only decides how to say it.
	var max_stars := maxi(1, int(appraisal.get("max_stars", STYLE.STARS)))
	var overall := int(appraisal.get("stars", 0))
	lines.append("[color=#%s]Appraisal[/color]  [b]%s[/b]   %s" % [
		STYLE.INK_DIM,
		verdict(overall, max_stars),
		STYLE.star_row(overall, max_stars),
	])

	# Per stat, compared against the species baseline at this level.
	var stats: Variant = appraisal.get("stats")
	if stats is Dictionary:
		for stat_name: String in (stats as Dictionary).keys():
			var entry: Variant = (stats as Dictionary)[stat_name]
			if not entry is Dictionary:
				continue
			var stat: Dictionary = entry
			# The star row and the pal's actual stat, never the ratio behind them.
			# `data/config/party.json` is explicit: "the UI is expected to draw the
			# stars and may draw the bars, but must not print the ratios." The value
			# is what this pal's attack IS; the ratio is the IV read-out
			# GAME_DESIGN.md §11 says not to build.
			lines.append("[color=#%s]%s[/color]  %s   [color=#%s]%d[/color]" % [
				STYLE.INK_DIM,
				label_for(stat_name),
				STYLE.star_row(int(stat.get("stars", 0)), max_stars),
				STYLE.INK_DIM,
				roundi(float(stat.get("value", 0.0))),
			])
	return lines


## The trait, what it does, and how far this pal is from its next level. What the
## pal CARRIES.
##
## `spaced` is how the one-column and two-column panels differ, and it is the only
## way they differ. A blank line is the single-column panel's paragraph break; in
## a column of its own the gap between the two columns already does that work, and
## spending a line height on it is spending the height this split was made to
## save. Defaulted to true so `appraisal_lines` reads exactly as it did.
static func trait_lines(member: Object, spaced: bool = true) -> Array[String]:
	var lines: Array[String] = []
	if member == null:
		return lines
	var appraisal := appraisal_of(member)

	# The trait, with what it actually DOES. The name on its own is a word the
	# player has to take on trust, and the description is the single line that
	# makes one pal worth keeping over another — which is the whole question M5's
	# release ceremony asks.
	var trait_dict := trait_data(member)
	var trait_name := str(trait_dict.get("display_name", ""))
	# Falls back to the pal's own answer rather than to nothing. Every pal has a
	# trait (§11: "Each pal starts with one trait"), so a blank where the name
	# should be is a data fault, and saying the id out loud is how somebody finds
	# it.
	if trait_name == "":
		trait_name = trait_of(member)
	lines.append("[color=#%s]Trait[/color]  [b]%s[/b]" % [STYLE.INK_DIM, trait_name])
	var description := str(trait_dict.get("description", ""))
	if description != "":
		lines.append("[color=#%s]%s[/color]" % [STYLE.INK_DIM, description])

	# Progress toward the next level, as a sentence rather than as stars — it is a
	# count, and a generic renderer over a structured payload will always find a
	# number it can misread.
	var xp := int(appraisal.get("xp", 0))
	var needed := int(appraisal.get("xp_for_next_level", 0))
	if needed > 0:
		if spaced:
			lines.append("")
		lines.append("[color=#%s]Next level in %d xp[/color]" % [STYLE.INK_DIM, maxi(needed - xp, 0)])
	return lines


# ------------------------------------------------------------- two columns

## `detail_lines`, cut down the middle: what the pal IS, and what it CARRIES.
##
## THE SAME WORDS AS `detail_lines`, in the same order, with the blank lines that
## separated the paragraphs removed — the gap between two columns already says
## what a blank line says, and on the release ceremony's panel a blank line is a
## line of the trait description that the player never gets to read.
##
## This exists because of a measured clip, not a preference. The release screen
## puts six cards above its appraisal panel and the panel that is left over is
## about six lines tall; the worst-case pal needs thirteen. Attack, Defence, the
## trait, its description and the xp line were all below the fold — computed,
## logged, and never shown. Halving the line count is what fits them, and it uses
## width the panel already had and was wasting.
##
## Two functions rather than one returning a pair, so a caller that only has room
## for one of the halves can ask for that half.
static func vitals_column(member: Object) -> Array[String]:
	var lines: Array[String] = []
	if member == null:
		return lines
	# The SPECIES name, and only when a nickname is hiding it — `detail_lines`'
	# rule, for `detail_lines`' reason: under a pal with no nickname it would just
	# repeat the heading.
	var species_name := species_of(member)
	if species_name != "" and species_name != display_of(member):
		lines.append("[color=#%s]%s[/color]" % [STYLE.INK_DIM, species_name])
	lines.append(vitals_line(member))
	lines.append_array(appraisal_stat_lines(member))
	return lines


static func trait_column(member: Object) -> Array[String]:
	return trait_lines(member, false)


## The trait sub-dictionary of an appraisal: id, display_name, description,
## modifiers. Empty for a pal with no appraisal.
static func trait_data(member: Object) -> Dictionary:
	var entry: Variant = appraisal_of(member).get("trait")
	return entry if entry is Dictionary else {}


## A word for a star count.
##
## Mapped from the COUNT, not from a fraction of it. Dividing by `max_stars` and
## banding the result put "Poor" and "Excellent" out of reach entirely and made a
## four-star pal read identically to a perfect one — which is exactly backwards
## for a screen whose job is to help somebody decide which pal to release.
##
## Five words over however many stars the data uses, so a `party.json` that moves
## `max_stars` moves the words with it rather than pinning "Exceptional" to a five
## that no longer exists.
static func verdict(stars: int, total: int) -> String:
	var last := VERDICTS.size() - 1
	if total <= 1:
		return str(VERDICTS[last])
	var position := float(clampi(stars, 1, total) - 1) / float(total - 1)
	return str(VERDICTS[clampi(int(position * float(last) + 0.5), 0, last)])


static func label_for(key: String) -> String:
	return str(KEY_NAMES.get(key, humanise(key)))


static func humanise(id: String) -> String:
	return id.replace("_", " ").capitalize()
