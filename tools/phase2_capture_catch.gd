extends SceneTree

## OF1's blind-judge frames: the whole catch sequence, both outcomes.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##       --script tools/capture_catch_sequence.gd
##
## NOT --headless: that swaps in a no-op renderer and the run silently hangs
## (survey_combat.sh's own header). Same honest limits as every combat capture:
## software rendering, so composition/colour/readability are trustworthy and
## lighting quality is not.
##
## survey_combat.gd stops at "08-orb-in-flight" — it has never photographed the
## resolution, which is exactly the half of catching OF1 exists to redo. This
## walks: aim -> flight -> strike/absorb -> the orb at rest under the resolve
## camera -> a shake mid-rock -> the verdict, and it does it twice, because the
## feel of failure matters as much as success:
##   sequence A, full-health target  -> expect a breakout
##   sequence B, target at a sliver  -> expect a catch
## Each sequence retries until the dice actually produce its outcome, since a
## frame named "breakout" showing a seal would make the whole critique a lie.
##
## Beat frames use the pause-after-the-effect-draws trick from
## survey_combat._capture_the_impact: a node added mid-frame has drawn nothing
## until its next physics tick, and without pausing, physics outruns the
## software renderer and the moment is gone before the shutter opens.

const MEADOWS_SCENE := "res://scenes/world/meadows_playground.tscn"
const TIDEWAKE_SCENE := "res://scenes/world/water_archipelago.tscn"
const STORMWOOD_SCENE := "res://scenes/world/stormwood.tscn"
const CLOUDREACH_SCENE := "res://scenes/world/cloudreach_cliffs.tscn"
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const MATH := preload("res://scripts/combat/combat_math.gd")
const CATCH := preload("res://scripts/combat/catch_math.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
var _out_dir := "res://ralph/reports/VISUAL/phase2/meadows/catch_raw_main"
var _seed := 2042
var _biome := "meadows"
var _scene := MEADOWS_SCENE

const SETTLE_FRAMES := 240
const POSE_FRAMES := 2
## Physics frames between a beat's signal and its shutter, so the effect it
## names has actually drawn something.
const BEAT_FRAMES := 5
## Attempts allowed per sequence before giving up on the dice.
const MAX_ATTEMPTS := 6

var _world: Node = null
var _player: CharacterBody3D = null
var _rig: Node3D = null
var _manager: Node = null
var _director: Node = null
var _wild: Node3D = null
var _ally: Node3D = null

var _written: Array[String] = []
var _failures: Array[String] = []
var _start_ms: int = 0
var _graphics_capture: Dictionary = {}
var _breakout_handback_only := false
var _handback_observations: Array[Dictionary] = []

## F40#18 (VIS-CLOUDREACH, 4 Nov 2026; coordinator-directed reproduced
## blocker): Cloudreach A/B rounds paired different wild species at different
## spots and different catch outcomes for the same --seed, because the capture
## took whichever streamed wild stood nearest. In Cloudreach the seed now picks
## the species from this list and the capture places that one wild at a fixed
## arrival-terrace spot (EncounterDirector.spawn_wild, fixed level, no wander),
## and every throw's catch roll is re-seeded from (seed, throw index).
const PINNED_WILD_SPECIES := ["skyrill", "galecrest", "pebbik"]
const PINNED_WILD_XZ := Vector2(-4.0, -254.0)
const PINNED_WILD_LEVEL := 30
const CAPTURE_ARBITRATION_WINDOW_MS := 600000
const PINNED_BANNER_YAW_DEG := 0.0
var _pinned_wild := false
var _throw_index := 0


static func pinned_wild(seed_value: int) -> Dictionary:
	return {"species": PINNED_WILD_SPECIES[posmod(seed_value, PINNED_WILD_SPECIES.size())],
		"xz": PINNED_WILD_XZ, "level": PINNED_WILD_LEVEL}


var _struck_flag := [false]
var _shook_flag := [false]
var _resolved := []  # appended [success] per resolution
## F38#33 capture fix (7 Nov, VIS-MEADOWS decision 3): the HUD whose broke-free
## card a verdict frame photographs, held still from the resolve to the shot.
var _verdict_hud: Node = null
var _hold_verdict_card := false
var _held_outcome_left := 0.0


func _init() -> void:
	process_frame.connect(_top_up_verdict_card)
	_run.call_deferred()


func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--preset="):
			_graphics_capture = preload("res://tools/lookdev_capture_bootstrap.gd").prepare(self)
			if _graphics_capture.is_empty():
				quit(1)
				return
			break
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):
			_out_dir = arg.trim_prefix("--output=")
		elif arg.begins_with("--seed="):
			_seed = int(arg.trim_prefix("--seed="))
		elif arg.begins_with("--biome="):
			_biome = arg.trim_prefix("--biome=")
		elif arg == "--breakout-handback-only":
			_breakout_handback_only = true
		elif arg.begins_with("--framed="):
			# P2-113 before/after: the same seed with catching.json's
			# framed_camera flag forced off or on in this process only.
			var framed: Dictionary = CATCH.config().get("framed_camera", {})
			framed["enabled"] = arg.trim_prefix("--framed=") == "on"
			CATCH.config()["framed_camera"] = framed
			print("[catch] framed_camera.enabled=%s" % str(framed["enabled"]))
	if _biome == "tidewake":
		_scene = TIDEWAKE_SCENE
	elif _biome == "stormwood":
		_scene = STORMWOOD_SCENE
	elif _biome == "cloudreach":
		_scene = CLOUDREACH_SCENE
	if _biome not in ["meadows", "tidewake", "stormwood", "cloudreach"] or not _out_dir.begins_with("res://ralph/reports/VISUAL/phase2/%s/" % _biome):
		push_error("Catch capture output must stay in Meadows Phase 2 evidence")
		quit(1)
		return
	seed(_seed)
	_start_ms = Time.get_ticks_msec()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out_dir))
	if _biome in ["tidewake", "stormwood", "cloudreach"]:
		var game := root.get_node(^"Game")
		game.call("reset_for_new_game")
		game.set("current_realm", "water" if _biome == "tidewake" else _biome)
		if _biome == "cloudreach":
			game.progression.set_flag("realm_key_cloudreach")
			for species: String in ["sparkit", "mudsnout", "bramblebun", "terrapup", "brooktail"]:
				var member: RefCounted = SPECIES.spawn(species)
				member.set_level(25, PROGRESSION.config())
				game.party.add(member)

	var packed: PackedScene = load(_scene)
	if packed == null:
		push_error("could not load %s" % _scene)
		quit(1)
		return
	_world = packed.instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame
	if _world.has_method("shell_build_complete"):
		# Wait on the world's own ready flag with a time cap, not a frame
		# count: GPU shells take minutes (Meadows ~140 s at High), far past
		# any fixed frame budget (capture-speed lane, 1 Nov 2026). Every
		# biome waits: Forward+ cheap build frames skip the 3D pass until
		# the build completes, so an early Meadows catch shot was HUD only.
		var shell_deadline_ms := Time.get_ticks_msec() + 900000
		while not bool(_world.call("shell_build_complete")) and Time.get_ticks_msec() < shell_deadline_ms:
			await physics_frame
		if not bool(_world.call("shell_build_complete")):
			_failures.append("%s shell did not build" % _biome)
			_finish()
			return
	_log("settled")

	await _ensure_ally()
	_leave_the_farmhouse()
	if _biome == "tidewake":
		# Water streams ordinary wilds around the player. This dry First Shore
		# site is outside the default spawn neighborhood.
		for i in 300:
			await physics_frame
		_stand_beside_streamed_tidewake_wild()
		for i in 30:
			await physics_frame
	_seed_orbs()
	if not _collect_nodes():
		_finish()
		return

	await _walk_to_the_wild_creature()
	await _engage()
	if not bool(_manager.call("is_fighting")):
		_failures.append("could not enter combat; nothing captured")
		_finish()
		return
	# P2-113: hidden before the Engage press, the HUD swallowed it (the world
	# interact routes through it); hide it only once the fight is live.
	var debug_hud: CanvasLayer = _world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	if debug_hud != null:
		debug_hud.visible = false
	_ally = _director.call("ally_body") as Node3D
	_log("fighting")

	# The capture-reticle pass (spec §10.2, D31): two aim-state stills at a
	# low and a high chance, taken BEFORE sequence A below starts stacking
	# `chance.min`/`chance.max` for the dice — these two only need real,
	# unclamped odds on screen, and by the far end of sequence B the fight
	# has usually already resolved and ended.
	if not _breakout_handback_only:
		await _capture_chance_frames()

	# The dice are stacked per sequence THROUGH THE CLAMPS the formula already
	# has (`chance.min`/`chance.max`), because a frame named "breakout" showing
	# a seal would make the whole critique a lie: a full-health throw can still
	# roll its ~5-10%, and a catch in sequence A ends the fight the entire run
	# depends on. The resolution path being photographed is untouched — only
	# the roll's odds are pinned, and only inside this process.
	var chance_cfg: Dictionary = CATCH.config().get("chance", {})
	var real_min: float = float(chance_cfg.get("min", 0.02))
	var real_max: float = float(chance_cfg.get("max", 0.95))

	# --- sequence A: full health, expect a breakout -------------------------
	chance_cfg["max"] = 0.001
	chance_cfg["min"] = 0.0
	var got_failure := false
	for attempt in MAX_ATTEMPTS:
		if not bool(_manager.call("is_fighting")):
			break
		_top_up()
		var foe: RefCounted = _manager.call("enemy")
		foe.hp = foe.max_hp
		var first := attempt == 0 and not _breakout_handback_only
		var outcome := await _one_throw("01-aiming-full-health" if first else "",
			"02-orb-in-flight" if first else "", "03-strike" if first else "",
			"04-orb-resting" if first else "", "05-orb-shakes" if first else "",
			"06-breakout")
		if outcome == "failure":
			got_failure = true
			break
	if not got_failure:
		_failures.append("sequence A never produced a breakout to photograph")
	if _breakout_handback_only:
		chance_cfg["min"] = real_min
		chance_cfg["max"] = real_max
		_finish()
		return

	# --- sequence B: a sliver of health, expect a catch ---------------------
	chance_cfg["max"] = real_max
	chance_cfg["min"] = 0.999
	if bool(_manager.call("is_fighting")):
		var got_catch := false
		for attempt in MAX_ATTEMPTS:
			if not bool(_manager.call("is_fighting")):
				break
			_top_up()
			var foe: RefCounted = _manager.call("enemy")
			foe.hp = foe.max_hp * 0.06
			var outcome := await _one_throw("07-aiming-weakened" if attempt == 0 else "",
				"", "", "", "", "08-caught-verdict")
			if outcome == "success":
				got_catch = true
				# F40#18 (VIS-CLOUDREACH, 5 Nov 2026): the resolve shot inherits the
				# rig yaw of the live fight, so the same pinned catch framed the road
				# on one run and the creature and cliffs on the next. In the pinned
				# capture the banner frame is taken from one fixed yaw, the same for
				# every tree, so A/B rounds judge the card over the same scene.
				if _pinned_wild and _rig != null:
					_rig.set("yaw", deg_to_rad(PINNED_BANNER_YAW_DEG))
					_rig.set("rotation", Vector3(float(_rig.get("pitch")), deg_to_rad(PINNED_BANNER_YAW_DEG), 0.0))
				for i in 30:
					await physics_frame
				await _capture("09-caught-banner")
				break
		if not got_catch:
			_failures.append("sequence B never produced a catch to photograph")
	else:
		_failures.append("the fight ended before sequence B could run")
	chance_cfg["min"] = real_min

	_finish()


