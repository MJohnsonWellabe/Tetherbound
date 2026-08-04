extends Node

## Combat Mode: a STATE, not a scene.
##
## The world keeps rendering, the trainer stays standing where they engaged, the
## terrain stays loaded. Nothing is unloaded and nothing is instanced from a
## separate arena scene. That is a stated requirement (TECHNICAL_START.md,
## "Combat Mode should be a state transition, not a separate unrelated game"),
## and it is also what keeps the transition free of a loading pause.
##
## Combat is PILOTED (docs/decisions/D07): the player takes over their pal,
## both fighters move inside a bounded arena, and attacks are aimed and can
## miss. There is no dodge button — movement is the dodge.
##
## This is the single place that knows a fight is happening. Everything else —
## the player controller, the camera rig, the HUD — is told, and does not ask.
##
## M2 scope: one wild pal, one of yours, quick and charged attacks, and three
## ways out. No catching, no party, no types, no switching UI.
##
## M4 was supposed to grow that into a party and a Switch command. It half did:
## the party arrived, and this file kept `_active_index` into a private
## `Array[RefCounted]` that the director filled with exactly one pal and that
## nothing ever moved. Two indices for one fact, one of them frozen at zero.
##
## The array is gone. This holds the PARTY ITSELF and addresses the fighter
## through `party.active()`, so `set_active()` from the menu and `Switchboard`
## below are the same move on the same number, and the menu and the fight cannot
## come apart.

const MATH := preload("res://scripts/combat/combat_math.gd")
const ARENA := preload("res://scripts/combat/combat_arena.gd")
const CATCH := preload("res://scripts/combat/catch_math.gd")
const THROW_AIM := preload("res://scripts/combat/throw_aim.gd")
const SPECIES := preload("res://scripts/pals/pal_species.gd")
const FLASH := preload("res://scripts/combat/impact_flash.gd")

signal entered()
signal exited(outcome: String)
signal state_changed()
signal hit_landed(on_enemy: bool, amount: float)
signal attack_missed(by_player: bool)
## A throw finished resolving. `shakes` is how many times the orb wobbled, and
## comes from the single decision made when it landed — it is never re-rolled.
signal catch_resolved(success: bool, shakes: int)
signal catch_refused(reason: String)
signal orb_shook(index: int)

## The deployed pal changed mid-fight. `index` is the party slot, and it is the
## party's own `active_index` — not a copy of it.
signal switched(index: int, pal: RefCounted)
## A switch was asked for and refused, with one of Switchboard's tokens. Emitted
## rather than swallowed because "nothing happened" and "you cannot do that yet"
## are different things to have just pressed a button for.
signal switch_refused(token: String)

enum State { INACTIVE, ACTIVE, RESOLVING }

## Why a fight ended. "caught" is new in M3 and is deliberately distinct from
## "won": beating a creature and keeping one are different outcomes and the
## world needs to treat them differently.
const OUTCOME_CAUGHT := "caught"

## What the player's pal is doing. Wind-up and recovery are ROOTED: committing
## to an attack costs you your mobility, which is the whole reason a charged
## attack is a decision rather than a better button.
enum Action { READY, WINDUP, RECOVERY }


