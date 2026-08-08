extends TestCase

## The companion's rules, asserted against the data the game actually ships.
##
## Pure logic only, per D02: the numbers in `data/config/party.json`'s
## `companion` block, and the graze/idle-variant fallback in `pal_animator.gd`.
## No scene, no player, no world — whether the follow actually FEELS right is a
## thing to be looked at, and `tools/preview_companion.gd` renders it for that.

const ANIMATOR := preload("res://scripts/pals/pal_animator.gd")
const SPECIES := preload("res://scripts/pals/pal_species.gd")

const PARTY_PATH := "res://data/config/party.json"
const MOVEMENT_PATH := "res://data/config/movement.json"


func _companion_config() -> Dictionary:
	var file := FileAccess.open(PARTY_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		return {}
	var block: Variant = (parsed as Dictionary).get("companion")
	return block if block is Dictionary else {}


func _movement() -> Dictionary:
	var file := FileAccess.open(MOVEMENT_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


## --- the speeds, against the trainer's own legs -----------------------------
##
## Both of these are comments in party.json turned into assertions, for the
## reason `test_mount.gd` gives about its own speed test: a bullet phrased as a
## comparison should fail the build on the day someone retunes the trainer and
## does not think about who is following him.

func test_the_run_beats_the_trainers_sprint_or_the_companion_is_lost_on_a_hill() -> void:
	var run: float = float(_companion_config().get("run_speed", 0.0))
	var sprint: float = float(_movement().get("sprint_speed", 7.6))
	assert_true(run > sprint,
		"companion run %.2f does not beat the trainer's sprint %.2f; it would fall behind on the first hill" % [
			run, sprint
		])


func test_the_walk_is_under_the_trainers_walk_so_a_stroll_is_trailed_not_orbited() -> void:
	var walk: float = float(_companion_config().get("walk_speed", 0.0))
	var trainer_walk: float = float(_movement().get("walk_speed", 4.2))
	assert_true(walk < trainer_walk,
		"companion walk %.2f is not under the trainer's %.2f; a strolling trainer would be circled, not trailed" % [
			walk, trainer_walk
		])


## --- the distances, and their hysteresis -------------------------------------

func test_the_distances_are_in_the_order_the_state_machine_assumes() -> void:
	var cfg := _companion_config()
	var follow: float = float(cfg.get("follow_distance", 0.0))
	var catch_up: float = float(cfg.get("catch_up_distance", 0.0))
	var run_at: float = float(cfg.get("run_distance", 0.0))
	var teleport: float = float(cfg.get("teleport_distance", 0.0))
	assert_true(follow < catch_up,
		"follow_distance must be under catch_up_distance or the hysteresis band is empty and the companion stutters")
	assert_true(catch_up < run_at, "catch_up_distance must be under run_distance")
	assert_true(run_at < teleport, "run_distance must be under teleport_distance")


func test_teleport_distance_is_well_past_what_the_camera_can_frame() -> void:
	# 5.2m is the spring arm's length in meadows_playground.tscn. Teleporting at
	# anything close to that would catch the companion popping into a frame the
	# player is still looking at.
	var teleport: float = float(_companion_config().get("teleport_distance", 0.0))
	assert_true(teleport > 15.0,
		"teleport_distance %.1fm is close enough to the camera that a catch-up would be seen" % teleport)


## --- the graze beats ----------------------------------------------------------

func test_the_graze_and_idle_ranges_are_real_ranges() -> void:
	var g: Dictionary = _companion_config().get("graze", {})
	for pair in [["idle_seconds_min", "idle_seconds_max"], ["graze_seconds_min", "graze_seconds_max"]]:
		var lo: float = float(g.get(pair[0], -1.0))
		var hi: float = float(g.get(pair[1], -1.0))
		assert_true(lo > 0.0, "%s must be positive" % pair[0])
		assert_true(hi >= lo, "%s (%.1f) is under %s (%.1f)" % [pair[1], hi, pair[0], lo])


func test_variety_chance_is_a_probability() -> void:
	var chance: float = float(_companion_config().get("graze", {}).get("variety_chance", -1.0))
	assert_between(chance, 0.0, 1.0, "variety_chance is not a probability")


## --- the roster's clips, and the fallback when they are missing --------------

func test_some_species_can_graze_and_some_fall_back_to_idle() -> void:
	# Both halves matter: at least one species proves the beat is real, and at
	# least one proves the fallback path is real rather than theoretical. The
	# Rat and the Frog (Easy Enemy Pack, .fbx) ship no Eating or Idle_2 — this is
	# the test that would fail quietly if a future pack made every species carry
	# one and nothing ever exercised `_fallbacks(GRAZE)` again.
	var with_graze := 0
	var without_graze := 0
	for id in SPECIES.ids():
		var anims: Dictionary = SPECIES.definition(id).get("placeholder", {}).get("animations", {})
		if anims.has("graze"):
			with_graze += 1
			assert_true(anims.has("idle_variant"),
				"'%s' declares graze but not idle_variant; the two beats should arrive together" % id)
		else:
			without_graze += 1
	assert_true(with_graze > 0, "no species can graze at all")
	assert_true(without_graze > 0, "every species grazes; the fallback to idle is never exercised")


## --- the animator itself, with fixtures rather than a scene ------------------
##
## A bare AnimationPlayer with one or two library entries, built and freed
## per-test, which is enough to prove `play_hold` without a world at all.

func test_a_settled_beat_with_no_clip_falls_back_to_idle_rather_than_freezing() -> void:
	var player := AnimationPlayer.new()
	var lib := AnimationLibrary.new()
	lib.add_animation("Idle", Animation.new())
	player.add_animation_library("", lib)
	var animator: RefCounted = ANIMATOR.new(player, {"idle": "Idle"})
	animator.call("play_hold", "graze", 4.0)
	assert_eq(player.current_animation, "Idle",
		"a species with no graze clip should hold on idle, not sit frozen with nothing playing")
	player.free()


func test_a_settled_beat_with_a_clip_plays_that_clip() -> void:
	var player := AnimationPlayer.new()
	var lib := AnimationLibrary.new()
	lib.add_animation("Idle", Animation.new())
	lib.add_animation("Eating", Animation.new())
	player.add_animation_library("", lib)
	var animator: RefCounted = ANIMATOR.new(player, {"idle": "Idle", "graze": "Eating"})
	animator.call("play_hold", "graze", 4.0)
	assert_eq(player.current_animation, "Eating", "a species with a graze clip should play it, not idle instead")
	player.free()


func test_a_faint_still_refuses_a_settled_beat_the_same_way_it_refuses_a_one_shot() -> void:
	# play_hold shares play_once's guard: nothing plays over a death. A companion
	# animator is never asked to graze a fainted body — companion.gd calls
	# play_faint() instead — but the guard has to hold regardless of caller.
	var player := AnimationPlayer.new()
	var lib := AnimationLibrary.new()
	lib.add_animation("Idle", Animation.new())
	lib.add_animation("Death", Animation.new())
	player.add_animation_library("", lib)
	var animator: RefCounted = ANIMATOR.new(player, {"idle": "Idle", "faint": "Death"})
	animator.call("play_faint")
	animator.call("play_hold", "graze", 4.0)
	assert_eq(player.current_animation, "Death", "a settled beat resumed animation after a faint")
	player.free()