## One aimed throw, capturing whichever beat frames were asked for ("" skips).
## Returns "success", "failure", or "" when the throw never resolved.
func _one_throw(aim_frame: String, flight_frame: String,
		strike_frame: String, rest_frame: String, shake_frame: String,
		verdict_frame: String) -> String:
	if not await _open_aim():
		return ""
	# Let the aim camera glide in before reading its eye or its frame.
	for i in 15:
		await physics_frame
	_aim_at_the_target()
	for i in 4:
		await physics_frame
	if aim_frame != "":
		await _capture(aim_frame)
		_aim_at_the_target()
		for i in 4:
			await physics_frame

	if _pinned_wild and _manager != null:
		var roll_rng: Variant = _manager.get("_rng")
		if roll_rng is RandomNumberGenerator:
			(roll_rng as RandomNumberGenerator).seed = hash("%d_%d" % [_seed, _throw_index])
	_throw_index += 1
	_struck_flag[0] = false
	_shook_flag[0] = false
	var resolutions_before := _resolved.size()
	# On CPU the orb can resolve before the shake still is taken, so the hold
	# is armed from the throw, not from the verdict wait.
	_hold_verdict_card = verdict_frame != "" and not _breakout_handback_only
	await _press("combat_orb_release")

	if flight_frame != "":
		# Past the release windup (0.18s ~ 11 ticks) with the trail drawn.
		for i in 16:
			await physics_frame
		await _capture(flight_frame)

	# The strike: flash + the creature shrinking toward the hanging orb.
	var waited := 0
	while not _struck_flag[0] and waited < 300 and bool(_manager.call("is_fighting")):
		await physics_frame
		waited += 1
	if not _struck_flag[0]:
		# The orb went wide; no resolution follows.
		for i in 60:
			await physics_frame
		return ""
	# Two beats, photographed separately, because they cannot share a still:
	# the flash peaks in the first tenth of a second and the shrink only READS
	# once the creature is well under size — round 2 captured "strike-absorb"
	# at 0.18s and showed a full-size creature next to a spent flash.
	if strike_frame != "":
		for i in BEAT_FRAMES:
			await physics_frame
		await _capture_paused(strike_frame)
		for i in 14:
			await physics_frame
		await _capture_paused(strike_frame.replace("-strike", "-absorbing"))

	# The orb at rest under the resolve camera, before the first shake.
	if rest_frame != "":
		var orb := _resting_orb()
		waited = 0
		while waited < 300:
			orb = _resting_orb()
			if orb != null and bool(orb.call("is_resting")):
				break
			await physics_frame
			waited += 1
		for i in 6:
			await physics_frame
		await _capture(rest_frame)

	# A shake, mid-rock. The rock is ~0.45s; shoot a third of the way in.
	if shake_frame != "":
		waited = 0
		while not _shook_flag[0] and waited < 300:
			await physics_frame
			waited += 1
		if _shook_flag[0]:
			for i in 8:
				await physics_frame
			await _capture_paused(shake_frame)
		else:
			_failures.append("%s: the orb never shook" % shake_frame)

	# The verdict.
	waited = 0
	while _resolved.size() == resolutions_before and waited < 900:
		await physics_frame
		waited += 1
	if _resolved.size() == resolutions_before:
		_release_verdict_hud()
		_failures.append("a struck orb never resolved")
		return ""
	if verdict_frame != "":
		for i in BEAT_FRAMES:
			_top_up_verdict_card()
			await physics_frame
		_top_up_verdict_card()
		if _breakout_handback_only:
			# Observe the existing handback with physics and the camera compositor
			# live. This diagnoses the paused beat; it never writes camera/body pose.
			if not bool(_resolved[-1]):
				await _capture("breakout-handback-live")
				for i in 35:
					await physics_frame
				await _capture("breakout-handback-settled")
		else:
			await _capture_paused(verdict_frame)
	_release_verdict_hud()
	# Let the aftermath (breakout pop, camera handback, cooldown) play out.
	for i in 70:
		await physics_frame
	return "success" if bool(_resolved[-1]) else "failure"


