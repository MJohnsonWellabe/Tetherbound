extends SceneTree

## ACCEPTANCE §6.1 F13#4 route depletion run: "... leave four-character
## supplies solvent without a new catch or repeated wild."
##
## tests/test_tidewake_b_four_character_ledger.gd proves the arithmetic from
## data. This run spends the supplies in the production Water scene instead:
## four characters in ONE world take turns claiming every base-material
## harvest node on the no-saddle route (First Shore .. Veilfall, gate stages
## 0-7; Drowned Garden and Deep Watch excluded as the ledger does) by the
## ordinary Interact press on the production harvest body, through the host
## ledger, and then pay every mandatory Tidewake material cost from what they
## gathered, at the gate stage it falls due:
##   stage 1  `reedhaven_repair` (world-once)  real dock prompt, character A
##   stage 5  Swim Saddle x4 (personal kit)    production Game.craft(), each
##   stage 6  two Small Potions x4 (PROGRESSION §6 emergency reserve), each
##   stage 7  `lastlight_shelter_supply` (world-once) real site prompt, char. B
## Depletion: after each claim the next character submits the same harvest
## intent to the host ledger and must be refused `already_taken` with no item
## granted, and the body must no longer be resident. Harvest is world-once
## (`harvest_node:order:<id>`): nothing regrows and nothing is counted twice.
##
## Split: claim i of an item goes to character i % 4 (round robin per item) --
## the ledger's even-split model enacted with real claims. The Tidal Cradle
## Reef Stone seam (`water:tidal_cradle:harvest:007`, the care chain's
## world-once payout) is claimed by character A only, so B, C and D never
## receive it and A's balance is also reported without it.
##
## DISCLOSED FIXTURES (listed in ralph/reports/TIDEWAKE/b/f13_4_route_depletion/PROOF.md):
##   * four PlayerStates in one process; switching character = assigning
##     Game.local and re-pointing the merged flag view and feed at it (what
##     `Game._ensure_containers` binds, minus its satchel rebuild),
##     standing in for four co-op peers sharing one host world;
##   * each carries an axe, pickaxe and knife (the ledger's carried-tool
##     assumption) on hotbar slots 1-3, and the retained five (party identity
##     only, asserted unchanged at the end);
##   * a position write beside every node / prompt (no walking between nodes);
##     the final approach is left-stick input until the production arbiter
##     offers that node's prompt, then one Interact press;
##   * EncounterDirector processing disabled: no wild can start, so none can
##     be what pays; CombatManager entries and catches are counted (must be 0);
##   * flags standing in for story steps this run does not replay: world
##     `water_swim_lesson_complete` (dock repair precondition),
##     `water_chapter_started`, `water_claim:local:lastlight_shelter:lead`
##     (Halen's lead); personal `water_swim_stone_earned`,
##     `water_swim_saddle_recipe_learned` on every character.
##
##   godot --headless --path . --script tests/smoke_tidewake_b_route_depletion.gd [-- --max-stage=N]
const WORLD_SCENE := preload("res://scenes/world/water_archipelago.tscn")
const SAVE := preload("res://scripts/save/save_game.gd")
const NAV := preload("res://tests/helpers/stick_navigator.gd")
const PLAYER_STATE := preload("res://autoload/player_state.gd")
const FEED := preload("res://scripts/creatures/progression_feed.gd")
const IDENTITY := preload("res://scripts/save/character_identity.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const WORLD_DATA := "res://data/config/water_world.json"
const PICKUPS := "res://data/config/water_pickups.json"
const DOCKS := "res://data/config/water_dock_actions.json"
const CHAINS := "res://data/config/water_local_chains.json"
const BASE := ["reed_fiber", "driftwood", "reef_stone", "tide_bloom"]
const TOOLS := ["axe", "pickaxe", "knife"]
const RETAINED_FIVE := ["terrapup", "bramblebun", "mudsnout", "pipwing", "trailpup"]
const CRADLE_SEAM := "water:tidal_cradle:harvest:007"
const NAMES := ["A", "B", "C", "D"]
const DRY_M := 0.8
const SADDLE := "water_swim_saddle"
const POTION := "water_small_potion"
const POTIONS_EACH := 2
## A stance steeper than this, or more than 1.2 m off the node's ground on the
## way in, slides the trainer down the bank (measured: 10-20 m falls).
const MAX_STANCE_SLOPE_DEG := 40.0

var game: Node
var world: Node3D
var player: CharacterBody3D
var camera: Node3D
var arbiter: Node
var service: Node
var navigator: RefCounted
var chars: Array = []
var current := -1
var stage: Dictionary = {}
var gated: Dictionary = {}
var failures: Array[String] = []
var checks := 0
var finished := false
var fights := 0
var catches := 0
var gathered: Array = []          # per character {item: n}
var claims: Array = []            # per character int
var paid_log: Array[String] = []
var cradle_to := -1
var cradle_amount := 0
var max_stage := 7
var landing_damage := 0.0
var heals := 0
var stance_retries := 0
var steepest_ring := INF
var unreachable: Array[String] = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(5400.0).timeout.connect(func() -> void:
		if not finished:
			_fail("5400 second watchdog expired")
			_finish())
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--max-stage="):
			max_stage = int(argument.trim_prefix("--max-stage="))
	game = root.get_node("Game")
	game.save_system = SAVE.new("user://smoke_tidewake_b_route_depletion_%d/" % Time.get_ticks_usec())
	game.reset_for_new_game()
	game.current_realm = "water"
	_build_stages()
	for index in 4:
		var state: RefCounted = game.local if index == 0 else PLAYER_STATE.new()
		if index > 0:
			state.call("configure", game.items)
			state.call("reset")
			state.set("character_id", IDENTITY.mint())
		state.set("display_name", "Character " + NAMES[index])
		state.set("realm", "water")
		chars.append(state)
		gathered.append({})
		claims.append(0)
	for index in 4:
		_become(index)
		for species: String in RETAINED_FIVE:
			var creature: RefCounted = SPECIES.spawn(species)
			creature.set_level(43, PROGRESSION.config())
			game.local.party.add(creature)
		for slot in TOOLS.size():
			if game.inventory.add(TOOLS[slot], 1) != 0 or not game.assign_hotbar(slot, TOOLS[slot]):
				_fail("could not create the disclosed carried %s for %s" % [TOOLS[slot], NAMES[index]])
		for flag: String in ["water_swim_stone_earned", "water_swim_saddle_recipe_learned"]:
			game.local.flags.set_flag(flag)
	_become(0)
	for flag: String in ["water_swim_lesson_complete", "water_chapter_started", "water_claim:local:lastlight_shelter:lead"]:
		game.world.flags.set_flag(flag)
	var ids := {}
	for state: RefCounted in chars:
		ids[str(state.get("character_id"))] = true
	_check(ids.size() == 4, "four distinct character ids")

	world = WORLD_SCENE.instantiate()
	root.add_child(world)
	current_scene = world
	for _frame in 1200:
		await physics_frame
		if bool(world.call("shell_build_complete")):
			break
	if not _check(bool(world.call("shell_build_complete")), "Water shell failed to build"):
		_finish()
		return
	player = world.get_node("Player")
	camera = world.get_node("CameraRig")
	arbiter = get_first_node_in_group("interaction_arbiter")
	service = world.get_node("WaterPickups")
	navigator = NAV.new(self, player, camera, _stick)
	var director := world.get_node_or_null("EncounterDirector")
	if director != null:
		director.process_mode = Node.PROCESS_MODE_DISABLED
	var manager := world.get_node_or_null("CombatManager")
	if manager != null:
		manager.connect("entered", func() -> void: fights += 1)
		manager.connect("catch_resolved", func(_s: bool, _n: int) -> void: catches += 1)
	# Every other committed world transaction is logged: nothing but harvest,
	# the two paid debits and nothing else may touch a satchel in this run.
	game.ledger.connect("delta_applied", func(delta: Dictionary) -> void:
		var text := str(delta.get("ops", []))
		if not text.contains("harvest_node:order:"):
			print("DELTA ops=%s" % text.left(300))
		if text.contains("satchel_add"):
			_fail("a death satchel was dropped during the run: " + text.left(200)))
	player.connect("landed", func(speed: float, damage: float) -> void:
		if damage > 0.0:
			landing_damage += damage
			print("LANDING speed=%.1f damage=%.1f at %s" % [speed, damage, player.global_position]))
	await _frames(30)

	var rows := _route_rows()
	print("ROUTE %d base-material harvest rows on %d no-saddle islands (stages 0-%d)" % [
		rows.size(), _islands_upto(max_stage).size(), max_stage])
	var turn := {}
	var done_stage := -1
	for row: Dictionary in rows:
		var row_stage := int(stage[str(row.island_id)])
		while done_stage < row_stage - 1:
			done_stage += 1
			await _debits_due(done_stage)
		var item := str(row.item_id)
		if _stances(Vector3(float(row.position[0]), float(row.position[1]), float(row.position[2]))).is_empty():
			unreachable.append("%s (%s x%d, gentlest ring slope %.0f deg)" % [str(row.id), item, int(row.get("yield", 0)), steepest_ring])
			print("UNREACHABLE %s %s x%d: no stance within 1.2 m of the node's baked ground at <= %.0f deg (gentlest %.0f deg)" % [
				str(row.id), item, int(row.get("yield", 0)), MAX_STANCE_SLOPE_DEG, steepest_ring])
			continue
		var who: int
		if str(row.id) == CRADLE_SEAM:
			who = 0
			cradle_to = 0
		else:
			who = int(turn.get(item, 0)) % 4
			turn[item] = int(turn.get(item, 0)) + 1
		await _claim(row, who)
	while done_stage < max_stage:
		done_stage += 1
		await _debits_due(done_stage)
	_report()
	_finish()


## Gate stages exactly as the ledger derives them (water_world.json docks).
func _build_stages() -> void:
	var docks: Array = _json(WORLD_DATA).get("docks", [])
	var targets := {}
	for dock: Dictionary in docks:
		targets[str(dock.outbound_edge).split("_to_")[1]] = true
	for dock: Dictionary in docks:
		var from := str(dock.outbound_edge).split("_to_")[0]
		if bool(dock.get("mandatory", false)) and not targets.has(from):
			stage[from] = 0
	var changed := true
	while changed:
		changed = false
		for dock: Dictionary in docks:
			var parts := str(dock.outbound_edge).split("_to_")
			if not stage.has(parts[0]) or stage.has(parts[1]):
				continue
			stage[parts[1]] = int(stage[parts[0]]) + (1 if bool(dock.get("mandatory", false)) else 0)
			if not (dock.get("required_equipment", []) as Array).is_empty() \
					or bool(dock.get("requires_compatible_active_swim_mount", false)):
				gated[parts[1]] = true
			changed = true


func _islands_upto(cut: int) -> Array:
	var out: Array = []
	for island: String in stage:
		if int(stage[island]) <= cut and not gated.has(island):
			out.append(island)
	return out


func _route_rows() -> Array:
	var out: Array = []
	var allowed := _islands_upto(max_stage)
	for row: Dictionary in _json(PICKUPS).get("harvest", []):
		if allowed.has(str(row.island_id)) and BASE.has(str(row.item_id)):
			out.append(row)
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var sa := int(stage[str(a.island_id)])
		var sb := int(stage[str(b.island_id)])
		return sa < sb if sa != sb else str(a.id) < str(b.id))
	return out


