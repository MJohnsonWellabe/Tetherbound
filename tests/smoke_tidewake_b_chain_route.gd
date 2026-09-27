extends SceneTree

## F13#3 normal-play route witness: all six Tidewake local chains played in ONE
## production Water world (scenes/world/water_archipelago.tscn), in sequence,
## by one character, with real input for every step.
##
## Real input: the trainer walks with real left-stick events only
## (tests/helpers/stick_navigator.gd over a harness A* route planned on the
## BAKED ground, reusing smoke_water_pocket_walk_claim.gd's plan_route), stops
## when the production interaction arbiter's winning provider is the step's own
## prompt (NPC "Greet" prompt, local-chain site prompt, pickup/seam
## Interactable, dock chart control), and presses the ordinary `interact`
## action. Conversations are opened by that press and every line is advanced by
## further `interact` presses read by the production DialoguePanel. The seam's
## pickaxe is equipped by the real `hotbar_N` action.
##
## DISCLOSED FIXTURES (everything not done by input):
##  * Position writes: whenever the next target is on a different island than
##    the trainer, the trainer is placed on that island's authored arrival
##    landing (`anchors[kind=arrival].safe_position`); inter-island swims are
##    not traversed. First Shore has no arrival anchor: Lantern's first leg
##    walks from the world's own start spawn (no write on the first leg; a
##    later return to First Shore re-places the trainer on that spawn). Every
##    write is printed as `POSE ...`. Deep Watch's Tidecoil stand is one extra
##    write.
##  * Where the baked-ground planner finds no dry cell route (NPCs standing on
##    dock decks over water), the walk is one straight left-stick leg steered
##    by the navigator, printed as `WALK <label> DIRECT`.
##  * Messages are read from the player-visible HUD message strip
##    (playground_hud.gd `_hotbar_message`), which consumes Game's queue.
##  * Upstream story facts pre-set before the world loads (world flags
##    water_swim_lesson_complete, water_dock_reedhaven_repaired,
##    water_dock_brine_steps_trial_won, water_aquaryn_resolved,
##    water_dock_salt_crown_landing_charted; character flags
##    water_swim_lesson_briefed, water_swim_stone_earned) -- the same upstream
##    facts the six per-chain smokes pre-set.
##  * Carried pickaxe on hotbar slot 1 (added before load).
##  * Tidecoil fight not played: its resident named body is marked engaged and
##    the director's production won-fight handler `_on_combat_exited("won")`
##    is invoked (as smoke_water_deep_watch_chart.gd does).
##  * Lastlight materials: 4 driftwood + 4 reed fiber added to the satchel just
##    before the walk to the delivery prompt (not gathered).
##  * Lastlight rest: after walking to the Veilfall camp bed, the production
##    bed's `assign_creature(0)` is called (bed panel UI not driven); a
##    Brooktail is spawned into the party only if the reset party is empty.
## Saved completion: after all six, one production Game.save_game ->
## reset_for_new_game -> Game.load_game -> rebuilt Water world
## (tests/helpers/water_chain_reload.gd), then every chain's records, receipts,
## rewards and quest-log `done` are re-asserted and each requester is greeted
## again by a real walk + Interact to hear the acknowledgement, not a re-offer.
## Solo host only.
## `-- --only=lantern,gull,cradle,garden,deep,lastlight` selects chains; the
## PROOF run used one process per chain (each: own world, own save/reload).
##   godot --headless --path . --script tests/smoke_tidewake_b_chain_route.gd [-- --only=<chain>]
const WORLD := preload("res://scenes/world/water_archipelago.tscn")
const NAV := preload("res://tests/helpers/stick_navigator.gd")
const POCKET := preload("res://tests/smoke_water_pocket_walk_claim.gd")
const FIELD := preload("res://scripts/world/water_heightfield.gd")
const QUEST_LOG := preload("res://scripts/world/quest_log.gd")
const RELOAD := preload("res://tests/helpers/water_chain_reload.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const CHARACTER := "tidewake-b-chain-route"

var game: Node
var world: Node3D
var player: CharacterBody3D
var camera: Node3D
var arbiter: Node
var navigator: RefCounted
var field := FIELD.new()
var config: Dictionary
var pickups_data: Dictionary
var reader: RefCounted
var checks := 0
var failures: Array[String] = []
var finished := false
var poses: Array[String] = []
var walked_total := 0.0
var summary: Array[String] = []
var spawn := Vector3.INF
var only: PackedStringArray = []
## `--continuous`: inter-island legs are SWUM with real `move_forward` input
## along the authored water_routes polylines instead of position writes, the
## Lastlight materials are gathered from production harvest rows by walk +
## Interact, and the Lastlight rest goes through the bed's real prompt and
## rest panel. See CONTINUOUS MODE below.
var continuous := false
const CHAINS := ["lantern", "gull", "cradle", "garden", "deep", "lastlight"]
const CHECKPOINT_SLOT := 20
const SAVE_GAME := preload("res://scripts/save/save_game.gd")
var save_dir := ""
var resume_from := ""
var swimming: Node
var swims: Array[String] = []


func _on(chain: String) -> bool:
	return only.is_empty() or only.has(chain)


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var watchdog := 7200.0 if OS.get_cmdline_user_args().has("--continuous") else 2400.0
	create_timer(watchdog).timeout.connect(func() -> void:
		if not finished:
			_check(false, "%d second watchdog expired" % int(watchdog))
			_finish())
	game = root.get_node("Game")
	game.reset_for_new_game()
	game.current_realm = "water"
	game.local.character_id = CHARACTER
	RELOAD.isolate(game, "tidewake_b_chain_route")
	# Checkpoints (continuous debugging aid): `--save-dir=<dir>` keeps the
	# production SaveGame in a stable directory; after each chain the run saves
	# through Game.save_game(CHECKPOINT_SLOT + chain index). `--resume-from=<chain>`
	# loads the checkpoint written after the previous chain through
	# Game.load_game and runs from <chain> on. A resumed run is a DRY RUN: it is
	# never the closing proof, which must be one uninterrupted run.
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--save-dir="):
			save_dir = argument.trim_prefix("--save-dir=")
		elif argument.begins_with("--resume-from="):
			resume_from = argument.trim_prefix("--resume-from=")
	if save_dir != "":
		game.save_system = SAVE_GAME.new(save_dir.trim_suffix("/") + "/")
	for upstream: String in ["water_swim_lesson_complete", "water_dock_reedhaven_repaired",
			"water_dock_brine_steps_trial_won", "water_aquaryn_resolved", "water_dock_salt_crown_landing_charted"]:
		game.world.flags.set_flag(upstream)
	for upstream: String in ["water_swim_lesson_briefed", "water_swim_stone_earned"]:
		game.local.flags.set_flag(upstream)
	if game.inventory.add("pickaxe", 1) != 0 or not game.assign_hotbar(0, "pickaxe"):
		_check(false, "could not create the disclosed carried pickaxe fixture")
		_finish()
		return
	continuous = OS.get_cmdline_user_args().has("--continuous")
	if continuous:
		# DISCLOSED (continuous): the two remaining main-route departure facts
		# the swim chain crosses, and a carried axe for the driftwood rows.
		for upstream: String in ["water_dock_shellwatch_residents_freed_and_pump_disabled",
				"water_dock_sluice_isle_both_controls_disabled"]:
			game.world.flags.set_flag(upstream)
		# DISCLOSED (continuous): the retained five at the Tidewake band level
		# (same fixture as smoke_water_pocket_walk_claim.gd --real-tidecoil).
		game.local.party.clear()
		for species: String in ["terrapup", "bramblebun", "mudsnout", "pipwing", "trailpup"]:
			var creature: RefCounted = SPECIES.spawn(species)
			creature.set_level(43, PROGRESSION.config())
			game.local.party.add(creature)
		if game.inventory.add("axe", 1) != 0 or not game.assign_hotbar(1, "axe"):
			_check(false, "could not create the disclosed carried axe fixture")
			_finish()
			return
	pickups_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_pickups.json"))
	reader = QUEST_LOG.new()
	reader.set_realm("water")
	if resume_from != "":
		var index := CHAINS.find(resume_from)
		if not _check(index > 0 and save_dir != "", "--resume-from needs a later chain and --save-dir"):
			_finish()
			return
		var loaded := bool(game.load_game(CHECKPOINT_SLOT + index - 1))
		print("DRY RUN: resumed from checkpoint slot %d (after %s) loaded=%s" % [CHECKPOINT_SLOT + index - 1, CHAINS[index - 1], loaded])
		if not _check(loaded, "checkpoint loaded"):
			_finish()
			return
		only = PackedStringArray(CHAINS.slice(index))
	if not await _build_world(WORLD.instantiate()):
		return
	await _frames(30)
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--only="):
			only = argument.trim_prefix("--only=").split(",")
	for index in CHAINS.size():
		var chain: String = CHAINS[index]
		if not _on(chain):
			continue
		match chain:
			"lantern": summary.append(await _lantern())
			"gull": summary.append(await _gull())
			"cradle": summary.append(await _cradle())
			"garden": summary.append(await _garden())
			"deep": summary.append(await _deep_watch())
			"lastlight": summary.append(await _lastlight())
		print(summary[-1])
		if save_dir != "":
			var saved := bool(game.save_game(CHECKPOINT_SLOT + index))
			print("CHECKPOINT slot=%d after %s saved=%s at %s" % [CHECKPOINT_SLOT + index, chain, saved, player.global_position])
	await _reload_leg()
	_finish()


func _build_world(fresh: Node3D) -> bool:
	world = fresh
	if world.get_parent() == null:
		root.add_child(world)
		current_scene = world
	for _frame in 1200:
		await physics_frame
		if bool(world.call("shell_build_complete")):
			break
	if not _check(bool(world.call("shell_build_complete")), "Production Water world built"):
		_finish()
		return false
	player = world.get_node("Player")
	camera = world.get_node("CameraRig")
	arbiter = get_first_node_in_group("interaction_arbiter")
	config = world.get("config")
	navigator = NAV.new(self, player, camera, _stick)
	swimming = player.get("swim_controller")
	if not spawn.is_finite():
		spawn = player.global_position
	return _check(arbiter != null, "production interaction arbiter present")


# ---------------------------------------------------------------- chains

func _lantern() -> String:
	var lead := "water_claim:local:lantern_return:lead"
	var done := "water_claim:local:lantern_return:complete"
	var cache := "water:lantern_cove:pickup:002"
	var heard: Array = await _talk("water_pell")
	_check(heard[0] == "water_pell_lantern_lead", "Lantern: Pell gives the lead (%s)" % heard[0])
	_check(game.world.flags.has(lead), "Lantern: lead recorded")
	_check(str(heard[2]).contains("Lantern Cove"), "Lantern: lead message shown: " + str(heard[2]))
	var candy_before: int = game.inventory.count("skill_candy_i")
	var claimed := await _claim_pickup(cache, 1)
	_check(claimed, "Lantern: cache claimed by walk + Interact")
	_check(game.world.flags.has("water_claim:%s:%s" % [CHARACTER, cache]), "Lantern: per-character cache receipt")
	heard = await _talk("water_pell")
	_check(heard[0] == "water_pell_lantern_return", "Lantern: Pell hears the return (%s)" % heard[0])
	_check(game.world.flags.has(done), "Lantern: completion recorded")
	heard = await _talk("water_pell")
	_check(heard[0] == "water_pell_lantern_thanks", "Lantern: acknowledgement (%s)" % heard[0])
	var ok: bool = game.world.flags.has(done) and heard[0] == "water_pell_lantern_thanks" \
		and game.inventory.count("skill_candy_i") == candy_before + 1 and _entry_done("Lantern Cove")
	_check(_entry_done("Lantern Cove"), "Lantern: quest log done")
	return "CHAIN side_water_lantern_return %s reward=Candy I +%d ack=%s" % [
		"PASS" if ok else "FAIL", game.inventory.count("skill_candy_i") - candy_before, heard[0]]


func _gull() -> String:
	var lead := "water_claim:local:gull_research:lead"
	var satchel := "water_claim:local:gull_research:satchel"
	var done := "water_claim:local:gull_research:complete"
	var candy := "water:gull_rest:pickup:002"
	var heard: Array = await _talk("water_adair")
	_check(heard[0] == "water_adair_gull_lead", "Gull: Adair gives the lead (%s)" % heard[0])
	_check(game.world.flags.has(lead), "Gull: lead recorded")
	var message := await _use_site("gull_research_satchel")
	_check(game.world.flags.has(satchel), "Gull: satchel recorded by walk + Interact")
	_check(message.contains("Brine Steps"), "Gull: satchel message points home: " + message)
	var before: int = game.inventory.count("skill_candy_ii")
	_check(await _claim_pickup(candy, 1), "Gull: Candy II claimed by walk + Interact")
	_check(game.local.flags.has("water_candy:" + candy), "Gull: personal Candy II receipt")
	heard = await _talk("water_adair")
	_check(heard[0] == "water_adair_gull_return", "Gull: Adair takes the observations (%s)" % heard[0])
	_check(game.world.flags.has(done), "Gull: completion recorded")
	heard = await _talk("water_adair")
	_check(heard[0] == "water_adair_gull_thanks", "Gull: acknowledgement (%s)" % heard[0])
	_check(_entry_done("Gull Rest"), "Gull: quest log done")
	var ok: bool = game.world.flags.has(done) and heard[0] == "water_adair_gull_thanks" \
		and game.inventory.count("skill_candy_ii") == before + 1 and _entry_done("Gull Rest")
	return "CHAIN side_water_gull_research %s reward=Candy II +%d ack=%s" % [
		"PASS" if ok else "FAIL", game.inventory.count("skill_candy_ii") - before, heard[0]]


func _cradle() -> String:
	var lead := "water_claim:local:cradle_care:lead"
	var done := "water_claim:local:cradle_care:complete"
	var seam_row := "water:tidal_cradle:harvest:007"
	var seam_flag := "harvest_node:order:water:tidal_cradle:harvest:007"
	var heard: Array = await _talk("water_otto")
	_check(heard[0] == "water_otto_nest_lead", "Cradle: Otto gives the lead (%s)" % heard[0])
	_check(game.world.flags.has(lead), "Cradle: lead recorded")
	var stone_before: int = game.inventory.count("reef_stone")
	var berries_before: int = game.inventory.count("berries")
	_check(await _mine_seam(seam_row), "Cradle: Reef Stone seam mined by walk + hotbar pickaxe + Interact")
	_check(game.inventory.count("reef_stone") == stone_before + 4, "Cradle: nest paid 4 Reef Stone (%d)" % (game.inventory.count("reef_stone") - stone_before))
	_check(game.world.flags.has(seam_flag), "Cradle: seam recorded world-once")
	heard = await _talk("water_otto")
	_check(heard[0] == "water_otto_nest_return", "Cradle: Otto takes the report (%s)" % heard[0])
	_check(game.world.flags.has(done), "Cradle: completion recorded")
	_check(game.inventory.count("berries") == berries_before + 3, "Cradle: return pays exactly 3 berries")
	heard = await _talk("water_otto")
	_check(heard[0] == "water_otto_nest_thanks", "Cradle: acknowledgement (%s)" % heard[0])
	_check(_entry_done("shell nest"), "Cradle: quest log done")
	var ok: bool = game.world.flags.has(done) and heard[0] == "water_otto_nest_thanks" \
		and game.inventory.count("berries") == berries_before + 3 and _entry_done("shell nest")
	return "CHAIN side_water_cradle_care %s reward=berries +%d reef_stone +%d ack=%s" % [
		"PASS" if ok else "FAIL", game.inventory.count("berries") - berries_before,
		game.inventory.count("reef_stone") - stone_before, heard[0]]


func _garden() -> String:
	var lead := "water_claim:local:garden_records:lead"
	var account := "water_claim:local:garden_records:account"
	var done := "water_claim:local:garden_records:complete"
	var candy := "water:drowned_garden:pickup:002"
	var heard: Array = await _talk("water_edda")
	_check(heard[0] == "water_edda_garden_lead", "Garden: Edda gives the lead (%s)" % heard[0])
	_check(game.world.flags.has(lead), "Garden: lead recorded")
	var message := await _use_site("garden_records_wall")
	_check(game.world.flags.has(account), "Garden: wall account recorded by walk + Interact")
	_check(message.contains("Edda"), "Garden: account message points home: " + message)
	var before: int = game.inventory.count("skill_candy_ii")
	_check(await _claim_pickup(candy, 1), "Garden: Candy II claimed by walk + Interact")
	heard = await _talk("water_edda")
	_check(heard[0] == "water_edda_garden_return", "Garden: Edda hears the account (%s)" % heard[0])
	_check(game.world.flags.has(done), "Garden: completion recorded")
	_check(str(heard[1]).contains("Tether"), "Garden: Edda explains pre-Tether dock history")
	heard = await _talk("water_edda")
	var ack := str(heard[0])
	_check(ack != "water_edda_garden_lead" and ack != "water_edda_garden_return" and ack != "", "Garden: after completion no re-offer (%s)" % ack)
	_check(_entry_done("Drowned Garden"), "Garden: quest log done")
	var ok: bool = game.world.flags.has(done) and game.inventory.count("skill_candy_ii") == before + 1 and _entry_done("Drowned Garden")
	return "CHAIN side_water_garden_records %s reward=Candy II +%d ack=return:%s after=%s" % [
		"PASS" if ok else "FAIL", game.inventory.count("skill_candy_ii") - before, "water_edda_garden_return", ack]


func _deep_watch() -> String:
	var resolved := "water_named_deep_watch_tidecoil_resolved"
	var charted := "water_dock_deep_watch_current_charted"
	var gated := "water:deep_watch:pickup:002"
	var heard: Array = await _talk("water_orsen")
	_check(heard[0] == "water_orsen_pre", "Deep Watch: Orsen's Sluice conversation (%s)" % heard[0])
	_check(str(heard[1]).contains("Deep Watch") and str(heard[1]).contains("Tidecoil"), "Deep Watch: Orsen names Deep Watch and Tidecoil")
	if continuous:
		# Real fight: tests/helpers/tidewake_b_tidecoil_fight.gd (walk to the
		# reef shore, deploy by creature_recall, engage, win with the shared
		# campaign pilot; the director's own won terminal writes the flag).
		var here := _island(player.global_position)
		if here != "deep_watch":
			_check(await _swim_between(here, "deep_watch", "Tidecoil"), "Deep Watch: swam to Deep Watch for Tidecoil")
		var fight: Dictionary = await load("res://tests/helpers/tidewake_b_tidecoil_fight.gd").new().run(self, world)
		print("TIDECOIL ", fight)
		_check(bool(fight.get("won", false)), "Deep Watch: real Tidecoil fight won (%s)" % str(fight.get("step", "")))
		_stick(0.0, 0.0)
		await _frames(30)
		# Known stranding (helper note): after the win the trainer stands in
		# the shallows under Deep Watch's ~12 m cliff with no wading path up and
		# a swim back beyond level-0 stamina; the intended route rides an owned
		# swimmer, which this party does not have. DISCLOSED POSITION WRITE.
		var up: Dictionary = POCKET.plan_route(world, Vector2(player.global_position.x, player.global_position.z),
			Vector2(_landing("deep_watch").x, _landing("deep_watch").z))
		if (up.points as Array).is_empty() or (swimming != null and swimming.is_swimming()):
			_pose(_landing("deep_watch"), "deep_watch arrival landing after the Tidecoil win (stranded below the cliff)")
			await _frames(60)
	else:
		await _tidecoil_fixture()
	_check(game.world.flags.has(resolved), "Deep Watch: Tidecoil resolution recorded")
	heard = await _talk("water_orsen")
	_check(heard[0] == "water_orsen_deep_watch_chart_lead", "Deep Watch: Orsen gives the chart lead (%s)" % heard[0])
	return await _deep_watch_rest(charted, gated)


func _tidecoil_fixture() -> void:
	# DISCLOSED FIXTURE: Tidecoil's fight resolved through the director's handler.
	var director: Node = world.get_node("EncounterDirector")
	var site := Vector3(1483.196, -0.5075, 3427.917)
	var stand := Vector3.INF
	for distance: float in [30.0, 40.0, 50.0, 60.0, 70.0, 80.0]:
		var candidate := site + (Vector3(1350.0, 0.0, 3500.0) - site).normalized() * distance
		if float(world.ground_height_at(candidate.x, candidate.z)) >= 0.8:
			stand = candidate
			break
	if _check(stand.is_finite(), "Deep Watch: dry stand in Tidecoil's reach"):
		_pose(stand, "tidecoil stand (fight fixture)")
	var body: Node3D = null
	for _attempt in 180:
		await process_frame
		for wild: Variant in director.get("_wild_creatures"):
			if is_instance_valid(wild) and str((wild as Node).get_meta("water_named_encounter", "")) == "water_deep_watch_tidecoil":
				body = wild
		if body != null:
			break
	if _check(body != null, "Deep Watch: named Tidecoil body resident"):
		director.set("_engaged_with", body)
		director.call("_on_combat_exited", "won")
		await _frames(4)


func _deep_watch_rest(charted: String, gated: String) -> String:
	var heard: Array = ["", "", ""]
	var before: int = game.inventory.count("skill_candy_iii")
	_check(await _claim_pickup(gated, 1), "Deep Watch: Candy III cache claimed by walk + Interact")
	_check(game.local.flags.has("water_candy:" + gated), "Deep Watch: personal cache receipt")
	var chart: Node3D = world.get_node("WaterDocks").get_node_or_null("deep_watch_chart")
	var control: Node = null
	if chart != null:
		for child: Node in chart.get_children():
			if child.has_method("interaction_activate"):
				control = child
	if _check(control != null, "Deep Watch: chart control present"):
		await _go(chart.global_position, 2.0, "deep_watch_chart")
		_check(await _approach_prompt(control, chart.global_position), "Deep Watch: chart prompt offered (winner=%s)" % arbiter.call("prompt"))
		await _press_interact()
		await _frames(20)
	_check(game.world.flags.has(charted), "Deep Watch: chart recorded by walk + Interact")
	heard = await _talk("water_orsen")
	_check(heard[0] == "water_orsen_deep_watch_charted", "Deep Watch: acknowledgement (%s)" % heard[0])
	_check(_entry_done("Deep Watch"), "Deep Watch: quest log done")
	var ok: bool = game.world.flags.has(charted) and heard[0] == "water_orsen_deep_watch_charted" \
		and game.inventory.count("skill_candy_iii") == before + 1 and _entry_done("Deep Watch")
	return "CHAIN side_water_deep_watch_chart %s reward=Candy III +%d ack=%s" % [
		"PASS" if ok else "FAIL", game.inventory.count("skill_candy_iii") - before, heard[0]]


func _lastlight() -> String:
	var lead := "water_claim:local:lastlight_shelter:lead"
	var supplied := "water_claim:local:lastlight_shelter:supplied"
	var rested := "water_claim:local:lastlight_shelter:rested"
	var heard: Array = await _talk("water_halen")
	_check(heard[0] == "water_halen_shelter_lead", "Lastlight: Halen gives the lead (%s)" % heard[0])
	_check(game.world.flags.has(lead), "Lastlight: lead recorded")
	if continuous:
		# Gathered: reed patches on Veilfall (3) and Sluice Isle (3, swum to and
		# back), driftwood from two Veilfall rows with the carried axe (3 + 3).
		_check(await _gather_hand("water:veilfall:harvest:005"), "Lastlight: Veilfall reed gathered by walk + Interact")
		_check(await _mine_seam("water:veilfall:harvest:007"), "Lastlight: Veilfall driftwood 007 cut by walk + Interact")
		_check(await _mine_seam("water:veilfall:harvest:011"), "Lastlight: Veilfall driftwood 011 cut by walk + Interact")
		if game.inventory.count("reed_fiber") < 4:
			_check(await _gather_hand("water:sluice_isle:harvest:012"), "Lastlight: Sluice Isle reed gathered by walk + Interact")
		_check(game.inventory.count("driftwood") >= 4 and game.inventory.count("reed_fiber") >= 4,
			"Lastlight: gathered 4+ driftwood and 4+ reed (%d, %d)" % [game.inventory.count("driftwood"), game.inventory.count("reed_fiber")])
	else:
		# DISCLOSED FIXTURE: the delivered materials.
		_check(game.inventory.add("driftwood", 4) == 0 and game.inventory.add("reed_fiber", 4) == 0, "Lastlight: disclosed material fixture")
	var wood_before: int = game.inventory.count("driftwood")
	var reed_before: int = game.inventory.count("reed_fiber")
	var chains: Node = world.get_node("WaterLocalChains")
	var site: Node3D = chains.call("site_root", "lastlight_shelter_supply")
	var message := await _use_site("lastlight_shelter_supply")
	_check(game.world.flags.has(supplied), "Lastlight: delivery recorded by walk + Interact")
	_check(game.inventory.count("driftwood") == wood_before - 4 and game.inventory.count("reed_fiber") == reed_before - 4, "Lastlight: host debited 4 + 4")
	_check(message.contains("sheltered"), "Lastlight: delivery message: " + message)
	var built: Node3D = site.get_node_or_null("Built") if site != null else null
	_check(built != null and built.visible, "Lastlight: shelter piece stands")
	heard = await _talk("water_halen")
	_check(heard[0] == "water_halen_shelter_rest", "Lastlight: Halen asks for a rest (%s)" % heard[0])
	var bed: Node3D = world.get_node("WaterCamps").get_node_or_null("water_camp_veilfall_creature_bed")
	var rest_message := ""
	if _check(bed != null, "Lastlight: Veilfall camp bed exists"):
		await _go(bed.global_position, 2.0, "veilfall_creature_bed")
		if game.local.party.size() == 0:
			_check(game.local.party.add(SPECIES.spawn("brooktail")), "Lastlight: disclosed companion fixture")
		hud_seen = ""
		if continuous:
			await _rest_via_panel(bed)
		else:
			# DISCLOSED FIXTURE: production bed assignment called directly.
			_check(bool(bed.call("assign_creature", 0)), "Lastlight: production bed takes the companion")
		for _attempt in 120:
			await _frames(1)
			if game.world.flags.has(rested):
				break
		await _frames(10)
		rest_message = hud_seen
	_check(game.world.flags.has(rested), "Lastlight: rest recorded")
	_check(rest_message.contains("sheltered bed"), "Lastlight: rest message: " + rest_message)
	heard = await _talk("water_halen")
	_check(heard[0] == "water_halen_shelter_thanks", "Lastlight: acknowledgement (%s)" % heard[0])
	_check(_entry_done("Lastlight"), "Lastlight: quest log done")
	var ok: bool = game.world.flags.has(rested) and heard[0] == "water_halen_shelter_thanks" and _entry_done("Lastlight")
	return "CHAIN side_water_lastlight_shelter %s reward=shelter built=%s ack=%s" % [
		"PASS" if ok else "FAIL", built != null and built.visible, heard[0]]


const RELOAD_TABLE := {
	"lantern": {"world": ["water_claim:local:lantern_return:complete", "water_claim:%s:water:lantern_cove:pickup:002"],
		"local": [], "log": "Lantern Cove", "npc": "water_pell", "ack": "water_pell_lantern_thanks"},
	"gull": {"world": ["water_claim:local:gull_research:complete"], "local": ["water_candy:water:gull_rest:pickup:002"],
		"log": "Gull Rest", "npc": "water_adair", "ack": "water_adair_gull_thanks"},
	"cradle": {"world": ["water_claim:local:cradle_care:complete", "harvest_node:order:water:tidal_cradle:harvest:007"],
		"local": [], "log": "shell nest", "npc": "water_otto", "ack": "water_otto_nest_thanks"},
	"garden": {"world": ["water_claim:local:garden_records:complete"], "local": ["water_candy:water:drowned_garden:pickup:002"],
		"log": "Drowned Garden", "npc": "water_edda", "ack": ""},
	"deep": {"world": ["water_dock_deep_watch_current_charted", "water_named_deep_watch_tidecoil_resolved"],
		"local": ["water_candy:water:deep_watch:pickup:002"], "log": "Deep Watch", "npc": "water_orsen", "ack": "water_orsen_deep_watch_charted"},
	"lastlight": {"world": ["water_claim:local:lastlight_shelter:rested", "water_claim:local:lastlight_shelter:supplied"],
		"local": [], "log": "Lastlight", "npc": "water_halen", "ack": "water_halen_shelter_thanks"},
}


func _reload_leg() -> void:
	var items := {}
	for item: String in ["skill_candy_i", "skill_candy_ii", "skill_candy_iii", "berries", "reef_stone"]:
		items[item] = game.inventory.count(item)
	var probe := ""
	for chain: String in RELOAD_TABLE:
		if _on(chain):
			probe = str(RELOAD_TABLE[chain].world[0])
			break
	var reloaded: Dictionary = await RELOAD.save_and_reload(self, game, world, probe, "")
	for pair: Array in reloaded.checks:
		_check(pair[0], "Reload: " + str(pair[1]))
	if reloaded.world == null:
		return
	if not await _build_world(reloaded.world):
		return
	await _frames(30)
	for item: String in items:
		_check(game.inventory.count(item) == int(items[item]), "Reload keeps %s x%d (%d)" % [item, int(items[item]), game.inventory.count(item)])
	for chain: String in RELOAD_TABLE:
		if not _on(chain):
			continue
		var row: Dictionary = RELOAD_TABLE[chain]
		for raw: String in row.world:
			var flag := raw % CHARACTER if raw.contains("%s") else raw
			_check(game.world.flags.has(flag), "Reload keeps world record " + flag)
		for flag: String in row.local:
			_check(game.local.flags.has(flag), "Reload keeps personal receipt " + flag)
		_check(_entry_done(str(row.log)), "Reloaded quest log: %s done" % row.log)
		# The requester acknowledges after reload, heard by walk + Interact.
		var heard: Array = await _talk(str(row.npc))
		if str(row.ack).is_empty():
			_check(str(heard[0]) != "" and not str(heard[0]).begins_with("water_edda_garden_lead") \
				and not str(heard[0]).begins_with("water_edda_garden_return"), "Reload: Edda does not re-offer (%s)" % heard[0])
		else:
			_check(heard[0] == row.ack, "Reload: %s acknowledges, no re-offer (%s)" % [row.npc, heard[0]])
		summary.append("RELOAD %s %s -> %s" % [chain, row.npc, heard[0]])
	for item: String in items:
		_check(game.inventory.count(item) == int(items[item]), "No extra %s from post-reload conversations" % item)


# ---------------------------------------------------------------- steps

func _entry_done(label: String) -> bool:
	for entry: Dictionary in reader.local_entries(game.progression):
		if str(entry.label).contains(label):
			return bool(entry.done)
	return false


## Walk to the NPC, open the conversation with an Interact press on its Greet
## prompt, then advance every line with Interact presses.
## Returns [conversation, delivered text, last world message].
func _talk(npc_id: String) -> Array:
	var chapter: Node = world.get_node("WaterChapter")
	var npcs: Node = world.get_node("WaterNPCs")
	var panel: Node = world.get_node("DialoguePanel")
	var body: Node3D = chapter.npc_bodies.get(npc_id)
	if not _check(body != null, "NPC body resident: " + npc_id):
		return ["", "", ""]
	if not await _go(body.global_position, 2.5, npc_id):
		return ["", "", ""]
	var prompt: Node = body.call("prompt_node")
	if not _check(await _approach_prompt(prompt, body.global_position), "%s Greet prompt offered (winner=%s)" % [npc_id, arbiter.call("prompt")]):
		return ["", "", ""]
	hud_seen = ""
	await _press_interact()
	await _frames(6)
	if not _check(bool(panel.call("is_open")), npc_id + ": Interact opened a conversation"):
		return ["", "", ""]
	var conversation := str(npcs.get("_active_conversation"))
	var text := ""
	var message := ""
	var last := ""
	for _guard in 30:
		if not bool(panel.call("is_open")):
			break
		var line := str(panel.call("runner").call("line").get("text", ""))
		if line != last:
			text += line + "\n"
			last = line
		await _press_interact()
		await _frames(10)
	_check(not bool(panel.call("is_open")), npc_id + ": conversation closed by Interact presses")
	await _frames(10)
	message = hud_seen
	print("TALK %s conversation=%s hud='%s'" % [npc_id, conversation, message])
	return [conversation, text, message]


## Walk to a WaterLocalChains site and press Interact on its prompt.
func _use_site(site_id: String) -> String:
	var site: Node3D = world.get_node("WaterLocalChains").call("site_root", site_id)
	if not _check(site != null, "site built: " + site_id):
		return ""
	var prompt: Node = site.get_node("Prompt")
	_check(site.visible and bool(prompt.get("enabled")), "%s visible and offered after the lead" % site_id)
	if not await _go(site.global_position, 2.0, site_id):
		return ""
	if not _check(await _approach_prompt(prompt, site.global_position), "%s prompt offered (winner=%s)" % [site_id, arbiter.call("prompt")]):
		return ""
	hud_seen = ""
	await _press_interact()
	await _frames(30)
	var message := hud_seen
	print("SITE %s hud='%s'" % [site_id, message])
	return message


func _row(id: String) -> Dictionary:
	for key: String in ["pickups", "harvest"]:
		for row: Dictionary in pickups_data.get(key, []):
			if str(row.id) == id:
				return row
	return {}


func _claim_pickup(id: String, quantity: int) -> bool:
	var row := _row(id)
	if not _check(not row.is_empty(), "pickup row exists: " + id):
		return false
	var at := Vector3(float(row.position[0]), 0.0, float(row.position[2]))
	if not await _go(at, 1.6, id):
		return false
	var service: Node = world.get_node("WaterPickups")
	var node: Node3D = null
	for _i in 120:
		node = service.call("node_for", id)
		if node != null:
			break
		await physics_frame
	if not _check(node != null, id + " resident on arrival"):
		return false
	if not _check(await _approach_prompt(node.get_node_or_null("Interactable"), node.global_position), "%s prompt offered (winner=%s)" % [id, arbiter.call("prompt")]):
		return false
	var item := str(row.item_id)
	var before: int = game.inventory.count(item)
	await _press_interact()
	await _frames(20)
	print("CLAIM %s %s %d->%d" % [id, item, before, game.inventory.count(item)])
	return game.inventory.count(item) == before + quantity


func _mine_seam(id: String) -> bool:
	var row := _row(id)
	if not _check(not row.is_empty(), "seam row exists: " + id):
		return false
	var at := Vector3(float(row.position[0]), 0.0, float(row.position[2]))
	if not await _go(at, 2.0, id):
		return false
	var service: Node = world.get_node("WaterPickups")
	var node: Node3D = null
	for _i in 120:
		node = service.call("node_for", id)
		if node != null:
			break
		await physics_frame
	if not _check(node != null, id + " resident on arrival"):
		return false
	var tool := str(row.get("gather_action", "pickaxe"))
	if str(game.equipped_tool) != tool:
		await _tap(StringName("hotbar_%d" % (game.hotbar.find(tool) + 1)))
		await _frames(20)
	_check(str(game.equipped_tool) == tool, "hotbar equipped the carried " + tool)
	if not _check(await _approach_prompt(node.get_node_or_null("Interactable"), node.global_position), "%s prompt offered (winner=%s)" % [id, arbiter.call("prompt")]):
		return false
	var item := str(row.item_id)
	var before: int = game.inventory.count(item)
	await _press_interact()
	for _frame in 240:
		await physics_frame
		if game.inventory.count(item) > before:
			break
	await _frames(10)
	print("MINE %s %s %d->%d" % [id, item, before, game.inventory.count(item)])
	return game.inventory.count(item) > before


# ---------------------------------------------------------------- movement

func _island(at: Vector3) -> String:
	var id: String = field.island_id_at(at.x, at.z, 40.0)
	return id


func _landing(island_id: String) -> Vector3:
	for anchor: Dictionary in config.anchors:
		if str(anchor.island_id) == island_id and str(anchor.kind) == "arrival":
			var at: Array = anchor.safe_position
			return Vector3(float(at[0]), float(at[1]), float(at[2]))
	# First Shore has no arrival anchor: the world's own start spawn stands in.
	if island_id == _island(spawn):
		return spawn
	return Vector3.INF


func _pose(at: Vector3, why: String) -> void:
	var deck: float = world.call("ground_height_at", at.x, at.z)
	player.global_position = Vector3(at.x, maxf(deck, at.y) + 0.3, at.z)
	player.velocity = Vector3.ZERO
	navigator.call("reset")
	poses.append("%s -> %s" % [why, at])
	print("POSE ", why, " -> ", at)


## Walk with left-stick input to within `tolerance` of `target`; if the target
## is on another island, first place the trainer on that island's arrival
## landing (disclosed fixture).
func _go(target: Vector3, tolerance: float, label: String) -> bool:
	var want := _island(target)
	var here := _island(player.global_position)
	if want != here:
		var landing := _landing(want)
		if not _check(landing.is_finite(), "%s: no arrival landing for island '%s' (trainer on '%s')" % [label, want, here]):
			return false
		if continuous:
			if not await _swim_between(here, want, label):
				return false
		else:
			_pose(landing, "%s arrival landing for %s" % [want, label])
			await _frames(60)
	return await _walk_here(target, tolerance, label, want)


## Stick-walk on the current island (no island check, no position write).
func _walk_here(target: Vector3, tolerance: float, label: String, want: String) -> bool:
	# Continuous mode retries a stalled walk (still stick input, no write) from
	# wherever the trainer stopped: re-plan on the baked ground, else plan to the
	# island's own landing (First Shore: its spawn) and go direct from there,
	# else one more straight leg. The per-attempt stall is printed as RETRY.
	var attempts := 3 if continuous else 1
	for attempt in attempts:
		var result := await _walk_attempt(target, tolerance, label, want, attempt, attempt == attempts - 1)
		if result:
			return true
	return false


func _walk_attempt(target: Vector3, tolerance: float, label: String, want: String, attempt: int, last_try: bool) -> bool:
	var from := Vector2(player.global_position.x, player.global_position.z)
	var plan: Dictionary = POCKET.plan_route(world, from, Vector2(target.x, target.z))
	var route: Array = plan.points
	if route.is_empty() and continuous:
		var hub := _landing(want)
		# First choice: straight to the landing (the way the trainer usually
		# came from a dock), then the baked-ground plan from the landing.
		var onward: Array = []
		if hub.is_finite() and attempt == 0 and Vector2(hub.x - from.x, hub.z - from.y).length() > 3.0:
			onward = (POCKET.plan_route(world, Vector2(hub.x, hub.z), Vector2(target.x, target.z)).points as Array)
		if not onward.is_empty():
			print("WALK %s DIRECT TO %s landing THEN PLANNED (attempt %d)" % [label, want, attempt + 1])
			route = [Vector2(hub.x, hub.z)]
			route.append_array(onward)
		elif hub.is_finite() and Vector2(hub.x - from.x, hub.z - from.y).length() > 3.0:
			var hub_plan: Dictionary = POCKET.plan_route(world, from, Vector2(hub.x, hub.z))
			if not (hub_plan.points as Array).is_empty():
				print("WALK %s VIA %s landing (attempt %d)" % [label, want, attempt + 1])
				route = (hub_plan.points as Array).duplicate()
				route.append(Vector2(target.x, target.z))
			elif attempt > 0:
				print("WALK %s VIA %s landing DIRECT (attempt %d)" % [label, want, attempt + 1])
				route = [Vector2(hub.x, hub.z), Vector2(target.x, target.z)]
	if route.is_empty():
		# The baked-ground planner treats docks/decks over water as impassable;
		# fall back to one straight stick leg (still real input, navigator
		# detours only) and say so.
		print("WALK %s DIRECT (no baked-ground plan from %s to %s)" % [label, player.global_position, target])
		route = [Vector2(target.x, target.z)]
	var metres := 0.0
	var last := player.global_position
	for index in route.size():
		var point: Vector2 = route[index]
		var final := index == route.size() - 1
		var goal := Vector3(point.x, 0.0, point.y)
		var budget := maxi(900, int(Vector2(player.global_position.x, player.global_position.z).distance_to(point) * 90.0))
		var arrived: bool = await navigator.walk_to(goal, budget, tolerance if final else 1.8)
		metres += Vector2(last.x, last.z).distance_to(Vector2(player.global_position.x, player.global_position.z))
		last = player.global_position
		if not arrived:
			_stick(0.0, 0.0)
			walked_total += metres
			if last_try:
				_check(false, "%s: walk stalled at leg %d/%d player=%s goal=%s" % [label, index + 1, route.size(), player.global_position, goal])
			else:
				print("RETRY %s: stalled at leg %d/%d player=%s goal=%s" % [label, index + 1, route.size(), player.global_position, goal])
				navigator.call("reset")
				await _frames(10)
			return false
	_stick(0.0, 0.0)
	await _frames(20)
	walked_total += metres
	print("WALK %s island=%s walked=%.0fm legs=%d" % [label, want, metres, route.size()])
	return true


func _approach_prompt(prompt: Node, at: Vector3) -> bool:
	if prompt == null:
		return false
	for _frame in 600:
		await physics_frame
		if arbiter.call("winning_provider") == prompt:
			_stick(0.0, 0.0)
			await _frames(4)
			if arbiter.call("winning_provider") == prompt:
				return true
		var flat := Vector3(at.x - player.global_position.x, 0.0, at.z - player.global_position.z)
		if flat.length() < 0.5:
			_stick(0.0, 0.0)
			continue
		navigator.call("push_once", flat.normalized() * 0.45)
	_stick(0.0, 0.0)
	return false


func _tap(action: StringName) -> void:
	for pressed in [true, false]:
		var event := InputEventAction.new()
		event.action = action
		event.pressed = pressed
		event.strength = 1.0 if pressed else 0.0
		Input.parse_input_event(event)
		await _frames(8)


func _press_interact() -> void:
	for pressed in [true, false]:
		var event := InputEventAction.new()
		event.action = &"interact"
		event.pressed = pressed
		event.strength = 1.0 if pressed else 0.0
		Input.parse_input_event(event)
		await _frames(3)


func _stick(x: float, y: float) -> void:
	for axis in [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y]:
		var event := InputEventJoypadMotion.new()
		event.axis = axis
		event.axis_value = x if axis == JOY_AXIS_LEFT_X else y
		Input.parse_input_event(event)


func _frames(count: int) -> void:
	for _frame in count:
		await physics_frame
		_watch_hud()


var _hud: Node = null
var _hud_last := ""
var hud_seen := ""


## The player-visible HUD message strip (playground_hud.gd `_hotbar_message`),
## which consumes Game's one-shot world-message queue every frame. Any new text
## it shows is recorded in `hud_seen`.
func _watch_hud() -> void:
	if _hud == null or not is_instance_valid(_hud):
		_hud = null
		for node: Node in root.find_children("*", "", true, false):
			if node.get("_hotbar_message") is Label:
				_hud = node
				break
		if _hud == null:
			return
	var label: Label = _hud.get("_hotbar_message")
	var text := label.text if label.visible else ""
	if text != _hud_last:
		_hud_last = text
		if not text.is_empty():
			hud_seen = text


func _check(condition: bool, message: String) -> bool:
	checks += 1
	if not condition:
		failures.append(message)
		print("FAIL: ", message)
	return condition


func _finish() -> void:
	if finished:
		return
	finished = true
	_stick(0.0, 0.0)
	for line: String in summary:
		print(line)
	print("POSES (%d disclosed position writes):" % poses.size())
	for line: String in poses:
		print("  ", line)
	print("Walked total %.0fm with left-stick input" % walked_total)
	print("SWIMS (%d inter-island crossings with real move_forward input):" % swims.size())
	for line: String in swims:
		print("  ", line)
	print("Tidewake-B chain route witness: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)


# ---------------------------------------------------------------- CONTINUOUS MODE
# Inter-island travel by real swimming: the island graph is the authored
# water_routes (sheltered variants preferred, either direction). For each edge
# the trainer stick-walks to the route's start anchor on its current island,
# idles (no input, no write) until natural stamina regen is full, then holds
# the real `move_forward` action with the camera yawed at each polyline vertex
# in turn (rest shoals included), idling to full on any dry vertex, until the
# far anchor. No position or stamina write.

func _route_island(anchor_id: String) -> String:
	for anchor: Dictionary in config.anchors:
		if str(anchor.id) == anchor_id:
			return str(anchor.get("island_id", ""))
	return ""


func _anchor_at(anchor_id: String) -> Vector3:
	for anchor: Dictionary in config.anchors:
		if str(anchor.id) == anchor_id:
			var at: Array = anchor.safe_position
			return Vector3(float(at[0]), float(at[1]), float(at[2]))
	return Vector3.INF


## Breadth-first island path over the sheltered routes (then direct ones).
func _island_path(from: String, to: String) -> Array:
	for suffix: String in ["_sheltered", "_direct"]:
		var edges := {}
		for raw: Variant in config.get("water_routes", []):
			var route: Dictionary = raw
			if not str(route.id).ends_with(suffix):
				continue
			var a := _route_island(str(route.from_anchor))
			var b := _route_island(str(route.to_anchor))
			if not edges.has(a): edges[a] = []
			if not edges.has(b): edges[b] = []
			edges[a].append([b, route, false])
			edges[b].append([a, route, true])
		var previous := {from: null}
		var queue: Array = [from]
		while not queue.is_empty():
			var island: String = queue.pop_front()
			if island == to:
				var steps: Array = []
				var at := to
				while previous[at] != null:
					steps.push_front(previous[at][1])
					at = previous[at][0]
				return steps
			for edge: Array in edges.get(island, []):
				if not previous.has(edge[0]):
					previous[edge[0]] = [island, [edge[1], edge[2]]]
					queue.append(edge[0])
	return []


func _swim_between(here: String, want: String, label: String) -> bool:
	var steps := _island_path(here, want)
	if not _check(not steps.is_empty(), "%s: no water route chain from '%s' to '%s'" % [label, here, want]):
		return false
	for step: Array in steps:
		if not await _swim_route(step[0], step[1], label):
			return false
	return true


func _rest_to_full() -> int:
	var vitals: RefCounted = player.get("vitals")
	var frames := 0
	_stick(0.0, 0.0)
	_move_forward(false)
	while float(vitals.stamina) < float(vitals.max_stamina) and frames < 2400:
		await physics_frame
		frames += 1
	return frames


func _swim_route(route: Dictionary, reverse: bool, label: String) -> bool:
	var points: Array[Vector3] = [_anchor_at(str(route.from_anchor))]
	for raw: Variant in route.get("polyline", []):
		points.append(Vector3(float(raw[0]), float(raw[1]), float(raw[2])))
	points.append(_anchor_at(str(route.to_anchor)))
	if reverse:
		points.reverse()
	var id := "%s%s" % [route.id, " (reversed)" if reverse else ""]
	var start := points[0]
	if Vector2(player.global_position.x - start.x, player.global_position.z - start.z).length() > 1.5:
		if not await _walk_here(start, 1.0, "start of " + id, _island(start)):
			return false
	var vitals: RefCounted = player.get("vitals")
	var rested := await _rest_to_full()
	var health_before := float(vitals.health)
	var minimum := float(vitals.stamina)
	var swum := 0.0
	var began := Time.get_ticks_msec()
	for index in range(1, points.size()):
		var target := points[index]
		var final := index == points.size() - 1
		var previous := player.global_position
		var budget := int(Vector2(target.x - previous.x, target.z - previous.z).length() * 45.0) + 900
		var arrived := false
		for _frame in budget:
			var offset := target - player.global_position
			offset.y = 0.0
			if offset.length() <= (0.8 if final else 1.6):
				arrived = true
				break
			camera.set("yaw", atan2(-offset.x, -offset.z))
			_move_forward(true)
			await physics_frame
			if swimming != null and swimming.is_swimming():
				var moved := player.global_position - previous
				moved.y = 0.0
				swum += moved.length()
				minimum = minf(minimum, float(vitals.stamina))
			previous = player.global_position
			if float(vitals.health) <= 0.0:
				break
		_move_forward(false)
		if not _check(arrived, "%s: %s stalled at vertex %d/%d player=%s target=%s swimming=%s stamina=%.1f" % [
				label, id, index, points.size() - 1, player.global_position, target,
				swimming != null and swimming.is_swimming(), float(vitals.stamina)]):
			return false
		await _frames(4)
		if not final and player.is_on_floor() and (swimming == null or not swimming.is_swimming()):
			rested += await _rest_to_full()
	await _frames(20)
	var dry: bool = player.is_on_floor() and (swimming == null or not swimming.is_swimming())
	var line := "SWIM %s swum=%.0fm min_stamina=%.1f rest_frames=%d health %.0f->%.0f dry=%s elapsed_s=%.0f" % [
		id, swum, minimum, rested, health_before, float(vitals.health), dry, float(Time.get_ticks_msec() - began) / 1000.0]
	print(line)
	swims.append(line)
	_check(swum > 1.0, "%s: %s actually swam" % [label, id])
	_check(float(vitals.health) > 0.0, "%s: %s survived" % [label, id])
	return _check(dry, "%s: %s ended on dry land" % [label, id])


func _move_forward(pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = &"move_forward"
	event.pressed = pressed
	event.strength = 1.0 if pressed else 0.0
	Input.parse_input_event(event)


## Walk + Interact on a hand-gathered harvest row (reed patch).
func _gather_hand(id: String) -> bool:
	var row := _row(id)
	if not _check(not row.is_empty(), "harvest row exists: " + id):
		return false
	var at := Vector3(float(row.position[0]), 0.0, float(row.position[2]))
	if not await _go(at, 1.6, id):
		return false
	var service: Node = world.get_node("WaterPickups")
	var node: Node3D = null
	for _i in 120:
		node = service.call("node_for", id)
		if node != null:
			break
		await physics_frame
	if not _check(node != null, id + " resident on arrival"):
		return false
	if not _check(await _approach_prompt(node.get_node_or_null("Interactable"), node.global_position), "%s prompt offered (winner=%s)" % [id, arbiter.call("prompt")]):
		return false
	var item := str(row.item_id)
	var before: int = game.inventory.count(item)
	await _press_interact()
	for _frame in 240:
		await physics_frame
		if game.inventory.count(item) > before:
			break
	await _frames(10)
	print("GATHER %s %s %d->%d" % [id, item, before, game.inventory.count(item)])
	return game.inventory.count(item) > before


## Rest the first companion through the bed's own prompt and rest panel:
## walk until the arbiter's winner is the bed's Interactable, press Interact,
## then press `ui_accept` on the panel's focused first row, then `menu_cancel`.
func _rest_via_panel(bed: Node3D) -> bool:
	var prompt: Node = bed.get_node_or_null("Interactable")
	if not _check(prompt != null, "Lastlight: bed has its Rest prompt"):
		return false
	if not _check(await _approach_prompt(prompt, bed.global_position), "Lastlight: bed Rest prompt offered (winner=%s)" % arbiter.call("prompt")):
		return false
	await _press_interact()
	await _frames(10)
	var panel: Node = null
	for child: Node in root.get_children():
		if child.has_method("is_open") and child.has_method("owns_input") and str(child.get_script().resource_path).ends_with("creature_bed_panel.gd"):
			panel = child
	if not _check(panel != null and bool(panel.call("is_open")), "Lastlight: Interact opened the bed's rest panel"):
		return false
	var focus: Control = root.get_viewport().gui_get_focus_owner()
	print("BED PANEL focus=%s" % (focus.get("text") if focus != null else "<none>"))
	await _tap(&"ui_accept")
	await _frames(20)
	await _tap(&"menu_cancel")
	await _frames(20)
	return _check(not bool(panel.call("is_open")), "Lastlight: rest panel closed by menu_cancel")
