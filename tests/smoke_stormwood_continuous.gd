extends SceneTree

## Continuous solo Stormwood acceptance, beginning at the chapter boundary.
##
## The wrapper owns one disclosed seam: it constructs an in-memory
## completed-Cloudreach party and entitlement, then asks the production realm
## router to enter Stormwood. It does not write an earned save and it sets no
## `stormwood:*` progression flag. From the authored arrival onward, movement,
## dialogue, weather witnessing, gathering and combat input are ordinary player
## actions. The `Segment` class is deliberately reusable by a future four-biome
## harness that arrives with its own live Game and mounted Stormwood scene.
##
## The first executable prefix reaches Act II's Stormglass Arch recipe.
## Later phases extend the same live Segment; a failed prefix requires diagnosis
## and must not be bypassed by seeding its next flag.

const GAME := preload("res://autoload/game_state.gd")
const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const NAVIGATOR := preload("res://tests/helpers/stick_navigator.gd")

const TEST_SAVE_DIR := "user://stormwood_continuous_chapter_entry"
const SCENE_WAIT_FRAMES := 7200
# The eight-minute prefix cap was measured too small after the segment grew into
# Act II: it expired after pair B's first endpoint, with 1,536.8 authored metres
# and Varga's bounded five-minute sequence still ahead. At 80 physics frames per
# metre and this wrapper's 480 Hz target, that walk's nominal target-clock
# estimate is 256 seconds (actual wall time still includes runtime overhead).
# Twenty minutes covers the observed eight-minute prefix + that walk + the
# unchanged trainer bound + interaction/dialogue margin. Per-step limits remain
# authoritative, so this outer guard is capacity rather than a weaker assertion.
const PREFIX_WATCHDOG_MS := 20 * 60 * 1000
const COMPLETED_CLOUDREACH_FLAGS: Array[String] = [
	"cloudreach_chapter_started",
	"cloudreach_act_i_complete",
	"cloudreach_act_ii_complete",
	"captain_veyra_defeated",
	"cloudreach_winds_restored",
	"realm_heart_cloudreach_earned",
	"realm_key_stormwood",
	"stormward_route_revealed",
	"cloudreach_chapter_complete",
]
const ENTRY_PARTY: Array[String] = [
	"sparkit", "mudsnout", "bramblebun", "terrapup", "brooktail",
]

var _failures: Array[String] = []
var _finished := false
var _segment: Variant = null


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	_watchdog.call_deferred()
	var game := root.get_node_or_null(^"Game")
	if game == null:
		game = GAME.new()
		game.name = "Game"
		root.add_child(game)
	await process_frame
	game.call("reset_for_new_game")
	game.set("save_system", SAVE_GAME.new(TEST_SAVE_DIR))
	game.get("local").set("character_id", "stormwood-continuous-solo")
	game.get("world").set("world_id", "stormwood-continuous-world")
	# Preserve the production 1/60 simulation step while shortening the real
	# wait for the first Calm -> Building -> Break cycle.
	Engine.time_scale = 8.0
	Engine.physics_ticks_per_second = 480
	Engine.max_physics_steps_per_frame = 32

	# CHAPTER-ENTRY FIXTURE. These are facts an ordinary completed-Cloudreach
	# handoff already owns. They are intentionally in-memory: this smoke may not
	# manufacture a save and cite it as earned campaign continuity.
	for flag: String in COMPLETED_CLOUDREACH_FLAGS:
		var verdict: Dictionary = game.get("ledger").call("submit", {
			"kind": "set_world_flag", "realm": "cloudreach", "id": flag,
			"value": true,
		})
		_expect(bool(verdict.get("ok", false)) and not bool(verdict.get("pending", false)),
			"chapter-entry fixture accepted completed Cloudreach fact %s" % flag)
	for species_id: String in ENTRY_PARTY:
		var creature: RefCounted = SPECIES.spawn(species_id)
		if creature != null:
			creature.call("set_level", 44, PROGRESSION.config())
		_expect(creature != null and bool(game.get("party").call("add", creature)),
			"chapter-entry fixture carries %s in the completed Cloudreach party" % species_id)
	for item_id: String in ["knife", "axe", "pickaxe"]:
		game.get("inventory").call("add", item_id, 1)
	game.call("assign_hotbar", 0, "knife")
	game.call("assign_hotbar", 1, "axe")
	game.call("assign_hotbar", 2, "pickaxe")
	for flag: String in game.get("progression").call("all_set"):
		_expect(not flag.begins_with("stormwood:"),
			"chapter-entry fixture contains no Stormwood progress (%s)" % flag)
	if not _failures.is_empty():
		_finish()
		return

	var source := Node3D.new()
	source.name = "StormwoodContinuousEntrySource"
	root.add_child(source)
	current_scene = source
	await process_frame
	_expect(await game.call("enter_realm", "stormwood", "stormwood_arrival_from_cloudreach"),
		"production router accepted the completed-Cloudreach Stormwood entry")
	var world := await _wait_for_stormwood()
	_expect(world != null, "production Stormwood scene became current")
	if world == null:
		_finish()
		return
	for _frame in SCENE_WAIT_FRAMES:
		if str(game.get("pending_realm_entry")) == "":
			break
		await physics_frame
	_expect(str(game.get("current_realm")) == "stormwood",
		"production router settled in Stormwood")
	_expect(str(game.get("pending_realm_entry")) == "",
		"authored Stormwood arrival settled its pending entry")
	if not _failures.is_empty():
		_finish()
		return

	_segment = Segment.new()
	var result: Dictionary = await _segment.run(self, world, game)
	for line: Variant in result.get("transcript", []):
		print("STORMWOOD CONTINUOUS — %s" % str(line))
	for line: Variant in result.get("failures", []):
		_failures.append(str(line))
	_finish()