## Switch the process's local character (DISCLOSED FIXTURE).
func _become(index: int) -> void:
	if current == index:
		return
	_stick(0.0, 0.0)
	# Re-point exactly what Game._ensure_containers() binds to the local
	# player, without its configure() (which would rebuild the satchel).
	var state: RefCounted = chars[index]
	game.local = state
	var merged: RefCounted = game.progression
	merged.set("player_flags", state.get("flags"))
	state.set("flag_reader", merged)
	FEED.set_active(state.get("feed"))
	current = index


func _claim(row: Dictionary, who: int) -> void:
	var id := str(row.id)
	var item := str(row.item_id)
	var flag := "harvest_node:order:" + id
	_become(who)
	var at := Vector3(float(row.position[0]), float(row.position[1]), float(row.position[2]))
	var stances := _stances(at)
	if stances.is_empty():
		# Not a claim failure to hide: the node is recorded as unreachable on
		# foot and its yield is simply never supply for anybody.
		unreachable.append("%s (%s x%d, gentlest ring slope %.0f deg)" % [id, item, int(row.get("yield", 0)), steepest_ring])
		print("UNREACHABLE %s %s x%d: no stance within 1.2 m of the node's baked ground at <= %.0f deg (gentlest %.0f deg)" % [
			id, item, int(row.get("yield", 0)), MAX_STANCE_SLOPE_DEG, steepest_ring])
		return
	var tool := str(game.items.call("gathered_with", item))
	var offered := false
	var tries := 0
	var body: Node3D = null
	for stance: Vector3 in stances.slice(0, 4):
		tries += 1
		_place(stance)
		service.call("refresh")
		await _frames(12)
		body = service.call("node_for", id)
		if body == null:
			continue
		if not tool.is_empty() and not await _equip(tool):
			continue
		if player.global_position.y < stance.y - 2.0:
			continue
		var prompt := body.get_node_or_null("Interactable")
		offered = await _approach(prompt, body.global_position)
		if offered and player.global_position.y >= stance.y - 2.0:
			break
		offered = false
	if tries > 1:
		stance_retries += tries - 1
	if not _check(offered, "%s prompt never offered to %s after %d stances; player=%s node=%s winner=%s" % [
			id, NAMES[who], tries, player.global_position, at, arbiter.call("prompt")]):
		return
	var before: int = game.inventory.count(item)
	await _press(&"interact")
	for _frame in 300:
		if game.world.flags.has(flag):
			break
		await physics_frame
	await _frames(6)
	var gained: int = game.inventory.count(item) - before
	var ok: bool = game.world.flags.has(flag) and gained == int(row.get("yield", 0))
	if not _check(ok, "%s: %s pressed Interact but gained %d %s (yield %d), flag=%s" % [
			id, NAMES[who], gained, item, int(row.get("yield", 0)), game.world.flags.has(flag)]):
		return
	gathered[who][item] = int(gathered[who].get(item, 0)) + gained
	claims[who] += 1
	if id == CRADLE_SEAM:
		cradle_amount = gained
	# Depletion: the next character asks the host for the same node.
	var other := (who + 1) % 4
	_become(other)
	var other_before: int = game.inventory.count(item)
	var verdict: Dictionary = game.ledger.call("submit", {"kind": "harvest", "realm": "water", "flag": flag,
		"item": item, "amount": int(row.get("yield", 0))})
	_check(not bool(verdict.get("ok", false)) and str(verdict.get("code", "")) == "already_taken"
		and game.inventory.count(item) == other_before,
		"%s: second claim by %s was not refused already_taken (%s)" % [id, NAMES[other], verdict])
	service.call("refresh")
	await _frames(2)
	_check(service.call("node_for", id) == null, "%s still resident after its claim" % id)
	print("CLAIM %s stage=%d %s +%d %s -> %s (inv %d) depleted_for_%s=%s" % [id, int(stage[str(row.island_id)]),
		NAMES[who], gained, item, NAMES[who], before + gained, NAMES[other], str(verdict.get("code", "")) == "already_taken"])


