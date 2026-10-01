extends SceneTree

## Named F22#0 contract proof to queue with ROOT's serialized engine batch.
## This checks actual CombatAI + shipped authored rows, not engine acceptance
## or displayed geometry, body movement, reaction observation or code-blind ID.
const AI := preload("res://scripts/combat/combat_ai.gd")
const MATH := preload("res://scripts/combat/combat_math.gd")
var _errors: Array[String] = []


func _init() -> void:
	_run.call_deferred()


func _check(value: bool, reason: String) -> void:
	if not value: _errors.append(reason)


func _run() -> void:
	var patterns: Dictionary = MATH.config().get("patterns", {})
	var base: Dictionary = MATH.config().get("enemy", {})
	for role: String in ["WALL", "CHARGER", "DIVER", "CURRENT", "ACE"]:
		var context := {"role": role, "chapter": "meadows", "move_quick": "pebble_toss",
			"move_charged": "stone_rush", "trainer_owned": true}
		var ids := AI.pattern_ids(patterns, role, context)
		_check(ids.size() >= 2, role + " lacks two authored role patterns")
		for cursor: int in ids.size():
			var row := AI.select_pattern(patterns, base, context, cursor)
			_check(not row.is_empty(), role + " failed owned move binding")
			_check(float(row.get("telegraph", 0.0)) >= (1.1 if bool(row.get("heavy", false)) else 1.0), role + " erased chapter/heavy tell")
			_check(float(row.get("recovery", 0.0)) >= 0.9, role + " erased chapter recovery")
	var opening := {"role": "CHARGER", "chapter": "meadows", "band": "band1_lower_meadows"}
	_check(AI.pattern_ids(patterns, "CHARGER", opening).size() == 1, "early wild has multiple lessons")
	opening.chapter = "water"
	_check(AI.pattern_ids(patterns, "CHARGER", opening).size() >= 2, "Meadows band leaked into Tidewake")
	_check(AI.normalize_role("ambush counterattacker", patterns) == "WALL", "compound role priority drifted")
	_check(AI.normalize_role("unknown", patterns).is_empty(), "unknown role silently acquired generic AI")
	var named := {"pattern_id": "named_warden_aldis", "sendout_index": 4, "role": "WALL"}
	_check(AI.context_role(patterns, named) == "ACE", "authored named ACE lost its composite role")
	named.sendout_index = 99
	_check(AI.pattern_ids(patterns, "WALL", named).is_empty(), "wrong named send-out fell back to generic role")
	var observed := {"action": "charged_windup", "visible_for_s": 0.249, "distance": 4.0,
		"safe_dodge_lane": true, "dodge_cooldown_s": 0.0}
	_check(AI.reaction(AI.Intent.CLOSE, observed, patterns).is_empty(), "AI predicted commitment before .25s observation")
	observed.visible_for_s = 0.25
	_check(AI.reaction(AI.Intent.CLOSE, observed, patterns) == "dodge", "observed commitment did not permit spatial dodge")
	_check(AI.reaction(AI.Intent.TELEGRAPH, observed, patterns).is_empty(), "AI cancelled its tell")
	_check(AI.reaction(AI.Intent.RECOVER, observed, patterns).is_empty(), "AI cancelled its recovery")
	observed.safe_dodge_lane = false
	_check(AI.reaction(AI.Intent.CLOSE, observed, patterns).is_empty(), "AI dodged into an unsafe lane")
	observed.safe_dodge_lane = true
	observed.distance = 3.0
	_check(AI.reaction(AI.Intent.CLOSE, observed, patterns).is_empty(), "AI dodged at forbidden short range")
	observed.distance = 4.0
	observed.dodge_cooldown_s = 0.1
	_check(AI.reaction(AI.Intent.CLOSE, observed, patterns).is_empty(), "AI ignored its dodge cooldown")
	var attacks: Dictionary = patterns.get("attacks", {})
	var lane: Dictionary = attacks.get("charger_rush", {})
	_check(AI.pattern_contains(lane, Vector3.ZERO, Vector3.FORWARD, Vector3.ZERO, Vector3(0, 0, -3)), "lane missed its advertised centre")
	_check(not AI.pattern_contains(lane, Vector3.ZERO, Vector3.FORWARD, Vector3.ZERO, Vector3(5, 0, -3)), "lane struck its safe lateral exit")
	var field: Dictionary = attacks.get("current_zone", {})
	var marker := Vector3(4, 0, 4)
	_check(AI.pattern_contains(field, Vector3.ZERO, Vector3.FORWARD, marker, marker), "field ignored its committed marker")
	_check(not AI.pattern_contains(field, Vector3.ZERO, Vector3.FORWARD, marker, Vector3.ZERO), "field retargeted to its origin")
	var ring: Dictionary = attacks.get("marrow_bank_answer", {})
	_check(not AI.pattern_contains(ring, Vector3.ZERO, Vector3.FORWARD, Vector3.ZERO, Vector3.ZERO), "authored ring centre is not a safe pocket")
	var guardian: Dictionary = attacks.get("guardian_earth_fist", {})
	_check(AI.armored_front_scale(guardian, Vector3.ZERO, Vector3.FORWARD, Vector3(0, 0, -2)) < 1.0, "guardian front is unarmored")
	_check(AI.armored_front_scale(guardian, Vector3.ZERO, Vector3.FORWARD, Vector3(0, 0, 2)) == 1.0, "guardian rear received hidden armor")
	print("F22_PATTERN_CONTRACT " + JSON.stringify({"pass": _errors.is_empty(), "errors": _errors,
		"scope": "pure actual-source contract only; runtime and C2/C3 remain separate"}))
	quit(0 if _errors.is_empty() else 1)
