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
const PLAYGROUND_HUD := preload("res://scripts/ui/playground_hud.gd")
const STAMINA_ARC := preload("res://scripts/ui/stamina_arc.gd")
const UI_TOKENS := preload("res://scripts/ui/ui_tokens.gd")
const CREATURE_SPECIES := preload("res://scripts/creatures/creature_species.gd")
const TERRAPUP_PORTRAIT := "res://assets/ui/portraits/creatures/terrapup.png"
const BRAMBLEBUN_PORTRAIT := "res://assets/ui/portraits/creatures/bramblebun.png"


# --- party_strip.gd -----------------------------------------------------------


func _make_strip() -> Control:
	var strip: Control = PARTY_STRIP.new()
	strip._build()
	return strip


func test_build_makes_five_fixed_rows() -> void:
	var strip := _make_strip()
	assert_eq(strip.get_child_count(), 2,
		"expected the roster stack plus OP21-12's cycle banner directly under the widget")
	assert_eq(strip._list.get_child_count(), PARTY_STRIP.SLOTS, "the row list does not hold five children")
	assert_eq(strip._rows.size(), PARTY_STRIP.SLOTS)
	assert_eq(strip._count_label.text, "TEAM  0 / 5")
	strip.free()


func test_build_is_idempotent() -> void:
	# A test (or a stray double-mount) calling `_build()` twice must not double
	# the rows — `autoload/party.gd`'s five-creature cap is meaningless if the
	# widget showing it can grow a sixth row of its own.
	var strip := _make_strip()
	strip._build()
	assert_eq(strip._rows.size(), PARTY_STRIP.SLOTS)
	strip.free()


func test_full_roster_mount_clears_the_separate_active_panel() -> void:
	var strip := _make_strip()
	for row: Control in strip._rows:
		assert_almost_eq(
			row.custom_minimum_size.y,
			PARTY_STRIP.ROW_SIZE.y,
			0.001,
			"occupied and vacant rows must reserve the same fixed vertical space"
		)
	# HUD-LAYOUT: the left column (party strip / creature panel / vitals) is
	# stacked bottom-up from the CANVAS BOTTOM (see
	# `playground_hud.gd::BOTTOM_DOCK_TOP_OFFSET`'s header for why a fixed
	# top-anchored offset was the actual defect), so its position math takes
	# an explicit canvas height rather than reading fixed constants.
	#
	# HUD-POPUP: this function used to say the roster and the active panel
	# were allowed to touch -- the strip's own `TOTAL_HEIGHT` (540, five
	# text-driven rows) genuinely did not fit in the room the old design left
	# above a correctly bottom-anchored creature panel, and the clamp that
	# handled the shortfall let the reveal draw its bottom rows straight over
	# the panel behind it. A blind critic then measured exactly that frame:
	# the panel's title compositing through a party row's name, an HP readout
	# floating over the wrong row, six distinct collisions from one shared
	# rect. The party strip no longer shares a rect with the creature panel
	# at all -- `PARTY_STRIP_X` moved it to its own screen region --
	# `test_party_strip_no_longer_overlaps_the_creature_panel` below is what
	# proves that on real geometry, and
	# `test_left_stack_clears_bottom_dock_at_every_supported_aspect` still
	# carries the vitals/creature-panel column's own guarantee.
	strip.free()


## HUD-LAYOUT's own regression: the OLD `CREATURE_BLOCK_POS`/`VITALS_POS`
## were fixed, top-anchored pixel offsets tuned against an assumed
## 1080-tall canvas. This project stretches `canvas_items` with
## `aspect="expand"`, and the Ally's real 1280x800 window computes an
## EFFECTIVE canvas of 1920x1200 (wider aspect ratio than 16:9 needs more
## vertical canvas to fill) -- 120px taller than the authoring assumption.
## `Root/BottomDock` already derives its own position from the canvas
## BOTTOM (`offset_top = -460`, anchored `anchor_top/bottom = 1`), so it
## slides down correctly on the taller canvas; the left column did not, and
## a real render of the full HUD scene at 1280x800 measured the creature
## panel and vitals cluster overlapping BottomDock's actual rect. This test
## proves the fixed math instead: the left column's lowest element must
## clear `BOTTOM_DOCK_TOP_OFFSET`'s own nominal top by at least
## `LEFT_STACK_CLEARANCE`, at both the project's 16:9 authoring aspect
## (1080) and the Ally's real effective canvas (1200).
func test_left_stack_clears_bottom_dock_at_every_supported_aspect() -> void:
	var creature_h := 150.0
	for canvas_h in [1080.0, 1200.0]:
		var vitals_pos: Vector2 = PLAYGROUND_HUD.vitals_position(canvas_h)
		var vitals_bottom := vitals_pos.y + PLAYGROUND_HUD.VITALS_HEIGHT
		var dock_top: float = canvas_h + float(PLAYGROUND_HUD.BOTTOM_DOCK_TOP_OFFSET)
		assert_true(
			dock_top - vitals_bottom >= PLAYGROUND_HUD.LEFT_STACK_CLEARANCE - 0.001,
			"left stack must clear BottomDock's nominal top at canvas height %.0f (vitals bottom %.1f, dock top %.1f)" % [
				canvas_h, vitals_bottom, dock_top,
			]
		)

		var creature_pos: Vector2 = PLAYGROUND_HUD.creature_block_position(canvas_h, creature_h)
		assert_almost_eq(
			vitals_pos.y - (creature_pos.y + creature_h),
			PLAYGROUND_HUD.PARTY_ACTIVE_GAP,
			0.001,
			"vitals cluster must sit a fixed gap below the creature panel at canvas height %.0f" % canvas_h
		)


