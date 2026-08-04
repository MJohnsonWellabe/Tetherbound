extends Node

## Everything around a fight that is not the fight: spawning the wild pal,
## offering the engage prompt, suspending exploration, and putting the world
## back afterwards.
##
## Split from CombatManager on purpose. The manager knows how a fight resolves
## and nothing about the world it happens in; this knows about the world and
## nothing about damage. M3 adds catching to the manager and M4 adds a party,
## and neither should have to touch spawn placement or the interact prompt.
##
## Split from the playground world too, which is about terrain. This node can be
## dropped into the real Meadows scene unchanged.

const MATH := preload("res://scripts/combat/combat_math.gd")
const CATCH := preload("res://scripts/combat/catch_math.gd")
const SPECIES := preload("res://scripts/pals/pal_species.gd")
## For the XP curve and the reward table, both of which live in
## data/config/party.json. Loaded through pal_instance so there is one reader of
## that file rather than two that can disagree about its defaults.
const PAL := preload("res://scripts/pals/pal_instance.gd")
## Mirrors CombatManager.OUTCOME_CAUGHT. Declared rather than typed twice so a
## renamed outcome cannot silently stop matching here.
const CAUGHT := "caught"
const PAL_SCENE := preload("res://scenes/pals/pal.tscn")
## pal.tscn carries no script; one body shape serves both roles and the script
## is chosen here. The alternative is two near-identical scenes, which means
## M11's real creature model has to be wired into the game twice.
const BODY_SCRIPT := preload("res://scripts/pals/pal_body.gd")
const WILD_SCRIPT := preload("res://scripts/pals/wild_pal.gd")

signal prompt_changed(text: String)

## A catch that could not be kept, with the party's refusal token. M5's release
## ceremony is what listens to this: capture-while-full is the only way that
## scene is ever reached.
signal caught_refused(token: String, instance: RefCounted)

## A pal was paid for a fight. `deployed` separates the one that fought from the
## ones that watched, because they are paid differently and a HUD that showed
## them the same way would be describing a rule the game does not have.
##
## Emitted as an EVENT rather than left for something to notice a stat moving:
## an evidence session can log "Bramblit gained 44 XP" honestly, and the M4 gate
## passed once already on a progression system whose only observable symptom
## would have been a number that never changed.
signal xp_awarded(pal: RefCounted, amount: int, deployed: bool)

## A pal levelled. Separate from `xp_awarded` because one award can buy several
## levels and each one is its own moment; `gained` is how many this award bought.
signal pal_levelled(pal: RefCounted, level: int, gained: int)

## Ids into data/pals/species.json, so swapping any of them is a data edit.
##
## Two wild creatures in M3: one peaceful to practise throwing at, and one that
## comes at you. They are separated in the playground so the ambush is something
## you walk into rather than something that happens while you are aiming at the
## other one.
const STARTER_SPECIES := "starter_ground"
const WILD_SPAWNS := [
	{"species": "wild_rabbit", "offset": Vector3(14.0, 0.0, -10.0)},
	{"species": "wild_bristler", "offset": Vector3(-6.0, 0.0, 26.0)},
]

## Seconds before a defeated wild pal is back on its feet. M2 only: the milestone
## exists to find out whether the owner wants another fight, and making them
## restart the game to have one would answer a different question.
const RESPAWN_DELAY := 6.0

@export var player_path: NodePath
@export var manager_path: NodePath
@export var camera_rig_path: NodePath

var _player: CharacterBody3D = null
var _manager: Node = null
var _camera_rig: Node = null
var _wild_pals: Array[Node3D] = []
var _engaged_with: Node3D = null
var _ally_body: Node3D = null

var _engage_range: float = 6.0
var _prompt: String = ""

## Pals waiting on their faint to clear, and on their respawn. Keyed by node, so
## two creatures can be knocked out at once without one cancelling the other's
## timer — which is the bug a single shared `_respawn_left` would have.
var _faint_timers: Dictionary = {}
var _respawn_timers: Dictionary = {}

