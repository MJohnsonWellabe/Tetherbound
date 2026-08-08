extends Node3D

## One Team Tether trainer, standing at a post on the road to the stronghold.
##
## MEADOWS_VERTICAL_SLICE.md M13 in one node: a world encounter with a trainer,
## a team fight against them, and creatures that cannot be caught. M14's Warden
## is this node with a longer team and a harder tether grade — there is no boss
## code path anywhere, on purpose, because two trainer-battle systems would mean
## two places the cannot-catch rule has to be remembered.
##
## A TRAINER BATTLE IS N ORDINARY FIGHTS IN A ROW.
##
## That is the whole design, and it is why nothing in `scripts/combat/` needed a
## team concept. `CombatManager` fights one creature against one creature inside
## one arena; this node decides WHICH creature of its own is standing in that
## arena, and sends the next one when the last goes down. The arena, the camera
## handover, the aimed cone, the wind-up, the Switch command and the five-pal
## party all work exactly as they already did.
##
## NEITHER HUMAN FIGHTS. There is no attack anywhere in this file, no weapon, no
## route into Combat Mode for a person. The player's own trainer is already
## protected by `GAME_DESIGN.md` §14 and by `CombatManager` never targeting them;
## this one is protected more simply than that — it is a `Node3D` with no
## collider and no body, so there is nothing in the world to hit. CLAUDE.md's
## "human cannot fight" is a hard rule and it is symmetric.

const DATA := preload("res://scripts/trainers/tether_data.gd")
const DRESS := preload("res://scripts/trainers/tether_dress.gd")
const BATTLE := preload("res://scripts/trainers/trainer_battle.gd")
const MODEL := preload("res://scripts/trainers/tether_trainer_model.gd")
const PAL_SCENE := preload("res://scenes/pals/pal.tscn")
const TETHER_PAL := preload("res://scripts/trainers/tether_pal.gd")

## The trainer's whole team is down. M14's legendary hangs off this one.
signal beaten(trainer_id: String)
## A creature was sent out, so a transcript can say what the fight is against
## without polling. `left` is how many of the team are still standing after it.
signal sent_out(species_id: String, index: int, left: int)
## The player broke off — ran, or lost their deployed pal. `restored` says
## whether the team was put back on its feet.
signal broke_off(trainer_id: String, restored: bool)

const PROMPT_CHALLENGE := "[X] / [E]   Challenge %s — %s"
const PROMPT_BEATEN := "%s: \"%s\""

var trainer_id: String = ""
var display_name: String = ""

var _definition: Dictionary = {}
var _battle: RefCounted = null
var _bodies: Array[Node3D] = []
var _model: Node3D = null

var _player: Node3D = null
var _director: Node = null
var _manager: Node = null
var _world: Node = null

## True from the moment a challenge is accepted until the battle resolves one way
## or the other. Everything this node does to a running fight is gated on it, so
## a wild encounter elsewhere in the meadow cannot be mistaken for this battle
## ending.
var _active: bool = false
var _send_out_left: float = 0.0
var _pending_index: int = -1
## Seconds until the team's bodies are cleared away after the trainer is beaten.
var _clear_left: float = 0.0


func configure(definition: Dictionary, player: Node3D, director: Node, manager: Node, world: Node) -> bool:
	_definition = definition
	trainer_id = str(definition.get("id", ""))
	display_name = str(definition.get("display_name", trainer_id))
	_player = player
	_director = director
	_manager = manager
	_world = world

	_battle = BATTLE.from_definition(definition)
	if _battle.size() == 0:
		push_error("trainer '%s' has no team: %s" % [trainer_id, _battle.last_refusal()])
		return false

	if _manager != null and not _manager.is_connected("exited", _on_combat_exited):
		_manager.connect("exited", _on_combat_exited)
	return true


## Build the body, the flags and the team. Separate from `configure` because it
## needs to be in the tree and standing on ground that exists.
##
## `facing` is which way the trainer looks — down the road, at whoever is coming
## up it. The NODE is turned rather than the model, so `post_forward()` below and
## the heel positions are all read off one transform instead of a stored vector
## that could disagree with the body's yaw.
func raise_the_post(facing: Vector3) -> void:
	var flat := Vector3(facing.x, 0.0, facing.z)
	if flat.length() > 0.01:
		# Same yaw convention as `pal_body.face_towards`: +Z is forward.
		rotation.y = atan2(flat.x, flat.z)
	_build_model()
	_build_dressing(post_forward())
	_build_team()