## Two aim-state stills (spec §10.2, D31): the capture reticle's ring +
## explicit percentage at a low chance (full-health target) and a high one
## (a sliver of health), so the reticle work has real numbers on real frames
## rather than a theoretical curve. Neither throw is ever released — both
## stills only need the AIM state, and releasing one would spend an orb and
## drag the fight into a resolution neither still is named for.
func _capture_chance_frames() -> void:
	await _capture_chance_frame(1.0, "catch_low")
	await _capture_chance_frame(0.05, "catch_high")


func _capture_chance_frame(hp_fraction: float, frame_name: String) -> void:
	if not bool(_manager.call("is_fighting")):
		_failures.append("%s: fight already over" % frame_name)
		return
	_top_up()
	var foe: RefCounted = _manager.call("enemy")
	foe.hp = clampf(foe.max_hp * hp_fraction, 1.0, foe.max_hp)
	if not await _open_aim():
		_failures.append("%s: could not open aim" % frame_name)
		return
	# Let the aim camera glide in and the reticle catch up before shooting.
	for i in 15:
		await physics_frame
	_aim_at_the_target()
	for i in 6:
		await physics_frame
	await _capture(frame_name)
	# Cancel rather than release: this throw was never meant to fly.
	await _press("menu_cancel")
	for i in 20:
		await physics_frame


