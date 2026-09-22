extends RefCounted

## Conditional protocol completion is not input coverage. The production caller
## supplies _step_assert as read; this helper invokes it NOW, never accepting a
## cached receipt. Optional/context/derail skips must never call this pathway.
const ACTIONS := ["press", "move_to_entity", "interact_with", "press_until",
	"chip_to_floor", "throw_until_caught", "track_aim", "force_aim", "focus_row"]


static func evaluate(action: String, predicate: Dictionary, read: Callable) -> Dictionary:
	var result := {"satisfied": false, "actual": "", "input_issued": false}
	if action not in ACTIONS or predicate.is_empty() \
			or str(predicate.get("check", "")).is_empty() or not read.is_valid():
		return result
	var checked: Variant = read.call(predicate.duplicate(true))
	if not checked is Dictionary:
		return result
	# Explicit booleans, no string/int coercion and no unevaluable-envelope pass.
	if typeof(checked.get("ok")) != TYPE_BOOL or checked.get("ok") != true \
			or bool(checked.get("skip", false)):
		return result
	var actual := str(checked.get("actual", "")).strip_edges()
	if actual.is_empty() or actual.begins_with("SKIPPED") \
			or actual.begins_with("FAIL") or actual.begins_with("BLOCKER") \
			or actual.begins_with("HARNESS-ERROR"):
		return result
	result.satisfied = true
	result.predicate = predicate.duplicate(true)
	result.readback = actual
	result.actual = "CONDITION-SATISFIED %s: authored skip_if verified from live state; no action input issued. predicate=%s; readback=%s" \
		% [action, JSON.stringify(predicate), actual]
	return result