## Where a caught pal goes.
##
## This used to be `var _caught: Array[RefCounted]` — an unbounded list with a
## comment admitting it was "a milestone-local record that catching worked", and
## an accessor nothing ever called. It is gone. Caught pals now go to the party,
## which is capped at five and refuses a sixth, so CLAUDE.md's hard rule is
## enforced by the code that holds the pals rather than by prose above a list
## that could not enforce it.
@export var party_path: NodePath
var _party: Node = null


func _ready() -> void:
	_party = get_node_or_null(party_path)
	_engage_range = float(MATH.config().get("flow", {}).get("engage_range", 6.0))
	_player = get_node_or_null(player_path) as CharacterBody3D
	_manager = get_node_or_null(manager_path)
	_camera_rig = get_node_or_null(camera_rig_path)
	if _player == null or _manager == null:
		push_error("encounter director needs a player and a combat manager")
		set_process(false)
		return
	_manager.connect("exited", _on_combat_exited)

	# `_ready` runs while the parent is still setting up its children, and
	# add_child() is refused during that. One frame is enough to be out of it.
	await get_tree().process_frame
	await _spawn_creatures()


## How many physics frames to keep trying to stand the wild pal on the ground.
##
## Terrain3D builds its collision over several frames after the data directory
## loads, and a raycast before then hits nothing. The first version of this
## spawned once on frame two, the ray missed, and the creature sat at the world
## origin under the terrain — where the player could neither see nor reach it,
## and where no error was printed. Retrying is the fix; the frame budget is so a
## scene with genuinely no ground fails loudly instead of looping.
const GROUND_WAIT_FRAMES := 300


func _spawn_creatures() -> void:
	var origin := _player.global_position

	for entry: Variant in WILD_SPAWNS:
		var spawn: Dictionary = entry
		var species := str(spawn["species"])
		var wild: Node3D = PAL_SCENE.instantiate()
		wild.name = "Wild_%s" % species
		wild.set_script(WILD_SCRIPT)
		get_parent().add_child(wild)
		if not await _stand_on_ground(wild, origin + (spawn["offset"] as Vector3)):
			push_error("no ground under the %s spawn point; it will be unreachable" % species)
		wild.call("populate", species, _player)
		wild.call("configure", MATH.config().get("wild", {}))
		wild.set("home", wild.global_position)
		# An aggressive pal asks; this node decides. Keeping the decision here
		# means every route into a fight goes through one place, so a new one
		# cannot forget to suspend exploration or hand over the camera.
		wild.connect("wants_to_engage", _on_wild_wants_to_engage.bind(wild))
		_wild_pals.append(wild)

	# The player's pal exists as a body in the world the whole time and is simply
	# hidden outside combat. Instancing it at the moment a fight opens is a hitch
	# in the one frame that most needs to be smooth.
	_ally_body = PAL_SCENE.instantiate()
	_ally_body.name = "AllyPal"
	_ally_body.set_script(BODY_SCRIPT)
	get_parent().add_child(_ally_body)
	_ally_body.visible = false

	# The deployed pal comes FROM THE PARTY.
	#
	# It used to be a separately-spawned starter that the party never knew about,
	# which is how a fight could begin with `party size: 0` — a blind reviewer
	# spotted exactly that in the transcript and asked, reasonably, what was
	# fighting on the player's behalf when they owned nothing. The seam existed
	# because M3 needed something to fight with before a party existed; it should
	# have closed the moment one did.
	#
	# The starter is granted INTO the party rather than held beside it, so there
	# is exactly one answer to "which pals does the player have" and switching in
	# a fight is switching the same list the menu shows.
	if _party != null and int(_party.call("size")) == 0:
		var starter: RefCounted = SPECIES.spawn(STARTER_SPECIES)
		if starter == null:
			push_error("starter species '%s' is missing from species.json" % STARTER_SPECIES)
		elif not bool(_party.call("add", starter)):
			push_error("could not grant the starter: %s" % _party.call("last_refusal"))

	var deployed := _active_pal()
	if deployed == null:
		push_error("no pal to deploy: the party is empty and the starter could not be granted")
	else:
		# Dressing the body early is a courtesy to the first fight, not the
		# decision about who fights it. CombatManager.begin() re-deploys the body
		# from the party every time a fight opens, so changing the deployment in
		# the menu changes what walks out — which was the entire point of this
		# line and was not true while the answer was cached here.
		_ally_body.call("setup", deployed.species_id)