## --- plumbing, same shapes as capture_combat_actions.gd ---------------------

func _ensure_ally() -> void:
	var director := _world.get_node_or_null(^"EncounterDirector")
	if director == null and _biome == "cloudreach":
		director = _world.get_node(^"CloudreachRuntime").get("director")
	if director == null or director.call("ally_instance") != null:
		return
	if _biome == "cloudreach":
		await director.call("summon_active_creature")
		return
	await director.call("adopt_starter", "terrapup")
	# Same ownership step as tests/smoke_controller_catching.gd: with
	# combat.json actor_vitals on, a wild fight refuses an unowned fighter.
	var owned_party: RefCounted = root.get_node(^"Game").get("party")
	if owned_party != null and int(owned_party.call("size")) == 0 and director.call("ally_instance") != null:
		owned_party.call("add", director.call("ally_instance"))


func _leave_the_farmhouse() -> void:
	var player := _world.get_node_or_null(^"Player") as CharacterBody3D
	if player == null:
		return
	var start := Vector3(48.0, 0.0, -58.0)
	if _biome == "tidewake":
		start = Vector3(-90.024, 0.0, 147.573)
	elif _biome == "stormwood":
		var director := _world.get_node_or_null(^"EncounterDirector")
		if director != null:
			var nearest := INF
			for candidate: Node3D in (director.call("wild_creatures") as Array[Node3D]):
				if candidate.has_meta("stormwood_named_encounter"):
					continue
				var distance := candidate.global_position.distance_to(player.global_position)
				if distance < nearest:
					nearest = distance
					_wild = candidate
			if _wild != null:
				start = _wild.global_position + Vector3(0.0, 0.0, 5.0)
	elif _biome == "cloudreach":
		var director: Node = _world.get_node(^"CloudreachRuntime").get("director")
		var pin := pinned_wild(_seed)
		var xz: Vector2 = pin["xz"]
		var spot := Vector3(xz.x, float(_world.call("ground_height_at", xz.x, xz.y)), xz.y)
		seed(_seed)
		var placed: Node3D = director.call("spawn_wild", str(pin["species"]), spot,
			{"name": "CapturePinnedWild", "level": int(pin["level"]), "wander_radius": 0.0, "aggressive": false}) as Node3D
		if placed != null:
			_wild = placed
			_pinned_wild = true
			print("cloudreach catch: pinned %s at %s (seed %d)" % [pin["species"], placed.global_position, _seed])
		var nearest := INF if _wild == null else -1.0
		for candidate: Node3D in (director.call("wild_creatures") as Array[Node3D]):
			var ground := float(_world.call("ground_height_at", candidate.global_position.x, candidate.global_position.z))
			if not is_finite(ground) or absf(ground - candidate.global_position.y) > 4.0:
				continue
			var distance := candidate.global_position.distance_to(player.global_position)
			if not _pinned_wild and distance < nearest:
				nearest = distance
				_wild = candidate
		if _wild != null:
			start = _wild.global_position + Vector3(0.0, 0.0, 5.0)
	start.y = float(_world.call("ground_height_at", start.x, start.z)) + 1.0
	player.global_position = start
	player.velocity = Vector3.ZERO