## The Switch command — GAME_DESIGN.md §14's fifth, beside Quick, Charged, Throw
## and Run — as an object rather than as three loose fields on the manager.
##
## Everything a switch decides is decidable from the party and a clock: who is
## eligible, whether the cooldown has run down, and which slot to land on. None
## of it needs an arena, a camera, a body or a scene, so none of it lives in the
## fight. That is what lets tests/test_combat_rewards.gd prove the RULES
## headlessly, per docs/decisions/D02, while the manager above adds only the
## presentation — the body's species, the entry lag, the signals.
##
## It MOVES THE PARTY rather than keeping an index of its own. That is the whole
## repair: `party.active_index` is the single fact, the menu writes it through
## `set_active()`, this writes it through `set_active()`, and there is no second
## copy left to disagree with.
class Switchboard extends RefCounted:
	## Refusal tokens, in party.gd's idiom: a stable token and never a sentence,
	## because the HUD has to be able to shorten, lengthen or translate it.
	const REFUSED_NO_PARTY := "no_party"
	const REFUSED_ALONE := "alone"
	const REFUSED_COOLING := "cooling_down"
	const REFUSED_ALL_DOWN := "all_down"

	## Seconds between switches. §14 requires a cooldown and names no number; the
	## one that ships is `switch.cooldown` in data/config/combat.json and is
	## TUNABLE. This default exists only so a missing config block cannot make
	## switching free.
	var period: float = 4.0
	var remaining: float = 0.0

	func configure(cfg: Dictionary) -> void:
		period = maxf(0.0, float(cfg.get("cooldown", 4.0)))
		remaining = 0.0

	func tick(delta: float) -> void:
		remaining = maxf(0.0, remaining - delta)

	func ready() -> bool:
		return remaining <= 0.0

	func seconds_left() -> float:
		return remaining

	## The slot a switch of `step` would land on, or -1 if there is nobody to
	## switch to.
	##
	## Fainted members are stepped OVER rather than landed on. §16 makes a
	## fainted pal unavailable, and a switch that deploys an unconscious creature
	## is a switch that loses the fight for you — so with two pals and one of them
	## down, this is a refusal rather than a very bad move.
	func target(party: Object, step: int) -> int:
		if party == null:
			return -1
		var count := int(party.call("size"))
		if count <= 1:
			return -1
		var from := int(party.get("active_index"))
		var direction := 1 if step >= 0 else -1
		for i in range(1, count):
			var index: int = posmod(from + direction * i, count)
			var pal: RefCounted = party.call("at", index) as RefCounted
			if pal != null and not bool(pal.get("fainted")):
				return index
		return -1

	## Why a switch would be refused right now, or "" if it would go through.
	func refusal(party: Object, step: int) -> String:
		if party == null:
			return REFUSED_NO_PARTY
		if int(party.call("size")) <= 1:
			# One pal is not a roster. Refusing here rather than letting the wrap
			# land back on the same creature is the difference between "you cannot
			# do that" and a button that appears to work and changes nothing.
			return REFUSED_ALONE
		if not ready():
			return REFUSED_COOLING
		if target(party, step) < 0:
			return REFUSED_ALL_DOWN
		return ""

	## Move the party's deployed pal one step. Returns the new slot, or -1 if the
	## switch was refused.
	##
	## The party's own `set_active()` is what moves. Nothing here caches the
	## result, so there is no way for the fight to believe one thing and the menu
	## another.
	func switch(party: Object, step: int) -> int:
		if not refusal(party, step).is_empty():
			return -1
		var index := target(party, step)
		if not bool(party.call("set_active", index)):
			return -1
		remaining = period
		return index

var state: State = State.INACTIVE

## The player's pals — the party object itself, duck-typed so either
## `scripts/pals/party.gd` or the `PartyManager` node wrapping it will do. There
## is no index here on purpose: `party.active_index` is the only one.
var _party: Object = null
var _enemy: RefCounted = null

var _player: Node3D = null
var _wild: Node3D = null
var _ally_body: Node3D = null
var _camera_rig: Node = null
var _arena: Node3D = null

var _action: Action = Action.READY
var _action_timer: float = 0.0
var _pending_move: Dictionary = {}
var _quick_cooldown: float = 0.0
var _charged_cooldown: float = 0.0

var _resolve_timer: float = 0.0
var _outcome: String = ""

## The Switch command's rules and its cooldown clock.
var _switchboard := Switchboard.new()

## Seconds after the fight opens during which player input is ignored.
##
## Engage and charged attack are the same physical button (X / interact and
## combat_charged), and `is_action_just_pressed` stays true for the whole frame.
## Without this, the press that starts the fight is also read as the first
## attack of it.
var _input_guard: float = 0.0

## Catching. The aim and the projectile live in throw_aim.gd; what lives here is
## deciding whether a throw is allowed and what its result means to the fight.
var _throw: Node = null
var _catch_shakes_left: int = 0
var _catch_shake_timer: float = 0.0
var _catch_succeeded: bool = false
var _catch_index: int = 0

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	set_physics_process(false)

	_throw = THROW_AIM.new()
	_throw.name = "ThrowAim"
	add_child(_throw)
	_throw.connect("orb_struck", _on_orb_struck)
	_throw.connect("orb_missed", _on_orb_missed)
	_throw.connect("throw_refused", func(reason: String) -> void: catch_refused.emit(reason))


