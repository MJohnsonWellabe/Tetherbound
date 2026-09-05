extends Node

## The conversation push-in: who is being talked to, and where the camera has to
## stand to make them readable.
##
## D73 §6 / closure plan CL-G10. "Villagers read too small in dialogue" is a
## camera-depth problem, not a scale problem — the owner has had villager scale
## cut and re-cut and it is not moving again. So when a conversation opens the
## rig leaves the exploration orbit and blends to a two-shot: the speaker near
## the middle of frame at about 3.5m, the trainer's near shoulder on the
## opposite third, the lens narrowed so the person talking actually fills the
## handheld's screen.
##
## Two jobs, deliberately split:
##
##   * this node WATCHES — it lives under the rig, listens to the interaction
##     arbiter for whoever was last activated, and answers "who is speaking";
##   * the statics below SOLVE — pure geometry, no nodes, no physics, so the
##     framing can be asserted by a unit test instead of by looking at it.
##
## `camera_rig.gd` owns the blend, the spring arm and the occlusion probe,
## because those are the rig's own state and splitting them across two files is
## how a camera ends up with two opinions about where it is.
##
## Nothing here changes any villager's size (CLAUDE.md: creatures loom, humans
## are what they are), and nothing here touches the dialogue panel's layout.

const CONFIG_PATH := "res://data/config/camera.json"

## Found by `dialogue_panel.gd` through this group rather than an exported path,
## the same way that panel is itself found through "dialogue_panel": the panel is
## a CanvasLayer built by the world and has no business knowing where the camera
## rig sits in the tree.
const GROUP := "conversation_camera"

## `interaction_arbiter.gd::GROUP`. Named here rather than preloaded because
## preloading the arbiter from the camera would make the player scene depend on
## the whole interaction stack to boot.
const ARBITER_GROUP := "interaction_arbiter"

## Seconds between attempts to find the arbiter. The rig exists in scenes that
## have no arbiter at all (the title screen, a capture fixture), and a per-frame
## group lookup that never succeeds is a per-frame cost for nothing.
const BIND_INTERVAL := 0.5

## Every tunable this file reads, with the value used when `camera.json` is
## missing or a key is absent. Duplicated from the JSON on purpose: a config
## file that fails to load must not silently produce a camera at the origin.
const DEFAULTS := {
	"distance": 3.5,
	"blend_time": 0.45,
	"fov": 40.0,
	"speaker_bias": 0.78,
	"shoulder_yaw_deg": 18.0,
	"elevation_deg": 7.0,
	"trainer_anchor_height": 1.45,
	"speaker_anchor_frac": 0.78,
	"min_speaker_clearance": 1.25,
	"min_trainer_clearance": 1.0,
	"min_pair_separation": 0.6,
	"max_speaker_distance": 9.0,
	"min_distance": 1.2,
	"clearance_ratio": 0.82,
	"fallback": {
		"distance": 2.1,
		"shoulder_yaw_deg": 11.0,
		"elevation_deg": 5.0,
		"fov": 46.0,
		"speaker_bias": 0.7,
		"swing_search_deg": [0.0, 25.0, -25.0, 50.0, -50.0, 75.0, -75.0, 100.0, -100.0],
	},
}

var _config: Dictionary = {}
var _arbiter: Node = null
var _last_provider: Node3D = null
var _bind_timer: float = 0.0
var _active: bool = false


func _ready() -> void:
	add_to_group(GROUP)
	_config = config()
	_bind_arbiter()


func _process(delta: float) -> void:
	if _arbiter != null and is_instance_valid(_arbiter):
		return
	_bind_timer -= delta
	if _bind_timer > 0.0:
		return
	_bind_timer = BIND_INTERVAL
	_bind_arbiter()


