extends SceneTree

## DIAG-S02-ENCOUNTER — why did the opening's beat-6 wild encounter never engage?
##
##   godot --headless --path . --script tools/gate_f/diag/probe_s02_encounter.gd
##
## ## The question this exists to answer
##
## Gate F run 3, segment S02, recorded six FAILs with one root cause: the beat-6
## wild encounter never engaged. There is no `combat_start` anywhere in
## `S02/telemetry/events.jsonl`, so the first catch never happened, the party
## stayed at 1 of 2, the objective chain stuck on "Catch your first wild
## creature", and `road_gate_open` was never set.
##
## That finding is recorded and is not in question here. What is NOT established
## is its CAUSE, and the two candidates are completely different findings:
##
##   GAME  — the encounter cannot be staged on the production path. A dead-end
##           in the opening, on the critical path, at `main@26f0db4`.
##   RIG   — the encounter stages fine and the harness never triggered it. More
##           rig error, and no statement about the game at all.
##
## ## Why this is a DIAG instrument and what that costs
##
## Protocol section 0.6 confines shortcuts to segments that audit the world or the
## instrument rather than the player's experience, and section 0.1 bars any pacing,
## navigation, difficulty or economy claim from a DIAG segment. This probe makes
## exactly one kind of claim — whether a fight CAN be started, and from where —
## and it uses two shortcuts to make it: it boots the world scene directly, and
## it places the player at named coordinates. Neither is a claim about how a
## player would get there. Section J's "record defects before any diagnostic
## rerun" is satisfied: S02's six FAILs are already on disk with their evidence.
##
## The operator changes no game code, data or config (section 13). This file is
## rig, it reads the game and never writes it, and every number below is measured
## in this process at the frozen candidate.
##
## ## The three measurements, and what each one rules out
##
## A. IS THERE A CREATURE THERE AT ALL, on a fresh stand-up of the world?
##    Every wild body in the tree, with the practice creature named, and the
##    distance from each to the two points S02 actually cared about: the target
##    its walk step asked for, and the place its player was standing when it
##    pressed. If nothing is within engage range of the press point, the rig
##    pressed at empty ground. If something is, the press had a target and the
##    question moves on.
##
## B. IS THERE ANYTHING TO FIGHT WITH?
##    `encounter_director.gd::_engageable()` returns null when `_ally` is null or
##    fainted, BEFORE it looks at distance at all. S02's telemetry says
##    `active_creature: Moss` throughout — but `gate_f_probe.gd::active_creature()`
##    reads the PARTY's active member, not the deployed body, so that field
##    cannot distinguish "a creature is out" from "a creature is owned". Nothing
##    in the run's evidence answers this, which is why it is measured here.
##
## C. DOES THE PRESS WORK?
##    A real `interact`, sent the way the harness sends one, from the exact place
##    S02 stood — and then again from arm's length. If it works at arm's length
##    and not from the press point, the finding is about distance and is the
##    rig's. If it works from neither, the finding is the game's.
##
## Runs twice over: once on a fresh stand-up (the state S02 was actually in, a
## new game whose opening had just run) and once on S02's own exit save (the
## production artefact the run carried forward), because a spawn that only
## appears on one of those is itself the answer.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 240
const LOAD_SETTLE_FRAMES := 300
## Slot 2, NOT slot 4. The first revision of this probe seeded S02-exit into
## slot 4 while segment S05 was live in another process, because slot 4 is the
## handoff slot section B reserves for exactly that. S05 was unharmed — it had
## already loaded, and its own `save_out` rewrites the slot at its last step —
## but a diagnostic that can overwrite the run's handoff save is a hazard
## whether or not it did harm this time. Slots 1-3 are the ones section B keeps
## free for natural play; this takes 2 and never touches 4.
const SLOT := 2