func throw_aim() -> Node:
	return _throw


## Whoever the party currently has deployed. Asked every time rather than cached:
## a cached copy is exactly how the M4 build ended up fighting with a pal the
## party menu had already replaced.
func active_pal() -> RefCounted:
	return (_party.call("active") as RefCounted) if _party != null else null


func enemy() -> RefCounted:
	return _enemy


func is_fighting() -> bool:
	return state != State.INACTIVE


func arena() -> Node3D:
	return _arena


## Begin a fight. `ally_body` is the body the player's pal is drawn on,
## `camera_rig` is the exploration camera that will be re-pointed at it.
##
## `party` is the PARTY, not a list of fighters. It used to be an
## `Array[RefCounted]` and the director passed `[cached_pal]` — a one-element
## array built at world load — so the fight opened with whoever had been deployed
## when the scene started, forever. Taking the party itself means the fight reads
## the deployment at the moment it opens, which is what §10 ("player chooses which
## pal to deploy when combat begins") actually says.
func begin(player: Node3D, wild: Node3D, ally_body: Node3D, party: Object, camera_rig: Node = null) -> bool:
	if is_fighting():
		return false
	if player == null or wild == null or ally_body == null:
		push_error("cannot begin combat without a player, a wild pal and a deployed body")
		return false
	if party == null or not party.has_method("active") or int(party.call("size")) == 0:
		push_error("cannot begin combat without a party to deploy from")
		return false

	_player = player
	_wild = wild
	_ally_body = ally_body
	_camera_rig = camera_rig
	_party = party
	_enemy = wild.get("instance")
	if _enemy == null:
		push_error("wild pal has no instance")
		return false

	var pal := active_pal()
	if pal == null or pal.fainted:
		return false
	# The body is built from whoever is deployed RIGHT NOW. Doing this once at
	# world load is how a party that says one creature is out produces a fight
	# that shows a different one.
	_deploy_body(pal)
	_switchboard.configure(MATH.config().get("switch", {}))

	_action = Action.READY
	_action_timer = 0.0
	_pending_move = {}
	_quick_cooldown = 0.0
	_charged_cooldown = 0.0
	_resolve_timer = 0.0
	_outcome = ""
	_input_guard = float(MATH.config().get("flow", {}).get("input_guard", 0.25))

	_catch_shakes_left = 0
	_catch_shake_timer = 0.0

	_open_arena()
	_place_fighters()
	_throw.call("arm", _player, _wild, _camera_rig)

	if not _wild.is_connected("strike_ready", _on_enemy_strike):
		_wild.connect("strike_ready", _on_enemy_strike)
	_wild.call("set_engaged", true, _ally_body)
	_wild.set("arena", _arena)
	_ally_body.set("arena", _arena)

	_take_camera()

	state = State.ACTIVE
	set_physics_process(true)
	entered.emit()
	state_changed.emit()
	return true


## --- setup ----------------------------------------------------------------

## Put the deployed pal's species onto the body the player drives.
##
## ONE body for the whole fight — the same collider, the same position, the same
## node the opponent is targeting — and only its species changes. Instancing a
## second body per switch would hitch in the one frame that most needs not to,
## and would hand the enemy a target that had moved, which is the free dodge this
## file is careful not to sell.
##
## Skipped when the species is already right, so re-deploying the same creature
## does not rebuild its art.
func _deploy_body(pal: RefCounted) -> void:
	if _ally_body == null or pal == null:
		return
	if str(_ally_body.get("species_id")) == pal.species_id:
		return
	_ally_body.call("setup", pal.species_id)


## The arena is centred between the two fighters, not on the trainer. Centring
## it on the trainer would put them at the middle of a circle they are supposed
## to be standing at the edge of, watching.
func _open_arena() -> void:
	var cfg: Dictionary = MATH.config().get("arena", {})
	_arena = ARENA.new()
	_arena.name = "CombatArena"
	_player.get_parent().add_child(_arena)
	_arena.call("configure", _midpoint(cfg), cfg)


func _midpoint(cfg: Dictionary) -> Vector3:
	var forward := _forward_axis()
	var deploy := float(cfg.get("deploy_offset", 2.6))
	var separation := float(cfg.get("separation", 5.0))
	return _player.global_position + forward * (deploy + separation * 0.5)


