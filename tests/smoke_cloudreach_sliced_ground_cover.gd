extends SceneTree

const COVER := preload("res://scripts/world/cloudreach_ground_cover.gd")


class RecordingCover extends COVER:
	var recorded: Dictionary = {}

	func _emit_patch_tier(parent: Node3D, label: String, mesh: ArrayMesh,
			material: ShaderMaterial, transforms: PackedFloat32Array, config: Dictionary,
			build_budget: RefCounted = null) -> int:
		var key: String = "%s/%s" % [parent.name, label]
		var values: Array[Transform3D] = []
		for offset in range(0, transforms.size(), 12):
			values.append(Transform3D(Basis(
				Vector3(transforms[offset], transforms[offset + 4], transforms[offset + 8]),
				Vector3(transforms[offset + 1], transforms[offset + 5], transforms[offset + 9]),
				Vector3(transforms[offset + 2], transforms[offset + 6], transforms[offset + 10])),
				Vector3(transforms[offset + 3], transforms[offset + 7], transforms[offset + 11])))
		recorded[key] = values
		return await super._emit_patch_tier(parent, label, mesh, material, transforms, config,
			build_budget)

class LinearCover extends RecordingCover:
	func _excluded(at: Vector3, local_only: bool = false) -> bool:
		return _excluded_from(at, _active_exclusions if local_only else _exclusions)

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
	var solo := RecordingCover.new()
	root.add_child(solo)
	await solo.build([patch], cfg, [])
	var solo_counts := [solo.grass_instance_count(), solo.flower_instance_count(), solo.bush_instance_count()]
	var solo_fingerprint := _transform_fingerprint(solo.recorded)
	_check(solo_counts[0] > 0 and solo_counts[1] > 0 and solo_counts[2] > 0,
		"visible solo build creates all real cover tiers")
	var budget := CountingBudget.new(self)
	var sliced := RecordingCover.new()
	root.add_child(sliced)
	await sliced.build([patch], cfg, [], budget)
	var sliced_counts := [sliced.grass_instance_count(), sliced.flower_instance_count(), sliced.bush_instance_count()]
	var sliced_fingerprint := _transform_fingerprint(sliced.recorded)
	_check(sliced_counts == solo_counts, "sliced and solo cover counts are deterministic and equal")
	_check(sliced_fingerprint == solo_fingerprint,
		"slicing preserves exact grass, flower, and bush origin/yaw/scale fingerprints")
	_check(sliced_counts[0] > 2048, "fixture exercises the MultiMesh upload release boundary")
	_check(budget.calls >= 3, "visible sliced build released outer, candidate, and upload work")
	# Exercise the new broad phase against the untouched linear predicate using
	# exact Transform3D equality, not rounded fingerprints or count alone.
	var exclusions: Array[Dictionary] = []
	for x in range(-3, 4):
		for z in range(-3, 4):
			exclusions.append({"kind": "ellipse" if (x + z) % 2 == 0 else "rect",
				"centre": Vector3(x * 11, 0, z * 9), "half": Vector2(1.5, 2.5), "rotation": 0.47})
	exclusions.append({"kind": "segment", "a": Vector3(-35, -2, -30),
		"b": Vector3(35, 2, 30), "half_width": 1.25})
	var linear := LinearCover.new()
	root.add_child(linear)
	await linear.build([patch], cfg, exclusions)
	var indexed := RecordingCover.new()
	root.add_child(indexed)
	await indexed.build([patch], cfg, exclusions, budget)
	_check(indexed.recorded == linear.recorded,
		"indexing preserves every unrounded grass/flower/bush origin, yaw and scale")
	_check(indexed.grass_instance_count() > 0 and indexed.flower_instance_count() > 0 \
		and indexed.bush_instance_count() > 0, "equivalence fixture retains all cover tiers")
	linear.queue_free()
	indexed.queue_free()
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


func _transform_fingerprint(recorded: Dictionary) -> Array[String]:
	var result: Array[String] = []
	var keys: Array = recorded.keys()
	keys.sort()
	for raw_key: Variant in keys:
		var key: String = str(raw_key)
		var transforms: Array = recorded[key]
		for raw_xform: Variant in transforms:
			var xform: Transform3D = raw_xform
			result.append("%s|%.5f,%.5f,%.5f|%.5f,%.5f,%.5f" % [key,
				xform.origin.x, xform.origin.y, xform.origin.z, xform.basis.x.x,
				xform.basis.x.z, xform.basis.y.length()])
	return result
