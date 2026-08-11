extends Node

## The first fifteen minutes: which beat we are on, and what is possible during
## it. docs/OPENING_SEQUENCE.md is the prose version and the two are meant to be
## read together.
##
## Everything this drives already existed and none of it was connected. There
## was dialogue with nobody to start it, an interact arbiter with a modal
## lockout nothing switched, an `Interactable.enabled` flag written for exactly
## this job and never set, a naming panel nothing opened, and two methods on
## `encounter_director.gd` — `suspend_default_starter()` and `adopt_starter()` —
## whose own comments named this file as their caller while this file did not
## exist. The slice was built systems-first and the sequence was never built at
## all; this is the sequence.
##
## Split the same way `encounter_director.gd` is split from `combat_manager.gd`.
## The manager knows how a fight resolves and nothing about the world; the
## encounter director knows about the world and nothing about damage; this knows
## about the ORDER OF THINGS and nothing about either. It starts conversations
## rather than drawing them, asks for a pal rather than spawning one, and reads
## the outcome of a fight rather than running one.
##
## It does spawn Grandpa, because nothing else does and his placement is
## already written down in data/config/opening.json. That is placement, not
## behaviour: Grandpa turns to look at you because `npc_body.gd` does that.
##
## The three starters no longer get bodies of their own in the meadow
## (`SA0-orbs`, owner directive 2026-08-11 — see docs/OPENING_SEQUENCE.md's
## own record of the reversal). They are previewed live, in orbs, by
## `starter_picker.gd`, which this file opens once Grandpa's briefing ends and
## reads back a choice from — the same "ask a panel, read the outcome" split
## this file already keeps with `dialogue_panel.gd` and `name_prompt.gd`.
##
## Beat order and the per-beat conversations are DATA
## (`data/config/opening.json`, read through `opening_beats.gd`). This file
## names six beats in code because the machine has to recognise them —
## `opening_beats.missing_beats()` fails loudly at boot if the data no longer
## contains one, which is the difference between a renamed beat and a gate that
## silently never opens.

const BEATS := preload("res://scripts/story/opening_beats.gd")
const RUNNER := preload("res://scripts/story/dialogue_runner.gd")
const INTERACTABLE := preload("res://scripts/world/interactable.gd")
const NPC := preload("res://scripts/npc/npc_body.gd")
const SPECIES := preload("res://scripts/pals/pal_species.gd")

## Mirrors CombatManager.OUTCOME_CAUGHT rather than typing "caught" twice, so a
## renamed outcome cannot silently stop matching here. Same reason
## encounter_director.gd declares its own.
const CAUGHT := "caught"

## The dialogue key `$name` is substituted from. data/dialogue/opening.json
## writes `$name` and this is the other half of that agreement.
const NAME_KEY := "name"

## How many physics frames to keep trying to stand something on the ground.
##
## Terrain3D builds its collision over several frames after the data directory
## loads, and anything placed before then ends up at the world origin under the
## terrain with no error printed. Same value and same reason as
## encounter_director.GROUND_WAIT_FRAMES.
const GROUND_WAIT_FRAMES := 300

## Above the dialogue panel (5) and the naming panel (6), below the pause menu
## (20). A fade-in that the HUD draws over is not a fade-in.
const FADE_LAYER := 15

signal beat_changed(beat: String)

@export var player_path: NodePath
@export var arbiter_path: NodePath
@export var encounter_path: NodePath
@export var manager_path: NodePath
@export var camera_rig_path: NodePath
@export var dialogue_path: NodePath
@export var name_prompt_path: NodePath
@export var starter_picker_path: NodePath

var _player: Node3D = null
var _arbiter: Node = null
var _encounter: Node = null
var _manager: Node = null
var _camera_rig: Node = null
var _dialogue: CanvasLayer = null
var _name_prompt: CanvasLayer = null
var _starter_picker: CanvasLayer = null

var _beat: String = ""

