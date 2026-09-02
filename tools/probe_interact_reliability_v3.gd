extends SceneTree
## OWNER-0901-INTERACT-RELIABILITY-V3.
##
## V2 (ralph/DONE.md, tools/probe_interact_flake.gd + probe_interact_approach.gd
## + probe_interact_lag.gd + probe_arbiter_race.gd) closed one real staleness
## window in interaction_arbiter.gd but said so itself, in its own commit
## message: "not a confirmed root cause of the owner's 'about half the time'
## report, which this session could not pin down through headless simulation."
## All four of its probes exercise exactly one situation -- Wilhelm's dialogue,
## stationary or walking-in -- which V2 also owns end to end (open on the
## physics tick, matching the arbiter). Real play uses `interact` for five
## different things, and one of them is NOT read on the same clock as the
## other four.
##
## This probe measures a SINGLE real controller press's success rate,
## end-to-end through the real InputMap (InputEventJoypadButton via
## Input.parse_input_event, never Input.action_press), across the five
## situations the owner's session actually presses the button in:
##
##   1. NPC dialogue (open/advance/close) -- Wilhelm, same fixture V2 used.
##   2. World pickups -- berries bushes (data/config/bands/band1_lower_meadows/
##      harvest.json), tool-free so a miss cannot be confused with a correct
##      "wrong tool" refusal.
##   3. A station panel -- the creature bed's Rest UI, a real BuildPlacer-
##      placed fixture, opened and closed on repeat.
##   4. The build catalogue via the hammer -- `playground_hud.gd::
##      _hammer_opens_the_catalogue()`, called from `_read_world_hotkeys()`,
##      called from `PlaygroundHUD._process()`. That is the IDLE/render-frame
##      clock. `interaction_arbiter.gd`, `dialogue_panel.gd` and the combat
##      manager all read `interact` from `_physics_process()` instead, by
##      explicit design (see interaction_arbiter.gd's own OWNER-0901 comment).
##      The hammer path is the one `interact` consumer on the OTHER clock, and
##      nothing in V2's four probes ever pressed a button anywhere near it.
##      Run once at native speed and once under an artificial physics-tick
##      stall (`probe_interact_lag.gd`'s own technique) that forces several
##      physics ticks to batch inside one process frame, the exact shape of a
##      real frame hitch.
##   5. The post-modal-close race named directly in this task: close a
##      conversation, then press `interact` again almost immediately (0-4
##      frames later) to open a fresh one on the same NPC -- exercising
##      `sequence_director.gd::_refresh_lockout()`, which recomputes the
##      arbiter's `_enabled` flag once per IDLE frame while the arbiter reads
##      it on the PHYSICS tick, the identical class of cross-clock staleness
##      V2 closed for `_winner`/`_winning_provider` but never touched here.
##
##   godot --headless --path . --script tools/probe_interact_reliability_v3.gd
##
## Every situation prints its own N attempts / M misses. Nothing here retries
## a press that missed -- one tap, one verdict, per `ralph/conventions.md`'s
## own rule that a poll-only/forgiving-retry test hides the exact flake rate
## an owner report like this one is asking about.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 300
const CHECK_FRAMES := 20

const TRIALS_DIALOGUE := 25
const TRIALS_STATION := 15
const TRIALS_BUILD_NORMAL := 20
const TRIALS_BUILD_LAGGED := 24
const TRIALS_RACE := 20

const STALL_MSEC := 70
const STALL_EVERY_N_TICKS := 3

const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
const PROMPT_ARBITER := preload("res://scripts/world/prompt_arbiter.gd")

var _world: Node = null
var _player: CharacterBody3D = null
var _rig: Node3D = null
var _panel: Node = null
var _arbiter: Node = null
var _game: Node = null
var _wilhelm: Node3D = null
var _interact_button: int = -1
var _tick_count := 0

## section -> {attempts, misses, log: Array[String]}
var _sections: Dictionary = {}


func _init() -> void:
	_run()


