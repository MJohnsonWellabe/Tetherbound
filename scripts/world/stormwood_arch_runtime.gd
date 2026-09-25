extends Node3D

const RULES := preload("res://scripts/world/stormwood_arch_rules.gd")
const BUILT := preload("res://scripts/world/stormwood_arch_build_rules.gd")
const PIECE := preload("res://scripts/build/stormwood_arch_piece.gd")
const CAPACITOR_GROVE := preload("res://scripts/world/stormwood_capacitor_grove.gd")
const INTERACTABLE := preload("res://scripts/world/interactable.gd")
const CLAIM := preload("res://scripts/world/ledger_claim.gd")
var world: Node3D
var game: Node
var session: Node
var _arches: Dictionary = {}
var _revision := -1
var _world_revision := -1
var _pending_id := ""
var _arrival_until: Dictionary = {}
var _footing_prompts: Dictionary = {}
## Road choices this peer has submitted but not yet seen committed, so a client
## waiting on the host cannot offer a third footing in the meantime.
var _pending_choices: Array[String] = []
const ROAD_REVEALED := "stormwood:arch_recipe_known"
const ROAD_STEP_1 := "stormwood:side_raise_a_road_1"
const ROAD_STEP_2 := "stormwood:side_raise_a_road_2"

func mount(owner_world: Node3D) -> void:
	world = owner_world
	game = get_node("/root/Game")
	session = get_node("/root/Game/Session")
	add_to_group("stormwood_arch_runtime")
	add_to_group("progression_restore")
	session.stormwood_arch_arrival.connect(_arrive)
	game.get("ledger").intent_refused.connect(func(kind: String, _code: String, _reason: String, _detail: Dictionary) -> void:
		if kind == "stormwood_relight_arch": _pending_id = "")
	for arch: Dictionary in RULES.config().arches:
		_build(arch)
	_build_footings()
	restore_progression_from_game(game)

func _build_footings() -> void:
	for socket: Dictionary in RULES.config().footings:
		var footing := StaticBody3D.new()
		footing.name = "Footing_%s" % str(socket.id)
		add_child(footing)
		footing.position = Vector3(float(socket.at[0]), world.ground_height_at(float(socket.at[0]), float(socket.at[1])), float(socket.at[1]))
		var collision := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(9, 0.3, 9)
		collision.shape = box
		footing.add_child(collision)
		if bool(world.get("simulation_only")): continue
		var stone := (load("res://assets/environment/stylized_nature/RockPath_Round_Wide.gltf") as PackedScene).instantiate() as Node3D
		var bounds := preload("res://scripts/characters/render_bounds.gd").measure(stone)
		var factor := 9.0 / maxf(0.1, maxf(bounds.size.x, bounds.size.z))
		stone.scale = Vector3(factor, 0.3 / maxf(0.1, bounds.size.y), factor)
		stone.position.y = -bounds.position.y * stone.scale.y
		footing.add_child(stone)
		var prompt := INTERACTABLE.new()
		prompt.position = Vector3(0, 0.8, -5)
		footing.add_child(prompt)
		prompt.configure("Inspect the shattered Crown footing" if str(socket.id) == "still_grove" else "Inspect the old arch footing", 2.5, true)
		prompt.activated.connect(_inspect_footing.bind(str(socket.id)))
		_footing_prompts[str(socket.id)] = prompt
		if str(socket.id) == "capacitor_grove":
			var grove := CAPACITOR_GROVE.new()
			grove.name = "CapacitorGrovePresentation"
			footing.add_child(grove)
			grove.call("build", world, bool(world.get("simulation_only")))

