extends SceneTree

## F13 `side_water_deep_watch_chart` in the production Water scene: Orsen names
## Deep Watch -> Tidecoil is resolved -> the separate chart control is used, and
## the Tidecoil cache (Skill Candy III) is withheld and refused until then.
##
## Real: production water_archipelago world, WaterNPCs + DialoguePanel speech,
## the Water encounter director's named Tidecoil body and its production
## won-fight terminal handler (`_on_combat_exited("won")`, which calls
## `_mark_once_cleared`), WaterPickups streamer, host LedgerRPC claim rule and
## WaterDocks chart prompt.
## Disclosed fixtures: player poses are teleports (no traversal or swim-mount
## route); upstream dock facts are pre-set exactly as smoke_water_dock_actions
## does; the Tidecoil fight itself is not played -- its body is marked engaged
## and the director's terminal handler is invoked with outcome "won". Solo only;
## co-op resolution is covered by unit tests of the relay.
const WORLD := preload("res://scenes/world/water_archipelago.tscn")
const QUEST_LOG := preload("res://scripts/world/quest_log.gd")
const GATED := "water:deep_watch:pickup:002"
const RESOLVED := "water_named_deep_watch_tidecoil_resolved"
const CHARTED := "water_dock_deep_watch_current_charted"
const TIDECOIL_ID := "water_deep_watch_tidecoil"

var game: Node
var world: Node3D
var player: CharacterBody3D
var checks := 0
var failures: Array[String] = []
var finished := false

func _init() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> bool:
	checks += 1
	if not ok:
		failures.append(message)
		print("FAIL: ", message)
	return ok

func frames(count: int = 4) -> void:
	for frame in count:
		await physics_frame

func pose(at: Vector3) -> void:
	player.global_position = Vector3(at.x, float(world.ground_height_at(at.x, at.z)) + 0.1, at.z)
	player.velocity = Vector3.ZERO

func gated_row() -> Dictionary:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_pickups.json"))
	for row: Dictionary in data.pickups:
		if str(row.id) == GATED:
			return row
	return {}

## Speak to Orsen through the production NPC seam; returns [conversation, text].
func hear_orsen() -> Array:
	var chapter: Node = world.get_node("WaterChapter")
	var npcs: Node = world.get_node("WaterNPCs")
	var panel: Node = world.get_node("DialoguePanel")
	var orsen: Node3D = chapter.npc_bodies.get("water_orsen")
	if orsen == null:
		return ["", ""]
	pose(orsen.global_position + Vector3(2.0, 0.0, 0.0))
	await frames()
	if not bool(npcs.call("start_conversation", "water_orsen")):
		return ["", ""]
	var conversation := str(npcs.get("_active_conversation"))
	var text := ""
	for guard in 12:
		if not bool(panel.call("is_open")):
			break
		text += str(panel.call("runner").call("line").get("text", "")) + "\n"
		panel.call("advance")
		await process_frame
	if bool(panel.call("is_open")):
		panel.call("close")
	return [conversation, text]

func tidecoil_body(director: Node) -> Node3D:
	for wild: Variant in director.get("_wild_creatures"):
		if is_instance_valid(wild) and str((wild as Node).get_meta("water_named_encounter", "")) == TIDECOIL_ID:
			return wild as Node3D
	return null

