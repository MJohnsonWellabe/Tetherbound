extends "res://tests/test_case.gd"

## `scripts/ui/party_strip.gd` and `scripts/ui/stamina_arc.gd` — two standalone
## HUD widgets, checked as data and state machines rather than as pixels
## (`docs/decisions/D02` scopes this harness to pure logic; a reveal tween's
## motion or an arc's actual rasterised curve is something the owner has to
## look at, not something this file can honestly claim to verify).
##
## PLAIN `Control.new()` GETS NO `_ready()`, THE SAME GAP `test_ui_tokens.gd`
## ALREADY WORKS AROUND (its own header: "No scene tree needed... without
## instancing a whole HUD scene"). `party_strip.gd` builds its five rows
## inside `_build()`, called by `_ready()` — but also callable directly,
## on purpose, exactly so a tree-less test can construct the real subtree and
## then drive `update_from_party()` against it. `stamina_arc.gd` needs no such
## workaround: its entire visibility state machine lives in `update_stamina()`
## and reads/writes plain Control properties (`visible`, `modulate.a`), none of
## which require a tree either.
##
## What is deliberately NOT claimed here: that the reveal/fade actually looks
## right, or that the arc draws where the spec says it should. Those need eyes
## on the Ally, same as everything else `CLAUDE.md`'s "Prototyping" section
## reserves for representative art and a real screen.

const PARTY_STRIP := preload("res://scripts/ui/party_strip.gd")
const STAMINA_ARC := preload("res://scripts/ui/stamina_arc.gd")
const UI_TOKENS := preload("res://scripts/ui/ui_tokens.gd")


# --- party_strip.gd -----------------------------------------------------------


func _make_strip() -> Control:
	var strip: Control = PARTY_STRIP.new()
	strip._build()
	return strip


func test_build_makes_five_fixed_rows() -> void:
	var strip := _make_strip()
	assert_eq(strip.get_child_count(), 1, "expected one list container directly under the widget")
	var list: Node = strip.get_child(0)
	assert_eq(list.get_child_count(), PARTY_STRIP.SLOTS, "the row list does not hold five children")
	assert_eq(strip._rows.size(), PARTY_STRIP.SLOTS)
	strip.free()


func test_build_is_idempotent() -> void:
	# A test (or a stray double-mount) calling `_build()` twice must not double
	# the rows — `autoload/party.gd`'s five-creature cap is meaningless if the
	# widget showing it can grow a sixth row of its own.
	var strip := _make_strip()
	strip._build()
	assert_eq(strip._rows.size(), PARTY_STRIP.SLOTS)
	strip.free()


func test_update_from_party_with_three_creatures_and_two_vacants_does_not_crash() -> void:
	var strip := _make_strip()
	var entries: Array = [
		{"label": "Terrapup", "level": 4, "hp_fraction": 0.8, "tint": Color(0.55, 0.35, 0.15), "fainted": false},
		{"label": "Bramblebun", "level": 6, "hp_fraction": 0.5, "tint": Color(0.2, 0.5, 0.2), "fainted": false},
		{"label": "Skitterling", "level": 2, "hp_fraction": 0.0, "tint": Color(0.4, 0.4, 0.45), "fainted": true},
	]
	strip.update_from_party(entries, 1)

	assert_eq(strip._rows.size(), PARTY_STRIP.SLOTS, "update_from_party must never change the row count")
	assert_eq(strip._name_labels[0].text, "Terrapup")
	assert_eq(strip._name_labels[1].text, "Bramblebun")
	assert_eq(strip._level_labels[1].text, "Lv 6")
	assert_almost_eq(strip._hp_bars[0].value, 0.8)

	# The two slots beyond the three real entries read as vacant: no name, no
	# level, an empty bar, and the dim vacant look — never leftover text from a
	# previous call.
	assert_eq(strip._name_labels[3].text, "")
	assert_eq(strip._name_labels[4].text, "")
	assert_almost_eq(strip._hp_bars[3].value, 0.0)
	assert_almost_eq(strip._rows[3].modulate.a, PARTY_STRIP.VACANT_MODULATE)
	strip.free()


func test_selected_row_gets_the_teal_rail_and_full_modulate() -> void:
	var strip := _make_strip()
	var entries: Array = [
		{"label": "Terrapup", "level": 4, "hp_fraction": 1.0, "tint": Color(0.55, 0.35, 0.15), "fainted": false},
		{"label": "Bramblebun", "level": 6, "hp_fraction": 1.0, "tint": Color(0.2, 0.5, 0.2), "fainted": false},
	]
	strip.update_from_party(entries, 1)

	assert_true(strip._rails[1].visible, "the active row's rail should be showing")
	assert_false(strip._rails[0].visible, "a non-active row's rail should be hidden")
	assert_almost_eq(strip._rows[1].modulate.a, PARTY_STRIP.SELECTED_MODULATE)
	assert_almost_eq(strip._rows[0].modulate.a, PARTY_STRIP.UNSELECTED_MODULATE)
	strip.free()


