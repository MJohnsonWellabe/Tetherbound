extends Label3D

## Test-only lifetime counterfactual, installed on existing actual chamber
## captions after the choice opens. No live property is changed. No product
## factory uses this script, and its result cannot count as acceptance proof.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		print("F19 LABEL BASE DETACH " + JSON.stringify({
			"original_path": str(get_meta("f19_diagnostic_original_path", "")),
			"text": text, "acceptance": false}))
		set_base(RID())