## Whichever pal the party currently has deployed.
##
## Read through the party rather than cached, so `set_active()` from the menu and
## the in-fight switch cannot disagree about who is out.
##
## That sentence used to sit above a function whose only caller cached the result
## at world load. Nothing calls it and keeps the answer now: the prompt asks per
## frame, the fight asks at the moment it opens, and CombatManager asks the party
## again on every switch.
func _active_pal() -> RefCounted:
	return (_party.call("active") as RefCounted) if _party != null else null


func _stand_on_ground(body: Node3D, spot: Vector3) -> bool:
	for i in GROUND_WAIT_FRAMES:
		if bool(body.call("place_on_ground", spot)):
			return true
		await get_tree().physics_frame
	return false


## The peaceful practice pal. Named for what it is used for rather than by index,
## so tests and tools do not silently start pointing at a different creature when
## the spawn list changes.
func wild_pal() -> Node3D:
	return _wild_of_species("wild_rabbit")


func aggressive_pal() -> Node3D:
	return _wild_of_species("wild_bristler")


func wild_pals() -> Array[Node3D]:
	return _wild_pals


## What the player is holding. Answered by the party, which is the only place a
## pal can be.
func caught() -> Array:
	return _party.call("members") if _party != null else []


## Hand a caught pal to the party.
##
## The refusal is not swallowed. A full party refusing a sixth is the moment
## M5's release ceremony exists to resolve, and a director that quietly dropped
## the creature on the floor would make that ceremony unreachable — the player
## would simply never learn they had caught anything.
func _keep(instance: RefCounted) -> void:
	if _party == null:
		push_warning("caught %s with no party to put it in" % instance.species_id)
		return
	if not bool(_party.call("add", instance)):
		var token := str(_party.call("last_refusal"))
		push_warning("could not keep %s: %s" % [instance.species_id, token])
		caught_refused.emit(token, instance)


func _wild_of_species(id: String) -> Node3D:
	for wild in _wild_pals:
		if str(wild.get("species_id")) == id:
			return wild
	return null


func ally_body() -> Node3D:
	return _ally_body


## The pal that would fight if a fight started now.
func ally_instance() -> RefCounted:
	return _active_pal()


func prompt() -> String:
	return _prompt


func _process(delta: float) -> void:
	_tick_respawn(delta)
	_update_prompt()


## Engage is read on the physics tick, not the idle tick.
##
## `Input.is_action_just_pressed()` is scoped to whichever frame the press was
## recorded in, and reading it from `_process` while CombatManager reads its own
## actions from `_physics_process` means one press can be seen by one and missed
## by the other depending on where in the frame it landed. It cost a survey run
## that captured four frames of a fight that had never started.
func _physics_process(_delta: float) -> void:
	_read_engage_input()


## Two clocks per knocked-out creature: how long its body lies there, and how
## long until it is back. Kept per-node so two faints cannot cancel each other.
func _tick_respawn(delta: float) -> void:
	for wild: Node3D in _faint_timers.keys().duplicate():
		var left: float = float(_faint_timers[wild]) - delta
		if left > 0.0:
			_faint_timers[wild] = left
			continue
		_faint_timers.erase(wild)
		if is_instance_valid(wild):
			wild.call("clear_faint")

	for wild: Node3D in _respawn_timers.keys().duplicate():
		var left: float = float(_respawn_timers[wild]) - delta
		if left > 0.0:
			_respawn_timers[wild] = left
			continue
		_respawn_timers.erase(wild)
		if is_instance_valid(wild):
			wild.call("revive_at_home")
			# M3-only: the orb stock refills with the practice pal, because there
			# is no inventory until M8 and running dry mid-session would end the
			# testing rather than teach anything.
			_refill_orbs()


func _refill_orbs() -> void:
	var throw_aim: Node = _manager.call("throw_aim") as Node
	if throw_aim != null:
		throw_aim.call("refill")