func _run() -> void:
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame

	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	_panel = _world.get_node_or_null(^"DialoguePanel")
	_arbiter = get_first_node_in_group("interaction_arbiter")
	_game = root.get_node_or_null(^"Game")
	var village := _world.get_node_or_null(^"VillageNPCs")
	_wilhelm = village.get_node_or_null(^"Wilhelm") as Node3D if village != null else null
	_interact_button = _pad_button_for("interact")

	if _player == null or _rig == null or _panel == null or _arbiter == null \
			or _game == null or _wilhelm == null or _interact_button < 0:
		print("probe FAIL: missing player/rig/panel/arbiter/Game/Wilhelm/interact binding")
		quit(1)
		return

	var director := _world.find_child("SequenceDirector", true, false)
	if director != null and director.has_method("_set_beat"):
		director.call("_set_beat", "free_play")
	var party: RefCounted = _game.get("party")
	while party != null and int(party.call("size")) < 1:
		var creature: RefCounted = _game.call("make_creature", "terrapup")
		if creature == null or not bool(party.call("add", creature)):
			break
	_game.set("free_build", true)
	for i in 12:
		await physics_frame

	await _section_dialogue()
	await _section_pickups()
	await _section_station()
	await _section_build_normal()
	await _section_build_lagged()
	await _section_post_modal_race()

	_report()


## --- shared input plumbing ---------------------------------------------------

func _pad_button_for(action: String) -> int:
	if not InputMap.has_action(action):
		return -1
	for event in InputMap.action_get_events(action):
		var button := event as InputEventJoypadButton
		if button != null:
			return button.button_index
	return -1


func _look_jitter() -> void:
	var e := InputEventJoypadMotion.new()
	e.axis = 2  # right stick X -- look_left/look_right, project.godot
	e.axis_value = 0.35 + randf() * 0.1
	Input.parse_input_event(e)


func _stop_look_jitter() -> void:
	var e := InputEventJoypadMotion.new()
	e.axis = 2
	e.axis_value = 0.0
	Input.parse_input_event(e)


## ONE real button down/up on the live InputMap's own joypad binding, camera
## look jittered across it the way probe_interact_flake.gd established --
## still nudging the stick while tapping is the realistic condition, not a
## corner case. Polls `check` every frame after the release, up to
## `max_wait` frames, returning true the moment it is satisfied (never
## re-pressing) or false once the budget runs out.
func _measured_tap(check: Callable, max_wait: int = CHECK_FRAMES) -> bool:
	var down := InputEventJoypadButton.new()
	down.button_index = _interact_button
	down.pressed = true
	Input.parse_input_event(down)
	_look_jitter()
	await physics_frame
	_look_jitter()
	await physics_frame
	var up := InputEventJoypadButton.new()
	up.button_index = _interact_button
	up.pressed = false
	Input.parse_input_event(up)
	_look_jitter()
	var ok := false
	for i in max_wait:
		if check.call():
			ok = true
			break
		_look_jitter()
		await physics_frame
	if not ok:
		ok = bool(check.call())
	_stop_look_jitter()
	for i in 10:
		await physics_frame
	return ok


## Same shape, but every frame is a `_tick()` (stalled-clock) frame rather
## than a plain `physics_frame` -- see `_tick()` for what that manufactures.
func _measured_tap_lagged(check: Callable, max_wait: int = CHECK_FRAMES) -> bool:
	var down := InputEventJoypadButton.new()
	down.button_index = _interact_button
	down.pressed = true
	Input.parse_input_event(down)
	await _tick()
	await _tick()
	var up := InputEventJoypadButton.new()
	up.button_index = _interact_button
	up.pressed = false
	Input.parse_input_event(up)
	var ok := false
	for i in max_wait:
		if check.call():
			ok = true
			break
		await _tick()
	if not ok:
		ok = bool(check.call())
	for i in 10:
		await _tick()
	return ok


## Not a measured press -- cleanup/setup only. Real InputMap button, no retry
## loop, but not scored against any section.
func _raw_tap(action: String) -> void:
	var idx := _pad_button_for(action)
	if idx < 0:
		return
	var down := InputEventJoypadButton.new()
	down.button_index = idx
	down.pressed = true
	Input.parse_input_event(down)
	for i in 4:
		await physics_frame
	var up := InputEventJoypadButton.new()
	up.button_index = idx
	up.pressed = false
	Input.parse_input_event(up)
	for i in 8:
		await physics_frame


