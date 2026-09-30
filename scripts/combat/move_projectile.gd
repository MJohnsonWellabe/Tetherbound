extends Node3D

## Backward-compatible presentation facade. Combat owns the immutable host
## arrival schedule even if this node is absent, culled or removed on exit.
## Neither this facade nor the library can mutate HP, poise, rewards or input.
const LIBRARY := preload("res://scripts/vfx/move_effect_library.gd")
const LEGACY := preload("res://scripts/vfx/legacy_move_travel.gd")

signal arrived()

static func launch(parent: Node, from: Vector3, to: Vector3, spec: Dictionary,
		context: Dictionary = {}) -> Node3D:
	if spec.has("archetype") and bool(LIBRARY.config().get("enabled", false)):
		return LIBRARY.launch(parent, from, to, spec, context)
	var fallback := LEGACY.launch(parent, from, to, spec)
	if fallback != null and context.has("travel_seconds"):
		fallback.set("_travel", maxf(0.0, float(context.travel_seconds)))
	return fallback

static func travel_seconds(from: Vector3, to: Vector3, spec: Dictionary,
		context: Dictionary = {}) -> float:
	return LIBRARY.travel_seconds(from, to, spec, context)