var _grandpa: Node3D = null
var _grandpa_prompt: Node3D = null
var _bed_prompt: Node3D = null
## The house, if this world built one — SA2's door gate lives on it (a
## collision box across the doorway; this director only decides when it is
## solid). Null in a bare test scene, which is a legal world and simply has
## no door to gate.
var _house: Node3D = null
## Where the bed is, in world space. Held separately from `_bed_prompt` because
## the wake beat's positional fallback has to work even when no prompt was ever
## built — which is the second, harder route into the same soft-lock: a world
## with no house builds no bed prompt, and `wake` then has NO exit at all.
var _bed_anchor: Variant = null
## The three starter species, in the order the orb picker shows them. The
## index IS the choice and it is what both the picker and the naming panel
## come back with.
var _starter_species: Array[String] = []
var _choice: int = -1
## Set the instant the beat reaches `choose`, cleared once the picker actually
## opens. The beat can only change while the dialogue that carries the effect
## is still open (`_drain_effects` runs before the player has closed it), so
## the picker cannot open the same frame — it waits for the box to clear.
var _picker_pending: bool = false

## True from the moment a name is confirmed until the pal is standing beside the
## trainer. `adopt_starter` waits for ground, so there are frames in there where
## no panel is open and the player must still not be able to walk off.
var _adopting: bool = false

var _fade_layer: CanvasLayer = null
var _fade_rect: ColorRect = null
var _fade_hold: float = 0.0
var _fade_left: float = 0.0
var _fade_total: float = 0.0


func _ready() -> void:
	_encounter = get_node_or_null(encounter_path)
	# FIRST, before anything else in this function and before any await.
	#
	# encounter_director spawns its sandbox starter behind
	# `await get_tree().process_frame`, and every `_ready` in the tree completes
	# before the next idle frame does — so this is the only window in which the
	# default pal can be called off. Move it below an await and the player is
	# given a terrapup they did not choose, and `adopt_starter` then refuses the
	# one they did.
	if _encounter != null:
		_encounter.call("suspend_default_starter")

	_player = get_node_or_null(player_path) as Node3D
	_arbiter = get_node_or_null(arbiter_path)
	_manager = get_node_or_null(manager_path)
	_camera_rig = get_node_or_null(camera_rig_path)
	_dialogue = get_node_or_null(dialogue_path) as CanvasLayer
	_name_prompt = get_node_or_null(name_prompt_path) as CanvasLayer
	_starter_picker = get_node_or_null(starter_picker_path) as CanvasLayer

	if _player == null or _arbiter == null or _encounter == null or _manager == null \
			or _dialogue == null or _name_prompt == null or _starter_picker == null:
		push_error("the sequence director is missing wiring: player=%s arbiter=%s encounter=%s manager=%s dialogue=%s name_prompt=%s starter_picker=%s" % [
			_player != null, _arbiter != null, _encounter != null, _manager != null,
			_dialogue != null, _name_prompt != null, _starter_picker != null
		])
		set_process(false)
		return

	# The panels are in the tree — but are they the panels?
	#
	# A .tscn whose script failed to parse instantiates as a bare CanvasLayer:
	# the node is there, the path resolves, and every call into it fails. It is
	# not hypothetical. `name_prompt.gd` had a type-inference parse error under
	# 4.7 and the scene was loading with no script at all, which showed up as
	# `_process` throwing "nonexistent function 'is_open'" once a frame forever.
	# One error at boot naming the node beats sixty a second naming a method.
	if not _dialogue.has_method("start") or not _dialogue.has_method("drain_effects") \
			or not _name_prompt.has_method("open") or not _name_prompt.has_signal("confirmed") \
			or not _starter_picker.has_method("open") or not _starter_picker.has_signal("chosen"):
		push_error("%s, %s and/or %s are in the scene but are not answering their own API; check for a parse error in their scripts" % [
			_dialogue.name, _name_prompt.name, _starter_picker.name
		])
		set_process(false)
		return

	_check_the_data()

	# The arbiter becomes the one voice for the prompt line and the one reader of
	# the interact button. Without this the encounter director keeps its own
	# hardcoded "Engage X" and two nodes read the same press, so walking between
	# Grandpa and a wild pal talks to him AND starts a fight.
	_encounter.call("set_arbiter", _arbiter)
	# Late binding rather than making the scene set `arbiter.player_path`: this
	# node already had to be given the player, and two places naming the same
	# body is one of them being wrong.
	_arbiter.call("set_player", _player)

	_manager.connect("entered", _on_combat_entered)
	_manager.connect("exited", _on_combat_exited)
	_name_prompt.connect("confirmed", _on_name_confirmed)
	_starter_picker.connect("chosen", _on_starter_picker_chosen)

	_build_fade()
	_set_beat(BEATS.first())

	# One frame, for the same reason encounter_director waits: add_child() is
	# refused while the parent is still setting up its children, and the world's
	# own `_ready` — which drops the player onto the baked ground — has not run
	# yet, so `_player.global_position` is still whatever the scene said.
	await get_tree().process_frame
	await _spawn_the_cast()