func _bind_arbiter() -> void:
	# `get_tree()` is not merely null outside the tree, it PRINTS — and this is
	# now reachable from `current_speaker()`, which a detached rig calls.
	if not is_inside_tree():
		return
	var node := get_tree().get_first_node_in_group(ARBITER_GROUP)
	if node == null:
		return
	_arbiter = node
	if _arbiter.has_signal("activated") \
			and not _arbiter.is_connected("activated", _on_interaction_activated):
		_arbiter.connect("activated", _on_interaction_activated)


## The arbiter hands over the provider that was activated, which for a person is
## the `interactable.gd` hung on their chest. Remembered rather than acted on:
## the press that activates a villager and the frame their conversation opens on
## are not the same frame, and plenty of activations (a berry bush, a bed) never
## open a conversation at all.
func _on_interaction_activated(provider: Object) -> void:
	_last_provider = provider as Node3D


## --- the hook ---------------------------------------------------------------

## A conversation went up. Returns true only if the camera actually moved, so a
## caller can tell "pushed in" from "left alone" without guessing.
##
## Left alone is the correct answer more often than it looks: a road gate's lock
## message and a cart repair both open the dialogue panel with nobody to frame,
## and a push-in onto a fence post is worse than no push-in.
func begin(speaker: Node3D = null) -> bool:
	if _active:
		return false
	var rig := _rig()
	if rig == null or not rig.has_method("enter_conversation"):
		return false
	var who := speaker if speaker != null else current_speaker()
	if who == null:
		return false
	_active = bool(rig.call("enter_conversation", who, config()))
	return _active


## The conversation came down. Safe to call when nothing pushed in.
func end() -> void:
	_active = false
	var rig := _rig()
	if rig != null and rig.has_method("exit_conversation"):
		rig.call("exit_conversation")


## Who this conversation is with, ASKED AT THE MOMENT THE BOX GOES UP rather
## than remembered from the `activated` signal.
##
## This ordering is not a detail, it is the whole reason the push-in works.
## `interaction_arbiter.gd::activate()` calls `provider.interaction_activate()`
## FIRST and emits `activated` afterwards — and `interaction_activate` on a
## villager opens the dialogue panel synchronously, which is what calls in here.
## So at this instant `activated` has not been emitted yet: `_last_provider`
## still holds the PREVIOUS conversation's speaker, and is null on the first one
## of the session. Reading it here meant the push-in silently never engaged on
## the first villager you ever spoke to and framed the wrong person after that —
## which is exactly what `tools/_capture_dialogue_camera.gd` caught ("the
## conversation opened but the camera never pushed in").
##
## `winning_provider()` is the arbiter's own live answer to "whose prompt is on
## screen", already public for `combat_hud.gd`, and during `activate()` it IS
## the provider being fired. The remembered `_last_provider` stays as the
## fallback for a conversation opened by something other than a button press (a
## story beat), where there is no live winner to read.
func current_speaker() -> Node3D:
	if _arbiter == null or not is_instance_valid(_arbiter):
		# A conversation can open on an earlier frame than the half-second bind
		# poll in `_process` has got to — the opening beat starts one before the
		# player has taken a step.
		_bind_arbiter()
	if _arbiter != null and is_instance_valid(_arbiter) and _arbiter.has_method("winning_provider"):
		var live := resolve_speaker(_arbiter.call("winning_provider") as Node3D)
		if live != null:
			return live
	return resolve_speaker(_last_provider)


func is_pushed_in() -> bool:
	return _active


func last_provider() -> Node3D:
	return _last_provider


## Test seam: stand in for the arbiter having reported an activation.
func note_activation_for_tests(provider: Node3D) -> void:
	_last_provider = provider


func _rig() -> Node:
	return get_parent()


## --- who is speaking --------------------------------------------------------