## Where S02's step script aimed its walk (`S02-30`, "walked 54.9 m to (30, -40)").
const WALK_TARGET := Vector3(30.0, 0.0, -40.0)
## Where the player ACTUALLY was for every step from `S02-32` (engage) through
## `S02-43` (catch resolve) — the position never changed again after the walk.
## Read out of S02/telemetry/events.jsonl, not guessed.
const PRESS_POINT := Vector3(26.78, 0.53, -38.32)

const EXIT_SAVE := "ralph/reports/gate-f-run-20260828T183531Z/S02/saves/S02-exit.json"


## Which passes to run. Each pass needs its own PROCESS, not just its own world:
## `Game` is an autoload, so a save loaded in pass 2 is still loaded in pass 3,
## and the first attempt at pass 3 booted a "fresh" world that already had a
## party of 1 in it and skipped the whole starter sequence
## (`sequence_director.gd::_starter_already_granted()`). That run is not evidence
## of anything and is not reported as any. Pass with `--diag-pass=3`.
var _only := 0


func _init() -> void:
	for arg in OS.get_cmdline_user_args() + OS.get_cmdline_args():
		if arg.begins_with("--diag-pass="):
			_only = int(arg.substr("--diag-pass=".length()))
	_run()


func _run() -> void:
	print("=== DIAG-S02-ENCOUNTER =========================================")
	print("candidate: the GAME at main@26f0db4; this file is rig and writes nothing")
	print("")

	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	current_scene = world
	for i in SETTLE_FRAMES:
		await physics_frame

	var player := world.get_node_or_null(^"Player") as CharacterBody3D
	var director := world.get_node_or_null(^"EncounterDirector")
	var arbiter := world.get_node_or_null(^"InteractionArbiter")
	if arbiter == null:
		for n in _descendants(world):
			if str(n.get_class()) == "Node" and n.has_method("winning_provider"):
				arbiter = n
				break
	if player == null or director == null:
		print("FATAL: missing Player (%s) or EncounterDirector (%s)" % [player, director])
		quit(1)
		return

	if _only == 0 or _only == 1:
		print("--- PASS 1: fresh stand-up, no save loaded ----------------------")
		await _measure(world, player, director, arbiter, "fresh")

	if _only == 0 or _only == 2:
		await _pass2(world, player, director, arbiter)

	if _only == 4:
		await _pass4(world, player, director, arbiter)

	if _only == 5:
		await _pass5(world, player, director, arbiter)

	if _only == 0 or _only == 3:
		print("")
		print("--- PASS 3: the LIVE opening path, no save, no grant -----------")
		await _pass3()

	print("")
	print("=== END DIAG-S02-ENCOUNTER =====================================")
	quit(0)


func _pass2(world: Node, player: CharacterBody3D, director: Node, arbiter: Node) -> void:
	print("")
	print("--- PASS 2: S02's own exit save, loaded through save_game.gd ----")
	if not _seed_save():
		print("  could not seed %s into the save dir; PASS 2 skipped" % EXIT_SAVE)
	else:
		var game := root.get_node_or_null(^"/root/Game")
		if game == null:
			print("  no /root/Game autoload; PASS 2 skipped")
		else:
			var saver: Object = _saver(game)
			if saver == null:
				print("  no save object reachable from Game; PASS 2 skipped")
			else:
				var ok := bool(saver.call("load_slot", game, SLOT))
				print("  load_slot(%d) -> %s" % [SLOT, ok])
				for i in LOAD_SETTLE_FRAMES:
					await physics_frame
				await _measure(world, player, director, arbiter, "S02-exit")


