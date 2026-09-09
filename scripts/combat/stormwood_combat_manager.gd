extends "res://scripts/combat/cloudreach_combat_manager.gd"

## Every participant earns the normal per-creature victory award exactly once,
## whether its own verdict or somebody else's host record arrives first.
var _hosted_awarded := false


## Final human death ends this participant's control immediately, including a
## won round's resolving pause. The hub separately withdraws the participant
## from the roster; ordinary done-round disengage intentionally does not do so.
func abort_for_finalized_death() -> void:
	if not is_fighting():
		return
	unbind_encounter()
	# _begin_resolve refuses to replace an existing RESOLVING outcome. Final
	# death must not retain "won" and admit the next round after camp recovery.
	_outcome = "lost"
	_finish()


## A trainer challenge is admitted by the realm host, but an aggressive local
## wild can reach the player during the network round trip.  Once the host has
## admitted the challenge its record is authoritative.  Yield only a fleeable
## wild fight; an existing trainer fight must never be torn down this way.
func yield_wild_fight_for_hosted_trainer() -> bool:
	if not is_fighting() or not can_flee():
		return false
	_begin_resolve("fled")
	_finish()
	return true

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