func _build_model() -> void:
	_model = Node3D.new()
	_model.name = "Body"
	_model.set_script(MODEL)
	# BEFORE it enters the tree: the base class builds the whole character in
	# `_ready()` from whatever `_load_config()` returns.
	_model.call("configure", _definition)
	add_child(_model)


func _build_dressing(facing: Vector3) -> void:
	var side := facing.cross(Vector3.UP).normalized()
	var count: int = maxi(1, int(_definition.get("banners", DATA.dress().get("banner", {}).get("count", 2))))
	for i in count:
		# Spread either side of the post rather than in a row behind it, so the
		# flags frame the trainer from the road instead of hiding behind them.
		var offset: float = (float(i) - float(count - 1) * 0.5) * 2.2
		var at := global_position + side * offset - facing * 0.6
		at.y = _ground(at.x, at.z, global_position.y)
		# Turned to face the way the trainer is facing — down the road, at whoever
		# is walking up it. A banner seen edge-on is a stick.
		DRESS.banner(self, at, facing)

	DRESS.barricade(
		self,
		global_position + facing * 2.4,
		side,
		func(x: float, z: float) -> float: return _ground(x, z, global_position.y)
	)


## The team, standing at heel and hidden.
##
## Every body exists from the moment the post is raised rather than being
## instanced when its turn comes: instancing a `CharacterBody3D` and loading a
## rigged model in the frame between one creature going down and the next
## arriving is a hitch in the one moment of a boss fight that most needs not to
## have one. `encounter_director` builds the player's own pal body for exactly
## the same reason.
func _build_team() -> void:
	var forward := post_forward()
	var side := forward.cross(Vector3.UP).normalized()
	for i in _battle.size():
		var pal: RefCounted = _battle.at(i)
		var body: Node3D = PAL_SCENE.instantiate()
		body.name = "TetherPal_%s_%d" % [trainer_id, i]
		body.set_script(TETHER_PAL)
		add_child(body)
		var heel := global_position - forward * 1.6 + side * ((float(i) - float(_battle.size() - 1) * 0.5) * 1.8)
		heel.y = _ground(heel.x, heel.z, global_position.y)
		body.global_position = heel
		body.call("adopt", pal.species_id, pal, _player, _battle.grade_at(i), trainer_id)
		body.visible = false
		_bodies.append(body)


func _ground(x: float, z: float, fallback: float) -> float:
	if _world == null or not _world.has_method("ground_height_at"):
		return fallback
	var height: float = float(_world.call("ground_height_at", x, z))
	return fallback if is_nan(height) else height


## --- the challenge ---------------------------------------------------------

func is_beaten() -> bool:
	return _battle != null and _battle.is_beaten()


func is_active() -> bool:
	return _active


func battle() -> RefCounted:
	return _battle


func distance_to_player() -> float:
	if _player == null:
		return INF
	return global_position.distance_to(_player.global_position)


## Is this trainer close enough, and in a state, to be challenged right now?
func can_challenge() -> bool:
	if _battle == null or _active or is_beaten():
		return false
	if _manager != null and bool(_manager.call("is_fighting")):
		return false
	return distance_to_player() <= DATA.engage_range()


## The line the world prompt shows for this trainer, or "" when it should show
## nothing. Their defeat line stays available afterwards, because a trainer you
## have beaten standing silently beside a road you can now walk up reads as a
## piece of scenery that used to be a person.
func prompt_line() -> String:
	if distance_to_player() > DATA.engage_range():
		return ""
	if is_beaten():
		return PROMPT_BEATEN % [display_name, str(_definition.get("defeat", ""))]
	if _active:
		return ""
	return PROMPT_CHALLENGE % [display_name, str(_definition.get("challenge", ""))]


## Accept the challenge. Returns false if this trainer cannot be fought now.
func challenge() -> bool:
	if not can_challenge():
		return false
	if not _battle.open():
		return false
	_active = true
	if _model != null:
		_model.call("play_role", MODEL.ROLE_CHALLENGE)
	_queue_send_out(_battle.current_index(), float(DATA.flow().get("challenge_delay", 0.7)))
	return true


func _queue_send_out(index: int, delay: float) -> void:
	_pending_index = index
	_send_out_left = maxf(0.05, delay)
	set_process(true)


func _process(delta: float) -> void:
	if _clear_left > 0.0:
		_clear_left -= delta
		if _clear_left <= 0.0:
			_recall_everyone()
	if _send_out_left <= 0.0:
		return
	_send_out_left -= delta
	if _send_out_left > 0.0:
		return
	_send_the_next_one()