## The only pass that can answer the question, and the reason the other two
## cannot.
##
## PASS 2 loads S02's exit save and finds no deployed body — but S02's encounter
## failed BEFORE that save was written, on a live process that had never loaded
## anything, so a null ally after a load says nothing about what S02 had. And
## `sequence_director.gd::_adopt()` calls `encounter_director.gd::adopt_starter()`,
## whose own job is to build "the one real follower body". So on the live path
## the body should be standing there the moment the name is confirmed.
##
## This boots a second, clean world and drives the real opening: Grandpa's
## conversation, the starter picker, the naming pad — the same production panels
## S02 drove, with the same synthetic input, and NOTHING granted. The one DIAG
## shortcut is placement: the player is put next to Grandpa and later next to the
## bramblebun instead of walking, because this probe makes no claim about walking.
func _pass3() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	current_scene = world
	for i in SETTLE_FRAMES:
		await physics_frame

	var player := world.get_node_or_null(^"Player") as CharacterBody3D
	var director := world.get_node_or_null(^"EncounterDirector")
	var arbiter: Node = null
	for n in _descendants(world):
		if n.has_method("winning_provider"):
			arbiter = n
			break
	if player == null or director == null:
		print("[live] FATAL: no Player/EncounterDirector in the second world")
		return

	print("[live] party at boot = %d, ally_body = %s"
		% [_party_size(), "null" if director.call("ally_body") == null else "present"])

	# Grandpa, from data/config/opening.json's own marker.
	var grandpa: Node3D = null
	for n in _descendants(world):
		if n is Node3D and str(n.name).to_lower().contains("grandpa") and (n as Node3D).is_inside_tree():
			grandpa = n as Node3D
			if n.has_method("interaction_offer"):
				break
	if grandpa == null:
		print("[live] no Grandpa node found; PASS 3 cannot run the opening")
		return
	print("[live] Grandpa is %s at %.2f, %.2f, %.2f"
		% [str(grandpa.name), grandpa.global_position.x, grandpa.global_position.y, grandpa.global_position.z])

	var stand := grandpa.global_position + Vector3(1.4, 0.0, 1.4)
	player.global_position = Vector3(stand.x, grandpa.global_position.y + 0.2, stand.z)
	player.velocity = Vector3.ZERO
	for i in 90:
		await physics_frame

	# Beat 3: the briefing. Advance until the panel stops owning input rather
	# than a guessed press count -- CD-3's rule, and the same predicate the
	# harness's own `advance_dialogue_until_closed` uses.
	print("[live] before talking: input_context-ish owner = %s" % _owner_name())
	_send_interact()
	for i in 60:
		await physics_frame
	print("[live] after one interact at Grandpa: owner = %s" % _owner_name())

	var pressed := 0
	while pressed < 60:
		var owner := _owner_name()
		if owner == "" or owner.contains("StarterPicker") or owner.contains("NamePrompt"):
			break
		_send_interact()
		for i in 20:
			await physics_frame
		pressed += 1
	print("[live] briefing advanced with %d presses; owner now = %s" % [pressed, _owner_name()])

	for i in 180:
		await physics_frame
	print("[live] owner after settle = %s   party = %d" % [_owner_name(), _party_size()])

	# Beat 4: choose a starter with the picker's own input, then the pad.
	if _owner_name().contains("StarterPicker"):
		_send_action("menu_confirm")
		for i in 180:
			await physics_frame
	print("[live] after picker confirm: owner = %s   party = %d" % [_owner_name(), _party_size()])

	# Beat 5: the naming pad. Confirm whatever default the grid lands on rather
	# than typing -- the name's CONTENT is not what this probe is about.
	var pad_tries := 0
	while _owner_name().contains("NamePrompt") and pad_tries < 40:
		_send_action("menu_confirm")
		for i in 15:
			await physics_frame
		pad_tries += 1
	for i in 240:
		await physics_frame

	var ally: Variant = director.call("ally_body")
	print("")
	print("[live] === THE ANSWER ===========================================")
	print("[live] party size after the opening      = %d" % _party_size())
	print("[live] director.ally_body()              = %s"
		% ["NULL — no follower body was ever built" if ally == null else str((ally as Node3D).name)])
	var named := 0
	for n in _descendants(world):
		if str(n.name) == "AllyCreature":
			named += 1
	print("[live] nodes named AllyCreature in tree  = %d" % named)

	if _party_size() == 0:
		print("[live] the opening did not reach a starter; PASS 3 is INCONCLUSIVE,")
		print("[live] and that inconclusiveness is about this probe, not the game.")
		return

	# And the whole point: with the live state the opening produced, does the
	# press at the bramblebun start a fight?
	await _press_from(world, player, director, arbiter, PRESS_POINT, "live", "S02's own press point")
	var practice: Variant = director.call("wild_creature")
	if practice != null:
		var close := (practice as Node3D).global_position + Vector3(1.2, 0.0, 1.2)
		await _press_from(world, player, director, arbiter, close, "live", "arm's length (1.7 m)")