## Fail at boot rather than at the beat.
##
## A beat id renamed in data/config/opening.json, or a dialogue effect pointing
## at a beat that is not in the list, produces a sequence that plays perfectly up
## to the point where it silently stops advancing. That is the worst possible
## shape for this bug: nothing errors, the player just stands in a meadow with
## nothing to do.
func _check_the_data() -> void:
	var missing: Array[String] = BEATS.missing_beats()
	if not missing.is_empty():
		push_error("data/config/opening.json has no beat(s) named %s; the gates gated by them will never open" % ", ".join(missing))
	var broken: Array[String] = BEATS.broken_effects()
	if not broken.is_empty():
		push_error("opening.json maps effect(s) %s to a beat that is not in the list; those conversations will end and change nothing" % ", ".join(broken))


## --- the beat -----------------------------------------------------------------

func beat() -> String:
	return _beat


func is_fading() -> bool:
	return _fade_rect != null and is_instance_valid(_fade_rect)


## Move to a named beat. The only way `_beat` changes.
##
## Refuses to go backwards. Nothing in the opening should, and the way it would
## happen is a conversation the player can re-run emitting its effect a second
## time — which would put the starters back on offer after they had been chosen.
func _set_beat(target: String) -> void:
	if target == "" or target == _beat:
		return
	if not BEATS.has(target):
		push_error("no beat named '%s' in data/config/opening.json" % target)
		return
	if BEATS.index_of(target) < BEATS.index_of(_beat):
		push_warning("refused to move the opening back from '%s' to '%s'" % [_beat, target])
		return
	_beat = target
	beat_changed.emit(_beat)
	if _beat == BEATS.CHOOSE:
		# Not opened here directly: this fires while `_drain_effects` is still
		# reading the line that carries `beat:starter_choice`, and the dialogue
		# box is still on screen over it. `_maybe_open_picker` waits for that
		# box to close.
		_picker_pending = true


## `_advance()` used to live here — `_set_beat(BEATS.next(_beat))`, with no
## callers anywhere in `scripts/`, `tests/` or `tools/`. Deleted by R9.4's
## soft-lock investigation rather than wired up: a generic "go to the next beat"
## is the wrong shape for this machine. Every real transition is caused by
## something specific (a prompt, a dialogue effect, a fight ending), and a
## caller-less shortcut that skips whatever that thing was is how a beat gets
## entered without its staging.

func _process(delta: float) -> void:
	_tick_fade(delta)
	_drain_effects()
	_refresh_lockout()
	_refresh_prompts()
	_refresh_door_gate()
	_check_left_the_bed()
	_maybe_open_picker()


## Effects are drained in production, here, every frame.
##
## `dialogue_panel.drain_effects()` has existed since the panel was written and
## its only caller was a unit test, which is how a conversation carrying
## `beat:starter_choice` could play end to end and unlock nothing. Drained per
## frame rather than on `finished`, so an effect takes hold when its line is
## SPOKEN — the intro's last line offers the choice while it is still on screen,
## and the prompts are live the instant the box closes.
func _drain_effects() -> void:
	for effect: String in _dialogue.call("drain_effects"):
		var parts: Array = RUNNER.parse_effect(effect)
		match str(parts[0]):
			"beat":
				var target := BEATS.beat_for_effect(str(parts[1]))
				if target == "":
					push_warning("dialogue asked for '%s' but opening.json's beats.effects does not map it" % effect)
					continue
				_set_beat(target)
			"give":
				_give_items(parts)
			_:
				push_warning("the opening ignored dialogue effect '%s'; it knows 'beat:' and 'give:' and nothing else" % effect)


