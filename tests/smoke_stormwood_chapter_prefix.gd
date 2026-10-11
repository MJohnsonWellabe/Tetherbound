extends SceneTree

const GAME := preload("res://autoload/game_state.gd")
const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const TEST_SAVE_DIR := "user://stormwood_chapter_prefix_smoke_0907"
const FRAMES := 3600
var failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var game: Node = root.get_node_or_null(^"Game")
	if game == null:
		game = GAME.new(); game.name = "Game"; root.add_child(game)
	await physics_frame
	game.reset_for_new_game()
	game.save_system = SAVE_GAME.new(TEST_SAVE_DIR)
	_commit(game, "realm_key_stormwood") # Existing story prerequisite retained; not portal admission.
	_expect(game.progression.has("realm_key_stormwood"), "chapter story prerequisite fixture did not commit")
	if not failures.is_empty(): _finish(); return
	# DISCLOSED prerequisite fixture, not earned portal/key/ledger proof (RD-17).
	# The production gate reads canonical redesign unlocks; the legacy flag no longer admits.
	_expect(not game.can_enter_realm("stormwood"), "fresh character unexpectedly admits Stormwood")
	if not failures.is_empty(): _finish(); return
	game.local.redesign_character.portal_unlocks.append("stormwood")
	_expect(game.can_enter_realm("stormwood"), "canonical fixture unlock did not admit Stormwood")
	if not failures.is_empty(): _finish(); return
	var source := Node3D.new(); root.add_child(source); current_scene = source
	_expect(await game.enter_realm("stormwood", "stormwood_arrival_from_cloudreach"), "router refused Stormwood arrival")
	var world := await _scene("Stormwood")
	_expect(world != null, "Stormwood did not mount")
	if world == null: _finish(); return
	var chapter: Node = null
	var people: Node = null
	var dynamo: Node3D = null
	var ending: Node3D = null
	for i in FRAMES:
		chapter = world.get_node_or_null(^"StormwoodChapter")
		people = world.get_node_or_null(^"StormwoodPeople")
		dynamo = world.get_node_or_null(^"StormwoodDynamo")
		ending = world.get_node_or_null(^"StormwoodEnding")
		if chapter != null and people != null and dynamo != null and ending != null: break
		await physics_frame
	var player := world.get_node_or_null(^"Player") as CharacterBody3D
	var hesk := people.get_node_or_null(^"Rodkeeper Hesk") as Node3D if people != null else null
	_expect(chapter != null and hesk != null and player != null and dynamo != null and ending != null,
		"chapter, Hesk, player, Dynamo, or ending controller missing")
	if chapter == null or hesk == null or player == null or dynamo == null or ending == null: _finish(); return
	await _check_mounted_rain_roofs(world)
	var arena := dynamo.get_node_or_null(^"DynamoArena")
	_expect(arena != null, "mounted Dynamo controller has no authored arena")
	if arena != null:
		_expect(arena.get_node_or_null(^"CapacitorBank0") != null and
			arena.get_node_or_null(^"CapacitorBank1") != null and
			arena.get_node_or_null(^"CapacitorBank2") != null and
			arena.get_node_or_null(^"CapacitorBank3") != null,
			"Dynamo arena must mount all four capacitor banks")
		_expect(arena.get_node_or_null(^"GroundedRodPlate0") != null and
			arena.get_node_or_null(^"GroundedRodPlate1") != null and
			arena.get_node_or_null(^"GroundedRodPlate2") != null,
			"Dynamo arena must mount all three grounded safe plates")
	_expect(ending.get_node_or_null(^"CaptiveStormheart") != null and
		ending.get_node_or_null(^"StormheartContainment") != null and
		ending.get_node_or_null(^"StormheartOffer") != null and
		ending.get_node_or_null(^"WaterwardView") != null,
		"ending must mount the captive, containment, offer and high-platform view")
	_expect(world.get_node_or_null(^"SparkOfStormwoodShrine") == null and
		world.get_node_or_null(^"DistantWaterwardSea") != null,
		"Stormwood must keep its Waterward horizon but leave relic placement to the Meadows circle")
	# Test transport places the arrival at authored Ashfoot; progression remains
	# owned by the chapter's real proximity check and the NPC's interaction path.
	player.global_position = hesk.global_position + Vector3(0, 0, 1.2)
	for i in 90: await physics_frame
	_expect(game.progression.has("stormwood:chapter_started"), "Ashfoot arrival did not set chapter_started")
	var prompt := hesk.get_node_or_null(^"Interactable") as Node3D
	var arbiter := get_first_node_in_group(&"interaction_arbiter")
	_expect(prompt != null and arbiter != null, "Hesk has no live interaction prompt/arbiter")
	if prompt == null or arbiter == null: _finish(); return
	var won := false
	for i in 180:
		if arbiter.call("winning_provider") == prompt: won = true; break
		await physics_frame
	if not won:
		_print_interaction_diagnostic(arbiter, player, hesk, prompt)
	_expect(won, "Hesk prompt never won the live interaction arbiter")
	if won:
		await _press_interact()
	var panel := world.get_node_or_null(^"DialoguePanel")
	var opened := false
	for i in 90:
		if panel != null and panel.call("is_open"): opened = true; break
		await physics_frame
	_expect(opened, "Hesk prompt did not open dialogue")
	if opened:
		for i in 40:
			if not panel.call("is_open"): break
			await _press_interact()
	_expect(panel == null or not panel.call("is_open"), "Hesk dialogue did not finish through interact")
	for i in 30: await physics_frame
	_expect(game.progression.has("stormwood:crisis_learned"), "completed Hesk dialogue did not set crisis_learned")
	var hud := world.get_node_or_null(^"PlaygroundHUD")
	var objective_label := hud.get("_objective_text_label") as Label if hud != null else null
	_expect(objective_label != null, "PlaygroundHUD has no tracked objective label")
	if objective_label != null:
		_expect(objective_label.text == "Read a Break with Tamsin.",
			"PlaygroundHUD did not advance to Tamsin's Break objective (got '%s')" % objective_label.text)
	_finish()

