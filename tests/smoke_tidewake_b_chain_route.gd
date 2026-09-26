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


func _on(chain: String) -> bool:
	return only.is_empty() or only.has(chain)


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(2400.0).timeout.connect(func() -> void:
		if not finished:
			_check(false, "2400 second watchdog expired")
			_finish())
	game = root.get_node("Game")
	game.reset_for_new_game()
	game.current_realm = "water"
	game.local.character_id = CHARACTER
	RELOAD.isolate(game, "tidewake_b_chain_route")
	for upstream: String in ["water_swim_lesson_complete", "water_dock_reedhaven_repaired",
			"water_dock_brine_steps_trial_won", "water_aquaryn_resolved", "water_dock_salt_crown_landing_charted"]:
		game.world.flags.set_flag(upstream)
	for upstream: String in ["water_swim_lesson_briefed", "water_swim_stone_earned"]:
		game.local.flags.set_flag(upstream)
	if game.inventory.add("pickaxe", 1) != 0 or not game.assign_hotbar(0, "pickaxe"):
		_check(false, "could not create the disclosed carried pickaxe fixture")
		_finish()
		return
	pickups_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_pickups.json"))
	reader = QUEST_LOG.new()
	reader.set_realm("water")
	if not await _build_world(WORLD.instantiate()):
		return
	await _frames(30)
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--only="):
			only = argument.trim_prefix("--only=").split(",")
	if _on("lantern"): summary.append(await _lantern())
	if _on("gull"): summary.append(await _gull())
	if _on("cradle"): summary.append(await _cradle())
	if _on("garden"): summary.append(await _garden())
	if _on("deep"): summary.append(await _deep_watch())
	if _on("lastlight"): summary.append(await _lastlight())
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
	_check(game.world.flags.has(resolved), "Deep Watch: Tidecoil resolution recorded")
	heard = await _talk("water_orsen")
	_check(heard[0] == "water_orsen_deep_watch_chart_lead", "Deep Watch: Orsen gives the chart lead (%s)" % heard[0])
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
	# DISCLOSED FIXTURE: the delivered materials.
	_check(game.inventory.add("driftwood", 4) == 0 and game.inventory.add("reed_fiber", 4) == 0, "Lastlight: disclosed material fixture")
	var chains: Node = world.get_node("WaterLocalChains")
	var site: Node3D = chains.call("site_root", "lastlight_shelter_supply")
	var message := await _use_site("lastlight_shelter_supply")
	_check(game.world.flags.has(supplied), "Lastlight: delivery recorded by walk + Interact")
	_check(game.inventory.count("driftwood") == 0 and game.inventory.count("reed_fiber") == 0, "Lastlight: host debited 4 + 4")
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
		_pose(landing, "%s arrival landing for %s" % [want, label])
		await _frames(60)
	var from := Vector2(player.global_position.x, player.global_position.z)
	var plan: Dictionary = POCKET.plan_route(world, from, Vector2(target.x, target.z))
	var route: Array = plan.points
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
			_check(false, "%s: walk stalled at leg %d/%d player=%s goal=%s" % [label, index + 1, route.size(), player.global_position, goal])
			_stick(0.0, 0.0)
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
	print("Tidewake-B chain route witness: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