## A physics_frame, with an occasional artificial stall first -- same
## technique as tools/probe_interact_lag.gd, which manufactures Godot's own
## fixed-timestep catch-up (several `_physics_process` calls batched inside
## one `_process` call) the way a real frame hitch on the ROG Ally does.
func _tick() -> void:
	_tick_count += 1
	if _tick_count % STALL_EVERY_N_TICKS == 0:
		OS.delay_msec(STALL_MSEC)
	await physics_frame


func _teleport_to(at: Vector3) -> void:
	var y := float(_world.call("ground_height_at", at.x, at.z)) if _world.has_method("ground_height_at") else _player.global_position.y
	_player.global_position = Vector3(at.x, y + 0.2, at.z)
	_player.velocity = Vector3.ZERO
	for i in 12:
		await physics_frame


func _face(target: Vector3) -> void:
	var to := target - _player.global_position
	to.y = 0.0
	if to.length() > 0.01:
		_rig.set("yaw", atan2(-to.x, -to.z))


func _teleport_near(target: Node3D, distance: float = 1.6) -> void:
	var spot := target.global_position + Vector3(distance, 0.0, 0.0)
	spot.y = float(_world.call("ground_height_at", spot.x, spot.z)) + 1.0
	_player.global_position = spot
	_player.velocity = Vector3.ZERO
	_face(target.global_position)
	for i in 20:
		await physics_frame


func _wait_provider(provider: Node, max_wait: int = 30) -> bool:
	for i in max_wait:
		await physics_frame
		if _arbiter.call("winning_provider") == provider:
			return true
	return false


func _wait_open_script(suffix: String, max_wait: int = 30) -> Node:
	for i in max_wait:
		await process_frame
		for node: Node in get_nodes_in_group(INPUT_OWNER.GROUP):
			var script: Script = node.get_script() as Script
			if script != null and str(script.resource_path).ends_with(suffix) \
					and node.has_method("is_open") and bool(node.call("is_open")):
				return node
	return null


func _record(section: String, ok: bool, label: String) -> void:
	if not _sections.has(section):
		_sections[section] = {"attempts": 0, "misses": 0, "log": []}
	var s: Dictionary = _sections[section]
	s["attempts"] = int(s["attempts"]) + 1
	if not ok:
		s["misses"] = int(s["misses"]) + 1
		(s["log"] as Array).append(label)


## --- 1. NPC dialogue: open / advance / close ---------------------------------

func _section_dialogue() -> void:
	print("\n--- 1. NPC dialogue (Wilhelm), %d trials ---" % TRIALS_DIALOGUE)
	await _teleport_near(_wilhelm, 2.2)
	if not await _wait_provider(_wilhelm.get_node_or_null(^"Interactable")):
		print("  SETUP FAIL: Wilhelm's prompt never won -- skipping this section")
		return
	for trial in TRIALS_DIALOGUE:
		if bool(_panel.call("is_open")):
			_record("1_dialogue", false, "trial %d: panel already open before the cycle started" % trial)
			continue
		var opened := await _measured_tap(func() -> bool:
			return bool(_panel.call("is_open")) and int(_panel.get("_runner").call("line").get("index", -1)) == 0)
		_record("1_dialogue", opened, "trial %d open" % trial)
		if not opened:
			# Recover so the next trial starts clean regardless.
			if bool(_panel.call("is_open")):
				var guard := 0
				while bool(_panel.call("is_open")) and guard < 10:
					await _raw_tap("interact")
					guard += 1
			continue
		var advanced := await _measured_tap(func() -> bool:
			return bool(_panel.call("is_open")) and int(_panel.get("_runner").call("line").get("index", -1)) == 1)
		_record("1_dialogue", advanced, "trial %d advance" % trial)
		var closed := await _measured_tap(func() -> bool:
			return not bool(_panel.call("is_open")))
		_record("1_dialogue", closed, "trial %d close" % trial)
		if bool(_panel.call("is_open")):
			var guard2 := 0
			while bool(_panel.call("is_open")) and guard2 < 10:
				await _raw_tap("interact")
				guard2 += 1


