extends SceneTree

const COVER := preload("res://scripts/world/cloudreach_ground_cover.gd")

class CountingBudget extends RefCounted:
	var tree: SceneTree
	var calls := 0
	func _init(owner: SceneTree) -> void:
		tree = owner
	func breathe() -> void:
		calls += 1
		await tree.process_frame

var failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	# More than 2,048 accepted transforms and more than 2,048 candidate attempts
	# exercise both inner release sites, rather than proving only the outer
	# once-per-patch release.
	var patch := {"kind":"ellipse", "centre":Vector3.ZERO, "half":Vector2(42, 36),
		"seed":71, "height_scale":1.0}
	var cfg := {"grass_density_per_m2":1.0, "region_grass_patch_cap":2600,
		"flower_density_per_m2":0.08, "region_flower_patch_cap":20,
		"bush_density_per_m2":0.04, "region_bush_patch_cap":10,
		"cluster_frequency":0.16, "cluster_threshold":-1.0,
		"grass_scale_min":0.3, "grass_scale_max":0.64,
		"flower_scale_min":0.62, "flower_scale_max":1.05,
		"bush_scale_min":0.72, "bush_scale_max":1.18}
	var solo := COVER.new()
	root.add_child(solo)
	await solo.build([patch], cfg, [])
	var solo_counts := [solo.grass_instance_count(), solo.flower_instance_count(), solo.bush_instance_count()]
	_check(solo_counts[0] > 0 and solo_counts[1] > 0 and solo_counts[2] > 0,
		"visible solo build creates all real cover tiers")
	var budget := CountingBudget.new(self)
	var sliced := COVER.new()
	root.add_child(sliced)
	await sliced.build([patch], cfg, [], budget)
	var sliced_counts := [sliced.grass_instance_count(), sliced.flower_instance_count(), sliced.bush_instance_count()]
	_check(sliced_counts == solo_counts, "sliced and solo cover counts are deterministic and equal")
	_check(sliced_counts[0] > 2048, "fixture exercises the MultiMesh upload release boundary")
	_check(budget.calls >= 3, "visible sliced build released outer, candidate, and upload work")
	solo.queue_free()
	sliced.queue_free()
	await process_frame
	await process_frame
	for failure in failures:
		push_error(failure)
	print("CLOUD SLICED GROUND COVER: solo=", solo_counts, " sliced=", sliced_counts,
		" budget_calls=", budget.calls, " failures=", failures.size())
	quit(0 if failures.is_empty() else 1)

func _check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