func _wait_for_stormwood() -> Node3D:
	for _frame in SCENE_WAIT_FRAMES:
		var candidate := current_scene as Node3D
		if candidate != null and candidate.name == "Stormwood" \
				and bool(candidate.call("shell_build_complete")):
			return candidate
		await physics_frame
	return null


func _watchdog() -> void:
	await create_timer(float(PREFIX_WATCHDOG_MS) / 1000.0, true, false, true).timeout
	if not _finished:
		var detail := ""
		if _segment != null and _segment.has_method("diagnostic_snapshot"):
			detail = " (%s)" % str(_segment.call("diagnostic_snapshot"))
		_failures.append("prefix watchdog expired before the Act-II Stormglass Arch recipe%s" % detail)
		_finish()


func _expect(condition: bool, label: String) -> void:
	if condition:
		print("  PASS: ", label)
	else:
		_failures.append(label)
		push_error("STORMWOOD CONTINUOUS: " + label)


func _finish() -> void:
	if _finished:
		return
	_finished = true
	Engine.time_scale = 1.0
	Engine.physics_ticks_per_second = 60
	Engine.max_physics_steps_per_frame = 8
	if _failures.is_empty():
		print("stormwood continuous: OK — chapter-entry through the Act-II arch recipe passed without Stormwood flag or position fixtures")
		quit(0)
		return
	for line: String in _failures:
		print("stormwood continuous FAIL: ", line)
	quit(1)


