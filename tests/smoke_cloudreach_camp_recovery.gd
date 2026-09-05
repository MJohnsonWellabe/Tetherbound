extends "res://tests/smoke_cloudreach_continuous.gd"

## Bounded production-scene fixture for the Cloudreach camp contract. It uses
## real camp/bed prompts and controller actions, then proves the shared night
## rest heals only the physically bedded KO member. The second member is left
## unbedded at partial HP to pin the canonical preparation trade-off.

func _run() -> void:
	Engine.time_scale = 4.0
	Engine.physics_ticks_per_second = 240
	Engine.max_physics_steps_per_frame = 32
	game = root.get_node("Game")
	game.reset_for_new_game()
	game.save_system = SAVE.new("user://cloudreach_camp_recovery_fixture")
	game.current_realm = "cloudreach"
	for flag: String in ["realm_key_cloudreach", "cloudreach_chapter_started", "causeway_survivors_reconnected",
			"windscar_aerie_prepared", "cloudreach_upper_route_unlocked", "cloudreach_upper_anchors_disabled"]:
		game.progression.set_flag(flag)
	for species: String in ["sparkit", "mudsnout"]:
		game.party.add(SPECIES.spawn(species))
	world = SCENE.instantiate()
	root.add_child(world)
	current_scene = world
	player = world.get_node("Player")
	chapter = world.get_node("CloudreachChapter")
	physical = chapter.physical_runtime()
	runtime = world.get_node("CloudreachRuntime")
	manager = runtime.manager
	director = runtime.director
	fly = player.fly_controller
	world.get_node("InteractionArbiter").activated.connect(func(provider: Object) -> void:
		interaction_activations += 1
		last_activated_path = str(provider.get_path()))
	await _frames(30)
	for id: String in ["galefoot_waycamp", "west_causeway_refuge", "windscar_flight_aerie_camp", "cliffhold_commons", "summit_bivouac"]:
		var authored_camp := physical.get_node_or_null(id) as Node3D
		_require(authored_camp != null, "Authored camp stood up: " + id)
		if authored_camp == null: continue
		var authored_bed := authored_camp.get_node_or_null("CampCreatureBed") as Node3D
		_require(authored_bed != null, "Recovery bed stood up: " + id)
		if authored_bed != null:
			_require(authored_camp.global_position.distance_to(authored_bed.global_position) > 2.0,
				"Recovery bed is offset from player rest centre: " + id)
			_require(_has_floor(authored_camp), "Actual floor under camp: " + id)
			if authored_bed != null:
				_require(_has_floor(authored_bed), "Actual floor under creature bed: " + id)

	var camp := physical.get_node("galefoot_waycamp") as Node3D
	var creature_bed := camp.get_node("CampCreatureBed") as Node3D
	var bed_prompt := creature_bed.get_node_or_null("Interactable") as Node3D if creature_bed != null else null
	var rest_prompt := camp.get_node_or_null("Interactable") as Node3D if camp != null else null
	if not _require(creature_bed != null and bed_prompt != null, "Galefoot builds its authored creature bed"): return _finish_recovery()
	_require(rest_prompt != null and camp.get_node_or_null("CraftInteractable") != null,
		"Galefoot keeps player rest and craft prompts alongside recovery")
	var decorative_bed := _find_decorative_trainer_bed(camp, creature_bed)
	_require(decorative_bed != null, "Cloudreach keeps the installed decorative trainer bed")
	if decorative_bed != null:
		_require(decorative_bed.global_position.distance_to(creature_bed.global_position) > 2.0,
			"Decorative trainer bed does not overlap the creature bed")
	_require(creature_bed.global_position.distance_to(camp.global_position) > 2.0,
		"Authored creature bed is offset from the player rest/dressing centre")
	if failed: return _finish_recovery()

	# A real world-floor ray is part of this fixture: a bed coordinate that only
	# exists in JSON but resolves to air must fail the same way as any physical
	# chapter placement.
	_require(_has_floor(camp), "Actual floor under galefoot_waycamp")
	_require(_has_floor(creature_bed), "Actual floor under CampCreatureBed")
	if failed: return _finish_recovery()

	var bedded: RefCounted = game.party.at(0)
	var unbedded: RefCounted = game.party.at(1)
	bedded.set("hp", 0.0)
	bedded.set("fainted", true)
	var unbedded_hp := float(unbedded.get("max_hp")) * 0.5
	unbedded.set("hp", unbedded_hp)
	unbedded.set("fainted", false)

	# The player-position placement is fixture setup only. Assignment and sleep
	# are ordinary controller input against the production interaction arbiter.
	player.global_position = bed_prompt.global_position + Vector3(0.0, -0.2, 0.0)
	player.velocity = Vector3.ZERO
	await _frames(30)
	if not await _interact(bed_prompt, "", false): return _finish_recovery()
	await _tap("ui_accept")
	await _frames(8)
	_require(bool(bedded.get("resting")), "Controller bed input assigns the KO creature")
	_require(int(bedded.get("rest_bed_index")) == int(creature_bed.call("build_index")),
		"KO creature stores the authored Cloudreach bed index")
	await _tap("menu_cancel")
	await _frames(8)
	if failed: return _finish_recovery()

	var day_before := int(game.day)
	if not await _walk(rest_prompt.global_position + Vector3(0.0, -0.2, 0.8), 1.0): return _finish_recovery()
	if not await _interact(rest_prompt, "", false): return _finish_recovery()
	await _frames(140)
	_require(int(game.day) == day_before + 1, "Ordinary camp input passes one night")
	_require(float(bedded.get("hp")) >= float(bedded.get("max_hp")) - 0.01 and not bool(bedded.get("fainted")),
		"Physically bedded KO creature recovers and revives overnight")
	_require(not bool(bedded.get("resting")) and int(bedded.get("rest_bed_index")) == -1,
		"Completed camp rest clears the bed assignment")
	_require(absf(float(unbedded.get("hp")) - unbedded_hp) < 0.01 and not bool(unbedded.get("fainted")),
		"Unbedded creature keeps its canonical pre-sleep HP")
	_finish_recovery()


func _find_decorative_trainer_bed(camp: Node3D, creature_bed: Node3D) -> Node3D:
	for child: Node in camp.get_children():
		if child is Node3D and child != creature_bed and str(child.name) not in ["Interactable", "CraftInteractable"]:
			var path := str(child.get_path())
			if path.contains("Bed_Twin1") or str(child.name).contains("Bed_Twin1"):
				return child as Node3D
	# Imported glTF roots are allowed to rename themselves on instantiation;
	# there is only one other direct Node3D child in this authored rest point,
	# so retain the placement check even when the asset's root name changes.
	for child: Node in camp.get_children():
		if child is Node3D and child != creature_bed and str(child.name) not in ["Interactable", "CraftInteractable"]:
			return child as Node3D
	return null


func _has_floor(spot: Node3D) -> bool:
	var ray := PhysicsRayQueryParameters3D.create(spot.global_position + Vector3.UP * 3.0,
		spot.global_position - Vector3.UP * 3.0, 1, [player.get_rid()])
	var hit := player.get_world_3d().direct_space_state.intersect_ray(ray)
	return not hit.is_empty() and absf((hit.position as Vector3).y - spot.global_position.y) < 0.6


func _finish_recovery() -> void:
	_release()
	print("CLOUDREACH CAMP RECOVERY %s" % ("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)
