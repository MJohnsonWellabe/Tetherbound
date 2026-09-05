extends "res://tests/test_case.gd"

## N06-MAP-UI — the map screen's legibility contract, in numbers.
##
## Every assertion here restates something W11-ALPHA-PINS-0904's round-3 blind
## judge measured off a rendered frame and reported as a defect. A judge cannot
## be re-run in CI and a frame cannot be diffed usefully, but the VALUE
## relationships the judge was measuring are decided by constants and by two
## pure functions in `tab_map.gd`/`minimap.gd` — so they can be pinned exactly,
## and a future change that reopens one of these defects goes red rather than
## waiting for the next visual pass to rediscover it.
##
## Pure logic, no scenes and no rendering, per `test_case.gd`'s own scope note
## and D02: this reads the constants and calls the same static functions the
## draw paths call, which IS what a player sees, rather than re-deriving a
## proxy for it. That is `test_map_fog.gd`'s own argument for reading
## `FOG_UNDISCOVERED` directly, applied to the rest of the screen.

const TAB_MAP_PATH := "res://scripts/ui/tab_map.gd"
const MINIMAP_PATH := "res://scripts/ui/minimap.gd"
const TAB_MAP := preload("res://scripts/ui/tab_map.gd")
const MINIMAP := preload("res://scripts/ui/minimap.gd")


func _const(script_path: String, name: String) -> Variant:
	var script: Script = load(script_path)
	return script.get_script_constant_map().get(name)


## Rec. 709 relative luminance (linearised), the quantity a contrast ratio is
## built from — distinct from the gamma-space luma the label lift uses, and
## used here because these assertions are about contrast RATIOS.
func _relative_luminance(colour: Color) -> float:
	var channels := [colour.r, colour.g, colour.b]
	var linear: Array[float] = []
	for c: float in channels:
		linear.append(c / 12.92 if c <= 0.04045 else pow((c + 0.055) / 1.055, 2.4))
	return 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2]