## F39#9 (VIS-TIDEWAKE, 4 Nov 2026): the Tidewake counterpart of pinned_wild.
const PINNED_TIDEWAKE_SPECIES := ["cannonback", "torrentoad", "mangrove_monitor"]
const PINNED_TIDEWAKE_XZ := Vector2(-90.024, 142.573)
const PINNED_TIDEWAKE_LEVEL := 8


static func pinned_tidewake_wild(seed_value: int) -> Dictionary:
	return {"species": PINNED_TIDEWAKE_SPECIES[posmod(seed_value, PINNED_TIDEWAKE_SPECIES.size())],
		"xz": PINNED_TIDEWAKE_XZ, "level": PINNED_TIDEWAKE_LEVEL}


## Tidewake wilds only exist once the director streams the neighborhood around
## the player, so pick one after that wait: the nearest active, grounded,
## unengaged wild (as the Cloudreach branch does), and stand 5 m from it. The
## Meadows "practice" species lookup can name a far or absent body here.
func _stand_beside_streamed_tidewake_wild() -> void:
	var player := _world.get_node_or_null(^"Player") as CharacterBody3D
	var director := _world.get_node_or_null(^"EncounterDirector")
	if player == null or director == null:
		return
	# F39#9 (VIS-TIDEWAKE, 4 Nov 2026): the same reproduced A/B blocker as the
	# Cloudreach pin above. The seed picks a First Shore species and the capture
	# places that one wild 5 m ahead of the fixed First Shore start.
	var pin := pinned_tidewake_wild(_seed)
	var xz: Vector2 = pin["xz"]
	seed(_seed)
	var placed: Node3D = director.call("spawn_wild", str(pin["species"]),
		Vector3(xz.x, float(_world.call("ground_height_at", xz.x, xz.y)), xz.y),
		{"name": "CapturePinnedWild", "level": int(pin["level"]), "wander_radius": 0.0, "aggressive": false}) as Node3D
	if placed != null:
		_wild = placed
		_pinned_wild = true
		print("tidewake catch: pinned %s at %s (seed %d)" % [pin["species"], placed.global_position, _seed])
	var nearest := INF if _wild == null else -1.0
	for candidate: Node3D in (director.call("wild_creatures") as Array[Node3D]):
		if _pinned_wild:
			break
		if not is_instance_valid(candidate) or not candidate.visible \
				or not candidate.is_physics_processing() or bool(candidate.get("engaged")):
			continue
		var ground := float(_world.call("ground_height_at", candidate.global_position.x, candidate.global_position.z))
		if not is_finite(ground) or absf(ground - candidate.global_position.y) > 2.0:
			continue
		var distance := candidate.global_position.distance_to(player.global_position)
		if distance < nearest:
			nearest = distance
			_wild = candidate
	if _wild == null:
		print("tidewake catch: no active grounded wild streamed near the player")
		return
	print("tidewake catch: %s at %.1f m" % [_wild.name, nearest])
	var at := _wild.global_position + Vector3(0.0, 0.0, 5.0)
	at.y = float(_world.call("ground_height_at", at.x, at.z)) + 1.0
	player.global_position = at
	player.velocity = Vector3.ZERO


func _seed_orbs(count: int = 20) -> void:
	var game := root.get_node_or_null(^"/root/Game")
	if game == null:
		return
	var inventory: RefCounted = game.get("inventory")
	var short: int = count - int(inventory.call("count", "orb_basic"))
	if short > 0:
		inventory.call("add", "orb_basic", short)


## Keep the ally standing and the satchel stocked between attempts, the same
## reasoning smoke_catching.gd already carries: aiming genuinely abandons the
## creature, and a capture run that throws repeatedly would otherwise end "lost".
func _top_up() -> void:
	_seed_orbs()
	var creature: RefCounted = _manager.call("active_creature")
	if creature != null:
		creature.hp = creature.max_hp


