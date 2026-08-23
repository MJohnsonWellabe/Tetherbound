extends RefCounted

## PERF-ROG / OP23-01. A per-subsystem frame-cost register, for the on-device
## overlay.
##
## The owner's report was "feels like ten frames per second on the ROG Ally" and
## nothing in the build could turn that into a number, let alone into a ranking.
## `tools/perf_profile.gd` can, but only in a container, on hardware nobody
## plays on. This is the device-side half: the same subsystems report what their
## own last call cost, the HUD's F3 readout ranks them, and the next owner
## playtest produces "collision streaming 12ms" instead of "it's slow".
##
## WHY IT IS SAFE TO LEAVE IN THE SHIPPED BUILD.
##
## Tracing is off unless the overlay asks for it. A traced call site pays one
## static bool read when it is off -- `if PERF_TRACE.enabled:` -- which is the
## cheapest thing GDScript can do and is nothing beside the work it guards. When
## it IS on, each site pays two `Time.get_ticks_usec()` calls and one dictionary
## write per call, which is measurable but is the price of measuring at all, and
## the overlay is the only thing that turns it on.
##
## Costs are reported as an exponential moving average rather than a last
## sample: the numbers that matter are per-frame ones in the tenths of a
## millisecond, where a single sample is mostly scheduling noise, and a mean
## over a fixed window would need a ring buffer per label. The smoothing is
## deliberately fast (`SMOOTHING`) so walking into a dense stand still moves the
## reading within a second or so.

## How much of the new sample each update takes. 0.1 settles in roughly 20
## samples -- a third of a second at 60fps for a per-frame cost.
const SMOOTHING := 0.1

## Off by default and turned on only by the overlay. Static so a call site can
## read it without holding a reference to anything.
static var enabled: bool = false

## label -> {"ms": float (smoothed cost of one call), "hz": float (smoothed
## calls per second), "calls": int}.
static var _costs: Dictionary = {}
static var _last_seen: Dictionary = {}


## Record one call of `label` that took `usec` microseconds.
##
## Call rate is measured rather than assumed: `interaction_arbiter` runs every
## frame and `vegetation.update_collision_streaming` runs twice a second, and a
## ranking by cost-per-call would put the twice-a-second sweep on top of a
## per-frame cost sixty times its size. `ms_per_second()` is what the overlay
## sorts on.
static func record(label: String, usec: int) -> void:
	var ms := float(usec) / 1000.0
	var now := Time.get_ticks_usec()
	var entry: Dictionary = _costs.get(label, {"ms": ms, "hz": 0.0, "calls": 0})
	entry["ms"] = lerpf(float(entry["ms"]), ms, SMOOTHING)
	entry["calls"] = int(entry["calls"]) + 1
	if _last_seen.has(label):
		var gap := float(now - int(_last_seen[label])) / 1_000_000.0
		if gap > 0.0:
			var hz := 1.0 / gap
			# The first interval is measured against a start-of-trace timestamp
			# and can be anything; take it whole rather than smoothing toward it
			# from a zero that would read as "never called".
			entry["hz"] = hz if float(entry["hz"]) <= 0.0 else lerpf(float(entry["hz"]), hz, SMOOTHING)
	_last_seen[label] = now
	_costs[label] = entry


## Milliseconds of work this label asks for per wall-clock second. This, not
## cost-per-call, is what decides whether a subsystem is a problem.
static func ms_per_second(label: String) -> float:
	var entry: Dictionary = _costs.get(label, {})
	if entry.is_empty():
		return 0.0
	return float(entry.get("ms", 0.0)) * float(entry.get("hz", 0.0))


## The `count` most expensive labels, dearest first, as
## `[{label, ms, hz, ms_per_second}]`. Empty until something has been recorded,
## which is the honest answer for an overlay switched on mid-session.
static func top(count: int) -> Array:
	var rows: Array = []
	for label: String in _costs.keys():
		var entry: Dictionary = _costs[label]
		rows.append({
			"label": label,
			"ms": float(entry.get("ms", 0.0)),
			"hz": float(entry.get("hz", 0.0)),
			"ms_per_second": ms_per_second(label),
		})
	rows.sort_custom(func(a, b): return float(a["ms_per_second"]) > float(b["ms_per_second"]))
	return rows.slice(0, maxi(0, count))


## Turn tracing on or off. Clears on the way on, so a reading is never a blend
## of this session and whatever the overlay saw last time it was open.
static func set_enabled(value: bool) -> void:
	if value and not enabled:
		_costs.clear()
		_last_seen.clear()
	enabled = value