func _forward_axis() -> Vector3:
	var forward := _wild.global_position - _player.global_position
	forward.y = 0.0
	if forward.length() < 0.01:
		forward = -_player.global_transform.basis.z
		forward.y = 0.0
	return Vector3.FORWARD if forward.length() < 0.01 else forward.normalized()


## Arrange the two fighters facing each other, along the line the player was
## already looking down when they engaged.
##
## The trainer is not moved and is never targeted. The fight forms in front of
## them, so the arena appears where the player was standing rather than the
## player being teleported into an arena. That is the whole difference between
## "a state" and "a separate scene".
func _place_fighters() -> void:
	var cfg: Dictionary = MATH.config().get("arena", {})
	var forward := _forward_axis()
	var ally_spot := _player.global_position + forward * float(cfg.get("deploy_offset", 2.6))
	var wild_spot := ally_spot + forward * float(cfg.get("separation", 5.0))

	_ally_body.visible = true
	_place(_ally_body, ally_spot)
	_ally_body.call("face_towards", wild_spot)
	_place(_wild, wild_spot)
	_wild.call("face_towards", ally_spot)
	_stand_the_trainer_aside(forward)


## The trainer steps to the side of the arena as their pal deploys.
##
## They stay in the fight, in frame, and untargetable — but not in the LANE. The
## camera follows the player's pal from behind, and the trainer engaged from
## directly behind that pal, so leaving them where they stood put a 1.8m body
## between the camera and the entire fight for the opening seconds of every
## single encounter. It filled the frame.
##
## This is a small, one-off move at the moment the fight opens, not a system
## that puppets them around afterwards.
func _stand_the_trainer_aside(forward: Vector3) -> void:
	if _arena == null:
		return
	var side := forward.cross(Vector3.UP).normalized()
	var centre: Vector3 = _arena.global_position
	# Well inside the boundary rather than on it. The aim camera sits several
	# metres behind the trainer, and standing them at the very edge put that
	# camera outside the arena looking in through the wall.
	var spot := centre + side * (float(_arena.get("radius")) * 0.55) - forward * 1.2
	_player.global_position = spot
	_player.velocity = Vector3.ZERO

	# Turn them to watch. The controller owns the model's yaw during
	# exploration, and locomotion is suspended, so writing it here is safe.
	var model: Node3D = _player.get_node_or_null(^"Model") as Node3D
	if model != null:
		var to := centre - spot
		to.y = 0.0
		if to.length() > 0.01:
			model.rotation.y = atan2(to.x, to.z)


func _place(body: Node3D, spot: Vector3) -> void:
	if not bool(body.call("place_on_ground", spot)):
		body.global_position = spot


## Point the exploration camera at the pal instead of the trainer.
##
## Reusing the orbit rig rather than adding a combat camera: a piloted pal wants
## exactly the third-person camera M1 already tuned, at a shorter creature's
## height. A second camera would be a second thing to keep in sync, and the rig
## already eases onto a new target for free.
func _take_camera() -> void:
	if _camera_rig == null or not _camera_rig.has_method("set_target"):
		return
	_camera_rig.call("set_target", _ally_body, MATH.config().get("camera", {}))


func _release_camera() -> void:
	if _camera_rig == null or not _camera_rig.has_method("set_target"):
		return
	_camera_rig.call("set_target", _player, {})


## --- the loop -------------------------------------------------------------

func _physics_process(delta: float) -> void:
	match state:
		State.ACTIVE:
			_tick_active(delta)
		State.RESOLVING:
			_resolve_timer -= delta
			if _resolve_timer <= 0.0:
				_finish()
		_:
			pass


func _tick_active(delta: float) -> void:
	_quick_cooldown = maxf(0.0, _quick_cooldown - delta)
	_charged_cooldown = maxf(0.0, _charged_cooldown - delta)
	_input_guard = maxf(0.0, _input_guard - delta)
	_switchboard.tick(delta)

	if _catch_shakes_left > 0:
		_tick_catch_wobble(delta)
		return

	_tick_action(delta)
	_drive_player_pal()
	if _input_guard <= 0.0:
		_read_player_input()