func _collect_nodes() -> bool:
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	_manager = _world.get_node_or_null(^"CombatManager")
	_director = _world.get_node_or_null(^"EncounterDirector")
	if _biome == "cloudreach":
		var runtime := _world.get_node_or_null(^"CloudreachRuntime")
		if runtime != null:
			_manager = runtime.get("manager")
			_director = runtime.get("director")
	if _player == null or _manager == null or _director == null or _rig == null:
		_failures.append("scene is missing the player, camera rig, combat manager or director")
		return false
	# F40#18 (VIS-CLOUDREACH, 4 Nov 2026): the catch arbiter's lease is wall-clock
	# milliseconds (multiplayer.json catch_arbitration_window_ms, 6 s). On CPU
	# llvmpipe at 1080p the throw-and-wobble outlives it, the claim lapses and
	# every finish is refused `not_claimant` (seen in qj_portrait2/2b). This
	# capture process alone widens the arbiter's test-overridable window.
	if _pinned_wild:
		# The director builds its arbiter lazily on the first engagement; build
		# it now (its own idempotent helper) so the widened window is the one
		# the fight uses.
		if _director.has_method("_ensure_encounter_arbiters"):
			_director.call("_ensure_encounter_arbiters")
		var arbiter: Variant = _director.get("_catch_arbiter")
		if arbiter is Object and "window_ms" in (arbiter as Object):
			(arbiter as Object).set("window_ms", CAPTURE_ARBITRATION_WINDOW_MS)
			print("cloudreach catch: arbiter window %d ms" % int((arbiter as Object).get("window_ms")))
	if _wild == null:
		_wild = _director.call("wild_creature") as Node3D
	if _wild == null and _biome == "tidewake":
		var nearest := INF
		for candidate: Node3D in (_director.call("wild_creatures") as Array[Node3D]):
			var distance := candidate.global_position.distance_to(_player.global_position)
			if distance < nearest:
				nearest = distance
				_wild = candidate
	if _wild == null:
		_failures.append("the encounter director never spawned a wild creature")
		return false

	var throw: Node = _manager.call("throw_aim")
	throw.connect("orb_struck", func(_t: Node3D, _o: float) -> void: _struck_flag[0] = true)
	_manager.connect("orb_shook", func(_i: int) -> void: _shook_flag[0] = true)
	_manager.connect("catch_resolved", _on_capture_resolved)
	return true


## The HUD's own handler (connected at game setup, so it runs first) has
## already raised the broke-free card. At 60 fps the verdict beat (BEAT_FRAMES
## plus POSE_FRAMES) is about 0.12 s of the card's 1.8 s hold; on CPU each of
## those frames feeds its wall time (often over 0.3 s) into the HUD's _process,
## so the card expired before the shot (`_outcome_left` -0.08 s at
## 06-breakout). Hold the card's own timer at its raised value through the
## beat (the HUD keeps processing and drawing normally); a frozen HUD
## (set_process false) left the card undrawn on CPU.
func _on_capture_resolved(success: bool, _shakes: int) -> void:
	_resolved.append(success)
	if success or not _hold_verdict_card:
		return
	_verdict_hud = _world.get_node_or_null(^"CombatHUD")
	if _verdict_hud == null:
		var found := _world.find_children("CombatHUD", "", true, false)
		_verdict_hud = found[0] if not found.is_empty() else null
	if _verdict_hud != null:
		_held_outcome_left = float(_verdict_hud.get("_outcome_left"))
	else:
		_hold_verdict_card = false


## Called on every process frame (SceneTree.process_frame, before the HUD's
## _process) and on every beat frame, from the resolve to the verdict shot.
func _top_up_verdict_card() -> void:
	if _hold_verdict_card and is_instance_valid(_verdict_hud):
		if float(_verdict_hud.get("_outcome_left")) < _held_outcome_left:
			_verdict_hud.set("_outcome_left", _held_outcome_left)


func _release_verdict_hud() -> void:
	_hold_verdict_card = false
	_verdict_hud = null


func _resting_orb() -> Node3D:
	var throw: Node = _manager.call("throw_aim")
	return throw.call("resting_orb") as Node3D


## P2-113: the walk-up and single interact tap never admitted a fight in
## Meadows or Stormwood ("could not enter combat"). This is
## capture_named_fights_f10_6.gd's proven path instead: stand 4.5 m from the
## wild (debug placement, disclosed), hide other wilds within 25 m so the
## Engage offer's nearest-body rule names this one (disclosed), call the ally
## out, and press interact only when the director's Engage offer is the
## arbiter's actionable winner.
var _hidden_wilds: Array[Node3D] = []

func _walk_to_the_wild_creature() -> void:
	var at := _wild.global_position
	for body: Node3D in (_director.call("wild_creatures") as Array):
		if is_instance_valid(body) and body != _wild and body.global_position.distance_to(at) < 25.0:
			body.visible = false
			body.process_mode = Node.PROCESS_MODE_DISABLED
			_hidden_wilds.append(body)
	await _stand_beside_wild(4.5)
	if _director.call("ally_body") == null:
		await _tap(&"creature_recall")
		for i in 90:
			if _director.call("ally_body") != null:
				break
			await physics_frame
	_log("stood beside the wild; hid %d neighbours" % _hidden_wilds.size())