## --- 2. World pickups: tool-free berries bushes ------------------------------

func _berries_nodes() -> Array:
	var found: Array = []
	for node: Node in get_nodes_in_group("harvestable"):
		if node.has_method("resource_item") and str(node.call("resource_item")) == "berries" \
				and node is Node3D and (node as Node3D).is_inside_tree():
			var prompt := (node as Node3D).get_node_or_null(^"Interactable")
			if prompt != null:
				found.append(node)
		if found.size() >= 8:
			break
	return found


func _section_pickups() -> void:
	var bushes := _berries_nodes()
	print("\n--- 2. World pickups (berries bushes), %d found ---" % bushes.size())
	if bushes.is_empty():
		print("  SETUP FAIL: no tool-free berries nodes found in the built world -- skipping")
		return
	for i in bushes.size():
		var bush: Node3D = bushes[i]
		var prompt := bush.get_node_or_null(^"Interactable")
		await _teleport_near(bush, 1.6)
		if not await _wait_provider(prompt):
			_record("2_pickup", false, "bush %d: prompt never won" % i)
			continue
		var got := await _measured_tap(func() -> bool:
			return not bool(prompt.get("enabled")))
		_record("2_pickup", got, "bush %d at %s" % [i, bush.global_position])


## --- 3. Station panel: creature bed Rest UI ----------------------------------

func _place_bed_fixture() -> Node3D:
	await _teleport_to(Vector3(70.0, 0.0, 70.0))
	_game.set("pending_build", "creature_bed")
	for i in 20:
		await physics_frame
	var before := _placed_count("creature_bed")
	await _raw_tap("build_place")
	for i in 20:
		await physics_frame
	_game.set("pending_build", "")
	if _placed_count("creature_bed") != before + 1:
		return null
	for node: Node in get_nodes_in_group("placed_building"):
		if str(node.get_meta("building_id", "")) == "creature_bed":
			return node as Node3D
	return null


func _placed_count(id: String) -> int:
	var count := 0
	for node: Node in get_nodes_in_group("placed_building"):
		if str(node.get_meta("building_id", "")) == id:
			count += 1
	return count


func _section_station() -> void:
	print("\n--- 3. Station panel (creature bed Rest UI), %d trials ---" % TRIALS_STATION)
	var bed := await _place_bed_fixture()
	if bed == null:
		print("  SETUP FAIL: could not place a creature bed fixture -- skipping this section")
		return
	var prompt := bed.get_node_or_null(^"Interactable")
	for trial in TRIALS_STATION:
		await _teleport_near(bed, 1.6)
		if not await _wait_provider(prompt):
			_record("3_station", false, "trial %d: prompt never won" % trial)
			continue
		var opened := await _measured_tap(func() -> bool:
			for node: Node in get_nodes_in_group(INPUT_OWNER.GROUP):
				var script: Script = node.get_script() as Script
				if script != null and str(script.resource_path).ends_with("creature_bed_panel.gd") \
						and node.has_method("is_open") and bool(node.call("is_open")):
					return true
			return false)
		_record("3_station", opened, "trial %d open" % trial)
		# Close whatever opened (or partially opened) before the next trial.
		var panel := await _wait_open_script("creature_bed_panel.gd", 5)
		if panel != null:
			await _raw_tap("menu_cancel")
			var guard := 0
			while bool(panel.call("is_open")) and guard < 10:
				await _raw_tap("menu_cancel")
				guard += 1


## --- 4. Build catalogue via the hammer (idle-frame clock) --------------------