# Check the REAL routed/mounted Stormwood scene, including the live Dynamo
# infill. No new tree-only scene or synthetic deck substitutes for topology.
func _check_mounted_rain_roofs(world: Node) -> void:
	var tree := world.get_node_or_null("StormheartTree") as Node3D
	var surge := world.get_node_or_null("StormwoodSurge")
	var infill := world.get_node_or_null("StormwoodDynamo/DeckInfill")
	_expect(tree != null and surge != null and infill != null, "rain proof requires actual mounted tree/Surge/Dynamo infill")
	if tree == null or surge == null or infill == null:
		return
	for _frame in 3:
		await physics_frame
	var cover: Dictionary = surge.mounted_deck_rain_cover(world)
	_expect(cover.bounds.size() == 6, "three deck rings plus two infill bands must retain six exact polygon arcs")
	_expect(cover.sources.count("StormwoodDynamo/DeckInfill") == 2, "rain topology omitted the actual mounted infill")
	var physical_extent := Vector2(0.0, -INF)
	var checked_sources: Array[String] = []
	for path: String in cover.sources:
		if checked_sources.has(path):
			continue
		checked_sources.append(path)
		var body := world.get_node(path)
		for child: Node in body.get_children():
			if child is CollisionShape3D and child.shape is ConcavePolygonShape3D:
				var pose: Transform3D = tree.global_transform.affine_inverse() * child.global_transform
				for vertex: Vector3 in (child.shape as ConcavePolygonShape3D).get_faces():
					var point: Vector3 = pose * vertex
					physical_extent.x = maxf(physical_extent.x, Vector2(point.x, point.z).length_squared())
					physical_extent.y = maxf(physical_extent.y, point.y)
	_expect(cover.extent == physical_extent, "fast rejection envelope is not actual mounted roof bounds")
	# radius, height in tree coordinates, sector centre, actual roof body name.
	# The important prior-review counterexample is35m/sector45.5 -> DeckInfill.
	var samples := [
		[35.0, 8.0, 48.5, "DynamoCore"],
		[26.0, 62.0, 17.28, "HollowTrunkAscent"],
		[35.0, 149.0, 45.5, "DeckInfill"],
		[15.0, 149.0, 45.5, "DeckInfill"],
		[26.0, 149.0, 45.5, ""],
		[50.0, 149.0, 16.5, ""],
		[5.0, 149.0, 16.5, ""],
		[12.0, 160.0, 16.5, "CrownChamber"],
		[25.0, 151.0, 16.5, ""],
		[12.0, 175.0, 16.5, ""]]
	var checks := 0
	for sample: Array in samples:
		var angle := float(sample[2]) * TAU / 64.0
		var local := Vector3(cos(angle) * float(sample[0]), float(sample[1]), sin(angle) * float(sample[0]))
		var at := tree.to_global(local)
		var query := PhysicsRayQueryParameters3D.create(at, tree.to_global(Vector3(local.x, 210.0, local.z)), 1)
		query.hit_back_faces = true
		var hit := tree.get_world_3d().direct_space_state.intersect_ray(query)
		var actual := str((hit.collider as Node).name) if not hit.is_empty() else ""
		_expect(actual == str(sample[3]), "mounted roof sample %s expected %s got %s" % [sample, sample[3], actual])
		for emitter: GPUParticles3D in [surge._rain, surge._rain_far, surge._rain_curtain]:
			var material := (emitter.draw_pass_1 as CylinderMesh).material as ShaderMaterial
			_expect(material.get_shader_parameter("roof_extent") == physical_extent,
				"%s does not bind measured squared-radius/height fast rejection" % emitter.name)
			_expect(not _rain_material_covers(material, tree.to_global(Vector3(sqrt(physical_extent.x) + 2.0, physical_extent.y - 1.0, 0.0))),
				"%s suppresses outdoor rain beyond actual roofs" % emitter.name)
			_expect(not _rain_material_covers(material, tree.to_global(Vector3(0.0, physical_extent.y + 1.0, 0.0))),
				"%s suppresses rain above actual roofs" % emitter.name)
			_expect(material.get_shader_parameter("roof_count") == cover.bounds.size(), "%s does not bind all mounted roof arcs" % emitter.name)
			_expect(material.get_shader_parameter("roof_bounds") == cover.bounds and material.get_shader_parameter("roof_arcs") == cover.arcs,
				"%s roof footprint is not the actual mounted collision topology" % emitter.name)
			var masked := _rain_material_covers(material, at)
			_expect(masked == (not hit.is_empty()), "%s rain mask disagrees with actual physics sample %s" % [emitter.name, sample])
			checks += 1
	print("STORMWOOD MOUNTED RAIN ROOFS: sources=%s samples=%d emitter_checks=%d includes_live_Dynamo_infill=true" % [cover.sources, samples.size(), checks])

