extends Node
const BOND_MILESTONES := preload("res://scripts/creatures/bond_milestones.gd")

## Combat Mode: a STATE, not a scene.
##
## The world keeps rendering, the trainer stays standing where they engaged, the
## terrain stays loaded. Nothing is unloaded and nothing is instanced from a
## separate arena scene. That is a stated requirement (TECHNICAL_START.md,
## "Combat Mode should be a state transition, not a separate unrelated game"),
## and it is also what keeps the transition free of a loading pause.
##
## Combat is PILOTED (docs/decisions/D07): the player takes over their creature,
## both fighters move inside a bounded arena, and attacks are aimed and can
## miss. There is no dodge button — movement is the dodge.
##
## This is the single place that knows a fight is happening. Everything else —
## the player controller, the camera rig, the HUD — is told, and does not ask.
##
## M2 scope: one wild creature, one of yours, quick and charged attacks, and three
## ways out. No catching, no party, no types, no switching UI. The switch SEAM
## is here (`_active_index` into `_party`) so M4 adds members rather than
## restructuring this file.

const MATH := preload("res://scripts/combat/combat_math.gd")
const ARENA := preload("res://scripts/combat/combat_arena.gd")
const OCCLUSION_FADE := preload("res://scripts/combat/ally_occlusion_fade.gd")
const CATCH := preload("res://scripts/combat/catch_math.gd")
const THROW_AIM := preload("res://scripts/combat/throw_aim.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const FLASH := preload("res://scripts/combat/impact_flash.gd")
## W09-VFX (CL-A2): the hit spark, body flash, KO puff, catch sparkle and
## level-up flourish. One door; see scripts/vfx/combat_vfx.gd.
const VFX := preload("res://scripts/vfx/combat_vfx.gd")
const TELEGRAPH_GLOW := preload("res://scripts/combat/telegraph_glow.gd")
const TARGET_MARKER := preload("res://scripts/combat/target_marker.gd")
## A ranged move's visible travel. Presentation only -- the hit is still
## decided instantly by the cone test (see its own header).
const PROJECTILE := preload("res://scripts/combat/move_projectile.gd")
## D30: XP/bond arithmetic and named-move power, both pure data readers with
## no scene-tree dependency — see their own file headers.
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const BUILT_FLOOR := preload("res://scripts/world/built_floor.gd")
## RG19-spec/D68. Winning together and being knocked out both move a
## creature's mood; the numbers are creature_condition.json's, not this
## file's.
const CONDITION := preload("res://scripts/creatures/creature_condition.gd")
const MOVE_DB := preload("res://scripts/creatures/move_db.gd")
## T3-TYPECHART. Type effectiveness, keyed on the ATTACKING MOVE's type against
## the DEFENDING CREATURE's species type — see its own header for why that
## keying rather than species-against-species. Pure config reader, no scene
## tree, same shape as PROGRESSION above.
const TYPE_CHART := preload("res://scripts/combat/type_chart.gd")
const RENDER_BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const CAPTURE_CODEC := preload("res://scripts/save/water_capture_codec.gd")

signal entered()
signal exited(outcome: String)
signal state_changed()
signal hit_landed(on_enemy: bool, amount: float)
signal staggered(on_enemy: bool)
## T3-TYPECHART. The type verdict for the hit `hit_landed` is about to report:
## 1 advantaged, -1 disadvantaged, 0 neutral. Emitted IMMEDIATELY BEFORE
## `hit_landed` for the same hit, and only for hits that actually landed.
##
## A SEPARATE SIGNAL rather than a third parameter on `hit_landed` on purpose.
## Nine callables across tests and tools (`smoke_gate_e_finale`, `smoke_boss`,
## `smoke_combat`, `_probe_combat_hit_rate`, `_capture_combat_moments`,
## `survey_combat`) connect two-argument handlers to that signal, and Godot
## errors when a signal emits more arguments than a connected callable accepts.
## Widening it would have broken six files to save one connection, and none of
## them wants this value.
##
## `effectiveness` is `type_chart.gd::classify` over the multiplier that was
## ACTUALLY APPLIED to the damage, not a second lookup — so what the player is
## told can never disagree with what the fight did.
signal hit_effectiveness(on_enemy: bool, effectiveness: int)
signal attack_missed(by_player: bool)
## A throw finished resolving. `shakes` is how many times the orb wobbled, and
## comes from the single decision made when it landed — it is never re-rolled.
signal catch_resolved(success: bool, shakes: int)
signal catch_refused(reason: String)
signal orb_shook(index: int)
## D32: a voluntary mid-combat switch just completed. `index` is the new
## `_active_index`. Distinct from `state_changed` (still emitted alongside it)
## so the HUD can react to "who is out" without diffing the whole state.
signal creature_switched(index: int)
## Stage B lane 4.C. The host refused something this player asked for, with the
## machine tag and the one player-facing sentence `world_ledger.gd`'s verdict
## shape carries. Separate from `catch_refused` (which predates it and has six
## existing listeners that take one argument) so no existing connection breaks.
signal encounter_refused(code: String, reason: String)
## §8 step 4. Somebody else won the catch on the creature this player was
## fighting. Their HUD says who got it rather than their fight silently ending.
signal caught_by_other(peer_id: int, species_id: String)

enum State { INACTIVE, ACTIVE, RESOLVING }

## Why a fight ended. "caught" is new in M3 and is deliberately distinct from
## "won": beating a creature and keeping one are different outcomes and the
## world needs to treat them differently.
const OUTCOME_CAUGHT := "caught"

## CL-W5(b). What the disengage button says when it refuses a trainer fight.
## Here rather than in a config block because it is not a tunable: it is the
## sentence that makes an otherwise dead button legible, and it has exactly one
## caller (`_refuse_flee()`).
const FLEE_REFUSED_MESSAGE := "You can't walk away from a challenge."

## What the player's creature is doing. Wind-up and recovery are ROOTED: committing
## to an attack costs you your mobility, which is the whole reason a charged
## attack is a decision rather than a better button.
enum Action { READY, WINDUP, RECOVERY, STAGGER, BURST }

var state: State = State.INACTIVE

## The player's creatures. Length one for M2; M4 grows it. Combat always addresses
## the active fighter through this index so switching is an index change rather
## than a rewrite.
var _party: Array[RefCounted] = []
var _active_index: int = 0
var _enemy: RefCounted = null

## R8.1. Does the creature on the other side of the arena BELONG to somebody?
##
## Set by `begin()` and read by the two places a catch can be attempted. A
## trainer's creature cannot be caught — a CLAUDE.md hard rule — and the
## refusal is enforced here, at the entry to the throw, rather than by hiding
## the button: the orb is never spent, the aim never opens, and the player is
## told why. `catch_math.can_be_caught()` has carried the `already_owned`
## argument since M3 for exactly this; until now every caller passed `false`.
var _enemy_owned: bool = false

## R4.7: whichever `_party` member is `autoload/party.gd`'s flagged Best
## Creature, passed in by whoever calls `begin()` (this file never reads the
## Party autoload directly — see `_is_best()`). Null means nobody is flagged,
## which is also what every existing caller/test that omits the new `begin()`
## argument gets.
var _best_creature: RefCounted = null

## D32. Seconds left before another voluntary switch is allowed. Set by
## `request_switch`, ticked down in `_tick_active`. Does not gate a faint —
## there is no auto-switch-on-faint (D32's own "what was deliberately not
## built") — only the player's own next `request_switch`/`cycle_active` call.
var _switch_lockout: float = 0.0

## D30. What the active creature and its bench earned from the fight that just
## ended, keyed by `creature_instance.label()`: `{"xp": int, "levels": int}`. Reset
## at the start of every fight and overwritten by the next victory. The HUD
## reads this; nothing here draws it. Two un-nicknamed party members of the
## same species collide on this key — a later milestone that keys the HUD's
## own readout by party index rather than label can retire this note.
var last_xp_award: Dictionary = {}
var _victory_awarded := false

var _player: Node3D = null
var _wild: Node3D = null
var _ally_body: Node3D = null
var _camera_rig: Node = null
var _arena: Node3D = null

## OP-0905-17: the smoothed extra-distance `_update_combat_camera_framing()`
## adds on top of `camera.distance` this physics tick. Persisted across frames
## (rather than recomputed from scratch each tick) so `camera.framing.lag`
## has something to ease FROM; reset to 0.0 whenever the camera is fully
## released so a later fight does not inherit a wide frame from this one's end.
var _camera_framing_extra: float = 0.0
var _framing_bounds_cache: Dictionary = {}
## MEADOWS-VISUAL-PASS: how far the ally is faded because it hides the foe
## (`ally_occlusion_fade.gd`), and the model it was written to, so the fade is
## taken off that model whatever replaces it.
var _ally_fade: float = 0.0
var _ally_faded_model: Node3D = null
var _ally_fade_state: Dictionary = {}
var _ally_hidden_for := 0.0
## Seconds the foe has been clear since the ally last hid it. The wider swing
## holds for `composition_hold_s` of that before easing back, so the tracker
## does not swing out, clear the foe, swing back into the ally and repeat.
var _ally_clear_for := 0.0

## OP23-02: the point `_open_arena()` already asked `_arena_bounds()` about
## when it sized this fight's radius. `_room_clearance()` (now diagnostics only;
## the camera is not capped by it, see `_update_combat_camera_framing`) asks
## the same question at the same point rather than at `_ally_body`'s own
## position -- a fighter placed near a wall (`_place_fighters()`, `deploy_offset`/
## `separation`) can end up a hair OUTSIDE a small room's rect even though
## the arena itself was correctly clamped to fit inside it, which read the
## room as "open" (`_arena_bounds()` returns -1.0 for a point outside every
## rect) and left the flat, uncollided shoulder offset in place exactly
## where the room is tightest.
var _arena_centre: Vector3 = Vector3.ZERO

var _action: Action = Action.READY
var _action_timer: float = 0.0
var _pending_move: Dictionary = {}
var _quick_cooldown: float = 0.0
var _charged_cooldown: float = 0.0
## COMBAT-2. Wind belongs to a party slot for the lifetime of one fight. A
## switch therefore preserves both creatures' pools instead of refilling the
## outgoing or incoming member. New fights initialize every member at its
## condition-adjusted cap; walking never reads or changes these arrays.
var _party_wind: Array[float] = []
var _party_wind_quiet: Array[float] = []
var _player_poise: float = 0.0
var _player_poise_quiet_left: float = 0.0
var _player_stagger_critical_ready := false
var _hitstop_left := 0.0
var _stagger_glows: Dictionary = {}
## A networked burst waits for host authorization before physical movement.
## This closes the attack/burst ordering window without adding prediction that
## the host could later have to rewind through collision.
var _burst_awaiting_host := false
## Scoped to this manager's current encounter. Transport action ids may restart
## for a new hosted trainer round while the physical body is reused, so replay
## memory belongs here/EncounterHost rather than on CreatureBody.
var _last_burst_action := 0

## An attack press made during wind-up, recovery or cooldown, kept alive for
## `flow.input_buffer` seconds and fired the moment the creature is ready. Without
## this, presses in the ~0.4s dead window were silently discarded and mashing
## at a natural rhythm read as dropped input. "" / "quick" / "charged".
var _buffered_attack: String = ""
var _buffer_left: float = 0.0

var _resolve_timer: float = 0.0
var _outcome: String = ""

## Seconds after the fight opens during which player input is ignored.
##
## Engage and charged attack are the same physical button (X / interact and
## combat_charged), and `is_action_just_pressed` stays true for the whole frame.
## Without this, the press that starts the fight is also read as the first
## attack of it.
var _input_guard: float = 0.0

## Seconds left on a disengage press made while input was not being read
## (hitstop, `_input_guard`, a burst awaiting the host). `_flee_pressed()` is an
## EDGE: without this, a player pressing Run on a frame the fight happens to be
## frozen for a hit loses the press entirely, and a creature under steady
## attack can make leaving a fight a lottery. Honoured the moment input is read
## again, and dropped once `flow.flee_buffer` runs out.
var _flee_buffer_left: float = 0.0

## Catching. The aim and the projectile live in throw_aim.gd; what lives here is
## deciding whether a throw is allowed and what its result means to the fight.
##
## The resolution is a staged sequence, not a bare timer: the creature is drawn
## in while the orb hangs (ABSORB), the orb drops and the camera glides into a
## close-up, a beat of stillness (WAIT), the shakes (SHAKING), a held breath
## (VERDICT), then the outcome. The outcome itself was decided the moment the
## orb landed; the phases only perform it.
enum CatchPhase { NONE, ABSORB, WAIT, SHAKING, VERDICT }
var _throw: Node = null
var _catch_phase: CatchPhase = CatchPhase.NONE
var _catch_timer: float = 0.0
var _catch_shakes_total: int = 0
var _catch_succeeded: bool = false
## See `last_catch_chance()`.
var _catch_chance_resolved: float = 0.0
var _catch_index: int = 0

## Opening-only reliability policy, configured by SequenceDirector rather than
## inferred from species here. Bramblebun remains an ordinary RNG catch
## everywhere else; only the authored first-catch beat gets the documented
## "cannot fail twice" bound. The count survives a run/re-engage during that
## beat and resets when the sequence disables the policy.
var _tutorial_catch_failure_bound: int = -1
var _tutorial_catch_failures: int = 0

## `R9.4-remainder-9-combat`: floats over the real opponent for the length of
## the fight, so it cannot be confused with an ambient decorative creature from the
## same spawn cluster.
var _target_marker: Node3D = null

var _rng := RandomNumberGenerator.new()

## --- Stage B Wave 4 lane 4.C: the encounter link -----------------------------
##
## `docs/specs/MP_ENCOUNTER_PROTOCOL.md`. NULL SOLO, and that is the whole of
## why single-player combat is byte-for-byte what it was: every gate below is
## `if _encounter_link != null`, so with no session there is not one extra
## branch taken on the path from a button press to a health bar.
##
## When a session IS live the link is `encounter_director.gd` -- the transport,
## exactly as `ledger_rpc.gd` is the transport for the world ledger. This file
## never touches `multiplayer`, never asks `multiplayer.is_server()` (the
## `OfflineMultiplayerPeer` trap: with no session that is TRUE and
## `get_unique_id()` is 1, so every headless test, capture tool and editor run
## would take the host branch), and never mints an id. It submits what the
## player did and renders what the host says happened.
##
## §3: the record's `hp` is THE hit points. In a session nothing in this file
## calls `_enemy.take_damage()` -- the host's number is WRITTEN to `_enemy.hp`,
## because a bar that un-drops is worse than a bar that lags.
var _encounter_link: Node = null
var _encounter_id: String = ""
var _realm_owned_opponent := false

## The record's `kind` ("wild" | "trainer" | "boss"). Held only so this file can
## report it back with a catch intent; the refusal itself is the host's (§8),
## and `_enemy_owned` remains the local, solo answer to the same question.
var _encounter_kind: String = ""

## §8. A throw whose orb has landed and whose outcome is with the host. A
## separate phase rather than a flag, so `_tick_catch_resolution()` cannot walk
## into the wobble on a decision that has not been made.
var _catch_awaiting_host: bool = false
var _catch_attempt_serial := 0
var _catch_awaiting_attempt := 0
var _catch_attempt_requires_exact := false
var _catch_claim_id := ""
var _catch_finish_requires_host := false
var _catch_presentation_last_ms := 0

## The last record `seq` this process applied, so a delta that arrives late or
## twice cannot walk the health bar backwards.
var _encounter_seq: int = 0

## The last refusal this process was given: `{"kind", "code", "reason"}`. Read
## by the HUD and by `tools/net/peer_runner.gd`'s probe -- the net smoke asserts
## the `friendly_target` refusal WAS issued, not merely that no damage landed.
var last_encounter_refusal: Dictionary = {}

## D30 named-move lookup, loaded once. Read-only after construction, so one
## instance shared for the life of the manager is fine — the same choice
## `_rng` above already makes.
var _moves: RefCounted = null


func _ready() -> void:
	_rng.randomize()
	_moves = MOVE_DB.new()

	_throw = THROW_AIM.new()
	_throw.name = "ThrowAim"
	add_child(_throw)
	_throw.connect("orb_struck", _on_orb_struck)
	_throw.connect("orb_missed", _on_orb_missed)
	_throw.connect("throw_refused", func(reason: String) -> void: catch_refused.emit(reason))
	# The camera comes BACK when the aim ends. This signal had no listener at
	# all: cancelling an aim, and every throw, left the whole rest of the fight
	# framed through the over-the-shoulder aim profile parked on the trainer.
	# After a release the aim camera is kept deliberately — watching your own
	# throw arc away is the shot — and the strike or miss decides what's next.
	_throw.connect("aim_exited", _on_aim_exited)


func throw_aim() -> Node:
	return _throw


## --- Stage B lane 4.C: joining this fight to a session -----------------------

## Bind this manager to a host-arbitrated encounter. `link` is the transport
## (`encounter_director.gd`); `encounter_id` is the host-minted id of the record
## this fight renders.
##
## Called by the director immediately after `begin()` when -- and only when --
## there is a real, live, multi-peer session. Nothing calls it solo, so nothing
## solo changes.
func bind_encounter(link: Node, encounter_id: String, kind: String) -> void:
	# A hosted trainer round reuses this manager, but it is a new encounter with
	# a new opponent and must be eligible for its one victory award.
	if _encounter_id != encounter_id:
		_victory_awarded = false
	_encounter_link = link
	_encounter_id = encounter_id
	_encounter_kind = kind
	_catch_claim_id = ""
	_catch_finish_requires_host = false
	_catch_presentation_last_ms = 0
	_last_burst_action = 0


func unbind_encounter() -> void:
	_encounter_link = null
	_encounter_id = ""
	_encounter_kind = ""
	_catch_awaiting_host = false
	_burst_awaiting_host = false
	_last_burst_action = 0


## The record this fight is rendering, or "" solo. Read by the director and by
## the net harness probe; nothing branches on it inside this file except the
## submit paths.
func encounter_id() -> String:
	return _encounter_id


## True when the outcome of this fight is somebody else's to decide.
func is_networked() -> bool:
	return _encounter_link != null


func active_creature() -> RefCounted:
	if _active_index < 0 or _active_index >= _party.size():
		return null
	return _party[_active_index]


func enemy() -> RefCounted:
	return _enemy


## T3-TYPECHART's readiness tell, as a number the HUD can draw an arrow from:
## 1 the creature currently piloted is advantaged into this foe, -1
## disadvantaged, 0 neither (and 0 whenever there is no fight, no creature or
## no foe, so a caller never has to null-check before asking).
##
## THE BEST OF THE TWO EQUIPPED MOVES, not the creature's own species type.
## The chart is keyed on moves (see `type_chart.gd`), and a creature's two
## slots can hold two different types -- Mosshell and Reedwing ship that way
## today and any TM creates it. Reporting the species type here would tell the
## player something the fight does not actually do. Reporting the BEST of the
## two is the honest summary of "is this the right creature to have out", which
## is the question an arrow on a nameplate is answering; the per-hit
## `hit_effectiveness` signal then reports the move actually thrown, so a
## player who sees an advantage arrow and then a WEAK hit has just been taught
## that their two moves are different types -- which is the coverage mechanic
## teaching itself, with no tutorial and no menu.
##
## Owner-direction section 9 is the constraint this is written against: "do not
## tell the player exactly which creature to use", while giving "enough
## information that preparation feels intelligent rather than random". One
## arrow on the creature that is already out says the matchup is favoured; it
## does not rank the other four.
func active_matchup() -> int:
	var creature: RefCounted = active_creature()
	if creature == null or _enemy == null or _moves == null:
		return 0
	var defending := str(_enemy.creature_type)
	var defending2 := str(_enemy.get("secondary_type"))
	var quick := TYPE_CHART.multiplier_dual(
		_moves.type_of(str(creature.move_quick)), defending, defending2
	)
	var charged := TYPE_CHART.multiplier_dual(
		_moves.type_of(str(creature.move_charged)), defending, defending2
	)
	return TYPE_CHART.classify(maxf(quick, charged))


## SequenceDirector owns whether the current fight is the authored tutorial.
## Re-enabling an already-active policy preserves failures across a run and
## retry; changing or disabling it starts the next context cleanly.
func configure_tutorial_catch_assist(enabled: bool, max_failures: int = 1) -> void:
	var next_bound := maxi(max_failures, 0) if enabled else -1
	if next_bound == _tutorial_catch_failure_bound:
		return
	_tutorial_catch_failure_bound = next_bound
	_tutorial_catch_failures = 0


func tutorial_catch_failures() -> int:
	return _tutorial_catch_failures


## R4.7: is `creature` the fight's flagged Best Creature? Compared by
## reference — `_best_creature` and `_party`'s members are the same live
## instances the caller's Party autoload holds, never copies.
func _is_best(creature: RefCounted) -> bool:
	return creature != null and _best_creature != null and creature == _best_creature


func is_fighting() -> bool:
	return state != State.INACTIVE


func arena() -> Node3D:
	return _arena


## Begin a fight. `ally_body` is the player's deployed creature, `camera_rig` is the
## exploration camera that will be re-pointed at it. `best_creature` is R4.7's
## Best Creature flag (`autoload/party.gd::best()`); optional and defaulting
## to null so every existing caller/test keeps behaving exactly as before.
##
## `opponent_owned` (R8.1) marks the opponent as somebody else's creature — a
## trainer's. The only thing it changes here is that catching is refused; a
## trainer's creature fights, takes damage, faints and grants XP exactly like a
## wild one. Defaults to false, so a wild fight is unaffected.
func begin(
	player: Node3D, wild: Node3D, ally_body: Node3D, party: Array[RefCounted],
	camera_rig: Node = null, best_creature: RefCounted = null,
	opponent_owned: bool = false, realm_owned_opponent: bool = false
) -> bool:
	if is_fighting():
		return false
	if player == null or wild == null or ally_body == null or party.is_empty():
		push_error("cannot begin combat without a player, a wild creature, a deployed body and a party")
		return false

	_player = player
	_wild = wild
	_ally_body = ally_body
	# BP2: an orb stopped dead on your own creature and the throw was spent.
	# The fight knows who is fighting for the trainer; `throw_aim.gd` does not,
	# so it is told here rather than reaching for it.
	if _throw != null and _throw.has_method("set_pass_through"):
		_throw.call("set_pass_through", [_ally_body])
	_camera_rig = camera_rig
	_best_creature = best_creature
	_party = party
	_active_index = 0
	_enemy_owned = opponent_owned
	_realm_owned_opponent = realm_owned_opponent
	_enemy = wild.get("instance")
	if _enemy == null:
		push_error("wild creature has no instance")
		return false

	var creature := active_creature()
	if creature == null or creature.fainted or bool(creature.get("resting")):
		return false

	_action = Action.READY
	_action_timer = 0.0
	_pending_move = {}
	_quick_cooldown = 0.0
	_charged_cooldown = 0.0
	_initialize_wind()
	_reset_player_poise()
	_hitstop_left = 0.0
	_burst_awaiting_host = false
	_last_burst_action = 0
	_buffered_attack = ""
	_buffer_left = 0.0
	_resolve_timer = 0.0
	_outcome = ""
	_input_guard = float(MATH.config().get("flow", {}).get("input_guard", 0.25))
	_flee_buffer_left = 0.0

	_catch_phase = CatchPhase.NONE
	_catch_timer = 0.0
	_catch_shakes_total = 0
	_catch_claim_id = ""
	_catch_finish_requires_host = false
	_catch_presentation_last_ms = 0

	_switch_lockout = 0.0
	last_xp_award.clear()
	_victory_awarded = false

	_open_arena()
	if realm_owned_opponent:
		# Joining a shared realm encounter must not reposition its enemy or
		# constrain it to this participant's disposable presentation arena.
		# The local follower can legitimately arrive here after snagging on world
		# geometry. Seat only that locally-piloted body at the ordinary player-side
		# staging spot; the authoritative enemy and trainer keep their transforms.
		_place_realm_owned_ally()
	else:
		_place_fighters()
	_throw.call("arm", _player, _wild, _camera_rig)

	if not _wild.is_connected("strike_ready", _on_enemy_strike):
		_wild.connect("strike_ready", _on_enemy_strike)
	if not _wild.is_connected("telegraph_started", _on_enemy_telegraph):
		_wild.connect("telegraph_started", _on_enemy_telegraph)
	if not realm_owned_opponent:
		_wild.call("set_engaged", true, _ally_body)
		_wild.set("arena", _arena)
	_ally_body.set("arena", null if realm_owned_opponent else _arena)

	_target_marker = TARGET_MARKER.begin(_arena, _wild, MATH.config().get("target_marker", {}))

	_take_camera()

	state = State.ACTIVE
	entered.emit()
	state_changed.emit()
	return true


## End only the presentation fight whose realm-owned body is being withdrawn.
## The ordinary wild/trainer paths cannot reach this guard.
func end_shared_opponent_presentation(body: Node3D) -> bool:
	if not _realm_owned_opponent or body == null or body != _wild:
		return false
	if state == State.ACTIVE:
		_begin_resolve("fled")
		return true
	return state == State.RESOLVING


## A realm-owned opponent has its own host simulation. This local manager draws
## HUD/camera/input only and must never retain a callback that can drive that
## opponent after this participant leaves or binds another fight.
func detach_realm_opponent_callbacks(body: Node3D) -> bool:
	if not _realm_owned_opponent or body == null or body != _wild:
		return false
	_disconnect_opponent_callbacks(body)
	return true


func present_realm_opponent_telegraph(seconds: float) -> void:
	if _realm_owned_opponent and state == State.ACTIVE and seconds > 0.0:
		_on_enemy_telegraph(seconds)


func _disconnect_opponent_callbacks(body: Node3D) -> void:
	if body == null or not is_instance_valid(body):
		return
	if body.has_signal("strike_ready") and body.is_connected("strike_ready", _on_enemy_strike):
		body.disconnect("strike_ready", _on_enemy_strike)
	if body.has_signal("telegraph_started") and body.is_connected("telegraph_started", _on_enemy_telegraph):
		body.disconnect("telegraph_started", _on_enemy_telegraph)


## --- setup ----------------------------------------------------------------

## The arena is centred between the two fighters, not on the trainer. Centring
## it on the trainer would put them at the middle of a circle they are supposed
## to be standing at the edge of, watching.
##
## OP21-25: `combat.json`'s radius is one flat number for every fight
## anywhere, and the Stronghold/Burrow Warrens rooms are mostly smaller than
## it in at least one dimension. `combat_arena.hold_inside()` corrects a
## fighter with a raw position write, not a physics move -- it has no
## collision to stop it -- so a boundary that reaches past a room's real walls
## does not clip a knocked-back fighter against them, it teleports the fighter
## straight through to the far side, and the fight becomes unwinnable exactly
## as OP21-25 describes. `_arena_bounds()` asks whatever built this room
## (`stronghold.gd`, `burrow_warrens.gd`) how much radius it can actually
## afford, the same way `_ground_height()` below already asks it for a Y --
## and only ever SHRINKS the configured radius, never grows it, so the open
## meadow (nothing answers the query, `_arena_bounds()` returns -1.0) fights
## exactly as before.
func _open_arena() -> void:
	var cfg: Dictionary = (MATH.config().get("arena", {}) as Dictionary).duplicate()
	_arena = ARENA.new()
	_arena.name = "CombatArena"
	_player.get_parent().add_child(_arena)
	var centre := _midpoint(cfg)
	_arena_centre = centre
	var bound := _arena_bounds(centre)
	if bound > 0.0:
		cfg["radius"] = minf(float(cfg.get("radius", 11.0)), bound)
	_arena.call("configure", centre, cfg)


## The most radius the room around `centre` can afford, or -1.0 if no room
## claims it.
##
## This is a SPATIAL search over the world root's own children, not an
## ancestry walk. An `_ground_height()`-style walk up from the player (or from
## this manager) does not work here: the player is never reparented into
## `Stronghold`/`BurrowWarrens` when they walk inside one (`playground_world.gd`
## keeps `Player` a permanent sibling of both), and neither is a trainer's
## deployed creature -- `encounter_director.gd::begin_trainer_battle()` adds
## every `TrainerCreature_*` body to ITS OWN parent (the world root), not to
## whichever room the trainer stands in. A wild creature IS parented under its
## room (`burrow_warrens.gd::_spawn_population()` passes `parent: self`), but a
## fix that only worked for wild fights would leave every Stronghold gauntlet
## and the Warden himself uncovered -- exactly the trainer battles OP21-25
## names. So this asks every child of the arena's own host (the same node
## `_open_arena()` just parented the arena under) that answers to
## `combat_arena_bounds_at`, and returns the first one that claims `centre` as
## its own. `Stronghold` and `BurrowWarrens` are both direct children of the
## world root (`playground_world.gd::_build_stronghold()`/
## `_build_burrow_warrens()`), so this reaches them regardless of which body
## the fight happens to be using.
func _arena_bounds(centre: Vector3) -> float:
	var host: Node = _player.get_parent() if _player != null else get_parent()
	if host == null:
		return -1.0
	for child in host.get_children():
		if child == _arena or not (child is Node) or not child.has_method("combat_arena_bounds_at"):
			continue
		var bound := float(child.call("combat_arena_bounds_at", centre.x, centre.z))
		if bound > 0.0:
			return bound
	return -1.0


func _midpoint(cfg: Dictionary) -> Vector3:
	var spots := _staging_spots(cfg)
	return (spots[0] + spots[1]) * 0.5


## How coarsely `_staging_reach()` walks the staging back out of a wall. Half a
## metre is well under the fighters' own body radii, so a spot found at this
## resolution is not one a body then overlaps the wall from.
const CONTAIN_STEP_M := 0.5


## The two spots the fight forms on, in front of the player along the line they
## engaged down: their creature at `deploy_offset`, the opponent `separation`
## past it. Taken as ONE piece so `_open_arena()` and `_place_fighters()` cannot
## disagree about where the fight is.
func _staging_spots(cfg: Dictionary) -> Array[Vector3]:
	var deploy := float(cfg.get("deploy_offset", 2.6))
	var separation := float(cfg.get("separation", 5.0))
	var full := deploy + separation
	var forward := _staging_axis(full)
	var scale := 1.0
	if full > 0.01:
		scale = _staging_reach(_player.global_position, forward, full) / full
	return [
		_player.global_position + forward * (deploy * scale),
		_player.global_position + forward * (full * scale),
	]


## Prefer the direction the encounter was taken up in, except when a built
## room has substantially more legal floor behind the player than ahead.
##
## The old containment fix only shortened the authored 7.6 m formation. With
## today's creature sizes, shortening can put two perfectly grounded capsules
## inside each other; physics then resolves the overlap vertically and a body
## appears to float metres above the arena floor. A room is not a corridor with
## only one legal facing: when the other direction carries the full formation,
## turn the formation into that floor instead of crushing it.
func _staging_axis(want: float) -> Vector3:
	var forward := _forward_axis()
	if want <= 0.0 or _arena_bounds(_player.global_position) <= 0.0:
		return forward
	var forward_reach := _staging_reach(_player.global_position, forward, want)
	var reverse_reach := _staging_reach(_player.global_position, -forward, want)
	return -forward if reverse_reach > forward_reach + CONTAIN_STEP_M else forward


## How far in front of `from` the fight may form before it leaves the room it is
## being held in. `want` back unchanged whenever no room claims `from`, which is
## every square metre of the open meadow.
##
## MP-F1-F2 finding F2, measured in the Warden Arena. The staging above is
## `deploy_offset + separation` -- ~7.6 m with the shipped `arena` block -- in
## front of wherever the player engaged. The Warden stands 5 m from that room's
## back wall, so a fight taken up beside him formed 4-5 m OUTSIDE it, at
## z 7666-7668 where the sweep below found no floor collider at all:
##
##     z 7663.0   claim 6.172   terrain -1.568   arena_r  0.50   slab collider
##     z 7664.0   claim 6.172   terrain -1.605   arena_r -1.00   slab collider
##     z 7666.0   claim 6.172   terrain -1.664   arena_r -1.00   NO COLLIDER
##     z 7668.0   claim 6.172   terrain -1.767   arena_r -1.00   NO COLLIDER
##
## `stronghold.gd::built_floor_height_at()` still CLAIMS those metres -- its
## margin is deliberately 10 m so that a fight which has drifted past a wall is
## not told its floor is the meadow far below -- so `place_on_ground()` seated
## every body at the room's floor height of 6.172 and
## `creature_body._physics_process()`, which grounds on `is_on_floor()` and not
## on anybody's claim, dropped them ~8 m. Measured: the boss finished at -1.767
## with both piloted creatures still falling from 6.172, and every swing missed.
##
## The claim margin is not the bug and is not narrowed here; the stronghold's own
## comment says so and names the owner of the other half outright: "containing
## that drift is `combat_manager.gd`'s own arena-bounds job and stays there."
## This is that. `_arena_bounds()` is already exactly the question -- it answers
## the room's affordable radius inside a chamber and -1.0 everywhere else -- so a
## fight started outdoors, or in a passage between two chambers, walks none of
## this and is byte-for-byte the fight it was.
func _staging_reach(from: Vector3, forward: Vector3, want: float) -> float:
	if want <= 0.0 or _arena_bounds(from) <= 0.0:
		return want
	var reach := want
	while reach > CONTAIN_STEP_M:
		if _arena_bounds(from + forward * reach) > 0.0:
			return reach
		reach -= CONTAIN_STEP_M
	return reach


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
	# Taken BEFORE anything is placed: `_forward_axis()` reads the opponent's
	# current position, and `_place()` below moves it.
	var full := float(cfg.get("deploy_offset", 2.6)) + float(cfg.get("separation", 5.0))
	var forward := _staging_axis(full)
	var spots := _staging_spots(cfg)
	var ally_spot: Vector3 = spots[0]
	var wild_spot: Vector3 = spots[1]

	_ally_body.visible = true
	_place(_ally_body, ally_spot)
	_ally_body.call("face_towards", wild_spot)
	_place(_wild, wild_spot)
	_wild.call("face_towards", ally_spot)
	_stand_the_trainer_aside(forward)


## Shared encounters retain the host-owned opponent's transform, but a local
## follower stranded on the route must still enter the fight it is asked to
## pilot. Use the same contained, grounded ally spot as ordinary combat without
## moving the enemy or stepping the trainer aside.
func _place_realm_owned_ally() -> void:
	var cfg: Dictionary = MATH.config().get("arena", {})
	var ally_spot: Vector3 = _staging_spots(cfg)[0]
	var enemy_at := _combat_position(_wild)
	# The shared opponent is deliberately not moved to staging spot 1. If it is
	# already near the trainer, ordinary spot 0 can therefore land between the
	# two bodies. Preserve the configured fighter separation by using the same
	# contained reach on the opposite side of the trainer in that case.
	if ally_spot.distance_to(enemy_at) < float(cfg.get("separation", 5.0)):
		var away := _combat_position(_player) - enemy_at
		away.y = 0.0
		if away.length_squared() > 0.001:
			away = away.normalized()
			var deploy := float(cfg.get("deploy_offset", 2.6))
			ally_spot = _combat_position(_player) \
				+ away * _staging_reach(_combat_position(_player), away, deploy)
	_ally_body.visible = true
	_place(_ally_body, ally_spot)
	_ally_body.call("face_towards", _combat_position(_wild))


func _combat_position(body: Node3D) -> Vector3:
	return body.global_position if body.is_inside_tree() else body.position


## The trainer steps to the side of the arena as their creature deploys.
##
## They stay in the fight, in frame, and untargetable — but not in the LANE. The
## camera follows the player's creature from behind, and the trainer engaged from
## directly behind that creature, so leaving them where they stood put a 1.8m body
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
	var spot := _player.global_position

	# Re-grounded rather than trusting the arena centre's own height (D09: ask
	# the world, never carry a Y across a horizontal move). `centre` is the
	# midpoint between where the player engaged and the wild creature, and `spot`
	# is shifted sideways from it — on a slope those two points are at
	# different heights, and this teleport (a raw position write, not a
	# physics move) has nothing else to correct it: the trainer fell through
	# the terrain forever on ground uneven enough for the difference to clear
	# the collision, `move_and_slide` never finding a floor to catch it on the
	# way down. A missing ground reading here is a placement to skip, same as
	# `creature_body.place_on_ground`, rather than a spot to stand on regardless.
	# A grounded destination can still be inside a closed building. Sweep the
	# actual player capsule along the relocation before accepting either side.
	# If both are obstructed, retaining the real starting position is safer than
	# moving through a wall merely to improve the camera composition.
	for sign_value in [1.0, -1.0]:
		var candidate: Vector3 = centre + side * (float(_arena.get("radius")) * 0.55 * float(sign_value)) - forward * 1.2
		if Vector2(candidate.x - centre.x, candidate.z - centre.z).length() > float(_arena.get("radius")):
			continue
		var height := _ground_height(candidate.x, candidate.z)
		if is_nan(height):
			continue
		candidate.y = height
		# Built-floor height providers may deliberately claim beyond their slabs.
		# A real nearby support surface with a walkable normal is also required.
		var support_query := PhysicsRayQueryParameters3D.create(candidate + Vector3.UP * 0.1,
			candidate - Vector3.UP * 0.1, _player.collision_mask, [_player.get_rid()])
		var support := _player.get_world_3d().direct_space_state.intersect_ray(support_query)
		if support.is_empty() or (support["normal"] as Vector3).dot(Vector3.UP) < cos(_player.floor_max_angle):
			continue
		var from := _player.global_transform
		# Avoid treating the supporting floor as an obstacle to horizontal travel.
		# This small clearance is far below any player-steppable obstacle.
		from.origin.y += 0.02
		if not _player.test_move(from, candidate - _player.global_position):
			spot = candidate
			break
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


## The world's own ground query, found by walking up the tree — same pattern
## as `creature_body._ground_height`. Not cached: this is a one-off correction at
## the moment a fight opens, not a per-frame lookup.
## GATE-E: corrected upward by a BUILT floor, the same way
## `creature_body._ground_height` is. This function is what teleports the PLAYER
## when a fight opens, and inside the stronghold the terrain answer put them
## seven metres under the room they engaged in -- see
## `scripts/world/built_floor.gd`. Outside a building the answer is unchanged.
func _ground_height(x: float, z: float) -> float:
	var node: Node = get_parent()
	while node != null:
		if node.has_method("ground_height_at"):
			return BUILT_FLOOR.resolve(self, x, z, float(node.call("ground_height_at", x, z)))
		node = node.get_parent()
	return NAN


## Point the exploration camera at the creature instead of the trainer.
##
## Reusing the orbit rig rather than adding a combat camera: a piloted creature wants
## exactly the third-person camera M1 already tuned, at a shorter creature's
## height. A second camera would be a second thing to keep in sync, and the rig
## already eases onto a new target for free.
func _take_camera() -> void:
	if _camera_rig == null or not _camera_rig.has_method("set_target"):
		return
	_camera_rig.call("set_target", _ally_body, _combat_camera_profile())
	# The camera still orbits the player's creature. A separate, soft opponent
	# tracker only corrects a neutral camera after manual-look grace, so the
	# player keeps full right-stick/mouse ownership instead of entering lock-on.
	if _camera_rig.has_method("set_tracking_target"):
		var tracking: Dictionary = (MATH.config().get("camera", {}) as Dictionary) \
			.get("tracking", {}) as Dictionary
		_camera_rig.call("set_tracking_target", _wild, tracking)


## OP23-02 (owner playtest 2026-08-23): "teleported to the stronghold, battle
## start takes the camera, can't see." `data/config/combat.json`'s flat
## profile ships a shoulder offset. CameraRig now shape-sweeps that lateral
## pivot movement as well as SpringArm's existing depth leg, so an interior can
## retain useful two-fighter composition without pushing the pivot through a
## wall.
##
## The offset is still solved from fighter spacing here. Collision constraints
## belong to the rig because they depend on the current orbit direction and
## must be recomputed while the player rotates the camera.
func _combat_camera_profile() -> Dictionary:
	var profile: Dictionary = (MATH.config().get("camera", {}) as Dictionary).duplicate()
	var distance := float(profile.get("distance", 6.0))
	profile["shoulder_offset"] = _combat_shoulder_offset(
		distance, float(profile.get("pitch_start_deg", -25.0)))
	return profile


## The nearest room-wall radius around the fight, or -1.0 if no room claims it.
## Retained as a diagnostic for runtime smokes and arena containment. CameraRig
## owns lateral pivot collision and SpringArm3D owns depth collision.
func _room_clearance() -> float:
	if _arena == null:
		return -1.0
	var points: Array[Vector3] = [_arena_centre]
	for body in [_player, _wild, _ally_body]:
		if body is Node3D:
			points.append((body as Node3D).global_position)
	var clearance := -1.0
	for at in points:
		var here := _arena_bounds(at)
		if here >= 0.0 and (clearance < 0.0 or here < clearance):
			clearance = here
	return clearance


## VISUAL-CENSUS-2026-08-31 defects 121/122: the flat `shoulder_offset` above
## (`combat.json`, 2.6) was picked ONLY against the config's own worked
## example -- a single assumed 2.1m ally-wild gap -- and never checked
## against the frame it actually produces. Confirmed by re-running
## `tools/survey_combat.gd` with the real geometry printed: at the real
## post-engage gap (2.63m, not the arena's 5.0m deploy separation -- the
## wild creature is already closing by the time the camera settles). a flat
## 2.6 puts the ALLY 25 degrees off the crosshair (its own vfov half-angle is
## 31, so that is most of the way to the edge -- "cropped to shell and one
## leg") and the WILD only 18 degrees off, at a distance where Bramblebun's
## own small mesh and grass-matching colour (separate, out-of-scope defects
## 123/124) make an 18-degree-off, screen-edge-adjacent creature read as
## "not in the frame" to a critic scanning near the boss nameplate instead.
##
## The lateral shift is pure parallax (`camera_rig.gd::_follow()` translates
## the follow pivot sideways without changing where the rig looks), so BOTH
## bodies swing toward the SAME screen edge by an angle of
## `atan(shoulder / depth)` -- the near one (the ally, sitting almost exactly
## at the pivot) swings the MOST because it is the closest, which is exactly
## backwards from where the swing is wanted. A flat metres constant cannot
## fix this: the two things that actually matter -- how far off-centre the
## ally ends up, and how much daylight the shift buys past the ally's own
## body toward the wild -- both depend on the CURRENT ally-wild gap, which
## changes continuously as the fight moves. So this solves the same
## occlusion arithmetic combat.json's own comment already works out, in the
## other direction: given the real gap right now, find the SMALLEST shoulder
## that clears the ally's live body radius (with the existing 0.6m floor)
## (the ORIGINAL bug this whole mechanism exists to fix -- OP23/R9.4's
## opponent hidden directly behind the ally, confirmed at the time with a
## real raycast), rather than a shoulder picked for one assumed distance and
## then applied at every other distance the fight can actually be at.
## The configured max_shoulder_offset bounds tight-clinch requests. Oblique
## tracking supplies additional silhouette separation; the rig sweeps actual
## shoulder travel against walls and framing checks both live render bounds.
##
## COMBAT-1, and an owner decision at the merge. The paragraph above solves for
## "the ally's live body RADIUS", which is a collision figure standing in for a
## silhouette; COMBAT-1 solves the same arithmetic against the live RENDERED
## envelopes of BOTH bodies instead -- including the enemy's apparent half-width
## compressed to the ally's depth plane by `setback / (setback + gap)` -- which
## is what the frame actually shows. That calculation is what `shoulder_for_
## extents()` below does and what now runs.
##
## What did NOT change is the ceiling: the owner's call was COMBAT-1's
## calculation under MAIN's configured bound, so the result is clamped by
## `combat.json`'s `camera.max_shoulder_offset` rather than by the hard
## `SHOULDER_MAX_M` constant COMBAT-1 clamped to on its own branch. Beyond that
## cap, complete separation needs a different composition, not a larger
## uncollided pivot excursion.
const SHOULDER_MIN_M := 1.0
const SHOULDER_MAX_M := 2.2
const SHOULDER_CLEARANCE_FLOOR_M := 0.6


func _combat_shoulder_offset(distance: float, pitch_start_deg: float) -> float:
	var max_shoulder := maxf(SHOULDER_MIN_M, float(
		(MATH.config().get("camera", {}) as Dictionary).get("max_shoulder_offset", SHOULDER_MAX_M)))
	if _ally_body == null or _wild == null \
			or not is_instance_valid(_ally_body) or not is_instance_valid(_wild):
		return minf(SHOULDER_MAX_M, max_shoulder)
	# Horizontal component of the arm's own setback -- the same
	# `distance * cos(pitch)` combat.json's comment already works this out
	# with, not a second guess at the rig's geometry.
	var setback := distance * cos(deg_to_rad(absf(pitch_start_deg)))
	if setback <= 0.01:
		return minf(SHOULDER_MAX_M, max_shoulder)
	var ally_flat := Vector2(_ally_body.global_position.x, _ally_body.global_position.z)
	var wild_flat := Vector2(_wild.global_position.x, _wild.global_position.z)
	var gap := maxf(ally_flat.distance_to(wild_flat), 0.3)
	var right := Basis(Vector3.UP, float(_camera_rig.get("yaw"))).x if _camera_rig != null else Vector3.RIGHT
	var ally_extent := _body_lateral_extent(_ally_body, right)
	var enemy_extent := _body_lateral_extent(_wild, right)
	return shoulder_for_extents(setback, gap, ally_extent, enemy_extent, max_shoulder)


## `max_shoulder` defaults to `SHOULDER_MAX_M` so the existing four-argument
## callers in `tests/test_combat_camera_shoulder.gd` keep their meaning; the
## live caller above passes the configured `camera.max_shoulder_offset`.
static func shoulder_for_extents(setback: float, gap: float, ally_extent: float,
		enemy_extent: float, max_shoulder: float = SHOULDER_MAX_M) -> float:
	var safe_gap := maxf(gap, 0.3)
	var safe_setback := maxf(setback, 0.01)
	# At the ally depth plane the enemy's apparent half-width is compressed
	# by setback / (setback + gap). Shoulder parallax must clear both edges.
	var clearance := maxf(0.0, ally_extent) + maxf(0.0, enemy_extent) \
		* safe_setback / (safe_setback + safe_gap) + SHOULDER_CLEARANCE_FLOOR_M
	# Owner decision: this branch's live-render-bounds clearance, under main's
	# CONFIGURED bound rather than the hard constant, so `combat.json`'s
	# `camera.max_shoulder_offset` still caps a tight-clinch request the way the
	# early returns above already assume it does.
	var ceiling := minf(SHOULDER_MAX_M, maxf(SHOULDER_MIN_M, max_shoulder))
	return clampf(clearance * (safe_setback + safe_gap) / safe_gap, SHOULDER_MIN_M, ceiling)


func _body_lateral_extent(body: Node3D, right: Vector3) -> float:
	var bounds := _body_render_bounds(body)
	if bounds.size.is_zero_approx() or not body.has_method("model_pivot"):
		return 0.0
	var model: Node3D = body.call("model_pivot") as Node3D
	if model == null: return 0.0
	var extent := 0.0
	for x in [0.0, 1.0]:
		for y in [0.0, 1.0]:
			for z in [0.0, 1.0]:
				var corner := bounds.position + bounds.size * Vector3(x, y, z)
				var offset := model.global_transform * corner - body.global_position
				extent = maxf(extent, absf(offset.dot(right)))
	return extent


## OP-0905-17 (owner playtest 2026-09-05): "the fighting camera sucks. I think
## it is too zoomed in." The raised `camera.distance`/`fov`/`height` in
## combat.json widen the base shot; this is what keeps it widening further as
## the fight itself demands more room, every ACTIVE tick (`_tick_active()`
## calls this directly, not just from the discrete `_take_camera()` takeover
## points) rather than only at the moments the camera changes target:
##
##   * the two fighters can spread far apart across an 11m arena with neither
##     switching creatures nor re-entering an aim, and a flat base distance
##     tuned for the OPENING gap crops one of them out as they separate;
##   * an alpha, a burrow guardian or the Warden's ace is scaled well past a
##     normal creature (`creature_body.gd::apply_size_multiplier()`) and the
##     same base distance that frames a normal fight crops a body that big.
##
## `camera_rig.gd::_follow()` already owns the LAST leg of getting to whatever
## `_distance` this writes -- `move_toward(spring_length, _distance,
## _recover_speed * delta)` -- so this only ever needs to update that one
## field, read here by the same reflection the production smokes already use
## on this rig's other "private" fields (`smoke_combat_camera.gd`'s own
## `_rig.get("_target")`/`_rig.set("yaw", ...)`), rather than re-running the
## whole `set_target()` takeover: THAT resets `_retarget_lag` on every call,
## which is spent once easing onto a brand-new target and must not be pinned
## back to its start value every physics tick a fight is merely continuing.
##
## Smoothed with `camera.framing.lag` (`_camera_framing_extra` is the eased
## state, not the raw target) so the frame breathes as the gap changes rather
## than snapping every tick. The request stays bounded by configured
## `max_extra_distance`; SpringArm3D contracts it against real geometry in the
## current camera direction.
func _update_combat_camera_framing(delta: float) -> void:
	if _camera_rig == null or _ally_body == null or not is_instance_valid(_ally_body):
		return
	# Only while the rig is actually following the piloted creature. Throw aim
	# re-points it at the trainer (`throw_aim.gd::arm()`) and the catch
	# resolution close-up re-points it at the orb (`_show_resolve_camera()`) --
	# both already own the shot for as long as they hold the target, and this
	# must not fight either of them for `_distance`.
	if _camera_rig.get("_target") != _ally_body:
		return
	var cfg: Dictionary = MATH.config().get("camera", {}) as Dictionary
	var base_distance := float(cfg.get("distance", 6.0))
	var framing: Dictionary = cfg.get("framing", {}) as Dictionary
	if not bool(framing.get("enabled", true)):
		_camera_framing_extra = 0.0
		_camera_rig.set("_distance", base_distance)
		return
	var target_extra := _combat_camera_framing_target(framing)
	var lag := maxf(float(framing.get("lag", 4.0)), 0.01)
	var weight := 1.0 - exp(-lag * delta)
	_camera_framing_extra = lerpf(_camera_framing_extra, target_extra, weight)
	var desired := base_distance + _camera_framing_extra
	# The nearest-wall distance cap is one config value, `room_distance_cap`,
	# and it ships off (see its `_why` in combat.json). The nearest wall to ANY
	# fighter is not a camera-distance ceiling: clamped to it, the den fight put
	# the lens 2 m behind a 3.9 m ally, inside its body. SpringArm3D contracts
	# depth against real geometry in the camera's actual direction, and
	# CameraRig sweeps the shoulder pivot against walls, so a tight room still
	# keeps the lens out of the rock.
	var clearance := _room_clearance() if bool(framing.get("room_distance_cap", false)) else -1.0
	if clearance >= 0.0:
		desired = minf(desired, maxf(1.5, clearance))
	_camera_rig.set("_distance", desired)
	if clearance >= 0.0:
		_camera_rig.set("_shoulder", 0.0)
	elif float(_camera_rig.get("_tracking_manual_left")) <= 0.0:
		# Use the live pitch/distance, and never retarget/reset manual orbit.
		var shoulder := _combat_shoulder_offset(desired, rad_to_deg(float(_camera_rig.get("pitch"))))
		_camera_rig.set("_shoulder", lerpf(float(_camera_rig.get("_shoulder")), shoulder, weight))


## MEADOWS-VISUAL-PASS: while the piloted ally hides the foe from the live
## camera, swing the neutral tracker wider first and fade the ally as the
## fallback; both undo when the foe is clear. Local presentation only; see
## `ally_occlusion_fade.gd`.
func _update_ally_occlusion_fade(delta: float) -> void:
	var cfg: Dictionary = (MATH.config().get("camera", {}) as Dictionary).get("occlusion_fade", {}) as Dictionary
	var model: Node3D = null
	if _ally_body != null and is_instance_valid(_ally_body) and _ally_body.has_method("model_pivot"):
		model = _ally_body.call("model_pivot") as Node3D
	if model != _ally_faded_model:
		_clear_ally_fade()
		_ally_faded_model = model
	if model == null:
		return
	var hidden := bool(cfg.get("enabled", true)) and _ally_hides_wild(model, int(cfg.get("hidden_points", 2)))
	_ally_hidden_for = _ally_hidden_for + delta if hidden else 0.0
	_ally_clear_for = 0.0 if hidden else _ally_clear_for + delta
	# First answer: the neutral tracker swings wider until the foe is clear,
	# which a still frame reads as ordinary framing. The dither is the fallback
	# for when that cannot happen -- the player is steering the camera, or a
	# wall stops the orbit -- and only after the foe has stayed hidden a moment.
	if _camera_rig != null and _camera_rig.has_method("set_composition_extra"):
		var current := float(_camera_rig.call("composition_extra"))
		var holding := current > 0.0 and _ally_clear_for < float(cfg.get("composition_hold_s", 1.5))
		var extra_target := float(cfg.get("composition_extra_deg", 40.0)) if hidden or holding else 0.0
		var ease_rate := maxf(float(cfg.get("composition_ease_deg_per_s", 90.0)), 1.0)
		_camera_rig.call("set_composition_extra", move_toward(current, extra_target, ease_rate * delta))
	var target := 0.0
	if hidden and _ally_hidden_for >= float(cfg.get("dither_after_s", 0.2)):
		target = clampf(float(cfg.get("transparency", 0.6)), 0.0, 0.9)
	var speed := maxf(float(cfg.get("speed", 4.0)), 0.01)
	_ally_fade = move_toward(_ally_fade, target, speed * delta)
	if _ally_fade <= 0.0 and _ally_fade_state.is_empty():
		return
	# Re-applied every tick while faded: the dither is set from the camera's
	# distance, which moves with the fight.
	var camera := get_viewport().get_camera_3d() if is_inside_tree() else null
	OCCLUSION_FADE.apply(model, _ally_fade, _ally_fade_state,
		camera.global_position if camera != null else model.global_position)


func _ally_hides_wild(ally_model: Node3D, needed: int) -> bool:
	if _wild == null or not is_instance_valid(_wild) or not _wild.has_method("model_pivot"):
		return false
	var camera := get_viewport().get_camera_3d() if is_inside_tree() else null
	if camera == null:
		return false
	var ally_bounds := _body_render_bounds(_ally_body)
	var wild_bounds := _body_render_bounds(_wild)
	var wild_model := _wild.call("model_pivot") as Node3D
	if ally_bounds.size.is_zero_approx() or wild_bounds.size.is_zero_approx() or wild_model == null:
		return false
	var wild_world: AABB = wild_model.global_transform * wild_bounds
	var base := Vector3(_wild.global_position.x, wild_world.position.y, _wild.global_position.z)
	return OCCLUSION_FADE.hidden_points(camera.global_position, base, wild_world.size.y,
		ally_model.global_transform, ally_bounds) >= maxi(1, needed)


func _clear_ally_fade() -> void:
	OCCLUSION_FADE.restore(_ally_fade_state)
	_ally_fade = 0.0
	_ally_hidden_for = 0.0
	_ally_clear_for = 0.0
	if _camera_rig != null and is_instance_valid(_camera_rig) and _camera_rig.has_method("set_composition_extra"):
		_camera_rig.call("set_composition_extra", 0.0)
	_ally_faded_model = null


## The extra distance the current moment of the fight calls for, uncapped by
## smoothing (that is `_update_combat_camera_framing()`'s job) but capped by
## `max_extra_distance` itself. The target derives one required distance from
## the combined live body envelopes and their gap at the configured FOV.
func _combat_camera_framing_target(framing: Dictionary) -> float:
	var max_extra := float(framing.get("max_extra_distance", 4.0))
	if _wild == null or not is_instance_valid(_wild):
		return _size_framing_extra(_ally_body, framing)
	var cfg: Dictionary = MATH.config().get("camera", {}) as Dictionary
	var vertical_fov: float = deg_to_rad(float(cfg.get("fov", 68.0)))
	var viewport: Vector2 = _camera_rig.get_viewport().get_visible_rect().size
	var aspect: float = viewport.x / maxf(viewport.y, 1.0)
	var horizontal_fov: float = 2.0 * atan(tan(vertical_fov * 0.5) * aspect)
	var fill: float = clampf(float(framing.get("horizontal_fill", 0.82)), 0.4, 0.95)
	var horizontal_tan: float = maxf(tan(horizontal_fov * 0.5) * fill, 0.01)
	var vertical_tan: float = maxf(tan(vertical_fov * 0.5) * fill, 0.01)
	var pivot: Vector3 = _ally_body.global_position + Vector3.UP * float(_camera_rig.get("_height"))
	pivot += Basis(Vector3.UP, float(_camera_rig.get("yaw"))).x * float(_camera_rig.get("_shoulder"))
	var rig_3d := _camera_rig as Node3D
	var basis: Basis = rig_3d.global_basis.orthonormalized()
	var required_distance: float = 0.0
	for body_variant in [_ally_body, _wild]:
		var body := body_variant as Node3D
		var measured: AABB = _body_render_bounds(body)
		var model: Node3D = body.call("model_pivot") as Node3D if body.has_method("model_pivot") else null
		if model == null or measured.size.is_zero_approx():
			continue
		for x in [0.0, 1.0]:
			for y in [0.0, 1.0]:
				for z in [0.0, 1.0]:
					var local: Vector3 = measured.position + measured.size * Vector3(x, y, z)
					var relative: Vector3 = model.global_transform * local - pivot
					var depth: float = relative.dot(basis.z)
					var horizontal: float = absf(relative.dot(basis.x)) / horizontal_tan
					var vertical: float = absf(relative.dot(basis.y)) / vertical_tan
					required_distance = maxf(required_distance, depth + maxf(horizontal, vertical))
	var base_distance := float(cfg.get("distance", 6.0))
	return clampf(required_distance - base_distance, 0.0, max_extra)


func _body_render_bounds(body: Node3D) -> AABB:
	if body == null or not is_instance_valid(body) or not body.has_method("model_pivot"):
		return AABB()
	var model := body.call("model_pivot") as Node3D
	if model == null:
		return AABB()
	var signature: String = "%s|%.5f|%.5f|%d" % [
		str(body.get("species_id")), float(body.get("_height")),
		float(body.get("_radius")), model.get_child_count()]
	var key: int = body.get_instance_id()
	var cached: Dictionary = _framing_bounds_cache.get(key, {}) as Dictionary
	if str(cached.get("signature", "")) == signature:
		var cached_bounds: AABB = cached.get("bounds", AABB())
		return cached_bounds
	var measured: AABB = RENDER_BOUNDS.measure(model)
	_framing_bounds_cache[key] = {"signature": signature, "bounds": measured}
	return measured


func _presentation_span(body: Node3D) -> float:
	if body == null or not is_instance_valid(body):
		return 0.0
	var current_height := float(body.get("_height"))
	var current_radius := float(body.get("_radius"))
	var footprint_allowance := maxf(float(body.get("_footprint_allowance")), 1.0)
	if current_height <= 0.0 or current_radius <= 0.0:
		return 0.0
	return maxf(current_height, current_radius * 2.0 * footprint_allowance)


## Creature scale is authored in metres, and ordinary bodies now range from a
## little over trainer height to 7.2m before any alpha/guardian multiplier is
## applied. Comparing a body only with its OWN species baseline made every
## ordinary body report 1x, so a 7.2m legendary received exactly the same frame
## as the smallest creature. The presentation span below uses the live height
## and the live footprint envelope (`radius * footprint_allowance`) instead:
## height catches tall upright bodies, footprint catches low/long animals such
## as Mirejaw. `apply_size_multiplier()` scales height and radius in place, so
## alphas and guardians naturally widen further through the same measurement.
func _size_framing_extra(body: Node3D, framing: Dictionary) -> float:
	if body == null or not is_instance_valid(body):
		return 0.0
	var presentation_span := _presentation_span(body)
	if presentation_span <= 0.0:
		return 0.0
	var reference := float(framing.get("size_reference_span_m", 5.0))
	var per_metre := float(framing.get("size_extra_per_metre", 0.5))
	return clampf((presentation_span - reference) * per_metre, 0.0,
		float(framing.get("max_extra_distance", 4.0)))


func _release_camera() -> void:
	_camera_framing_extra = 0.0
	_clear_ally_fade()
	_framing_bounds_cache.clear()
	if _camera_rig == null or not _camera_rig.has_method("set_target"):
		return
	_camera_rig.call("set_target", _player, {})


## --- the loop -------------------------------------------------------------

## Ticks in every state now, including INACTIVE.
##
## `_ready()` and `_finish()` used to `set_physics_process(false)`, which is why
## the INACTIVE branch below was a bare `pass` that nothing could ever have
## reached: with no fight running this node did not run at all. That was a real
## saving of nothing — the branch is three `is_action_just_pressed` polls — and
## it is what made the fight buttons silent rather than merely unavailable.
func _physics_process(delta: float) -> void:
	match state:
		State.ACTIVE:
			_tick_active(delta)
		State.RESOLVING:
			_resolve_timer -= delta
			if _resolve_timer <= 0.0:
				_finish()
		_:
			_refuse_combat_input()


## Say something when an attack button is pressed and there is no fight.
##
## `_read_player_input()` only ever runs from `_tick_active()`, so outside an
## encounter quick and charged attack produced no animation or message and read
## as broken rather than unavailable. Orb input is deliberately different: the
## 2026-09-12 owner playtest found the repeated "Can't throw an orb outside a
## fight" toast to be constant noise, so an out-of-fight throw press is silent.
##
## Answered through `Game.push_world_message()`, the one-shot toast
## `harvest_node.gd` already refuses a wrong-tool gather through, rather than a
## new UI; `game_menu.gd::_flash_refusal()` is the same idea on the menu's side
## of the screen.
##
## Deliberately NOT extended to RESOLVING. That state lasts about a second while
## the outcome banner is up and the player is watching a fight end, which is not
## the "is this button broken?" moment this exists for.
func _refuse_combat_input() -> void:
	# Nothing pressed is the case on very nearly every frame, so it is answered
	# before any node lookup.
	var attacking := Input.is_action_just_pressed("combat_quick") \
			or Input.is_action_just_pressed("combat_charged")
	if not attacking:
		return

	# Two of these buttons are shared with build mode (project.godot):
	#
	#   LMB / RMB  -> build_place / build_cancel
	#   LT / RT    -> build_rotate_left / build_rotate_right
	#
	# All four only mean anything with a placement armed, so one check covers
	# them, and a refusal that fires on top of the other thing is worse than
	# silence. `torch_place` used to need its own line here because it shared RT
	# with `combat_quick`; CONTROLLER-MAP took its pad binding away entirely, so
	# there is no longer a torch press to stand aside for.
	var game := get_node_or_null(^"/root/Game")
	if game == null:
		return
	if str(game.get("pending_build")) != "":
		return

	# The same "the player does not have free run of the world" gate
	# `playground_hud.gd::_world_hotkeys_enabled()` uses. A conversation, a
	# naming prompt or a fade puts the arbiter to sleep, and a refusal toast
	# under an open dialogue box is noise about a button nobody pressed for
	# this. No arbiter at all (a stripped test scene) reads as permissive.
	var arbiter := get_tree().get_first_node_in_group("interaction_arbiter")
	if arbiter != null and arbiter.has_method("enabled") and not bool(arbiter.call("enabled")):
		return

	game.call("push_world_message", "Can't attack outside a fight.")


func _tick_active(delta: float) -> void:
	_buffer_flee_while_input_unread(delta)
	if _hitstop_left > 0.0:
		_hitstop_left = maxf(0.0, _hitstop_left - delta)
		if _hitstop_left <= 0.0:
			_set_bodies_hitstopped(false)
		return
	_quick_cooldown = maxf(0.0, _quick_cooldown - delta)
	_charged_cooldown = maxf(0.0, _charged_cooldown - delta)
	_input_guard = maxf(0.0, _input_guard - delta)
	_buffer_left = maxf(0.0, _buffer_left - delta)
	_switch_lockout = maxf(0.0, _switch_lockout - delta)
	_tick_player_poise(delta)
	_tick_wind(delta)
	if _buffer_left <= 0.0:
		_buffered_attack = ""

	# OP-0905-17: framing runs every ACTIVE tick, not just at the discrete
	# takeover points `_take_camera()` fires from -- the fighters' separation
	# and either one's size can change continuously through a fight, and the
	# frame is meant to breathe with that rather than snap only when a switch
	# or an aim re-takes the camera.
	_update_combat_camera_framing(delta)
	_update_ally_occlusion_fade(delta)

	# OWNER PLAYTEST 2026-09-02 finding #6: aiming a catch is too hard because
	# the target keeps moving at normal combat speed through the whole window.
	# `throw_aim.gd` owns whether an aim is open; `wild_creature.gd` owns its
	# own movement speed. This is the one place that already talks to both
	# every tick, so it is the wire between them rather than either side
	# reaching for the other.
	if _wild != null and _wild.has_method("set_catch_aim_active"):
		_wild.call("set_catch_aim_active", bool(_throw.call("is_aiming")))

	if _catch_phase != CatchPhase.NONE:
		_tick_catch_resolution(delta)
		return

	_tick_action(delta)
	_drive_player_creature()
	if _input_guard <= 0.0:
		_read_player_input()
	_consume_buffered_attack()


## Wind-up, strike, recovery. The strike resolves at the END of the wind-up, and
## the recovery that follows is time the player cannot move — which is what the
## opponent is meant to punish.
func _tick_action(delta: float) -> void:
	if _action == Action.READY:
		return

	# Track the target through the wind-up. The creature is rooted from the press to
	# the end of recovery, and the connect test runs against the enemy's LIVE
	# position at the end of the wind-up — so a swing whose facing was frozen at
	# the press whiffed on any enemy that stepped sideways, and standing still
	# and pressing attack swung at whatever direction the creature last WALKED in.
	# Facing is free to give: range and timing stay the real skills, and the
	# owner's first-playtest verdict was "too hard to hit", not "too easy".
	if _action == Action.WINDUP and _ally_body != null and _wild != null:
		_ally_body.call("face_towards", _wild.call("centre"))

	_action_timer -= delta
	if _action_timer > 0.0:
		return

	if _action == Action.WINDUP:
		_resolve_player_strike()
		_action = Action.RECOVERY
		_action_timer = float(_pending_move.get("recovery", 0.2))
		state_changed.emit()
		return
	if _action == Action.STAGGER or _action == Action.BURST:
		if _action == Action.STAGGER:
			# Recovery restores resistance on both sides, not only opponents.
			_reset_player_poise()
		_action = Action.READY
		_pending_move = {}
		state_changed.emit()
		return

	_action = Action.READY
	_pending_move = {}
	state_changed.emit()


func _poise_config() -> Dictionary:
	return MATH.config().get("poise", {})


func _player_poise_max() -> float:
	return maxf(1.0, float(_poise_config().get("max", 40.0)))


func _enemy_poise_max() -> float:
	if _wild != null and _wild.has_method("combat_config"):
		return maxf(1.0, float((_wild.call("combat_config") as Dictionary).get(
			"poise_max", _poise_config().get("max", 40.0))))
	return maxf(1.0, float(_poise_config().get("max", 40.0)))


func _poise_crit_scale() -> float:
	return maxf(1.0, float(_poise_config().get("crit_scale", 1.5)))


func _reset_player_poise() -> void:
	_player_poise = _player_poise_max()
	_player_poise_quiet_left = 0.0
	_player_stagger_critical_ready = false


func _tick_player_poise(delta: float) -> void:
	if _action == Action.STAGGER:
		return
	_player_poise_quiet_left = maxf(0.0, _player_poise_quiet_left - delta)
	if _player_poise_quiet_left <= 0.0:
		_player_poise = minf(_player_poise_max(), _player_poise
			+ float(_poise_config().get("regen_per_second", 20.0)) * delta)


## --- COMBAT-2 Wind ---------------------------------------------------------

func _wind_config() -> Dictionary:
	return MATH.config().get("wind", {})


func _species_wind_config(creature: RefCounted) -> Dictionary:
	if creature == null:
		return {}
	var raw: Variant = SPECIES.definition(str(creature.get("species_id"))).get("wind")
	return raw if raw is Dictionary else {}


## Capacity is deliberately recomputed rather than cached: nourishment and
## bond can change while the instance remains in the party, and a timed cap
## buff added later should automatically participate without a migration.
func wind_capacity_for(creature: RefCounted) -> float:
	if creature == null:
		return 1.0
	var condition_cfg := CONDITION.config()
	return float(host_wind_profile({
		"species_id": str(creature.get("species_id")),
		"nourishment_fraction": CONDITION.nourishment_fraction(creature, condition_cfg),
		"bond_nodes": int(creature.call("bond_nodes")) if creature.has_method("bond_nodes") else 0,
		"wind_cap_scale": float(creature.call("buff_scale", "wind_cap")) if creature.has_method("buff_scale") else 1.0,
		"wind_regen_scale": float(creature.call("buff_scale", "wind_regen")) if creature.has_method("buff_scale") else 1.0,
	}).get("max", 1.0))


func wind_regen_for(creature: RefCounted) -> float:
	if creature == null:
		return 0.0
	var condition_cfg := CONDITION.config()
	return float(host_wind_profile({
		"species_id": str(creature.get("species_id")),
		"nourishment_fraction": CONDITION.nourishment_fraction(creature, condition_cfg),
		"bond_nodes": int(creature.call("bond_nodes")) if creature.has_method("bond_nodes") else 0,
		"wind_cap_scale": float(creature.call("buff_scale", "wind_cap")) if creature.has_method("buff_scale") else 1.0,
		"wind_regen_scale": float(creature.call("buff_scale", "wind_regen")) if creature.has_method("buff_scale") else 1.0,
	}).get("regen_per_second", 0.0))


## Host-safe Wind numbers from a deployment card. The card is a snapshot like
## attack/defence already are; every cost, threshold and species override is
## still resolved from the host's own checked-in config rather than per swing.
static func host_wind_profile(card: Dictionary) -> Dictionary:
	var wind_cfg: Dictionary = MATH.config().get("wind", {})
	var raw_species: Variant = SPECIES.definition(str(card.get("species_id", ""))).get("wind")
	var species_cfg: Dictionary = raw_species if raw_species is Dictionary else {}
	var condition_cfg := CONDITION.config()
	var bonuses: Dictionary = condition_cfg.get("combat_wind", {})
	var nourishment := clampf(float(card.get("nourishment_fraction", 0.0)), 0.0, 1.0)
	var empty_scale := clampf(float(bonuses.get("empty_cap_scale", 0.65)), 0.1, 1.0)
	var cap_scale := lerpf(empty_scale, 1.0, nourishment)
	if nourishment >= float(condition_cfg.get("nourishment", {}).get("fed_at", 0.55)):
		cap_scale += maxf(0.0, float(bonuses.get("fed_cap_bonus", 0.1)))
	var nodes := clampi(int(card.get("bond_nodes", 0)), 0, 5)
	cap_scale += nodes * maxf(0.0, float(bonuses.get("bond_cap_bonus_per_node", 0.025)))
	cap_scale *= clampf(float(card.get("wind_cap_scale", 1.0)), 0.1, 3.0)
	var base_max := maxf(1.0, float(species_cfg.get("max", wind_cfg.get("max", 100.0))))
	var regen := maxf(0.0, float(species_cfg.get(
		"regen_per_second", wind_cfg.get("regen_per_second", 18.0))))
	regen *= 1.0 + nodes * maxf(0.0, float(bonuses.get("bond_regen_bonus_per_node", 0.02)))
	regen *= clampf(float(card.get("wind_regen_scale", 1.0)), 0.1, 3.0)
	return {"max": maxf(1.0, base_max * cap_scale), "regen_per_second": regen}


func _initialize_wind() -> void:
	_party_wind.clear()
	_party_wind_quiet.clear()
	for member in _party:
		_party_wind.append(wind_capacity_for(member))
		_party_wind_quiet.append(0.0)


func _ensure_wind_slots() -> void:
	while _party_wind.size() < _party.size():
		var i := _party_wind.size()
		_party_wind.append(wind_capacity_for(_party[i]))
		_party_wind_quiet.append(0.0)


func _tick_wind(delta: float) -> void:
	_ensure_wind_slots()
	var delay := maxf(0.0, float(_wind_config().get("regen_delay", 0.6)))
	for i in _party.size():
		var member: RefCounted = _party[i]
		if member == null:
			continue
		var capacity := wind_capacity_for(member)
		_party_wind[i] = minf(_party_wind[i], capacity)
		# Only the active creature can be in a committed action. Bench members
		# are outside wind-up/recovery and recover normally.
		if i == _active_index and (_action == Action.WINDUP or _action == Action.RECOVERY \
				or _action == Action.BURST or _burst_awaiting_host):
			continue
		_party_wind_quiet[i] += delta
		if _party_wind_quiet[i] >= delay:
			_party_wind[i] = minf(capacity, _party_wind[i] + wind_regen_for(member) * delta)


func wind_cost(slot: String) -> float:
	var key: String = str({"quick": "quick_cost", "charged": "charged_cost",
		"skill": "skill_cost", "burst": "burst_cost"}.get(slot, ""))
	return maxf(0.0, float(_wind_config().get(key, 0.0))) if key != "" else 0.0


## Spend a configured action cost. False means the action was exhausted, not
## refused: the caller still starts it with the authored slow/weak penalty.
## `skill` and `burst` are valid today so their later milestones consume this
## one resource contract without COMBAT-2 implementing either action.
func consume_wind(slot: String) -> bool:
	_ensure_wind_slots()
	if _active_index < 0 or _active_index >= _party_wind.size():
		return false
	var cost := wind_cost(slot)
	var had_enough := _party_wind[_active_index] + 0.001 >= cost
	_party_wind[_active_index] = maxf(0.0, _party_wind[_active_index] - cost)
	_party_wind_quiet[_active_index] = 0.0
	return had_enough


func wind_value() -> float:
	_ensure_wind_slots()
	return _party_wind[_active_index] if _active_index >= 0 and _active_index < _party_wind.size() else 0.0


func wind_max() -> float:
	return wind_capacity_for(active_creature())


func wind_fraction() -> float:
	return clampf(wind_value() / maxf(1.0, wind_max()), 0.0, 1.0)


func wind_exhausted() -> bool:
	return bool(_pending_move.get("wind_exhausted", false))


## Every landed enemy hit breaks a player wind-up, even before the poise pool
## empties. This is the anti-mash rule: an attack committed into a visible tell
## is lost instead of resolving through the incoming blow.
func _take_player_poise_damage(amount: float) -> bool:
	var interrupted := _action == Action.WINDUP
	if interrupted:
		_pending_move = {}
		_buffered_attack = ""
		_buffer_left = 0.0
	_player_poise_quiet_left = float(_poise_config().get("regen_delay", 2.0))
	_player_poise = maxf(0.0, _player_poise - maxf(0.0, amount))
	if _player_poise > 0.0:
		if interrupted:
			_action = Action.READY
			_action_timer = 0.0
		return false
	_player_stagger_critical_ready = true
	if _action == Action.BURST and _ally_body != null \
			and _ally_body.has_method("cancel_combat_burst"):
		_ally_body.call("cancel_combat_burst")
	_action = Action.STAGGER
	_action_timer = float(_poise_config().get("stagger_seconds", 0.6))
	return true


func _consume_player_stagger_critical() -> bool:
	if _action != Action.STAGGER or not _player_stagger_critical_ready:
		return false
	_player_stagger_critical_ready = false
	return true


func _play_combat_flinch(body: Node3D, away: Vector3) -> void:
	if body.has_method("play_combat_flinch"):
		body.call("play_combat_flinch", away)
	else:
		body.call("play_hit")


func _hitstop_seconds(is_quick: bool, stagger_crit: bool) -> float:
	var cfg: Dictionary = MATH.config().get("hitstop", {})
	if stagger_crit:
		return maxf(0.0, float(cfg.get("stagger_crit_seconds", 0.12)))
	return maxf(0.0, float(cfg.get("quick_seconds" if is_quick else "charged_seconds",
		0.03 if is_quick else 0.07)))


func _set_bodies_hitstopped(active: bool) -> void:
	for body: Node3D in [_ally_body, _wild]:
		if body != null and is_instance_valid(body) and body.has_method("set_combat_hitstop"):
			body.call("set_combat_hitstop", active)


func _begin_hitstop(seconds: float) -> void:
	if seconds <= 0.0 or state != State.ACTIVE:
		return
	_hitstop_left = maxf(_hitstop_left, seconds)
	_set_bodies_hitstopped(true)


func _end_hitstop() -> void:
	_hitstop_left = 0.0
	_set_bodies_hitstopped(false)


func _resolve_player_strike() -> void:
	var creature := active_creature()
	if creature == null or _enemy == null or _ally_body == null or _wild == null:
		return

	# Stage B lane 4.C, protocol §5. In a session THIS PROCESS DOES NOT DECIDE.
	# What the player did -- the move, where they were, which way they faced --
	# goes to the host, and the answer comes back through
	# `apply_host_strike_verdict()`. The intent deliberately carries no damage
	# number and no target: that asymmetry is the protocol.
	#
	# Note what is NOT gated on being a client. The HOST submits through this
	# same door too, and its own intent is arbitrated by literally the same
	# lines a remote peer's is (`ledger_rpc.gd::_commit_here()`'s reasoning). A
	# "host fast path" here would be a second copy of the rules that eventually
	# disagrees with the first, and it would be the copy nobody ever tests
	# against a second peer.
	if _encounter_link != null:
		_submit_strike_intent()
		return

	var origin: Vector3 = _ally_body.call("centre")
	var facing: Vector3 = _ally_body.call("facing")
	var target: Vector3 = _wild.call("centre")

	_perform_player_strike(MATH.move_connects(_pending_move, origin, facing, target))


## §5. Send what the player did. `origin` is this process's own position for its
## own creature -- which the host uses ONLY for the latency tolerance, never to
## decide the hit (`encounter_host.gd::_retro_window_applies()` is the one line
## that reads it, and a lying origin can only ever cost this player its
## tolerance).
func _submit_strike_intent() -> void:
	var origin: Vector3 = _ally_body.call("centre")
	var facing: Vector3 = _ally_body.call("facing")
	var creature := active_creature()
	var is_quick: bool = bool(_pending_move.get("is_quick", false))
	var verdict: Dictionary = _encounter_link.call("submit_encounter_intent", {
		"kind": "strike_intent",
		"encounter_id": _encounter_id,
		# The move is named, not described. The host rebuilds the profile from
		# its OWN `combat.json` and its own two body radii
		# (`host_move_profile()`), so a peer cannot post itself a longer reach.
		"slot": "quick" if is_quick else "charged",
		"move_id": str(creature.move_quick if is_quick else creature.move_charged),
		"origin": [origin.x, origin.y, origin.z],
		"facing": [facing.x, facing.y, facing.z],
	})
	# `pending` is the ordinary answer on a CLIENT: the host has not spoken yet,
	# nothing is drawn and nothing is decremented until it does (§3), and the
	# answer arrives later through `apply_host_strike_verdict()`.
	#
	# On the HOST the answer is already here, because the host arbitrated its
	# own intent in the line above. It has to be rendered from here or it is
	# never rendered at all: the record broadcast would still move the health
	# bar, so the bug this branch prevents is the subtle one -- the host's own
	# blows landing silently, with no spark, no projectile and no `hit_landed`,
	# while a client's looked normal.
	if bool(verdict.get("pending", false)):
		return
	if bool(verdict.get("ok", false)):
		apply_host_strike_verdict(verdict.get("delta", {}) as Dictionary)
	else:
		note_encounter_refusal(verdict)


## The host has answered a `strike_intent` this process submitted.
##
## `payload` is the accepted delta plus the numbers the host rolled:
## `{"hit": bool, "damage": float, "hp": float, "hp_max": float, "killed": bool}`.
## A refusal never arrives here -- it goes to `_note_encounter_refusal()` -- so
## this function is only ever the performance of a decision already made.
func apply_host_strike_verdict(payload: Dictionary) -> void:
	if state != State.ACTIVE:
		return
	_sync_authoritative_wind(payload)
	if payload.has("hp") and _enemy != null:
		# §3: WRITTEN, not decremented. `take_damage()` here would apply the
		# host's blow on top of whatever the record broadcast already set, and
		# the bar would drop twice for one hit.
		_enemy.hp = clampf(float(payload["hp"]), 0.0, float(_enemy.max_hp))
	if _wild != null and _wild.has_method("sync_poise") and payload.has("poise"):
		_wild.call("sync_poise", float(payload["poise"]),
			bool(payload.get("staggered", false)), bool(payload.get("critical_ready", true)),
			float(payload.get("stagger_left", -1.0)))
	_perform_player_strike(bool(payload.get("hit", false)),
		float(payload.get("damage", 0.0)), bool(payload.get("killed", false)),
		bool(payload.get("stagger_crit", false)), bool(payload.get("stagger_triggered", false)))


## The performance of a strike, and -- solo -- the decision too.
##
## `connected` is whether it landed: solo that is this process's own
## `move_connects` on the line above; in a session it is the host's, tested
## against the host's own positions. `damage`/`killed` are supplied in a session
## and rolled here solo, so there is exactly ONE copy of the impact, the spark,
## the projectile, the energy gain and the two signals.
func _perform_player_strike(connected: bool, damage_override: float = -1.0,
		killed_override: bool = false, crit_override: bool = false,
		stagger_triggered_override: bool = false) -> void:
	var creature := active_creature()
	if creature == null or _enemy == null or _ally_body == null or _wild == null:
		return
	var origin: Vector3 = _ally_body.call("centre")
	var facing: Vector3 = _ally_body.call("facing")
	var target: Vector3 = _wild.call("centre")

	if not connected:
		attack_missed.emit(true)
		state_changed.emit()
		return

	var is_quick: bool = bool(_pending_move.get("is_quick", false))
	var stagger_crit := crit_override
	if damage_override < 0.0 and _wild.has_method("consume_stagger_critical"):
		stagger_crit = bool(_wild.call("consume_stagger_critical"))
	var move_id: String = creature.move_quick if is_quick else creature.move_charged
	var cfg: Dictionary = PROGRESSION.config()
	var is_best := _is_best(creature)
	var ability: Dictionary = SPECIES.best_creature_ability(creature.species_id) if is_best else {}
	# T3-TYPECHART. The move the player actually threw against the species the
	# foe actually is. `move_id` can be "" for a creature with no named move in
	# that slot (`creature_instance.gd` documents "" as a legitimate value), and
	# `type_of` then returns "" and the chart returns neutral — so a moveless
	# creature fights at exactly today's numbers rather than crashing or getting
	# free damage.
	var type_mult: float = TYPE_CHART.multiplier_dual(
		_moves.type_of(move_id), str(_enemy.creature_type), str(_enemy.get("secondary_type"))
	)
	# Solo this is the decision. In a session the host already rolled it with
	# ITS `_rng` and the number arrived with the verdict; re-rolling here would
	# give every peer a different fight.
	var damage: float = damage_override
	var killed: bool = killed_override
	if damage_override < 0.0:
		damage = MATH.rolled_damage(
			float(_pending_move.get("power", 9.0)),
			creature.effective_attack(cfg), _enemy.effective_defence(cfg), _rng.randf(),
			_moves.power(move_id), type_mult
		)
		if stagger_crit:
			damage *= _poise_crit_scale()
		killed = _enemy.take_damage(damage)
	var stagger_triggered := stagger_triggered_override
	if damage_override < 0.0 and not killed and _wild.has_method("apply_poise_damage"):
		var force_interrupt := not is_quick and enemy_is_winding_up() \
			and bool(_poise_config().get("interrupt_on_charged_into_telegraph", true))
		stagger_triggered = bool(_wild.call("apply_poise_damage", damage, force_interrupt))
	# W09-VFX: damage over the bar, so the spark can be sized to the blow.
	var hit_fraction: float = damage / maxf(1.0, float(_enemy.max_hp))
	_wild.call("add_impulse", facing, float(_pending_move.get("lunge", 3.6)) * 0.4)
	if killed:
		_wild.call("play_faint")
	else:
		_play_combat_flinch(_wild, facing)
	# Ranged moves draw their travel, and the impact waits for it to land. A
	# melee move has no travel to draw, so `launch` hands back null and the
	# burst goes off here exactly as it always did.
	var vfx: Dictionary = _pending_move.get("vfx", {}) as Dictionary
	var tint: Variant = Color(str(vfx["colour"])) if vfx.has("colour") else null
	var host: Node = _arena if _arena != null else _player.get_parent()
	# The bolt LEAVES the creature rather than starting inside it.
	#
	# `origin` is the body's centre, which is correct for `move_connects` above
	# and wrong for the thing the player watches: spawned there, the first third
	# of every flight is buried in the caster's own shell, and at the distance
	# the AI actually holds station that is most of the visible travel. A blind
	# round watching a bolt that had finally been made to render at all still
	# read it as a streak lying on the creature's back.
	#
	# Deliberately a SEPARATE value from `origin`. Moving `origin` itself would
	# move the point `move_connects` measures reach from, which is a change to
	# whether attacks land -- presentation must not reach into the hit math.
	var muzzle := origin
	if _ally_body.has_method("body_radius"):
		muzzle = origin + facing * float(_ally_body.call("body_radius"))
	var shot := PROJECTILE.launch(host, muzzle, target, vfx)
	if shot != null:
		var landing: Vector3 = target
		shot.connect("arrived", func() -> void: _flash_at(landing, not is_quick, tint, _wild, hit_fraction))
	else:
		_flash_at(_wild.call("centre"), not is_quick, tint, _wild, hit_fraction)

	# Energy is earned by CONNECTING, not by pressing. That is what makes
	# positioning matter to the charged attack rather than only to survival.
	if is_quick:
		creature.gain_energy_from_quick(creature.quick_energy_multiplier(is_best, ability))

	hit_effectiveness.emit(true, TYPE_CHART.classify(type_mult))
	if stagger_triggered:
		_announce_stagger(true)
	hit_landed.emit(true, damage)
	_begin_hitstop(_hitstop_seconds(is_quick, stagger_crit))
	state_changed.emit()
	if killed:
		_award_victory()
		_begin_resolve("won")


## --- Stage B lane 4.C: the host's half, and the record's ---------------------

## A host or a client was told no. One place, so the HUD's sentence and the
## print a log has to be read against cannot drift apart.
##
## `friendly_target` is the one this lane exists for and it is deliberately NOT
## silent: §5 says a silent no-op would pass a weaker test while hiding a
## targeting bug, and a player who cannot tell "I swung at my friend" from "the
## game dropped my input" will conclude the second.
func note_encounter_refusal(verdict: Dictionary) -> void:
	if str(verdict.get("kind", "")) == "burst_intent":
		_burst_awaiting_host = false
	_sync_authoritative_wind(verdict.get("delta", {}) as Dictionary)
	var code := str(verdict.get("code", ""))
	var reason := str(verdict.get("reason", ""))
	last_encounter_refusal = {"kind": str(verdict.get("kind", "")), "code": code,
		"reason": reason}
	print("[encounter] %s refused: %s (%s)" % [str(verdict.get("kind", "")), code, reason])
	if code == "friendly_target":
		attack_missed.emit(true)
	if not reason.is_empty():
		# Signal emission returns void in Godot 4.7, so it cannot be selected
		# with a value-producing ternary expression.
		if str(verdict.get("kind", "")) == "catch_attempt":
			catch_refused.emit(reason)
		else:
			encounter_refused.emit(code, reason)
	state_changed.emit()


## The host's copy of the record landed. §3: this is where a participant's HUD
## gets its hit points, and the ONLY place a client's opponent HP changes.
##
## Deliberately tolerant of arriving out of order or twice: `seq` is the host's
## commit counter and an older record is dropped rather than applied backwards,
## which is what stops a late packet from un-dropping the bar.
## `quiet` suppresses only the hit REACTION, never the number. The host applies
## its own strike's record change on the way through `_host_strike()` and then
## renders the strike properly a moment later, so without this the body would
## flinch twice for one blow.
func apply_encounter_record(rec: Dictionary, quiet: bool = false) -> void:
	if _encounter_link == null or str(rec.get("encounter_id", "")) != _encounter_id:
		return
	var incoming := int(rec.get("seq", 0))
	if incoming < _encounter_seq:
		return
	_encounter_seq = incoming
	# COMBAT-2. Observers receive every participant's absolute pool in this
	# record. The local participant also reconciles from it; the richer verdict
	# repeats the same absolute value and therefore cannot double-drain.
	var local_peer_method := "_local_peer_id" if _encounter_link.has_method("_local_peer_id") \
		else ("local_encounter_peer_id" if _encounter_link.has_method("local_encounter_peer_id") else "")
	if not local_peer_method.is_empty():
		var peer_id := int(_encounter_link.call(local_peer_method))
		var participants: Dictionary = rec.get("participants", {}) as Dictionary
		if participants.has(peer_id):
			_sync_authoritative_wind(participants[peer_id] as Dictionary)
	var opponent: Dictionary = rec.get("opponent", {}) as Dictionary
	var was_staggered := enemy_is_staggered()
	if _enemy != null and opponent.has("hp"):
		var hp_max := maxf(1.0, float(opponent.get("hp_max", _enemy.max_hp)))
		var hp := clampf(float(opponent["hp"]), 0.0, hp_max)
		var dropped: bool = hp < float(_enemy.hp) - 0.001
		_enemy.max_hp = hp_max
		_enemy.hp = hp
		if dropped and not quiet and _wild != null and hp > 0.0:
			# Somebody else's blow. The body reacts so a teammate's hits are
			# visible rather than the bar moving on its own.
			_play_combat_flinch(_wild, Vector3.ZERO)
		state_changed.emit()
	if _wild != null and _wild.has_method("sync_poise") and opponent.has("poise"):
		_wild.call("sync_poise", float(opponent["poise"]),
			bool(opponent.get("staggered", false)),
			bool(opponent.get("critical_ready", true)),
			float(opponent.get("stagger_left", -1.0)))
		if not quiet and not was_staggered and bool(opponent.get("staggered", false)):
			_announce_stagger(true)
		state_changed.emit()
	var phase := str(rec.get("phase", "active"))
	if phase == "done" and state == State.ACTIVE:
		# §9: the fight ended for this participant because the record says so --
		# somebody else landed the last blow, or won the catch.
		var won := float(opponent.get("hp", 1.0)) <= 0.0
		if won:
			_award_victory()
		_begin_resolve("won" if won else "lost")


func _sync_authoritative_wind(payload: Dictionary) -> void:
	if not payload.has("wind"):
		return
	_ensure_wind_slots()
	if _active_index < 0 or _active_index >= _party_wind.size():
		return
	var maximum := maxf(1.0, float(payload.get("wind_max", wind_max())))
	_party_wind[_active_index] = clampf(float(payload["wind"]), 0.0, maximum)


## §8 step 4. Another participant won the catch. This player's fight ends, and
## their HUD says WHO got it rather than silently stopping.
func note_caught_by(peer_id: int, species: String) -> void:
	if state != State.ACTIVE and state != State.RESOLVING:
		return
	caught_by_other.emit(peer_id, species)
	if state == State.ACTIVE:
		_begin_resolve("fled")


# --- what the HOST asks of this manager ------------------------------------------

## §5 steps 4-5, run on the host for ANY participant's strike -- its own
## included. `card` is the striker's creature as the host holds it (announced at
## deploy time or after a shrine selection changes, never per-swing: see
## `encounter_director.gd::_creature_card()`).
##
## Returns `{"damage", "killed", "hp", "hp_max", "type_mult"}`. The opponent is
## `_enemy`, the host's own live instance, so `take_damage()` here IS the record
## and there is no second copy of the number to keep in step.
func host_roll_damage(card: Dictionary, move_id: String, move_power: float,
		charged: bool = false) -> Dictionary:
	if _enemy == null:
		return {}
	var cfg: Dictionary = PROGRESSION.config()
	var type_mult: float = TYPE_CHART.multiplier_dual(
		_moves.type_of(move_id), str(_enemy.creature_type), str(_enemy.get("secondary_type"))
	)
	var damage: float = MATH.rolled_damage(
		move_power,
		maxf(1.0, float(card.get("attack", 1.0))),
		_enemy.effective_defence(cfg),
		_rng.randf(),
		_moves.power(move_id),
		type_mult
	)
	var stagger_crit := false
	if _wild != null and _wild.has_method("consume_stagger_critical"):
		stagger_crit = bool(_wild.call("consume_stagger_critical"))
		if stagger_crit:
			damage *= _poise_crit_scale()
	var killed: bool = _enemy.take_damage(damage)
	var stagger_triggered := false
	if not killed and _wild != null and _wild.has_method("apply_poise_damage"):
		var force_interrupt := charged and enemy_is_winding_up() \
			and bool(_poise_config().get("interrupt_on_charged_into_telegraph", true))
		stagger_triggered = bool(_wild.call("apply_poise_damage", damage, force_interrupt))
	return {"damage": damage, "killed": killed, "hp": _enemy.hp,
		"hp_max": _enemy.max_hp, "type_mult": type_mult,
		"poise": float(_wild.call("poise_fraction")) * _enemy_poise_max() if _wild != null and _wild.has_method("poise_fraction") else _enemy_poise_max(),
		"poise_max": _enemy_poise_max(),
		"staggered": bool(_wild.call("is_staggered")) if _wild != null and _wild.has_method("is_staggered") else false,
		"critical_ready": stagger_triggered, "stagger_crit": stagger_crit,
		"stagger_triggered": stagger_triggered,
		"stagger_left": float(_wild.call("stagger_seconds_left")) if _wild != null and _wild.has_method("stagger_seconds_left") else 0.0}


## The move profile the HOST tests a strike against: its own `combat.json`, its
## own move database, and the two bodies' own radii.
##
## Static, and the instance path below delegates to it, so there is exactly one
## copy of "what a quick attack reaches". A peer therefore cannot post itself a
## longer reach by describing its own move in the intent -- it names the move,
## and this decides what the move is.
static func host_move_profile(moves: RefCounted, block: String, move_id: String,
		mine: float, theirs: float, cooldown_multiplier: float = 1.0) -> Dictionary:
	var profile: Dictionary = MATH.config().get(block, {}).duplicate()
	if not move_id.is_empty() and moves != null:
		var move: Dictionary = moves.call("move", move_id)
		for key in ["range", "cone_degrees", "windup", "recovery", "cooldown", "lunge"]:
			if move.has(key):
				profile[key] = float(move[key])
		profile["vfx"] = move.get("vfx", {})
		profile["move_id"] = move_id
	profile = with_cooldown_multiplier(profile, cooldown_multiplier)
	return floor_reach_for_bodies(profile, mine, theirs)


## Realm powers may shorten a move's cooldown, but never lengthen it and never
## erase it. The host supplies the multiplier from its own validated relic
## definition; a client does not send a numeric value with each swing.
static func with_cooldown_multiplier(profile: Dictionary, multiplier: float) -> Dictionary:
	var resolved := profile.duplicate(true)
	if not resolved.has("cooldown"):
		return resolved
	var safe := clampf(multiplier, 0.1, 1.0)
	resolved["cooldown"] = maxf(0.05, float(resolved["cooldown"]) * safe)
	return resolved


## §5's other half, on the host: the opponent picks a target among the
## PARTICIPANTS rather than always swinging at whoever engaged first.
##
## Returns true when the blow was resolved against somebody else's creature and
## delivered to them; false when the host's own creature is the target, in which
## case `_on_enemy_strike()` falls through to the ordinary local path -- so the
## solo code below stays the one copy of what being hit looks like.
##
## The host tests the swing against ITS OWN copy of each participant's deployed
## body (4.B's `deployed_body_for()`), and rolls with its own `_rng` against the
## defence on that participant's announced card. Nothing here reads a client's
## report of anything.
func _host_resolve_enemy_strike_for_a_participant(cfg: Dictionary, origin: Vector3,
		facing: Vector3) -> bool:
	var pick: Dictionary = _encounter_link.call("host_pick_struck_participant",
		_encounter_id, cfg, origin, facing)
	if pick.is_empty():
		# Nobody in the arc. Reported as a miss by the host, for everybody: a
		# swing that connects with nobody is still a swing that happened.
		attack_missed.emit(false)
		state_changed.emit()
		return true
	if int(pick.get("peer_id", 0)) == int(_encounter_link.call("local_encounter_peer_id")):
		return false

	var card: Dictionary = pick.get("card", {}) as Dictionary
	var prog_cfg: Dictionary = PROGRESSION.config()
	var move_id := str(cfg.get("move_id", _enemy.move_quick))
	var type_mult: float = TYPE_CHART.multiplier_dual(
		_moves.type_of(move_id), str(card.get("creature_type", "")),
		str(card.get("secondary_type", ""))
	)
	var damage: float = MATH.rolled_damage(
		float(cfg.get("power", 8.0)),
		_enemy.effective_attack(prog_cfg),
		maxf(1.0, float(card.get("defence", 1.0))),
		_rng.randf(), _moves.power(move_id), type_mult
	)
	_encounter_link.call("host_deliver_enemy_hit", _encounter_id,
		int(pick.get("peer_id", 0)), {
			"damage": damage,
			"type_mult": type_mult,
			"move_id": move_id,
			"lunge": float(cfg.get("lunge", 3.4)),
		})
	return true


## The host's opponent hit THIS player's creature. The decision is already made;
## everything here is the performance of it, and it is deliberately the same
## presentation the solo path plays (`_flash_at`, the two signals, the faint
## handling) so being in a session does not change what a blow looks like.
func _incoming_owned_damage(amount: float) -> float:
	if not is_inside_tree():
		return amount
	var game := get_node_or_null("/root/Game")
	if game == null or game.get("realm_hearts") == null:
		return amount
	var power: Dictionary = game.realm_hearts.active_power()
	return amount * clampf(float(power.get("incoming_damage_multiplier", 1.0)), 0.0, 1.0)

func apply_host_enemy_hit(payload: Dictionary) -> void:
	if state != State.ACTIVE or _ally_body == null:
		return
	var creature := active_creature()
	if creature == null:
		return
	# Host rolls the base strike; this character's one active relic applies
	# once at the owning health mutation, also for a host on another island.
	var damage := _incoming_owned_damage(float(payload.get("damage", 0.0)))
	var move_id := str(payload.get("move_id", ""))
	var stagger_crit := _consume_player_stagger_critical()
	if stagger_crit:
		damage *= _poise_crit_scale()
	var killed: bool = creature.take_damage(damage)
	var stagger_triggered := false if killed else _take_player_poise_damage(damage)
	var facing: Vector3 = _ally_body.call("facing")
	_ally_body.call("add_impulse", -facing, float(payload.get("lunge", 3.4)) * 0.4)
	if killed:
		_ally_body.call("play_faint")
	else:
		_play_combat_flinch(_ally_body, -facing)
	_flash_at(_ally_body.call("centre"), false, VFX.tint_for_type(_moves.type_of(move_id)),
		_ally_body, damage / maxf(1.0, float(creature.max_hp)))
	hit_effectiveness.emit(false, TYPE_CHART.classify(float(payload.get("type_mult", 1.0))))
	if stagger_triggered:
		_announce_stagger(false)
	hit_landed.emit(false, damage)
	_begin_hitstop(_hitstop_seconds(true, stagger_crit))
	state_changed.emit()
	if killed:
		CONDITION.note_faint(creature, CONDITION.config())
		_handle_active_faint()


## The opponent's body and instance, for the host to read its own truth off.
## `enemy_body()` already exists; this is the other half.
func opponent_hp_pair() -> Array:
	if _enemy == null:
		return [0.0, 1.0]
	return [_enemy.hp, _enemy.max_hp]


## --- progression (D30) ------------------------------------------------------

## The fight has just been WON — `_enemy` is still valid (called before
## `_begin_resolve` starts tearing anything down). The creature that landed the
## killing blow gets the full award and a bond tick for the win; every other
## non-fainted party member gets `party_share` of the same award, matching
## the rest of the party having been "in the fight" without taking the risk.
## A fainted party member gets nothing — it did not fight.
func _award_victory() -> void:
	if _enemy == null:
		return
	if _victory_awarded:
		return
	_victory_awarded = true
	var cfg: Dictionary = PROGRESSION.config()
	var condition_cfg: Dictionary = CONDITION.config()
	var award: int = PROGRESSION.xp_award_for(_enemy.level, cfg)
	var share: int = PROGRESSION.party_share(award, cfg)

	last_xp_award.clear()
	for i in _party.size():
		var member: RefCounted = _party[i]
		if member == null or member.fainted:
			continue
		var amount: int = award if i == _active_index else share
		var levels_gained: int = member.gain_xp(amount, cfg)
		last_xp_award[member.label()] = {"xp": amount, "levels": levels_gained}
		# Prompt 67's history, recorded where the facts already are. This loop
		# already skips a fainted member ("it did not fight"), so the same rule
		# decides what counts as a battle fought -- one definition, one place.
		member.credit_battle_fought()  # battles_fought += 1 via bond_milestones.credit(), which ticks the feed
		if levels_gained > 0:
			member.set("levels_gained_with_you",
				int(member.get("levels_gained_with_you")) + levels_gained)
		# RG19-spec/D68: everyone who was in the fight gets the mood of having
		# won it, and a level-up is worth a little more on top. Paid to the
		# same members the XP is, on the same rule -- a fainted party member
		# gets neither, because it did not fight.
		CONDITION.note_victory(member, condition_cfg)
		for _level in levels_gained:
			CONDITION.note_level_up(member, condition_cfg)
	# OWNER-0901-BOND-MILESTONES: bond's "fighting together" milestone reads
	# `battles_fought` directly (just incremented above for every member who
	# fought), so a win needs no separate bond credit here any more -- see
	# bond_milestones.json's own comment. A freshly caught creature no longer
	# gets a bond head start either: milestone 0 is always "0/50", the same
	# concrete starting line as every creature caught before or after it.


## Movement is the dodge. The creature is driven straight from the stick, in camera
## space, exactly like the trainer — and is rooted while attacking.
func _drive_player_creature() -> void:
	if _ally_body == null:
		return
	if _action != Action.READY or _burst_awaiting_host:
		return
	# Aiming abandons your creature. It stops taking stick input while you line up the
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
	var direction: Vector3 = basis_value * Vector3(input.x, 0.0, input.y)
	# A Swift Tonic (creature_instance.buff_scale("speed")) drives the body
	# faster for its ninety seconds; at 1.0 the default-speed path is taken so
	# an unbuffed fight runs exactly the code it always did.
	var creature_for_speed := active_creature()
	var speed_scale: float = float(creature_for_speed.call("buff_scale", "speed")) \
			if creature_for_speed != null else 1.0
	if speed_scale != 1.0 and _ally_body.has_method("base_speed"):
		_ally_body.call("request_move", direction, float(_ally_body.call("base_speed")) * speed_scale)
	else:
		_ally_body.call("request_move", direction)


func _read_player_input() -> void:
	var creature := active_creature()
	if creature == null:
		return

	# While aiming, throw_aim.gd owns the input: Run cancels the aim rather than
	# ending the fight, and the attack buttons release the orb. Reading them here
	# too would make one press do two things.
	if bool(_throw.call("is_busy")):
		return
	if _burst_awaiting_host:
		return

	# CONTROLLER-MAP: "Fleeing is RB. Putting the creature away IS disengaging."
	# `combat_run` keeps its keyboard Escape and lost its pad button, so the pad
	# reaches this through `creature_recall` -- the same button that calls the
	# creature out and puts it away outside a fight.
	if _flee_pressed() or _flee_buffer_left > 0.0:
		_flee_buffer_left = 0.0
		try_flee()
		return

	# COMBAT-3. Pad A is `jump`; piloted creatures never jumped. Burst is
	# deliberately unbuffered: a press during attack/recovery/stagger cannot
	# cancel that action or turn into surprising movement later.
	if Input.is_action_just_pressed("jump"):
		request_burst(_combat_input_direction())
		return

	# Attack presses are RECORDED whatever state the creature is in, and fired by
	# `_consume_buffered_attack()` the moment it is ready. Throws stay
	# un-buffered: a throw is a deliberate mode change, and one that fires
	# half a second after the press feels like the game acting on its own.
	if Input.is_action_just_pressed("combat_charged"):
		_buffered_attack = "charged"
		_buffer_left = float(MATH.config().get("flow", {}).get("input_buffer", 0.3))
	elif Input.is_action_just_pressed("combat_quick"):
		_buffered_attack = "quick"
		_buffer_left = float(MATH.config().get("flow", {}).get("input_buffer", 0.3))

	if _action != Action.READY:
		return

	if _throw_pressed():
		_try_throw()


func _combat_input_direction() -> Vector3:
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if input.length_squared() <= 0.000001:
		return Vector3.ZERO
	var basis_value := Basis.IDENTITY
	if _camera_rig != null and _camera_rig.has_method("planar_basis"):
		basis_value = _camera_rig.call("planar_basis")
	var direction: Vector3 = basis_value * Vector3(input.x, 0.0, input.y)
	return direction.normalized()


## Public for the runtime pilot and focused regressions. Solo spends and moves
## immediately. A hosted fight submits only direction; the host owns approval,
## the Wind spend, and the absolute value returned in the verdict and record.
func request_burst(direction: Vector3) -> bool:
	if state != State.ACTIVE or _action != Action.READY or _burst_awaiting_host:
		return false
	if _throw == null or bool(_throw.call("is_busy")):
		return false
	var flat := Vector3(direction.x, 0.0, direction.z)
	if flat.length_squared() <= 0.000001:
		return false
	if wind_value() + 0.001 < wind_cost("burst"):
		return false
	flat = flat.normalized()
	if _encounter_link != null:
		_burst_awaiting_host = true
		var verdict: Dictionary = _encounter_link.call("submit_encounter_intent", {
			"kind": "burst_intent", "encounter_id": _encounter_id,
			"direction": [flat.x, 0.0, flat.z],
		})
		if bool(verdict.get("pending", false)):
			state_changed.emit()
			return true
		if bool(verdict.get("ok", false)):
			apply_host_burst_verdict(verdict.get("delta", {}) as Dictionary)
			return true
		_burst_awaiting_host = false
		note_encounter_refusal(verdict)
		return false
	consume_wind("burst")
	return _begin_burst(flat, _burst_config(), 0)


func _burst_config() -> Dictionary:
	return MATH.config().get("burst", {}) as Dictionary


func _begin_burst(direction: Vector3, spec: Dictionary, action_id: int) -> bool:
	if _ally_body == null or not _ally_body.has_method("begin_combat_burst"):
		return false
	if action_id > 0 and action_id <= _last_burst_action:
		return false
	var distance := maxf(0.0, float(spec.get("distance", 3.0)))
	var duration := maxf(0.01, float(spec.get("duration", 0.2)))
	# A same-process hosted adapter may already have started the authoritative
	# body before its synchronous verdict reaches this manager. Adopt that live
	# movement instead of restarting it or leaving the manager READY.
	var body_started := action_id > 0 and _ally_body.has_method("combat_burst_active") \
		and bool(_ally_body.call("combat_burst_active"))
	if not body_started:
		body_started = bool(_ally_body.call("begin_combat_burst", direction,
			distance, duration, action_id))
	if not body_started:
		return false
	_last_burst_action = maxi(_last_burst_action, action_id)
	_action = Action.BURST
	_action_timer = duration
	_pending_move = {"kind": "burst", "distance": distance, "duration": duration,
		"action": action_id}
	_buffered_attack = ""
	_buffer_left = 0.0
	state_changed.emit()
	return true


func apply_host_burst_verdict(payload: Dictionary) -> void:
	_burst_awaiting_host = false
	if state != State.ACTIVE:
		return
	_sync_authoritative_wind(payload)
	var raw: Variant = payload.get("direction", [])
	var direction := Vector3.ZERO
	if raw is Array and raw.size() >= 3:
		direction = Vector3(float(raw[0]), float(raw[1]), float(raw[2]))
	_begin_burst(direction, payload, int(payload.get("accepted_action", 0)))


## The throw button, on both devices.
##
## CONTROLLER-MAP put the orb on the hotbar and throws it with interact, so
## `combat_throw` no longer has a pad binding of its own; X reaches this
## through `interact`. Keyboard F still works, and is what the on-screen
## `throw` glyph names for a desktop player.
func _throw_pressed() -> bool:
	return Input.is_action_just_pressed("combat_throw") \
			or Input.is_action_just_pressed("interact")


## Keep a disengage press made on a tick whose input `_read_player_input()`
## will not read. Aiming is left alone: there Run cancels the aim
## (`throw_aim.gd` owns it), and buffering it too would make one press do two
## things. A catch in progress is left alone too; the orb decides that fight.
func _buffer_flee_while_input_unread(delta: float) -> void:
	# Hitstop also freezes `_input_guard`, so the buffer holds too: a guard plus
	# a hit or two landing in it could otherwise outlast `flow.flee_buffer`.
	if _hitstop_left <= 0.0:
		_flee_buffer_left = maxf(0.0, _flee_buffer_left - delta)
	var unread := _hitstop_left > 0.0 or _input_guard > 0.0 or _burst_awaiting_host
	if not unread or _catch_phase != CatchPhase.NONE or bool(_throw.call("is_busy")):
		return
	if _flee_pressed():
		_flee_buffer_left = float(MATH.config().get("flow", {}).get("flee_buffer", 0.4))


## The disengage button, on both devices. See `_read_player_input`.
func _flee_pressed() -> bool:
	return Input.is_action_just_pressed("combat_run") \
			or Input.is_action_just_pressed("creature_recall")


## CL-W5(b), owner directive 2026-09-04-B amendment A-1: "you shouldn't be able
## to leave a fight with another character once it's started. still should be
## able to with a wild creature."
##
## Wild fights keep the exit exactly as they had it, which is what keeps the
## softlock D-0904B-5 worried about off the table: the player is never sealed
## into an unwinnable encounter they did not accept. A TRAINER fight is a
## commitment the moment it is accepted, and the only other way out stays what
## it already was -- the whole party fainting, which
## `encounter_director.gd`/the death satchel already resolve.
##
## `_enemy_owned` (R8.1) is the same flag that already refuses a catch on
## somebody else's creature, so "whose creature is this" is asked once and
## answered in one place.
func can_flee() -> bool:
	return not _enemy_owned


## Act on the disengage button. Split out of `_read_player_input()` so the
## refusal is testable without driving `Input` through a whole standing world:
## the decision, the message and the resolve all live here rather than inside a
## frame handler.
##
## Returns true only when the fight actually ended.
func try_flee() -> bool:
	if not can_flee():
		_refuse_flee()
		return false
	_begin_resolve("fled")
	return true


## What the player is told when the disengage button refuses, or "" when it
## would not refuse. Pure, and separate from the push below, so the SENTENCE
## can be checked without a `Game` autoload to push it through -- the unit
## runner starts none (`tests/run_tests.gd` runs under `--script`), and a rule
## whose only test is "a function returned false" passes just as happily when
## the player is told nothing at all.
func flee_refusal() -> String:
	return "" if can_flee() else FLEE_REFUSED_MESSAGE


## Say why the button did nothing, through the same one-shot toast
## `_refuse_combat_input()` above already answers a dead fight button with. An
## unexplained dead button reads as a broken build -- a blind playtest reached
## exactly that verdict about the three combat buttons once already, which is
## why that function exists.
func _refuse_flee() -> void:
	if not is_inside_tree():
		return
	var game := get_node_or_null(^"/root/Game")
	if game == null:
		return
	game.call("push_world_message", flee_refusal())


## Fire a buffered attack press once the creature is ready for it.
##
## Split from `_read_player_input` so a press made during recovery fires on the
## frame recovery ends rather than waiting for the next press. The charged
## branch consumes the buffer even when energy is short — a refused press
## should stay refused, not retry itself every frame until it surprises you.
func _consume_buffered_attack() -> void:
	if _action != Action.READY or _buffered_attack == "" or _input_guard > 0.0 \
			or _burst_awaiting_host:
		return
	if bool(_throw.call("is_busy")):
		return
	var creature := active_creature()
	if creature == null:
		return

	if _buffered_attack == "charged":
		if _charged_cooldown > 0.0:
			return
		_buffered_attack = ""
		if creature.spend_charged():
			var charged := _move_profile("player_charged", str(creature.move_charged))
			charged["is_quick"] = false
			_start_action(charged, "charged")
			_charged_cooldown = float(charged.get("cooldown", 1.2))
		return

	if _quick_cooldown > 0.0:
		return
	_buffered_attack = ""
	var quick := _move_profile("player_quick", str(creature.move_quick))
	quick["is_quick"] = true
	_start_action(quick, "quick")
	_quick_cooldown = float(quick.get("cooldown", 0.45))


## The config block for a slot, with the named move's own numbers laid over it.
##
## Every one of the 26 moves used to be `power: 1.0` and nothing else, so a
## named move contributed a display string and a multiplier of exactly one:
## mechanically all quick attacks were the same attack and all charged attacks
## were the same attack. That is the ground under the owner's report that TMs
## "aren't upgrades" -- there was nothing for an upgrade to be better THAN.
##
## A move may now override reach, arc, timing and commitment. Anything it does
## not name falls through to `combat.json`'s block exactly as before, so a move
## with no overrides still plays precisely as it did. `power` is deliberately
## NOT merged here: it stays a multiplier applied at damage time
## (`combat_math.gd::rolled_damage`), because the block's own `power` is what a
## plain hit is worth and the move scales it.
func _move_profile(block: String, move_id: String) -> Dictionary:
	var profile: Dictionary = MATH.config().get(block, {}).duplicate()
	if not move_id.is_empty() and _moves != null:
		var move: Dictionary = _moves.call("move", move_id)
		for key in ["range", "cone_degrees", "windup", "recovery", "cooldown", "lunge"]:
			if move.has(key):
				profile[key] = float(move[key])
		# Carried so `_start_action` and the impact can read how this move should
		# look without going back to the database for it.
		profile["vfx"] = move.get("vfx", {})
		profile["move_id"] = move_id
	return with_cooldown_multiplier(profile, active_move_cooldown_multiplier())


## The single personal relic selection is the solo authority. In multiplayer
## this same selection is announced in the deployment card and refreshed only
## on a selection revision; the host then resolves the number from its own
## config and placed-world state.
func active_move_cooldown_multiplier() -> float:
	if not is_inside_tree():
		return 1.0
	var game := get_node_or_null(^"/root/Game")
	if game == null or game.get("realm_hearts") == null:
		return 1.0
	var power: Dictionary = game.realm_hearts.call("active_power")
	return clampf(float(power.get("cooldown_multiplier", 1.0)), 0.1, 1.0)


func _start_action(move: Dictionary, wind_slot: String = "") -> void:
	var resolved := move.duplicate(true)
	var exhausted := not wind_slot.is_empty() and not consume_wind(wind_slot)
	resolved = with_wind_exhaustion(resolved, exhausted)
	resolved["wind_exhausted"] = exhausted
	_pending_move = _with_reach_for_the_bodies(resolved)
	_action = Action.WINDUP
	_action_timer = float(_pending_move.get("windup", 0.18))
	# Face and lunge at the START of the wind-up, not at the strike. The lunge
	# used to fire on the same frame as the connect test, and an impulse only
	# changes velocity — position is integrated NEXT physics frame — so the
	# lunge could never help the swing that fired it; it was pure
	# follow-through, and the charged attack whiffed structurally against any
	# repositioning enemy. Applied here, it integrates across the whole
	# wind-up and genuinely closes the gap the test will be run over. The
	# animation starts here too, so the body moves when the motion does.
	if _ally_body != null and _wild != null:
		_ally_body.call("face_towards", _wild.call("centre"))
		_ally_body.call("add_impulse", _ally_body.call("facing"), float(_pending_move.get("lunge", 3.6)))
		_ally_body.call("play_attack")
	state_changed.emit()


static func with_wind_exhaustion(move: Dictionary, exhausted: bool) -> Dictionary:
	var resolved := move.duplicate(true)
	if not exhausted:
		return resolved
	var wind_cfg: Dictionary = MATH.config().get("wind", {})
	resolved["windup"] = float(resolved.get("windup", 0.18)) \
		* float(wind_cfg.get("exhausted_windup_scale", 2.0))
	resolved["power"] = float(resolved.get("power", 9.0)) \
		* float(wind_cfg.get("exhausted_power_scale", 0.6))
	return resolved


## Floor a move's reach by the two creatures' actual sizes.
##
## Reach is measured centre to centre, and the configured 2.6m was written when
## every creature was the same capsule. Against a large opponent, two bodies
## that are merely touching are already further apart than that, so the player's
## attack whiffs at point-blank range — which reads as the game dropping the
## input, and is the single complaint most likely to end a playtest.
##
## The wild creature applies the same floor to its own attacks. Both sides space
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

	return floor_reach_for_bodies(move, mine, theirs)


## The reach floor itself, static so the host's own profile builder
## (`host_move_profile()`) and this instance path are one copy rather than two
## that eventually disagree about what a quick attack reaches.
static func floor_reach_for_bodies(move: Dictionary, mine: float, theirs: float) -> Dictionary:
	var clearance: float = float(MATH.config().get("enemy", {}).get("body_clearance", 1.35))
	var adjusted := move.duplicate()
	adjusted["range"] = maxf(float(move.get("range", 2.6)), (mine + theirs) * clearance + 0.5)
	return adjusted


## Both authority paths present the same beat; repeated records reuse its ring.
func _announce_stagger(on_enemy: bool) -> void:
	var body: Node3D = _wild if on_enemy else _ally_body
	var cfg: Dictionary = MATH.config().get("stagger_feedback", {})
	var existing: Variant = _stagger_glows.get(on_enemy)
	var already_visible: bool = is_instance_valid(existing) and not existing.is_queued_for_deletion()
	if not already_visible and body != null and is_instance_valid(body) and bool(cfg.get("enabled", true)):
		var host: Node = _arena if _arena != null else body.get_parent()
		if host != null:
			var radius := float(cfg.get("radius", 1.1))
			if body.has_method("body_radius"):
				radius = maxf(radius, float(body.call("body_radius")) * 1.2)
			var feet := body.global_position if body.is_inside_tree() else body.position
			var glow := TELEGRAPH_GLOW.begin(host, feet,
				Color(str(cfg.get("colour", "#70ddff"))), radius, 0.6)
			glow.call("follow_state", body,
				enemy_is_staggered if on_enemy else player_is_staggered)
			_stagger_glows[on_enemy] = glow
	staggered.emit(on_enemy)


## The warning follows the real wind-up, including hitstop and interruptions.
func _on_enemy_telegraph(seconds: float) -> void:
	var cfg: Dictionary = MATH.config().get("telegraph", {})
	if not bool(cfg.get("enabled", true)) or _wild == null:
		return
	var host: Node = _arena if _arena != null else _player.get_parent()
	var glow := TELEGRAPH_GLOW.begin(
		host,
		_wild.global_position,
		Color(str(cfg.get("colour", "#ff5a3c"))),
		float(cfg.get("radius", 1.1)),
		seconds
	)
	glow.call("follow_state", _wild, enemy_is_winding_up)


## The opponent announces its swing when its wind-up completes; whether it
## connects is decided here, by the same arithmetic the player's attacks use.
func _on_enemy_strike() -> void:
	if state != State.ACTIVE:
		return
	var creature := active_creature()
	if creature == null or _enemy == null:
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

	# F04: a named CHARGER's lunge has already travelled by the time it strikes
	# (`wild_creature.gd`, combat.json `charger_lunge`), and it reports whether
	# its body actually reached the target on the way. That report replaces the
	# cone test below, so a player who read the lane and stepped off it is
	# missed. Every other opponent returns nothing here and strikes exactly as
	# before: impulse, attack animation, cone test.
	var lunge: Dictionary = _wild.call("take_lunge_outcome") \
		if _wild.has_method("take_lunge_outcome") else {}
	var travelled := not lunge.is_empty()
	if not travelled:
		_wild.call("add_impulse", facing, float(cfg.get("lunge", 3.4)))
		_wild.call("play_attack")

	# Stage B lane 4.C, protocol §2 and §5, and 4.B's handover H1.
	#
	# On a CLIENT this body is a local stand-in: Terrain3D FULL_GAME collision
	# is unimplemented and wild creatures are not replicated, so this process's
	# wilds are its own simulation and have already drifted from the host's.
	# Letting one of them decide that this player just took eleven damage would
	# be a peer authoring an outcome from a position no other process holds --
	# exactly what §2 forbids, and in the direction that hurts the player.
	# The host swings for everybody; the answer arrives at
	# `apply_host_enemy_hit()`.
	if _encounter_link != null:
		if not bool(_encounter_link.call("is_encounter_host")):
			return
		if travelled and not bool(lunge.get("contact", false)):
			# The charge reached nobody: a miss for everybody, decided here.
			attack_missed.emit(false)
			state_changed.emit()
			return
		# On contact the host still picks who was struck, from where the
		# charging body actually stopped.
		if _host_resolve_enemy_strike_for_a_participant(cfg, origin, facing):
			return

	var connects: bool = bool(lunge.get("contact", false)) if travelled \
		else MATH.move_connects(cfg, origin, facing, target)
	if not connects:
		attack_missed.emit(false)
		state_changed.emit()
		return

	# Ordinary wilds retain their quick-move fallback.  An opt-in named attack
	# freezes its move id in the body's combat profile at telegraph start, and
	# that same id owns type, multiplier, VFX and host-delivered damage.
	var move_id := str(cfg.get("move_id", _enemy.move_quick))
	var prog_cfg: Dictionary = PROGRESSION.config()
	var is_best := _is_best(creature)
	var ability: Dictionary = SPECIES.best_creature_ability(creature.species_id) if is_best else {}
	# T3-TYPECHART, the other half. The chart is symmetric across both call
	# sites deliberately: what makes a matchup a real decision is the EXCHANGE
	# ratio -- dealing 1.25 while taking 0.80 is a 1.56x swing, where a chart
	# that only ever helped the player would be a flat damage buff with a type
	# name on it. `move_id` is the frozen selected attack, or the quick fallback.
	var type_mult: float = TYPE_CHART.multiplier_dual(
		_moves.type_of(move_id), str(creature.creature_type),
		str(creature.get("secondary_type"))
	)
	var damage: float = MATH.rolled_damage(
		float(cfg.get("power", 8.0)),
		_enemy.effective_attack(prog_cfg), creature.effective_defence(prog_cfg, is_best, ability),
		_rng.randf(), _moves.power(move_id), type_mult
	)
	damage = _incoming_owned_damage(damage)
	var stagger_crit := _consume_player_stagger_critical()
	if stagger_crit:
		damage *= _poise_crit_scale()
	var killed: bool = creature.take_damage(damage)
	var stagger_triggered := false if killed else _take_player_poise_damage(damage)
	_ally_body.call("add_impulse", facing, float(cfg.get("lunge", 3.4)) * 0.4)
	if killed:
		_ally_body.call("play_faint")
	else:
		_play_combat_flinch(_ally_body, facing)
	# W09-VFX: the foe's blow carries its own element's hue, sized to the bite it took.
	_flash_at(_ally_body.call("centre"), false, VFX.tint_for_type(_moves.type_of(move_id)),
		_ally_body, damage / maxf(1.0, float(creature.max_hp)))

	hit_effectiveness.emit(false, TYPE_CHART.classify(type_mult))
	if stagger_triggered:
		_announce_stagger(false)
	hit_landed.emit(false, damage)
	_begin_hitstop(_hitstop_seconds(true, stagger_crit))
	state_changed.emit()
	if killed:
		# RG19-spec/D68. A creature carried off the field is neither happy nor
		# still rested; `note_faint` owns both, so no caller has to remember
		# the second half.
		CONDITION.note_faint(creature, CONDITION.config())
		_handle_active_faint()


## The active creature was just reduced to 0 HP. GATE-F-LEG-S04 (owner
## directive): against a TRAINER (`_enemy_owned`, R8.1's "somebody else's
## creature" flag) the fight goes on with whoever else is still standing,
## exactly as it already does when the OPPONENT's creature falls
## (`_on_trainer_round_ended`'s "next one steps up") — the whole point being
## that a person fields a ROSTER, not one animal, and the player's own bench
## is the same kind of roster. A WILD encounter is unaffected and still ends
## here: D32's original "no auto-switch-on-faint" reasoning still holds for
## one creature against one animal; it never held for a trainer's whole team
## against the player's, which the tournament's own Gate F evidence measured
## losing a round to a single hit the player could not have dodge-cancelled
## out of, with four fully healthy party members sitting unused on the bench
## the whole time. Split out from `_on_enemy_strike()` so a test can drive
## this decision directly against `_party`/`_active_index`/`_enemy_owned`,
## the same bare-manager style `test_combat_progression.gd` already uses for
## the rest of the switch seam, without needing a live wild/ally body node.
func _handle_active_faint() -> void:
	var next_index := _next_switchable_index(1) if _enemy_owned else -1
	if next_index >= 0:
		_activate_party_member(next_index)
		creature_switched.emit(next_index)
		state_changed.emit()
		return
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
## `tint` overrides the impact's colour when the move that landed carries one
## of its own. Quick-vs-charged still decides SIZE and duration -- an expensive
## move should still burst bigger -- but the hue now says which element hit
## you. Before this the only per-move visual difference in the entire game was
## a three-colour hairline on a HUD button, so a Water creature and an Air
## creature landing a blow produced the identical orange ring.
## W09-VFX (CL-A2): `struck` is the body the blow landed on and
## `damage_fraction` the damage over its max HP. Both damage sites pass them,
## and this is the ONE place the spark, the body flash and -- when the blow
## emptied the bar -- the KO puff are fired from; `combat_vfx.gd` reads the
## struck instance's `fainted` flag here rather than needing a hook of its own.
func _flash_at(where: Vector3, charged: bool, tint: Variant = null, struck: Node3D = null, damage_fraction: float = 0.0) -> void:
	# Parented into the WORLD, not to this manager. CombatManager is a plain
	# Node, and a Node3D hung under one is outside the 3D transform chain: the
	# burst was created correctly twelve times in a row and rendered none of
	# them. The arena is a Node3D that already exists for exactly the length of
	# the fight, so it also cleans these up on its way out.
	var host: Node = _arena if _arena != null else _player.get_parent()
	VFX.hit(host, where, tint, charged, struck, damage_fraction)
	_nudge_camera_on_landing(charged)
	var cfg: Dictionary = MATH.config().get("impact", {})
	if not bool(cfg.get("enabled", true)):
		return
	var key := "charged" if charged else "quick"
	var spec: Dictionary = cfg.get(key, {})
	# The move's elemental hue when it has one, warmed halfway toward the
	# config's own impact colour so a hit still reads as a HIT rather than as a
	# coloured light -- the brightness of the burst is what sells contact, and a
	# fully saturated blue ring loses it.
	var colour := Color(str(spec.get("colour", "#ffd27a")))
	if tint != null:
		colour = (tint as Color).lerp(colour, 0.35)
	FLASH.burst(
		host,
		where,
		colour,
		float(spec.get("radius", 1.5)),
		float(spec.get("duration", 0.34)),
		float(spec.get("strength", 1.0)),
		# N14: the attack path reads the same opt-in key from `combat.json`'s own
		# `impact.quick` / `impact.charged`. Neither sets it today, so every blow
		# in the game draws exactly the spike it always has.
		float(spec.get("spike_softness", 0.0))
	)


func _nudge_camera_on_landing(charged: bool) -> void:
	if charged and _camera_rig != null and _camera_rig.has_method("nudge_combat_impact"):
		_camera_rig.call("nudge_combat_impact", MATH.config().get("charged_camera_nudge", {}))


## --- catching -------------------------------------------------------------

## Legality is checked before the aim opens, not after the orb lands.
##
## §15 says a faint ENDS the capture opportunity. That is a refusal, not a very
## low chance, and telling the player before they spend an orb and a vulnerable
## second of aiming is the difference between a rule and a punishment. R8.1
## adds the second refusal — somebody else's creature — on the same terms and
## through the same door, so no route into a throw can miss either.
func _try_throw() -> void:
	if _enemy == null:
		return
	var allowed: bool = CATCH.can_be_caught(_enemy.fainted, _enemy_owned)
	_throw.call("try_begin_aim", allowed, _catch_refusal())
	state_changed.emit()


## Why this throw is being refused. Ownership is named FIRST: a trainer's
## creature that has also just fainted is still refused for the reason that
## will never change, not for the one that would have expired.
func _catch_refusal() -> String:
	if _enemy_owned:
		return "You can't catch a trained creature"
	return "%s is out cold — too late to catch it" % _enemy.display_name


func _on_orb_struck(_target: Node3D, offset: float) -> void:
	if state != State.ACTIVE or _enemy == null:
		return

	# Re-checked at the moment of impact as well as before the aim: the opponent
	# can faint to your creature's attack while the orb is still in the air, and an
	# orb that lands on a corpse must not catch it. The ownership half is
	# unreachable from here (`_try_throw` already refused to open the aim) and
	# is checked anyway — a second route into a throw is exactly the kind of
	# thing a later milestone adds without reading this file.
	if not CATCH.can_be_caught(_enemy.fainted, _enemy_owned):
		catch_refused.emit(_catch_refusal() if _enemy_owned
			else "%s fainted before the orb landed" % _enemy.display_name)
		_throw.call("clear_orb")
		_take_camera()
		state_changed.emit()
		return

	var radius := 0.5
	if _wild != null and _wild.has_method("body_radius"):
		radius = float(_wild.call("body_radius"))

	# Stage B lane 4.C, protocol §8. In a session THIS PROCESS DOES NOT DECIDE
	# whether the creature was caught, and it does not get to decide how close
	# the orb passed either: the host re-derives the closest approach from the
	# launch parameters with its OWN position for the creature
	# (`catch_arbiter.gd`), rolls with its own `_rng`, and arbitrates the race.
	# `offset` above -- this process's own measurement, taken against this
	# process's own body -- is deliberately NOT sent.
	if _encounter_link != null:
		_submit_catch_attempt()
		return

	# The decision, made once. Everything after this dramatises it.
	#
	# R4.9: the orb id has to be the one `throw_aim.gd` actually SPENT for
	# this throw, not whatever tier is best right now — the satchel already
	# lost that orb by the time the strike resolves, and re-querying "best
	# available" here could silently price a greater-orb throw at the basic
	# multiplier (or vice versa) if the two ever disagree.
	var decision: Dictionary = CATCH.resolve(
		SPECIES.catch_rate(_enemy.species_id),
		_enemy.hp_fraction(),
		str(_throw.call("thrown_orb_id")),
		offset,
		radius,
		_rng.randf(),
		_personal_catching_bonus()
	)
	if _tutorial_catch_failure_bound >= 0:
		decision = CATCH.apply_failure_bound(
			decision, _tutorial_catch_failures, _tutorial_catch_failure_bound
		)
		if not bool(decision["caught"]):
			_tutorial_catch_failures += 1
	_play_catch_decision(decision)


## The performance of a catch decision, whoever made it: this process solo, or
## the host in a session. One copy, so a networked catch and a solo one are the
## same beat -- same flash, same absorb, same camera glide, same wobble.
func _play_catch_decision(decision: Dictionary) -> void:
	if _wild == null or _enemy == null:
		return
	_catch_succeeded = bool(decision.get("caught", false))
	_catch_shakes_total = int(decision.get("shakes", 0))
	_catch_chance_resolved = float(decision.get("chance", 0.0))
	_catch_index = 0

	# The performance: a flash says the throw landed, the creature is drawn in
	# toward the hanging orb, and the camera starts its glide into the close-up
	# the rest of the sequence plays through. The old presentation was
	# `_wild.visible = false` — one frame, no event, and a HUD label counting
	# dots. Everything else about "catching is still bad" starts there.
	var cfg: Dictionary = CATCH.config().get("resolve", {})
	var absorb := float(cfg.get("absorb_seconds", 0.45))
	var orb: Node3D = _throw.call("resting_orb")
	var strike_point: Vector3 = orb.global_position if orb != null \
		else (_wild.call("centre") if _wild != null else Vector3.ZERO)
	_catch_flash("strike", strike_point)
	if _wild != null and _wild.has_method("play_absorb"):
		_wild.call("play_absorb", strike_point, absorb)
	elif _wild != null:
		_wild.visible = false
	# The "this is your opponent" marker has no opponent to mark while the
	# creature is in the orb; left on, it floats over empty grass all wobble.
	if _target_marker != null and is_instance_valid(_target_marker):
		_target_marker.visible = false
	_watch_the_orb(orb)

	_catch_phase = CatchPhase.ABSORB
	# The orb hangs for `absorb` and then has to fall; the timeout is a backstop
	# for a strike over ground the drop raycast never finds, not the schedule.
	# A shared claim's complete authored presentation must fit inside the host's
	# monotonic lease. Once the host accepted this hit, a missing/rest-failing
	# local orb is presentation loss rather than authority to hold the fight an
	# extra 2.5 seconds. Solo and Water keep the original ground-rest backstop.
	_catch_timer = absorb if _catch_finish_requires_host else absorb + 2.5
	_catch_presentation_last_ms = _catch_now_ms() if _catch_finish_requires_host else 0
	state_changed.emit()


## §8. Send the shot that was taken -- where it left the hand, which way it
## went, and which orb was actually spent -- and wait.
##
## `throw_aim.gd::last_launch()` is the source for all three because
## `_release()` is the one place they exist: `origin` has had `_spawn_forward`
## added and `forward` has been through the launch assist, and re-deriving
## either here would describe a different throw from the one in the air.
func _submit_catch_attempt() -> void:
	var launch: Dictionary = _throw.call("last_launch")
	if launch.is_empty():
		# No throw was recorded, so there is nothing honest to arbitrate. The
		# orb is already spent; say so rather than resolving a catch off a
		# guess.
		catch_refused.emit("that throw got lost")
		_throw.call("clear_orb")
		_take_camera()
		state_changed.emit()
		return
	_catch_awaiting_host = true
	_catch_attempt_serial += 1
	_catch_awaiting_attempt = _catch_attempt_serial
	_catch_attempt_requires_exact = _encounter_link != null \
		and _encounter_link.has_method("confirm_shared_catch_finish") \
		and not _encounter_link.has_method("confirm_catch_finish")
	_catch_claim_id = ""
	_catch_finish_requires_host = false
	var intent := {
		"kind": "catch_attempt",
		"encounter_id": _encounter_id,
		"attempt": _catch_awaiting_attempt,
		"launch_point": launch.get("launch_point", []),
		"direction": launch.get("direction", []),
		"orb_id": str(launch.get("orb_id", "")),
	}
	var verdict: Dictionary = _encounter_link.call("submit_encounter_intent", intent)
	# The host's own throw is arbitrated in that call and answered here; a
	# client's `pending` answer arrives later on the same function. Same reason
	# the strike path above does it: without this the host would win a race and
	# never see the wobble.
	if not bool(verdict.get("pending", false)):
		apply_host_catch_verdict(verdict)


## The host has arbitrated the throw. On `ok` the delta is
## `catch_math.gd::resolve()`'s own decision -- `caught`, `chance`, `shakes` --
## made once, on the host, and everything from here is the performance of it,
## which is byte-for-byte the sequence the solo path plays.
##
## On a refusal the orb is still spent (§8 step 5: "the orb is spent either
## way") and the player is told which of the three things happened: somebody
## else's orb got there first, it is not a creature that can be caught, or the
## fight had already moved on.
func apply_host_catch_verdict(verdict: Dictionary) -> bool:
	if not _catch_awaiting_host:
		return false
	if _catch_attempt_requires_exact and (str(verdict.get("encounter_id", "")) != _encounter_id \
			or int(verdict.get("attempt", 0)) != _catch_awaiting_attempt):
		return false
	_catch_awaiting_host = false
	_catch_attempt_requires_exact = false
	if not bool(verdict.get("ok", false)):
		_catch_claim_id = ""
		_catch_finish_requires_host = false
		note_encounter_refusal(verdict)
		_throw.call("clear_orb")
		if _wild != null and _wild.has_method("play_breakout"):
			_wild.call("play_breakout", 0.2)
		elif _wild != null:
			_wild.visible = true
		if _target_marker != null and is_instance_valid(_target_marker):
			_target_marker.visible = true
		_take_camera()
		state_changed.emit()
		return true
	var delta: Dictionary = verdict.get("delta", {}) as Dictionary
	_catch_claim_id = str(delta.get("claim_id", ""))
	_catch_finish_requires_host = _encounter_link != null \
		and _encounter_link.has_method("confirm_shared_catch_finish") \
		and not _encounter_link.has_method("confirm_catch_finish")
	if _catch_finish_requires_host and _catch_claim_id.is_empty():
		_catch_finish_requires_host = false
		note_encounter_refusal({"kind": "catch_attempt", "code": "missing_claim",
			"reason": "The host did not identify this catch safely."})
		_throw.call("clear_orb")
		_take_camera()
		state_changed.emit()
		return true
	_play_catch_decision(delta)
	return true


func _on_orb_missed(message: String) -> void:
	if state != State.ACTIVE:
		return
	# A clean miss is not a failed catch. It costs an orb and the moment, and it
	# gets its own message, because "you missed" and "it broke out" are different
	# things to have just done. The message is built by the orb's own flight --
	# how near it came, and what ended it -- so a graze and a throw that was
	# never close no longer read identically.
	catch_refused.emit(message)
	_take_camera()
	state_changed.emit()


## A cancelled aim hands the camera straight back to the creature. A released throw
## keeps the aim camera — watching your own orb arc away is the shot — and
## `_on_orb_struck` / `_on_orb_missed` decide where it goes next.
func _on_aim_exited() -> void:
	if state != State.ACTIVE:
		return
	if bool(_throw.call("is_busy")):
		return
	_take_camera()


func _tick_catch_resolution(delta: float) -> void:
	var cfg: Dictionary = CATCH.config().get("resolve", {})
	if _catch_finish_requires_host:
		var now_ms := _catch_now_ms()
		var wall_delta := 0.0 if _catch_presentation_last_ms <= 0 else \
			maxf(0.0, float(now_ms - _catch_presentation_last_ms) / 1000.0)
		_catch_presentation_last_ms = now_ms
		_tick_shared_catch_resolution(wall_delta, cfg)
		return
	_catch_timer -= delta

	match _catch_phase:
		CatchPhase.ABSORB:
			# Wait for the orb to actually be on the ground; the first shake of
			# an orb still falling would read as the animation firing early.
			var orb: Node3D = _throw.call("resting_orb")
			var rested: bool = orb != null and bool(orb.call("is_resting"))
			if rested or _catch_timer <= 0.0:
				_catch_phase = CatchPhase.WAIT
				_catch_timer = float(cfg.get("first_shake_delay", 0.9))
		CatchPhase.WAIT:
			if _catch_timer <= 0.0:
				_catch_phase = CatchPhase.SHAKING
				_catch_timer = 0.0
		CatchPhase.SHAKING:
			if _catch_timer > 0.0:
				return
			if _catch_index < _catch_shakes_total:
				_catch_index += 1
				var orb: Node3D = _throw.call("resting_orb")
				if orb != null and orb.has_method("shake"):
					orb.call("shake", _catch_index)
				orb_shook.emit(_catch_index)
				_catch_timer = float(cfg.get("shake_interval", 0.85))
				return
			# All shakes performed. The held breath before the verdict — this
			# pause existed in config from the start and was silently ignored:
			# the verdict used to land on the same frame as the final shake.
			_catch_phase = CatchPhase.VERDICT
			_catch_timer = float(cfg.get("settle_pause", 0.8))
		CatchPhase.VERDICT:
			if _catch_timer <= 0.0:
				_finish_catch()


## A shared claim is leased on the host's monotonic clock, so its presentation
## must reach `catch_finished` on that same unscaled clock. Carrying negative
## timer remainder across phase boundaries prevents a slow frame from adding
## one whole extra phase of lease time. Solo and Water catches retain their
## existing delta-driven presentation above.
func _tick_shared_catch_resolution(elapsed: float, cfg: Dictionary) -> void:
	_catch_timer -= elapsed
	for _step in 16:
		match _catch_phase:
			CatchPhase.ABSORB:
				var orb: Node3D = _throw.call("resting_orb")
				var rested := orb != null and bool(orb.call("is_resting"))
				if not rested and _catch_timer > 0.0:
					return
				var over := minf(0.0, _catch_timer)
				_catch_phase = CatchPhase.WAIT
				_catch_timer = float(cfg.get("first_shake_delay", 0.9)) + over
			CatchPhase.WAIT:
				if _catch_timer > 0.0:
					return
				_catch_phase = CatchPhase.SHAKING
			CatchPhase.SHAKING:
				if _catch_timer > 0.0:
					return
				if _catch_index < _catch_shakes_total:
					_catch_index += 1
					var orb: Node3D = _throw.call("resting_orb")
					if orb != null and orb.has_method("shake"):
						orb.call("shake", _catch_index)
					orb_shook.emit(_catch_index)
					_catch_timer += float(cfg.get("shake_interval", 0.85))
				else:
					_catch_phase = CatchPhase.VERDICT
					_catch_timer += float(cfg.get("settle_pause", 0.8))
			CatchPhase.VERDICT:
				if _catch_timer > 0.0:
					return
				_finish_catch()
				return
			_:
				return


func _catch_now_ms() -> int:
	return Time.get_ticks_msec()


func _finish_catch() -> void:
	var confirmed_by_shared_host := _catch_finish_requires_host
	var confirmed_by_realm := not confirmed_by_shared_host and _encounter_link != null \
		and _encounter_link.has_method("confirm_catch_finish")
	var confirmation: Dictionary = {}
	var finish_terminal := false
	if confirmed_by_shared_host:
		if _encounter_link != null and _encounter_link.has_method("confirm_shared_catch_finish"):
			confirmation = _encounter_link.call("confirm_shared_catch_finish",
				_encounter_id, _catch_claim_id)
		else:
			confirmation = {"ok": false, "pending": false, "caught": false,
				"code": "host_unavailable", "reason": "The host disconnected before confirming the catch."}
		if bool(confirmation.get("pending", false)):
			return
		if not bool(confirmation.get("ok", false)):
			note_encounter_refusal(confirmation)
			finish_terminal = str(confirmation.get("code", "")) in [
				"finish_timeout", "host_unavailable"]
		_catch_succeeded = bool(confirmation.get("ok", false)) \
			and bool(confirmation.get("caught", false))
		if _catch_succeeded:
			var canonical := CAPTURE_CODEC.decode(confirmation.get("creature", {}))
			if canonical == null:
				_catch_succeeded = false
				note_encounter_refusal({"kind": "catch_finished", "code": "invalid_capture",
					"reason": "The host could not deliver the caught creature safely."})
			else:
				_enemy = canonical
	elif confirmed_by_realm:
		confirmation = _encounter_link.call("confirm_catch_finish", _encounter_id)
		if bool(confirmation.get("pending", false)):
			return
		_catch_succeeded = bool(confirmation.get("caught", false))
	_catch_claim_id = ""
	_catch_finish_requires_host = false
	_catch_presentation_last_ms = 0
	_catch_phase = CatchPhase.NONE
	var cfg: Dictionary = CATCH.config().get("resolve", {})
	var orb: Node3D = _throw.call("resting_orb")
	if finish_terminal:
		_throw.call("clear_orb")
		_take_camera()
		_begin_resolve("fled")
		return

	# §8. The wobble is over, so the fight stops being held for this thrower --
	# either it goes `resolving` because they won it, or it goes back to
	# `active` and anybody may throw again. Reported rather than inferred: the
	# host cannot see a client's animation finish, and
	# `catch_arbitration_window_ms` is the backstop for the case where this
	# message never arrives, not the schedule.
	if _encounter_link != null and not confirmed_by_realm and not confirmed_by_shared_host:
		_encounter_link.call("submit_encounter_intent", {
			"kind": "catch_finished",
			"encounter_id": _encounter_id,
			"caught": _catch_succeeded,
			"species_id": str(_enemy.species_id) if _enemy != null else "",
		})

	if _catch_succeeded:
		# The seal: the orb blooms warm and stays glowing, the camera stays on
		# it through the fight's resolve pause, and the orb is only freed with
		# the rest of the fight in `_finish()`.
		if orb != null:
			if orb.has_method("seal"):
				orb.call("seal")
			_catch_flash("caught", orb.global_position)
			# W09-VFX: the seal is a reward, not only a verdict.
			VFX.catch_success(_arena if _arena != null else _player.get_parent(), orb.global_position)
		catch_resolved.emit(true, _catch_index)
		_begin_resolve(OUTCOME_CAUGHT)
		return

	# It broke out: a sharper, whiter burst covers the orb vanishing, and the
	# creature pops back to full size with a shove — an event, not a toggle.
	# No free damage either way: the cost of a failed catch is the orb and the
	# seconds you spent standing still, which is quite enough.
	if orb != null:
		_catch_flash("breakout", orb.global_position)
	_throw.call("clear_orb")
	if _wild != null:
		if _wild.has_method("play_breakout"):
			_wild.call("play_breakout", float(cfg.get("breakout_pop_seconds", 0.35)))
		else:
			_wild.visible = true
		if _ally_body != null:
			var away: Vector3 = _wild.global_position - _ally_body.global_position
			_wild.call("add_impulse", away, 2.5)
		# Re-engage from scratch: the creature takes the same "read the
		# situation" beat it takes when a fight opens (`first_attack_delay`)
		# instead of swinging on the frame it reappears.
		_wild.call("set_engaged", true, _ally_body)
	if _target_marker != null and is_instance_valid(_target_marker):
		_target_marker.visible = true
	_take_camera()
	catch_resolved.emit(false, _catch_index)
	state_changed.emit()


## Point the camera at the resting orb for the resolution close-up. The rig
## glides rather than cuts (`resolve_camera.retarget_lag`), so the shot arrives
## while the orb is still dropping and settles with it.
func _watch_the_orb(orb: Node3D) -> void:
	if orb == null or _camera_rig == null or not _camera_rig.has_method("set_target"):
		return
	_camera_rig.call("set_target", orb, CATCH.config().get("resolve_camera", {}))


## One of the catch's three flashes (catching.json `vfx`): strike, caught,
## breakout. Same impact_flash.gd primitive the attacks use, so it reads on
## both renderers and advances on the physics clock.
func _catch_flash(key: String, at: Vector3) -> void:
	var spec: Dictionary = CATCH.config().get("vfx", {}).get(key, {})
	if spec.is_empty():
		return
	var host: Node = _arena if _arena != null else _player.get_parent()
	FLASH.burst(
		host,
		at,
		Color(str(spec.get("colour", "#ffd27a"))),
		float(spec.get("radius", 1.2)),
		float(spec.get("duration", 0.35)),
		float(spec.get("strength", 1.0)),
		# N14: opt-in, from the spec's own data. 0.0 (absent) is the flat spike
		# every attack has always drawn -- see impact_flash.gd's `_spike_softness`.
		float(spec.get("spike_softness", 0.0))
	)


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
	_end_hitstop()
	# W12-COMPANION-0904. The result beat: the fight is decided and nothing is
	# piloting the ally body any more, but the arena still stands and the
	# creature is still where it won. `companion_presence.gd`'s guard lets its
	# victory reaction (and only that one) run during this pause -- celebrating
	# after `_finish()` would mean celebrating back beside the trainer with the
	# fight already gone.
	if outcome == "won":
		get_tree().call_group(&"companion_presence", "on_event", "victory")
	var flow: Dictionary = MATH.config().get("flow", {})
	_resolve_timer = float(flow.get("run_delay", 0.5)) if outcome == "fled" \
		else float(flow.get("faint_pause", 1.6))
	if _wild != null and not _realm_owned_opponent:
		_wild.call("set_engaged", false)
	state_changed.emit()


func _finish() -> void:
	_end_hitstop()
	state = State.INACTIVE
	_disconnect_opponent_callbacks(_wild)

	# §9. Leaving is `disengage`: the fight survives if anybody else is still in
	# it, and it is the LAST participant leaving that ends it -- with the HP it
	# has, because a creature that heals instantly because everyone walked away
	# is an exploit. Submitted before the link is dropped, obviously.
	if _encounter_link != null:
		_encounter_link.call("submit_encounter_intent", {
			"kind": "disengage", "encounter_id": _encounter_id,
		})
		unbind_encounter()
	_encounter_seq = 0

	_throw.call("disarm")
	if _ally_body != null:
		_ally_body.visible = false
		_ally_body.set("arena", null)
	# Freed with the arena it was parented to; only the stale reference needs
	# clearing here.
	_target_marker = null
	if _arena != null:
		_arena.queue_free()
		_arena = null
	_release_camera()

	exited.emit(_outcome)
	_realm_owned_opponent = false
	state_changed.emit()


## --- switching (D32) --------------------------------------------------------
##
## Voluntary mid-combat switching. LOGIC ONLY here — the header comment has
## named `_active_index` into `_party` as this seam since M2, and this is that
## later milestone. No input is read here and no selector is drawn: a future
## HUD milestone binds `party_cycle` (one LB press cycles) to the functions
## below. D32's hold-to-open-a-selector chord was retired by CONTROLLER-MAP.
##
## GATE-F-LEG-S04 (owner directive, in response to the tournament's own
## Gate F evidence): a TRAINER fight now auto-switches to the next available
## party member the instant the active one faints, rather than ending the
## whole battle right there — see `_on_enemy_strike()`'s use of
## `_next_switchable_index()`. D32's original "no auto-switch-on-faint" rule
## still stands for a WILD encounter (`_enemy_owned == false`): a wild fight
## is one creature against one creature and still ends exactly as it always
## has. The distinction is `_enemy_owned` (R8.1), already threaded through
## `begin()` for the unrelated "catching a trainer's creature is refused"
## rule — the same flag answers "is this a person, not an animal" that the
## owner's own framing asked for.

## Party indices, in `_party` order, that are alive and not the one currently
## piloted — what a switch selector has to offer.
func switchable_indices() -> Array[int]:
	var out: Array[int] = []
	for i in _party.size():
		if i == _active_index:
			continue
		var member: RefCounted = _party[i]
		if member != null and _can_take_the_field(member):
			out.append(i)
	return out


## Can this creature take the field RIGHT NOW? Fainted is the obvious half.
## RESTING is the other, and it was missing from every switch path in this file
## while every other place in the project already had it:
## `begin()` above refuses to start a fight on a resting creature, and
## `autoload/party.gd::cycle_active()` -- the exploration-side cycle, whose own
## comment is "wraps and skips anything that cannot take the field" -- skips
## both. Only the in-fight switch disagreed.
##
## GATE-F-LEG-S10AB, 2026-08-31. That disagreement is reachable in exactly one
## place in the chapter, and it is inside this lane's own segment: the Hall's
## recovery point (`stronghold.json`'s `recovery` block) is the only creature
## bed standing within metres of a fight. Park a creature in it, walk nine
## metres to the elite, and LB would pull the sleeping creature straight out of
## the bed and into the fight -- still flagged `resting`, so
## `game_state.gd::_tick_creature_bed_recovery()` keeps healing it every frame
## WHILE it fights, and `creature_bed.gd` still lists it as the bed's occupant.
## A creature that is both asleep and in a boss fight is not a state any of the
## three systems involved thinks it can be in.
func _can_take_the_field(member: RefCounted) -> bool:
	return not member.fainted and not bool(member.get("resting"))


## The index `cycle_active(direction)` would land on, or -1 if nobody
## switchable exists. Factored out of `cycle_active` so the involuntary
## post-faint auto-switch in `_handle_active_faint()` can reuse the exact same
## traversal order (nearest-next, wrapping, skipping anyone who cannot take
## the field -- see `_can_take_the_field()`) without going through
## `request_switch()`'s VOLUNTARY-switch guards (`can_switch()`'s
## aim/catch/commitment/lockout checks) — none of which make sense for a
## switch the player did not choose and cannot refuse.
func _next_switchable_index(direction: int) -> int:
	var size := _party.size()
	if size < 2:
		return -1
	var step: int = 1 if direction >= 0 else -1
	var i := _active_index
	for _n in size - 1:
		i = ((i + step) % size + size) % size
		var member: RefCounted = _party[i]
		if member != null and _can_take_the_field(member):
			return i
	return -1


## Is a voluntary switch allowed RIGHT NOW? Mirrors the guards the fight
## already applies elsewhere: aiming owns the controls (`_drive_player_creature`'s
## own comment), a resolving catch pauses the whole fight
## (`is_resolving_catch`'s own comment), and `player_is_committed()` refuses
## it mid-swing — switching out from under a wind-up would refund the very
## commitment a charged attack is supposed to cost. The lockout stops a tap
## being spammed into a stutter of creatures.
func can_switch() -> bool:
	return is_fighting() \
		and not is_aiming() \
		and not is_resolving_catch() \
		and not player_is_committed() \
		and _switch_lockout <= 0.0


## The next (`direction > 0`) or previous (`direction < 0`) switchable party
## member from the active one, wrapping around the whole party order and
## skipping anyone who cannot take the field (fainted, or asleep in a creature
## bed -- see `_can_take_the_field`). Delegates to `request_switch` so cycling and any
## future direct-pick selector share one path in and one set of guards.
func cycle_active(direction: int) -> bool:
	var index := _next_switchable_index(direction)
	if index < 0:
		return false
	return request_switch(index)


## Switch the piloted creature to party index `index`. Guarded rather than
## clamped: an illegal request is refused outright (returns false), never
## partially applied.
func request_switch(index: int) -> bool:
	if not can_switch():
		return false
	if index < 0 or index >= _party.size() or index == _active_index:
		return false
	var member: RefCounted = _party[index]
	if member == null or not _can_take_the_field(member):
		return false

	_activate_party_member(index)
	_switch_lockout = float(MATH.config().get("switch", {}).get("lockout_seconds", 1.5))
	creature_switched.emit(index)
	state_changed.emit()
	return true


## The body-swap core. Re-points `_active_index` at `index` and, if the
## incoming creature is a different species OR a different shiny status
## (OF27) from whatever `_ally_body` is currently wearing, re-skins that
## SAME body through `setup()` — the
## identical call `encounter_director._spawn_ally_body()` makes for a brand
## new creature. There is deliberately only one piloted body in a fight (M2's "one
## of yours" scope never grew a second one), so a switch re-casts it rather
## than instancing another; the incoming creature takes over at the exact position
## and facing the old body already had, because that body never moved.
##
## The switched-OUT creature keeps its hp/energy exactly as the fight left them —
## no reset, no heal; only the piloted identity changes. Action/cooldown state
## resets to READY because it belongs to whichever creature is being piloted, and
## it is safe to zero here: `can_switch()`'s `player_is_committed()` guard
## already refused this call unless the fight was between actions.
func _activate_party_member(index: int) -> void:
	var incoming: RefCounted = _party[index]
	_active_index = index

	if _ally_body != null and (str(_ally_body.get("species_id")) != incoming.species_id
			or bool(_ally_body.get("shiny")) != bool(incoming.get("shiny"))):
		_ally_body.call("setup", incoming.species_id, bool(incoming.get("shiny")))

	_action = Action.READY
	_action_timer = 0.0
	_pending_move = {}
	_quick_cooldown = 0.0
	_charged_cooldown = 0.0
	_buffered_attack = ""
	_buffer_left = 0.0
	_burst_awaiting_host = false
	_reset_player_poise()


## --- readouts for the HUD -------------------------------------------------
##
## The HUD asks; it is never pushed to. A HUD that keeps its own copy of the
## fight can disagree with the fight, and the first time that happens it costs
## an afternoon.

func quick_ready() -> bool:
	return _action == Action.READY and _quick_cooldown <= 0.0


func charged_ready() -> bool:
	var creature := active_creature()
	return creature != null and creature.can_use_charged() \
		and _action == Action.READY and _charged_cooldown <= 0.0


## The centre-to-centre reach the currently piloted creature gets for a move
## slot. Combat drivers (the smoke pilots today, an accessibility auto-pilot
## tomorrow) must ask the same size-aware rule the impact resolver uses. A
## hard-coded two metres becomes unreachable as soon as two large creatures'
## non-overlapping capsules already stand farther apart than that.
func combat_move_reach(slot: String) -> float:
	var creature := active_creature()
	if creature == null:
		return 0.0
	var block := "player_charged" if slot == "charged" else "player_quick"
	var move_id := str(creature.get("move_charged")) if slot == "charged" \
		else str(creature.get("move_quick"))
	return float(_with_reach_for_the_bodies(_move_profile(block, move_id)).get("range", 0.0))


## True while the player's creature is committed and cannot move.
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


func enemy_is_staggered() -> bool:
	return _wild != null and _wild.has_method("is_staggered") and bool(_wild.call("is_staggered"))


func enemy_poise_fraction() -> float:
	return float(_wild.call("poise_fraction")) if _wild != null and _wild.has_method("poise_fraction") else 1.0


func player_poise_fraction() -> float:
	return clampf(_player_poise / _player_poise_max(), 0.0, 1.0)


func player_is_staggered() -> bool:
	return _action == Action.STAGGER


func outcome() -> String:
	return _outcome


func is_aiming() -> bool:
	return _throw != null and bool(_throw.call("is_aiming"))


func orbs_left() -> int:
	return int(_throw.call("stock")) if _throw != null else 0


## R4.9: which orb tier a throw right now would actually use — the HUD's own
## orb cluster reads this so it never names/shows a tier the player is not
## about to spend.
func current_orb_id() -> String:
	return str(_throw.call("current_orb_id")) if _throw != null else "orb_basic"


## True from the orb striking to the verdict. The fight is paused around it:
## neither fighter acts, because a creature landing a hit on an orb that is
## deciding whether it caught something is nonsense. (The wild creature's own physics
## is off for the duration — it is inside the orb.)
## The chance the LANDED throw actually resolved at, including the placement
## bonus for where the orb really struck. Valid from the strike until the next
## throw.
##
## The capture reticle's contract animation reads this so the ring that
## collapses onto the resting orb shows the number the roll USED, not the
## number the aim last advertised. That closes the loop the shake count alone
## could not: before this, a player who clipped the edge saw the aim's
## dead-centre figure, then a wobble, then a breakout, with nothing anywhere in
## the sequence telling them the throw had been worth much less than the ring
## said. "Was I unlucky or was I sloppy" was unanswerable, and a skill mechanic
## you cannot learn from is a slot machine.
func last_catch_chance() -> float:
	return _catch_chance_resolved


func is_resolving_catch() -> bool:
	return _catch_phase != CatchPhase.NONE


## The odds THIS throw would resolve at right now, for the aim HUD.
##
## It used to pass `offset = 0.0` unconditionally -- the dead-centre best case,
## whatever the player was actually pointing at. That is a bigger deal than it
## reads: `catching.json`'s own `accuracy_bonus` spans `centre_bonus` 1.45 to
## `edge_bonus` 0.80, an 1.81x spread the config itself calls "the ONLY reason
## the aiming skill exists". So the reticle showed 73% over a sliver-HP
## Bramblebun while a throw that clipped its edge resolved at 40%, and it
## showed that number whether or not the player was lined up at all.
##
## `catch_math.gd`'s header states this project's own rule about the wobble:
## the outcome is decided once, and "dramatising a lie is exactly what makes
## catch animations feel cheap". Promising odds the throw will not use is the
## same lie one step earlier, before the orb has even left the hand.
##
## OF19 made it worse without meaning to. Widening the orb's collision radius
## 0.42 -> 0.60 for "too hard to know where the ball is going to go" is pure
## forgiveness on the miss/no-miss line -- which means it grew the set of
## throws that LAND while being scored at the edge multiplier. More landed
## throws, a larger share of them scored well below the advertised number.
##
## Now: when the launch assist is eligible the orb is genuinely led to the
## body's centre, so the dead-centre number IS the honest one and nothing
## changes. When it is not, the throw is unassisted and the honest estimate is
## the offset the player's own reticle is sitting at.
func catch_chance_now() -> float:
	if _enemy == null:
		return 0.0
	var radius := 0.5
	if _wild != null and _wild.has_method("body_radius"):
		radius = float(_wild.call("body_radius"))
	return CATCH.catch_chance(
		SPECIES.catch_rate(_enemy.species_id), _enemy.hp_fraction(), current_orb_id(),
		catch_aim_offset(radius), radius, _personal_catching_bonus()
	)


func _personal_catching_bonus() -> float:
	var game := get_node_or_null("/root/Game")
	return float(game.get("local").skills.catch_bonus()) if game != null and game.get("local") != null else 0.0


## Metres off centre this throw would strike at, as best the aim can know
## before the orb flies.
##
## Zero while the launch assist is eligible: `throw_aim.gd::_commit_launch_assist()`
## aims the orb at the predicted body centre, so an eligible throw really does
## earn the centre bonus. Otherwise the reticle's own distance from the body
## axis, clamped to the body -- `accuracy_bonus()` clamps at `body_radius`
## anyway, and past that the throw is a MISS rather than a poor catch, which is
## `catch_aim_is_locked()`'s job to say rather than this one's.
func catch_aim_offset(body_radius: float) -> float:
	if _throw == null:
		return 0.0
	var report: Dictionary = _throw.call("aim_report")
	if report.is_empty():
		return 0.0
	if bool(report.get("eligible", false)):
		return 0.0
	# A throw whose predicted flight reaches the body is scored on where that
	# flight passes, not on where the reticle sits -- the same distinction
	# `orb.gd::closest_approach_ahead()` makes at the moment of the strike. The
	# reticle offset is only the honest estimate when the arc does NOT already
	# answer the question.
	# OP-0830-5: clamped at the placement SCALE, not at `body_radius`. Both this
	# and the strike itself used to pin at the body, which meant the reticle
	# reported the worst possible placement for every aim more than 0.325m off
	# a Bramblebun's centre -- a range the aim spends most of its time in. See
	# `catch_math.accuracy_bonus()` for the measurement.
	var scale: float = CATCH.accuracy_scale(maxf(body_radius, 0.0))
	if bool(report.get("trajectory_hits_target", false)):
		return clampf(float(report.get("trajectory_offset", 0.0)), 0.0, scale)
	return clampf(float(report.get("reticle_offset", 0.0)), 0.0, scale)


## Whether the aim is genuinely ON the creature -- reticle inside the visible
## body AND line of sight to it, the same pair `throw_aim.gd` requires before
## it will grant a launch assist.
##
## The HUD needs this separately from the chance because the two say different
## things. The chance answers "how good is this throw"; this answers "is the
## game about to help you, or are you about to lob an orb past it". Before this
## existed the reticle drew an identical ring and an identical percentage in
## both cases, which is most of why a miss and an unlucky roll were
## indistinguishable to the player.
func catch_aim_is_locked() -> bool:
	if _throw == null:
		return false
	var report: Dictionary = _throw.call("aim_report")
	if report.is_empty():
		return false
	# An eligible camera ray cannot promise a throw through an observed
	# hand-arc obstruction. This changes the HUD claim, not launch assist.
	if bool(report.get("trajectory_blocked", false)):
		return false
	# EITHER the assist is eligible, OR the previewed flight actually reaches
	# the creature. The two are different questions and a render caught them
	# contradicting each other on screen: the throw cone visibly ended on the
	# Bramblebun while the caption under it read NOT ON TARGET, because the
	# screen-centre ray sat just outside the assist window even though the arc
	# did not. The player reads the picture; the words have to agree with it.
	#
	# The assist gate itself is unchanged -- it still needs the reticle inside
	# the window AND line of sight before it will lead a throw. This only widens
	# what the HUD calls "on target" to include a throw that lands without help.
	return bool(report.get("eligible", false)) \
		or bool(report.get("trajectory_hits_target", false))


## The body of the creature currently being fought, or null between fights.
##
## Public for the same reason `encounter_director.gd::ally_body()` is: a caller
## that needs to know where the opponent physically IS must ask the fight,
## never search the scene tree for it. `smoke_tournament_bracket.gd` did the
## latter -- `_world.find_child("TrainerCreature_*")` -- and `find_child`
## returns the first match in tree order, so on the round AFTER a loss (the one
## moment two trainer-creature bodies coexist, the previous round's still
## queued for free) it aimed and measured against the wrong body while the live
## opponent stood elsewhere, and the round stalled with the enemy at full HP.
## Intermittent, because it depended on free timing.
func enemy_body() -> Node3D:
	return _wild


## Where the two fighters are, for anything that needs to frame them.
func arena_focus() -> Vector3:
	if _ally_body != null and _wild != null:
		return (_ally_body.global_position + _wild.global_position) * 0.5
	if _player != null:
		return _player.global_position
	return Vector3.ZERO
