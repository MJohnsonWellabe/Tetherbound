extends Node

## W12-COMPANION-0904 -- the deployed creature's contextual-reaction layer.
##
## `docs/FINISH_THE_MEADOWS_ADDENDUM_2026-09-04.md` section E and the owner's
## directive C section 5: the five-creature rule and the bond ladder cannot carry
## their emotional weight if the creature walking behind the trainer behaves
## like a model that appears when a fight needs it. This is the small reusable
## layer they ask for -- a handful of high-value reactions, each with a cooldown
## and a context guard, NOT a pet simulation.
##
## Attached by `follower_creature.gd` as a child named `Presence` and ticked by
## it every physics frame AFTER the follower's own follow logic and BEFORE the
## body integrates (`creature_body._physics_process`). That order matters: the
## only gameplay movement this layer ever asks for is the short `approach` walk,
## which goes through the same `request_move()` the follower uses, and a request
## made after the follower's own is the one the body honours this frame.
## Everything else here is presentation on `creature_body.model_pivot()` -- the
## pivot the body's own header says procedural motion may move ("the body's
## position is gameplay and belongs to the combat manager").
##
## What the installed rigs actually have, measured 2026-09-04 with
## `tools/_capture_companion_rig_inventory.gd`: every one of the 21 unique
## creature GLBs carries exactly `attack, faint, hit, idle, run, walk` and a
## `head` + `neck` bone. No happy loop, no bounce, no lie-down. So every state
## below is procedural (hop, nod, wiggle, scale pulse, roll/sink on the pivot)
## plus a clip the rig does have (`hit` as a flinch, `attack` as a roar), and
## the head turn is a `LookAtModifier3D` on the head bone. `play_if_exists` in
## `creature_animator.gd` is the one clip entry point, so a rig that some day
## lacks a clip degrades to "no clip", never to a frozen pose.
##
## THE GUARD. `blocked_reason()` names why nothing may start right now:
## a fight (aiming included), riding, any panel/menu/dialogue that owns input
## (`input_owner.gd`), a live actionable interact prompt, the sequence
## director's lockout, an armed build ghost, or a hidden body. A running
## reaction is cut and the pivot restored the instant a reason appears, so no
## reaction can ever be on screen while the player is piloting, aiming, reading
## or building. The one carve-out is data (`guard.victory_during_resolve`): the
## post-victory reaction may play during `combat_manager`'s RESOLVING pause
## after a WON fight -- the result beat -- when nothing pilots the body any more.
##
## EVENTS. Fights and the satchel reach this through `SceneTree.call_group`
## on `GROUP` (`on_event("victory")`, `on_care(creature, "feed")`), which is
## why neither hook needs a reference to the follower or a preload of this
## file. Events that arrive while the guard is up (care always does -- the
## satchel owns input at that moment) are QUEUED and fire when the context
## clears, expiring after `guard.pending_expiry_s`.
##
## BOND. `creature_instance.bond_nodes()` (0-5 milestones) shortens the
## acknowledgment delay and cooldown, adds hops and height to the victory
## reaction, unlocks the roar and the walk-up. A bond node completing is
## itself the strongest moment here -- polled off `bond_nodes()` each tick for
## now. HOOK POINT: `on_event("bond_milestone")` is the entry the progression
## feed (`docs/prompts/73-PROGRESSION-VISIBLE-bond-and-level-feedback.md`
## section 2.1, being built by another lane on `Game`) should call; when it
## lands, the poll below becomes redundant and can be removed. Nothing here
## builds that feed.

const CONFIG_PATH := "res://data/config/companion_presence.json"

## `combat_manager.gd` and `tab_backpack.gd` reach this layer with
## `get_tree().call_group(GROUP, ...)`; the follower body joins on setup.
const GROUP := &"companion_presence"
## Anything in this group counts as a camp source for the rest reaction, on
## top of the script-suffix scan `camp.script_suffixes` configures. A fixture
## or a future camp piece opts in by joining; nothing else is required.
const CAMP_GROUP := &"companion_camp"

const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
const CONDITION := preload("res://scripts/creatures/creature_condition.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")

## Reaction names. Also the keys of the config and of `_cooldowns`.
const ACKNOWLEDGE := "acknowledge"
const VICTORY := "victory"
const CARE := "care"
const BOND_MILESTONE := "bond_milestone"
## Not reactions: the two continuous states, reported by `is_hurt()` /
## `is_camped()` and driven every tick while their condition holds.
const HURT := "hurt"
const CAMP := "camp"

## Event kinds `on_event` accepts. `deploy` comes from the follower itself
## (`set_following(true)`), the other two from the hooks named above.
const EVENT_VICTORY := "victory"
const EVENT_DEPLOY := "deploy"
const EVENT_BOND_MILESTONE := "bond_milestone"

static var _config_cache: Dictionary = {}


