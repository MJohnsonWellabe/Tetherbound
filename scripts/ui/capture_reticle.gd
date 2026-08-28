extends Control

## The capture reticle (spec §10.2, decision D31: an explicit percentage,
## not a worded odds tier). Floats over the enemy's screen position while
## aiming, and plays the attempt choreography (contract -> per-shake pulse ->
## success/break burst) that follows a released throw.
##
## Positioning is entirely combat_hud.gd's job — this file only draws
## whatever `update_target()` last told it and animates whatever the four
## `play_*()` calls started. It owns no reference to the fight, the camera,
## or the enemy; that split is the same "HUD reads, never owns state" rule
## the rest of combat_hud.gd's header states, one file further out.
##
## Geometry at the target point: a broken ring (5 arcs + 5 tether-node dots
## in the gaps), a thin central diamond, and an inner teal arc whose swept
## fraction IS the catch chance — filled clockwise from the top, same
## direction a clock hand moves. The number below the ring is the same
## chance in the tier's own colour (`UITokens.chance_tier_color`); the
## colour is a read at a glance, the digits are the actual answer, and the
## digits are never dropped in favour of the colour.
##
## All four choreography beats are timer dictionaries ticked in `_process`
## and drawn in `_draw` — no `Tween` node per effect, because several of
## these can be alive at once (a pulse arriving mid-contract, say) and a
## flat list of "elapsed / duration" entries composes without one tween
## fighting another over the same property.

const RING_DIAMETER := 180.0
const GAP_DEGREES := 14.0
const ARC_SEGMENTS := 5
const NODE_DOT_RADIUS := 3.0
const DIAMOND_HALF := 7.0
const INNER_RING_INSET := 16.0
const ARC_WIDTH := 3.0

const PULSE_DURATION := 0.18
const CONTRACT_DURATION := 0.25
const SUCCESS_DURATION := 0.4
const BREAK_DURATION := 0.3

const READOUT_GAP := 40.0
const CAPTION_GAP := 22.0
## How much wider the ring stands off the body while the aim is NOT on the
## creature. Enough to read as a different state at a glance rather than as the
## same ring in a different mood.
const UNLOCKED_RING_STANDOFF := 14.0

var _active := false
var _pos := Vector2.ZERO
var _chance := 0.0
## Whether the aim is genuinely on the creature (reticle inside the visible
## body, with line of sight). See `update_target()`'s own note for why the ring
## has to say this out loud.
var _locked := true

## Transient choreography state. Each of `_pulses`' entries and the three
## singleton dictionaries below carry their own `t` (seconds elapsed),
## cleared once `t` passes that effect's duration.
var _pulses: Array = []
var _contract: Dictionary = {}
var _success: Dictionary = {}
var _break_fx: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)


## Called every frame while aiming (and once more with `active=false` the
## frame aiming stops). `screen_pos`/`chance` are ignored while inactive —
## the ring simply stops drawing until the next active update.
## `locked` is whether the reticle is actually ON the creature. It defaults
## true so an older caller keeps the previous appearance.
##
## The ring used to draw identically whether the player was lined up or lobbing
## an orb into the grass beside the target, and `catch_chance_now()` fed it the
## dead-centre chance in both cases. So the one piece of information the player
## most needed before spending an orb -- am I actually on it -- was the one
## thing the capture reticle did not say, and a miss and an unlucky roll were
## indistinguishable both before the throw and after it.
func update_target(screen_pos: Vector2, chance: float, active: bool,
		locked: bool = true) -> void:
	_pos = screen_pos
	_chance = clampf(chance, 0.0, 1.0)
	_active = active
	_locked = locked
	queue_redraw()


## The ring shrinks and fades from wherever it last sat toward
## `to_screen_pos` — the orb's strike point, when combat_hud.gd can reach
## it, or the ring's own last position otherwise (a fade in place, per the
## task brief's "if reachable, else just fade").
## `resolved_chance` is the odds the landed throw ACTUALLY rolled at, including
## where the orb struck. Negative means "unknown", and the ring falls back to
## whatever the aim last showed -- which is what it always used to do, and is
## the reason a clipped throw and a centred one contracted identically.
func play_contract(to_screen_pos: Vector2, resolved_chance: float = -1.0) -> void:
	var shown := _chance if resolved_chance < 0.0 else clampf(resolved_chance, 0.0, 1.0)
	_contract = {"from": _pos, "to": to_screen_pos, "t": 0.0, "chance": shown}
	_active = false


## A brief expanding ring on each orb shake — tension made visible, not just
## audible-in-text.
func play_pulse() -> void:
	_pulses.append({"t": 0.0, "pos": _effect_anchor()})