## Whichever panel currently owns input, by class/script name, or "" for none.
func _owner_name() -> String:
	var owner: Variant = null
	var io := load("res://scripts/ui/input_owner.gd")
	if io != null and io.has_method("current"):
		owner = io.call("current", self)
	if owner == null:
		return ""
	var node := owner as Node
	if node == null:
		return str(owner)
	var script_path := ""
	if node.get_script() != null:
		script_path = str(node.get_script().resource_path)
	return "%s (%s)" % [str(node.name), script_path]


func _send_action(action: String) -> void:
	var ev := InputEventJoypadButton.new()
	ev.button_index = JOY_BUTTON_A
	ev.pressed = true
	Input.parse_input_event(ev)
	Input.action_press(action)
	await physics_frame
	var up := InputEventJoypadButton.new()
	up.button_index = JOY_BUTTON_A
	up.pressed = false
	Input.parse_input_event(up)
	Input.action_release(action)


## One full A/B/C sweep against whatever state the world is currently in.
func _measure(world: Node, player: CharacterBody3D, director: Node, arbiter: Node, label: String) -> void:
	# --- A: is there a creature there at all? ---------------------------------
	var wilds: Array = []
	var raw: Variant = director.call("wild_creatures")
	if raw is Array:
		for w in (raw as Array):
			if w is Node3D and is_instance_valid(w):
				wilds.append(w)
	# and independently, by node name, in case the director's own list is the
	# thing that is empty — the two disagreeing IS a finding.
	var by_name: Array[Node3D] = []
	for n in _descendants(world):
		if n is Node3D and str(n.name).begins_with("Wild_"):
			by_name.append(n as Node3D)

	print("[%s] A. wild bodies: director.wild_creatures()=%d, nodes named Wild_*=%d"
		% [label, wilds.size(), by_name.size()])
	if wilds.size() != by_name.size():
		print("[%s]    MISMATCH: the director's list and the tree disagree." % label)

	var practice: Variant = director.call("wild_creature")
	print("[%s]    director.wild_creature() (the practice creature) = %s"
		% [label, "null" if practice == null else str((practice as Node3D).name)])

	var near_target := _nearest(by_name, WALK_TARGET)
	var near_press := _nearest(by_name, PRESS_POINT)
	_report_nearest(label, "S02's walk TARGET   (30.00, -40.00)", near_target, WALK_TARGET)
	_report_nearest(label, "S02's PRESS POINT   (26.78, -38.32)", near_press, PRESS_POINT)

	var engage_range := _engage_range(director)
	print("[%s]    engage_range read from data/config/combat.json flow = %.2f m" % [label, engage_range])

	# --- B: is there anything to fight with? ----------------------------------
	var ally: Variant = director.call("ally_body")
	print("[%s] B. director.ally_body() = %s"
		% [label, "NULL — nothing is deployed" if ally == null else str((ally as Node3D).name)])
	var party_size := _party_size()
	print("[%s]    Game.party size = %d" % [label, party_size])
	if ally == null and party_size > 0:
		print("[%s]    >>> a party of %d and NO deployed body. _engageable() returns null" % [label, party_size])
		print("[%s]    >>> before it ever measures a distance, so NOTHING is engageable" % label)
		print("[%s]    >>> anywhere in the world, at any range, with any press." % label)

	# --- C: does the press work? ---------------------------------------------
	if practice == null:
		print("[%s] C. no practice creature to press at; C not run" % label)
		return
	var target := practice as Node3D
	await _press_from(world, player, director, arbiter, PRESS_POINT, label, "S02's own press point")
	var close := target.global_position + Vector3(1.2, 0.0, 1.2)
	await _press_from(world, player, director, arbiter, close, label, "arm's length (1.7 m)")