## Put the creature at `_pending_index` on the ground in front of the player and
## hand it to the fight.
##
## The player walking away during the pause between two of a trainer's creatures
## counts as breaking off. Without that check the next creature is teleported to
## wherever the player has wandered to and the fight reopens around them, which
## reads as being ambushed by something that was two hundred metres away.
func _send_the_next_one() -> void:
	_send_out_left = 0.0
	var index := _pending_index
	_pending_index = -1
	if not _active or index < 0 or index >= _bodies.size():
		return
	if _player == null or _director == null:
		return
	if distance_to_player() > DATA.release_range() * 2.0:
		_break_off()
		return

	var body := _bodies[index]
	var forward := (_player.global_position - global_position)
	forward.y = 0.0
	forward = Vector3.FORWARD if forward.length() < 0.01 else forward.normalized()
	body.call("send_out", global_position + forward * 2.2, _player.global_position)

	if _model != null:
		_model.call("play_role", MODEL.ROLE_SEND_OUT)

	var pal: RefCounted = _battle.at(index)
	sent_out.emit(pal.species_id, index, _battle.standing())

	if not bool(_director.call("engage", body)):
		# The director refused — the player's whole party is down, or a fight
		# opened elsewhere in the frame. Not an error; put the creature away and
		# let the player challenge again.
		body.call("recall")
		_break_off()


## --- resolution ------------------------------------------------------------

func _on_combat_exited(outcome: String) -> void:
	if not _active:
		return

	match outcome:
		"won":
			# The player's pal knocked this creature out. `trainer_battle` has
			# nothing to update — the instance the fight damaged IS the team's,
			# there is no second copy — so this only decides who is next.
			var body := _bodies[_battle.current_index()]
			if not _battle.advance():
				_finish_beaten()
				return
			body.call("recall")
			_queue_send_out(_battle.current_index(), float(DATA.flow().get("send_out_delay", 1.6)))
		"caught":
			# Unreachable, and loud rather than silent if it ever is not.
			# `catch_math.can_be_caught()` refuses a trainer-owned creature and
			# `combat_manager` asks it twice — before the aim opens and again when
			# the orb lands. If this line is ever hit, CLAUDE.md's hard rule has a
			# hole in it and the fight must not carry on as though it had not.
			push_error("A TRAINER-OWNED PAL WAS CAUGHT. This must be impossible; see catch_math.can_be_caught.")
			_break_off()
		_:
			# "lost" or "fled". Either way the player is out of this battle.
			_break_off()


## The trainer's last creature has gone down.
##
## The bodies are cleared after a PAUSE, not immediately. The director slumps the
## creature that just fell — the same body-on-the-ground feedback a wild faint
## gives, and §15's reason for it — and hiding it in the same frame would delete
## the one beat the whole battle has been building to. The Warden plays his
## beaten clip into that pause with the creature still lying in front of him.
##
## `beaten` fires NOW rather than after the pause, so the tether snaps as the last
## creature drops rather than a second and a half later for no reason the player
## can see.
func _finish_beaten() -> void:
	_active = false
	_send_out_left = 0.0
	_clear_left = maxf(0.1, float(DATA.flow().get("send_out_delay", 1.6)))
	if _model != null:
		_model.call("play_role", MODEL.ROLE_BEATEN)
	beaten.emit(trainer_id)


func _recall_everyone() -> void:
	_clear_left = 0.0
	for body in _bodies:
		if is_instance_valid(body):
			body.call("recall")


## The player disengaged. Put the team back, if the config says to.
##
## `restore_on_disengage` is a difficulty mechanic and `data/config/trainers.json`
## says why at length: without it, any trainer is beatable by attrition across
## unlimited attempts, and M14's "meaningful difficulty" becomes meaningful
## patience. The player's own party is NOT restored, and that asymmetry is the
## fight — your damage carries, theirs does not.
func _break_off() -> void:
	_active = false
	_send_out_left = 0.0
	_pending_index = -1
	_recall_everyone()
	var restore := bool(DATA.flow().get("restore_on_disengage", true))
	if restore and _battle != null:
		_battle.restore()
	broke_off.emit(trainer_id, restore)


## Where the freed legendary should be told to stand, and what the route needs to
## know about this post's geometry. Public because `stronghold_route` places the
## pylon relative to the Warden rather than at an absolute coordinate that would
## have to be kept in step with his by hand.
func post_forward() -> Vector3:
	var forward := global_transform.basis.z
	forward.y = 0.0
	return Vector3.FORWARD if forward.length() < 0.01 else forward.normalized()