## `_hammer_opens_the_catalogue()` (playground_hud.gd) stands down only when
## the arbiter's winner is ACTIONABLE (`prompt_arbiter.gd::is_actionable`) --
## `encounter_director.gd`'s own non-actionable "[RB] Call out <creature>"
## status line, which the party makes near-universal once seeded, does NOT
## stand it down (that is the whole point of `_winner_would_refuse_this_hand()`
## in the real code: a line that was never going to consume the button should
## not cost the hammer its own button either). So "clear" here means no
## ACTIONABLE winner, matching that real gate exactly -- checking raw
## `winner().is_empty()` instead made every spot in the world look occupied
## and this search always failed.
##
## Searches the AUTHORED spawn clearing first (data/config/bands/
## band1_lower_meadows/vegetation.json's clearings[0]: x=0,z=0,r=16,
## "_why": "spawn") -- a disc where the scatter deliberately places nothing,
## rather than open-ended rings around wherever a previous section left the
## player, which are just as likely to be mid-scatter as clear. A 24m
## fallback sweep from the player's own current position covers the case
## where even the spawn clearing has something (an NPC, a hand-placed
## harvest node) standing in every sampled spot.
func _find_clear_spot() -> Vector3:
	var near_radii: Array[float] = [2.0, 4.0, 6.0, 8.0, 10.0, 12.0, 14.0]
	var spot := await _search_rings(Vector3.ZERO, near_radii)
	if spot != Vector3.INF:
		return spot
	var far_radii: Array[float] = [0.0, 6.0, 12.0, 18.0, 24.0]
	return await _search_rings(_player.global_position, far_radii)


func _search_rings(base: Vector3, radii: Array[float]) -> Vector3:
	var angles: Array[float] = [0.0, PI * 0.25, PI * 0.5, PI * 0.75, PI, PI * 1.25, PI * 1.5, PI * 1.75]
	for radius in radii:
		for angle in angles:
			var spot: Vector3 = base + Vector3(cos(angle), 0.0, sin(angle)) * radius
			await _teleport_to(spot)
			for i in 10:
				await physics_frame
			if not PROMPT_ARBITER.is_actionable(_arbiter.call("winner") as Dictionary):
				return spot
			if radius == 0.0:
				break
	return Vector3.INF


func _section_build_normal() -> void:
	print("\n--- 4a. Build catalogue via hammer, native speed, %d trials ---" % TRIALS_BUILD_NORMAL)
	var spot := await _find_clear_spot()
	if spot == Vector3.INF:
		print("  SETUP FAIL: could not find ground with no competing interactable -- skipping this section")
		return
	_game.set("equipped_tool", "hammer")
	for i in 6:
		await physics_frame
	for trial in TRIALS_BUILD_NORMAL:
		await _teleport_to(spot)
		var opened := await _measured_tap(func() -> bool:
			for node: Node in get_nodes_in_group("build_menu"):
				if node.has_method("is_open") and bool(node.call("is_open")):
					return true
			return false)
		_record("4a_build_hammer_normal", opened, "trial %d" % trial)
		for node: Node in get_nodes_in_group("build_menu"):
			if node.has_method("is_open") and bool(node.call("is_open")):
				node.call("close", false)
		for i in 10:
			await physics_frame
		_game.set("equipped_tool", "hammer")
		for i in 4:
			await physics_frame


func _section_build_lagged() -> void:
	print("\n--- 4b. Build catalogue via hammer, UNDER SIMULATED LAG, %d trials ---" % TRIALS_BUILD_LAGGED)
	var spot := await _find_clear_spot()
	if spot == Vector3.INF:
		print("  SETUP FAIL: could not find ground with no competing interactable -- skipping this section")
		return
	_game.set("equipped_tool", "hammer")
	for i in 6:
		await physics_frame
	for trial in TRIALS_BUILD_LAGGED:
		await _teleport_to(spot)
		var opened := await _measured_tap_lagged(func() -> bool:
			for node: Node in get_nodes_in_group("build_menu"):
				if node.has_method("is_open") and bool(node.call("is_open")):
					return true
			return false)
		_record("4b_build_hammer_lagged", opened, "trial %d (tick phase %d)" % [trial, _tick_count % STALL_EVERY_N_TICKS])
		for node: Node in get_nodes_in_group("build_menu"):
			if node.has_method("is_open") and bool(node.call("is_open")):
				node.call("close", false)
		for i in 10:
			await physics_frame
		_game.set("equipped_tool", "hammer")
		for i in 4:
			await physics_frame