## Every material debit that falls due at gate stage `s`.
func _debits_due(s: int) -> void:
	if s > max_stage:
		return
	_snapshot("END OF STAGE %d" % s)
	if s == int(stage.get("reedhaven", -1)):
		await _dock_repair(0)
	if s == int(stage.get("salt_crown", -1)):
		for index in 4:
			_become(index)
			var before: int = game.inventory.count("swim_saddle")
			var ok: bool = game.call("craft", SADDLE)
			_check(ok and game.inventory.count("swim_saddle") == before + 1,
				"%s could not craft the Swim Saddle at stage %d: %s" % [NAMES[index], s, _balance(index)])
			paid_log.append("stage %d: %s crafted Swim Saddle (8 reed, 6 driftwood, 4 reef stone) %s" % [
				s, NAMES[index], "OK" if ok else "FAILED"])
	if s == int(stage.get("sluice_isle", -1)):
		for index in 4:
			_become(index)
			var made := 0
			for _n in POTIONS_EACH:
				if bool(game.call("craft", POTION)):
					made += 1
			_check(made == POTIONS_EACH, "%s crafted %d/%d emergency Small Potions before Veilfall" % [
				NAMES[index], made, POTIONS_EACH])
			paid_log.append("stage %d: %s crafted %d Small Potions (1 tide bloom + 1 reed each)" % [s, NAMES[index], made])
	if s == int(stage.get("veilfall", -1)):
		await _lastlight_supply(1)