func _stand_beside_wild(distance: float) -> void:
	var at := _wild.global_position
	var away := _player.global_position - at
	away.y = 0.0
	away = away.normalized() if away.length() > 0.1 else Vector3(0, 0, 1)
	var xz := Vector2(at.x + away.x * distance, at.z + away.z * distance)
	var space := _player.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(Vector3(xz.x, at.y + 60.0, xz.y), Vector3(xz.x, at.y - 60.0, xz.y))
	query.exclude = [_player.get_rid()]
	var hit := space.intersect_ray(query)
	var ground: Vector3 = hit.position if not hit.is_empty() else Vector3(xz.x, at.y, xz.y)
	_player.global_position = ground + Vector3.UP * 0.2
	_player.velocity = Vector3.ZERO
	var to := at - _player.global_position
	_rig.set("yaw", atan2(-to.x, -to.z))
	for i in 45:
		await physics_frame


func _engage() -> void:
	var arbiter := get_first_node_in_group(&"interaction_arbiter")
	for attempt in 900:
		if bool(_manager.call("is_fighting")):
			return
		var candidate := _director.call("_engageable") as Node3D
		var winner := arbiter.call("winning_provider") as Node if arbiter != null else null
		var offer: Dictionary = arbiter.call("winner") if arbiter != null else {}
		# The director names the nearest wild; follow it (the off run waited 40
		# min on a different Bramblebun than the one first picked).
		if candidate != null and candidate != _wild and winner == _director:
			_wild = candidate
		if candidate == _wild and winner == _director and bool(offer.get("actionable", false)) \
				and INPUT_OWNER.current(self) == null and not paused:
			_log("Engage offer '%s' -> pressing interact" % str(offer.get("label", "")))
			await _tap(&"interact")
			for i in 30:
				if bool(_manager.call("is_fighting")):
					return
				await physics_frame
		# Cloudreach arrival road (GPU item scores 31 Oct, P2-117/P2-118): a
		# 'Take Good Candy' pickup 1.12 m from the wild wins the interact
		# offer, so Engage never fires. Take the pickup first, as a player
		# would, then the wild's offer is the winner.
		elif winner != null and winner != _director and bool(offer.get("actionable", false)) \
				and str(offer.get("label", "")).begins_with("Take") \
				and INPUT_OWNER.current(self) == null and not paused and attempt % 30 == 0:
			_log("pickup '%s' holds the offer -> taking it first" % str(offer.get("label", "")))
			await _tap(&"interact")
		if attempt % 120 == 0:
			_log("engage waiting: candidate=%s winner=%s offer=%s" % [str(candidate), str(winner), str(offer)])
			if is_instance_valid(_wild) and _player.global_position.distance_to(_wild.global_position) > 5.5:
				await _stand_beside_wild(4.0)
		await physics_frame


func _tap(action: StringName) -> void:
	var binding: InputEvent = null
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventJoypadButton:
			binding = event
			break
	if binding == null:
		Input.action_press(action)
		for i in 3:
			await physics_frame
		Input.action_release(action)
		return
	var press := InputEventJoypadButton.new()
	press.button_index = (binding as InputEventJoypadButton).button_index
	press.pressed = true
	Input.parse_input_event(press)
	for i in 2:
		await physics_frame
		await process_frame
	var release := press.duplicate() as InputEventJoypadButton
	release.pressed = false
	Input.parse_input_event(release)
	for i in 2:
		await physics_frame


func _open_aim() -> bool:
	for i in 240:
		if not bool(_manager.call("is_fighting")):
			return false
		if not bool(_manager.call("player_is_committed")):
			break
		await physics_frame
	var cooldown := float(CATCH.config().get("throw", {}).get("cooldown", 0.9))
	var budget := int(ceil(cooldown * float(Engine.physics_ticks_per_second))) + 120
	while budget > 0:
		await _press("combat_throw")
		budget -= 4
		for i in 6:
			await physics_frame
			budget -= 1
		if bool(_manager.call("is_aiming")):
			return true
	return false


## smoke_catching.gd's proven aim: straight at the leaded centre from the
## camera's eye, letting `_aim_direction`'s snap window and ballistic solve do
## the rest.
func _aim_at_the_target() -> void:
	var camera := _rig.get_node_or_null(^"Camera3D") as Camera3D
	if camera == null:
		return
	var eye := camera.global_position
	var velocity := Vector3.ZERO
	if _wild is CharacterBody3D:
		velocity = (_wild as CharacterBody3D).velocity
	var release_windup := float(CATCH.config().get("throw", {}).get("release_windup", 0.18))
	var lead_time := 8.0 / float(Engine.physics_ticks_per_second) + release_windup
	var predicted: Vector3 = (_wild.call("centre") as Vector3) + velocity * lead_time
	var to := predicted - eye
	_rig.set("yaw", atan2(-to.x, -to.z))
	var flat := Vector2(to.x, to.z).length()
	_rig.set("pitch", atan2(to.y, maxf(flat, 0.01)))