## `party_strip_position()` never draws the reveal above `TOP_SAFE_INSET`,
## regardless of canvas height -- the strip's own screen region (see its own
## header) means this is normally a plain top anchor, not an engaged clamp,
## but the function still has a defensive floor for a canvas short enough
## that `TOP_SAFE_INSET + TOTAL_HEIGHT` would overrun `Root/BottomDock`'s
## nominal top. This test proves the bound holds at both supported canvas
## heights.
func test_party_strip_never_goes_off_the_top_of_the_screen() -> void:
	for canvas_h in [1080.0, 1200.0]:
		var strip_pos: Vector2 = PLAYGROUND_HUD.party_strip_position(
			canvas_h, PARTY_STRIP.TOTAL_HEIGHT, PLAYGROUND_HUD.CREATURE_BLOCK_MIN_WIDTH
		)
		assert_true(
			strip_pos.y >= 0.0 - 0.001,
			"party strip top (%.1f) must never draw above the screen at canvas height %.0f" % [
				strip_pos.y, canvas_h,
			]
		)
		assert_almost_eq(
			strip_pos.y, PLAYGROUND_HUD.TOP_SAFE_INSET, 0.001,
			"party strip should rest at TOP_SAFE_INSET, not an engaged clamp, at canvas height %.0f -- " % canvas_h +
			"if this fails, TOTAL_HEIGHT or BOTTOM_DOCK_TOP_OFFSET moved enough to eat the defensive floor's margin"
		)


## HUD-POPUP: the top defect a blind critic found -- the creature panel's
## own title/HP/type readout compositing directly on top of party rows 3 and
## 4 ("R**Kite**ADY TO CALL OUT" was one specific byproduct of the two
## widgets sharing a rect). Checked on real `Rect2` geometry, not just a Y
## comparison, so a future width change to either widget cannot silently
## reopen this without tripping the test.
##
## `creature_w` is deliberately NOT `CREATURE_BLOCK_MIN_WIDTH` here -- the
## first version of this fix used exactly that constant as a fixed guess at
## the panel's real width, and a live render with a seeded creature (an HP
## value column, a type tag, a portrait) immediately measured the panel at
## 435, well past its 374px floor, reopening the same collision this test
## exists to catch. 435 is that measured value, not a round number, so this
## test would have failed against BOTH the pre-fix design (same x as the
## panel) and the first, width-naive version of the actual fix.
func test_party_strip_no_longer_overlaps_the_creature_panel() -> void:
	var creature_h := 230.0
	var creature_w := 435.0
	for canvas_h in [1080.0, 1200.0]:
		var strip_pos: Vector2 = PLAYGROUND_HUD.party_strip_position(canvas_h, PARTY_STRIP.TOTAL_HEIGHT, creature_w)
		var strip_rect := Rect2(strip_pos, Vector2(PARTY_STRIP.ROW_SIZE.x, PARTY_STRIP.TOTAL_HEIGHT))
		var creature_pos: Vector2 = PLAYGROUND_HUD.creature_block_position(canvas_h, creature_h)
		var creature_rect := Rect2(creature_pos, Vector2(creature_w, creature_h))
		assert_false(
			strip_rect.intersects(creature_rect),
			"party strip %s must never intersect the creature panel %s at canvas height %.0f" % [
				strip_rect, creature_rect, canvas_h,
			]
		)