## Teal/gold double-ring burst on a successful catch.
func play_success() -> void:
	_success = {"t": 0.0, "pos": _effect_anchor()}


## Red/orange arcs scattering outward on a failed catch.
func play_break() -> void:
	_break_fx = {"t": 0.0, "pos": _effect_anchor()}


## Wherever the ring last actually was — the contract's landing point once
## one has played this attempt, else the last aimed-at position.
func _effect_anchor() -> Vector2:
	if not _contract.is_empty():
		return _contract.get("to", _pos)
	return _pos


func _process(delta: float) -> void:
	var animating := false

	if not _contract.is_empty():
		_contract["t"] = float(_contract["t"]) + delta
		if float(_contract["t"]) >= CONTRACT_DURATION:
			_contract.clear()
		else:
			animating = true

	for pulse in _pulses.duplicate():
		pulse["t"] = float(pulse["t"]) + delta
		if float(pulse["t"]) >= PULSE_DURATION:
			_pulses.erase(pulse)
		else:
			animating = true

	if not _success.is_empty():
		_success["t"] = float(_success["t"]) + delta
		if float(_success["t"]) >= SUCCESS_DURATION:
			_success.clear()
		else:
			animating = true

	if not _break_fx.is_empty():
		_break_fx["t"] = float(_break_fx["t"]) + delta
		if float(_break_fx["t"]) >= BREAK_DURATION:
			_break_fx.clear()
		else:
			animating = true

	if _active or animating:
		queue_redraw()


func _draw() -> void:
	if _active:
		_draw_ring(_pos, _chance, 1.0, 1.0, _locked)

	if not _contract.is_empty():
		var t: float = float(_contract["t"]) / CONTRACT_DURATION
		var pos: Vector2 = Vector2(_contract["from"]).lerp(Vector2(_contract["to"]), t)
		# A contract only ever plays off a thrown orb, which by then is a
		# committed throw rather than an aim -- so it always draws locked.
		_draw_ring(pos, float(_contract.get("chance", _chance)), lerp(1.0, 0.35, t), 1.0 - t, true)

	for pulse in _pulses:
		_draw_pulse(Vector2(pulse["pos"]), float(pulse["t"]) / PULSE_DURATION)

	if not _success.is_empty():
		_draw_success(Vector2(_success["pos"]), float(_success["t"]) / SUCCESS_DURATION)

	if not _break_fx.is_empty():
		_draw_break(Vector2(_break_fx["pos"]), float(_break_fx["t"]) / BREAK_DURATION)


## The ring itself: broken outer ring + tether-node dots, central diamond,
## inner teal chance-arc, and the percentage/caption readout below it.
## `scale_value` shrinks everything but the stroke widths (a thinner ring
## reads as further away, not as a different ring), `alpha` fades the lot.
func _draw_ring(center: Vector2, chance: float, scale_value: float, alpha: float,
		locked: bool = true) -> void:
	var radius: float = (RING_DIAMETER * 0.5) * scale_value
	var tier_colour: Color = UITokens.chance_tier_color(chance)
	tier_colour.a *= alpha
	# An unlocked ring is drawn OPEN and quiet: the arcs fade back, the ring
	# stands off wider, and the readout stops claiming a capture chance. It is
	# deliberately not just a dimmer version of the same ring -- the two states
	# mean different things ("this is your chance" vs "you are not on it") and
	# a player has to be able to tell them apart at a glance, mid-fight, on a
	# 7-inch panel.
	if not locked:
		tier_colour = UITokens.TEXT_MUTED
		tier_colour.a *= alpha * 0.85
		radius += UNLOCKED_RING_STANDOFF * scale_value

	var gap_rad := deg_to_rad(GAP_DEGREES)
	var segment_rad: float = (TAU - float(ARC_SEGMENTS) * gap_rad) / float(ARC_SEGMENTS)
	for i in ARC_SEGMENTS:
		var start: float = float(i) * (segment_rad + gap_rad) + gap_rad * 0.5
		draw_arc(center, radius, start, start + segment_rad, 24, tier_colour, ARC_WIDTH, true)
		var dot_angle: float = start - gap_rad * 0.5
		var dot_pos: Vector2 = center + Vector2(cos(dot_angle), sin(dot_angle)) * radius
		draw_circle(dot_pos, NODE_DOT_RADIUS * scale_value, tier_colour)

	var dh: float = DIAMOND_HALF * scale_value
	draw_line(center + Vector2(0.0, -dh), center + Vector2(dh, 0.0), tier_colour, 2.0)
	draw_line(center + Vector2(dh, 0.0), center + Vector2(0.0, dh), tier_colour, 2.0)
	draw_line(center + Vector2(0.0, dh), center + Vector2(-dh, 0.0), tier_colour, 2.0)
	draw_line(center + Vector2(-dh, 0.0), center + Vector2(0.0, -dh), tier_colour, 2.0)

	var inner_radius: float = radius - INNER_RING_INSET * scale_value
	var sweep: float = TAU * chance
	if sweep > 0.001 and inner_radius > 2.0:
		var inner_colour := UITokens.TEAL_SOFT
		inner_colour.a *= alpha
		# Clockwise from the top: draw_arc's angle 0 points along +X and grows
		# clockwise on screen (Y-down), so starting at -TAU/4 (straight up)
		# and sweeping by a POSITIVE amount is exactly "fill clockwise from
		# twelve o'clock" — the same direction the shake countdown empties.
		draw_arc(center, inner_radius, -PI * 0.5, -PI * 0.5 + sweep, 48, inner_colour, ARC_WIDTH, true)

	_draw_readout(center, radius, chance, tier_colour, alpha, locked)