## Stand at `where`, read what the game offers, send one `interact`, and report
## whether a fight started. The press is sent the way the harness sends one:
## a parsed physical joypad event AND the action press/release beside it, per
## protocol section 0.1.
func _press_from(world: Node, player: CharacterBody3D, director: Node, arbiter: Node,
		where: Vector3, label: String, what: String) -> void:
	var here := where
	if world.has_method("ground_height_at"):
		here.y = float(world.call("ground_height_at", here.x, here.z)) + 1.0
	player.global_position = here
	player.velocity = Vector3.ZERO
	for i in 60:
		await physics_frame

	var practice: Variant = director.call("wild_creature")
	var dist := -1.0
	if practice != null:
		dist = player.global_position.distance_to((practice as Node3D).global_position)

	var prompt := str(director.call("prompt"))
	var owns := bool(director.call("owns_active_prompt"))
	var offer: Variant = director.call("interaction_offer", player.global_position)
	var arb_prompt := "" if arbiter == null else str(arbiter.call("prompt"))
	var arb_winner: Variant = null if arbiter == null else arbiter.call("winning_provider")

	print("[%s] C. standing at %s: %.2f, %.2f  (%s)"
		% [label, what, here.x, here.z, "%.2f m from the practice creature" % dist if dist >= 0.0 else "no creature"])
	print("[%s]    director.prompt()          = %s" % [label, JSON.stringify(prompt)])
	print("[%s]    director.owns_active_prompt= %s" % [label, owns])
	print("[%s]    director.interaction_offer = %s" % [label, JSON.stringify(offer)])
	print("[%s]    arbiter.prompt()           = %s" % [label, JSON.stringify(arb_prompt)])
	print("[%s]    arbiter.winning_provider() = %s" % [label,
		"null" if arb_winner == null else str((arb_winner as Object).get_script().resource_path if (arb_winner as Object).get_script() != null else arb_winner)])

	var before := _is_fighting(director)
	_send_interact()
	for i in 180:
		await physics_frame
	var after := _is_fighting(director)
	print("[%s]    pressed interact: is_fighting %s -> %s   %s"
		% [label, before, after, ">>> A FIGHT STARTED" if after and not before else ">>> NO FIGHT"])
	print("")


## Both halves, per section 0.1: the parsed physical event so focus-based and
## event-based readers see it, and the action press/release so poll-based
## readers (`Input.is_action_just_pressed`, which is what
## `_read_engage_input()` and the arbiter both use) see it too.
func _send_interact() -> void:
	var ev := InputEventJoypadButton.new()
	ev.button_index = JOY_BUTTON_X
	ev.pressed = true
	Input.parse_input_event(ev)
	Input.action_press("interact")
	await physics_frame
	var up := InputEventJoypadButton.new()
	up.button_index = JOY_BUTTON_X
	up.pressed = false
	Input.parse_input_event(up)
	Input.action_release("interact")


func _is_fighting(director: Node) -> bool:
	var mgr := root.get_node_or_null(^"/root/CombatManager")
	if mgr == null:
		for n in _descendants(current_scene):
			if n.has_method("is_fighting"):
				mgr = n
				break
	if mgr == null:
		return false
	return bool(mgr.call("is_fighting"))


func _nearest(bodies: Array[Node3D], to: Vector3) -> Node3D:
	var best: Node3D = null
	var best_d := INF
	for b in bodies:
		if not is_instance_valid(b):
			continue
		var flat := b.global_position
		var probe := to
		flat.y = 0.0
		probe.y = 0.0
		var d := flat.distance_to(probe)
		if d < best_d:
			best_d = d
			best = b
	return best