## The body to frame, from the interaction provider that was last activated.
##
## The provider is a prompt node bolted to something; the thing itself is its
## parent. Only a CHARACTER is accepted — `character_model.gd` descendants
## answer `height()` and `has_model()`, and a harvest point, a bed or a gate
## answers neither. That is the whole filter, and it is why pressing the button
## on a cart still opens the cart's dialogue with the ordinary camera.
static func resolve_speaker(provider: Node3D) -> Node3D:
	if provider == null or not is_instance_valid(provider):
		return null
	if _is_character(provider):
		return provider
	var parent := provider.get_parent() as Node3D
	if parent != null and _is_character(parent):
		return parent
	return null


static func _is_character(node: Node) -> bool:
	return node != null and node.has_method("height") and node.has_method("has_model")


## --- reading a node's place in the world ------------------------------------
##
## `Node3D` refuses to answer `global_transform` outside a SceneTree — the
## engine asserts `is_inside_tree()`, prints, and hands back the identity. The
## rig's own unit test (`tests/test_conversation_camera.gd`) has no tree to be
## inside, because `tests/run_tests.gd` runs entirely inside `_init` and
## `Engine.get_main_loop()` is null for the whole of it, so a rig built there is
## detached by necessity.
##
## Every world position on the conversation path is therefore read and written
## through these three. Inside the tree they are exactly `global_position` /
## `global_transform.basis`; outside it they fall back to the node's own
## transform, which for an unparented node is the same thing. The rig itself is
## `top_level`, so even in the running game its global transform IS its local
## one — this is not a test-only path pretending to be the real one.

static func world_position(node: Node3D) -> Vector3:
	if node == null or not is_instance_valid(node):
		return Vector3.ZERO
	return node.global_position if node.is_inside_tree() else node.position


static func set_world_position(node: Node3D, at: Vector3) -> void:
	if node == null or not is_instance_valid(node):
		return
	if node.is_inside_tree():
		node.global_position = at
	else:
		node.position = at


static func world_basis(node: Node3D) -> Basis:
	if node == null or not is_instance_valid(node):
		return Basis()
	return node.global_transform.basis if node.is_inside_tree() else node.transform.basis


## The point on the speaker the shot is framed on: their own chest, derived from
## their own height, so a tall NPC is not framed on the belt and a short one is
## not framed over the head.
static func speaker_anchor(speaker: Node3D, cfg: Dictionary) -> Vector3:
	if speaker == null or not is_instance_valid(speaker):
		return Vector3.ZERO
	var frac := float(cfg.get("speaker_anchor_frac", DEFAULTS["speaker_anchor_frac"]))
	var at := world_position(speaker)
	if speaker.has_method("height"):
		return at + Vector3.UP * float(speaker.call("height")) * frac
	return at


## --- the geometry -----------------------------------------------------------

