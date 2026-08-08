extends Node

## The active party pal, OUT in the world beside the trainer.
##
## This is the identity fix. A creature-collector where the creature you caught
## is a row in a menu is not the genre it claims to be — MEADOWS_VERTICAL_SLICE
## and every reference this project measures itself against put the pal on
## screen, at your heel, the whole time. Before this file, the party's deployed
## pal existed only as data and as whichever body a fight happened to spawn.
##
## THE CREATURE RIDDEN IS THE CREATURE WALKING is `mount.gd`'s reasoning
## (docs/decisions/D24) extended one step further: it is also the creature
## FOLLOWING. One pal, one body, one set of rules about where it can be — never a
## second thing the player owns that the five-pal cap and the release ceremony
## have to be taught about separately.
##
## WHAT THIS IS NOT: a second locomotion system. `pal_body` already knows how to
## move a creature over this terrain — gravity, slopes, the world's own ground
## query, an animator that shows idle/walk/run from its own speed with no help
## from here. This file is the follow/settle DECISION, expressed as
## `request_move` calls into a body that already knows how to obey them, the same
## division `wild_pal.gd`'s AI and `mount.gd`'s stick-reading keep.
##
## D09 IS BINDING. Every placement — first appearance, teleport catch-up, a
## fallen pal's spot — goes through `pal_body.place_on_ground`, which asks the
## world's heightfield before it ever considers a ray. Roughly a quarter of
## downward rays miss terrain that is demonstrably there; a companion placed by
## ray would fall through the meadow once in four appearances and read as a
## physics bug rather than as the placement bug it would be.
##
## WHAT THIS FILE DELIBERATELY DOES NOT DO, so the gap is on the record rather
## than discovered later:
##
##   * NO MANUAL RECALL BUTTON. `data/config/party.json`'s header describes a
##     save-state flag for "is the companion out at all", which implies a player
##     toggle. This pass makes presence fully automatic instead — out whenever
##     there is an active, standing pal and nothing else has claimed the world
##     (a fight, a menu, the saddle) — because the headline ask was "not a toggle
##     you must discover", and because wiring a second meaning onto the `mount`
##     button (which already answers "get on" vs "get off" for a rideable pal)
##     risks exactly the kind of silent input collision `mount.gd`'s own header
##     warns about on `interact`. A recall button is a real feature to add later;
##     it is not this one.
##   * NO SHARED BODY WITH COMBAT. When a fight opens, this file's body is
##     hidden and `encounter_director` spawns its own `_ally_body` for the fight,
##     exactly as it always has — the companion does not hand its body to the
##     fight. The visible seam is one frame: the same species that was walking
##     beside the trainer is the one that appears in the arena, which reads as
##     continuous even though the node underneath is not the same one. Unifying
##     them is a real simplification available later; it touches
##     `encounter_director.gd`, which had five other systems land in it tonight,
##     and this file does not risk that edit blind.
##   * NO SAVE DOMAIN. Nothing here is player-set state to persist — "is the
##     companion out" is derived every frame from the party and the world, not
##     stored — so there is nothing to write to `SaveManager` yet. The day a
##     manual toggle exists, it needs one; today it would be inventing a flag to
##     persist a fact the code can always re-derive.

const SPECIES := preload("res://scripts/pals/pal_species.gd")
const BODY_SCENE := preload("res://scenes/pals/pal.tscn")
## `pal.tscn` carries no script by design; the role picks one. A companion is a
## plain body with no AI of its own — it is driven entirely from here.
const BODY_SCRIPT := preload("res://scripts/pals/pal_body.gd")

const CONFIG_PATH := "res://data/config/party.json"

## The two settled beats a companion cycles through while it waits, and the
## third state that is simply "say nothing and let `pal_body`'s own idle show" —
## see `_tick_settled()`.
enum Beat { WAIT, GRAZE, VARIETY }

signal shown(species_id: String)
signal hidden(species_id: String, reason: String)

const REASON_NO_PAL := "no_pal"
const REASON_SUPPRESSED := "suppressed"
const REASON_LEFT_BEHIND := "left_behind"


## --- config -------------------------------------------------------------

static var _config: Dictionary = {}