## Wind-up, strike, recovery. The strike resolves at the END of the wind-up, and
## the recovery that follows is time the player cannot move — which is what the
## opponent is meant to punish.
func _tick_action(delta: float) -> void:
	if _action == Action.READY:
		return
	_action_timer -= delta
	if _action_timer > 0.0:
		return

	if _action == Action.WINDUP:
		_resolve_player_strike()
		_action = Action.RECOVERY
		_action_timer = float(_pending_move.get("recovery", 0.2))
		state_changed.emit()
		return

	_action = Action.READY
	_pending_move = {}
	state_changed.emit()


func _resolve_player_strike() -> void:
	var pal := active_pal()
	if pal == null or _enemy == null or _ally_body == null or _wild == null:
		return

	var origin: Vector3 = _ally_body.call("centre")
	var facing: Vector3 = _ally_body.call("facing")
	var target: Vector3 = _wild.call("centre")

	_ally_body.call("add_impulse", facing, float(_pending_move.get("lunge", 3.6)))
	_ally_body.call("play_attack")

	if not MATH.move_connects(_pending_move, origin, facing, target):
		attack_missed.emit(true)
		state_changed.emit()
		return

	var damage: float = MATH.rolled_damage(
		float(_pending_move.get("power", 9.0)), pal.attack, _enemy.defence, _rng.randf()
	)
	var killed: bool = _enemy.take_damage(damage)
	_wild.call("add_impulse", facing, float(_pending_move.get("lunge", 3.6)) * 0.4)
	_wild.call("play_faint" if killed else "play_hit")
	_flash_at(_wild.call("centre"), not bool(_pending_move.get("is_quick", false)))

	# Energy is earned by CONNECTING, not by pressing. That is what makes
	# positioning matter to the charged attack rather than only to survival.
	if bool(_pending_move.get("is_quick", false)):
		pal.gain_energy_from_quick()

	hit_landed.emit(true, damage)
	state_changed.emit()
	if killed:
		_begin_resolve("won")


## Movement is the dodge. The pal is driven straight from the stick, in camera
## space, exactly like the trainer — and is rooted while attacking.
func _drive_player_pal() -> void:
	if _ally_body == null:
		return
	if _action != Action.READY:
		return
	# Aiming abandons your pal. It stops taking stick input while you line up the
	# throw and the opponent does not stop attacking it — that is the entire cost
	# of catching, and without it throwing is free and the correct play is to
	# throw constantly between attacks.
	if bool(_throw.call("is_aiming")):
		return

	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if input == Vector2.ZERO:
		return
	var basis_value := Basis.IDENTITY
	if _camera_rig != null and _camera_rig.has_method("planar_basis"):
		basis_value = _camera_rig.call("planar_basis")
	_ally_body.call("request_move", basis_value * Vector3(input.x, 0.0, input.y))


func _read_player_input() -> void:
	var pal := active_pal()
	if pal == null:
		return

	# While aiming, throw_aim.gd owns the input: Run cancels the aim rather than
	# ending the fight, and the attack buttons release the orb. Reading them here
	# too would make one press do two things.
	if bool(_throw.call("is_busy")):
		return

	if Input.is_action_just_pressed("combat_run"):
		_begin_resolve("fled")
		return

	if _action != Action.READY:
		return

	# Below this line the pal is uncommitted. Switching sits here rather than
	# beside Run on purpose: swapping out of your own recovery would cancel the
	# punish window the opponent just earned, which is the free dodge D08 refused
	# to sell for throwing.
	if Input.is_action_just_pressed("combat_switch_right"):
		switch_active(1)
		return
	if Input.is_action_just_pressed("combat_switch_left"):
		switch_active(-1)
		return

	if Input.is_action_just_pressed("combat_throw"):
		_try_throw()
		return

	if Input.is_action_just_pressed("combat_charged") and _charged_cooldown <= 0.0:
		if pal.spend_charged():
			var charged: Dictionary = MATH.config().get("player_charged", {}).duplicate()
			charged["is_quick"] = false
			_start_action(charged)
			_charged_cooldown = float(charged.get("cooldown", 1.2))
		return

	if Input.is_action_just_pressed("combat_quick") and _quick_cooldown <= 0.0:
		var quick: Dictionary = MATH.config().get("player_quick", {}).duplicate()
		quick["is_quick"] = true
		_start_action(quick)
		_quick_cooldown = float(quick.get("cooldown", 0.45))


