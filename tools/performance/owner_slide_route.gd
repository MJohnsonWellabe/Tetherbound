extends "res://tools/capture_lookdev_route.gd"
const OWNER_PROBE := preload("res://tools/performance/owner_slide_attribution.gd")

func _capture_route_case() -> void:
	OWNER_PROBE.prepare(_world, _source_commit)
	await super._capture_route_case()

func _record_frame() -> void:
	if _measuring and OWNER_PROBE.start_process < 0:
		OWNER_PROBE.start({"source": _source_commit, "biome": _biome_id, "preset": _preset,
			"route_revision": _manifest.get("route_revision", ""),
			"route_config_sha256": _manifest.get("route_config_sha256", ""),
			"route": _route.duplicate(true)})
	super._record_frame()

func _route_still(label: String) -> void:
	if label == "end":
		OWNER_PROBE.stop()
	await super._route_still(label)

func _write_route_receipt(complete: bool) -> void:
	OWNER_PROBE.stop()
	var diagnostic_complete := complete and OWNER_PROBE.start_process >= 0 \
		and not OWNER_PROBE.rows.is_empty() and not OWNER_PROBE.capacity_reached
	var error := OWNER_PROBE.flush(_output_dir.path_join("slide-attribution.json"), complete, _route_finished_usec)
	if error != OK:
		_failures.append("Cannot flush diagnostic slide-attribution receipt")
		push_error("Cannot flush diagnostic slide-attribution receipt: " + str(error))
	elif not diagnostic_complete:
		_failures.append("Diagnostic slide-attribution measurement is incomplete")
	super._write_route_receipt(complete and diagnostic_complete and error == OK and _failures.is_empty())