## HUD-POPUP task 4: "Bramblebun's row (party row 5) is clipped at the panel
## bottom by the player's own HP and satiety bars" -- the vitals cluster used
## to share the SAME x column as the party strip's old (clamped, overlapping)
## rest position, so the strip's fifth row could land under the vitals rect
## with no panel backing of its own. Now that the strip lives in its own
## screen region, the two literally cannot share a column; this proves it on
## geometry rather than trusting the new x offset by eye.
func test_party_strip_never_overlaps_player_vitals() -> void:
	for canvas_h in [1080.0, 1200.0]:
		var strip_pos: Vector2 = PLAYGROUND_HUD.party_strip_position(
			canvas_h, PARTY_STRIP.TOTAL_HEIGHT, PLAYGROUND_HUD.CREATURE_BLOCK_MIN_WIDTH
		)
		var strip_rect := Rect2(strip_pos, Vector2(PARTY_STRIP.ROW_SIZE.x, PARTY_STRIP.TOTAL_HEIGHT))
		var vitals_pos: Vector2 = PLAYGROUND_HUD.vitals_position(canvas_h)
		var vitals_rect := Rect2(vitals_pos, Vector2(PLAYGROUND_HUD.VITALS_WIDTH, PLAYGROUND_HUD.VITALS_HEIGHT))
		assert_false(
			strip_rect.intersects(vitals_rect),
			"party strip %s must never intersect the player vitals cluster %s at canvas height %.0f" % [
				strip_rect, vitals_rect, canvas_h,
			]
		)


func test_update_from_party_with_three_creatures_and_two_vacants_does_not_crash() -> void:
	var strip := _make_strip()
	var entries: Array = [
		{"label": "Terrapup", "level": 4, "hp_fraction": 0.8,
			"tint": Color(0.55, 0.35, 0.15), "portrait": TERRAPUP_PORTRAIT,
			"fainted": false},
		{"label": "Bramblebun", "level": 6, "hp_fraction": 0.5,
			"tint": Color(0.2, 0.5, 0.2), "portrait": BRAMBLEBUN_PORTRAIT,
			"fainted": false},
		{"label": "Skitterling", "level": 2, "hp_fraction": 0.0, "tint": Color(0.4, 0.4, 0.45), "fainted": true},
	]
	strip.update_from_party(entries, 1)

	assert_eq(strip._rows.size(), PARTY_STRIP.SLOTS, "update_from_party must never change the row count")
	assert_eq(strip._count_label.text, "TEAM  3 / 5", "the roster capacity must be explicit at a glance")
	assert_eq(strip._name_labels[0].text, "Terrapup")
	assert_eq(strip._name_labels[1].text, "Bramblebun")
	assert_eq(strip._level_labels[1].text, "Lv 6")
	assert_almost_eq(strip._hp_bars[0].value, 0.8)
	assert_true(strip._portraits[0].visible, "an occupied slot should show its creature render")
	assert_ne(strip._portraits[0].texture, strip._portraits[1].texture,
		"different species should not collapse to the same abstract swatch")

	# The two slots beyond the three real entries read as deliberately open:
	# fixed labels and numbered chips, no stale level/portrait/HP from a prior
	# occupant.
	assert_eq(strip._name_labels[3].text, "OPEN SLOT")
	assert_eq(strip._name_labels[4].text, "OPEN SLOT")
	assert_true(strip._slot_labels[3].visible, "a vacant row must remain visibly numbered")
	assert_true(strip._slot_labels[4].visible, "all five slots must remain visible")
	assert_almost_eq(strip._hp_bars[3].value, 0.0)
	assert_almost_eq(strip._rows[3].modulate.a, PARTY_STRIP.VACANT_MODULATE)
	assert_false(strip._portraits[3].visible, "a vacant slot must not retain a previous portrait")
	strip.free()


func test_occupied_rows_hide_slot_numbers_and_vacant_rows_remain_legible() -> void:
	var strip := _make_strip()
	strip.update_from_party([{
		"label": "Terrapup", "level": 4, "hp_fraction": 1.0,
		"tint": Color(0.55, 0.35, 0.15), "portrait": TERRAPUP_PORTRAIT,
		"fainted": false,
	}], 0)
	assert_false(strip._slot_labels[0].visible, "a portrait replaces the occupied slot number")
	assert_true(strip._slot_labels[1].visible)
	assert_true(strip._rows[1].modulate.a >= 0.6, "open slots must not disappear into the world")
	strip.free()


func test_every_installed_species_has_the_hud_portrait_it_resolves() -> void:
	var hud: CanvasLayer = PLAYGROUND_HUD.new()
	for species_id: String in CREATURE_SPECIES.table().keys():
		var path := str(hud.call("_species_portrait_path", species_id))
		assert_true(ResourceLoader.exists(path), "%s portrait missing: %s" % [species_id, path])
	hud.free()


