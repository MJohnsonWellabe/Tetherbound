extends Sprite3D

## Test-only counterfactual attached to actual scriptless world sprites.
## No live property changes; no product factory uses this script.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		print("F19 SPRITE BASE DETACH " + JSON.stringify({
			"original_path": str(get_meta("f19_diagnostic_original_path", "")),
			"acceptance": false}))
		set_base(RID())