func run() -> void:
	create_timer(240.0).timeout.connect(func() -> void:
		if not finished:
			check(false, "240 second watchdog expired")
			finish())
	game = root.get_node("Game")
	game.reset_for_new_game()
	game.current_realm = "water"
	game.local.character_id = "water-deep-watch-chart"
	for upstream: String in ["water_dock_brine_steps_trial_won", "water_aquaryn_resolved",
			"water_dock_salt_crown_landing_charted", "water_swim_stone_earned"]:
		if upstream.begins_with("water_swim_stone"):
			game.local.flags.set_flag(upstream)
		else:
			game.world.flags.set_flag(upstream)
	world = WORLD.instantiate()
	root.add_child(world)
	current_scene = world
	for frame in 900:
		await process_frame
		if world.shell_build_complete():
			break
	if not check(world.shell_build_complete(), "Production Water world built"):
		finish()
		return
	player = world.get_node("Player")
	player.set_physics_process(false)
	var pickups: Node = world.get_node("WaterPickups")
	var docks: Node = world.get_node("WaterDocks")
	var director: Node = world.get_node("EncounterDirector")
	var log_reader := QUEST_LOG.new()
	log_reader.set_realm("water")

	# Step 1: Orsen names Deep Watch.
	var heard: Array = await hear_orsen()
	check(heard[0] == "water_orsen_pre", "Orsen greets with his Sluice conversation (%s)" % heard[0])
	check(str(heard[1]).contains("Deep Watch") and str(heard[1]).contains("Tidecoil"), "Orsen names Deep Watch and Tidecoil in delivered lines")
	check(not game.world.flags.has(RESOLVED) and not game.world.flags.has(CHARTED), "Speech writes no chain flag")
	var local_before: Array = log_reader.local_entries(game.progression)
	check(local_before.filter(func(e: Dictionary) -> bool: return str(e.label).contains("Deep Watch")).is_empty(),
		"Chart request is not pre-labelled before resolution")

	# The cache is withheld and refused while Tidecoil holds the lookout.
	var row := gated_row()
	var cache_at := Vector3(float(row.position[0]), 0.0, float(row.position[2]))
	pose(cache_at + Vector3(1.0, 0.0, 0.0))
	await frames(2)
	await create_timer(0.7).timeout
	pickups.call("refresh")
	check(pickups.call("node_for", GATED) == null, "Locked Tidecoil cache is not spawned at the pocket")
	var neighbour := false
	for id in ["water:deep_watch:pickup:001", "water:deep_watch:pickup:003", "water:deep_watch:harvest:001"]:
		neighbour = neighbour or pickups.call("node_for", id) != null
	check(neighbour, "Ungated Deep Watch finds around the pocket still stream in")
	var locked: Dictionary = game.ledger.submit({"kind": "water_personal_pickup", "realm": "water",
		"pickup_id": GATED, "personal_claimed": false})
	check(not bool(locked.get("ok", false)) and str(locked.get("code", "")) == "locked", "Host claim rule refuses the cache as locked (%s)" % str(locked.get("code", "")))
	check(str(locked.get("reason", "")).contains("Tidecoil"), "Locked message names Tidecoil: " + str(locked.get("reason", "")))
	check(game.inventory.count("skill_candy_iii") == 0, "No Candy III granted while locked")

	# Step 3 attempted early: the chart control refuses.
	var chart: Node3D = docks.get_node("deep_watch_chart")
	pose(chart.global_position + Vector3(2.0, 0.0, 0.0))
	await frames()
	var early: Dictionary = game.ledger.submit({"kind": "water_dock_action", "realm": "water", "action_id": "deep_watch_chart", "inventory": {}})
	check(not bool(early.get("ok", false)) and str(early.get("reason", "")).contains("Tidecoil"), "Chart refuses before Tidecoil with a clear reason")
	check(not game.world.flags.has(CHARTED), "Early chart attempt leaves the current uncharted")

	# Step 2: resolve Tidecoil through the director's won-fight terminal handler.
	var tidecoil_site := Vector3(1483.196, -0.5075, 3427.917)
	var stand := Vector3.INF
	for distance: float in [30.0, 40.0, 50.0, 60.0, 70.0, 80.0]:
		var candidate := tidecoil_site + (Vector3(1350.0, 0.0, 3500.0) - tidecoil_site).normalized() * distance
		if float(world.ground_height_at(candidate.x, candidate.z)) >= 0.8:
			stand = candidate
			break
	if not check(stand.is_finite(), "Dry standing ground within Tidecoil's activation reach"):
		finish()
		return
	pose(stand)
	var body: Node3D = null
	for attempt in 120:
		await process_frame
		body = tidecoil_body(director)
		if body != null:
			break
	if not check(body != null, "Named Tidecoil body is resident at its reef edge"):
		finish()
		return
	check(str(director.get("_once_only").get(body, "")) == RESOLVED, "Tidecoil carries its completion flag as once-id")
	var candy_before := int(game.inventory.count("skill_candy_iii"))
	director.set("_engaged_with", body)
	director.call("_on_combat_exited", "won")
	await frames()
	check(game.world.flags.has(RESOLVED), "Won Tidecoil records its world resolution flag")
	check(not game.world.flags.has(CHARTED), "Victory alone does not flip the chart flag")
	check(int(game.inventory.count("skill_candy_iii")) == candy_before, "Resolution grants no direct Candy")
	var revealed: Array = log_reader.local_entries(game.progression).filter(func(e: Dictionary) -> bool: return str(e.label).contains("Deep Watch"))
	check(revealed.size() == 1 and not bool(revealed[0].done), "Resolution reveals the open chart request")
	heard = await hear_orsen()
	check(heard[0] == "water_orsen_deep_watch_chart_lead", "Orsen now gives the chart lead (%s)" % heard[0])
	check(str(heard[1]).contains("chart table") and str(heard[1]).contains("cache"), "Chart lead points at the table and the cache")

	# The cache now streams in and pays through the production claim.
	pose(cache_at + Vector3(1.0, 0.0, 0.0))
	await frames(2)
	await create_timer(0.7).timeout
	var cache: Node = pickups.call("node_for", GATED)
	check(cache != null, "Resolved Tidecoil cache spawns on the ordinary refresh")
	if cache != null:
		cache.call("_on_picked_up")
		await frames()
	check(int(game.inventory.count("skill_candy_iii")) == candy_before + 1, "Production claim pays exactly one Candy III")
	check(game.local.flags.has("water_candy:" + GATED), "Personal receipt recorded")
	var again: Dictionary = game.ledger.submit({"kind": "water_personal_pickup", "realm": "water",
		"pickup_id": GATED, "personal_claimed": true})
	check(str(again.get("code", "")) == "already_taken", "Second claim by the same character refuses")

	# Step 3: operate the separate chart control through its real prompt.
	pose(chart.global_position + Vector3(2.0, 0.0, 0.0))
	await frames()
	for child: Node in chart.get_children():
		if child.has_method("interaction_activate"):
			child.call("interaction_activate")
	await frames()
	check(game.world.flags.has(CHARTED), "Chart prompt commits the chart flag after resolution")
	var done: Array = log_reader.local_entries(game.progression).filter(func(e: Dictionary) -> bool: return str(e.label).contains("Deep Watch"))
	check(done.size() == 1 and bool(done[0].done), "Chart completes the local request")
	heard = await hear_orsen()
	check(heard[0] == "water_orsen_deep_watch_charted", "Orsen acknowledges the charted current (%s)" % heard[0])
	finish()

func finish() -> void:
	finished = true
	print("Water Deep Watch chart smoke: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