func _build(spec: Dictionary) -> void:
	var arch := Node3D.new()
	arch.name = str(spec.id)
	add_child(arch)
	arch.position = Vector3(float(spec.at[0]), world.ground_height_at(float(spec.at[0]), float(spec.at[1])), float(spec.at[1]))
	arch.rotation.y = deg_to_rad(float(spec.yaw_deg))
	var row := {"spec": spec, "node": arch}
	_arches[str(spec.id)] = row
	if bool(spec.get("constructed", false)):
		if bool(world.get("simulation_only")):
			var piece := PIECE.new()
			arch.add_child(piece)
			piece.build_real()
			piece.visible = false
		else:
			_mount_passage(arch, str(spec.id))
		return
	var footing := StaticBody3D.new()
	footing.name = "Footing"
	arch.add_child(footing)
	var footing_shape := CollisionShape3D.new()
	var footing_box := BoxShape3D.new()
	footing_box.size = Vector3(9, 0.4, 9)
	footing_shape.shape = footing_box
	footing.add_child(footing_shape)
	if bool(world.get("simulation_only")):
		return
	var slab := MeshInstance3D.new()
	var slab_mesh := BoxMesh.new()
	slab_mesh.size = footing_box.size
	slab.mesh = slab_mesh
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color("343a42")
	slab.material_override = stone
	footing.add_child(slab)
	var piece := PIECE.new()
	piece.name = "ArchPresentation"
	arch.add_child(piece)
	piece.build_display()
	row["piece"] = piece
	var prompt := INTERACTABLE.new()
	prompt.name = "Relight"
	prompt.position = Vector3(0, 1, -1.5)
	arch.add_child(prompt)
	prompt.configure("Relight %s · 3 Stormglass" % spec.name, 3.2, true)
	prompt.activated.connect(_relight.bind(str(spec.id)))
	row["prompt"] = prompt
	_mount_passage(arch, str(spec.id))

func _mount_passage(arch: Node3D, id: String) -> void:
	var passage := Area3D.new()
	passage.name = "Passage"
	passage.collision_layer = 0
	passage.collision_mask = 1
	arch.add_child(passage)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.5, 3.5, 0.8)
	collision.shape = shape
	collision.position.y = 1.75
	passage.add_child(collision)
	passage.body_entered.connect(func(body: Node3D) -> void:
		if body == world.get_node("Player") and not _twin(id).is_empty():
			session.request_stormwood_arch_travel(id))

func _twin(id: String) -> Dictionary:
	return BUILT.linked_twin(id, game.get("progression"), game.get("placed_buildings"))

func _sync_buildings() -> void:
	var buildings: Array = game.get("placed_buildings")
	for id: String in _arches.keys():
		if bool(_arches[id].spec.get("constructed", false)) and BUILT.definition(id, buildings).is_empty():
			_arches[id].node.queue_free()
			_arches.erase(id)
	for record: Dictionary in BUILT.records(buildings):
		var id := str(record.uid)
		var spec := BUILT.definition(id, buildings)
		if not _arches.has(id): _build(spec)
		else: _arches[id].spec = spec
	_world_revision = int(game.get("world").get("revision"))
	# BuildPlacer remains the one owner of visible placed-building geometry.
	for piece: Node in get_tree().get_nodes_in_group("placed_building"):
		if not world.is_ancestor_of(piece) or not piece.has_method("set_lit"):
			continue
		var index := int(piece.get_meta("placed_index", -1))
		if index >= 0 and index < buildings.size():
			var uid := str(buildings[index].get("uid", ""))
			piece.set_lit(true, 1.0 if not _twin(uid).is_empty() else 0.18)

func _process(_delta: float) -> void:
	if game != null and (int(game.get("progression").get("revision")) != _revision or int(game.get("world").get("revision")) != _world_revision):
		restore_progression_from_game(game)

