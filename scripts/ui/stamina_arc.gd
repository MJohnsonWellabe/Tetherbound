extends Control

## The contextual stamina gauge (`ENVIRONMENT_AND_UI_BIBLE.md` §6.6.2):
## Palworld-style world-adjacent readout, drawn as a slender curve beside the
## player rather than a bar bolted to the corner of the screen.
##
## This widget only knows how to draw an arc at wherever it has been placed
## (the HUD positions it ~48px right of screen centre, next to the player
## silhouette — a later integration pass); it has no opinion about layout.
## Like `party_strip.gd`, it never reaches `/root/Game` — `update_stamina()`
## is fed a fraction and a draining flag by the caller, which is what lets
## `tests/test_hud_widgets.gd` drive its visibility state machine with no
## player, no vitals, and no tree.
##
## Visible only while stamina is doing something worth showing: being spent,
## or resting below 85%. At rest and full, it disappears — the bible's ask is
## "hide/fade what is not relevant" (the same reasoning
## `playground_hud.gd::_update_vitals` already applies to the health/stamina
## bars it fades rather than hides outright; this widget hides outright
## because, unlike those two, it has nothing to say at rest).

const UI_TOKENS := preload("res://scripts/ui/ui_tokens.gd")

const SIZE := Vector2(48.0, 160.0)

const ARC_RADIUS := 150.0
const ARC_MARGIN := 4.0
const SWEEP_DEGREES := 60.0
const STROKE_WIDTH := 9.0
const ARC_SEGMENTS := 48
const TRACK_ALPHA := 0.4

## Visibility thresholds and timers — see `update_stamina()`.
const VISIBLE_BELOW := 0.85
const FULL_AT := 0.999
const FULL_HOLD_SECONDS := 0.35
const IDLE_HIDE_AFTER_SECONDS := 1.2
const FADE_OUT_SECONDS := 0.22

## Color tier boundaries (spec §6.6.2).
const WARNING_BELOW := 0.30
const DANGER_BELOW := 0.10

var _fraction := 1.0

## Counts up while the gauge would otherwise be idle-and-hideable (not
## draining, fraction >= `VISIBLE_BELOW`). Reset to zero the instant that
## stops being true, so a player who taps sprint again mid-countdown gets a
## full fresh grace window rather than an already-half-spent one.
var _idle_timer := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = SIZE
	size = SIZE
	visible = false
	modulate.a = 0.0


## `fraction`: current stamina, 0..1. `draining`: true while stamina is
## actively being spent this frame (sprinting, an action with a stamina
## cost) — separate from a low-but-recovering fraction because both cases
## must show the gauge, but only one of them resets the idle countdown that
## would otherwise start hiding it. `delta`: frame time, for the idle/fade
## timers below.
##
## State machine:
##   - `draining` OR `fraction < VISIBLE_BELOW`: shown immediately, no fade.
##   - full (`fraction >= FULL_AT`) and not draining: holds
##     `FULL_HOLD_SECONDS`, then fades out over `FADE_OUT_SECONDS`. Short,
##     because a topped-out gauge has nothing left to say.
##   - resting between `VISIBLE_BELOW` and `FULL_AT`, not draining: holds the
##     longer `IDLE_HIDE_AFTER_SECONDS` before the same fade — a partial
##     reserve is worth keeping on screen a beat longer than a full one, since
##     the player may well be about to spend it again.
func update_stamina(fraction: float, draining: bool, delta: float) -> void:
	_fraction = clampf(fraction, 0.0, 1.0)
	var full := _fraction >= FULL_AT
	var active := draining or _fraction < VISIBLE_BELOW

	if active:
		_idle_timer = 0.0
		visible = true
		modulate.a = 1.0
	else:
		var hold: float = FULL_HOLD_SECONDS if full else IDLE_HIDE_AFTER_SECONDS
		if _idle_timer < hold:
			_idle_timer += delta
		elif visible:
			modulate.a = move_toward(modulate.a, 0.0, delta / FADE_OUT_SECONDS)
			if modulate.a <= 0.0:
				visible = false

	# Perf: only ask for a redraw while there is something on screen to keep
	# current, matching the header's "hide what is not relevant" all the way
	# down to the draw call this file's header promises are skipped.
	if visible:
		queue_redraw()


## The color tier for a given stamina fraction, exposed static and pure so
## `tests/test_hud_widgets.gd` can check the boundaries without a Control at
## all — the same reasoning `UITokens.chance_tier_color` was written for
## (`ui_tokens.gd`), including its boundary convention: the value ON a
## threshold reads as the BETTER tier, not the worse one, so a fraction
## sitting exactly on 0.30 never flickers between mint and amber depending on
## which side of a float comparison it lands.
##
## Picked fresh from `fraction` every call rather than cached or stepped
## through intermediate state — "smooth, not stepped flicker" in the spec
## means the color is always a pure function of the CURRENT fraction, so it
## can never get stuck reporting a tier from a frame ago.
static func arc_color(fraction: float) -> Color:
	if fraction < DANGER_BELOW:
		return UI_TOKENS.DANGER
	elif fraction < WARNING_BELOW:
		return UI_TOKENS.WARNING
	else:
		return UI_TOKENS.TEAL_SOFT.lerp(Color.WHITE, 0.4)


func _draw() -> void:
	var half_sweep := deg_to_rad(SWEEP_DEGREES * 0.5)
	var center := Vector2(ARC_RADIUS + ARC_MARGIN, size.y * 0.5)
	# angle 0 is +x (screen right); Godot's canvas y grows downward, so the
	# larger angle (PI + half_sweep) is the visually higher point. Bottom to
	# top therefore runs start -> end as angle INCREASES.
	var start_angle := PI - half_sweep  # bottom of the curve
	var end_angle := PI + half_sweep    # top of the curve

	var track_color := Color(UI_TOKENS.TRACK.r, UI_TOKENS.TRACK.g, UI_TOKENS.TRACK.b, TRACK_ALPHA)
	draw_arc(center, ARC_RADIUS, start_angle, end_angle, ARC_SEGMENTS, track_color, STROKE_WIDTH, true)

	if _fraction > 0.0:
		var fill_end := start_angle + (end_angle - start_angle) * _fraction
		draw_arc(center, ARC_RADIUS, start_angle, fill_end, ARC_SEGMENTS, arc_color(_fraction), STROKE_WIDTH, true)