# Read back the production material parameters; real physics above is the
# independent oracle. This is not a visual/shader-render correctness claim.
func _rain_material_covers(material: ShaderMaterial, at: Vector3) -> bool:
	var inverse: Transform3D = material.get_shader_parameter("world_to_roofs")
	var local := inverse * at
	var extent: Vector2 = material.get_shader_parameter("roof_extent")
	if Vector2(local.x, local.z).length_squared() > extent.x or local.y >= extent.y:
		return false
	var bounds: PackedVector4Array = material.get_shader_parameter("roof_bounds")
	var arcs: PackedVector4Array = material.get_shader_parameter("roof_arcs")
	var angle := fposmod(atan2(local.z, local.x), TAU)
	var radius := Vector2(local.x, local.z).length()
	for k in bounds.size():
		var arc := arcs[k]
		var band := bounds[k]
		if angle < arc.x or angle >= arc.y or local.y >= band.z:
			continue
		var middle: float = arc.x + (floor((angle - arc.x) / arc.z) + 0.5) * arc.z
		var scale := cos(arc.z * 0.5) / cos(angle - middle)
		if radius > band.x * scale and radius < band.y * scale:
			return true
	return false

func _commit(game: Node, id: String) -> void:
	game.ledger.submit({"kind":"set_world_flag", "realm":"cloudreach", "id":id, "value":true})

func _scene(name: String) -> Node:
	for i in FRAMES:
		if current_scene != null and current_scene.name == name: return current_scene
		await physics_frame
	return null

func _press_interact() -> void:
	Input.action_press(&"interact")
	await physics_frame
	await physics_frame
	Input.action_release(&"interact")
	await physics_frame

func _print_interaction_diagnostic(arbiter: Node, player: CharacterBody3D, hesk: Node3D, prompt: Node3D) -> void:
	var winner := arbiter.call("winning_provider") as Node
	print("STORMWOOD HESK DIAG player=%s hesk=%s prompt=%s winner=%s arbiter_enabled=%s input_owner=%s" % [
		player.global_position, hesk.global_position, prompt.global_position,
		_node_identity(winner), arbiter.get("_enabled"), _node_identity(get_first_node_in_group(&"input_owner"))])
	var direct_offer: Dictionary = prompt.call("interaction_offer", player.global_position)
	var los: Variant = prompt.call("_has_line_of_sight", player.global_position) if prompt.has_method("_has_line_of_sight") else "not_callable"
	print("STORMWOOD HESK DIAG enabled=%s actionable=%s radius=%s direct_offer=%s los=%s" % [
		prompt.get("enabled"), prompt.get("actionable"), prompt.get("radius"), direct_offer, los])
	var providers: Dictionary = arbiter.get("_provider_set") as Dictionary
	for provider: Variant in providers:
		var node := provider as Node3D
		if node == null or not is_instance_valid(node) or player.global_position.distance_to(node.global_position) > 6.0:
			continue
		var offer: Dictionary = provider.call("interaction_offer", player.global_position)
		print("STORMWOOD HESK DIAG nearby provider=%s distance=%.2f offer=%s" % [
			_node_identity(node), player.global_position.distance_to(node.global_position), offer])

func _node_identity(node: Node) -> String:
	if node == null or not is_instance_valid(node):
		return "<none>"
	return "%s (%s)" % [node.get_path(), node.name]

func _expect(ok: bool, text: String) -> void:
	if not ok: failures.append(text)

func _finish() -> void:
	if failures.is_empty(): print("STORMWOOD CHAPTER PREFIX OK: Ashfoot -> Hesk -> Tamsin objective"); quit(0)
	else:
		for failure in failures: push_error("STORMWOOD CHAPTER PREFIX: " + failure)
		quit(1)
