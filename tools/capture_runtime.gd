extends RefCounted

## Shared guardrails for full-world visual evidence tools. Meadows startup can
## spend more than two minutes building its real 129k-prop world, so readiness
## must be a state check with wall-clock diagnostics, not an arbitrary number
## of rendered frames. This helper deliberately does not skip world content or
## change renderer settings: captures remain honest, only their failure mode is
## made bounded and legible.

const DEFAULT_TIMEOUT_MS := 300_000
const PROGRESS_INTERVAL_MS := 30_000


static func wait_until(
	tree: SceneTree, predicate: Callable, label: String,
	diagnostics: Callable = Callable(), timeout_ms: int = DEFAULT_TIMEOUT_MS
) -> bool:
	var started := Time.get_ticks_msec()
	var deadline := started + timeout_ms
	var next_progress := started + PROGRESS_INTERVAL_MS
	while Time.get_ticks_msec() < deadline:
		if bool(predicate.call()):
			print("  ready: %s after %.1fs" % [label, (Time.get_ticks_msec() - started) / 1000.0])
			return true
		var now := Time.get_ticks_msec()
		if now >= next_progress:
			print("  waiting: %s (%.1fs)%s" % [
				label,
				(now - started) / 1000.0,
				_diagnostic_suffix(diagnostics),
			])
			next_progress = now + PROGRESS_INTERVAL_MS
		await tree.process_frame
	print("FAIL: timed out after %.1fs waiting for %s%s" % [
		timeout_ms / 1000.0,
		label,
		_diagnostic_suffix(diagnostics),
	])
	return false


## Evidence directories persist between runs. Delete only the named PNGs this
## invocation promises to replace, so a timeout cannot be mistaken for a fresh
## successful capture and unrelated evidence is never removed.
static func clear_named_pngs(paths: Array[String]) -> Array[String]:
	var failures: Array[String] = []
	for path in paths:
		if not path.ends_with(".png"):
			failures.append("refused to clear non-PNG capture target %s" % path)
			continue
		var absolute := ProjectSettings.globalize_path(path)
		if FileAccess.file_exists(absolute):
			var error := DirAccess.remove_absolute(absolute)
			if error != OK:
				failures.append("could not clear stale capture %s (%d)" % [path, error])
	return failures


static func _diagnostic_suffix(diagnostics: Callable) -> String:
	if not diagnostics.is_valid():
		return ""
	var detail := str(diagnostics.call())
	return "" if detail.is_empty() else " -- %s" % detail