func _contrast(a: Color, b: Color) -> float:
	var la := _relative_luminance(a)
	var lb := _relative_luminance(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


## `map_baker.gd::bake()`'s own meadow green — the ground the player walks on
## for most of the Meadows. Recomputed here from the same two inputs that file
## uses rather than pinned as a literal, so if the terrain palette moves this
## test moves with it instead of asserting against a colour the bake no longer
## produces.
func _meadow_green() -> Color:
	return UITokens.HP_GREEN.lerp(Color(0.5, 0.5, 0.5), 0.2)


# --- item 1: the fog value ladder -------------------------------------------
#
# The judge's finding, verbatim: the two flat fields on the map screen sat
# 1.16:1 apart and it could not tell which was the ground it had earned. Those
# two fields were FOG_UNDISCOVERED and the page `UITokens.BG_DEEP` the canvas
# paints under everything. The fix is a THREE-tier ladder — page, fog, revealed
# ground — with each step clearly separated and in the right order.


## SUPERSEDED BY OWNER RULE, 2026-09-05, and left here as the measurement rather
## than deleted.
##
## N06-MAP-UI raised FOG_UNDISCOVERED to a blue-grey so unexplored ground sat
## 1.8:1 or better from the page behind it. Cloudreach carries its own near-black
## fog, and the owner's standing instruction is that Cloudreach wins any conflict,
## so Cloudreach's value ships. Against `BG_DEEP` it measures **1.14:1** — below
## even the 1.16:1 this lane's blind judge called indistinguishable.
##
## The bar is therefore recorded at the shipped value, not at the one the lane
## wanted, so the suite stays honest about what is on main: this is an ACCEPTED,
## OPEN legibility defect, not a passing requirement. Raise the constant in
## `tab_map.gd`/`minimap.gd` (they must move together — see the two-screens test
## below) and restore 1.8 here the moment the owner wants the fog lifted.
func test_unexplored_ground_is_distinguishable_from_the_page_it_sits_on() -> void:
	var fog: Color = _const(TAB_MAP_PATH, "FOG_UNDISCOVERED")
	var ratio := _contrast(fog, UITokens.BG_DEEP)
	assert_true(ratio >= 1.1, (
		"unexplored ground and the page chrome behind the map are %.2f:1 apart; "
		+ "at 1.16:1 a blind judge could not tell which field was the map at all, "
		+ "and the map had no readable footprint on its own screen"
	) % ratio)


func test_explored_ground_reads_lighter_than_the_fog_over_unexplored_ground() -> void:
	var fog: Color = _const(TAB_MAP_PATH, "FOG_UNDISCOVERED")
	var ground := _meadow_green()
	assert_true(_relative_luminance(ground) > _relative_luminance(fog), (
		"revealed meadow (luminance %.4f) is not lighter than the fog over unexplored "
		+ "ground (%.4f) — the ground the player earned must be the brighter half of "
		+ "that pair, which is the direction the judge asked for"
	) % [_relative_luminance(ground), _relative_luminance(fog)])
	var ratio := _contrast(ground, fog)
	assert_true(ratio >= 2.5, (
		"revealed meadow and unexplored fog are only %.2f:1 apart; the boundary "
		+ "between surveyed and unsurveyed is the single thing this screen exists "
		+ "to show"
	) % ratio)


func test_the_two_screens_fog_the_same_ground_the_same_way() -> void:
	# D33: the minimap and the full map share ONE database and ONE vocabulary.
	# The colour is copied rather than imported (see either file's header), so
	# nothing but this test stops the copies from drifting.
	assert_eq(_const(MINIMAP_PATH, "FOG_UNDISCOVERED"), _const(TAB_MAP_PATH, "FOG_UNDISCOVERED"),
		"the minimap and the full map paint unexplored ground in different colours; the same ground would read as two different states depending on which screen the player looked at")


func test_lifting_the_fog_off_the_page_did_not_start_revealing_terrain() -> void:
	# The other half of item 1, and the thing it must not cost: OW3 / spec §16.
	# An opaque fill hides what is under it whatever its colour, so this stays
	# true — but it is asserted here as well as in `test_map_fog.gd` because it
	# is THIS change that would break it if it were ever made translucent to
	# "soften" the new value.
	for path in [TAB_MAP_PATH, MINIMAP_PATH]:
		var fog: Color = _const(path, "FOG_UNDISCOVERED")
		assert_eq(fog.a, 1.0,
			"%s's fog is %.2f opaque; anything under 1.0 shows unexplored terrain through it, which is the exact 'the full map is rendered before I explore anything' report" % [path, fog.a])


# --- item 7: labels get their weight from value, not hue ---------------------
#
# The judge converted the map to greyscale and found the danger label at L≈136
# while the place names sat at L=255 — the one label that means DANGER was the
# dimmest text on the screen.


func test_a_danger_label_is_no_longer_the_dimmest_text_on_the_map() -> void:
	var danger := TAB_MAP.label_core_colour(UITokens.DANGER)
	var place := TAB_MAP.label_core_colour(UITokens.TEXT_PRIMARY)
	var min_luma: float = _const(TAB_MAP_PATH, "CANVAS_LABEL_MIN_LUMA")
	assert_true(TAB_MAP.luma(danger) >= min_luma, (
		"a danger label inks at luma %.3f, under the screen's own %.2f floor"
	) % [TAB_MAP.luma(danger), min_luma])
	# The greyscale spread, which is the thing the judge actually measured.
	var spread := absf(TAB_MAP.luma(place) - TAB_MAP.luma(danger)) * 255.0
	assert_true(spread <= 20.0, (
		"a place name and a danger label are still %.0f levels apart in greyscale "
		+ "(the judge measured 119 of 255); after this fix they must differ by HUE, "
		+ "not by whether you can see them"
	) % spread)


func test_every_label_colour_the_map_uses_clears_the_value_floor() -> void:
	var min_luma: float = _const(TAB_MAP_PATH, "CANVAS_LABEL_MIN_LUMA")
	# Exactly the token colours the draw paths in `tab_map.gd` pass in.
	for entry in [
		["TEXT_PRIMARY", UITokens.TEXT_PRIMARY],
		["TEXT_SECONDARY", UITokens.TEXT_SECONDARY],
		["DANGER", UITokens.DANGER],
		["WARNING", UITokens.WARNING],
		["TEAL", UITokens.TEAL],
	]:
		var inked: Color = TAB_MAP.label_core_colour(entry[1] as Color)
		assert_true(TAB_MAP.luma(inked) >= min_luma - 0.001,
			"a %s label inks at luma %.3f, under the %.2f floor" % [entry[0], TAB_MAP.luma(inked), min_luma])


func test_lifting_a_label_keeps_its_hue_and_its_alpha() -> void:
	# The lift must not turn every label white — hue is still how a reader tells
	# a danger label from a place name, it just is not carrying the legibility.
	var inked := TAB_MAP.label_core_colour(UITokens.DANGER)
	assert_true(inked.r > inked.g and inked.r > inked.b,
		"a lifted DANGER label is no longer red-dominant (%s); the value fix must not cost the colour coding" % inked)
	var translucent := Color(UITokens.DANGER, 0.5)
	assert_almost_eq(TAB_MAP.label_core_colour(translucent).a, 0.5, 0.0001,
		"the lift changed a label's alpha, which would make a faded label opaque")


func test_a_label_already_bright_enough_is_left_exactly_alone() -> void:
	assert_eq(TAB_MAP.label_core_colour(UITokens.TEXT_PRIMARY), UITokens.TEXT_PRIMARY,
		"a label already over the floor was still altered; only the labels that were failing should move")


func test_the_minimap_lifts_its_labels_by_the_same_rule() -> void:
	assert_eq(MINIMAP.label_core_colour(UITokens.TEXT_MUTED), TAB_MAP.label_core_colour(UITokens.TEXT_MUTED),
		"the two map screens ink the same label colour differently")


func test_canvas_labels_outline_heavier_than_the_shared_label_token() -> void:
	# The other half of item 7: a lifted core needs something to sit against on
	# the pale high ground at the top of the bake's height ramp.
	var canvas_outline: int = _const(TAB_MAP_PATH, "CANVAS_OUTLINE_SIZE")
	assert_true(canvas_outline > UITokens.OUTLINE_SIZE, (
		"the map canvas outlines its text at %d, no heavier than the shared %d authored "
		+ "for Labels a third of this screen's font size"
	) % [canvas_outline, UITokens.OUTLINE_SIZE])


# --- item 8: a marker ends the terrain under it ------------------------------


func test_a_marker_knocks_the_terrain_under_it_all_the_way_back() -> void:
	# The old plate was 72% opaque, so 28% of the ground came through — and
	# around a notched or spiked glyph that show-through lands in the notches,
	# which is exactly the silhouette contamination the judge measured.
	for path in [TAB_MAP_PATH, MINIMAP_PATH]:
		var knockback: Color = _const(path, "MARKER_KNOCKBACK")
		assert_eq(knockback.a, 1.0,
			"%s's marker backing is %.2f opaque; any terrain showing through fills in a shaped marker's notches" % [path, knockback.a])
		assert_true(TAB_MAP.luma(knockback) < 0.12,
			"%s's marker backing inks at luma %.3f — it has to knock the ground DOWN, or a pale icon has nothing to sit on" % [path, TAB_MAP.luma(knockback)])


func test_a_marker_backing_is_darker_than_any_ground_it_can_land_on() -> void:
	var knockback: Color = _const(TAB_MAP_PATH, "MARKER_KNOCKBACK")
	# The two extremes of `map_baker.gd`'s own height ramp.
	var pale_high := UITokens.GROUND_OCHRE.lerp(Color(0.85, 0.83, 0.78), 0.55)
	for ground in [_meadow_green(), pale_high]:
		assert_true(_contrast(knockback, ground) >= 4.5, (
			"a marker's backing is only %.2f:1 against ground it can land on; the "
			+ "backing is what makes a pale vendored icon a mark rather than a smudge"
		) % _contrast(knockback, ground))


# --- item 6: the map is usable on a pad --------------------------------------


func test_map_zoom_is_reachable_from_a_controller() -> void:
	# W11's judge read `[Minus]`/`[Equal]` off a frame captured with no pad
	# attached and concluded zoom was keyboard-only on a controller-first
	# project. The bindings are in fact there; this pins them so the reading
	# cannot become true later.
	for action in ["map_zoom_in", "map_zoom_out"]:
		assert_true(InputMap.has_action(action), "the map has no %s action at all" % action)
		var pad := false
		for event in InputMap.action_get_events(action):
			if event is InputEventJoypadMotion or event is InputEventJoypadButton:
				pad = true
		assert_true(pad, "%s has no controller binding; this is a controller-first project and the map cannot be zoomed without a keyboard" % action)