## `give:orb_basic:15` — Grandpa's parting gifts, granted on the line that
## mentions them so the words and the satchel agree. Into the REAL inventory
## through the same autoload everything else uses; a full satchel is warned
## about rather than silently swallowed, because a player who was promised
## fifteen orbs and got twelve has no way to know.
##
## `parse_effect` splits on the FIRST colon only, so parts[1] here is
## "orb_basic:15" and the id/count split is this function's own job.
func _give_items(parts: Array) -> void:
	var rest := str(parts[1]).split(":")
	if rest.size() != 2 or not str(rest[1]).is_valid_int():
		push_warning("a give: effect reads give:<item_id>:<count>; got 'give:%s'" % parts[1])
		return
	var item_id := str(rest[0])
	var count := int(str(rest[1]))
	var game := get_node_or_null(^"/root/Game")
	if game == null:
		push_error("no Game autoload; '%s' was given to nobody" % item_id)
		return
	var items: RefCounted = game.get("items")
	if items != null and not bool(items.call("has", item_id)):
		push_error("dialogue gives '%s', which data/items/items.json does not define" % item_id)
		return
	var inventory: RefCounted = game.get("inventory")
	var leftover := int(inventory.call("add", item_id, count))
	if leftover > 0:
		push_warning("the satchel was full; %d of the %d %s did not fit" % [leftover, count, item_id])


## --- what is possible right now -------------------------------------------------
##
## Polled, not pushed. Same house rule as `combat_hud.gd` and the pause menu: the
## gates are recomputed from the beat every frame and nothing keeps a second copy
## of "are the starters offering". A gate that is set once when a beat changes is
## a gate that is wrong the first time something else touches it.

## The modal lockout, through the mechanism built for it.
##
## `InteractionArbiter.set_enabled()` was written with the comment "cleared while
## a conversation, a naming prompt or a fight owns the screen" and had no callers
## at all. These are those three, plus the fade.
##
## The fight case is not decoration. `interact` and `combat_charged` are the same
## physical button (X), so with the arbiter live during a fight, one press both
## swings your pal and opens a conversation with Grandpa if the fight happened to
## start near him.
func _refresh_lockout() -> void:
	var fighting: bool = _manager != null and bool(_manager.call("is_fighting"))
	var panel: bool = bool(_dialogue.call("is_open")) or bool(_name_prompt.call("is_open")) \
			or bool(_starter_picker.call("is_open"))
	var modal := panel or is_fading() or _adopting

	_arbiter.call("set_enabled", not modal and not fighting)

	# Locomotion and the camera belong to combat while a fight is running.
	# Handing them back here every frame would undo what the encounter director
	# and the combat manager just did to them.
	if fighting:
		return
	if _player.has_method("set_locomotion_enabled"):
		_player.call("set_locomotion_enabled", not modal)
	if _camera_rig != null and is_instance_valid(_camera_rig):
		# The rig has no suspend of its own, so its idle tick — which is where
		# both the stick look and the follow live — is switched off. Not during
		# the fade: the world is black, but the camera still has to be sitting
		# behind the player by the time it clears.
		_camera_rig.set_process(not panel)


## Grandpa offers his prompt on any beat he has something to say on.
func _refresh_prompts() -> void:
	if _grandpa_prompt != null and is_instance_valid(_grandpa_prompt):
		_grandpa_prompt.call("set_enabled", BEATS.conversation_for(_beat) != "")
	if _bed_prompt != null and is_instance_valid(_bed_prompt):
		_bed_prompt.call("set_enabled", _beat == BEATS.WAKE)


