extends SceneTree

const MODEL := preload("res://tools/gate_f/road_creature_visibility_model.gd")


func _init() -> void:
	var result: Dictionary = MODEL.evaluate_all()
	var criterion: Dictionary = result["criterion"]
	print("ROAD VISIBILITY: %.0fm samples, 1m=%.0fpx@%.0fm (%.0fpx minimum), %.0fp/%.0fdeg, forward %.0fdeg, need %d" % [
		criterion["sample_step_m"], criterion["minimum_projected_height_px"],
		criterion["reference_distance_m"], criterion["minimum_projected_height_px"],
		criterion["viewport_height_px"], criterion["vertical_fov_deg"],
		criterion["forward_cone_deg"], criterion["required_visible"],
	])
	for realm_id: String in ["meadows", "cloudreach", "stormwood", "water"]:
		print("[%s]" % realm_id)
		for route: Dictionary in result[realm_id]:
			print("  %s samples=%d min=%d failing=%d longest=%.0fm" % [
				route["id"], route["samples"], route["minimum_visible"],
				route["failing_samples"], route["longest_failing_run_m"],
			])
			if int(route["failing_samples"]) > 0:
				print("    first failures: %s" % str((route["failing_positions"] as Array).slice(0, 8)))
	quit(0 if MODEL.all_routes_pass(result) else 1)