## The nearest wild pal the player could choose to fight right now.
func _engageable() -> Node3D:
	var deployed := _active_pal()
	if deployed == null or _manager == null or deployed.fainted:
		return null
	if bool(_manager.call("is_fighting")):
		return null

	var best: Node3D = null
	var best_distance := _engage_range
	for wild in _wild_pals:
		if not is_instance_valid(wild) or not wild.visible or not bool(wild.call("is_alive")):
			continue
		var distance := _player.global_position.distance_to(wild.global_position)
		if distance <= best_distance:
			best = wild
			best_distance = distance
	return best


func _update_prompt() -> void:
	var text := ""
	var deployed := _active_pal()
	if bool(_manager.call("is_fighting")):
		text = ""
	elif deployed != null and deployed.fainted:
		text = "%s is out of the fight." % deployed.display()
	else:
		var candidate := _engageable()
		if candidate != null:
			text = "[X] / [E]   Engage %s" % str(candidate.get("display_name"))
	if text != _prompt:
		_prompt = text
		prompt_changed.emit(text)


func _read_engage_input() -> void:
	if not Input.is_action_just_pressed("interact"):
		return
	var candidate := _engageable()
	if candidate == null:
		return
	# For a PEACEFUL pal this press is the only way in. GAME_DESIGN.md §14
	# forbids proximity starting a fight with one, and nothing but this line
	# starts a fight with the Meadow Hopper.
	_start_fight(candidate)


## An aggressive pal has reached the trainer and is starting the fight itself.
##
## §14 lists "Aggressive pal initiates" beside the player's own routes in, and
## scopes the "not simple proximity" rule to peaceful pals. This is that other
## route, and it is guarded rather than trusted: the creature asks, and gets
## refused if a fight is already running or the player has nothing to fight with.
func _on_wild_wants_to_engage(wild: Node3D) -> void:
	if not bool(wild.get("aggressive")):
		push_error("%s asked to initiate but is not aggressive" % wild.name)
		return
	var deployed := _active_pal()
	if deployed == null or deployed.fainted or bool(_manager.call("is_fighting")):
		return
	if not is_instance_valid(wild) or not wild.visible or not bool(wild.call("is_alive")):
		return
	_start_fight(wild)


## One way in, whoever started it. A second route that forgot to suspend
## exploration or hand over the camera would be a bug that only shows up when
## something ambushes you.
func _start_fight(wild: Node3D) -> void:
	# The PARTY goes in, not a snapshot of it.
	#
	# This line used to build `[_ally]` — a one-element array holding a pal read
	# once at world load. Three things followed from that and all three read as
	# separate bugs: choosing a different pal in the menu did not change who
	# fought, the deployed BODY never changed species, and CombatManager's index
	# had nothing to move through, so the Switch command could not exist.
	var deployed := _active_pal()
	if deployed == null or deployed.fainted:
		return
	if not bool(_manager.call("begin", _player, wild, _ally_body, _party, _camera_rig)):
		return
	_engaged_with = wild
	_set_exploration_active(false)