func restore_progression_from_game(_game: Node) -> void:
	if game == null:
		return
	_sync_buildings()
	var flags: RefCounted = game.get("progression")
	_revision = int(flags.get("revision"))
	for id: String in _arches:
		var row: Dictionary = _arches[id]
		var spec: Dictionary = row.spec
		var lit := RULES.is_lit(spec, flags)
		var available := RULES.is_available(spec, flags)
		row.node.visible = available and not bool(world.get("simulation_only"))
		if row.has("prompt"):
			row.prompt.enabled = available and not lit
		if row.has("piece"):
			row.piece.set_lit(lit, 1.0 if not _twin(id).is_empty() else 0.18)
		if id == _pending_id and lit:
			_pending_id = ""
	if not bool(world.get("simulation_only")):
		var chapter := world.get_node("StormwoodChapter")
		if flags.has(RULES.lit_flag("a_ashfoot")):
			chapter.emit_event("arch:ancient_a_south")
		if not RULES.linked_twin("b_pools", flags).is_empty():
			chapter.emit_event("arch:pair_b_linked")
		if not _twin("e_crown").is_empty():
			chapter.emit_event("arch:crown_constructed")
		if flags.has(ROAD_STEP_1) and not flags.has(ROAD_STEP_2) \
				and not BUILT.chosen_road(flags, game.get("placed_buildings")).is_empty():
			chapter.emit_event("side:stormwood_raise_a_road:step_2")
		for footing: String in _footing_prompts:
			(_footing_prompts[footing] as Node).call("configure",
				footing_prompt_label(footing, flags), 2.5, true)

## Raise a Road: before two footings are chosen, an optional footing's prompt
## records it as one of the player's road ends; otherwise it explains the
## footing as before. The choice is separate from building on it.
static func footing_prompt_label(footing: String, flags: RefCounted) -> String:
	if footing == "still_grove":
		return "Inspect the shattered Crown footing"
	var socket := {}
	for row: Dictionary in RULES.config().footings:
		if str(row.id) == footing:
			socket = row
	if BUILT.ROAD_FOOTINGS.has(footing) and flags.has(ROAD_REVEALED) and RULES.is_available(socket, flags):
		if flags.has(BUILT.ROAD_CHOSEN_PREFIX + footing):
			return "Your chosen road footing"
		if not flags.has(ROAD_STEP_1) and chosen_count(flags) < 2:
			return "Choose this footing for your road"
	return "Inspect the old arch footing"


static func chosen_count(flags: RefCounted) -> int:
	var count := 0
	for footing: String in BUILT.ROAD_FOOTINGS:
		if flags.has(BUILT.ROAD_CHOSEN_PREFIX + footing):
			count += 1
	return count


func _inspect_footing(footing: String) -> void:
	var flags: RefCounted = game.get("progression")
	if footing == "still_grove":
		game.push_world_message("Open Build and choose Stormglass Arch. The Crown footing needs six Crown-grade Stormglass.")
		return
	_pending_choices = _pending_choices.filter(func(id: String) -> bool:
		return not flags.has(BUILT.ROAD_CHOSEN_PREFIX + id))
	if footing_prompt_label(footing, flags) == "Choose this footing for your road" \
			and (_pending_choices.has(footing) or chosen_count(flags) + _pending_choices.size() < 2):
		if not _pending_choices.has(footing):
			_pending_choices.append(footing)
		world.get_node("StormwoodChapter").emit_event("count:" + BUILT.ROAD_CHOSEN_PREFIX + footing)
		game.push_world_message("Chosen for your road. Raise its two arches one after the other: a new arch binds to the last unpaired one.")
		restore_progression_from_game(game)
		return
	if flags.has(BUILT.ROAD_CHOSEN_PREFIX + footing):
		game.push_world_message("Your chosen road footing. Open Build and raise a Stormglass Arch here.")
		return
	game.push_world_message("This footing accepts a Stormglass Arch. The next raised arch becomes its twin.")


func _relight(id: String) -> void:
	if not _pending_id.is_empty():
		return
	var available := int(game.get("inventory").count("stormglass"))
	_pending_id = id
	var verdict := CLAIM.submit(self, {"kind": "stormwood_relight_arch", "realm": "stormwood", "id": id, "available_stormglass": available})
	if not CLAIM.in_flight(verdict):
		_pending_id = ""