## Solve the two-shot.
##
## Returns the pose the rig has to take, in the rig's own terms: `pivot` is where
## the arm's origin goes, `dir` is the unit vector from that pivot out to the
## camera (a SpringArm3D places its children along its own +Z, so `dir` IS the
## rig's basis.z), `yaw`/`pitch` are that direction as the euler the rig stores,
## and `distance` is the arm length.
##
## Framing, in one paragraph: the pivot sits `speaker_bias` of the way along the
## line from the trainer's chest to the speaker's, so the frame's centre is
## mostly on the person talking. The camera then stands back along that same
## line, swung `shoulder_yaw_deg` to one side and lifted `elevation_deg`. That
## swing is what turns "looking at the back of the trainer's head" into "looking
## past the trainer's shoulder": the trainer ends up a metre and a half from the
## lens on one third of frame, the speaker three or four metres away on the other.
##
## `fallback_forward` is used only when the two are standing on top of each
## other and the line between them has no direction to speak of.
static func solve(trainer_anchor: Vector3, speaker_anchor_point: Vector3,
		fallback_forward: Vector3, cfg: Dictionary,
		max_distance: float = INF) -> Dictionary:
	var to_speaker := speaker_anchor_point - trainer_anchor
	var planar := Vector3(to_speaker.x, 0.0, to_speaker.z)
	var separation := float(cfg.get("min_pair_separation", DEFAULTS["min_pair_separation"]))
	var axis := Vector3.FORWARD
	if planar.length() >= separation:
		axis = planar.normalized()
	else:
		var fallback_planar := Vector3(fallback_forward.x, 0.0, fallback_forward.z)
		axis = fallback_planar.normalized() if fallback_planar.length() > 0.001 else Vector3.FORWARD

	var swing := deg_to_rad(float(cfg.get("shoulder_yaw_deg", DEFAULTS["shoulder_yaw_deg"])))
	var elevation := deg_to_rad(float(cfg.get("elevation_deg", DEFAULTS["elevation_deg"])))
	var back := (-axis).rotated(Vector3.UP, swing)
	var dir := (back * cos(elevation) + Vector3.UP * sin(elevation)).normalized()

	var floor_distance := float(cfg.get("min_distance", DEFAULTS["min_distance"]))
	var distance := maxf(float(cfg.get("distance", DEFAULTS["distance"])), floor_distance)
	# `max_distance` is the room actually measured behind the shot, and it is a
	# hard ceiling: past this point there is a wall, and an arm longer than it
	# is an arm the engine will shorten on its own, somewhere the framing did
	# not choose.
	if max_distance < INF:
		distance = clampf(max_distance, floor_distance, distance)

	var bias := clampf(float(cfg.get("speaker_bias", DEFAULTS["speaker_bias"])), 0.0, 1.0)

	# NEVER INSIDE THE TRAINER'S OWN HEAD.
	#
	# The pivot sits `bias` of the way along the line to the speaker and the
	# camera stands `distance` back from it, so it is the TRAINER who ends up
	# between the pivot and the lens. Outdoors, with the full 3.5m arm, they are
	# a comfortable metre and a half away. In Bram's inn, with the arm cut to the
	# room and then cut again by the spring arm's own margin, the lens finished
	# 0.36m off their centre line with their hair filling the left third of the
	# frame as unlit backfaces.
	#
	# `distance` cannot grow — there is a wall there — so the bias gives way
	# instead: sliding the pivot back toward the trainer pushes the lens further
	# from them for the same arm.
	#
	# Solved rather than approximated, because the swing matters. With the
	# camera almost straight behind the trainer, clearance is very nearly
	# `distance - bias * separation`; swung 80 degrees round the pivot (which is
	# what a corner forces, see `swing_search_deg`) the lens is off to one side
	# and already clear, and an along-the-axis estimate would crush the bias to
	# nothing for no reason. So: the lens sits at `bias * u + v` from the
	# trainer, where u is the trainer -> speaker vector and v the arm. Its length
	# is a quadratic in `bias`, dipping below the guard between two roots; the
	# lower root is the largest bias still outside the trainer.
	var u := speaker_anchor_point - trainer_anchor
	var v := dir * distance
	var trainer_clearance := float(cfg.get(
		"min_trainer_clearance", DEFAULTS["min_trainer_clearance"]))
	var uu := u.length_squared()
	if uu > 0.000001:
		var uv := u.dot(v)
		var disc := uv * uv - uu * (v.length_squared() - trainer_clearance * trainer_clearance)
		if disc > 0.0:
			# disc <= 0 means the arm never brings the lens within the guard at
			# any bias, and there is nothing to correct.
			bias = minf(bias, maxf((-uv - sqrt(disc)) / uu, 0.0))

	var pivot := trainer_anchor.lerp(speaker_anchor_point, bias)

	# Never inside the person talking either. The camera stands behind the
	# trainer, so this only bites when the two are almost sharing a tile — but
	# that is exactly what happens when a villager is placed against a wall and
	# the player walks into them to trigger the greeting. It may lengthen the
	# arm past `max_distance`, and is allowed to: a lens inside somebody's chest
	# is a worse frame than one that clips a wall behind it.
	var clearance := float(cfg.get("min_speaker_clearance", DEFAULTS["min_speaker_clearance"]))
	var gap := (pivot + dir * distance).distance_to(speaker_anchor_point)
	if gap < clearance:
		distance += clearance - gap

	return {
		"pivot": pivot,
		"dir": dir,
		"distance": distance,
		"yaw": atan2(dir.x, dir.z),
		"pitch": -asin(clampf(dir.y, -1.0, 1.0)),
		"fov": float(cfg.get("fov", DEFAULTS["fov"])),
		"fallback": false,
	}