func _on_combat_exited(outcome: String) -> void:
	_set_exploration_active(true)
	var wild := _engaged_with
	_engaged_with = null

	# Read BEFORE the match, because the match can change both.
	#
	# The roster especially: a creature caught in this fight joins the party
	# inside `_keep()` below, and paying it a share for its own capture would
	# hand the player a levelled newcomer for a fight it was on the wrong side of.
	var roster: Array = _party.call("members") if _party != null else []
	var deployed := _active_pal()
	var defeated: RefCounted = _manager.call("enemy") as RefCounted

	if wild != null and is_instance_valid(wild):
		match outcome:
			"won":
				# It stays on the ground for a moment before it clears. §15: the
				# body is the feedback for having over-damaged something you
				# might have caught.
				wild.call("notify_fainted")
				_faint_timers[wild] = float(CATCH.config().get("faint", {}).get("linger_seconds", 4.0))
				_respawn_timers[wild] = RESPAWN_DELAY
			CAUGHT:
				var kept: RefCounted = _manager.call("caught_instance")
				if kept != null:
					_keep(kept)
				wild.visible = false
				# The creature comes back so the owner can keep testing throws.
				# It is a different individual from the one now in the party —
				# the party holds the instance that was caught, and this is the
				# world putting another of its species back on the hillside.
				#
				# That sentence sat here before anything made it true. The body
				# kept the very object the party had just taken, so the hillside
				# and the party shared one pal: reviving the body healed a party
				# member, and catching that species again came back
				# `already_held`. The handover below is what the comment always
				# claimed, and it happens NOW rather than at respawn — the moment
				# the party owns a pal, the world has to stop touching it.
				if wild.has_method("hand_instance_to_owner"):
					wild.call("hand_instance_to_owner")
				_respawn_timers[wild] = RESPAWN_DELAY

	# GAME_DESIGN.md §11: combat is the primary source of XP. Paid here, on the
	# way out of the fight, for both outcomes that mean the fight was won —
	# and before the heal below, so a level-up's HP is handed over on top of the
	# damage the fight did rather than into an already-full bar.
	if outcome == "won" or outcome == CAUGHT:
		award_xp(defeated, roster, deployed, outcome == CAUGHT)

	# There is no healing system, no camp and no bond yet, so the player's pals
	# are restored between fights. That is a placeholder for M5's stronghold rest
	# and M6's pal beds, and it is deliberately generous: this milestone is
	# measuring whether the fight is worth repeating, and a recovery chore in
	# front of the second one measures something else.
	#
	# The WHOLE party, not just the pal that finished. It was just the deployed
	# one, which was the same thing while only one pal could ever fight. Now that
	# Switch works, a pal swapped out at a sliver of health would sit there for
	# the rest of the session with nothing in the game able to heal it — and a
	# command you cannot afford to use twice is a trap, not a command.
	#
	# Read fresh rather than reusing the roster snapshot above, so a creature
	# caught in this fight is healed too instead of joining the party at the 8%
	# health you had to leave it at to catch it.
	for entry: Variant in (_party.call("members") if _party != null else []):
		var pal: RefCounted = entry as RefCounted
		if pal != null:
			pal.heal_fully()


## --- rewards --------------------------------------------------------------
##
## GAME_DESIGN.md §11: "Combat is primary XP." Until this section existed,
## `pal_instance.grant_xp()` had no caller anywhere in `scripts/` — the level
## curve, the stat growth, the cap and six passing unit tests all worked
## perfectly on a number that never moved in a real session. Every pal the owner
## has ever played with was level 1.


## What beating this creature is worth, in XP, to the pal that finished the fight.
##
## Scaled off the DEFEATED creature, never off the player's own progress: §11
## forbids scaling wild levels to the player, and §27 asks for danger that rises
## with geography instead. A flat number would make the Thornback that ambushes
## you and the Hopper you practise on worth the same afternoon, which is exactly
## the difference §27 will need to express.
##
## Two things scale it, and only one of them can bite today:
##
##   * The creature's WEIGHT — its species' base HP, attack and defence added up
##     and measured against `reference_stat_total`. Nothing sets wild levels yet,
##     so every creature in the Meadows is level 1 and this is the only thing
##     that separates one fight from another. It is also the honest measure: a
##     kill is worth what it cost to make.
##   * The LEVEL DIFFERENCE, `defeated.level - earner.level`. Inert right now
##     (every difference is zero and the multiplier is exactly 1.0) and built in
##     anyway, because §27's deeper Meadows needs it and retrofitting it later
##     would silently rebalance every reward already in a save.
##
## `cfg` is passed in rather than read inside, for the reason catch_math.resolve()
## gives about its roll: a function that reaches for the shipping config cannot
## be tested against any other one, and a reward that cannot be tested against a
## known table is a reward nobody can prove came from the table at all.
static func xp_for_defeating(defeated: RefCounted, earner: RefCounted, caught: bool, cfg: Dictionary) -> int:
	if defeated == null or earner == null:
		return 0

	var reference := maxf(1.0, float(cfg.get("reference_stat_total", 160.0)))
	var weight: float = (
		float(defeated.base_hp) + float(defeated.base_attack) + float(defeated.base_defence)
	) / reference
	var level := float(maxi(1, int(defeated.level)))
	var difference := float(int(defeated.level) - int(earner.level))
	var multiplier := clampf(
		1.0 + float(cfg.get("level_difference_step", 0.12)) * difference,
		float(cfg.get("level_difference_min", 0.35)),
		float(cfg.get("level_difference_max", 2.0))
	)

	var award: float = float(cfg.get("win_base", 55.0)) \
		* pow(level, float(cfg.get("level_exponent", 1.2))) \
		* weight \
		* multiplier

	# A catch pays less than a kill, and not nothing.
	#
	# Nothing was the tempting answer — §15 and D08 already make catching cost
	# you orbs, a weakened target and seconds of your pal standing undefended,
	# and the creature itself is the reward. But a zero would mean the fastest
	# way to level is to kill the pals you would rather keep, which is a perverse
	# incentive pointed straight at the verb the game is named for.
	#
	# A fraction says the true thing instead: your pal did the work of wearing it
	# down and is paid for that, and the fight simply ended before the last blow,
	# so it is paid less. Winning stays the better XP route, catching stays the
	# better acquisition route, and the two verbs remain worth choosing between.
	if caught:
		award *= float(cfg.get("caught_fraction", 0.5))

	return maxi(int(cfg.get("minimum", 1)), int(round(award)))