func _start_action(move: Dictionary) -> void:
	_pending_move = _with_reach_for_the_bodies(move)
	_action = Action.WINDUP
	_action_timer = float(move.get("windup", 0.18))
	state_changed.emit()


## Floor a move's reach by the two creatures' actual sizes.
##
## Reach is measured centre to centre, and the configured 2.6m was written when
## every creature was the same capsule. Against a large opponent, two bodies
## that are merely touching are already further apart than that, so the player's
## attack whiffs at point-blank range — which reads as the game dropping the
## input, and is the single complaint most likely to end a playtest.
##
## The wild pal applies the same floor to its own attacks. Both sides space
## themselves by their bodies; both sides reach as far as they have spaced.
func _with_reach_for_the_bodies(move: Dictionary) -> Dictionary:
	if _ally_body == null or _wild == null:
		return move
	var mine := 0.5
	var theirs := 0.5
	if _ally_body.has_method("body_radius"):
		mine = float(_ally_body.call("body_radius"))
	if _wild.has_method("body_radius"):
		theirs = float(_wild.call("body_radius"))

	var clearance: float = float(MATH.config().get("enemy", {}).get("body_clearance", 1.35))
	var adjusted := move.duplicate()
	adjusted["range"] = maxf(float(move.get("range", 2.6)), (mine + theirs) * clearance + 0.5)
	return adjusted


## The opponent announces its swing when its wind-up completes; whether it
## connects is decided here, by the same arithmetic the player's attacks use.
func _on_enemy_strike() -> void:
	if state != State.ACTIVE:
		return
	var pal := active_pal()
	if pal == null or _enemy == null:
		return

	# The creature's OWN numbers, not the raw config: it spaces itself by how big
	# the two bodies are, and its reach grows with that spacing. Testing the
	# swing against the config's flat 2.6m while it stands further out than that
	# is a creature that walks to exactly where it can no longer hit anything.
	var cfg: Dictionary = _wild.call("combat_config") if _wild.has_method("combat_config") \
		else MATH.config().get("enemy", {})
	var origin: Vector3 = _wild.call("centre")
	var facing: Vector3 = _wild.call("facing")
	var target: Vector3 = _ally_body.call("centre")

	_wild.call("add_impulse", facing, float(cfg.get("lunge", 3.4)))
	_wild.call("play_attack")

	if not MATH.move_connects(cfg, origin, facing, target):
		attack_missed.emit(false)
		state_changed.emit()
		return

	var damage: float = MATH.rolled_damage(
		float(cfg.get("power", 8.0)), _enemy.attack, pal.defence, _rng.randf()
	)
	var killed: bool = pal.take_damage(damage)
	_ally_body.call("add_impulse", facing, float(cfg.get("lunge", 3.4)) * 0.4)
	_ally_body.call("play_faint" if killed else "play_hit")
	_flash_at(_ally_body.call("centre"), false)

	hit_landed.emit(false, damage)
	state_changed.emit()
	if killed:
		_begin_resolve("lost")


## A blow that landed has to look like one.
##
## The blind critic counted bright warm pixels at the moment of contact:
## `combat/05-quick-attack-lands` held ten of them, `palworld-01` held 24,623,
## and its summary of the beat was that the health bar got shorter and nothing
## else happened. Damage numbers are state; this is the event.
##
## Charged hits burst larger and warmer than quick ones. If the expensive move
## and the free one look the same, building energy was never worth doing.
func _flash_at(where: Vector3, charged: bool) -> void:
	var cfg: Dictionary = MATH.config().get("impact", {})
	if not bool(cfg.get("enabled", true)):
		return
	var key := "charged" if charged else "quick"
	var spec: Dictionary = cfg.get(key, {})
	# Parented into the WORLD, not to this manager. CombatManager is a plain
	# Node, and a Node3D hung under one is outside the 3D transform chain: the
	# burst was created correctly twelve times in a row and rendered none of
	# them. The arena is a Node3D that already exists for exactly the length of
	# the fight, so it also cleans these up on its way out.
	var host: Node = _arena if _arena != null else _player.get_parent()
	FLASH.burst(
		host,
		where,
		Color(str(spec.get("colour", "#ffd27a"))),
		float(spec.get("radius", 1.5)),
		float(spec.get("duration", 0.34)),
		float(spec.get("strength", 1.0))
	)