func _report_nearest(label: String, what: String, body: Node3D, to: Vector3) -> void:
	if body == null:
		print("[%s]    nearest to %s: NOTHING — no wild body anywhere in the tree" % [label, what])
		return
	var flat := body.global_position
	flat.y = 0.0
	var probe := to
	probe.y = 0.0
	print("[%s]    nearest to %s: %s at %.2f, %.2f  -> %.2f m  (visible=%s alive=%s aggressive=%s)"
		% [label, what, str(body.name), body.global_position.x, body.global_position.z,
			flat.distance_to(probe), body.visible,
			bool(body.call("is_alive")) if body.has_method("is_alive") else "?",
			body.get("aggressive")])


func _engage_range(director: Node) -> float:
	var file := FileAccess.open("res://data/config/combat.json", FileAccess.READ)
	if file == null:
		return -1.0
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return -1.0
	return float((parsed as Dictionary).get("flow", {}).get("engage_range", 6.0))


func _party_size() -> int:
	var game := root.get_node_or_null(^"/root/Game")
	if game == null:
		return -1
	var party: Variant = game.get("party")
	if party == null:
		return -1
	var members: Variant = party.call("members")
	return (members as Array).size() if members is Array else -1


func _saver(game: Node) -> Object:
	for prop in ["save_system", "save_game", "saves", "save"]:
		var v: Variant = game.get(prop)
		if v is Object and (v as Object).has_method("load_slot"):
			return v as Object
	return null


func _seed_save() -> bool:
	var src := FileAccess.open("res://" + EXIT_SAVE, FileAccess.READ)
	if src == null:
		return false
	var text := src.get_as_text()
	DirAccess.make_dir_recursive_absolute("user://saves")
	var dst := FileAccess.open("user://saves/slot_%d.json" % SLOT, FileAccess.WRITE)
	if dst == null:
		return false
	dst.store_string(text)
	dst.close()
	return true


func _descendants(node: Node) -> Array[Node]:
	var out: Array[Node] = [node]
	for child in node.get_children():
		out.append_array(_descendants(child))
	return out


