extends SceneTree

## Evidence-routing regression only. This synthetic refusal cannot satisfy
## any capture, character-save, transaction or F48 acceptance requirement.
const STEPS := preload("res://tools/net/proof_steps_f48.gd")
var _original := {"verdict": "FAIL", "detail": "synthetic owner refusal",
	"data": {"owner_plan": {"ok": false, "code": "owner_action_baseline_conflict"},
		"owner_before": {"fixture": "before"}, "owner_after": {"fixture": "after"}}}

func _init() -> void:
	_run.call_deferred()

func _step_f48_fixture_capture(_args: Dictionary) -> Dictionary:
	return _original.duplicate(true)

func _run() -> void:
	var output := ProjectSettings.globalize_path("user://f48-capture-evidence-" + str(Time.get_ticks_usec()))
	OS.set_environment("TB_PROOF_OUT", output)
	var args := {"fixture_disclosure": "synthetic_evidence_route_only"}
	var result := await STEPS.step(self, "f48_fixture_capture", args)
	var path := str(result.get("data", {}).get("observation_path", ""))
	var saved: Variant = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	var checks := [result.get("verdict") == "FAIL", result.get("detail") == _original.detail,
		saved is Dictionary and saved.get("action") == "f48_fixture_capture",
		saved is Dictionary and saved.get("args") == args,
		saved is Dictionary and saved.get("result") == _original]
	var failures := checks.count(false)
	print("F48 capture evidence routing: %d checks, %d failures; synthetic only" % [checks.size(), failures])
	quit(1 if failures > 0 else 0)
