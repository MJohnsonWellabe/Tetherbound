extends RefCounted

## Presentation-only run maths for the trainer model: a steady forward lean that
## grows with ground speed above walk speed, and a gait playback scale that
## tracks ground speed. Pure statics so tests can pin them headless.
## Tunables live in data/config/movement.json `gait_feel` (run_* keys).
## trainer_model.gd drives it, and remote_trainer.gd reuses trainer_model.gd, so
## host and guests see the same lean with no extra network state.


## 0 at or below walk speed, `max_deg` at or above full speed, smoothstep between.
static func lean_target_deg(speed: float, walk_speed: float, full_speed: float, max_deg: float) -> float:
	if full_speed <= walk_speed or max_deg <= 0.0:
		return 0.0
	var t := clampf((speed - walk_speed) / (full_speed - walk_speed), 0.0, 1.0)
	return max_deg * t * t * (3.0 - 2.0 * t)


## Frame-rate independent exponential ease; `ease_s` is the time constant.
static func ease_toward(current: float, target: float, delta: float, ease_s: float) -> float:
	if delta <= 0.0:
		return current
	if ease_s <= 0.0:
		return target
	return lerpf(current, target, 1.0 - exp(-delta / ease_s))


## Playback speed for a gait clip authored at `reference_speed`. `cadence_scale`
## (<1 slows the step rate below the authored one) is a per-role feel factor.
static func playback_scale(ground_speed: float, reference_speed: float, cadence_scale: float,
		min_scale: float, max_scale: float) -> float:
	if reference_speed <= 0.0:
		return 1.0
	return clampf(ground_speed / reference_speed * cadence_scale, min_scale, max_scale)