## SA2 (spec sec1D). "The player cannot leave Grandpa's house until the
## required Grandpa opening interaction is complete." The physical stop is
## grandpa_house.gd's own collision box; this decides when it is solid, and
## opens it for good once the beat that sends the player outdoors is
## reached — the spec's own "never re-triggers this gate" once earned.
##
## The one thing it does beyond blocking: an approach at the door, while the
## required briefing has not been heard yet, starts it — the same
## conversation pressing interact on Grandpa would open. Spec sec1D is
## explicit that a sterile "the door is locked" message is the wrong shape
## here — the player is meant to walk toward the door, get called back, and
## end up in the conversation naturally, not read an error about it.
##
## Restricted to the `house` beat specifically, not every beat the gate
## covers. `choose` and `name` are also before `walk_out` (the door stays
## physically shut through both, correctly), but their own conversations
## are incidental ("Still deciding?"), not the required one — and the
## player is standing right where the briefing left them, close enough to
## the door to be back inside the callout radius the instant a panel closes.
## Triggering on every gated beat reopens a new conversation the moment the
## last one's box clears, which starves `_maybe_open_picker()` of the
## closed-dialogue frame it needs and the starter picker never opens.
func _refresh_door_gate() -> void:
	if _house == null or not is_instance_valid(_house):
		return
	var door_open := BEATS.at_or_after(_beat, BEATS.WALK_OUT)
	_house.call("set_door_open", door_open)
	if door_open or _beat != BEATS.HOUSE:
		return
	if bool(_dialogue.call("is_open")) or _adopting:
		return
	var door: Vector3 = _house.call("marker", "door")
	if _player.global_position.distance_to(door) > DOOR_CALLOUT_RADIUS:
		return
	_start_conversation(BEATS.conversation_for(_beat))


## The picker cannot open on the same frame the beat reaches `choose` — the
## dialogue box carrying that effect is still open on that frame — so this
## polls until it closes, the same "recomputed every frame, no pushed state"
## house rule `_refresh_lockout` and `_refresh_prompts` already follow.
func _maybe_open_picker() -> void:
	if not _picker_pending:
		return
	if bool(_dialogue.call("is_open")):
		return
	_picker_pending = false
	if _choice >= 0:
		return
	_starter_picker.call("open", _starter_species)


## --- beat 1: the fade ------------------------------------------------------------

## Beat 1 is a fade-in from black rather than an interior, which saves an entire
## interior art pass for a beat that lasts forty seconds
## (docs/OPENING_SEQUENCE.md). Both numbers are in data/config/opening.json and
## until now nothing read them.
##
## Built in code rather than added to the scene: it is two nodes with no layout,
## it belongs to this beat and to nothing else, and a scene the world has to
## remember to include is a scene one world will be missing.
func _build_fade() -> void:
	var cfg := BEATS.fade()
	_fade_total = maxf(float(cfg.get("seconds", 1.6)), 0.01)
	_fade_hold = float(cfg.get("hold_seconds", 0.5))
	_fade_left = _fade_total

	_fade_layer = CanvasLayer.new()
	_fade_layer.name = "OpeningFade"
	_fade_layer.layer = FADE_LAYER
	add_child(_fade_layer)

	_fade_rect = ColorRect.new()
	_fade_rect.name = "Black"
	_fade_rect.color = Color(0.0, 0.0, 0.0, 1.0)
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	# The black must not eat the cursor: the naming panel releases the mouse and
	# this is the layer above it.
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_layer.add_child(_fade_rect)


func _tick_fade(delta: float) -> void:
	if not is_fading():
		return
	if _fade_hold > 0.0:
		_fade_hold -= delta
		return

	_fade_left -= delta
	_fade_rect.color.a = clampf(_fade_left / _fade_total, 0.0, 1.0)
	if _fade_left > 0.0:
		return

	_fade_layer.queue_free()
	_fade_layer = null
	_fade_rect = null
	# The fade clearing no longer advances the beat: the opening starts in bed,
	# and `wake` ends when the player chooses to get up — the bed's own
	# interactable carries that. What the fade's end DOES mean is that the
	# player can see the room; the beat machine does not need telling.


## --- the cast ---------------------------------------------------------------------

