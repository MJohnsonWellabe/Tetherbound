extends SceneTree

## K3: `tests/smoke_authored_camps.gd`'s SECOND pass at `trail_camp` (the sleep
## phase) sometimes finds the rest-point interact prompt inert -- 2/8 (25%)
## per `ralph/reports/audit/K-2026-08-31.md`. Reproduces the exact test
## sequence (offer sweep over every authored camp, then the sleep phase at
## trail_camp) but logs the arbiter's winner/prompt/actionable state on EVERY
## physics frame of the 20-frame settle window after the second teleport,
## instead of only checking the outcome, so a failure shows what the arbiter
## actually saw instead of just that it saw nothing.
##
##   godot --headless --path . --script tools/_probe_trail_camp_second_visit.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const BAND_CONTENT := preload("res://scripts/data/band_content.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const ARBITER_HELPER := preload("res://scripts/world/prompt_arbiter.gd")
const BEDDED_SPECIES := "brooktail"
const PROPS_CONFIG := "res://data/config/props.json"

const SETTLE_FRAMES := 240
const STAND_OFF_M := 1.8


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame

	var player: CharacterBody3D = world.get_node_or_null(^"Player") as CharacterBody3D
	var props: Node3D = world.get_node_or_null(^"Props") as Node3D
	var game := root.get_node_or_null(^"/root/Game")
	var arbiter: Node = get_first_node_in_group("interaction_arbiter")
	if player == null or props == null or game == null or arbiter == null:
		print("missing Player/Props/Game/arbiter")
		quit(1)
		return

	var authored := _authored_rest_clusters()
	print("authored camps in sweep order: %s" % str(authored.map(func(e): return e[0])))

	# --- phase 1: the offer sweep, exactly like the smoke test -----------------
	for entry: Array in authored:
		var name: String = entry[0]
		var point := _rest_node(props, name)
		if point == null:
			continue
		var label := str((entry[1] as Dictionary).get("label", "Rest until morning"))
		if name == "trail_camp":
			await _stand_beside(world, player, point.global_position)
			print("  [sweep visit to trail_camp] player settled at %.3f,%.3f,%.3f on_floor=%s" % [
				player.global_position.x, player.global_position.y, player.global_position.z,
				str(player.call("is_on_floor"))])
		else:
			await _stand_beside(world, player, point.global_position)
		var offered := str(arbiter.call("prompt"))
		print("  sweep  %-22s offers '%s' (want '%s')" % [name, offered, label])

	# --- phase 2: the sleep test, at trail_camp, instrumented ------------------
	var point: Node3D = null
	var camp_name := ""
	for entry: Array in authored:
		var candidate := _rest_node(props, entry[0])
		if candidate != null and candidate.get_node_or_null(^"CampCreatureBed") != null:
			point = candidate
			camp_name = entry[0]
			break
	if point == null:
		print("no authored camp has a creature bed")
		quit(1)
		return
	print("\nsleep phase at '%s'" % camp_name)

	var party: RefCounted = game.get("party")
	var creature: RefCounted = null
	if int(party.call("size")) > 0:
		creature = party.call("at", 0)
	else:
		creature = SPECIES.spawn(BEDDED_SPECIES)
		party.call("add", creature)
	var bed := point.get_node_or_null(^"CampCreatureBed")
	creature.set("hp", maxf(1.0, float(creature.get("max_hp")) * 0.25))
	var assigned: bool = bed.call("assign_creature", 0)
	print("assign_creature -> %s" % str(assigned))

	# Teleport with the SAME fixed `_stand_beside` (hold every frame), but log
	# every physics frame of the settle window instead of just the last one.
	var target := point.global_position + Vector3(STAND_OFF_M, 0.2, 0.0)
	player.velocity = Vector3.ZERO
	player.global_position = target
	print("teleported to %s (player now at %.2f, %.2f, %.2f)" % [
		camp_name, player.global_position.x, player.global_position.y, player.global_position.z])
	var rest_interactable: Node3D = point.get_node_or_null(^"Interactable") as Node3D
	var craft_interactable: Node3D = point.get_node_or_null(^"CraftInteractable") as Node3D
	for i in 20:
		player.velocity = Vector3.ZERO
		player.global_position = target
		await physics_frame
		var winner: Dictionary = arbiter.call("winner")
		var winning_provider: Object = arbiter.call("winning_provider")
		var provider_name := "<none>"
		if winning_provider != null and is_instance_valid(winning_provider):
			provider_name = str(winning_provider)
			if winning_provider is Node:
				provider_name = (winning_provider as Node).get_path()
		var actionable := ARBITER_HELPER.is_actionable(winner)
		var rest_offer: Dictionary = rest_interactable.call("interaction_offer", player.global_position) as Dictionary
		var craft_offer: Dictionary = craft_interactable.call("interaction_offer", player.global_position) as Dictionary
		var shape := SphereShape3D.new()
		shape.radius = 0.05
		var sparam := PhysicsShapeQueryParameters3D.new()
		sparam.shape = shape
		sparam.transform = Transform3D(Basis(), Vector3(player.global_position.x, 1.60, player.global_position.z))
		sparam.collide_with_areas = false
		var hits: Array = world.get_world_3d().direct_space_state.intersect_shape(sparam, 4)
		var hit_names := []
		for h in hits:
			var c: Variant = (h as Dictionary).get("collider")
			hit_names.append(str((c as Node).name) if c is Node else str(c))
		print("  frame %2d: prompt='%s' winner_label='%s' provider=%s actionable=%s on_floor=%s | rest_offer=%s craft_offer=%s player=%.3f,%.3f,%.3f solid_at_y1.60=%s" % [
			i, str(arbiter.call("prompt")), str(winner.get("label", "")), provider_name, str(actionable), str(player.call("is_on_floor")),
			str(rest_offer), str(craft_offer),
			player.global_position.x, player.global_position.y, player.global_position.z, str(hit_names)])

	var activated: bool = arbiter.call("activate")
	print("\nactivate() -> %s" % str(activated))
	if not activated:
		print("REPRO: pressing interact at '%s' activated nothing" % camp_name)
		quit(1)
		return
	print("no repro this run")
	quit(0)


func _authored_rest_clusters() -> Array:
	var parsed: Dictionary = BAND_CONTENT.load_config(PROPS_CONFIG, "clusters")
	var out: Array = []
	for cluster: Variant in parsed.get("clusters", []):
		if not cluster is Dictionary:
			continue
		var rest: Variant = (cluster as Dictionary).get("rest", {})
		if rest is Dictionary and not (rest as Dictionary).is_empty():
			out.append([str((cluster as Dictionary).get("name", "?")), rest as Dictionary])
	return out


func _rest_node(props: Node3D, name: String) -> Node3D:
	var group := props.get_node_or_null(NodePath(name))
	if group == null:
		return null
	return group.get_node_or_null(NodePath("%s_Rest" % name)) as Node3D


func _stand_beside(_world: Node, player: CharacterBody3D, at: Vector3) -> void:
	var target := at + Vector3(STAND_OFF_M, 0.2, 0.0)
	for i in 20:
		player.velocity = Vector3.ZERO
		player.global_position = target
		await physics_frame