## What the pals that did NOT fight are each paid.
##
## Not zero, and not the full share.
##
## Deployed-only is the obvious answer and it quietly breaks the five-pal design.
## The party is capped at five and CLAUDE.md says so twice; the whole emotional
## bet is that the owner knows all five. Pay only the one that fights and the
## first pal runs twenty levels ahead within an afternoon, the other four become
## too weak to deploy without losing, and the player settles on a party of one
## they are afraid to switch out of — which also makes the Switch command
## pointless, and §14 lists it as one of five.
##
## Paying everyone equally breaks it from the other side: deploying stops being a
## choice, and switching costs nothing.
##
## A full share for the pal that stood in the fight and a quarter for the ones
## that watched keeps deployment a real decision while stopping the rest of the
## five falling permanently out of the game. Fainted members are paid nothing —
## they were not watching.
static func xp_for_watching(award: int, cfg: Dictionary) -> int:
	if award <= 0:
		return 0
	var share := float(award) * float(cfg.get("bench_fraction", 0.25))
	return maxi(int(cfg.get("minimum", 1)), int(round(share)))


## Pay out a won fight.
##
## `roster` is the party as it stood when the fight ENDED, `deployed` is the pal
## that was out at the final blow, and `caught` says whether the fight ended in
## an orb rather than a faint.
##
## Public, and called from exactly one place. It takes everything it needs as
## arguments and touches no node, so tests/test_combat_rewards.gd can prove the
## payout — including the signals — without standing up a scene. The one thing
## worse than an untested reward is the reward this replaced, which was tested
## thoroughly and never called.
func award_xp(defeated: RefCounted, roster: Array, deployed: RefCounted, caught: bool) -> void:
	if defeated == null or deployed == null:
		return
	var cfg: Dictionary = PAL.config().get("rewards", {})

	var award := xp_for_defeating(defeated, deployed, caught, cfg)
	_grant(deployed, award, true)

	var share := xp_for_watching(award, cfg)
	for entry: Variant in roster:
		var pal: RefCounted = entry as RefCounted
		# `pal == defeated` is not paranoia: a caught creature is the opponent AND
		# a party member moments later, and the roster is snapshotted early
		# precisely so it cannot be both here.
		if pal == null or pal == deployed or pal == defeated or pal.fainted:
			continue
		_grant(pal, share, false)


func _grant(pal: RefCounted, amount: int, deployed: bool) -> void:
	if pal == null or amount <= 0:
		return
	# A capped pal is told nothing rather than told it gained XP it cannot spend.
	# grant_xp() correctly refuses at the cap; announcing an award it discarded
	# would put a number on screen that no bar can account for.
	if pal.level >= PAL.level_cap():
		return
	var gained: int = pal.grant_xp(amount)
	xp_awarded.emit(pal, amount, deployed)
	if gained > 0:
		pal_levelled.emit(pal, int(pal.level), gained)


## Hand control back and forth between exploration and combat. One place, so a
## new way of entering a fight cannot forget half of it.
func _set_exploration_active(active: bool) -> void:
	if _player != null and _player.has_method("set_locomotion_enabled"):
		_player.call("set_locomotion_enabled", active)