## The whole staging: the player into the bed, Grandpa downstairs — both read
## from the HOUSE's own markers, because the building is the authority on
## where its bed is. A world without a house (a bare test scene) falls back to
## opening.json's positions.
##
## Cast parented to this node's PARENT rather than to this node, matching
## encounter_director: `pal_body` and `npc_body` both find the ground by walking
## up the tree looking for `ground_height_at`, and the world root is what offers
## it. A creature hung under a plain Node is also outside the 3D transform chain.
func _spawn_the_cast() -> void:
	var house := await _wait_for_the_house()
	_house = house
	var cfg := BEATS.grandpa()

	if house != null:
		# Into bed. The world's own _place_player already ran (the house is
		# only built after it), so nothing later overwrites this.
		var bed: Vector3 = house.call("marker", "bed")
		_player.global_position = bed + Vector3(0.6, 0.4, 0.0)
		_player.velocity = Vector3.ZERO
		_bed_anchor = bed
		_build_bed_prompt(house)
	else:
		# NO HOUSE. The comment above used to claim "the old open-meadow staging
		# still works" here. It did not, and could not: without a house there is
		# no bed prompt, and until R9.4's fix the bed prompt was the ONLY exit
		# from the wake beat — so a houseless world pinned the beat at `wake`
		# forever and Grandpa never spoke. Anchoring on the player's own start
		# position gives the positional fallback something to measure against,
		# so walking away still opens the beat.
		_bed_anchor = _player.global_position

	_grandpa = NPC.new()
	_grandpa.name = "Grandpa"
	get_parent().add_child(_grandpa)
	_grandpa.call("setup", str(cfg.get("art", "grandpa")), _player)

	if house != null:
		# Indoors: the house floor is a body, not terrain, so `stand_at`'s
		# ground query would sink him below the slab. The marker knows better.
		_grandpa.global_position = (house.call("marker", "grandpa") as Vector3) + Vector3(0.0, 0.12, 0.0)
		# Facing the foot of the stairs, where the player will appear from.
		_grandpa.rotation.y = deg_to_rad(-80.0)
	else:
		var spot := _player.global_position + _to_vector3(cfg.get("offset", []))
		if not await _stand_npc(_grandpa, spot):
			push_error("no ground under Grandpa's spot; the house beat has nobody to talk to")
		var towards := _player.global_position - _grandpa.global_position
		towards.y = 0.0
		if towards.length() > 0.01:
			_grandpa.rotation.y = atan2(towards.x, towards.z)

	_grandpa_prompt = _grandpa.call("add_prompt",
		str(cfg.get("prompt", "Talk to Grandpa")),
		float(cfg.get("prompt_radius", 3.8)))
	_grandpa_prompt.call("set_enabled", false)
	_grandpa_prompt.connect("activated", _on_grandpa_activated)

	_load_starter_species()


## The house is built by the world root at the end of ITS _ready, several
## frames after this director's. Null after the wait means this world has no
## house, which is a legal world — the smoke tests' bare boots included.
func _wait_for_the_house() -> Node3D:
	for i in GROUND_WAIT_FRAMES:
		var house := get_parent().get_node_or_null(^"GrandpaHouse") as Node3D
		if house != null:
			return house
		# A world that will never build one: no point burning five seconds.
		if get_parent().get_node_or_null(^"Terrain") == null and i > 10:
			return null
		await get_tree().physics_frame
	return null


## "Get up." The wake beat's one gate, on the bed itself.
func _build_bed_prompt(house: Node3D) -> void:
	var bed_cfg := BEATS.bed()
	var prompt: Node3D = INTERACTABLE.new()
	prompt.name = "BedPrompt"
	prompt.position = (house.call("marker", "bed") as Vector3) + Vector3.UP * 0.4
	prompt.call("configure", str(bed_cfg.get("prompt", "Get up")), 2.5, true)
	prompt.connect("activated", _on_bed_activated)
	get_parent().add_child(prompt)
	_bed_prompt = prompt


func _on_bed_activated() -> void:
	if _beat != BEATS.WAKE:
		return
	_set_beat(BEATS.HOUSE)


