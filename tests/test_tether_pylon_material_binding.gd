extends "res://tests/test_case.gd"

## Native material proof for the production geometry-only pylon. The raw GLB
## remains the negative control; every positive case below executes the actual
## consumer that used to leave those mesh surfaces unbound.

const PYLON := preload("res://assets/environment/team_tether/tether_pylon.glb")
const PYLON_MATERIALS := preload("res://scripts/world/tether_pylon_materials.gd")
const ROD_STATIONS := preload("res://scripts/world/stormwood_rod_stations.gd")
const DYNAMO_ARENA := preload("res://scripts/world/stormwood_dynamo_arena.gd")
const DYNAMO_RULES := preload("res://scripts/world/stormwood_dynamo_rules.gd")
const CAMPS := preload("res://scripts/world/stormwood_camps.gd")
const CLOUDREACH_SUMMIT := preload("res://scripts/world/cloudreach_summit_presentation.gd")
const CLOUDREACH_WORLD := preload("res://scripts/world/cloudreach_world.gd")


class FlatWorld extends Node3D:
	var simulation_only := false
	func ground_height_at(_x: float, _z: float) -> float:
		return 12.0


class Flags extends RefCounted:
	var revision := 0
	var values: Dictionary = {}
	func has(id: String) -> bool:
		return values.has(id)
	func set_flag(id: String) -> void:
		values[id] = true
		revision += 1


class GameFixture extends Node:
	var progression := Flags.new()


func test_raw_geometry_is_unbound_then_shared_finish_binds_without_transform_changes() -> void:
	var raw := PYLON.instantiate() as Node3D
	var raw_meshes := _meshes(raw)
	assert_true(not raw_meshes.is_empty(), "negative control must instantiate real pylon mesh geometry")
	var surface_count := 0
	for instance: MeshInstance3D in raw_meshes:
		assert_eq(instance.material_override, null,
			"the source GLB intentionally has no runtime material override")
		if instance.mesh != null:
			for surface in instance.mesh.get_surface_count():
				surface_count += 1
				var imported := instance.mesh.surface_get_material(surface) as StandardMaterial3D
				assert_true(imported == null or (imported.albedo_texture != PYLON_MATERIALS.LIVE_ALBEDO
					and imported.albedo_texture != PYLON_MATERIALS.DEAD_ALBEDO),
					"the raw geometry must not resolve either installed pylon texture")
	assert_true(surface_count > 0, "negative control must contain actual mesh surfaces")
	var transforms := _transforms(raw)
	assert_eq(PYLON_MATERIALS.apply(raw, true), raw_meshes.size())
	_assert_finish(raw, true)
	_assert_transforms(raw, transforms)
	assert_eq(PYLON_MATERIALS.apply(raw, false), raw_meshes.size())
	_assert_finish(raw, false)
	_assert_transforms(raw, transforms)
	raw.free()


func _case_stormwood_stations_follow_existing_live_disabled_state_without_moving() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var world := FlatWorld.new()
	world.name = "PylonMaterialStationWorld"
	tree.root.add_child(world)
	var runtime := ROD_STATIONS.new()
	runtime.name = "StormwoodRodStations"
	world.add_child(runtime)
	runtime.mount(world)
	var fake_game := GameFixture.new()
	runtime.game = fake_game
	runtime.restore_progression_from_game(fake_game)
	for spec: Dictionary in runtime.stations:
		var station := runtime.get_node_or_null(NodePath(str(spec.id))) as Node3D
		assert_true(station != null, str(spec.id) + " must instantiate its production station")
		if station == null:
			continue
		var model := _pylon_child(station)
		assert_true(model != null, str(spec.id) + " must contain actual pylon geometry")
		if model == null:
			continue
		_assert_finish(model, true)
		var authored_transform := station.transform
		var model_transforms := _transforms(model)
		var prompt: Node = station.get_node_or_null(^"RodSwitch")
		assert_true(bool(prompt.get("enabled")), str(spec.id) + " keeps its live switch enabled")
		fake_game.progression.set_flag(str(spec.disabled_flag))
		runtime.restore_progression_from_game(fake_game)
		_assert_finish(model, false)
		assert_eq(station.transform, authored_transform, str(spec.id) + " state change must not move the station")
		_assert_transforms(model, model_transforms)
		assert_false(bool(prompt.get("enabled")), str(spec.id) + " keeps its established disabled switch state")
		var lights := station.find_children("*", "OmniLight3D", true, false)
		var light := lights[0] as OmniLight3D if not lights.is_empty() else null
		assert_true(light != null)
		if light != null:
			assert_almost_eq(light.light_energy, 0.3, 0.0001,
				str(spec.id) + " keeps its established disabled light energy")
	world.free()
	fake_game.free()