func _draw_readout(center: Vector2, radius: float, chance: float, tier_colour: Color,
		alpha: float, locked: bool = true) -> void:
	var font := get_theme_default_font()
	if font == null:
		return

	# Withheld rather than greyed. A percentage that is on screen is read as an
	# answer, and off the body there is no honest answer to give -- the throw
	# does not have a low catch chance, it has a miss chance this widget cannot
	# compute. Saying "NOT ON TARGET" is the true statement.
	var pct_text := "%d%%" % int(round(chance * 100.0)) if locked else "--"
	var pct_size := UITokens.FONT_BIG_NUMBER - 4
	var pct_dims: Vector2 = font.get_string_size(pct_text, HORIZONTAL_ALIGNMENT_LEFT, -1, pct_size)
	var pct_pos := center + Vector2(-pct_dims.x * 0.5, radius + READOUT_GAP)
	draw_string(font, pct_pos, pct_text, HORIZONTAL_ALIGNMENT_LEFT, -1, pct_size, tier_colour)

	var caption_text := "CAPTURE CHANCE" if locked else "NOT ON TARGET"
	var caption_colour := UITokens.TEXT_SECONDARY
	caption_colour.a *= alpha
	var caption_dims: Vector2 = font.get_string_size(
		caption_text, HORIZONTAL_ALIGNMENT_LEFT, -1, UITokens.FONT_TINY
	)
	var caption_pos := center + Vector2(-caption_dims.x * 0.5, radius + READOUT_GAP + CAPTION_GAP)
	draw_string(font, caption_pos, caption_text, HORIZONTAL_ALIGNMENT_LEFT, -1, UITokens.FONT_TINY, caption_colour)


## A single expanding, fading ring — the visible half of an orb shake.
func _draw_pulse(pos: Vector2, t: float) -> void:
	var radius: float = lerp(RING_DIAMETER * 0.35, RING_DIAMETER * 0.75, t)
	var colour := UITokens.TEAL
	colour.a = 1.0 - t
	draw_arc(pos, radius, 0.0, TAU, 40, colour, ARC_WIDTH + 1.0, true)


## Two rings expanding at different rates, teal outrunning gold — the catch
## sealing shut, read as light rather than as text.
func _draw_success(pos: Vector2, t: float) -> void:
	var r1: float = lerp(RING_DIAMETER * 0.30, RING_DIAMETER * 0.95, t)
	var r2: float = lerp(RING_DIAMETER * 0.15, RING_DIAMETER * 0.65, t)
	var teal := UITokens.TEAL_SOFT
	teal.a = 1.0 - t
	var gold := UITokens.WARNING
	gold.a = 1.0 - t
	draw_arc(pos, r1, 0.0, TAU, 48, teal, 4.0, true)
	draw_arc(pos, r2, 0.0, TAU, 48, gold, 4.0, true)


## Three short arcs flying outward and spinning as they go — the ring
## breaking apart rather than politely fading, so a failure never plays like
## a quieter version of the success burst above it.
func _draw_break(pos: Vector2, t: float) -> void:
	var colour := UITokens.DANGER
	colour.a = 1.0 - t
	var travel: float = lerp(RING_DIAMETER * 0.3, RING_DIAMETER * 1.05, t)
	var arc_len := deg_to_rad(50.0)
	for i in 3:
		var dir_angle: float = float(i) * TAU / 3.0 + t * 1.4
		var shard_centre: Vector2 = pos + Vector2(cos(dir_angle), sin(dir_angle)) * travel
		draw_arc(shard_centre, RING_DIAMETER * 0.2, dir_angle, dir_angle + arc_len, 12, colour, ARC_WIDTH, true)