func _dock_repair(who: int) -> void:
	_become(who)
	var docks: Node = world.get_node("WaterDocks")
	var equipment: Node3D = docks.get_node_or_null("reedhaven_repair")
	if not _check(equipment != null, "reedhaven_repair equipment missing"):
		return
	var prompt: Node = null
	for child: Node in equipment.get_children():
		if child.has_method("interaction_offer"):
			prompt = child
	var flag := "water_dock_reedhaven_repaired"
	var before := {"reed_fiber": game.inventory.count("reed_fiber"), "driftwood": game.inventory.count("driftwood")}
	_place(_stance(equipment.global_position))
	await _frames(12)
	if not _check(await _approach(prompt, equipment.global_position), "reedhaven_repair prompt never offered; winner=%s" % arbiter.call("prompt")):
		return
	await _press(&"interact")
	for _frame in 300:
		if game.world.flags.has(flag):
			break
		await physics_frame
	await _frames(10)
	var spent := {"reed_fiber": int(before.reed_fiber) - int(game.inventory.count("reed_fiber")),
		"driftwood": int(before.driftwood) - int(game.inventory.count("driftwood"))}
	var ok: bool = game.world.flags.has(flag) and spent.reed_fiber == 6 and spent.driftwood == 4
	_check(ok, "reedhaven_repair by %s: flag=%s spent=%s" % [NAMES[who], game.world.flags.has(flag), spent])
	paid_log.append("stage 1: %s repaired the Reedhaven dock by Interact, spent %s -> %s" % [NAMES[who], spent, "OK" if ok else "FAILED"])