func test_stormwood_stations_follow_existing_live_disabled_state_without_moving() -> void:
	# The unit runner invokes tests during SceneTree._init(), before its root is
	# available. Run this one tree-dependent consumer case in an initialized
	# native child process so mount() can resolve the real /root/Game autoload.
	var path := "user://pylon-material-stations-child.gd"
	var file := FileAccess.open(path, FileAccess.WRITE)
	assert_true(file != null)
	if file == null:
		return
	file.store_string('extends SceneTree\nfunc _initialize():\n\tcall_deferred("run")\nfunc run():\n\tvar test = load("res://tests/test_tether_pylon_material_binding.gd").new()\n\ttest._case_stormwood_stations_follow_existing_live_disabled_state_without_moving()\n\tprint("PYLON_STATIONS_RESULT=" + JSON.stringify({"assertions":test.assertion_count,"failures":test.failures}))\n\tquit(0 if test.failures.is_empty() and test.assertion_count > 60 else 1)\n')
	file.close()
	var output: Array = []
	var absolute := ProjectSettings.globalize_path(path)
	var code := OS.execute(OS.get_executable_path(), ["--headless", "--path",
		ProjectSettings.globalize_path("res://"), "--script", absolute, "--log-file",
		ProjectSettings.globalize_path("user://pylon-material-stations-child.log")], output, true)
	DirAccess.remove_absolute(absolute)
	var combined := "\n".join(output)
	assert_eq(code, 0, combined)
	assert_false(combined.contains("SCRIPT ERROR") or combined.contains("ERROR:"), combined)
	var result: Dictionary = {}
	for line: String in combined.split("\n"):
		if line.begins_with("PYLON_STATIONS_RESULT="):
			result = JSON.parse_string(line.trim_prefix("PYLON_STATIONS_RESULT="))
	assert_true(int(result.get("assertions", 0)) > 60,
		"all four real station geometries and both material states must run")
	assert_eq(result.get("failures", ["missing result"]), [])


func test_stormwood_dynamo_and_camp_consumers_bind_their_intended_finish() -> void:
	var rules := DYNAMO_RULES.new()
	var arena := DYNAMO_ARENA.new()
	arena.build(rules, false)
	assert_eq(arena._banks.size(), int(rules.config.bank_count))
	for row: Dictionary in arena._banks:
		var model := _pylon_child(row.node)
		assert_true(model != null, "each real Dynamo bank must contain pylon geometry")
		if model != null:
			_assert_finish(model, true)
	var first_model := _pylon_child(arena._banks[0].node)
	var first_transform := first_model.transform
	arena.show_state({"bank": 0, "state": "fire", "charge": 1.0})
	assert_eq(first_model.transform, first_transform, "Dynamo firing state must not move its pylon")
	_assert_finish(first_model, true)
	assert_true(bool(arena._banks[0].lane.visible), "existing active discharge lane remains visible")
	assert_almost_eq(float(arena._banks[0].light.light_energy), 3.0, 0.0001,
		"existing firing light state is preserved")
	arena.free()

	var adapter := CAMPS.new()
	var dressing_root := Node3D.new()
	var world := FlatWorld.new()
	for camp: Dictionary in CAMPS.load_config().get("camps", []):
		adapter._build_dressing(dressing_root, camp, world)
		var dressing := dressing_root.get_node_or_null(NodePath(str(camp.id) + "Dressing")) as Node3D
		var rod := dressing.get_node_or_null(^"lightning_rod") as Node3D if dressing != null else null
		assert_true(rod != null, str(camp.id) + " must instantiate its real camp rod")
		if rod == null:
			continue
		_assert_finish(rod, false)
		var rod_spec := _prop(camp, "lightning_rod")
		var at: Array = camp.at
		var offset: Array = rod_spec.offset
		assert_eq(rod.position, Vector3(float(at[0]) + float(offset[0]), 12.0,
			float(at[1]) + float(offset[1])), str(camp.id) + " keeps its authored placement")
		assert_eq(rod.scale, Vector3.ONE * 0.55, str(camp.id) + " keeps its authored scale")
		assert_almost_eq(rod.rotation.y, deg_to_rad(float(rod_spec.get("yaw_deg", 0.0))), 0.0001,
			str(camp.id) + " keeps its authored yaw")
	dressing_root.free()
	world.free()
	adapter.free()