## Getting out of bed ends the wake beat, however you do it.
##
## THIS IS THE FIX FOR A SOFT-LOCK THAT MADE THE GAME UNCOMPLETABLE, and it is
## worth spelling out because the shape of it will recur.
##
## `wake` had exactly one exit — pressing interact on the bed — and nothing
## forced the player through it. `_refresh_lockout()` never gated locomotion on
## the beat, so once the fade cleared you could simply walk off the bed. Do that
## and the beat stays `wake` forever. `_refresh_prompts()` then keeps Grandpa's
## interactable disabled (his `conversation_for("wake")` is ""), which makes
## `interactable.gd` return an empty offer, which means the arbiter never even
## sees him: no prompt, and the button does nothing. The owner's report —
## "you still can't interact with grandpa at the beginning, so then you leave
## the house and never get a starter" — is that state exactly.
##
## The lesson generalises: a beat whose only exit is one optional button press
## is a soft-lock waiting to happen. Any beat gate added later wants a
## positional fallback like this one, or a lockout that makes the intended
## action the only available one.
##
## Distance from the bed rather than a floor height test: the loft has no
## collision volume of its own to leave, and a height test would fire while the
## player is still standing on the mattress. `BED_LEAVE_RADIUS` is comfortably
## outside the bed prompt's own 2.5 m so pressing the prompt still reads as the
## intended path, and comfortably inside the loft so descending the stairs
## cannot outrun it.
const BED_LEAVE_RADIUS := 3.2

## SA2 (spec sec1D). How close to the exterior doorway counts as "trying to
## leave" — Grandpa calls out before the player actually collides with the
## gate, so the redirect reads as noticing them heading for the door rather
## than as bumping into an invisible wall and only then getting a reaction.
## Comfortably inside the door's own solid collision (built in
## grandpa_house.gd, roughly 1.2m short of the "door" marker this measures
## against).
const DOOR_CALLOUT_RADIUS := 2.6

func _check_left_the_bed() -> void:
	if _beat != BEATS.WAKE or _bed_anchor == null:
		return
	if _player.global_position.distance_to(_bed_anchor) < BED_LEAVE_RADIUS:
		return
	_set_beat(BEATS.HOUSE)


## Read straight off data/config/opening.json's `starters.species`. No bodies,
## no placement — the orb picker builds its own live previews from this list
## when the beat reaches `choose` (`_maybe_open_picker`).
func _load_starter_species() -> void:
	var species: Array = BEATS.starters().get("species", [])
	if species.is_empty():
		push_error("opening.json lists no starter species; the choice has nothing to choose from")
		return
	for id: Variant in species:
		_starter_species.append(str(id))


func _display_name(species_id: String) -> String:
	return str(SPECIES.definition(species_id).get("display_name", species_id))


func _stand_npc(npc: Node3D, spot: Vector3) -> bool:
	for i in GROUND_WAIT_FRAMES:
		if bool(npc.call("stand_at", spot.x, spot.z)):
			return true
		await get_tree().physics_frame
	return false


## `[10.0, 0.0, 32.0]` out of JSON. Y is ignored everywhere in opening.json —
## everything is stood on the ground by asking the world (docs/decisions/D09) —
## but it is carried here so a config with a Y in it is not silently reshaped.
func _to_vector3(raw: Variant) -> Vector3:
	if not raw is Array or (raw as Array).size() < 3:
		return Vector3.ZERO
	var values: Array = raw
	return Vector3(float(values[0]), float(values[1]), float(values[2]))


## --- beat 3: Grandpa ---------------------------------------------------------------

func _on_grandpa_activated() -> void:
	_start_conversation(BEATS.conversation_for(_beat))


func _start_conversation(id: String) -> bool:
	if id == "":
		return false
	if bool(_dialogue.call("is_open")):
		return false
	return bool(_dialogue.call("start", id))


## --- beats 4 and 5: the choice, and the name ------------------------------------------

func _on_starter_picker_chosen(index: int) -> void:
	if _beat != BEATS.CHOOSE or _adopting:
		return
	if index < 0 or index >= _starter_species.size():
		return
	_choice = index
	# Naming is mandatory, not skippable (docs/OPENING_SEQUENCE.md): a pal you did
	# not name is a pal you did not adopt. The panel has no cancel, and the beat
	# does not advance until it comes back with a word.
	_name_prompt.call("open", _display_name(_starter_species[index]))