func travel_for_peer(peer: int, id: String) -> Dictionary:
	_sync_buildings()
	var refused := {"ok": false, "reason": "This road is not ready."}
	if not session.is_host() or session.realm_of(peer) != "stormwood" or not _arches.has(id):
		return refused
	if Time.get_ticks_msec() < int(_arrival_until.get(peer, 0)):
		return refused
	var actors: Dictionary = world.get_node("StormwoodLightning")._actors()
	if not actors.has(peer):
		return refused
	var body: Node3D = actors[peer]
	var source: Node3D = _arches[id].node
	if body.global_position.distance_to(source.global_position) > 5:
		return refused
	var director := world.get_node("EncounterDirector")
	var host: RefCounted = director.get("_encounter_host")
	if host != null:
		for fight: Dictionary in host.get("encounters").values():
			if str(fight.get("phase", "")) != "done" and (fight.get("participants", {}) as Dictionary).has(peer):
				return {"ok": false, "reason": "Finish the fight before taking an arch."}
	if peer == session.local_peer_id() and world.get_node("CombatManager").is_fighting():
		return {"ok": false, "reason": "Finish the fight before taking an arch."}
	var twin := _twin(id)
	if twin.is_empty() or not _arches.has(str(twin.id)):
		return refused
	var target: Node3D = _arches[str(twin.id)].node
	var at := target.to_global(Vector3(0, 0, 3.5))
	at.y = world.ground_height_near(at) + 0.6
	if not at.is_finite() or absf(at.y - target.global_position.y) > 6:
		return {"ok": false, "reason": "The far footing is obstructed."}
	var capsule := CapsuleShape3D.new()
	capsule.height = 1.8
	capsule.radius = 0.35
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.collision_mask = 1
	if body is CollisionObject3D: query.exclude = [body.get_rid()]
	for offset: Vector3 in [Vector3.ZERO, Vector3(2, 0, 0)]:
		query.transform = Transform3D(Basis.IDENTITY, at + offset + Vector3(0, 0.9, 0))
		if not get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty():
			return {"ok": false, "reason": "Clear the far footing before travelling."}
	_arrival_until[peer] = Time.get_ticks_msec() + 2000
	body.global_position = at
	if body is CharacterBody3D:
		body.velocity = Vector3.ZERO
	return {"ok": true, "source": id, "target": twin.id, "at": at}

func _arrive(event: Dictionary) -> void:
	if bool(world.get("simulation_only")):
		return
	if not bool(event.get("ok", false)):
		game.push_world_message(str(event.get("reason", "This road is not ready.")))
		return
	var player := world.get_node("Player") as CharacterBody3D
	player.global_position = event.at
	player.velocity = Vector3.ZERO
	var ally: Node3D = world.get_node("EncounterDirector").get("_ally_body")
	if is_instance_valid(ally):
		ally.global_position = player.global_position + Vector3(2, 0, 0)
		if ally is CharacterBody3D: ally.velocity = Vector3.ZERO
	var layer := CanvasLayer.new()
	var flash := ColorRect.new()
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(0.85, 0.95, 1.0, 0.85)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(flash)
	add_child(layer)
	var tween := create_tween()
	tween.tween_property(flash, "color:a", 0.0, 0.5)
	tween.tween_callback(layer.queue_free)
	if str(event.get("source", "")).begins_with("a_"):
		world.get_node("StormwoodChapter").emit_event("arch:pair_a_travel")
	if str(event.get("target", "")) == "e_crown":
		world.get_node("StormwoodChapter").emit_event("arch:crown_arrived")
	var departure := BUILT.road_departure_event(str(event.get("source", "")),
		str(event.get("target", "")), game.get("progression"), game.get("placed_buildings"))
	if not departure.is_empty():
		world.get_node("StormwoodChapter").emit_event(departure)
