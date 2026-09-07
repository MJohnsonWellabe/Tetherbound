extends "res://scripts/combat/cloudreach_combat_manager.gd"

## Every participant earns the normal per-creature victory award exactly once,
## whether its own verdict or somebody else's host record arrives first.
var _hosted_awarded := false

func bind_encounter(link: Node, id: String, kind: String) -> void:
	_hosted_awarded = false
	super.bind_encounter(link, id, kind)

func _award_victory() -> void:
	if _encounter_link != null and _encounter_link.has_method("hosted_transport"):
		if _hosted_awarded:
			return
		_hosted_awarded = true
	super._award_victory()

func apply_encounter_record(rec: Dictionary, quiet: bool = false) -> void:
	if _encounter_link != null and _encounter_link.has_method("hosted_transport") \
			and str(rec.get("encounter_id", "")) == _encounter_id \
			and int(rec.get("seq", 0)) >= _encounter_seq \
			and str(rec.get("phase", "")) == "done" \
			and float((rec.get("opponent", {}) as Dictionary).get("hp", 1.0)) <= 0.0:
		_award_victory()
	super.apply_encounter_record(rec, quiet)