func test_cloudreach_world_and_summit_consumers_bind_live_finish_without_refitting() -> void:
	var cloud_world := CLOUDREACH_WORLD.new()
	var direct := cloud_world._tether_pylon() as Node3D
	_assert_finish(direct, true)
	_assert_default_transforms(direct)
	direct.free()
	cloud_world.free()

	var presentation := CLOUDREACH_SUMMIT.new()
	var parent := Node3D.new()
	var at := Vector3(7.0, 0.15, -11.0)
	var yaw := 0.37
	presentation._install(PYLON, parent, at, 7.2, yaw)
	assert_eq(parent.get_child_count(), 1, "summit installer keeps one fitted anchor")
	var anchor := parent.get_child(0) as Node3D
	var model := anchor.get_child(0) as Node3D
	_assert_finish(model, true)
	assert_eq(anchor.position, at, "summit pylon keeps its authored placement")
	assert_almost_eq(anchor.rotation.y, yaw, 0.0001, "summit pylon keeps its authored yaw")
	assert_almost_eq(model.scale.x, model.scale.y, 0.0001, "summit fit remains uniform")
	assert_almost_eq(model.scale.y, model.scale.z, 0.0001, "summit fit remains uniform")
	assert_true(model.scale.y > 0.0, "summit installer still fits the real geometry")
	parent.free()
	presentation.free()


func _meshes(root: Node) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	if root is MeshInstance3D:
		result.append(root as MeshInstance3D)
	for child: Node in root.get_children():
		result.append_array(_meshes(child))
	return result


func _pylon_child(root: Node) -> Node3D:
	for child: Node in root.get_children():
		if child is Node3D and not _meshes(child).is_empty():
			return child as Node3D
	return null


func _assert_finish(root: Node, lit: bool) -> void:
	var expected := PYLON_MATERIALS.LIVE_ALBEDO if lit else PYLON_MATERIALS.DEAD_ALBEDO
	var meshes := _meshes(root)
	assert_true(not meshes.is_empty(), "finish assertion must inspect actual mesh geometry")
	for instance: MeshInstance3D in meshes:
		var material := instance.material_override as StandardMaterial3D
		assert_true(material != null, "%s pylon mesh must have a StandardMaterial3D override" % (
			"live" if lit else "dead"))
		if material == null:
			continue
		assert_eq(material.albedo_texture, expected, "pylon must resolve the installed state texture")
		assert_almost_eq(material.roughness, 0.82, 0.0001)
		assert_almost_eq(material.metallic, 0.0, 0.0001)
		assert_false(material.emission_enabled, "Compatibility finish must not emit the whole object")


func _transforms(root: Node) -> Dictionary:
	var result: Dictionary = {}
	if root is Node3D:
		result[root] = (root as Node3D).transform
	for child: Node in root.get_children():
		result.merge(_transforms(child))
	return result


func _assert_transforms(root: Node, expected: Dictionary) -> void:
	var actual := _transforms(root)
	assert_eq(actual.size(), expected.size(), "material binding must keep the geometry hierarchy")
	for node: Node in expected:
		assert_eq(actual.get(node), expected[node], "material binding must not alter %s" % node.name)


func _assert_default_transforms(root: Node) -> void:
	for node: Node in _transforms(root):
		assert_eq((node as Node3D).transform, Transform3D.IDENTITY,
			"fresh Cloudreach pylon helper must return the GLB's original transforms")


func _prop(camp: Dictionary, id: String) -> Dictionary:
	for prop: Dictionary in camp.get("props", []):
		if str(prop.get("model", "")) == id:
			return prop
	return {}
