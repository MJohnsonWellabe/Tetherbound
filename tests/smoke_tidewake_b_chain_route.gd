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
## `--continuous` (DRY RUN until it starts from an earned save): inter-island
## legs are SWUM with real move_forward along the authored water_routes (no
## position write), Lastlight's materials are gathered from production harvest
## rows (hand reed, axe driftwood) by walk + Interact, the bed rest goes through
## the bed's Rest prompt and rest panel (ui_accept / menu_cancel), and Tidecoil
## is fought for real (tests/helpers/tidewake_b_tidecoil_fight.gd). Remaining
## fixtures in that mode: the retained five at L43, a carried pickaxe + axe,
## the upstream flags above plus the Shellwatch and Sluice departure facts, and
## one landing write after the Tidecoil win if stranded under Deep Watch's
## cliff (no owned swimmer yet). `--save-dir=user://<dir>` writes a production
## checkpoint save after each chain (slot 2 of <save-dir>/ck_<chain index>/);
## `--resume-from=<chain>` loads the previous chain's checkpoint (DRY RUN);
## `--start-slot=<n>` starts from a save in --save-dir through Game.load_game.
## `-- --only=lantern,gull,cradle,garden,deep,lastlight` selects chains; the
## PROOF run used one process per chain (each: own world, own save/reload).
##   godot --headless --path . --script tests/smoke_tidewake_b_chain_route.gd [-- --only=<chain>]
const WORLD := preload("res://scenes/world/water_archipelago.tscn")
const RELOAD := preload("res://tests/helpers/water_chain_reload.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const LOCAL_CHAINS := preload("res://tests/helpers/tidewake_b_local_chains.gd")
const CHARACTER := "tidewake-b-chain-route"
const CHAINS := LOCAL_CHAINS.CHAINS
const CHECKPOINT_SLOT := 2
const SAVE_GAME := preload("res://scripts/save/save_game.gd")

## Chain steps, movement, swims and checks live in the shared helper
## tests/helpers/tidewake_b_local_chains.gd (also used by the four-biome
## Water stage's `--with-local-chains`).
var chains: RefCounted = LOCAL_CHAINS.new()
var game: Node
var world: Node3D
var finished := false
var summary: Array[String] = []
var only: PackedStringArray = []
var continuous := false
var save_dir := ""
var resume_from := ""


func _on(chain: String) -> bool:
	return only.is_empty() or only.has(chain)


func _check(condition: bool, message: String) -> bool:
	return chains._check(condition, message)


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
	# through Game.save_game(CHECKPOINT_SLOT) in <save-dir>/ck_<chain index>/. `--resume-from=<chain>`
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
		if OS.get_cmdline_user_args().has("--mount-fixture"):
			# DISCLOSED (DRY RUN ridden-leg iteration only): the fifth member is
			# a Water Mosshell with a carried Swim Saddle, standing in for the
			# earned swimmer the four-biome stage hands the helper.
			game.local.party.clear()
			for species: String in ["terrapup", "bramblebun", "mudsnout", "pipwing", "water_mosshell"]:
				var member: RefCounted = SPECIES.spawn(species)
				member.set_level(43, PROGRESSION.config())
				game.local.party.add(member)
			game.local.flags.set_flag("water_swim_saddle_recipe_learned")
			if game.inventory.add("swim_saddle", 1) != 0:
				_check(false, "could not create the disclosed swim saddle fixture")
			chains.mount = game.local.party.at(4)
			print("DRY RUN mount fixture: %s" % chains.mount.species_id)
	var start_slot := -1
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--start-slot="):
			start_slot = int(argument.trim_prefix("--start-slot="))
	if start_slot >= 0:
		# Start from a declared save through the normal load path. Loading
		# replaces the fixture state set above.
		var started := bool(game.load_game(start_slot))
		print("START from save slot %d in %s loaded=%s realm=%s party=%d" % [start_slot, save_dir, started, game.current_realm, game.local.party.size()])
		if not _check(started and str(game.current_realm) == "water", "start save loads into Water"):
			_finish()
			return
	else:
		print("DRY RUN - does not count: declared fixture start (see header)")
	if resume_from != "":
		var index := CHAINS.find(resume_from)
		if not _check(index > 0 and save_dir != "", "--resume-from needs a later chain and --save-dir"):
			_finish()
			return
		var base: RefCounted = game.save_system
		game.save_system = SAVE_GAME.new(_checkpoint_dir(index - 1))
		var loaded := bool(game.load_game(CHECKPOINT_SLOT))
		game.save_system = base
		print("DRY RUN: resumed from checkpoint %s (after %s) loaded=%s" % [_checkpoint_dir(index - 1), CHAINS[index - 1], loaded])
		if not _check(loaded, "checkpoint loaded"):
			_finish()
			return
		only = PackedStringArray(CHAINS.slice(index))
	if not await _build_world(WORLD.instantiate()):
		return
	await chains._frames(30)
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--only="):
			only = argument.trim_prefix("--only=").split(",")
	for index in CHAINS.size():
		var chain: String = CHAINS[index]
		if not _on(chain):
			continue
		summary.append(await chains.run_chain(chain))
		print(summary[-1])
		if save_dir != "":
			# SaveGame has 5 slots, so each checkpoint is slot CHECKPOINT_SLOT
			# in its own directory <save-dir>/ck_<chain index>/.
			var base: RefCounted = game.save_system
			game.save_system = SAVE_GAME.new(_checkpoint_dir(index))
			var saved := bool(game.save_game(CHECKPOINT_SLOT))
			game.save_system = base
			print("CHECKPOINT %s slot=%d after %s saved=%s at %s" % [_checkpoint_dir(index), CHECKPOINT_SLOT, chain, saved, chains.player.global_position])
	await _reload_leg()
	_finish()


func _checkpoint_dir(index: int) -> String:
	return "%s/ck_%d/" % [save_dir.trim_suffix("/"), index]


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
	return chains.bind(self, world, continuous)


func _reload_leg() -> void:
	var items := {}
	for item: String in ["skill_candy_i", "skill_candy_ii", "skill_candy_iii", "berries", "reef_stone"]:
		items[item] = game.inventory.count(item)
	var probe := ""
	for chain: String in LOCAL_CHAINS.RELOAD_TABLE:
		if _on(chain):
			probe = str(LOCAL_CHAINS.RELOAD_TABLE[chain].world[0])
			break
	var reloaded: Dictionary = await RELOAD.save_and_reload(self, game, world, probe, "")
	for pair: Array in reloaded.checks:
		_check(pair[0], "Reload: " + str(pair[1]))
	if reloaded.world == null:
		return
	if not await _build_world(reloaded.world):
		return
	await chains._frames(30)
	summary.append_array(await chains.verify_saved(PackedStringArray(only if not only.is_empty() else PackedStringArray(CHAINS)), items))


func _finish() -> void:
	if finished:
		return
	finished = true
	chains._stick(0.0, 0.0)
	for line: String in summary:
		print(line)
	chains.print_travel_log()
	print("Tidewake-B chain route witness: %d checks, %d failures" % [chains.checks, chains.failures.size()])
	quit(0 if chains.failures.is_empty() else 1)