func test_fainted_entry_dims_and_tints_its_hp_bar_danger() -> void:
	var strip := _make_strip()
	var entries: Array = [
		{"label": "Terrapup", "level": 4, "hp_fraction": 0.0, "tint": Color(0.55, 0.35, 0.15), "fainted": true},
	]
	# Fainted but also the active slot -- fainted must win over the brighter
	# selected look, per the widget's header: "Fainted always reads as
	# fainted."
	strip.update_from_party(entries, 0)

	assert_almost_eq(strip._rows[0].modulate.a, PARTY_STRIP.FAINTED_MODULATE, 0.001,
		"a fainted creature should read as dimmed even while selected")
	assert_eq(strip._hp_fills[0].bg_color, UI_TOKENS.DANGER, "a fainted creature's hp bar should be danger-tinted")
	strip.free()


func test_a_healthy_entry_keeps_the_green_hp_fill() -> void:
	var strip := _make_strip()
	strip.update_from_party([
		{"label": "Terrapup", "level": 4, "hp_fraction": 1.0, "tint": Color(0.55, 0.35, 0.15), "fainted": false},
	], 0)
	assert_eq(strip._hp_fills[0].bg_color, UI_TOKENS.HP_GREEN)
	strip.free()


# --- stamina_arc.gd ------------------------------------------------------------


func test_draining_shows_the_arc_immediately() -> void:
	var arc := STAMINA_ARC.new()
	arc.update_stamina(0.5, true, 0.016)
	assert_true(arc.visible, "draining should show the gauge on the very first frame")
	arc.free()


func test_low_fraction_shows_the_arc_even_without_draining() -> void:
	var arc := STAMINA_ARC.new()
	arc.update_stamina(0.5, false, 0.016)
	assert_true(arc.visible, "stamina below 85% should show, drain or no drain")
	arc.free()


func test_full_and_idle_eventually_hides() -> void:
	var arc := STAMINA_ARC.new()
	var elapsed := 0.0
	var step := 0.05
	# FULL_HOLD_SECONDS (0.35) to start the fade, then FADE_OUT_SECONDS (0.22)
	# to finish it -- well under a couple of seconds of simulated frames.
	while elapsed < 3.0 and arc.visible:
		arc.update_stamina(1.0, false, step)
		elapsed += step
	assert_false(arc.visible, "a full, undrained gauge should fade out and hide")
	arc.free()


func test_partial_idle_holds_longer_than_full_before_hiding() -> void:
	# A resting-but-not-full gauge (90%) should still be showing after the
	# FULL case would already have hidden -- the longer IDLE_HIDE_AFTER_SECONDS
	# grace window is the whole point of the two-timer design.
	var arc := STAMINA_ARC.new()
	var step := 0.05
	var elapsed := 0.0
	while elapsed < STAMINA_ARC.FULL_HOLD_SECONDS + STAMINA_ARC.FADE_OUT_SECONDS + 0.1:
		arc.update_stamina(0.9, false, step)
		elapsed += step
	assert_true(arc.visible, "a partial reserve should still be visible where a full one would already have hidden")
	arc.free()


func test_resuming_drain_cancels_a_pending_hide() -> void:
	var arc := STAMINA_ARC.new()
	# Idle long enough to be mid-fade (but not yet hidden).
	for i in 8:
		arc.update_stamina(1.0, false, 0.05)
	assert_true(arc.visible, "should still be mid-fade, not hidden yet")
	arc.update_stamina(0.95, true, 0.016)
	assert_true(arc.visible)
	assert_almost_eq(arc.modulate.a, 1.0, 0.001, "resuming drain should snap the gauge back to fully shown")
	arc.free()


func test_arc_color_boundaries() -> void:
	var mint: Color = UI_TOKENS.TEAL_SOFT.lerp(Color.WHITE, 0.4)
	assert_eq(STAMINA_ARC.arc_color(0.05), UI_TOKENS.DANGER, "well below the danger threshold")
	# On the boundary: the better tier, not the worse one (matches
	# UITokens.chance_tier_color's own convention).
	assert_eq(STAMINA_ARC.arc_color(0.10), UI_TOKENS.WARNING)
	assert_eq(STAMINA_ARC.arc_color(0.29), UI_TOKENS.WARNING)
	assert_eq(STAMINA_ARC.arc_color(0.30), mint)
	assert_eq(STAMINA_ARC.arc_color(0.65), mint)
	assert_eq(STAMINA_ARC.arc_color(1.0), mint)