class Segment extends RefCounted:
	const FIRST_HARVEST_ID := "stormwood_harvest_cinder_verge_018"
	const SECOND_HARVEST_ID := "stormwood_harvest_cinder_verge_023"
	const VERGE_ROUTE_PICKUP_ID := "stormwood_pickup_route_03"
	const RODLINE_ROUTE_PICKUP_ID := "stormwood_pickup_route_07"
	const POOLS_HARVEST_IDS: Array[String] = [
		"stormwood_harvest_glowmoss_hollows_036",
		"stormwood_harvest_glowmoss_hollows_037",
	]
	const BREAK_WAIT_MS := 120000
	# Measured on the failed 2026-09-08 run: from Lantern Pools camp to both
	# charged nodes plus their impact settles consumed about 45.7 simulation
	# seconds. Require 55 contiguous seconds of the runtime's own open window;
	# this is route margin, not a weather-duration or wall-clock change.
	const MIN_CHARGED_ROUTE_SECONDS := 55.0
	const ARRIVAL_XZ := Vector2(-350.0, 450.0)
	const HESK_STANCE_XZ := Vector2(-350.0, 447.5)
	const TAMSIN_STANCE_XZ := Vector2(-300.0, 347.5)
	const ASHFOOT_SHELTER_XZ := Vector2(-325.0, 466.0)
	const FIRST_GLASS_XZ := Vector2(-762.0, 893.0)
	const SECOND_GLASS_XZ := Vector2(-738.0, 877.0)

	var tree: SceneTree
	var world: Node3D
	var game: Node
	var player: CharacterBody3D
	var camera: Node3D
	var navigator: RefCounted
	var arbiter: Node
	var director: Node
	var manager: Node
	var transcript: Array[String] = []
	var failures: Array[String] = []
	var _activated_provider_id := 0
	var _activated_provider_path := ""
	var _trainer_outcomes: Dictionary = {}
	var _last_combat_outcome := ""
	var _active_phase := "segment setup"
	var _active_phase_started_ms := 0
	var _active_target := Vector2.ZERO
	var _active_target_valid := false
	var _active_walk_budget := 0
	var _active_walked := 0


	func run(p_tree: SceneTree, p_world: Node3D, p_game: Node) -> Dictionary:
		tree = p_tree
		world = p_world
		game = p_game
		player = world.get_node_or_null(^"Player") as CharacterBody3D
		camera = world.get_node_or_null(^"CameraRig") as Node3D
		arbiter = tree.get_first_node_in_group(&"interaction_arbiter")
		director = world.get_node_or_null(^"EncounterDirector")
		manager = world.get_node_or_null(^"CombatManager")
		_active_phase_started_ms = Time.get_ticks_msec()
		if player == null or camera == null or arbiter == null or director == null or manager == null:
			_fail("Stormwood lacks the live player, camera, InteractionArbiter, or combat runtime")
			return _result()
		var session: Node = game.get("session") as Node
		if session == null or not session.has_signal("stormwood_encounter_message"):
			_fail("Stormwood lacks the production hosted-encounter result signal")
			return _result()
		session.connect("stormwood_encounter_message", _on_stormwood_encounter_message)
		manager.connect("exited", _on_combat_exited)
		navigator = NAVIGATOR.new(tree, player, camera, _send_stick)
		if game.get("progression").call("has", "stormwood:chapter_started"):
			_fail("chapter_started was already set before ordinary arrival movement")
			return _result()

		# The route begins at the production realm anchor and walks into Ashfoot.
		if not await _walk_xz(ARRIVAL_XZ, "Ashfoot Waycamp arrival", 1.8):
			return _result()
		if not await _wait_flag("stormwood:chapter_started", 240):
			_fail("ordinary arrival at Ashfoot did not set stormwood:chapter_started")
			return _result()
		_note("ARRIVED Ashfoot; chapter_started was earned by the proximity event")

		if not await _talk_to("Rodkeeper Hesk", HESK_STANCE_XZ,
				"stormwood:crisis_learned", "Hesk's Long Storm account"):
			return _result()
		_note("HEARD Hesk; crisis_learned came from the completed dialogue")

		# Tamsin's production dialogue is the visible instruction for the next
		# objective. The objective itself remains weather-owned, so no test event is
		# emitted after this conversation.
		if not await _talk_to("Tamsin", TAMSIN_STANCE_XZ, "", "Tamsin's Break lesson"):
			return _result()
		_note("HEARD Tamsin through her ordinary NPC prompt")

		if not await _walk_xz(ASHFOOT_SHELTER_XZ, "Ashfoot lightning shelter", 1.5):
			return _result()
		var surge := world.get_node_or_null(^"StormwoodSurge")
		if surge == null:
			_fail("StormwoodSurge is absent from the production world")
			return _result()
		var wait_started := Time.get_ticks_msec()
		var sheltered_break_witnessed := false
		while Time.get_ticks_msec() - wait_started < BREAK_WAIT_MS:
			if str(surge.get("phase")) == "break" and bool(surge.get("sheltered")) \
					and game.get("progression").call("has", "stormwood:first_break_witnessed"):
				sheltered_break_witnessed = true
				break
			await tree.physics_frame
		if not sheltered_break_witnessed:
			_fail("waiting under Ashfoot shelter through the production cycle did not witness the tutorial Break")
			return _result()
		_note("WITNESSED a production Break while sheltered at Ashfoot")

		if not await _equip_fixture_tool("pickaxe"):
			return _result()
		if not await _walk_route("ash_road", 2, "Verge rod clearing"):
			return _result()
		var harvest := world.get_node_or_null(NodePath("StormwoodHarvests/" + FIRST_HARVEST_ID)) as Node3D
		if harvest == null:
			_fail("the authored first charged Stormglass node is absent")
			return _result()
		if not await _activate_node(harvest, harvest.get_node_or_null(^"Interactable") as Node3D,
				FIRST_GLASS_XZ, "first charged Stormglass node"):
			return _result()
		if not await _wait_flag("stormwood:first_stormglass_gathered", 300):
			_fail("ordinary charged-node interaction did not set first_stormglass_gathered")
			return _result()
		if int(game.get("inventory").call("count", "stormglass")) < 3:
			_fail("first charged node did not deliver its authored three Stormglass")
			return _result()
		_note("GATHERED first charged Stormglass through the live tool and interaction path")

		# Pair A costs three at each end. Gather a second authored charged node
		# while the same Break/Fading window is still open; this is real inventory
		# supply, not a material fixture.
		var second_harvest := world.get_node_or_null(NodePath(
			"StormwoodHarvests/" + SECOND_HARVEST_ID)) as Node3D
		if second_harvest == null:
			_fail("the second authored charged Stormglass node is absent")
			return _result()
		if not await _activate_node(second_harvest,
				second_harvest.get_node_or_null(^"Interactable") as Node3D,
				SECOND_GLASS_XZ, "second charged Stormglass node"):
			return _result()
		for _frame in 300:
			if int(game.get("inventory").call("count", "stormglass")) >= 6:
				break
			await tree.physics_frame
		if int(game.get("inventory").call("count", "stormglass")) < 6:
			_fail("two authored charged nodes did not supply the six Stormglass pair A costs")
			return _result()
		_note("GATHERED the real six-Stormglass cost for both ends of pair A")

		if not await _walk_xz(Vector2(-650.0, 830.0), "Verge rod road return", 2.0):
			return _result()
		if not await _relight_arch("a_ashfoot", Vector2(-350.0, 503.0),
				"stormwood:ashfoot_arch_relit"):
			return _result()
		_note("RELIT Ashfoot's ancient arch through its ordinary prompt")

		for point: Vector2 in [Vector2(-590.0, 1060.0), Vector2(-380.0, 1400.0)]:
			if not await _walk_xz(point, "Ash road toward Lantern Pools", 2.0):
				return _result()
		if not await _relight_arch("a_pools", Vector2(-350.0, 1437.0), ""):
			return _result()
		_note("RELIT Lantern Pools' twin with the remaining earned Stormglass")

		# Walk out and then through the linked threshold. The Area3D owns travel;
		# the harness neither calls the arch runtime nor moves either actor.
		if not await _walk_arch_threshold(Vector2(-350.0, 1440.0),
				"stormwood:lantern_pools_linked", "linked pair-A threshold"):
			_fail("walking through the live linked pair did not set lantern_pools_linked")
			return _result()
		_note("TRAVELLED pair A; the production arch moved player and companion to Ashfoot")

		# The authored route reward and Maren share the Verge station. Collect the
		# visible one-time pickup first, through its own prompt, so challenging her
		# cannot silently spend a different provider than the one the test names.
		if not await _collect_route_pickup(VERGE_ROUTE_PICKUP_ID):
			return _result()
		if not await _defeat_trainer("officer_maren_verge_rod"):
			return _result()
		if not await _disable_rod("verge_rod_station"):
			return _result()
		_note("DEFEATED Maren and disabled the Verge rod through its live switch")

		for point: Vector2 in [Vector2(-590.0, 1060.0), Vector2(-380.0, 1400.0),
				Vector2(-900.0, 1780.0)]:
			if not await _walk_xz(point, "Ash road to the Hollows station", 2.0):
				return _result()
		if not await _defeat_trainer("lieutenant_dace_hollows_rod"):
			return _result()
		if not await _disable_rod("hollows_rod_station"):
			return _result()
		if not await _wait_flag("stormwood:lower_rods_disabled", 600):
			_fail("both live lower switches are down but lower_rods_disabled was not earned")
			return _result()
		_note("DEFEATED Dace and earned lower_rods_disabled from both live switches")

		# Pair B needs another six Stormglass. Wait at the authored Pools camp for
		# the next usable weather window, then gather its two nearby charged nodes.
		if not await _walk_xz(Vector2(-410.0, 1425.0), "Lantern Pools safe camp", 1.8):
			return _result()
		if not await _wait_for_charged_window(Vector2(-410.0, 1425.0), "Lantern Pools"):
			return _result()
		for id: String in POOLS_HARVEST_IDS:
			var node := world.get_node_or_null(NodePath("StormwoodHarvests/" + id)) as Node3D
			if node == null:
				_fail("authored Pools charged node %s is absent" % id)
				return _result()
			if not await _harvest_charged_node(node, id):
				return _result()
		if int(game.get("inventory").call("count", "stormglass")) < 6:
			_fail("the two Pools charged nodes did not supply pair B's six Stormglass")
			return _result()
		if not await _relight_arch("b_pools", Vector2(-410.0, 1347.0), ""):
			return _result()
		for point: Vector2 in [Vector2(-900.0, 1780.0), Vector2(-700.0, 2300.0)]:
			if not await _walk_xz(point, "road to Rodline Post", 2.0):
				return _result()
		if not await _relight_arch("b_rodline", Vector2(-680.0, 2363.0),
				"stormwood:rodline_linked"):
			return _result()
		_note("RELIT pair B with entirely harvested Stormglass")
		# The route-07 reward and Bryn occupy the same Rodline prompt cluster.
		# Consume the visible one-time pickup before asking the arbiter for Bryn;
		# otherwise its slightly nearer Take Good Candy offer correctly wins and
		# the ordinary chapter conversation is unreachable from this stance.
		if not await _collect_route_pickup(RODLINE_ROUTE_PICKUP_ID):
			return _result()
		if not await _talk_to("Warden-Elect Bryn", Vector2(-700.0, 2297.0),
				"stormwood:bryn_met", "Bryn's shattered-road account"):
			return _result()
		if not await _wait_flag("stormwood:act_i_complete", 180):
			_fail("Bryn dialogue advanced its objective but did not complete Act I")
			return _result()
		_note("COMPLETED Act I through the production task chain at Rodline Post")

		# Act II opens on the named trainer standing at Rodline's far side. The
		# co-located route-07 reward was already consumed before Bryn, so no later
		# pickup can be mistaken for Varga's challenge.
		if not await _defeat_trainer("lieutenant_varga_rodline_bridge"):
			return _result()
		if not await _wait_flag("stormwood:varga_defeated", 300):
			_fail("Varga's hosted victory did not advance the Act-II chapter event")
			return _result()
		_note("RECLAIMED the conductor bridge through Varga's authored trainer fight")

		for point: Vector2 in [Vector2(-560.0, 2480.0), Vector2(-160.0, 2700.0)]:
			if not await _walk_xz(point, "conductor road to Keeper Ondra", 2.0):
				return _result()
		if not await _talk_to("Keeper Ondra", Vector2(-160.0, 2697.5),
				"stormwood:arch_recipe_known", "Ondra's Stormglass Arch lesson"):
			return _result()
		_note("LEARNED the Stormglass Arch recipe through Ondra's production dialogue")
		return _result()


	func _collect_route_pickup(id: String) -> bool:
		var pickup := world.get_node_or_null(NodePath("StormwoodPickups/" + id)) as Node3D
		var prompt := pickup.get_node_or_null(^"Interactable") as Node3D if pickup != null else null
		if pickup == null or prompt == null:
			_fail("authored route pickup %s or its live prompt is absent" % id)
			return false
		var before := int(game.get("inventory").call("count", "good_candy"))
		var at := Vector2(prompt.global_position.x, prompt.global_position.z)
		if not await _activate_node(pickup, prompt, at + Vector2(0.0, -1.05),
				"%s route reward" % id):
			return false
		var flag := "cache:stormwood:%s" % id
		if not await _wait_flag(flag, 300):
			_fail("%s activation did not commit its durable pickup flag %s" % [id, flag])
			return false
		if int(game.get("inventory").call("count", "good_candy")) <= before:
			_fail("%s committed without granting its authored good candy" % id)
			return false
		_note("COLLECTED %s through its ordinary route prompt" % id)
		return true


	func _defeat_trainer(id: String) -> bool:
		var trainers := world.get_node_or_null(^"StormwoodTrainers")
		var body := trainers.call("body_for", id) as Node3D if trainers != null else null
		var prompt := body.call("prompt_node") as Node3D if body != null else null
		if body == null or prompt == null:
			_fail("critical trainer %s or its challenge prompt is absent" % id)
			return false
		if not await _ensure_usable_ally(id):
			return false
		var spec: Dictionary = trainers.get("authored_specs").get(id, {})
		if not bool(director.call("can_challenge", spec)):
			_fail(("%s remains unavailable after usable-ally recovery "
				+ "(manager_fighting=%s trainer_active=%s ally_blocker=%s already_defeated=%s)") % [
				id, bool(manager.call("is_fighting")),
				bool(director.call("trainer_battle_active")),
				str(director.call("usable_ally_blocker")),
				bool(game.get("progression").call("has", str(spec.get("defeat_flag", "")))),
			])
			return false
		if not await _activate_node(body, prompt,
				Vector2(body.global_position.x, body.global_position.z - 2.0), "%s challenge" % id):
			return false
		if not await _drain_dialogue("%s challenge" % id):
			return false
		for _frame in 600:
			if bool(director.call("trainer_battle_active")):
				break
			await tree.physics_frame
		if not bool(director.call("trainer_battle_active")):
			_fail("%s challenge dialogue did not start production hosted combat" % id)
			return false
		var started := Time.get_ticks_msec()
		while bool(director.call("trainer_battle_active")) \
				and Time.get_ticks_msec() - started < 300000:
			if bool(manager.call("is_fighting")):
				if not await _fight_current_encounter(id):
					return false
			else:
				await tree.physics_frame
		if bool(director.call("trainer_battle_active")):
			_fail("%s trainer sequence did not finish within five minutes" % id)
			return false
		if not _trainer_outcomes.has(id):
			_fail("%s trainer sequence ended without a production finished outcome" % id)
			return false
		if not bool(_trainer_outcomes.get(id, false)):
			_fail("%s trainer sequence ended in a loss, not a victory" % id)
			return false
		_note("WON %s; hosted authority published its finished outcome" % id)
		var defeat_flag := "stormwood:trainer:%s:defeated" % id
		if not await _wait_flag(defeat_flag, 300):
			_fail("%s combat ended without durable defeat flag %s" % [id, defeat_flag])
			return false
		return true


	func _ensure_usable_ally(label: String) -> bool:
		# A wild fight is one creature against one creature and legitimately leaves
		# its loser fainted. The player still owns the rest of the disclosed five-
		# member party, so use the ordinary field controls to select and deploy the
		# next healthy member before asking a trainer for another battle.
		if bool(director.call("no_usable_ally")):
			await _tap(&"party_cycle")
			for _frame in 180:
				if not bool(director.call("no_usable_ally")):
					break
				await tree.physics_frame
		if director.call("ally_body") == null:
			await _tap(&"creature_recall")
			for _frame in 180:
				if director.call("ally_body") != null:
					break
				await tree.physics_frame
		if bool(director.call("no_usable_ally")):
			var party: RefCounted = game.get("party") as RefCounted
			var alive := 0
			var members: Array = party.call("members") if party != null else []
			for member: RefCounted in members:
				if member != null and not bool(member.get("fainted")):
					alive += 1
			_fail("ordinary party-cycle/recall input left no usable ally before %s (healthy party members=%d)" % [
				label, alive])
			return false
		return true


	func _on_stormwood_encounter_message(event: Dictionary) -> void:
		if str(event.get("kind", "")) == "finished":
			_trainer_outcomes[str(event.get("trainer_id", ""))] = bool(event.get("won", false))


	func _on_combat_exited(outcome: String) -> void:
		_last_combat_outcome = outcome


	func _disable_rod(id: String) -> bool:
		var station := world.get_node_or_null(NodePath("StormwoodRodStations/" + id)) as Node3D
		var prompt := station.get_node_or_null(^"RodSwitch") as Node3D if station != null else null
		if station == null or prompt == null:
			_fail("rod station %s or its live switch is absent" % id)
			return false
		if not await _activate_node(station, prompt,
				Vector2(prompt.global_position.x, prompt.global_position.z - 1.8), "%s switch" % id):
			return false
		var flag := "stormwood:rod_%s_disabled" % (
			"verge" if id == "verge_rod_station" else "hollows")
		if not await _wait_flag(flag, 300):
			_fail("%s switch accepted but did not commit %s" % [id, flag])
			return false
		return true


	func _wait_for_charged_window(at: Vector2, label: String) -> bool:
		var surge := world.get_node_or_null(^"StormwoodSurge")
		var started := Time.get_ticks_msec()
		_begin_phase("%s charged-window wait" % label, at)
		print("STORMWOOD CONTINUOUS — DIAGNOSTIC: START %s" % _active_phase)
		while surge != null and Time.get_ticks_msec() - started < BREAK_WAIT_MS:
			var state := _charged_window_snapshot(at)
			if float(state.get("open_seconds", 0.0)) >= MIN_CHARGED_ROUTE_SECONDS:
				print("STORMWOOD CONTINUOUS — DIAGNOSTIC: END %s elapsed_ms=%d state=%s" % [
					_active_phase, Time.get_ticks_msec() - started, str(state)])
				_end_phase()
				return true
			await tree.physics_frame
		_fail("%s did not reach a Break/Fading window with %.1f simulation seconds remaining (last=%s)" % [
			label, MIN_CHARGED_ROUTE_SECONDS, str(_charged_window_snapshot(at))])
		return false


	func _charged_window_snapshot(at: Vector2) -> Dictionary:
		var surge := world.get_node_or_null(^"StormwoodSurge")
		if surge == null:
			return {}
		var environment: Dictionary = game.get("realm_environment")
		var saved: Variant = environment.get("stormwood", {})
		var raw_elapsed: Variant = saved.get("elapsed", 0.0) if saved is Dictionary else 0.0
		var elapsed := float(raw_elapsed) if raw_elapsed is float or raw_elapsed is int else 0.0
		var point := Vector3(at.x, world.call("ground_height_at", at.x, at.y), at.y)
		var region := str(surge.call("region_at", point))
		var rules: RefCounted = surge.get("rules") as RefCounted
		if rules == null:
			return {}
		var config: Dictionary = rules.get("config")
		var region_row: Dictionary = config.get("regions", {}).get(region, {})
		var rod_flag := str(region_row.get("rod_flag", ""))
		var flags: RefCounted = game.get("progression") as RefCounted
		var rod_disabled := not rod_flag.is_empty() and bool(flags.call("has", rod_flag))
		var aftermath := bool(flags.call("has", "stormwood:long_storm_ended"))
		var current: Dictionary = rules.call("phase_at", elapsed, region, rod_disabled, aftermath)
		var next: Dictionary = {}
		if str(current.get("phase", "")) == "break":
			next = rules.call("phase_at",
				elapsed + float(current.get("remaining", 0.0)) + 0.001,
				region, rod_disabled, aftermath)
		return {
			"phase": str(current.get("phase", "")),
			"remaining": float(current.get("remaining", 0.0)),
			"next_phase": str(next.get("phase", "")),
			"next_remaining": float(next.get("remaining", 0.0)),
			"open_seconds": open_window_seconds(current, next),
			"elapsed": elapsed,
			"rod_disabled": rod_disabled,
			"aftermath": aftermath,
		}


	static func open_window_seconds(current: Dictionary, next: Dictionary = {}) -> float:
		var phase := str(current.get("phase", ""))
		var remaining := maxf(0.0, float(current.get("remaining", 0.0)))
		if phase == "fading":
			return remaining
		if phase != "break":
			return 0.0
		if str(next.get("phase", "")) == "fading":
			return remaining + maxf(0.0, float(next.get("remaining", 0.0)))
		return remaining


	func _harvest_charged_node(node: Node3D, id: String) -> bool:
		var inventory: RefCounted = game.get("inventory") as RefCounted
		var pickaxe_slot := int(inventory.call("find_slot", "pickaxe"))
		var count_before := int(inventory.call("count", "stormglass"))
		var wear_before := int(inventory.call("durability_at", pickaxe_slot)) \
			if pickaxe_slot >= 0 else -1
		var at := Vector2(node.global_position.x, node.global_position.z)
		if not await _activate_node(node, node.get_node_or_null(^"Interactable") as Node3D,
				at, id):
			return false
		var receipt := "harvest_node:order:" + id
		for _frame in 600:
			if bool(game.get("progression").call("has", receipt)) \
					and int(inventory.call("count", "stormglass")) > count_before:
				break
			await tree.physics_frame
		var gained := int(inventory.call("count", "stormglass")) - count_before
		var wear_after := int(inventory.call("durability_at", pickaxe_slot)) \
			if pickaxe_slot >= 0 else -1
		if gained != 3 or not bool(game.get("progression").call("has", receipt)) \
				or wear_after != wear_before - 1:
			_fail("%s did not settle its exact receipt/yield/wear (gained=%d receipt=%s wear=%d->%d weather=%s)" % [
				id, gained, str(bool(game.get("progression").call("has", receipt))),
				wear_before, wear_after, str(_charged_window_snapshot(at))])
			return false
		_note("GATHERED %s exact +3 Stormglass receipt with one pickaxe wear" % id)
		return true


	func _relight_arch(id: String, stance: Vector2, earned_flag: String) -> bool:
		var arch := world.get_node_or_null(NodePath("StormglassArches/" + id)) as Node3D
		var prompt := arch.get_node_or_null(^"Relight") as Node3D if arch != null else null
		if arch == null or prompt == null:
			_fail("ancient arch %s or its production relight prompt is absent" % id)
			return false
		if not await _activate_node(arch, prompt, stance, "%s relight" % id):
			return false
		var lit_flag := "stormwood:arch:%s:lit" % id
		if not await _wait_flag(lit_flag, 300):
			_fail("%s prompt accepted but did not commit %s" % [id, lit_flag])
			return false
		if not earned_flag.is_empty() and not await _wait_flag(earned_flag, 300):
			_fail("%s relight did not advance the chapter to %s" % [id, earned_flag])
			return false
		return true


	func _walk_arch_threshold(point: Vector2, earned_flag: String, label: String) -> bool:
		var target := Vector3(point.x, world.call("ground_height_at", point.x, point.y), point.y)
		navigator.call("reset")
		for _frame in 1800:
			if bool(game.get("progression").call("has", earned_flag)):
				_send_stick.call(0.0, 0.0)
				return true
			if bool(navigator.call("can_walk")):
				await navigator.call("step", target)
			elif bool(manager.call("is_fighting")):
				if not await _fight_current_encounter(label):
					return false
				navigator.call("reset")
			else:
				_send_stick.call(0.0, 0.0)
				await tree.physics_frame
		_send_stick.call(0.0, 0.0)
		return false


	func _talk_to(node_name: String, stance: Vector2, earned_flag: String,
			label: String) -> bool:
		var people := world.get_node_or_null(^"StormwoodPeople")
		var actor := people.get_node_or_null(NodePath(node_name)) as Node3D if people != null else null
		var prompt := actor.get_node_or_null(^"Interactable") as Node3D if actor != null else null
		if actor == null or prompt == null:
			_fail("%s has no production actor/prompt" % label)
			return false
		if not await _activate_node(actor, prompt, stance, label):
			return false
		if not await _drain_dialogue(label):
			return false
		if not earned_flag.is_empty() and not await _wait_flag(earned_flag, 180):
			_fail("%s completed without earning %s" % [label, earned_flag])
			return false
		return true


	func _drain_dialogue(label: String) -> bool:
		var panel := world.get_node_or_null(^"DialoguePanel")
		for _frame in 180:
			if panel != null and bool(panel.call("is_open")):
				break
			await tree.physics_frame
		if panel == null or not bool(panel.call("is_open")):
			_fail("%s did not open the production dialogue panel" % label)
			return false
		for _line in 64:
			if not bool(panel.call("is_open")):
				break
			await _tap(&"interact")
		if bool(panel.call("is_open")):
			_fail("%s did not finish through ordinary interact presses" % label)
			return false
		return true


	func _activate_node(body: Node3D, prompt: Node3D, preferred: Vector2,
			label: String) -> bool:
		if prompt == null:
			_fail("%s has no interaction prompt" % label)
			return false
		var candidates: Array[Vector2] = [
			preferred,
			Vector2(prompt.global_position.x, prompt.global_position.z) + Vector2(0.0, -1.05),
			Vector2(prompt.global_position.x, prompt.global_position.z) + Vector2(1.05, 0.0),
			Vector2(prompt.global_position.x, prompt.global_position.z) + Vector2(0.0, 1.05),
			Vector2(prompt.global_position.x, prompt.global_position.z) + Vector2(-1.05, 0.0),
		]
		for stance: Vector2 in candidates:
			if not await _walk_xz(stance, "%s stance" % label, 0.7, false):
				continue
			var held := 0
			for _frame in 180:
				if arbiter.call("winning_provider") == prompt:
					held += 1
					if held < 8:
						await tree.physics_frame
						continue
					_activated_provider_id = 0
					_activated_provider_path = ""
					var observer := Callable(self, "_on_arbiter_activated")
					arbiter.connect("activated", observer)
					var wanted_id := prompt.get_instance_id()
					await _tap(&"interact")
					arbiter.disconnect("activated", observer)
					if _activated_provider_id == wanted_id:
						return true
					if _activated_provider_id != 0:
						# A roaming wild can enter engage range after this prompt has
						# held the arbiter for eight frames but before the physical
						# button edge is recomputed. The arbiter then truthfully fires
						# EncounterDirector, which synchronously starts that ordinary
						# fight. Resolve only that exact production effect and approach
						# again; every other competitor remains a hard failure, and this
						# never counts as activating the requested provider.
						if _activated_provider_id == director.get_instance_id() \
								and bool(manager.call("is_fighting")):
							_note("ANSWERED a roaming wild that won the button edge before %s" % label)
							if not await _fight_current_encounter("%s competing wild" % label):
								return false
							if not await _ensure_usable_ally("retrying %s" % label):
								return false
							break
						_fail("%s press activated competing provider %s#%d" % [
							label, _activated_provider_path, _activated_provider_id])
						return false
					# Production recomputes at the button edge. A pre-press winner can
					# therefore legitimately become NONE; approach again, never claim
					# that the requested provider fired from the stale snapshot.
					break
				else:
					held = 0
				await tree.physics_frame
		var winner := arbiter.call("winning_provider") as Node
		_fail("%s never won the live InteractionArbiter (target=%s#%d winner=%s#%d offer=%s body_distance=%.2f prompt_distance=%.2f)" % [
			label, str(prompt.get_path()), prompt.get_instance_id(),
			str(winner.get_path()) if winner != null else "<null>",
			winner.get_instance_id() if winner != null else 0, str(arbiter.call("winner")),
			player.global_position.distance_to(body.global_position),
			player.global_position.distance_to(prompt.global_position)])
		return false


	func _on_arbiter_activated(provider: Object) -> void:
		if provider == null:
			return
		_activated_provider_id = provider.get_instance_id()
		_activated_provider_path = str((provider as Node).get_path()) \
			if provider is Node else str(provider)


	func _walk_route(id: String, through_index: int, label: String) -> bool:
		var routes: Array = world.call("config_data").get("routes", [])
		for route: Dictionary in routes:
			if str(route.get("id", "")) != id:
				continue
			var points: Array = route.get("points", [])
			if through_index < 1 or points.size() <= through_index:
				_fail("authored route %s has %d points; requested through index %d" % [
					id, points.size(), through_index])
				return false
			var last := mini(through_index, points.size() - 1)
			for index in range(1, last + 1):
				var raw: Array = points[index]
				if not await _walk_xz(Vector2(float(raw[0]), float(raw[1])),
						"%s leg %d" % [label, index], 2.0):
					return false
			return true
		_fail("authored route %s is absent" % id)
		return false


	func _walk_xz(point: Vector2, label: String, tolerance: float = 1.3,
			record_failure: bool = true) -> bool:
		var target := Vector3(point.x, world.call("ground_height_at", point.x, point.y), point.y)
		var distance := Vector2(player.global_position.x, player.global_position.z).distance_to(point)
		var budget := maxi(1800, int(distance * 80.0))
		_begin_phase("walk to %s" % label, point)
		_active_walk_budget = budget
		print("STORMWOOD CONTINUOUS — DIAGNOSTIC: START %s from=%s target=%s distance_m=%.1f budget_frames=%d" % [
			_active_phase, str(player.global_position), str(target), distance, budget])
		navigator.call("reset")
		var walked := 0
		var held := 0
		var arrived := false
		while walked < budget:
			_active_walked = walked
			var remaining := Vector2(player.global_position.x, player.global_position.z).distance_to(point)
			if remaining <= tolerance:
				arrived = true
				break
			if bool(navigator.call("can_walk")):
				walked += 1
				held = 0
				await navigator.call("step", target)
				continue
			_send_stick.call(0.0, 0.0)
			if bool(manager.call("is_fighting")):
				if not await _fight_current_encounter(label):
					return false
				navigator.call("reset")
				continue
			held += 1
			if held > 36000:
				break
			await tree.physics_frame
		_send_stick.call(0.0, 0.0)
		if not arrived:
			if record_failure:
				_fail("ordinary locomotion could not reach %s (%.1fm remain; player=%s target=%s)" % [
					label, player.global_position.distance_to(target), str(player.global_position), str(target)])
			return false
		print("STORMWOOD CONTINUOUS — DIAGNOSTIC: END %s elapsed_ms=%d walked_frames=%d player=%s" % [
			_active_phase, Time.get_ticks_msec() - _active_phase_started_ms, walked,
			str(player.global_position)])
		_end_phase()
		return true


	func _begin_phase(label: String, target: Vector2 = Vector2.ZERO) -> void:
		_active_phase = label
		_active_phase_started_ms = Time.get_ticks_msec()
		_active_target = target
		_active_target_valid = true
		_active_walk_budget = 0
		_active_walked = 0


	func _end_phase() -> void:
		_active_phase = "between route steps"
		_active_phase_started_ms = Time.get_ticks_msec()
		_active_target_valid = false
		_active_walk_budget = 0
		_active_walked = 0


	func diagnostic_snapshot() -> String:
		var parts: Array[String] = [
			"phase=%s" % _active_phase,
			"phase_elapsed_ms=%d" % (Time.get_ticks_msec() - _active_phase_started_ms),
		]
		if is_instance_valid(player):
			parts.append("player=%s" % str(player.global_position))
			if _active_target_valid:
				var here := Vector2(player.global_position.x, player.global_position.z)
				parts.append("target=%s" % str(_active_target))
				parts.append("remaining_m=%.1f" % here.distance_to(_active_target))
		if _active_walk_budget > 0:
			parts.append("walked_frames=%d/%d" % [_active_walked, _active_walk_budget])
		if is_instance_valid(manager):
			parts.append("fighting=%s" % str(bool(manager.call("is_fighting"))))
		if is_instance_valid(navigator):
			parts.append("can_walk=%s" % str(bool(navigator.call("can_walk"))))
		return ", ".join(parts)


	## Ordinary locomotion can be interrupted by the production wild population.
	## A continuous route must answer that encounter rather than waiting forever
	## for exploration to restore itself. Every strike below is an Input action;
	## no HP, manager state, reward, or encounter flag is written by the harness.
	func _fight_current_encounter(route_label: String) -> bool:
		var started := Time.get_ticks_msec()
		var tick := 0
		_last_combat_outcome = ""
		var next_quick_ms := 0
		var quick_release_tick := -1
		while bool(manager.call("is_fighting")) and Time.get_ticks_msec() - started < 180000:
			var enemy := manager.call("enemy_body") as Node3D
			var ally := director.call("ally_body") as Node3D
			if is_instance_valid(enemy) and is_instance_valid(ally):
				ally.call("face_towards", enemy.global_position)
				var offset := enemy.global_position - ally.global_position
				offset.y = 0.0
				_send_stick.call(0.0, 0.0)
				if offset.length() > float(manager.call("combat_move_reach", "quick")) * 0.8:
					var local: Vector3 = camera.call("planar_basis").inverse() * offset.normalized()
					_send_stick.call(local.x, local.z)
				if quick_release_tick >= 0 and tick >= quick_release_tick:
					_set_action(&"combat_quick", false)
					quick_release_tick = -1
				if Time.get_ticks_msec() >= next_quick_ms and bool(manager.call("quick_ready")):
					_set_action(&"combat_quick", true)
					quick_release_tick = tick + 2
					# Stormwood's host authority uses an unscaled wall-clock cooldown.
					# The wrapper accelerates weather and locomotion at 480Hz, so keep
					# controller presses at an ordinary human cadence instead of sending
					# twenty-four inputs per wall-clock second.
					next_quick_ms = Time.get_ticks_msec() + 900
			tick += 1
			await tree.physics_frame
		_set_action(&"combat_quick", false)
		_send_stick.call(0.0, 0.0)
		if bool(manager.call("is_fighting")):
			_fail("production encounter during %s did not resolve through controller combat within 180 seconds" % route_label)
			return false
		if _last_combat_outcome.is_empty():
			_fail("production encounter during %s ended without publishing its combat outcome" % route_label)
			return false
		_note("RESOLVED live combat through controller input during %s (outcome=%s)" % [
			route_label, _last_combat_outcome])
		return true


	func _equip_fixture_tool(item_id: String) -> bool:
		var slot := int(game.call("hotbar_slot_of", item_id))
		if slot < 0:
			_fail("completed-Cloudreach fixture has no %s on its hotbar" % item_id)
			return false
		await _tap(StringName("hotbar_%d" % (slot + 1)))
		for _frame in 60:
			if str(game.get("equipped_tool")) == item_id:
				return true
			await tree.physics_frame
		_fail("ordinary hotbar input did not equip %s" % item_id)
		return false


	func _wait_flag(id: String, frames: int) -> bool:
		for _frame in frames:
			if bool(game.get("progression").call("has", id)):
				return true
			await tree.physics_frame
		return false


	func _tap(action: StringName) -> void:
		var down := InputEventAction.new()
		down.action = action
		down.pressed = true
		down.strength = 1.0
		Input.parse_input_event(down)
		await tree.process_frame
		for _frame in 4:
			await tree.physics_frame
		var up := InputEventAction.new()
		up.action = action
		up.pressed = false
		up.strength = 0.0
		Input.parse_input_event(up)
		await tree.process_frame
		for _frame in 8:
			await tree.physics_frame


	func _set_action(action: StringName, pressed: bool) -> void:
		var event := InputEventAction.new()
		event.action = action
		event.pressed = pressed
		event.strength = 1.0 if pressed else 0.0
		Input.parse_input_event(event)


	func _send_stick(x: float, y: float) -> void:
		_send_axis(JOY_AXIS_LEFT_X, x)
		_send_axis(JOY_AXIS_LEFT_Y, y)


	func _send_axis(axis: JoyAxis, value: float) -> void:
		var event := InputEventJoypadMotion.new()
		event.device = 0
		event.axis = axis
		event.axis_value = clampf(value, -1.0, 1.0)
		Input.parse_input_event(event)


	func _note(line: String) -> void:
		transcript.append(line)
		print("STORMWOOD CONTINUOUS — CHECKPOINT: ", line)


	func _fail(line: String) -> void:
		failures.append(line)
		push_error("STORMWOOD CONTINUOUS SEGMENT: " + line)


	func _result() -> Dictionary:
		return {"passed": failures.is_empty(), "failures": failures.duplicate(),
			"transcript": transcript.duplicate(), "world": world, "game": game,
			"player": player}