func _lastlight_supply(who: int) -> void:
	_become(who)
	var chains: Node = world.get_node("WaterLocalChains")
	var site: Node3D = chains.call("site_root", "lastlight_shelter_supply")
	if not _check(site != null, "lastlight_shelter_supply site missing"):
		return
	var prompt: Node = site.get_node_or_null("Prompt")
	var flag := "water_claim:local:lastlight_shelter:supplied"
	var before := {"reed_fiber": game.inventory.count("reed_fiber"), "driftwood": game.inventory.count("driftwood")}
	_place(_stance(site.global_position))
	await _frames(12)
	if not _check(await _approach(prompt, site.global_position), "lastlight site prompt never offered; winner=%s" % arbiter.call("prompt")):
		return
	await _press(&"interact")
	for _frame in 300:
		if game.world.flags.has(flag):
			break
		await physics_frame
	await _frames(10)
	var spent := {"reed_fiber": int(before.reed_fiber) - int(game.inventory.count("reed_fiber")),
		"driftwood": int(before.driftwood) - int(game.inventory.count("driftwood"))}
	var ok: bool = game.world.flags.has(flag) and spent.reed_fiber == 4 and spent.driftwood == 4
	_check(ok, "lastlight_shelter_supply by %s: flag=%s spent=%s" % [NAMES[who], game.world.flags.has(flag), spent])
	paid_log.append("stage 7: %s delivered Lastlight shelter supply by Interact, spent %s -> %s" % [NAMES[who], spent, "OK" if ok else "FAILED"])


## The disclosed position write. Trainer health is topped up first (landing
## damage from earlier approaches must not stack into a death that is not
## part of this ledger); every top-up is counted and printed.
func _place(at: Vector3) -> void:
	var vitals: RefCounted = player.get("vitals")
	if vitals != null and float(vitals.get("health")) < float(vitals.get("max_health")):
		heals += 1
		vitals.set("health", float(vitals.get("max_health")))
	player.global_position = at
	player.velocity = Vector3.ZERO


## Dry stances 1.6-2.3 m from `at` (inside the 2.4 m prompt radius), best
## first: ground within 1.2 m of the node's own ground along the straight line
## to it (no cliff between), then the gentlest local slope.
func _stances(at: Vector3) -> Array:
	var base := float(world.call("ground_height_at", at.x, at.z))
	var scored: Array = []
	steepest_ring = INF
	for radius: float in [2.0, 1.6, 2.3]:
		for index in 16:
			var angle := TAU * float(index) / 16.0
			var offset := Vector3(cos(angle), 0.0, sin(angle)) * radius
			var p := at + offset
			var h := float(world.call("ground_height_at", p.x, p.z))
			if not is_finite(h) or h < DRY_M:
				continue
			var step := absf(h - base)
			for k in range(1, 5):
				var q := at + offset * (float(k) / 5.0)
				step = maxf(step, absf(float(world.call("ground_height_at", q.x, q.z)) - base))
			var gx := (float(world.call("ground_height_at", p.x + 1.0, p.z)) - float(world.call("ground_height_at", p.x - 1.0, p.z))) * 0.5
			var gz := (float(world.call("ground_height_at", p.x, p.z + 1.0)) - float(world.call("ground_height_at", p.x, p.z - 1.0))) * 0.5
			var slope := rad_to_deg(atan(sqrt(gx * gx + gz * gz)))
			if step <= 1.2 and slope <= MAX_STANCE_SLOPE_DEG:
				scored.append({"at": Vector3(p.x, h + 0.3, p.z), "score": step * 10.0 + slope})
			steepest_ring = minf(steepest_ring, slope)
	scored.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.score) < float(b.score))
	var out: Array = []
	for row: Dictionary in scored:
		out.append(row.at)
	return out