## PASS 4 — the one that settles S02, and why passes 2 and 3 could not.
##
## Passes 2 and 3 both found no follower body, but both had loaded or inherited a
## save, and S02's encounter failed on a LIVE process that had never loaded
## anything. On that live path `sequence_director.gd::_adopt()` calls
## `encounter_director.gd::adopt_starter()`, whose own job is to build "the one
## real follower body" — and S02's telemetry proves that call succeeded: the
## party grew 0 -> 1 carrying the name the pad typed, which `_adopt()` only
## reaches after `adopt_starter()` returns true. So S02 HAD a creature out, and
## the null-ally explanation that covers S03 onward does not cover S02.
##
## What is left is distance, and distance here is not a constant. So this pass
## grants the starter through the game's own `adopt_starter()` — the same
## function, with the same arguments, that the naming prompt's own handler calls;
## the DIAG shortcut is past the naming UI, not past the deploy path — stands the
## player exactly where S02 stood, and then WATCHES, because the thing S02 aimed
## at moves.
##
## `S02-30` is `move_to {"at": [30, -40], "close_enough": 4.0}`: a hardcoded
## point. `data/config/combat.json` gives a wild creature `wander_radius` 7.0 m
## around its home and `_engageable()` a reach of 6.0 m. A step that arrives
## anywhere inside a 4 m disc of a point, to engage something that roams a 7 m
## disc of its own, against a 6 m reach, is a step whose success is a coin toss —
## and S02 pressed once.
func _pass4(world: Node, player: CharacterBody3D, director: Node, arbiter: Node) -> void:
	print("--- PASS 4: live, a creature actually out, and the wander envelope -")
	print("[s02] at boot: party = %d, ally_body = %s"
		% [_party_size(), "null" if director.call("ally_body") == null else "present"])

	var adopted: bool = await director.call("adopt_starter", "ripplet", "Moss")
	for i in 120:
		await physics_frame
	var ally: Variant = director.call("ally_body")
	print("[s02] adopt_starter(\"ripplet\", \"Moss\") -> %s" % adopted)
	print("[s02] director.ally_body() now         = %s"
		% ["NULL" if ally == null else str((ally as Node3D).name)])
	if ally == null:
		print("[s02] >>> the deploy path itself is broken; nothing below can be read.")
		return

	var here := PRESS_POINT
	if world.has_method("ground_height_at"):
		here.y = float(world.call("ground_height_at", here.x, here.z)) + 1.0
	player.global_position = here
	player.velocity = Vector3.ZERO
	for i in 60:
		await physics_frame

	# S02 stood still here for 15.5 s of play (t=219.4 engage -> t=234.9 catch
	# resolve) and pressed once. Sample twice that, so the reading is about the
	# envelope rather than about one lucky or unlucky instant.
	print("")
	print("[s02] standing at S02's own press point (%.2f, %.2f). Sampling the offer" % [here.x, here.z])
	print("[s02] the game makes there, once a play-second, for 30 s:")
	print("")
	print("      t     nearest wild   dist    offer")
	var in_range := 0
	var samples := 0
	var min_d := INF
	var max_d := 0.0
	var first_engage_t := -1.0
	for sec in 30:
		for i in 60:
			await physics_frame
		var practice: Variant = director.call("wild_creature")
		var d := -1.0
		var who := "(none)"
		if practice != null:
			who = str((practice as Node3D).name)
			d = player.global_position.distance_to((practice as Node3D).global_position)
			min_d = minf(min_d, d)
			max_d = maxf(max_d, d)
		var offer: Variant = director.call("interaction_offer", player.global_position)
		var label := str((offer as Dictionary).get("label", "")) if offer is Dictionary else ""
		var engageable := label.contains("Engage")
		samples += 1
		if engageable:
			in_range += 1
			if first_engage_t < 0.0:
				first_engage_t = float(sec)
		print("   %5d   %-22s %6.2f  %s" % [sec, who, d, _plain(label)])

	print("")
	print("[s02] === THE ANSWER ===========================================")
	print("[s02] engage_range                        = 6.00 m")
	print("[s02] nearest wild creature, over 30 s    = %.2f m min, %.2f m max" % [min_d, max_d])
	print("[s02] samples where the game offered Engage = %d of %d" % [in_range, samples])
	if in_range == 0:
		print("[s02] >>> From the place S02 actually stood, the game NEVER offered")
		print("[s02] >>> an engagement in 30 s. One `interact` there could not have")
		print("[s02] >>> started a fight at any moment in the window S02 pressed in.")
	elif in_range < samples:
		print("[s02] >>> The offer came and went while the player stood still. A")
		print("[s02] >>> single press at a fixed point is a coin toss against a")
		print("[s02] >>> creature that wanders.")
	else:
		print("[s02] >>> The offer stood the whole time, so distance from THIS point")
		print("[s02] >>> is not what stopped S02, and the cause is elsewhere.")

	# And the confirmation: walk in and press, so "could not" is not inferred
	# from a prompt string alone.
	var practice2: Variant = director.call("wild_creature")
	if practice2 != null:
		var close := (practice2 as Node3D).global_position + Vector3(1.0, 0.0, 1.0)
		await _press_from(world, player, director, arbiter, close, "s02", "arm's length, creature out")


## The prompt with its BBCode glyph tag stripped, so a table stays a table.
func _plain(label: String) -> String:
	var out := label
	while out.contains("[img=") and out.contains("[/img]"):
		var a := out.find("[img=")
		var b := out.find("[/img]") + 6
		out = out.substr(0, a) + out.substr(b)
	return out.strip_edges()


