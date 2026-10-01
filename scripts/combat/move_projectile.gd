extends Node3D

## Disposable drawing of the same accepted combat action. Combat owns HP,
## the immutable host arrival, current actor/target and receipt commit.
const LIBRARY := preload("res://scripts/vfx/move_effect_library.gd")
const LEGACY := preload("res://scripts/vfx/legacy_move_travel.gd")
const ULTIMATE_PATH := "res://scripts/vfx/ultimates/ultimate_library.gd"

signal arrived()

static func launch(parent: Node, from: Vector3, to: Vector3, spec: Dictionary,
		context: Dictionary = {}) -> Node3D:
	# F35 receives the complete F23 frozen row, including its accepted identity.
	# Dynamic loading lets the independently owned F35 source land separately.
	if str(spec.get("slot", "")) == "ultimate":
		if not FileAccess.file_exists(ULTIMATE_PATH): return null
		var ultimates := load(ULTIMATE_PATH) as Script
		if ultimates == null or not ultimates.has_method("launch"): return null
		return ultimates.call("launch", parent, from, to, spec, context) as Node3D
	if spec.has("vfx") and not spec.vfx is Dictionary: return null
	var visual: Dictionary = spec.get("vfx", spec)
	if bool(LIBRARY.config().get("enabled", false)) and visual.has("archetype"):
		return LIBRARY.launch(parent, from, to, spec, context)
	return LEGACY.launch(parent, from, to, visual, context)

## Presentation estimate for older callers only. The accepted host schedule
## supplies travel_seconds at production birth; this result cannot commit HP.
static func travel_seconds(from: Vector3, to: Vector3, spec: Dictionary,
		context: Dictionary = {}) -> float:
	return LIBRARY.travel_seconds(from, to, spec.get("vfx", spec), context)

static func cancel_action(tree: SceneTree, action_id: String) -> void:
	LIBRARY.cancel_action(tree, action_id)

static func impact_cue(frozen_move: Dictionary) -> Dictionary:
	return LIBRARY.impact_cue(frozen_move)

static func confirm_impact(tree: SceneTree, action_id: String) -> void:
	if tree == null or action_id.is_empty(): return
	for effect: Node in tree.get_nodes_in_group("move_effect_presentation"):
		if not is_instance_valid(effect) or effect.is_queued_for_deletion(): continue
		if effect.has_method("action_id") and str(effect.call("action_id")) == action_id \
				and effect.has_method("confirm_presentation_impact"):
			effect.call("confirm_presentation_impact")

static func cancel_encounter(tree: SceneTree, encounter_id: String) -> void:
	LIBRARY.cancel_encounter(tree, encounter_id)

## Call from the existing actor replacement/death/exit lifecycle. Starting a
## newer action on the same body does not erase an already airborne action.
static func reconcile_actor(tree: SceneTree, current: Dictionary) -> void:
	if tree == null: return
	for effect: Node in tree.get_nodes_in_group("move_effect_presentation"):
		if is_instance_valid(effect) and not effect.is_queued_for_deletion() \
				and effect.has_method("reconcile_actor"):
			# F35 also joins this shared presentation group. Explicit scope
			# prevents one actor replacement from cancelling another player's.
			if not effect.has_method("actor_binding"): continue
			var binding: Dictionary = effect.call("actor_binding")
			if binding.get("character_id") == current.get("character_id") \
					and binding.get("encounter_id") == current.get("encounter_id"):
				effect.call("reconcile_actor", current)