func _stance(at: Vector3) -> Vector3:
	var all := _stances(at)
	return all[0] if not all.is_empty() else Vector3.INF


func _equip(tool: String) -> bool:
	var hold: Node = player.get("tool_hold")
	for attempt in 3:
		for _frame in 120:
			if hold == null or not hold.call("is_swinging"):
				break
			await physics_frame
		if str(game.equipped_tool) == tool and (hold == null or hold.call("prop_node") != null):
			return true
		await _press(StringName("hotbar_%d" % (game.hotbar.find(tool) + 1)))
		for _frame in 30:
			if str(game.equipped_tool) == tool and (hold == null or hold.call("prop_node") != null):
				return true
			await physics_frame
	return false


func _approach(prompt: Node, at: Vector3) -> bool:
	if prompt == null:
		return false
	for _frame in 600:
		await physics_frame
		if not is_instance_valid(prompt):
			_stick(0.0, 0.0)
			return false
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


func _balance(index: int) -> Dictionary:
	var inventory: RefCounted = chars[index].get("inventory")
	var out := {}
	for item: String in BASE + ["swim_saddle", "potion_small"]:
		out[item] = int(inventory.call("count", item))
	return out


func _snapshot(label: String) -> void:
	var parts: Array[String] = []
	for index in 4:
		parts.append("%s=%s" % [NAMES[index], _balance(index)])
	print("%s: %s" % [label, " ".join(parts)])


func _report() -> void:
	print("---- ROUTE DEPLETION RESULT ----")
	for line: String in paid_log:
		print("PAID ", line)
	for index in 4:
		var bal := _balance(index)
		var party: RefCounted = chars[index].get("party")
		var species: Array = []
		for creature: RefCounted in party.call("members"):
			species.append(str(creature.get("species_id")))
		_check(species == RETAINED_FIVE, "%s party changed: %s" % [NAMES[index], species])
		_check(int(bal.swim_saddle) == 1 and int(bal.potion_small) == POTIONS_EACH,
			"%s does not hold its saddle and emergency heals: %s" % [NAMES[index], bal])
		for item: String in BASE:
			_check(int(bal[item]) >= 0, "negative balance")
		var without_cradle := ""
		if index == cradle_to:
			without_cradle = " reef_stone_without_cradle=%d" % (int(bal.reef_stone) - cradle_amount)
			_check(int(bal.reef_stone) - cradle_amount >= 0, "A is insolvent without the Cradle seam")
		print("CHARACTER %s claims=%d gathered=%s remaining=%s%s party=%s" % [NAMES[index], claims[index],
			gathered[index], bal, without_cradle, species])
	_check(fights == 0 and catches == 0, "a fight (%d) or catch (%d) happened during the run" % [fights, catches])
	print("TRAINER landing_damage=%.1f health_top_ups=%d stance_retries=%d" % [landing_damage, heals, stance_retries])
	print("UNREACHABLE_NODES %d: %s" % [unreachable.size(), "; ".join(unreachable)])
	print("FIGHTS %d CATCHES %d cradle_seam_to=%s cradle_reef_stone=%d" % [fights, catches,
		NAMES[cradle_to] if cradle_to >= 0 else "-", cradle_amount])


func _json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed as Dictionary if parsed is Dictionary else {}


func _press(action: StringName) -> void:
	for pressed in [true, false]:
		var event := InputEventAction.new()
		event.action = action
		event.pressed = pressed
		event.strength = 1.0 if pressed else 0.0
		Input.parse_input_event(event)
		await _frames(4)


func _stick(x: float, y: float) -> void:
	for axis in [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y]:
		var event := InputEventJoypadMotion.new()
		event.axis = axis
		event.axis_value = x if axis == JOY_AXIS_LEFT_X else y
		Input.parse_input_event(event)


func _frames(count: int) -> void:
	for _frame in count:
		await physics_frame


func _check(condition: bool, message: String) -> bool:
	checks += 1
	if not condition:
		failures.append(message)
		print("FAIL: ", message)
	return condition


func _fail(message: String) -> void:
	failures.append(message)
	print("FAIL: ", message)


func _finish() -> void:
	if finished:
		return
	finished = true
	_stick(0.0, 0.0)
	print("Tidewake route depletion smoke: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