func test_resting_entry_has_an_explicit_unavailable_marker() -> void:
	var strip := _make_strip()
	strip.update_from_party([{
		"label": "Terrapup", "level": 4, "hp_fraction": 0.8,
		"tint": Color(0.55, 0.35, 0.15), "portrait": TERRAPUP_PORTRAIT,
		"fainted": false, "resting": true,
	}], 0)
	assert_true(strip._rest_labels[0].visible, "resting must be readable without inferring it from dimming")
	# HUD-EMPHASIS: `KO`'s visibility now lives on its badge, not the bare
	# label inside it -- see `_build_row()`'s own comment on why the badge
	# carries a `self_modulate` compensation the label alone cannot.
	assert_false(strip._ko_badges[0].visible)
	assert_true(strip._rows[0].modulate.a < PARTY_STRIP.SELECTED_MODULATE)
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
	assert_eq(strip._chip_boxes[1].border_color, UI_TOKENS.TEAL_SOFT,
		"the active creature portrait should carry the same selected highlight")
	assert_almost_eq(strip._rows[1].modulate.a, PARTY_STRIP.SELECTED_MODULATE)
	assert_almost_eq(strip._rows[0].modulate.a, PARTY_STRIP.UNSELECTED_MODULATE)
	# `update_from_party()`'s default `active_out=true`: the rail reads
	# full-brightness TEAL, same as before this task touched it.
	assert_eq(strip._rails[1].color, UI_TOKENS.TEAL,
		"a selected AND summoned row's rail should read the bright TEAL")
	strip.free()


## HUD-POPUP task 2: "the list's teal 'active' highlight moves to the new
## creature at the same moment the popup says that creature is only 'ready to
## be called out.' Selected-but-not-summoned and active-in-the-world
## currently share one visual treatment." This proves the two states now
## carry two different rail colours, with the chip border (the plain
## "selected" signal `test_selected_row_gets_the_teal_rail_and_full_modulate`
## above already covers) deliberately left untouched by the distinction.
func test_selected_but_not_out_row_gets_the_dimmer_rail() -> void:
	var strip := _make_strip()
	var entries: Array = [
		{"label": "Terrapup", "level": 4, "hp_fraction": 1.0, "tint": Color(0.55, 0.35, 0.15), "fainted": false},
	]
	strip.update_from_party(entries, 0, false)

	assert_true(strip._rails[0].visible, "the selected row's rail should still show")
	assert_eq(strip._rails[0].color, UI_TOKENS.TEAL_SOFT,
		"a selected-but-not-summoned row's rail should read the dimmer TEAL_SOFT, not full TEAL")
	assert_eq(strip._chip_boxes[0].border_color, UI_TOKENS.TEAL_SOFT,
		"the chip border stays the plain 'selected' signal regardless of out-state")
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


# --- OP21-12: cycle-clarity banner ----------------------------------------------


func test_flash_cycle_shows_previous_and_next_and_roster_position() -> void:
	var strip := _make_strip()
	strip.flash_cycle(1, "Terrapup", "Bramblebun", 2, 5)
	assert_true(strip._cycle_banner.visible, "a real cycle must show the transition banner")
	assert_true(strip._cycle_banner.text.contains("Terrapup"),
		"the creature the player was on must be named")
	assert_true(strip._cycle_banner.text.contains("Bramblebun"),
		"the creature the player is moving to must be named")
	assert_true(strip._cycle_banner.text.contains("2 / 5"),
		"roster position must be stated, not left for the player to infer")
	assert_true(strip._cycle_banner.text.contains("▶"),
		"forward cycling must show a forward-facing arrow")
	strip.free()


