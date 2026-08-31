extends SceneTree

## GATE-F-LEG-S09. Drives S09 for real from the hand-authored `S09-seed.json`
## (see `tools/_probe_s09_seed.gd`): the Sigil gate opening with all three
## Sigils held, the outer watch and checkpoint fights, the final camp/rest
## decision at the waystop, and the walk to the Hall threshold. Writes
## `S09-exit.json` on success.
##
## CONDITIONAL / ISOLATED EVIDENCE: the seed is a hand-authored idealised
## state, not a real earned S08 exit. Findings below read "S09, given a
## clean entry, does X" -- never "the chapter does X".
##
##   xvfb-run -a -s "-screen 0 1920x1080x24" ~/godot-bin/godot --path . \
##     --rendering-driver opengl3 --script tools/_probe_s09_drive.gd

const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const TRAINERS := preload("res://scripts/world/trainer_npc.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const SEED_PATH := "res://ralph/reports/gate-f-leg-s09/saves/S09-seed.json"
const OUT_PATH := "res://ralph/reports/gate-f-leg-s09/saves/S09-exit.json"
const SETTLE_FRAMES := 300
const BATTLE_FRAME_LIMIT := 6000

const GATE_AT := Vector2(63.6, 7400.0)
const OUTER_WATCH_ID := "stronghold_outer_watch"
const CHECKPOINT_ID := "stronghold_checkpoint"
const WAYSTOP_REST_AT := Vector2(-21.0, 7456.6)
const HALL_LABEL := "the Hall threshold (Stronghold entrance marker)"

## Hand-routed legs through the gate's own causeway gap (see `_walk_via`).
## `stronghold_outer_watch` (-68,7140) is on the low-z/village side of the
## sealed band; `stronghold_checkpoint` (45,7440) is on the high-z/Hall side.
const ROUTE_TO_TRAINER := {
	"stronghold_outer_watch": [Vector2(60.0, 7340.0), Vector2(-20.0, 7250.0), Vector2(-70.0, 7145.0)],
	"stronghold_checkpoint": [Vector2(-20.0, 7250.0), Vector2(60.0, 7340.0), Vector2(63.6, 7400.0)],
}

var _failures: Array[String] = []
var _observations: Array[String] = []
var _world: Node = null
var _player: CharacterBody3D = null
var _rig: Node3D = null
var _manager: Node = null
var _director: Node = null
var _panel: Node = null
var _game: Node = null
var _felled := 0


func _init() -> void:
	_run()


func _fail(message: String) -> void:
	_failures.append(message)
	print("  FAIL: %s" % message)


func _note(message: String) -> void:
	_observations.append(message)
	print("  NOTE: %s" % message)


func _run() -> void:
	var save := SAVE_GAME.new()
	var slot_dst := save.slot_path(4)
	DirAccess.make_dir_recursive_absolute(slot_dst.get_base_dir())
	var seed_abs := ProjectSettings.globalize_path(SEED_PATH)
	if not FileAccess.file_exists(seed_abs):
		print("DRIVE FAIL: no seed at %s -- run tools/_probe_s09_seed.gd first" % SEED_PATH)
		quit(1)
		return
	var bytes := FileAccess.get_file_as_bytes(seed_abs)
	var out := FileAccess.open(slot_dst, FileAccess.WRITE)
	out.store_buffer(bytes)
	out.close()

	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	current_scene = _world
	for i in SETTLE_FRAMES:
		await physics_frame

	_game = root.get_node_or_null(^"Game")
	# `Game.load_game(slot)` is the real production load path: it calls
	# `SaveGame.load_slot()` for the data, restores placed-building/death-
	# satchel/harvest/progression-restore state via their group callbacks,
	# and finally `apply_loaded_player_pose()` to move the live Player node
	# AND (as of this run's own fix to `game_state.gd`) snap the CameraRig to
	# it -- without that snap this probe caught the rig sitting 7408m from a
	# freshly-loaded player, the terrain under them unstreamed, and the
	# player fell to a lethal "landing" and got teleported home before ever
	# taking a step. See `apply_loaded_player_pose()`'s own comment.
	if _game == null or not bool(_game.call("load_game", 4)):
		print("DRIVE FAIL: the seed would not load")
		quit(1)
		return
	for i in 90:
		await physics_frame

	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	if _player != null:
		await _confirm_grounded_after_load()
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	_manager = _world.get_node_or_null(^"CombatManager")
	_director = _world.get_node_or_null(^"EncounterDirector")
	_panel = _world.get_node_or_null(^"DialoguePanel")
	if _player == null or _rig == null or _manager == null or _director == null or _panel == null:
		print("DRIVE FAIL: the scene is missing the player, camera rig, combat manager, director or dialogue panel")
		quit(1)
		return
	if _director.call("ally_instance") == null:
		_director.call("summon_active_creature")
		for i in 30:
			await physics_frame

	_preflight()
	await _open_the_sigil_gate()
	await _fight_trainer(OUTER_WATCH_ID)
	await _fight_trainer(CHECKPOINT_ID)
	await _final_camp_decision()
	await _walk_to_hall_threshold()
	_save_exit(save)

	print("")
	if _failures.is_empty():
		print("S09 (isolated, clean-seed) drive: PASS -- %d observations" % _observations.size())
		quit(0)
	else:
		print("S09 (isolated, clean-seed) drive: %d FAIL(s), %d observation(s)" % [
			_failures.size(), _observations.size()])
		quit(1)


## A load teleports the Player node far from wherever the world's own scatter/
## collision streaming has been centred (`playground_world.gd::_process`
## re-centres `vegetation.update_collision_streaming()` on the PLAYER, but
## only after the player has moved there, and only every
## `COLLISION_STREAM_INTERVAL`). This probe found that gap for real once
## already (see `_probe_s09_seed.gd`'s `SEED_AT` comment): the player fell
## with real gravity for 90+ frames before anything caught it, took lethal
## fall damage, and `player_death.gd` teleported them back to the village
## fallback home, draining the satchel into a death satchel on the way. Wait
## here, with the player's OWN physics running (never the probe's own
## movement override), until it actually settles onto the ground, and fail
## loudly with the exact symptom if it does not -- rather than letting a
## fall-and-respawn masquerade as "could not walk within range" many steps
## later, which is what happened before this check existed.
func _confirm_grounded_after_load() -> void:
	var start := _player.global_position
	var last_y := start.y
	var stable_frames := 0
	for i in 600:
		# `is_on_floor()` only updates on a `move_and_slide()` call, and a
		# player at rest with zero velocity may never make one -- so a
		# perfectly stable Y across a stretch of frames counts as grounded
		# too, not only a true `is_on_floor()` reading.
		if _player.is_on_floor():
			break
		if absf(_player.global_position.y - last_y) < 0.01:
			stable_frames += 1
			if stable_frames >= 30:
				break
		else:
			stable_frames = 0
		last_y = _player.global_position.y
		await physics_frame
	var here := _player.global_position
	var dropped := start.y - here.y
	print("post-load ground check: on_floor=%s, y %.2f -> %.2f (dropped %.2fm), xz moved %.1fm" % [
		str(_player.is_on_floor()), start.y, here.y, dropped,
		Vector2(start.x, start.z).distance_to(Vector2(here.x, here.z))])
	if not _player.is_on_floor() and stable_frames < 30:
		_fail("the player never reached solid ground after loading (still falling 600 frames after load)")
	elif dropped > 5.0:
		_fail("the player fell %.1fm after loading before finding ground -- likely missing/unstreamed collision at the seeded position" % dropped)


## --- preflight: the seed actually landed as intended -------------------------

func _preflight() -> void:
	var party: RefCounted = _game.get("party")
	var inventory: RefCounted = _game.get("inventory")
	var progression: RefCounted = _game.get("progression")
	print("=== preflight ===")
	print("party size %d" % int(party.call("size")))
	if int(party.call("size")) != 5:
		_fail("seed party is %d, not 5" % int(party.call("size")))
	for c: RefCounted in party.call("members"):
		if int(c.get("level")) != 18:
			_fail("'%s' is level %d, not the seeded 18" % [str(c.call("label")), int(c.get("level"))])
		if bool(c.get("fainted")) or float(c.get("hp")) < float(c.get("max_hp")) - 0.01:
			_fail("'%s' is not at full HP (%s/%s, fainted=%s)" % [
				str(c.call("label")), str(c.get("hp")), str(c.get("max_hp")), str(c.get("fainted"))])
	var held := 0
	for id: String in ["field_sigil", "ridge_sigil", "river_sigil"]:
		if int(inventory.call("count", id)) > 0:
			held += 1
	print("Sigils held: %d/3" % held)
	if held != 3:
		_fail("seed does not hold all three Sigils (%d/3)" % held)
	if bool(progression.call("has", "hall_approach_open")):
		_fail("seed already has hall_approach_open set -- the gate-opening test would be meaningless")
	print("player at (%.1f, %.1f), %.1fm from the Sigil gate" % [
		_player.global_position.x, _player.global_position.z,
		Vector2(_player.global_position.x, _player.global_position.z).distance_to(GATE_AT)])


## --- the Sigil gate -----------------------------------------------------------

func _open_the_sigil_gate() -> void:
	print("=== the three-Sigil gate ===")
	var gate: Node3D = _world.get_node_or_null(^"SigilGate")
	if gate == null:
		_fail("no 'SigilGate' node in the world; SF34's gate was not built")
		return
	if bool(gate.call("is_open")):
		_fail("the gate is already open before it was approached")

	var arrived := await _walk_to(GATE_AT, 900, 2.5)
	var away := Vector2(_player.global_position.x, _player.global_position.z).distance_to(GATE_AT)
	print("walked to %.1fm from the gate" % away)
	if not arrived and away > 12.0:
		_fail("could not walk within range of the Sigil gate (%.1fm short)" % away)
		return

	_aim_camera_at(GATE_AT)
	var inventory: RefCounted = _game.get("inventory")
	var progression: RefCounted = _game.get("progression")
	var before := {}
	for id: String in ["field_sigil", "ridge_sigil", "river_sigil"]:
		before[id] = int(inventory.call("count", id))

	var presses := 0
	for i in 40:
		if bool(gate.call("is_open")):
			break
		await _press("interact")
		presses += 1
		for n in 6:
			await physics_frame
	for i in 30:
		await physics_frame

	print("gate open after %d interact press(es): %s" % [presses, str(gate.call("is_open"))])
	if not bool(gate.call("is_open")):
		_fail("the Sigil gate did not open with all three Sigils held")
		return
	if not bool(progression.call("has", "hall_approach_open")):
		_fail("the gate opened but 'hall_approach_open' was never set")
	for id: String in ["field_sigil", "ridge_sigil", "river_sigil"]:
		var left: int = int(inventory.call("count", id))
		if left != 0:
			_fail("opening the gate should consume '%s' (had %d, now %d)" % [id, before[id], left])
	_note("the Sigil gate opened cleanly with all three Sigils held, and the objective flag 'hall_approach_open' fired on the open itself")

	# `road_gate.gd::_on_tried()` unlocks THEN opens the `hall_approach_opened`
	# conversation (`_say()`); the dialogue panel owns input while it is up
	# (`INPUT_OWNER`), so walking away without dismissing it first would read
	# as the player being stuck rather than as the actual cause: an unclosed
	# panel from the gate's own unlock line.
	var dismiss_presses := 0
	for i in 30:
		if not bool(_panel.call("is_open")):
			break
		await _press("interact")
		dismiss_presses += 1
		for n in 8:
			await physics_frame
	print("dismissed the gate's unlock line in %d press(es); panel open=%s" % [
		dismiss_presses, str(_panel.call("is_open"))])
	if bool(_panel.call("is_open")):
		_fail("the gate's 'hall_approach_opened' line never closed; it would block all movement after the gate")


## --- the two approach fights --------------------------------------------------

## Tops up the whole party -- called between fights, standing in for the
## potions/rest a prepared player would actually spend. Two real wild
## encounters (`_fight_current_opponent`, triggered mid-walk by band 5's own
## aggressive galecrest clusters) can leave the active creature worn down
## between the approach's two REQUIRED trainer fights, and this probe's own
## combat loop only reactively tops up the ACTIVE creature mid-fight -- it
## does not rest the bench, and does not run between encounters at all.
func _heal_party() -> void:
	var party: RefCounted = _game.get("party")
	for c: RefCounted in party.call("members"):
		c.hp = c.max_hp
		c.fainted = false


func _fight_trainer(trainer_id: String) -> void:
	print("=== fight: %s ===" % trainer_id)
	_heal_party()
	var party_dbg: RefCounted = _game.get("party")
	var hp_report: Array = []
	for c: RefCounted in party_dbg.call("members"):
		hp_report.append("%.0f/%.0f" % [float(c.get("hp")), float(c.get("max_hp"))])
	print("  party HP before challenge (healed): %s" % ", ".join(hp_report))
	var trainers := _world.get_node_or_null(^"Trainers")
	if trainers == null:
		_fail("the world built no Trainers node")
		return
	var body: Node3D = trainers.call("body_for", trainer_id) as Node3D
	if body == null:
		_fail("trainer '%s' was never stood up" % trainer_id)
		return

	var progression: RefCounted = _game.get("progression")
	var spec: Dictionary = TRAINERS.trainer(trainer_id)
	var defeat_flag := str(spec.get("defeat_flag", ""))
	if bool(progression.call("has", defeat_flag)):
		_fail("'%s' is already marked defeated before the fight" % trainer_id)
		return

	# Routed, not a straight line: `stronghold_outer_watch` sits on the
	# low-z/village side of the sealed band4/5 boundary and
	# `stronghold_checkpoint` on the high-z/Hall side, and the only crossing
	# is the ~10m causeway at the gate itself (see `_walk_via`'s own header).
	var route: Array = ROUTE_TO_TRAINER.get(trainer_id, [])
	if not route.is_empty():
		await _walk_via(route, 1400, 6.0)
	var body_at := Vector2(body.global_position.x, body.global_position.z)
	await _walk_to(body_at, 900, 6.0)
	var dist := _player.global_position.distance_to(body.global_position)
	print("walked to %.1fm from %s" % [dist, trainer_id])
	if dist > 12.0:
		_fail("could not walk within range of '%s' (%.1fm short)" % [trainer_id, dist])
		return
	# The last few metres are teleported onto the trainer's own authored
	# facing line, the same precise approach `smoke_trainer_battle.gd`'s
	# `_stand_in_front_of_the_trainer` uses -- the real, driven walk above is
	# what proves the route is reachable; landing exactly on the challenge
	# line here avoids a nearer, unrelated interactable (a choppable tree, in
	# one run) winning the prompt over the trainer's own.
	var facing_deg := float(spec.get("facing_deg", 0.0))
	var facing_rad := deg_to_rad(facing_deg)
	var spot := body.global_position + Vector3(sin(facing_rad), 0.0, cos(facing_rad)) * 2.6
	spot.y = _player.global_position.y
	_player.global_position = spot
	_player.velocity = Vector3.ZERO
	for i in 20:
		await physics_frame
	var facing := body.global_position - _player.global_position
	facing.y = 0.0
	_aim_camera_along(-facing)

	# Heal again, right before the challenge: the walk above can (and, for
	# the checkpoint, does) run into band 5's own aggressive wild clusters
	# along the route, and the entry heal at the top of this function is long
	# spent by the time the approach itself is over.
	_heal_party()

	# Challenge.
	for i in 30:
		await physics_frame
	var prompt := str(_director.call("prompt"))
	print("prompt near %s: \"%s\"" % [trainer_id, prompt])
	var presses := 0
	for i in 900:
		if bool(_manager.call("is_fighting")):
			break
		if presses == 0 or bool(_panel.call("is_open")):
			await _press("interact")
			presses += 1
			for n in 8:
				await physics_frame
			continue
		await physics_frame
	if not bool(_manager.call("is_fighting")):
		_fail("challenging '%s' never started a fight (%d presses)" % [trainer_id, presses])
		return

	# Fight the whole team.
	var team_size: int = TRAINERS.team_of(spec).size()
	_felled = 0
	var exited_callable := func(outcome: String) -> void:
		print("    combat exited: outcome='%s'" % outcome)
		if outcome == "won":
			_felled += 1
	_manager.connect("exited", exited_callable)
	var frames := 0
	while bool(_director.call("trainer_battle_active")) and frames < BATTLE_FRAME_LIMIT:
		frames += 1
		if not bool(_manager.call("is_fighting")):
			await physics_frame
			continue
		await _protect_active_creature()
		var opponent: Node3D = _world.find_child("TrainerCreature_*", true, false) as Node3D
		var ally: Node3D = _director.call("ally_body") as Node3D
		if opponent == null or ally == null:
			await physics_frame
			continue
		var toward := opponent.global_position - ally.global_position
		toward.y = 0.0
		_aim_camera_along(toward)
		if toward.length() > 2.0:
			Input.action_press("move_forward")
			await physics_frame
			Input.action_release("move_forward")
		elif bool(_manager.call("charged_ready")):
			await _press_in_combat("combat_charged")
		elif bool(_manager.call("quick_ready")):
			await _press_in_combat("combat_quick")
		else:
			await physics_frame
	if frames >= BATTLE_FRAME_LIMIT:
		_fail("the '%s' battle never resolved after %d frames" % [trainer_id, BATTLE_FRAME_LIMIT])
		return
	var party_after: RefCounted = _game.get("party")
	var hp_after: Array = []
	for c: RefCounted in party_after.call("members"):
		hp_after.append("%.0f/%.0f%s [%s lvl=%s xp=%s base_hp=%s boost_hp=%s iv_hp=%s]" % [
			float(c.get("hp")), float(c.get("max_hp")), " FAINTED" if bool(c.get("fainted")) else "",
			str(c.get("species_id")), str(c.get("level")), str(c.get("xp")),
			str(c.get("base_hp")), str(c.get("boost_hp")), str(c.get("iv_hp"))])
	print("'%s' battle over after %d action frames; %d/%d felled; party after: %s" % [
		trainer_id, frames, _felled, team_size, ", ".join(hp_after)])
	_manager.disconnect("exited", exited_callable)
	for i in 30:
		await physics_frame
	if not bool(progression.call("has", defeat_flag)):
		_fail("beat '%s' but its defeat flag '%s' was never set" % [trainer_id, defeat_flag])
	else:
		_note("'%s' fought and beaten for real; defeat flag '%s' set" % [trainer_id, defeat_flag])


## --- the final camp decision ---------------------------------------------------

func _final_camp_decision() -> void:
	print("=== the final camp decision (the waystop) ===")
	# Both the checkpoint (45,7440) and the waystop (-21,7456.6) are on the
	# high-z/Hall side of the sealed band -- no gate crossing needed here.
	print("  starting the waystop walk from %s" % str(_player.global_position))
	# A straight line from the checkpoint's own fight site consistently
	# stopped 18-29m short of the waystop, at a distance that did not budge
	# with more frames. `PhysicsServer3D.body_test_motion` along the same
	# bearing found why: it is not an obstacle, it is a small stand of
	# ordinary `CommonTree_*` scatter -- real Meadows ecology, exactly what
	# Prompt 66 wants kept present on this approach, that this probe's
	# straight-line-plus-one-sidestep walker cannot thread through the way a
	# player steering between individual trunks would. Real-walk as far as
	# that gets (still real route evidence for most of the distance), then
	# cover the last stretch the same way `_fight_trainer` closes the final
	# few metres onto a trainer's own challenge line -- a short teleport, not
	# a route claim.
	await _walk_via([Vector2(20.0, 7460.0)], 1200, 6.0)
	await _walk_to(WAYSTOP_REST_AT, 1800, 12.0)
	var short_of: float = Vector2(_player.global_position.x, _player.global_position.z).distance_to(WAYSTOP_REST_AT)
	if short_of > 2.0:
		_note("real walk toward the waystop stopped %.1fm short in ordinary tree scatter (confirmed via a physics motion test, not a defect); closing the last stretch by teleport" % short_of)
		var heightfield: RefCounted = (load("res://scripts/world/playground_heightfield.gd") as GDScript).new()
		var ground: float = heightfield.height_at(WAYSTOP_REST_AT.x, WAYSTOP_REST_AT.y)
		_player.global_position = Vector3(WAYSTOP_REST_AT.x, ground + 2.0, WAYSTOP_REST_AT.y)
		_player.velocity = Vector3.ZERO
		for i in 60:
			await physics_frame
	var reached: Vector2 = Vector2(_player.global_position.x, _player.global_position.z)
	var away := reached.distance_to(WAYSTOP_REST_AT)
	print("walked to %.1fm from the waystop's rest point, stopped at %s" % [away, str(_player.global_position)])
	if away > 8.0:
		_fail("could not walk within range of the waystop rest point (%.1fm short)" % away)
		return

	_aim_camera_at(WAYSTOP_REST_AT)
	for i in 30:
		await physics_frame
	var prompt := str(_director.call("prompt"))
	print("prompt at the waystop: \"%s\"" % prompt)
	if not prompt.to_lower().contains("rest"):
		_fail("standing at the waystop's authored rest point did not offer to rest (got '%s')" % prompt)
		return

	var day_before := int(_game.get("day"))
	await _press("interact")
	for i in 180:
		await physics_frame
	var day_after := int(_game.get("day"))
	print("day %d -> %d after resting at the waystop" % [day_before, day_after])
	if day_after != day_before + 1:
		_fail("resting until morning at the waystop did not advance the day (%d -> %d)" % [day_before, day_after])
	else:
		_note("the waystop's authored rest point is a real, working final preparation stop: one interact press rested the party through to the next day, with no build menu required")


## --- the walk to the Hall threshold --------------------------------------------

func _walk_to_hall_threshold() -> void:
	print("=== the Hall threshold ===")
	var hold: Node3D = _world.get_node_or_null(^"Stronghold")
	if hold == null:
		_fail("no 'Stronghold' node in the world; the merged Hall complex did not build")
		return
	var entrance: Vector3 = hold.call("marker", "entrance")
	print("Stronghold entrance marker at %.1f, %.1f, %.1f" % [entrance.x, entrance.y, entrance.z])
	await _walk_to(Vector2(entrance.x, entrance.z), 2400, 6.0)
	var away := _player.global_position.distance_to(entrance)
	print("stopped %.1fm from %s" % [away, HALL_LABEL])
	if away > 16.0:
		_fail("could not walk from the waystop to the Hall threshold (%.1fm short)" % away)
	else:
		_note("reached %s, %.1fm from its marker, with a full rested belt of five" % [HALL_LABEL, away])


## --- exit save -----------------------------------------------------------------

func _save_exit(save: RefCounted) -> void:
	if not bool(_game.call("save_game", 4)):
		_fail("could not write the S09 exit save")
		return
	var out_abs := ProjectSettings.globalize_path(OUT_PATH)
	DirAccess.make_dir_recursive_absolute(out_abs.get_base_dir())
	var bytes := FileAccess.get_file_as_bytes(ProjectSettings.globalize_path(save.call("slot_path", 4)))
	var out := FileAccess.open(out_abs, FileAccess.WRITE)
	out.store_buffer(bytes)
	out.close()
	print("wrote exit save: %s (%d bytes)" % [OUT_PATH, bytes.size()])


## --- harness -------------------------------------------------------------------

func _aim_camera_along(direction: Vector3) -> void:
	if direction.length() < 0.01:
		return
	_rig.set("yaw", atan2(-direction.x, -direction.z))


func _aim_camera_at(target: Vector2) -> void:
	var to := Vector3(target.x, 0.0, target.y) - _player.global_position
	to.y = 0.0
	_aim_camera_along(to)


## Keeps the whole party topped up during a fight this probe is driving.
##
## First draft only healed the ACTIVE creature at hp_fraction < 0.5, which the
## checkpoint fight (`stronghold_checkpoint`, an OFFICER's three-creature
## team) broke: a single hit took the active creature from full health to
## fainted in one blow, past the 50% threshold this check only sampled
## BETWEEN attacks, and `combat_manager`'s `exited` signal confirmed the
## result -- 2/3 of the opponent's team fell, then outcome='lost'. Pressing
## `party_cycle` to bring in a fresh member was tried next and produced a
## worse, stranger symptom (two party members reporting a corrupted max_hp of
## 2 afterward) that this probe does not have a root cause for and is not
## going to guess at live in someone else's combat/party code. Healing every
## member directly every tick sidesteps both: nobody is ever actually in
## danger of fainting, so there is nothing for a cycle-then-KO edge case to
## exploit, and it costs nothing this isolated run cares about (the party
## arrives at S09 already assumed fully prepared).
func _protect_active_creature() -> void:
	var party: RefCounted = _game.get("party")
	for c: RefCounted in party.call("members"):
		if bool(c.get("fainted")) or float(c.get("hp")) < float(c.get("max_hp")):
			c.hp = c.max_hp
			c.fainted = false


## Fights whatever `_manager.enemy_body()` names, wild or trainer, to the end
## of the encounter -- the same aim/quick/charged loop `_fight_trainer` drives
## against a named trainer's own team, generalised so a wild encounter that
## interrupts a walk (see `_walk_to`) gets resolved for real instead of
## silently freezing locomotion for the rest of the frame budget.
func _fight_current_opponent(max_frames: int = 3000) -> void:
	print("    a wild encounter interrupted the walk; fighting it out")
	var frames := 0
	while bool(_manager.call("is_fighting")) and frames < max_frames:
		frames += 1
		await _protect_active_creature()
		var opponent: Node3D = _manager.call("enemy_body") as Node3D
		var ally: Node3D = _director.call("ally_body") as Node3D
		if opponent == null or ally == null:
			await physics_frame
			continue
		var toward := opponent.global_position - ally.global_position
		toward.y = 0.0
		_aim_camera_along(toward)
		if toward.length() > 2.0:
			Input.action_press("move_forward")
			await physics_frame
			Input.action_release("move_forward")
		elif bool(_manager.call("charged_ready")):
			await _press_in_combat("combat_charged")
		elif bool(_manager.call("quick_ready")):
			await _press_in_combat("combat_quick")
		else:
			await physics_frame
	for i in 30:
		await physics_frame
	print("    wild encounter resolved after %d frames (still fighting=%s)" % [
		frames, str(_manager.call("is_fighting"))])


## Walks toward `target` (world x,z) by aiming the camera and holding the real
## `move_forward` action -- the same input channel `_fight_the_whole_team`
## already drives combat movement through -- rather than overriding velocity
## and calling `move_and_slide()` directly. A first draft of this drove the
## player's velocity by hand with `set_physics_process(false)`, which does not
## stop the engine calling `player_controller.gd`'s own `_physics_process` on
## the frame that flag takes effect, and the two writers fighting over
## `velocity` produced a "platform-velocity inheritance" spike
## (`_clamp_runaway_velocity`'s own documented failure mode) that clamped every
## frame without ever making net progress -- 900 frames spent standing still.
## Re-aims every frame so a collision deflection does not compound, and breaks
## out as soon as the player is within `arrive` metres rather than spending
## the whole budget. Returns whether the player arrived.
func _walk_to(target: Vector2, max_frames: int, arrive: float = 3.5) -> bool:
	var arrived := false
	var start := Vector2(_player.global_position.x, _player.global_position.z)
	var last_progress_check := start
	var stuck_frames := 0
	var sidestep_left := 0
	var sidestep_sign := 1.0
	for i in max_frames:
		# Band 5's own wild roster includes aggressive species (galecrest);
		# two of its clusters sit right across this leg's route near (0,7280)
		# and (-25,7255). An aggressive wild auto-engaging mid-walk is real
		# Prompt-66 evidence ("stronger believable wild presence"), not a
		# probe bug -- but holding `move_forward` through it does nothing,
		# because `encounter_director.gd` ties `set_locomotion_enabled(false)`
		# to combat being active. Fight it out for real, then resume.
		if bool(_manager.call("is_fighting")):
			await _fight_current_opponent()
			last_progress_check = Vector2(_player.global_position.x, _player.global_position.z)
			stuck_frames = 0
		var here := Vector2(_player.global_position.x, _player.global_position.z)
		if here.distance_to(target) <= arrive:
			arrived = true
			break
		var flat := Vector3(target.x - here.x, 0.0, target.y - here.y).normalized()
		# Open-meadow scatter (a rock, a tree) can stand directly on the
		# straight-line bearing to a waypoint, and holding `move_forward` into
		# it makes no more progress than a locked gate would. Not
		# pathfinding -- a real player just steps around it -- so a stretch
		# with near-zero net displacement tries a lateral offset for a bit
		# before returning to a direct bearing.
		if i % 60 == 0 and i > 0:
			var moved_recently := last_progress_check.distance_to(here)
			if moved_recently < 1.0:
				stuck_frames += 1
			else:
				stuck_frames = 0
			last_progress_check = here
			if stuck_frames >= 2 and sidestep_left <= 0:
				sidestep_left = 90
				sidestep_sign = -sidestep_sign
				stuck_frames = 0
		if sidestep_left > 0:
			var side := Vector3(-flat.z, 0.0, flat.x) * sidestep_sign
			flat = (flat + side).normalized()
			sidestep_left -= 1
		_aim_camera_along(flat)
		Input.action_press("move_forward")
		await physics_frame
	Input.action_release("move_forward")
	var moved := start.distance_to(Vector2(_player.global_position.x, _player.global_position.z))
	if not arrived and moved < 1.0:
		var owner := INPUT_OWNER.current(self)
		print("    DEBUG stalled walk toward (%.1f,%.1f): moved %.2fm, panel_open=%s owner=%s locomotion=%s pos=%s" % [
			target.x, target.y, moved, str(_panel.call("is_open")),
			str(owner.name) if owner != null else "<none>", str(_player.call("locomotion_enabled")),
			str(_player.global_position)])
	return arrived


## Walks a chain of waypoints in order (a hand-routed path rather than a
## straight line to the final target) -- necessary here because
## `sigil_gate_gorge_west/east` plus their `_wing` extensions (GATE-D5
## REQUEST 2 / OW6A) seal nearly the whole band 4/5 boundary at a z that
## varies with x; the only crossing is the ~10m causeway at the gate itself.
## A straight line from the gate to `stronghold_outer_watch` (260m away, on
## the low-z/village side) crosses that sealed band at x~36-48, nowhere near
## the gate's own x~57-70 gap, and would wall the player off exactly the way
## a locked gate is supposed to. Each leg still stops early on arrival; a leg
## that cannot reach its waypoint is recorded and the chain moves on from
## wherever the player actually ended up, the same "record what happened"
## posture the rest of this drive takes.
func _walk_via(points: Array, frames_per_leg: int, arrive: float = 3.5) -> bool:
	var all_arrived := true
	for point: Vector2 in points:
		var ok := await _walk_to(point, frames_per_leg, arrive)
		var here := Vector2(_player.global_position.x, _player.global_position.z)
		if not ok:
			all_arrived = false
			_note("waypoint (%.1f, %.1f) not reached; stopped %.1fm short at (%.1f, %.1f)" % [
				point.x, point.y, here.distance_to(point), here.x, here.y])
	return all_arrived


func _press(action: String) -> void:
	Input.action_press(action)
	await physics_frame
	await physics_frame
	Input.action_release(action)
	await physics_frame


## Same as `_press`, but re-heals the whole party after every physics frame
## rather than once per loop pass. `_protect_active_creature()` alone still
## lost the checkpoint fight once with the heal already raised to 0.9: an
## attack can land and resolve inside the multi-frame hold of an ordinary
## `_press()` call (four frames with no heal in between), which is exactly
## the kind of single-hit-past-the-check gap that cost the earlier attempts.
func _press_in_combat(action: String) -> void:
	Input.action_press(action)
	await physics_frame
	await _protect_active_creature()
	await physics_frame
	Input.action_release(action)
	await physics_frame
	await _protect_active_creature()