## --- switching ------------------------------------------------------------

## Swap the deployed pal mid-fight. `step` is +1 for the next member and -1 for
## the previous; fainted members are skipped.
##
## This is the whole of GAME_DESIGN.md §14's Switch command, and it is
## deliberately NOT an escape:
##
##  * The body does not move. Whoever arrives inherits the position, the
##    spacing and the opponent's attention.
##  * The opponent's clocks are untouched. Its wind-up keeps winding up and
##    `_on_enemy_strike` resolves against `active_pal()` — so a switch made into
##    a telegraph means the NEWCOMER eats the blow.
##  * The arriving pal cannot attack for `switch.entry_lag` seconds, and the
##    cooldown means it cannot be undone on the next frame.
##
## D08 settled the same argument for throwing: the cost is what turns a button
## into a decision.
func switch_active(step: int) -> bool:
	var reason := _switchboard.refusal(_party, step)
	if not reason.is_empty():
		switch_refused.emit(reason)
		return false

	var index := _switchboard.switch(_party, step)
	if index < 0:
		# The party refused a slot the rules had already cleared. Nothing should
		# be able to reach here; if it does, the fight must not silently continue
		# believing a switch happened.
		switch_refused.emit(Switchboard.REFUSED_NO_PARTY)
		return false

	var pal := active_pal()
	_deploy_body(pal)

	var lag := float(MATH.config().get("switch", {}).get("entry_lag", 0.6))
	# Floored rather than overwritten: switching must not be a way to wipe an
	# attack cooldown you were waiting out.
	_quick_cooldown = maxf(_quick_cooldown, lag)
	_charged_cooldown = maxf(_charged_cooldown, lag)

	switched.emit(index, pal)
	state_changed.emit()
	return true


## --- catching -------------------------------------------------------------

## Legality is checked before the aim opens, not after the orb lands.
##
## §15 says a faint ENDS the capture opportunity. That is a refusal, not a very
## low chance, and telling the player before they spend an orb and a vulnerable
## second of aiming is the difference between a rule and a punishment.
func _try_throw() -> void:
	if _enemy == null:
		return
	var allowed: bool = CATCH.can_be_caught(_enemy.fainted, false)
	_throw.call("try_begin_aim", allowed, "%s is out cold — too late to catch it" % _enemy.display_name)
	state_changed.emit()


func _on_orb_struck(_target: Node3D, offset: float) -> void:
	if state != State.ACTIVE or _enemy == null:
		return

	# Re-checked at the moment of impact as well as before the aim: the opponent
	# can faint to your pal's attack while the orb is still in the air, and an
	# orb that lands on a corpse must not catch it.
	if not CATCH.can_be_caught(_enemy.fainted, false):
		catch_refused.emit("%s fainted before the orb landed" % _enemy.display_name)
		_throw.call("clear_orb")
		state_changed.emit()
		return

	var radius := 0.5
	if _wild != null and _wild.has_method("body_radius"):
		radius = float(_wild.call("body_radius"))

	# The decision, made once. Everything after this dramatises it.
	var decision: Dictionary = CATCH.resolve(
		SPECIES.catch_rate(_enemy.species_id),
		_enemy.hp_fraction(),
		"basic",
		offset,
		radius,
		_rng.randf()
	)
	_catch_succeeded = bool(decision["caught"])
	_catch_shakes_left = int(decision["shakes"])
	_catch_index = 0
	_catch_shake_timer = 0.0

	# The creature goes into the orb for the duration either way. Watching it
	# stand there unbothered while the orb wobbles beside it would tell the
	# player the throw had already failed.
	if _wild != null:
		_wild.visible = false
	state_changed.emit()


func _on_orb_missed() -> void:
	if state != State.ACTIVE:
		return
	# A clean miss is not a failed catch. It costs an orb and the moment, and it
	# gets its own message, because "you missed" and "it broke out" are different
	# things to have just done.
	catch_refused.emit("the orb went wide")
	state_changed.emit()