func _press(action: String) -> void:
	Input.action_press(action)
	await physics_frame
	await physics_frame
	Input.action_release(action)
	await physics_frame


func _log(label: String) -> void:
	print("  [phase] %-28s +%.1fs" % [label, (Time.get_ticks_msec() - _start_ms) / 1000.0])


func _capture(name: String) -> void:
	for i in POSE_FRAMES:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null:
		_failures.append("%s: viewport returned no image" % name)
		return
	if not _graphics_capture.is_empty():
		var expected: Array = _graphics_capture.resolution
		if image.is_empty() or image.get_size() != Vector2i(int(expected[0]), int(expected[1])):
			_failures.append("%s: declared graphics raster mismatch" % name)
			return
	var path := "%s/%s.png" % [_out_dir, name]
	if image.save_png(path) != OK:
		_failures.append("%s: save_png failed" % name)
		return
	_written.append(path)
	if _breakout_handback_only:
		var camera := root.get_camera_3d()
		var model := _player.get_node_or_null(^"Model") as Node3D
		var ally_model := _ally.get_node_or_null(^"Model") as Node3D if is_instance_valid(_ally) else null
		var wild_model := _wild.get_node_or_null(^"Model") as Node3D if is_instance_valid(_wild) else null
		var camera_target := _rig.get("_target") as Node3D
		_handback_observations.append({"id": name, "paused": paused,
			"physics_frame": Engine.get_physics_frames(),
			"fighting": bool(_manager.call("is_fighting")),
			"resolved_success": bool(_resolved[-1]),
			"player_transform": str(_player.global_transform),
			"model_transform": str(model.global_transform) if model != null else "unavailable",
			"ally_transform": str(_ally.global_transform) if is_instance_valid(_ally) else "unavailable",
			"ally_model_transform": str(ally_model.global_transform) if ally_model != null else "unavailable",
			"ally_model_visible": ally_model.is_visible_in_tree() if ally_model != null else false,
			"ally_visible": _ally.is_visible_in_tree() if is_instance_valid(_ally) else false,
			"wild_transform": str(_wild.global_transform) if is_instance_valid(_wild) else "unavailable",
			"wild_model_transform": str(wild_model.global_transform) if wild_model != null else "unavailable",
			"wild_model_visible": wild_model.is_visible_in_tree() if wild_model != null else false,
			"wild_visible": _wild.is_visible_in_tree() if is_instance_valid(_wild) else false,
			"camera_path": str(camera.get_path()) if camera != null else "unavailable",
			"camera_transform": str(camera.global_transform) if camera != null else "unavailable",
			"camera_target_path": str(camera_target.get_path()) if is_instance_valid(camera_target) else "unavailable",
			"camera_target_transform": str(camera_target.global_transform) if is_instance_valid(camera_target) else "unavailable",
			"rig_transform": str(_rig.global_transform),
			"rig_has_current_camera": camera == _rig.get_node_or_null(^"Camera3D")})
	print("  %-26s -> %s  (+%.1fs)" % [name, path, (Time.get_ticks_msec() - _start_ms) / 1000.0])


## Freeze physics for the shutter so a sub-second beat is not gone before the
## software renderer produces a frame.
func _capture_paused(name: String) -> void:
	paused = true
	await _capture(name)
	paused = false


func _finish() -> void:
	print("")
	print("%d frames -> %s" % [_written.size(), _out_dir])
	print("Software rendering: composition, readability and colour only.")
	var records: Array[Dictionary] = []
	for path: String in _written:
		records.append({"id": path.get_file().get_basename(), "file": path})
	var manifest := {"biome": _biome, "category": "systems", "system": "catch",
		"seed": _seed, "scene": _scene, "display_server": DisplayServer.get_name(),
		"rendering_method": RenderingServer.get_current_rendering_method(),
		"adapter": RenderingServer.get_video_adapter_name(),
		"resolution": [root.size.x, root.size.y], "frames": records,
		"failures": _failures, "complete": _failures.is_empty()}
	if not _graphics_capture.is_empty():
		manifest["graphics_capture"] = _graphics_capture
	if _breakout_handback_only:
		manifest["subset"] = "breakout-handback-only"
		manifest["fixture"] = "Existing staged full-health target, in-memory failure odds and supplied orbs; same ordinary fight/aim/throw/resolve path. Two unpaused handback views only; no earned catch, continuous motion, success sequence or whole twelve-frame proof."
		manifest["handback_observations"] = _handback_observations
		if _written.size() != 2 or _handback_observations.size() != 2:
			_failures.append("breakout handback subset requires both unpaused views")
		manifest["complete"] = _failures.is_empty()
	var manifest_file := FileAccess.open("%s/manifest.json" % _out_dir, FileAccess.WRITE)
	manifest_file.store_string(JSON.stringify(manifest, "\t") + "\n")
	manifest_file.close()
	if not _failures.is_empty():
		for line in _failures:
			print("FAIL: %s" % line)
		quit(1)
		return
	quit(0)