## The tighter shot used when the two-shot has no room. Indoors — Mira's cottage,
## Bram's inn — there is frequently under two metres of floor behind the trainer,
## and a 3.5m arm the engine then clamps to 1.4m is a camera looking at a wall
## with a person somewhere off the edge of it. Re-solving at a shorter distance
## with less swing keeps the composition instead of losing it to the clamp.
static func fallback_config(cfg: Dictionary) -> Dictionary:
	var merged := cfg.duplicate(true)
	var overrides: Variant = cfg.get("fallback", DEFAULTS["fallback"])
	if overrides is Dictionary:
		for key: String in (overrides as Dictionary):
			merged[key] = (overrides as Dictionary)[key]
	merged.erase("fallback")
	return merged


## Does `free_distance` metres of clear space behind the pivot leave room for
## this shot? `clearance_ratio` rather than the full length because the spring
## arm's own `margin` already eats a little, and re-solving for the last few
## centimetres would flip between the two shots as the player shuffled.
static func is_blocked(shot: Dictionary, free_distance: float, cfg: Dictionary) -> bool:
	var ratio := float(cfg.get("clearance_ratio", DEFAULTS["clearance_ratio"]))
	return free_distance < float(shot.get("distance", 0.0)) * ratio


## How far behind the trainer this shot actually puts the lens. The number the
## `min_trainer_clearance` guard above exists to hold up, exposed so a test can
## assert on it rather than on the bias that produced it.
static func trainer_clearance_of(shot: Dictionary, trainer_anchor: Vector3) -> float:
	var pivot: Vector3 = shot.get("pivot", Vector3.ZERO)
	var dir: Vector3 = shot.get("dir", Vector3.FORWARD)
	var at := pivot + dir * float(shot.get("distance", 0.0))
	return at.distance_to(trainer_anchor)


## --- config -----------------------------------------------------------------

static var _cached_config: Dictionary = {}


static func config() -> Dictionary:
	if not _cached_config.is_empty():
		return _cached_config
	_cached_config = DEFAULTS.duplicate(true)
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_warning("camera.json missing; the conversation push-in is using built-in defaults")
		return _cached_config
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("camera.json is not valid JSON; the conversation push-in is using built-in defaults")
		return _cached_config
	var block: Variant = (parsed as Dictionary).get("conversation", {})
	if not block is Dictionary:
		return _cached_config
	for key: String in (block as Dictionary):
		if key.begins_with("_comment"):
			continue
		if key == "fallback":
			var overrides: Variant = (block as Dictionary)[key]
			if overrides is Dictionary:
				var merged: Dictionary = (_cached_config["fallback"] as Dictionary).duplicate()
				for inner: String in (overrides as Dictionary):
					if inner.begins_with("_comment"):
						continue
					merged[inner] = (overrides as Dictionary)[inner]
				_cached_config["fallback"] = merged
			continue
		_cached_config[key] = (block as Dictionary)[key]
	return _cached_config


## The swings the cramped shot is allowed to try, as extra degrees added to the
## configured `shoulder_yaw_deg`. See `camera.json`'s own note: a corner has no
## room behind the trainer and plenty beside them.
static func swing_search(cfg: Dictionary) -> Array:
	var swings: Variant = cfg.get("swing_search_deg", DEFAULTS["fallback"]["swing_search_deg"])
	if swings is Array and not (swings as Array).is_empty():
		return swings as Array
	return [0.0]