static func config() -> Dictionary:
	if not _config_cache.is_empty():
		return _config_cache
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("companion_presence.json missing at %s" % CONFIG_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_config_cache = parsed
	return _config_cache


# --- wiring -----------------------------------------------------------------

var _body: Node3D = null
var _cfg: Dictionary = {}
var _rng := RandomNumberGenerator.new()

## Where the guard looks. Resolved lazily from the current scene by node name
## (the same names `scripts/debug/gate_f_probe.gd` uses) and overridable, so a
## unit test can hand in a stub combat manager or arbiter and drive the real
## guard rather than a mock of it.
var _combat_manager: Node = null
var _riding: Node = null
var _arbiter: Node = null
var _game: Node = null
var _context_resolved := false

## A test may pin the creature instance this layer reads; in the game it is
## `Game.party.active()` -- the deployed body IS the active party member.
var creature_override: RefCounted = null

## The active reaction, or "" when none.
var _state := ""
var _state_time := 0.0
var _state_cfg: Dictionary = {}
## Reaction phases: approaching the trainer first, then performing.
var _approaching := false
var _approach_time := 0.0
## Per-reaction cooldowns, seconds left.
var _cooldowns: Dictionary = {}
## Queued events awaiting a clear context: name -> seconds until it expires.
var _pending: Dictionary = {}
## Care kinds queued, in order (feed / heal / revive).
var _pending_care: Array[String] = []

var _still_seconds := 0.0
var _leader_last_pos := Vector3.ZERO
var _leader_seen := false

var _hurt := false
var _flinch_timer := 0.0
var _camp := false
var _camp_near := false
var _camp_standing_seconds := 0.0
var _camp_scan_timer := 0.0
var _camp_sources: Array[Node3D] = []

var _last_bond_nodes := -1
## Which creature `_last_bond_nodes` was read from. A party cycle swaps the
## deployed creature; comparing the new one's ladder against the old one's
## count would celebrate bond it earned long ago.
var _last_bond_creature: WeakRef = null

## Pivot bookkeeping: the rest transform is captured the first frame any
## effect touches the pivot and restored the frame the last one lets go.
var _pivot_held := false
var _pivot_rest := Transform3D.IDENTITY

var _anim_player: AnimationPlayer = null
var _anim_speed_held := false
var _look: LookAtModifier3D = null
var _look_skeleton: Skeleton3D = null
## Where a hurt creature's head hangs: a point on the ground just ahead of its
## own feet, which the head bone is aimed at instead of at the trainer. A
## whole-body forward pitch was tried first and a code-blind critic read it as
## "lying down, resting, or nosing at something on the ground" rather than as
## injured -- tipping the entire animal nose-down is a crouch, not a hung head.
## Drooping the HEAD while the body stays standing is the read that was wanted,
## and the rig has the bone for it.
var _droop_target: Node3D = null

## What fired, for tests and for the report: name -> count.
var fired: Dictionary = {}
## Hops the last hop-based reaction performed (bond scaling is visible here).
var last_hops := 0
var last_hop_height := 0.0
## Nodes walked by the last camp scan, so the cost is a printed number and
## not a guess.
var last_camp_scan_nodes := 0


func setup(body: Node3D, cfg: Dictionary = {}) -> void:
	_body = body
	_cfg = cfg if not cfg.is_empty() else config()
	_rng.randomize()
	if not is_in_group(GROUP):
		add_to_group(GROUP)


## For tests: the guard's three witnesses, handed in rather than searched for.
func set_context(combat_manager: Node, riding: Node, arbiter: Node, game: Node = null) -> void:
	_combat_manager = combat_manager
	_riding = riding
	_arbiter = arbiter
	_game = game
	_context_resolved = true


# --- events -----------------------------------------------------------------

## `victory` (combat_manager, at the result beat), `deploy` (the follower, when
## following starts), `bond_milestone` (the progression feed's hook; polled
## for now). Queued; fires on the first clear tick.
func on_event(kind: String) -> void:
	match kind:
		EVENT_VICTORY:
			_queue(VICTORY)
		EVENT_DEPLOY:
			# A fresh deployment is an acknowledgment without the wait -- but
			# never over a queued victory, which already brings the creature
			# back to the trainer.
			if not _pending.has(VICTORY):
				_queue(EVENT_DEPLOY)
		EVENT_BOND_MILESTONE:
			_queue(BOND_MILESTONE)
		_:
			push_warning("companion_presence: unknown event '%s'" % kind)


## The satchel fed / healed / revived `creature`. Only the creature this body
## represents reacts -- a potion on a benched party member is not this
## creature's moment.
func on_care(creature: RefCounted, kind: String) -> void:
	if creature == null or creature != _creature():
		return
	if not (_cfg.get(CARE, {}) as Dictionary).has(kind):
		push_warning("companion_presence: unknown care kind '%s'" % kind)
		return
	if not _pending_care.has(kind):
		_pending_care.append(kind)
	_queue(CARE)


func _queue(name: String) -> void:
	_pending[name] = float((_cfg.get("guard", {}) as Dictionary).get("pending_expiry_s", 20.0))


# --- the tick ---------------------------------------------------------------

func tick(delta: float) -> void:
	if _body == null or not is_instance_valid(_body) or delta <= 0.0:
		return
	_resolve_context()
	_resolve_model()
	for name in _cooldowns.keys():
		_cooldowns[name] = maxf(0.0, float(_cooldowns[name]) - delta)
	for name in _pending.keys():
		_pending[name] = float(_pending[name]) - delta
		if float(_pending[name]) <= 0.0:
			_pending.erase(name)
			if name == CARE:
				_pending_care.clear()

	var reason := blocked_reason()
	if reason != "":
		var victory_ok: bool = reason == "resolving_won" \
			and bool((_cfg.get("guard", {}) as Dictionary).get("victory_during_resolve", true))
		if not victory_ok:
			_suspend(reason)
			return
		# The result beat: only the victory reaction is welcome here. Anything
		# else waits for the handoff.
		_leave_continuous()
		_still_seconds = 0.0
		if _state == "" and _pending.has(VICTORY):
			_start(VICTORY)
		if _state == VICTORY:
			_advance(delta)
		return

	var leader := _leader()
	var creature := _creature()
	_track_stillness(delta, leader)
	_poll_bond(creature)
	_update_camp(delta, leader)
	_update_hurt(creature)
	_update_look(leader)

	if _state != "":
		_advance(delta)
		return

	# Pick the next reaction. Priority: the rare moment first, then the fight
	# just won, then something the player just did for it, then presence.
	if _pending.has(BOND_MILESTONE) and _off_cooldown(BOND_MILESTONE):
		_start(BOND_MILESTONE)
	elif _pending.has(VICTORY) and _off_cooldown(VICTORY):
		_start(VICTORY)
	elif _pending.has(CARE) and _off_cooldown(CARE) and not _pending_care.is_empty():
		_start(CARE)
	elif _pending.has(EVENT_DEPLOY) and _off_cooldown(EVENT_DEPLOY) and _standing():
		_pending.erase(EVENT_DEPLOY)
		_start(ACKNOWLEDGE, EVENT_DEPLOY)
	elif _still_seconds >= _acknowledge_delay(creature) and _off_cooldown(ACKNOWLEDGE) and _standing():
		_start(ACKNOWLEDGE)
	else:
		_drive_continuous(delta)


## Cut everything and restore the pivot: the context stopped being ours.
func _suspend(reason: String) -> void:
	if _state != "":
		var cut := _state
		_end_state()
		# The fight teardown hides the body under a victory hop; when the
		# body reappears beside the trainer it should turn to them rather
		# than stand facing the empty arena.
		if cut == VICTORY and reason == "hidden":
			_queue(EVENT_DEPLOY)
			# Deliberate and rare: it must not be swallowed by the ordinary
			# deploy cooldown from a recall a few seconds earlier.
			_cooldowns.erase(EVENT_DEPLOY)
	_leave_continuous()
	_set_look(false)
	_still_seconds = 0.0
	_camp_standing_seconds = 0.0


# --- the guard --------------------------------------------------------------

## "" when a reaction may run; otherwise the first reason it may not, in the
## game's own precedence (fight, then riding, then panels, then prompts).
func blocked_reason() -> String:
	if _body == null or not is_instance_valid(_body):
		return "no_body"
	if not _body.visible:
		return "hidden"
	if _leader() == null:
		return "no_leader"
	if _combat_manager != null and is_instance_valid(_combat_manager):
		if _combat_manager.has_method("is_aiming") and bool(_combat_manager.call("is_aiming")):
			return "aiming"
		if _combat_manager.has_method("is_fighting") and bool(_combat_manager.call("is_fighting")):
			# State.RESOLVING is 2 in combat_manager.gd's enum; asked by value
			# because the enum is not reachable without preloading a 1900-line
			# file this layer otherwise never needs.
			var resolving: bool = int(_combat_manager.get("state")) == 2
			var won: bool = _combat_manager.has_method("outcome") \
				and str(_combat_manager.call("outcome")) == "won"
			return "resolving_won" if resolving and won else "combat"
	if _riding != null and is_instance_valid(_riding) and _riding.has_method("is_mounted") \
			and bool(_riding.call("is_mounted")):
		return "riding"
	if _input_owner() != null:
		return "menu"
	if _arbiter != null and is_instance_valid(_arbiter):
		if _arbiter.has_method("enabled") and not bool(_arbiter.call("enabled")):
			return "locked"
		if _arbiter.has_method("winner"):
			var winner: Variant = _arbiter.call("winner")
			if winner is Dictionary and not (winner as Dictionary).is_empty() \
					and bool((winner as Dictionary).get("actionable", true)):
				return "prompt"
	if _game != null and is_instance_valid(_game) and not str(_game.get("pending_build")).is_empty():
		return "build"
	return ""


func _resolve_context() -> void:
	if _context_resolved:
		return
	_context_resolved = true
	var tree := _tree()
	if tree == null:
		return
	# The world is whichever ancestor of the body owns a CombatManager -- not
	# `tree.current_scene`, which is null in every `--script` smoke and capture
	# run (they `root.add_child(world)`), and a guard that cannot see the fight
	# in exactly the runs that verify it would be no guard at all.
	var scene: Node = null
	var node: Node = _body.get_parent() if _body != null else null
	while node != null:
		if node.get_node_or_null(^"CombatManager") != null:
			scene = node
			break
		node = node.get_parent()
	if scene == null:
		scene = tree.current_scene
	if scene != null:
		_combat_manager = scene.get_node_or_null(^"CombatManager")
		_riding = scene.get_node_or_null(^"RidingController")
		_arbiter = scene.get_node_or_null(^"InteractionArbiter")
	if tree.root != null:
		_game = tree.root.get_node_or_null(^"Game")


func _leader() -> Node3D:
	if _body == null:
		return null
	var leader: Variant = _body.get("leader")
	if leader is Node3D and is_instance_valid(leader):
		return leader
	return null


func _creature() -> RefCounted:
	if creature_override != null:
		return creature_override
	if _game == null or not is_instance_valid(_game):
		return null
	var party: Variant = _game.get("party")
	if party == null or not (party as Object).has_method("active"):
		return null
	return (party as Object).call("active")


## Position math that does not need a live tree. `global_position` errors on a
## node outside one, and `tests/run_tests.gd` has no tree for its whole life
## (see `tests/test_party_seam.gd`'s note): the unit fixture is a detached
## world whose children's local positions ARE their world positions.
func _gpos(node: Node3D) -> Vector3:
	return node.global_position if node.is_inside_tree() else node.position


## The node to walk for camp sources and input owners: the tree's root in the
## game, the body's topmost ancestor in a detached fixture.
## `get_tree()` is an engine error on a node outside a tree; this is the
## null-returning form every lookup below goes through.
func _tree() -> SceneTree:
	return get_tree() if is_inside_tree() else null


func _root() -> Node:
	var tree := _tree()
	if tree != null and tree.root != null:
		return tree.root
	var node: Node = _body
	while node != null and node.get_parent() != null:
		node = node.get_parent()
	return node


## `input_owner.gd::current()` in the game; the same group and the same
## `_owns` rule walked by hand when there is no tree to ask.
func _input_owner() -> Node:
	var tree := _tree()
	if tree != null:
		return INPUT_OWNER.current(tree)
	var root := _root()
	if root == null:
		return null
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node.is_in_group(INPUT_OWNER.GROUP) and bool(INPUT_OWNER._owns(node)):
			return node
		stack.append_array(node.get_children())
	return null


func _face_leader(leader: Node3D) -> void:
	if _body.is_inside_tree():
		_body.call("face_towards", leader.global_position)
		return
	var to := _gpos(leader) - _gpos(_body)
	to.y = 0.0
	if to.length() > 0.01:
		_body.rotation.y = atan2(to.x, to.z)


## Standing with the trainer rather than closing the gap: the follower's own
## `is_closing()` when it has one, else "not moving".
func _standing() -> bool:
	if _body.has_method("is_closing") and bool(_body.call("is_closing")):
		return false
	var velocity: Variant = _body.get("velocity")
	if velocity is Vector3:
		var flat: Vector3 = velocity as Vector3
		flat.y = 0.0
		return flat.length() < 0.6
	return true


func _off_cooldown(name: String) -> bool:
	return float(_cooldowns.get(name, 0.0)) <= 0.0


# --- stillness / bond polling -----------------------------------------------

func _track_stillness(delta: float, leader: Node3D) -> void:
	if leader == null:
		_still_seconds = 0.0
		return
	var speed := 0.0
	if leader.has_method("ground_speed"):
		speed = float(leader.call("ground_speed"))
	elif _leader_seen:
		var moved := _gpos(leader) - _leader_last_pos
		moved.y = 0.0
		speed = moved.length() / delta
	_leader_last_pos = _gpos(leader)
	_leader_seen = true
	var still_speed := float((_cfg.get(ACKNOWLEDGE, {}) as Dictionary).get("still_speed", 0.3))
	if speed <= still_speed:
		_still_seconds += delta
	else:
		_still_seconds = 0.0


func _bond_nodes(creature: RefCounted) -> int:
	if creature == null or not creature.has_method("bond_nodes"):
		return 0
	return int(creature.call("bond_nodes"))


func _acknowledge_delay(creature: RefCounted) -> float:
	var ack: Dictionary = _cfg.get(ACKNOWLEDGE, {})
	var bond: Dictionary = _cfg.get("bond", {})
	var base := float(ack.get("still_seconds", 6.0))
	var per := float(bond.get("acknowledge_still_seconds_per_node", -0.7))
	return maxf(float(ack.get("still_seconds_min", 2.5)), base + per * _bond_nodes(creature))


func _acknowledge_cooldown(creature: RefCounted) -> float:
	var ack: Dictionary = _cfg.get(ACKNOWLEDGE, {})
	var bond: Dictionary = _cfg.get("bond", {})
	var base := float(ack.get("cooldown_s", 30.0))
	var per := float(bond.get("acknowledge_cooldown_per_node", -3.0))
	return maxf(float(ack.get("cooldown_min_s", 12.0)), base + per * _bond_nodes(creature))


## A bond node completing is the layer's strongest moment. Polled until the
## progression feed exists (see the header's HOOK POINT); the first reading
## only primes the counter so a loaded save does not celebrate old news.
func _poll_bond(creature: RefCounted) -> void:
	if creature == null:
		return
	var nodes := _bond_nodes(creature)
	var same_creature: bool = _last_bond_creature != null and _last_bond_creature.get_ref() == creature
	if _last_bond_nodes < 0 or not same_creature:
		_last_bond_nodes = nodes
		_last_bond_creature = weakref(creature)
		return
	if nodes > _last_bond_nodes:
		_queue(BOND_MILESTONE)
	_last_bond_nodes = nodes


# --- reactions --------------------------------------------------------------

func _start(name: String, variant: String = "") -> void:
	_pending.erase(name)
	var cfg: Dictionary = (_cfg.get(name, {}) as Dictionary).duplicate()
	var creature := _creature()
	var nodes := _bond_nodes(creature)
	var bond: Dictionary = _cfg.get("bond", {})
	match name:
		CARE:
			var kind: String = _pending_care.pop_front() if not _pending_care.is_empty() else "feed"
			var kind_cfg: Dictionary = cfg.get(kind, {})
			for key in kind_cfg.keys():
				cfg[key] = kind_cfg[key]
			cfg["kind"] = kind
		VICTORY:
			cfg["hops"] = int(cfg.get("hops", 2)) \
				+ int(bond.get("victory_extra_hops_per_two_nodes", 1)) * int(nodes / 2)
			cfg["hop_height_fraction"] = float(cfg.get("hop_height_fraction", 0.16)) \
				* (1.0 + float(bond.get("victory_hop_height_scale_per_node", 0.12)) * nodes)
			if nodes < int(bond.get("victory_roar_from_node", 3)):
				cfg.erase("roar_clip")
			if nodes >= int(bond.get("approach_from_node", 2)):
				cfg["approach_distance"] = float((_cfg.get(ACKNOWLEDGE, {}) as Dictionary).get("approach_distance", 2.2))
				cfg["approach_seconds_max"] = 2.0
		ACKNOWLEDGE:
			cfg["variant"] = variant
	_state = name
	_state_cfg = cfg
	_state_time = 0.0
	_approach_time = 0.0
	_approaching = float(cfg.get("approach_distance", 0.0)) > 0.0
	last_hops = int(cfg.get("hops", 0))
	last_hop_height = float(cfg.get("hop_height_fraction", 0.0)) * _height()
	_leave_continuous()
	_hold_pivot()
	var clip := str(cfg.get("roar_clip", ""))
	if clip != "" and not _approaching:
		_play_clip(clip)
	var key := ACKNOWLEDGE + ":" + variant if name == ACKNOWLEDGE and variant != "" else name
	fired[key] = int(fired.get(key, 0)) + 1
	_still_seconds = 0.0


func _advance(delta: float) -> void:
	var leader := _leader()
	if leader == null:
		_end_state()
		return
	if _approaching:
		_approach_time += delta
		var to := _gpos(leader) - _gpos(_body)
		to.y = 0.0
		var want := float(_state_cfg.get("approach_distance", 2.0))
		if to.length() > want and _approach_time < float(_state_cfg.get("approach_seconds_max", 3.0)):
			var speed: Variant = _body.get("_walk_speed")
			var walk := float(speed) if speed is float else float(_body.call("base_speed")) * 0.6
			_body.call("request_move", to.normalized(), walk)
			return
		_approaching = false
		var clip := str(_state_cfg.get("roar_clip", ""))
		if clip != "":
			_play_clip(clip)
	_face_leader(leader)
	_state_time += delta
	var duration := maxf(float(_state_cfg.get("duration_s", 1.5)), 0.05)
	var t := clampf(_state_time / duration, 0.0, 1.0)
	_apply_pivot(_reaction_offsets(t))
	if _state_time >= duration:
		_end_state()


## The pose offsets a reaction wants at normalised time `t`, from its config:
## `hops` sequential arcs of `hop_height_fraction` x height; `nods` head dips of
## `nod_deg`; `wiggles` yaw shakes of `wiggle_deg`; `pulse` a scale swell.
func _reaction_offsets(t: float) -> Dictionary:
	var out := {"y": 0.0, "pitch": 0.0, "yaw": 0.0, "roll": 0.0, "scale": 0.0, "x": 0.0}
	var hops := int(_state_cfg.get("hops", 0))
	if hops > 0:
		var phase := fmod(t * hops, 1.0)
		out["y"] = float(_state_cfg.get("hop_height_fraction", 0.0)) * _height() * sin(PI * phase)
	var nods := int(_state_cfg.get("nods", 0))
	if nods > 0:
		var phase := fmod(t * nods, 1.0)
		out["pitch"] = deg_to_rad(float(_state_cfg.get("nod_deg", 0.0))) * sin(PI * phase)
	var wiggles := int(_state_cfg.get("wiggles", 0))
	if wiggles > 0:
		out["yaw"] = deg_to_rad(float(_state_cfg.get("wiggle_deg", 0.0))) * sin(TAU * t * wiggles)
	var pulse := float(_state_cfg.get("pulse", 0.0))
	if pulse > 0.0:
		out["scale"] = pulse * sin(PI * t)
	return out


func _end_state() -> void:
	var name := _state
	if name == "":
		return
	var creature := _creature()
	var cooldown := float(_state_cfg.get("cooldown_s", 0.0))
	if name == ACKNOWLEDGE:
		if str(_state_cfg.get("variant", "")) == EVENT_DEPLOY:
			_cooldowns[EVENT_DEPLOY] = float(_state_cfg.get("deploy_cooldown_s", 8.0))
			# A deploy nod is still an acknowledgment: it must not be chased by
			# a second nod the moment the trainer stands still.
			_cooldowns[ACKNOWLEDGE] = maxf(float(_cooldowns.get(ACKNOWLEDGE, 0.0)),
				float(_state_cfg.get("deploy_cooldown_s", 8.0)))
		else:
			_cooldowns[ACKNOWLEDGE] = _acknowledge_cooldown(creature)
	else:
		_cooldowns[name] = cooldown
	_state = ""
	_state_cfg = {}
	_approaching = false
	_release_pivot()


# --- continuous states: hurt, camp -------------------------------------------

func _update_hurt(creature: RefCounted) -> void:
	var cfg: Dictionary = _cfg.get(HURT, {})
	var hurt := false
	if creature != null:
		var fraction := float(creature.call("hp_fraction")) if creature.has_method("hp_fraction") else 1.0
		hurt = fraction < float(cfg.get("hp_below", 0.3)) \
			or CONDITION.is_hungry(creature, CONDITION.config())
	if hurt and not _hurt:
		_flinch_timer = _next_flinch()
	_hurt = hurt


func _next_flinch() -> float:
	var cfg: Dictionary = _cfg.get(HURT, {})
	var every := float(cfg.get("flinch_every_s", 9.0))
	var jitter := float(cfg.get("flinch_jitter_s", 3.0))
	return maxf(0.5, every + _rng.randf_range(-jitter, jitter))


func _update_camp(delta: float, leader: Node3D) -> void:
	var cfg: Dictionary = _cfg.get(CAMP, {})
	# Only ever scanned while the creature is standing. Settling requires
	# standing anyway (below), so a walk across the Meadows costs this nothing
	# -- which is the half that matters: the scan walks the world's node tree,
	# and the world is at its largest exactly while the player is travelling
	# through it. `last_camp_scan_nodes` reports what one scan actually cost.
	if not _standing():
		_camp_near = false
		_camp_standing_seconds = 0.0
		_camp_scan_timer = 0.0
		return
	_camp_scan_timer -= delta
	if _camp_scan_timer <= 0.0:
		_camp_scan_timer = float(cfg.get("scan_every_s", 2.0))
		_camp_sources = _scan_camp_sources(cfg)
	var radius := float(cfg.get("radius", 6.0))
	_camp_near = false
	for source in _camp_sources:
		if not is_instance_valid(source):
			continue
		var gap := _gpos(source) - _gpos(_body)
		gap.y = 0.0
		if gap.length() <= radius:
			_camp_near = true
			break
	# The trainer has to be part of the camp too: a creature that lies down
	# beside a fire while the player walks off has stopped following.
	if _camp_near and leader != null:
		var to_leader := _gpos(leader) - _gpos(_body)
		to_leader.y = 0.0
		if to_leader.length() > radius:
			_camp_near = false
	if _camp_near:
		_camp_standing_seconds += delta
	else:
		_camp_standing_seconds = 0.0


## Walks the tree for camp sources. Every `scan_every_s`, not every frame:
## the world has thousands of nodes and this needs a handful of them. Skips
## Control/CanvasLayer subtrees (the HUD holds no campfires).
func _scan_camp_sources(cfg: Dictionary) -> Array[Node3D]:
	var out: Array[Node3D] = []
	var root := _root()
	if root == null:
		return out
	var suffixes: Array = cfg.get("script_suffixes", [])
	var stack: Array[Node] = [root]
	var walked := 0
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		walked += 1
		if node is CanvasLayer or node is Control:
			continue
		if node is Node3D:
			if node.is_in_group(CAMP_GROUP):
				out.append(node as Node3D)
				stack.append_array(node.get_children())
				continue
			var script: Variant = node.get_script()
			if script != null:
				var path := str((script as Script).resource_path)
				for suffix in suffixes:
					if path.ends_with(str(suffix)):
						out.append(node as Node3D)
						break
		stack.append_array(node.get_children())
	last_camp_scan_nodes = walked
	return out


## The two continuous states, driven while no reaction is running. Camp beats
## hurt for the pivot: a lying creature reads as resting whatever its HP.
func _drive_continuous(delta: float) -> void:
	var camp_cfg: Dictionary = _cfg.get(CAMP, {})
	var want_camp := _camp_near and _camp_standing_seconds >= float(camp_cfg.get("settle_seconds", 2.0))
	if want_camp != _camp:
		_camp = want_camp
	if _camp:
		_hold_pivot()
		var roll_deg := float(SPECIES.placeholder(str(_body.get("species_id"))).get("rest_roll_deg", 90.0)) \
			* float(camp_cfg.get("roll_fraction", 0.45))
		_apply_pivot({
			"roll": deg_to_rad(roll_deg),
			"y": -float(camp_cfg.get("sink_fraction", 0.05)) * _height(),
			"x": 0.0, "pitch": 0.0, "yaw": 0.0, "scale": 0.0,
		}, true)
		_set_anim_speed(float(camp_cfg.get("anim_speed_scale", 0.5)))
		return
	if _hurt:
		var cfg: Dictionary = _cfg.get(HURT, {})
		_hold_pivot()
		# A small sink and a slight nose-down only: the readable part of this
		# state is the HUNG HEAD (`_update_look` aims the head bone at the
		# ground marker while hurt) and the slower gait, not a tipped body.
		_apply_pivot({
			"pitch": deg_to_rad(float(cfg.get("body_pitch_deg", 3.0))),
			"y": -float(cfg.get("sink_fraction", 0.03)) * _height(),
			"x": 0.0, "yaw": 0.0, "roll": 0.0, "scale": 0.0,
		})
		_set_anim_speed(float(cfg.get("anim_speed_scale", 0.78)))
		if _standing():
			_flinch_timer -= delta
			if _flinch_timer <= 0.0:
				_flinch_timer = _next_flinch()
				_play_clip(str(cfg.get("flinch_clip", "hit")))
		return
	_leave_continuous()


func _leave_continuous() -> void:
	_camp = false
	if _state == "":
		_release_pivot()
	_set_anim_speed(1.0)


## The follower multiplies its walk and run speeds by this.
func gait_scale() -> float:
	if not _hurt:
		return 1.0
	return float((_cfg.get(HURT, {}) as Dictionary).get("gait_scale", 0.72))


# --- pivot / clips / head ---------------------------------------------------

func _height() -> float:
	if _body != null and _body.has_method("body_height"):
		return maxf(float(_body.call("body_height")), 0.3)
	return 1.0


func _radius() -> float:
	if _body != null and _body.has_method("body_radius"):
		return maxf(float(_body.call("body_radius")), 0.1)
	return 0.4


func _pivot() -> Node3D:
	if _body == null or not _body.has_method("model_pivot"):
		return null
	return _body.call("model_pivot") as Node3D


func _hold_pivot() -> void:
	if _pivot_held:
		return
	var pivot := _pivot()
	if pivot == null:
		return
	_pivot_rest = pivot.transform
	_pivot_held = true


func _release_pivot() -> void:
	if not _pivot_held:
		return
	var pivot := _pivot()
	if pivot != null:
		pivot.transform = _pivot_rest
	_pivot_held = false


## Compose offsets over the captured rest transform. Rotations are in the
## pivot's own axes: X pitch (nod / head-low), Y yaw (shake), Z roll (rest).
## A roll re-centres sideways and grounds its own dip the way
## `creature_body.play_rest()` does, scaled by the same fraction.
func _apply_pivot(offsets: Dictionary, rolled: bool = false) -> void:
	var pivot := _pivot()
	if pivot == null or not _pivot_held:
		return
	var roll := float(offsets.get("roll", 0.0))
	# Grounding a roll is `+radius * |sin(roll)|`, NOT `+radius * sin(roll)`.
	# Rolling a body either way dips its lower corner by about a radius, so the
	# correction that puts it back on the ground is a LIFT in both directions.
	# Signed, a negative roll turns the lift into a dip and buries the creature:
	# terrapup's own `rest_roll_deg` is -45, and at 0.85 of it the signed form
	# drops the pivot 0.75m -- most of a 2.3m animal -- which a code-blind
	# critic caught as "the creature is half inside the hillside... a head and
	# a paw lying detached in a meadow". The sideways re-centre above keeps its
	# sign, because which way the body falls is exactly what that term means.
	#
	# `creature_body.gd::play_rest()` carries the same signed form for the bed
	# pose and so has the same latent dip on the two negative-roll species
	# (terrapup, trailpup). That file is outside this lane's ownership and is
	# not touched here; reported for routing instead.
	var position := _pivot_rest.origin + Vector3(
		float(offsets.get("x", 0.0)) + (_height() * 0.5 * sin(roll) if rolled else 0.0),
		float(offsets.get("y", 0.0)) + (_radius() * absf(sin(roll)) if rolled else 0.0),
		0.0)
	var rotation := Basis.from_euler(Vector3(
		float(offsets.get("pitch", 0.0)), float(offsets.get("yaw", 0.0)), roll))
	var swell := 1.0 + float(offsets.get("scale", 0.0))
	pivot.transform = Transform3D(_pivot_rest.basis * rotation * Basis.from_scale(Vector3.ONE * swell), position)


func _play_clip(role: String) -> void:
	if _body == null:
		return
	var animator: Variant = _body.get("_animator")
	if animator != null and (animator as Object).has_method("play_if_exists"):
		(animator as Object).call("play_if_exists", role)


func _resolve_model() -> void:
	if _anim_player != null and is_instance_valid(_anim_player):
		return
	var pivot := _pivot()
	if pivot == null:
		return
	var players: Array[Node] = pivot.find_children("*", "AnimationPlayer", true, false)
	_anim_player = players[0] as AnimationPlayer if not players.is_empty() else null
	_anim_speed_held = false
	_look = null
	_look_skeleton = null


func _set_anim_speed(scale_value: float) -> void:
	if _anim_player == null or not is_instance_valid(_anim_player):
		return
	if is_equal_approx(scale_value, 1.0):
		if _anim_speed_held:
			_anim_player.speed_scale = 1.0
			_anim_speed_held = false
		return
	_anim_player.speed_scale = scale_value
	_anim_speed_held = true


func anim_speed_scale() -> float:
	if _anim_player == null or not is_instance_valid(_anim_player):
		return 1.0
	return _anim_player.speed_scale


## Head toward the trainer while standing near them. Built once per model on
## the rig's `head` bone; `forward_axis` is measured from the bone's rest
## pose against the model's own +Z rather than assumed, because 21 rigs from
## the same pipeline still cannot be trusted to agree.
func _update_look(leader: Node3D) -> void:
	var cfg: Dictionary = _cfg.get("look", {})
	if not bool(cfg.get("enabled", true)) or leader == null:
		_set_look(false)
		return
	if _look == null:
		_build_look(cfg, leader)
	if _look == null:
		return
	var to := _gpos(leader) - _gpos(_body)
	to.y = 0.0
	# A hurt creature hangs its head instead of holding the trainer's eye --
	# and does so whether or not the trainer is near, which is what makes the
	# state readable at a glance from any angle. Camp keeps the greeting: a
	# resting creature that still looks up at you is the warmer read.
	var droop: bool = _hurt and not _camp and _state == ""
	if droop and _droop_target != null:
		_look.target_node = _look.get_path_to(_droop_target)
		_set_look(true)
		return
	_look.target_node = _look.get_path_to(leader)
	_set_look(_standing() and to.length() <= float(cfg.get("radius", 7.0)))


func _build_look(cfg: Dictionary, leader: Node3D) -> void:
	var pivot := _pivot()
	if pivot == null:
		return
	var skeletons: Array[Node] = pivot.find_children("*", "Skeleton3D", true, false)
	if skeletons.is_empty():
		return
	var skeleton := skeletons[0] as Skeleton3D
	var bone := skeleton.find_bone(str(cfg.get("bone", "head")))
	if bone < 0:
		return
	if _droop_target == null:
		var marker := Node3D.new()
		marker.name = "CompanionDroopTarget"
		_body.add_child(marker)
		var hurt_cfg: Dictionary = _cfg.get(HURT, {})
		marker.position = Vector3(
			0.0,
			float(hurt_cfg.get("droop_height_fraction", 0.18)) * _height(),
			float(hurt_cfg.get("droop_forward_radii", 2.2)) * _radius())
		_droop_target = marker
	var look := LookAtModifier3D.new()
	look.name = "CompanionLook"
	skeleton.add_child(look)
	look.bone = bone
	look.target_node = look.get_path_to(leader)
	look.forward_axis = _forward_axis_of(skeleton, bone)
	look.primary_rotation_axis = Vector3.AXIS_Y
	look.use_secondary_rotation = true
	look.use_angle_limitation = true
	look.symmetry_limitation = true
	look.primary_limit_angle = deg_to_rad(float(cfg.get("limit_deg", 55.0)) * 2.0)
	look.secondary_limit_angle = deg_to_rad(60.0)
	look.duration = float(cfg.get("duration_s", 0.35))
	look.influence = float(cfg.get("influence", 0.75))
	look.active = false
	_look = look
	_look_skeleton = skeleton


## Which bone-local axis points the way the creature faces (+Z on the body).
func _forward_axis_of(skeleton: Skeleton3D, bone: int) -> int:
	var rest := skeleton.get_bone_global_rest(bone)
	# The skeleton's basis in BODY space, composed up the local chain so it
	# holds with or without a tree; the body's forward is its own +Z.
	var to_body := Basis.IDENTITY
	var node: Node = skeleton
	while node != null and node != _body:
		if node is Node3D:
			to_body = (node as Node3D).transform.basis * to_body
		node = node.get_parent()
	var world_forward := to_body.inverse() * Vector3.BACK
	var axes := [
		[SkeletonModifier3D.BONE_AXIS_PLUS_X, Vector3.RIGHT], [SkeletonModifier3D.BONE_AXIS_MINUS_X, Vector3.LEFT],
		[SkeletonModifier3D.BONE_AXIS_PLUS_Y, Vector3.UP], [SkeletonModifier3D.BONE_AXIS_MINUS_Y, Vector3.DOWN],
		[SkeletonModifier3D.BONE_AXIS_PLUS_Z, Vector3.BACK], [SkeletonModifier3D.BONE_AXIS_MINUS_Z, Vector3.FORWARD],
	]
	var best: int = SkeletonModifier3D.BONE_AXIS_PLUS_Z
	var best_dot := -INF
	for entry: Array in axes:
		var direction: Vector3 = (rest.basis * (entry[1] as Vector3)).normalized()
		var dot := direction.dot(world_forward.normalized())
		if dot > best_dot:
			best_dot = dot
			best = int(entry[0])
	return best


func _set_look(on: bool) -> void:
	if _look == null or not is_instance_valid(_look):
		return
	if _look.active != on:
		_look.active = on


# --- read-outs for tests, smokes and the report -----------------------------

func state() -> String:
	return _state


func is_hurt() -> bool:
	return _hurt


func is_camped() -> bool:
	return _camp


func is_camp_near() -> bool:
	return _camp_near


func is_looking() -> bool:
	return _look != null and is_instance_valid(_look) and _look.active


func pending() -> Array:
	return _pending.keys()


func cooldown_left(name: String) -> float:
	return float(_cooldowns.get(name, 0.0))


func still_seconds() -> float:
	return _still_seconds


func fired_count(name: String) -> int:
	return int(fired.get(name, 0))


func pivot_is_at_rest() -> bool:
	return not _pivot_held
