extends SceneTree

## Both former pure-init cases run here against actual process frames.
## No discovery exclusion or relaxed assertion is used. The CI step is required
## alongside the existing regional ending smoke; this remains synthetic proof.
const CASES := preload("res://tests/fixtures/regional_homecoming_pending_cases.gd")
const CASE_NAMES: Array[String] = [
	"test_pending_owner_acknowledgement_waits_for_receipt",
	"test_pending_owner_result_cannot_cross_reconnect_generation",
]
const EXPECTED_ASSERTIONS := 9 # Seven retained assertions plus two live-tree guards.


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	var suite := CASES.new()
	var completed := 0
	for case_name: String in CASE_NAMES:
		suite.before_each()
		await suite.call(case_name)
		suite.after_each()
		if suite.completed_cases.get(case_name) == true:
			completed += 1
		else:
			suite.failures.append("Case aborted before its final assertion: " + case_name)
	if completed != CASE_NAMES.size() or suite.assertion_count != EXPECTED_ASSERTIONS:
		suite.failures.append("Both cases must complete all nine assertions, including every retained receipt/epoch negative control.")
	var failed := suite.failures.size()
	for failure: String in suite.failures:
		print("smoke FAIL: ", failure)
	print("regional pending acknowledgement: %d cases, %d assertions, %d failed" % [
		completed, suite.assertion_count, failed])
	suite = null
	await process_frame
	quit(1 if failed > 0 else 0)