## --- 5. Post-modal-close race: close a conversation, reopen almost at once ---
##
## `sequence_director.gd::_refresh_lockout()` recomputes the arbiter's
## `_enabled` flag once per IDLE frame (`_process`), and
## `interaction_arbiter.gd::_physics_process()` reads it on the PHYSICS tick.
## The close-press and the very next open-press can land on physics ticks
## either side of the idle frame that flips `_enabled` back to true -- the
## delay swept below (0-4 physics frames) brackets that window.
func _section_post_modal_race() -> void:
	print("\n--- 5. Close dialogue then reopen within 0-4 frames, %d trials ---" % TRIALS_RACE)
	await _teleport_near(_wilhelm, 2.2)
	var prompt := _wilhelm.get_node_or_null(^"Interactable")
	if not await _wait_provider(prompt):
		print("  SETUP FAIL: Wilhelm's prompt never won -- skipping this section")
		return
	for trial in TRIALS_RACE:
		var delay := trial % 5
		if bool(_panel.call("is_open")):
			_record("5_post_modal_race", false, "trial %d: panel already open before cycle" % trial)
			continue
		var opened := await _measured_tap(func() -> bool:
			return bool(_panel.call("is_open")) and int(_panel.get("_runner").call("line").get("index", -1)) == 0)
		if not opened:
			_record("5_post_modal_race", false, "trial %d: initial open missed, skipping race window" % trial)
			if bool(_panel.call("is_open")):
				var g := 0
				while bool(_panel.call("is_open")) and g < 10:
					await _raw_tap("interact")
					g += 1
			continue
		await _measured_tap(func() -> bool:
			return bool(_panel.call("is_open")) and int(_panel.get("_runner").call("line").get("index", -1)) == 1)
		var closed := await _measured_tap(func() -> bool:
			return not bool(_panel.call("is_open")))
		if not closed:
			_record("5_post_modal_race", false, "trial %d: close itself missed, skipping race window" % trial)
			if bool(_panel.call("is_open")):
				var g2 := 0
				while bool(_panel.call("is_open")) and g2 < 10:
					await _raw_tap("interact")
					g2 += 1
			continue
		# The race window itself: `delay` bare physics frames with nothing
		# read, then ONE real press aimed at reopening.
		for i in delay:
			await physics_frame
		var reopened := await _measured_tap(func() -> bool:
			return bool(_panel.call("is_open")) and int(_panel.get("_runner").call("line").get("index", -1)) == 0)
		_record("5_post_modal_race", reopened, "trial %d: reopen after %d-frame gap" % [trial, delay])
		if bool(_panel.call("is_open")):
			var g3 := 0
			while bool(_panel.call("is_open")) and g3 < 10:
				await _raw_tap("interact")
				g3 += 1


## --- reporting -----------------------------------------------------------------

func _report() -> void:
	print("\n==================== INTERACT RELIABILITY V3 SUMMARY ====================")
	var total_attempts := 0
	var total_misses := 0
	var order := ["1_dialogue", "2_pickup", "3_station", "4a_build_hammer_normal",
			"4b_build_hammer_lagged", "5_post_modal_race"]
	for key in order:
		if not _sections.has(key):
			print("%-28s: NOT RUN (setup failed)" % key)
			continue
		var s: Dictionary = _sections[key]
		var attempts := int(s["attempts"])
		var misses := int(s["misses"])
		total_attempts += attempts
		total_misses += misses
		var rate := 100.0 * float(misses) / float(maxi(1, attempts))
		print("%-28s: %3d attempts, %2d misses (%.1f%% miss rate)" % [key, attempts, misses, rate])
		for line in (s["log"] as Array):
			print("    miss/fail: %s" % line)
	print("---------------------------------------------------------------------------")
	print("TOTAL: %d attempts, %d misses (%.1f%%)" % [
		total_attempts, total_misses, 100.0 * float(total_misses) / float(maxi(1, total_attempts))])
	print("=============================================================================")
	quit(0 if total_misses == 0 else 1)