## PASS 5 — is the load path broken, or merely un-pressed?
##
## The census that makes this the question: across S01-S05 of this run there is
## not one `combat_start` event. Not a fight that went badly — no fight at all,
## in five segments, including a whole tournament. Pass 2 measured why: after
## `save_game.gd::load_slot()` the party is restored but no follower body is,
## `_sync_active_creature()` declines to summon when nothing is out ("the new
## active creature comes out on next recall"), and `_engageable()` returns null
## on a null ally BEFORE it ever measures a distance. Every journey segment from
## S03 on begins with a load.
##
## Two very different findings fit that, and only one of them is about the game:
##
##   GAME — a loaded save cannot fight. The player is stranded with a party they
##          cannot deploy, and the chapter is unplayable from any save.
##   RIG  — a loaded save needs one press of `creature_recall` to put the
##          creature back out, exactly as the on-screen line says, and no journey
##          step-script in this protocol ever presses it. S01-S10 contain zero
##          occurrences of the action; X01, X02, X03 and X06 contain it.
##
## So this loads S02's exit save, presses the button the game's own prompt names,
## and then tries to engage. If a fight starts, the game was never broken here
## and the whole downstream silence is the harness's.
func _pass5(world: Node, player: CharacterBody3D, director: Node, arbiter: Node) -> void:
	print("--- PASS 5: after a load, press the button the prompt names --------")
	if not _seed_save():
		print("[load] could not seed the exit save; PASS 5 cannot run")
		return
	var game := root.get_node_or_null(^"/root/Game")
	var saver: Object = _saver(game) if game != null else null
	if saver == null:
		print("[load] no save system reachable; PASS 5 cannot run")
		return
	print("[load] load_slot(%d) -> %s" % [SLOT, bool(saver.call("load_slot", game, SLOT))])
	for i in LOAD_SETTLE_FRAMES:
		await physics_frame

	print("[load] after the load: party = %d, ally_body = %s"
		% [_party_size(), "NULL" if director.call("ally_body") == null else "present"])
	var offer_before: Variant = director.call("interaction_offer", player.global_position)
	print("[load] the line the game shows      = %s"
		% _plain(str((offer_before as Dictionary).get("label", "")) if offer_before is Dictionary else ""))
	print("[load] ...and it is actionable      = %s"
		% (bool((offer_before as Dictionary).get("actionable", false)) if offer_before is Dictionary else false))
	print("[load] ...which is why `interact` does nothing: the verb it names is")
	print("[load]    `creature_recall`, RB, and `interact` is X.")
	print("")

	# The press the prompt asks for. Same shape as every other synthetic press
	# here: the parsed physical event and the action beside it.
	var ev := InputEventJoypadButton.new()
	ev.button_index = JOY_BUTTON_RIGHT_SHOULDER
	ev.pressed = true
	Input.parse_input_event(ev)
	Input.action_press("creature_recall")
	await physics_frame
	var up := InputEventJoypadButton.new()
	up.button_index = JOY_BUTTON_RIGHT_SHOULDER
	up.pressed = false
	Input.parse_input_event(up)
	Input.action_release("creature_recall")
	for i in 180:
		await physics_frame

	var ally: Variant = director.call("ally_body")
	print("[load] one press of creature_recall -> ally_body = %s"
		% ["STILL NULL" if ally == null else str((ally as Node3D).name)])
	if ally == null:
		print("[load] >>> the game cannot put the creature back out after a load.")
		print("[load] >>> That is a GAME finding and it strands every save.")
		return

	var practice: Variant = director.call("wild_creature")
	if practice == null:
		print("[load] no wild creature to try; inconclusive")
		return
	var close := (practice as Node3D).global_position + Vector3(1.0, 0.0, 1.0)
	await _press_from(world, player, director, arbiter, close, "load", "arm's length, after one RB")
	print("[load] === THE ANSWER ===========================================")
	print("[load] If a fight started above, the load path is sound and every")
	print("[load] silent segment from S03 on is the harness never pressing a")
	print("[load] button the game puts on screen and no journey step contains.")
