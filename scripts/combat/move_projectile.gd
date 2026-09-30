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
	return LEGACY.launch(parent, from, to, spec, context)

static func travel_seconds(from: Vector3, to: Vector3, spec: Dictionary,
		context: Dictionary = {}) -> float:
	return LIBRARY.travel_seconds(from, to, spec, context)

static func cancel_action(tree: SceneTree, action_id: String) -> void:
	LIBRARY.cancel_action(tree, action_id)

## Reconcile drawing to an already accepted host impact. Combat can call this
## before presenting/debiting its result; no signal returned here owns HP.
static func confirm_impact(tree: SceneTree, action_id: String) -> void:
	if tree == null or action_id.is_empty(): return
	for effect: Node in tree.get_nodes_in_group("move_effect_presentation"):
		if not is_instance_valid(effect) or effect.is_queued_for_deletion(): continue
		if effect.has_method("action_id") and str(effect.call("action_id")) == action_id \
				and effect.has_method("confirm_presentation_impact"):
			effect.call("confirm_presentation_impact")

static func cancel_encounter(tree: SceneTree, encounter_id: String) -> void:
	LIBRARY.cancel_encounter(tree, encounter_id)