static func config() -> Dictionary:
	if not _config.is_empty():
		return _config
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("party.json missing at %s" % CONFIG_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		var block: Variant = (parsed as Dictionary).get("companion")
		if block is Dictionary:
			_config = block
	return _config


## --- wiring ---------------------------------------------------------------

var _player: CharacterBody3D = null
var _camera_rig: Node3D = null
## Duck-typed, cached, the idiom `mount.gd` and `tools.gd` already use — this
## works in the shipping scene, in a preview tool, and in a bare test world with
## no exported NodePath having to be right.
var _party: Node = null
var _world: Node = null

var _body: CharacterBody3D = null
var _species: String = ""

var _state := Beat.WAIT
var _beat_left: float = 0.0
## Latched once a fainted companion has been put away for being left behind, so
## the distance check that put it away does not immediately respawn it at the
## trainer's own feet. Cleared the moment the pal is no longer fainted.
var _fainted_away: bool = false

var _rng := RandomNumberGenerator.new()


func bind(player: CharacterBody3D, camera_rig: Node3D = null) -> void:
	_player = player
	_camera_rig = camera_rig


func _ready() -> void:
	if _player == null:
		_player = get_parent() as CharacterBody3D
	_rng.randomize()


func is_out() -> bool:
	return _body != null and is_instance_valid(_body)


func species_id() -> String:
	return _species


func body() -> Node3D:
	return _body


## --- the loop ---------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return

	var pal := _active_pal()
	if pal == null:
		_put_away(REASON_NO_PAL)
		return

	if _is_suppressed():
		_put_away(REASON_SUPPRESSED)
		return

	if bool(pal.get("fainted")):
		_tick_fainted(pal)
		return

	_fainted_away = false
	_ensure_body(pal)
	if _body == null:
		return
	_follow(delta)


## Locomotion is already the one door in and out of "is the trainer free to act
## right now" — `mount.gd` reads it for the same reason and its comment says it
## best: asking the trainer whether he is currently allowed to move is one
## question that covers every present and future reason he is not, rather than
## this file having to learn each one by name.
func _is_suppressed() -> bool:
	if _player.has_method("mount"):
		var mount_node: Node = _player.call("mount") as Node
		if mount_node != null and bool(mount_node.call("is_mounted")):
			return true
	if _player.has_method("locomotion_enabled") and not bool(_player.call("locomotion_enabled")):
		return true
	return false


func _active_pal() -> RefCounted:
	var party := _find_party()
	if party == null:
		return null
	return party.call("active") as RefCounted


## --- fainted: it stays where it fell -----------------------------------------
##
## GAME_DESIGN.md §16, carried into M6: a fainted pal's body stays down rather
## than walking. The real fight is fought by `encounter_director`'s own body
## (see the file header on why this is a separate node), so the first thing this
## file learns about a faint is the party record already saying so — there is no
## earlier moment to catch it in.

func _tick_fainted(pal: RefCounted) -> void:
	if _fainted_away:
		return

	var id := str(pal.get("species_id"))
	if _body == null or not is_instance_valid(_body) or _species != id:
		_despawn()
		_body = _spawn_at(id, _player.global_position)
		_species = id
		if _body == null:
			return
		_body.call("play_faint")

	var cfg := config()
	var leave := float(cfg.get("fainted_leave_distance", 20.0))
	var dist: float = _player.global_position.distance_to(_body.global_position)
	if dist > leave:
		_despawn()
		_fainted_away = true
		hidden.emit(id, REASON_LEFT_BEHIND)


## --- healthy: spawn, and keep the right species on screen --------------------

func _ensure_body(pal: RefCounted) -> void:
	var id := str(pal.get("species_id"))
	if _body != null and is_instance_valid(_body) and _species == id:
		return
	_despawn()
	var spot := _spawn_spot()
	_body = _spawn_at(id, spot)
	if _body == null:
		return
	_species = id
	_state = Beat.WAIT
	_beat_left = _rng.randf_range(
		float(config().get("graze", {}).get("idle_seconds_min", 3.0)),
		float(config().get("graze", {}).get("idle_seconds_max", 7.0))
	)
	shown.emit(id)


## --- following ----------------------------------------------------------------
##
## Distance decides everything, with hysteresis between settling and setting off
## again — `follow_distance` and `catch_up_distance` are deliberately different
## numbers (see party.json) so the companion does not stutter at one boundary.

func _follow(delta: float) -> void:
	var cfg := config()
	var to_trainer := _player.global_position - _body.global_position
	to_trainer.y = 0.0
	var dist := to_trainer.length()

	var teleport_at := float(cfg.get("teleport_distance", 26.0))
	if dist > teleport_at:
		_teleport_to_trainer()
		return

	var follow_at := float(cfg.get("follow_distance", 2.6))
	var catch_up_at := float(cfg.get("catch_up_distance", 4.5))
	var run_at := float(cfg.get("run_distance", 8.0))

	if dist <= follow_at:
		_tick_settled(delta)
		return
	if _state != Beat.WAIT and dist < catch_up_at:
		# Inside the hysteresis band: was settled, not yet far enough to chase
		# again. Keep waiting rather than creeping — a companion that paces
		# forward one step at a time here reads as broken, not attentive.
		_tick_settled(delta)
		return

	_state = Beat.WAIT
	var running := dist > run_at
	var speed := float(cfg.get("run_speed", 8.8)) if running else float(cfg.get("walk_speed", 3.6))
	_body.call("request_move", to_trainer.normalized(), speed)


## The settled cycle: WAIT (plain idle, `pal_body` shows this on its own from
## zero velocity) alternates with one active beat — grazing most of the time, an
## idle variant sometimes (`graze.variety_chance`) — each on its own rolled
## duration. See the file header for why the timer lives here rather than being
## read back from the animator: `pal_animator.play_hold` counts down privately,
## and this is the one place both need to agree on how long a beat lasts.
func _tick_settled(delta: float) -> void:
	_beat_left -= delta
	if _beat_left > 0.0:
		return

	var g: Dictionary = config().get("graze", {})
	match _state:
		Beat.WAIT:
			if _rng.randf() < float(g.get("variety_chance", 0.25)):
				_state = Beat.VARIETY
				_beat_left = float(g.get("variety_seconds", 2.5))
				_play_hold("idle_variant", _beat_left)
			else:
				_state = Beat.GRAZE
				_beat_left = _rng.randf_range(
					float(g.get("graze_seconds_min", 4.0)), float(g.get("graze_seconds_max", 9.0))
				)
				_play_hold("graze", _beat_left)
		_:
			_state = Beat.WAIT
			_beat_left = _rng.randf_range(
				float(g.get("idle_seconds_min", 3.0)), float(g.get("idle_seconds_max", 7.0))
			)
			# No clip to start: `pal_body`'s own tick sees zero velocity and
			# shows its base idle unprompted, which IS the WAIT beat.


func _play_hold(role: String, seconds: float) -> void:
	if _body != null and _body.has_method("play_hold"):
		_body.call("play_hold", role, seconds)


## Re-place at the trainer's side rather than force a long run home. A companion
## that sprints across the whole distance it was left behind by is a companion
## announcing that the player did something wrong; one that is simply there when
## you look again is not.
func _teleport_to_trainer() -> void:
	var spot := _spawn_spot()
	if not bool(_body.call("place_on_ground", spot)):
		return
	_body.call("face_towards", _player.global_position)
	_state = Beat.WAIT
	_beat_left = _rng.randf_range(
		float(config().get("graze", {}).get("idle_seconds_min", 3.0)),
		float(config().get("graze", {}).get("idle_seconds_max", 7.0))
	)


## --- spawning -----------------------------------------------------------------

func _spawn_spot() -> Vector3:
	var side := float(config().get("spawn_side", 1.7))
	return _player.global_position + _side_direction() * side


func _side_direction() -> Vector3:
	if _camera_rig != null and _camera_rig.has_method("planar_basis"):
		var basis_value: Basis = _camera_rig.call("planar_basis")
		return basis_value * Vector3(1.0, 0.0, 0.0)
	return _player.global_transform.basis.x


## Build the creature and stand it at `spot`. Returns null rather than a floating
## companion if the ground cannot be found — `place_on_ground` asks the world's
## heightfield first (D09) and only a spot neither it nor the ray fallback can
## answer for is refused, the same contract `mount.gd._spawn_body` keeps.
func _spawn_at(id: String, spot: Vector3) -> CharacterBody3D:
	var creature: CharacterBody3D = BODY_SCENE.instantiate()
	creature.set_script(BODY_SCRIPT)
	creature.name = "Companion"
	var parent := _find_world_root()
	if parent == null:
		parent = _player.get_parent()
	if parent == null:
		creature.free()
		return null
	parent.add_child(creature)
	creature.call("setup", id)
	if not bool(creature.call("place_on_ground", spot)):
		creature.queue_free()
		return null
	creature.call("face_towards", _player.global_position)

	# Excepted from each other, the reason `mount.gd` gives about the same
	# overlap: two CharacterBody3Ds resolving a collision by shoving each other
	# is how the trainer once left the playground at 500 m/s.
	creature.add_collision_exception_with(_player)
	_player.add_collision_exception_with(creature)
	if _camera_rig != null and _camera_rig.has_method("exclude_from_arm"):
		_camera_rig.call("exclude_from_arm", creature)
	return creature


func _despawn() -> void:
	if _body != null and is_instance_valid(_body):
		if _camera_rig != null and _camera_rig.has_method("stop_excluding"):
			_camera_rig.call("stop_excluding", _body)
		if _player != null and is_instance_valid(_player):
			_body.remove_collision_exception_with(_player)
			_player.remove_collision_exception_with(_body)
		_body.queue_free()
	_body = null
	_species = ""


func _put_away(reason: String) -> void:
	if _body == null:
		return
	var id := _species
	_despawn()
	hidden.emit(id, reason)


## --- finding the rest of the scene ---------------------------------------------

func _find_party() -> Node:
	if _party != null and is_instance_valid(_party):
		return _party
	_party = null
	var root: Node = _player.get_parent() if _player != null else null
	if root == null:
		return null
	for child in root.get_children():
		if child.has_method("active") and child.has_method("capacity"):
			_party = child
			break
	return _party


func _find_world_root() -> Node:
	if _world != null and is_instance_valid(_world):
		return _world
	_world = null
	var node: Node = _player.get_parent() if _player != null else null
	while node != null:
		if node.has_method("ground_height_at"):
			_world = node
			break
		node = node.get_parent()
	return _world