func _tick_catch_wobble(delta: float) -> void:
	var cfg: Dictionary = CATCH.config().get("resolve", {})
	_catch_shake_timer -= delta
	if _catch_shake_timer > 0.0:
		return

	if _catch_index < _catch_shakes_left:
		_catch_index += 1
		orb_shook.emit(_catch_index)
		_catch_shake_timer = float(cfg.get("shake_interval", 0.55))
		return

	_catch_shakes_left = 0
	_finish_catch(float(cfg.get("settle_pause", 0.6)))


func _finish_catch(_settle: float) -> void:
	_throw.call("clear_orb")
	catch_resolved.emit(_catch_succeeded, _catch_index)

	if _catch_succeeded:
		_begin_resolve(OUTCOME_CAUGHT)
		return

	# It broke out. Back on its feet, back in the fight, no free damage either
	# way — the cost of a failed catch is the orb and the seconds you spent
	# standing still, which is quite enough.
	if _wild != null:
		_wild.visible = true
	state_changed.emit()


## The instance the player just caught, for the director to keep. Valid only
## between `catch_resolved(true, ...)` and the end of the fight.
func caught_instance() -> RefCounted:
	return _enemy if _outcome == OUTCOME_CAUGHT else null


## --- resolution -----------------------------------------------------------

func _begin_resolve(outcome: String) -> void:
	if state == State.RESOLVING:
		return
	_outcome = outcome
	state = State.RESOLVING
	var flow: Dictionary = MATH.config().get("flow", {})
	_resolve_timer = float(flow.get("run_delay", 0.5)) if outcome == "fled" \
		else float(flow.get("faint_pause", 1.6))
	if _wild != null:
		_wild.call("set_engaged", false)
	state_changed.emit()


func _finish() -> void:
	state = State.INACTIVE
	set_physics_process(false)

	_throw.call("disarm")
	if _ally_body != null:
		_ally_body.visible = false
		_ally_body.set("arena", null)
	if _arena != null:
		_arena.queue_free()
		_arena = null
	_release_camera()

	exited.emit(_outcome)
	state_changed.emit()


## --- readouts for the HUD -------------------------------------------------
##
## The HUD asks; it is never pushed to. A HUD that keeps its own copy of the
## fight can disagree with the fight, and the first time that happens it costs
## an afternoon.

func quick_ready() -> bool:
	return _action == Action.READY and _quick_cooldown <= 0.0


func charged_ready() -> bool:
	var pal := active_pal()
	return pal != null and pal.can_use_charged() \
		and _action == Action.READY and _charged_cooldown <= 0.0


## Whether pressing Switch right now would do anything, and how long until it
## would. §14 lists Switch beside Quick, Charged, Throw and Run, so the verb row
## has to be able to grey it out and count it down the way it does the others —
## and scripts/ui is not allowed to reach into `_switchboard` to find out.
func switch_ready() -> bool:
	return state == State.ACTIVE and _switchboard.refusal(_party, 1).is_empty()


func switch_cooldown_left() -> float:
	return _switchboard.seconds_left()


## True while the player's pal is committed and cannot move.
func player_is_committed() -> bool:
	return _action != Action.READY


## True while the enemy's wind-up is visible and its blow has not landed. This
## is the fight's only warning, and it is now something the player can act on by
## moving out of the way.
func enemy_is_winding_up() -> bool:
	return _wild != null and bool(_wild.call("is_winding_up"))


## True while the enemy is rooted — winding up or recovering. The recovery half
## is the player's punish window.
func enemy_is_rooted() -> bool:
	return _wild != null and bool(_wild.call("is_rooted"))


func outcome() -> String:
	return _outcome


func is_aiming() -> bool:
	return _throw != null and bool(_throw.call("is_aiming"))


func orbs_left() -> int:
	return int(_throw.get("stock")) if _throw != null else 0


## True while an orb is wobbling. The fight is paused around it: neither fighter
## acts, because a creature landing a hit on an orb that is deciding whether it
## caught something is nonsense.
func is_resolving_catch() -> bool:
	return _catch_shakes_left > 0


## Where the two fighters are, for anything that needs to frame them.
func arena_focus() -> Vector3:
	if _ally_body != null and _wild != null:
		return (_ally_body.global_position + _wild.global_position) * 0.5
	if _player != null:
		return _player.global_position
	return Vector3.ZERO