## HUD-EMPHASIS: the whole point of this task. A blind critic measured the
## destination name -- "the single word the player cycled to find out" -- as
## the smallest text on the entire screen, smaller than the creature being
## left behind and the roster-position readout beside it. Encodes the
## invariant directly against the constants `flash_cycle()` actually tags
## each run with, not just a "text contains the name" check that would pass
## even with the sizes inverted.
func test_flash_cycle_destination_name_is_the_dominant_element() -> void:
	assert_true(
		PARTY_STRIP.CYCLE_DEST_FONT_SIZE > PARTY_STRIP.CYCLE_SOURCE_FONT_SIZE,
		"the destination (where the player is going) must be authored larger than the source (where they left)"
	)
	assert_true(
		PARTY_STRIP.CYCLE_DEST_FONT_SIZE > PARTY_STRIP.CYCLE_POSITION_FONT_SIZE,
		"the destination name must be the single most dominant element in the banner"
	)

	var strip := _make_strip()
	strip.flash_cycle(1, "Terrapup", "Bramblebun", 2, 5)
	var text: String = strip._cycle_banner.text
	var dest_tag := "[font_size=%d]" % PARTY_STRIP.CYCLE_DEST_FONT_SIZE
	var source_tag := "[font_size=%d]" % PARTY_STRIP.CYCLE_SOURCE_FONT_SIZE
	var dest_tag_pos := text.find(dest_tag)
	var source_tag_pos := text.find(source_tag)
	var dest_name_pos := text.find("Bramblebun")
	var source_name_pos := text.find("Terrapup")
	assert_true(dest_tag_pos != -1 and source_tag_pos != -1,
		"the banner text must carry both the destination and source font-size tags")
	assert_true(dest_tag_pos < dest_name_pos and dest_name_pos < dest_tag_pos + dest_tag.length() + 60,
		"the destination name must actually be wrapped in its own dominant font-size tag, not just present somewhere in the string")
	assert_true(source_tag_pos < source_name_pos and source_name_pos < source_tag_pos + source_tag.length() + 60,
		"the source name must actually be wrapped in its own small font-size tag")

	# HUD-EMPHASIS root-cause regression guard: `[b]` alone silently falls
	# back to the theme's untouched `bold_font_size` default, which is what
	# made the destination name render smaller than everything else despite
	# `flash_cycle()` already wrapping it in `[b]` before this task. This
	# must stay explicitly overridden so that root cause cannot come back
	# quietly if a future edit ever drops the `[font_size=]` tags and leans
	# on `[b]` alone again.
	assert_eq(strip._cycle_banner.get_theme_font_size("bold_font_size"), PARTY_STRIP.CYCLE_DEST_FONT_SIZE,
		"bold_font_size must be explicitly overridden -- relying on [b] alone silently under-sizes the destination name")
	strip.free()


func test_flash_cycle_backward_shows_the_backward_arrow() -> void:
	var strip := _make_strip()
	strip.flash_cycle(-1, "Bramblebun", "Terrapup", 1, 5)
	assert_true(strip._cycle_banner.text.contains("◀"),
		"backward cycling must show a backward-facing arrow, not the forward one")
	strip.free()


func test_flash_cycle_with_zero_direction_is_a_no_op() -> void:
	# A same-frame roster edit that happens to also move the active index
	# (a catch, a menu reorder) is not a cycle -- the caller passes direction
	# 0 for it, and this must not claim a transition that didn't happen.
	var strip := _make_strip()
	strip.flash_cycle(0, "Terrapup", "Bramblebun", 2, 5)
	assert_false(strip._cycle_banner.visible)
	strip.free()


func test_cycle_banner_hides_itself_after_its_hold_expires() -> void:
	var strip := _make_strip()
	strip.flash_cycle(1, "Terrapup", "Bramblebun", 2, 5)
	assert_true(strip._cycle_banner.visible)
	# HUD-LAYOUT: a single oversized `delta` no longer collapses the whole
	# hold in one `_process()` call -- `MAX_TIMER_DELTA` caps what any one
	# frame can subtract (see that constant's own header for the real bug
	# this fixes: a slow real frame during a cold scene boot exhausting the
	# hold before the reveal was ever drawn). Enough calls at the cap to
	# cover the hold, same as a real slow-but-nonzero framerate would.
	var frames := int(ceil(PARTY_STRIP.CYCLE_BANNER_SECONDS / PARTY_STRIP.MAX_TIMER_DELTA)) + 1
	for i in frames:
		strip._process(PARTY_STRIP.MAX_TIMER_DELTA)
	assert_false(strip._cycle_banner.visible, "the banner must not linger past its own hold")
	strip.free()


## HUD-LAYOUT's own regression: one abnormally slow frame (a hitch, or the
## first frame after a heavy scene load -- exactly what a cold Meadows boot
## produces) must not, by itself, exhaust the whole cycle-banner hold before
## anyone has a chance to see it. This is the literal bug a real full-world
## capture caught: `visible=false` on both the banner and the strip at the
## moment of the shot, despite `flash_cycle()` having just run.
func test_one_oversized_frame_does_not_hide_the_cycle_banner() -> void:
	var strip := _make_strip()
	strip.flash_cycle(1, "Terrapup", "Bramblebun", 2, 5)
	strip._process(PARTY_STRIP.CYCLE_BANNER_SECONDS + 1.0)
	assert_true(
		strip._cycle_banner.visible,
		"a single oversized frame delta must not by itself exhaust the cycle banner's hold"
	)
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