func _on_name_confirmed(chosen: String) -> void:
	if _choice < 0:
		push_error("a name came back with no starter chosen")
		return
	await _adopt(_choice, chosen)


func _adopt(index: int, chosen: String) -> void:
	_adopting = true
	var species := _starter_species[index]

	# The other two never got bodies at all (SA0-orbs) — there is nothing left
	# in the world to free. `encounter_director.adopt_starter()` builds the one
	# real follower body below, for the one the player actually chose.
	var adopted: bool = await _encounter.call("adopt_starter", species, chosen)
	_adopting = false
	if not adopted:
		push_error("could not give the player the %s they chose" % species)
		return

	if not _give_to_party(_encounter.call("ally_instance"), chosen):
		push_error("the chosen %s is beside the trainer but not in the party" % species)

	# The first time this game says a word the player wrote.
	_dialogue.call("set_value", NAME_KEY, chosen)
	_set_beat(BEATS.NAMED)
	# Started here rather than waiting for them to walk back to him: the reply is
	# the beat, and data/dialogue/opening.json says so ("Immediately after the
	# name is entered"). Its last line carries `beat:first_encounter`.
	_start_conversation(BEATS.named_conversation())


## --- beats 6, 7 and 8: the encounter, the fight and the catch ----------------------------
##
## None of this is reimplemented here. The wild bramblebun, the engage prompt,
## the fight and the throw are `encounter_director.gd` and `combat_manager.gd`
## and they already work; this reads the result and moves the beat.
##
## Nothing gates the encounter either, and nothing needs to: the encounter
## director offers no engagement while the player has no pal, so beats 1 to 5 are
## already unreachable from a fight.

func _on_combat_entered() -> void:
	if _beat == BEATS.WALK_OUT:
		_set_beat(BEATS.ENCOUNTER)


func _on_combat_exited(outcome: String) -> void:
	if outcome != CAUGHT:
		# They won it instead of catching it, or ran. The encounter director puts
		# the bramblebun back on its feet after a few seconds, so the beat stays
		# where it is and they get another go — species.json gives that creature
		# the highest catch rate in the game precisely so the tutorial catch does
		# not have to succeed first time.
		return

	var kept: RefCounted = _manager.call("caught_instance")
	if kept == null:
		push_error("combat ended as a catch with nothing caught")
		return
	# No nickname. GAME_DESIGN.md 10: a new capture keeps its species name by
	# default, and `pal_instance.nickname` stays empty so the party screen can
	# still tell a pal the player never renamed from one they deliberately named
	# after its species.
	if not _give_to_party(kept, ""):
		push_error("the caught %s never reached the party" % kept.species_id)
	_set_beat(BEATS.ROAD)


## --- the party -------------------------------------------------------------------

## Into the real party, which is `Game`'s.
##
## Not through `scripts/story/party_seam.gd`. That file was written while there
## was no autoload to hold a party, and it says so in its own TODO; there is one
## now, `autoload/party.gd` enforces the five-pal cap in `add()` and nowhere
## else, and a second path into the party is a second place the cap can be
## missed.
##
## Looked up by path rather than through the `Game` global so a null is a
## push_error at the one call site instead of a crash, and so this node can be
## dropped into a scene run outside the normal boot.
func _give_to_party(instance: RefCounted, nickname: String) -> bool:
	if instance == null:
		return false
	if nickname != "":
		instance.set("nickname", nickname)

	var game := get_node_or_null(^"/root/Game")
	if game == null:
		push_error("no Game autoload; the pal exists but nobody owns it")
		return false
	var party: RefCounted = game.get("party")
	if party == null:
		push_error("the Game autoload has no party")
		return false

	if bool(party.call("is_full")):
		# The opening cannot reach this — it adds two pals to an empty party —
		# but the sixth-pal release ceremony is real design (GAME_DESIGN.md 3)
		# and a director that silently dropped a pal would hide the day it starts
		# mattering.
		push_warning("the party is full; %s was not added" % instance.get("display_name"))
		return false
	return bool(party.call("add", instance))
