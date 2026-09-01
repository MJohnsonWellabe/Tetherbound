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
## rather than drawing them, asks for a creature rather than spawning one, and reads
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
## F3/GATE-F-LEG-S10CDE. `greeting_for()` is what reads a villager's
## `greeting_when` ladder; `_grandpa_conversation_id()` reuses it for
## Grandpa's own ladder (opening_beats.gd's `grandpa_conversations_when()`)
## rather than re-implementing the same first-match-wins lookup a second time.
const VILLAGE_NPCS := preload("res://scripts/world/village_npcs.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const CATCH := preload("res://scripts/combat/catch_math.gd")
## D39 (OF31). The two trading screens a villager's `shop:` effect can open.
const SHOP_PANEL := preload("res://scripts/ui/shop_panel.gd")
const SWAP_PANEL := preload("res://scripts/ui/swap_panel.gd")
const SHOP_GOODS := "goods"
const SHOP_CREATURES := "creatures"

## RG7. Opening progress belongs in the existing flat progression store. One
## stable flag per reached beat preserves an in-progress save without growing
## ProgressionState into a story object; the latest flag in opening.json's
## canonical order is the resumed beat. STARTER_GRANTED is a separate fact so
## the grant is guarded even if old/corrupt beat flags are absent.
const OPENING_BEAT_PREFIX := "opening:beat:"
const STARTER_GRANTED_FLAG := "opening:starter_granted"

## The tier the tutorial's orb floor restocks. Named rather than derived from
## `catch_math.best_orb()`: the floor exists to keep the opening playable, not
## to hand out a tier the player has not earned, and at this point in the game
## the basic orb is the only one that exists anyway.
const TUTORIAL_ORB := "orb_basic"

## SC12/SC13. The table `battle:<trainer_id>` reads from — the same reader
## `trainer_npc.gd` itself uses, so a villager's challenge and a standalone
## trainer's challenge look up the exact same data.
const TRAINERS := preload("res://scripts/world/trainer_npc.gd")

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

## OF8. How far, along the bed's own length, the player's feet land from the
## "bed" marker — which sits near the headboard/pillow end (confirmed against
## `BedTwin.obj`'s vertices: the marker falls just past the taller, more
## decorative end of the two). Feet-out rather than head-out because
## `character_model.gd::set_lying()`'s rotation pivots the body around its
## feet and swings the head end toward -Z from there; 1.5m lands the feet at
## the OTHER (shorter, footboard) end of the same mesh, which is the mattress
## actually being roughly the trainer's own height (~1.8m) long inside its
## frame. TUNABLE — a different bed model changes both numbers.
const BED_LIE_REACH := 1.5

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

## D39 (OF31). `[kind, vendor_id]` while a villager's `shop:` effect is waiting
## for the dialogue box to close, empty otherwise. Same "wait for the box"
## problem `_picker_pending` above solves, same shape.
var _shop_pending: Array = []
var _shop_panel: CanvasLayer = null

## SC12/SC13. The trainer id a `battle:` effect named, while it waits for the
## dialogue box to close — same "wait for the box" shape as `_shop_pending`,
## and for the identical reason: `_drain_effects` reads the last line of a
## challenge conversation while that line is STILL ON SCREEN, and opening a
## fight under an open dialogue box is the bug both of these avoid.
var _battle_pending: String = ""
var _swap_panel: CanvasLayer = null

## True from the moment a name is confirmed until the creature is standing beside the
## trainer. `adopt_starter` waits for ground, so there are frames in there where
## no panel is open and the player must still not be able to walk off.
var _adopting: bool = false

var _fade_layer: CanvasLayer = null
var _fade_rect: ColorRect = null
var _fade_hold: float = 0.0
var _fade_left: float = 0.0
var _fade_total: float = 0.0


func _ready() -> void:
	add_to_group("progression_restore")
	_encounter = get_node_or_null(encounter_path)
	# FIRST, before anything else in this function and before any await.
	#
	# encounter_director spawns its sandbox starter behind
	# `await get_tree().process_frame`, and every `_ready` in the tree completes
	# before the next idle frame does — so this is the only window in which the
	# default creature can be called off. Move it below an await and the player is
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
	# Grandpa and a wild creature talks to him AND starts a fight.
	_encounter.call("set_arbiter", _arbiter)
	# Late binding rather than making the scene set `arbiter.player_path`: this
	# node already had to be given the player, and two places naming the same
	# body is one of them being wrong.
	_arbiter.call("set_player", _player)

	_manager.connect("entered", _on_combat_entered)
	_manager.connect("exited", _on_combat_exited)
	_manager.connect("catch_refused", _on_catch_refused)
	_name_prompt.connect("confirmed", _on_name_confirmed)
	_starter_picker.connect("chosen", _on_starter_picker_chosen)

	_restore_opening_beat()
	if _beat == BEATS.WAKE:
		_build_fade()

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
	_persist_beat_history(_beat)
	beat_changed.emit(_beat)
	if _beat == BEATS.CHOOSE:
		# Not opened here directly: this fires while `_drain_effects` is still
		# reading the line that carries `beat:starter_choice`, and the dialogue
		# box is still on screen over it. `_maybe_open_picker` waits for that
		# box to close.
		_picker_pending = true


## Restore the latest reached beat, including an older save written before RG7
## had opening flags. A party member is definitive evidence that the starter
## opportunity must not be offered again; two members additionally mean the
## old tutorial catch has already happened. Compatibility inference is used
## ONLY when no saved opening beat exists: a current save with two creatures at
## `road` still needs Grandpa's post-catch conversation, and must not silently
## skip Mira and tournament registration.
func _restore_opening_beat() -> void:
	var restored := ""
	var game := get_node_or_null(^"/root/Game")
	var progression: RefCounted = game.get("progression") if game != null else null
	if progression != null:
		for candidate: String in BEATS.order():
			if bool(progression.call("has", OPENING_BEAT_PREFIX + candidate)):
				restored = candidate
	var party: RefCounted = game.get("party") if game != null else null
	var party_size := int(party.call("size")) if party != null else 0
	var starter_recorded := progression != null and bool(progression.call("has", STARTER_GRANTED_FLAG))
	# `name` was transient before this opening gained its required return to
	# Grandpa. A save made in that small post-adoption window already owns the
	# starter, so resume at the first meaningful next action instead of showing
	# the obsolete "still deciding" line forever.
	if restored == BEATS.NAMED and party_size > 0:
		restored = BEATS.RETURN_STARTER
	if restored == "" and party_size > 1:
		restored = BEATS.FREE_PLAY
	elif restored == "" and (party_size > 0 or starter_recorded):
		restored = BEATS.WALK_OUT
	if party_size > 0:
		_persist_opening_fact(STARTER_GRANTED_FLAG)
	if restored == "":
		restored = BEATS.first()
	_force_restore_beat(restored)


## Called through Game's progression_restore seam after a mid-session Load.
## Unlike ordinary transitions, loading an earlier slot is allowed to move the
## machine backwards because the slot—not the pre-load scene—is authoritative.
func restore_progression_from_game(_game: Node) -> void:
	_restore_opening_beat()
	_picker_pending = _beat == BEATS.CHOOSE
	_choice = -1
	_adopting = false
	if _beat == BEATS.WAKE:
		_set_player_lying(true)
	else:
		_set_player_lying(false)
		_clear_fade()
	_refresh_prompts()
	_refresh_door_gate()


func _force_restore_beat(target: String) -> void:
	if not BEATS.has(target):
		target = BEATS.first()
	var changed := target != _beat
	_beat = target
	_picker_pending = _beat == BEATS.CHOOSE
	_persist_beat_history(_beat)
	if changed:
		beat_changed.emit(_beat)


## Every beat at or before `beat`, not just `beat` itself.
##
## OP-0830-4. The beat flags were only ever written one at a time, as the
## machine stepped through them, which is correct for the machine's own resume
## (`_restore_opening_beat` takes the LAST one set). It is wrong for anything
## that reads them as history — and `data/progression/objectives.json` now
## does, because the opening's rungs are those flags. Two ways a save reaches a
## beat without having written the ones before it: the compatibility inference
## in `_restore_opening_beat` (a party of one with no beat flags at all resumes
## straight at `walk_out`), and a mid-session Load. Either left the guided
## objective ladder pointing at "Go down and hear Grandpa out" for a player
## already outside with a named creature.
##
## The beats are a strictly ordered list nobody may skip, so "reached beat N"
## genuinely does mean "passed 1..N-1"; this writes what was already true.
func _persist_beat_history(beat: String) -> void:
	var reached := BEATS.index_of(beat)
	if reached < 0:
		return
	var order := BEATS.order()
	for i in reached + 1:
		_persist_opening_fact(OPENING_BEAT_PREFIX + order[i])


func _persist_opening_fact(flag_id: String) -> void:
	var game := get_node_or_null(^"/root/Game")
	var progression: RefCounted = game.get("progression") if game != null else null
	if progression != null:
		progression.call("set_flag", flag_id)


func _clear_fade() -> void:
	if _fade_layer != null and is_instance_valid(_fade_layer):
		_fade_layer.queue_free()
	_fade_layer = null
	_fade_rect = null
	_fade_hold = 0.0
	_fade_left = 0.0


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
	_advance_from_external_progression()
	_refresh_lockout()
	_refresh_prompts()
	_refresh_door_gate()
	_check_left_the_bed()
	_maybe_open_picker()
	_maybe_open_shop()
	_maybe_start_battle()
	_hold_the_tutorial_orb_floor()
	_hold_the_tutorial_team_floor()


## Mira and the registrar already own their interactions, rewards and one-time
## facts. The opening observes only the fact written by those existing systems,
## then advances its own persisted beat. This is intentionally a poll: a flag
## can be restored from a save while this node is asleep, and a signal-only
## connection would miss exactly that case.
func _advance_from_external_progression() -> void:
	var required_flag := BEATS.advance_flag_for(_beat)
	if required_flag == "":
		return
	var game := get_node_or_null(^"/root/Game")
	if game == null:
		return
	var progression: RefCounted = game.get("progression")
	if progression == null or not bool(progression.call("has", required_flag)):
		return
	var next := BEATS.next(_beat)
	if next == "":
		push_error("opening beat '%s' waits for '%s' but has no following beat" % [_beat, required_flag])
		return
	_set_beat(next)


## Effects are drained in production, here, every frame.
##
## `dialogue_panel.drain_effects()` has existed since the panel was written and
## its only caller was a unit test, which is how a conversation carrying
## `beat:starter_choice` could play end to end and unlock nothing. Drained per
## frame rather than on `finished`, so an effect takes hold when its line is
## SPOKEN — the intro's last line offers the choice while it is still on screen,
## and the prompts are live the instant the box closes.
##
## Conversation-blind on purpose, and OF30 is what proved that matters: the
## panel this drains is the ONE dialogue panel, found by `village_npcs.gd`
## through the `dialogue_panel` group. Tam the blacksmith hands his tools over
## through the same `give:` effects Grandpa's briefing uses, and not a line of
## routing had to be written for it — a villager's conversation arrives in this
## queue exactly like the opening's own.
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
			"flag":
				_set_progression_flag(str(parts[1]))
			"shop":
				_queue_shop(str(parts[1]))
			"battle":
				_queue_battle(str(parts[1]))
			_:
				push_warning("the opening ignored dialogue effect '%s'; it knows 'beat:', 'give:', 'flag:', 'shop:' and 'battle:' and nothing else" % effect)


## `shop:goods:mira` / `shop:creatures:oskar` — D39 (OF31). A villager opens a
## trading screen at the end of their line.
##
## Two kinds, because there are two genuinely different transactions and the
## owner settled them differently: `goods` is Mira's coin store (buy and sell,
## `shop_panel.gd`), `creatures` is Oskar's straight swap (`swap_panel.gd`, no
## coins at all). The second half of the effect names WHO, and is a key in
## data/config/trade.json's `vendors`/`creature_traders` — so a second merchant
## is a data entry plus a dialogue line, not a change here.
##
## Queued rather than opened, for exactly the reason `_maybe_open_picker` is:
## effects are drained while the line that carries them is still ON SCREEN, so
## opening here would put a shop behind an open dialogue box. `_maybe_open_shop`
## waits for the box to close, the same way the starter picker does.
func _queue_shop(payload: String) -> void:
	var pieces := payload.split(":")
	if pieces.size() != 2 or str(pieces[0]).is_empty() or str(pieces[1]).is_empty():
		push_warning("a shop: effect reads shop:<goods|creatures>:<vendor_id>; got 'shop:%s'" % payload)
		return
	if str(pieces[0]) != SHOP_GOODS and str(pieces[0]) != SHOP_CREATURES:
		push_warning("dialogue asked for a '%s' shop; only '%s' and '%s' exist" % [
			str(pieces[0]), SHOP_GOODS, SHOP_CREATURES
		])
		return
	_shop_pending = [str(pieces[0]), str(pieces[1])]


## The other half of `_queue_shop`, polled every frame beside the picker's own.
##
## The panels are made on first use and kept, under the SceneTree root rather
## than under this node — the same lazy-instance shape `camp.gd` uses for the
## craft panel and `storage_container.gd` for the storage panel, and for the
## same reason: they pause the tree themselves and must not be children of
## anything that gets freed while they are open.
func _maybe_open_shop() -> void:
	if _shop_pending.is_empty():
		return
	if bool(_dialogue.call("is_open")):
		return
	var kind: String = str(_shop_pending[0])
	var vendor: String = str(_shop_pending[1])
	_shop_pending = []
	if kind == SHOP_GOODS:
		if _shop_panel == null or not is_instance_valid(_shop_panel):
			_shop_panel = SHOP_PANEL.new()
			_shop_panel.name = "ShopPanel"
			get_tree().root.add_child(_shop_panel)
		_shop_panel.call("open", vendor)
	else:
		if _swap_panel == null or not is_instance_valid(_swap_panel):
			_swap_panel = SWAP_PANEL.new()
			_swap_panel.name = "SwapPanel"
			get_tree().root.add_child(_swap_panel)
		_swap_panel.call("open", vendor)


## `battle:trainer_mira` — SC12/SC13. A villager's challenge line ends the
## conversation with a fight, the same way `trainer_npc.gd::_on_challenged` /
## `_on_conversation_finished` starts one for a standalone trainer body — this
## is the village-greeting half of that same contract, because Mira, Oskar and
## Tam are challenged through `village_npcs.gd`'s ordinary greeting flow
## (`greeting_when`), never through `trainer_npc.gd`'s own placement and prompt
## (spec §3 Band 1: "possible existing village NPCs can fill these roles" — no
## fourth body). `trainers.json`'s entries for the three of them carry
## `placed_by: "village_npcs"` precisely so `trainer_npc.gd::build()` never
## stands up a duplicate.
##
## Queued rather than started here, for the exact reason `_queue_shop` is:
## effects drain while the line that carries them is still ON SCREEN, and a
## battle dropped on top of an open dialogue box is the bug this avoids.
func _queue_battle(trainer_id: String) -> void:
	if trainer_id == "":
		push_warning("a battle: effect reads battle:<trainer_id>; got an empty id")
		return
	_battle_pending = trainer_id


## The other half of `_queue_battle`, polled every frame beside the shop and
## the picker's own. Waits for the dialogue box to close, then hands the
## fight to `encounter_director.gd` exactly the way `trainer_npc.gd` does:
## `can_challenge()` decides, `begin_trainer_battle()` starts it, and a
## refusal (the ally already fainted to something else, say) is quiet rather
## than an error — the player can walk back and ask again.
##
## The second argument `trainer_npc.gd` passes is the trainer's own placed
## body, used only to decide which direction their creature steps out from
## (`encounter_director._send_out_spot()`). A villager has no such body
## registered here — `village_npcs.gd` places them and keeps no lookup this
## file has any business reaching into — so `null` is passed, the same
## "smallest honest thing" `_send_out_spot()` already falls back to for a
## battle with no trainer body at all: the creature steps out in front of the
## player instead, exactly where a wild encounter would have put it.
func _maybe_start_battle() -> void:
	if _battle_pending.is_empty():
		return
	if bool(_dialogue.call("is_open")):
		return
	var trainer_id := _battle_pending
	_battle_pending = ""
	if _encounter == null:
		push_error("no EncounterDirector; '%s' offered a battle nobody can run" % trainer_id)
		return
	var spec := TRAINERS.trainer(trainer_id)
	if spec.is_empty():
		push_error("battle: named '%s', which trainers.json does not define" % trainer_id)
		return
	if not bool(_encounter.call("begin_trainer_battle", spec, null)):
		print("[village] '%s' offered a battle that could not start" % trainer_id)


## `flag:tam_tools_given` — OF30. Write one progression flag, on the line that
## earns it.
##
## The store is `autoload/progression_state.gd`, the same flat flag store the
## road gate (`item_gate.gd`) and the TM pickups already write to; there is no
## second one and there must never be. What reads these: `village_npcs.gd`'s
## `greeting_for()` (which conversation a villager opens next, and therefore
## whether a one-time gift can be taken twice) and `game_state.recipe_known()`
## (`recipes.json`'s `unlocked_by`).
##
## Deliberately NOT a beat. Beats are the opening's own spine, ordered and
## refusing to run backwards; these are flat, unordered facts about the save.
## A villager's handover is the second kind and folding it into the first would
## put the village in the opening's state machine.
func _set_progression_flag(flag_id: String) -> void:
	if flag_id == "":
		push_warning("a flag: effect reads flag:<flag_id>; got an empty id")
		return
	var game := get_node_or_null(^"/root/Game")
	if game == null:
		push_error("no Game autoload; the flag '%s' was written nowhere" % flag_id)
		return
	var progression: RefCounted = game.get("progression")
	if progression == null:
		push_error("the Game autoload has no progression store; '%s' was written nowhere" % flag_id)
		return
	progression.call("set_flag", flag_id)


## `give:orb_basic:50` — Grandpa's parting gifts, granted on the line that
## mentions them so the words and the satchel agree. Into the REAL inventory
## through the same autoload everything else uses; a full satchel is warned
## about rather than silently swallowed, because a player who was promised
## fifty orbs and got twelve has no way to know.
##
## `parse_effect` splits on the FIRST colon only, so parts[1] here is
## "orb_basic:50" and the id/count split is this function's own job.
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
## swings your creature and opens a conversation with Grandpa if the fight happened to
## start near him.
##
## The build case is the identical argument one context along, and it is the
## other half of the owner's "building doesn't work" report: `interact` and
## `build_place` are ALSO the same physical button (X). With the arbiter live
## while a ghost is armed, the press that plants a wall also opens whatever
## conversation or harvest prompt happened to be in reach — so building next to
## anything interactive fought the player for the button. An armed ghost owns
## the screen the same way a fight does.
func _refresh_lockout() -> void:
	var fighting: bool = _manager != null and bool(_manager.call("is_fighting"))
	# R8.1: a trainer battle is longer than any one fight inside it — their
	# next creature is still coming during the beat after the last one fell,
	# and the fight is not running for that beat. Without this, the arbiter
	# and the trainer's own legs come back in the gap, and the player can walk
	# out of a challenge they are in the middle of. `has_method` because a
	# bare scene may carry an older director.
	if not fighting and _encounter != null and _encounter.has_method("trainer_battle_active"):
		fighting = bool(_encounter.call("trainer_battle_active"))
	var panel: bool = bool(_dialogue.call("is_open")) or bool(_name_prompt.call("is_open")) \
			or bool(_starter_picker.call("is_open"))
	var modal := panel or is_fading() or _adopting
	# An armed build ghost is a fourth owner of the screen — see the header.
	var game := get_node_or_null(^"/root/Game")
	var building: bool = game != null and str(game.get("pending_build")) != ""

	_arbiter.call("set_enabled", not modal and not fighting and not building)

	# Locomotion and the camera belong to combat while a fight is running.
	# Handing them back here every frame would undo what the encounter director
	# and the combat manager just did to them.
	if fighting:
		# OP23-02 (owner playtest 2026-08-23): "battle start takes the camera,
		# can't see." `trainer_npc.gd::_on_conversation_finished` opens a fight
		# SYNCHRONOUSLY the instant the challenge dialogue's `finished` signal
		# fires -- `panel` and `fighting` can both change on the exact same
		# frame, unlike Mira's village path (`_maybe_start_battle()`'s own
		# per-frame poll, which only opens a fight once `panel` has already
		# read false for a frame). When that lands, this function would have
		# hit the early `return` below without ever undoing the LAST frame's
		# `set_process(false)` from the still-open dialogue -- the rig's idle
		# tick (stick look AND follow both live there) stays off for the
		# fight's entire duration, a frozen camera rather than a misframed one.
		# A fight always wants the rig processing; there is no modal case for
		# combat the way there is for a dialogue box.
		if _camera_rig != null and is_instance_valid(_camera_rig):
			_camera_rig.set_process(true)
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
		_grandpa_prompt.call("set_enabled", _grandpa_conversation_id() != "")
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
## Restricted to the beats whose own conversation is a REQUIRED one, not
## every beat the gate covers. `choose` and `name` are also before
## `walk_out` (the door stays physically shut through both, correctly), but
## their own conversation is incidental ("Still deciding?"), not required —
## and the player is standing right where the briefing left them, close
## enough to the door to be back inside the callout radius the instant a
## panel closes. Triggering on those two reopens a new conversation the
## moment the last one's box clears, which starves `_maybe_open_picker()` of
## the closed-dialogue frame it needs and the starter picker never opens.
##
## OP-0830-4, 2026-08-30 owner playtest: "after the first conversation with
## grandpa you're trapped in his house with nothing telling you to talk to
## him again before you can go." `return_starter` is the SECOND required
## conversation — `grandpa_first_catch`, whose last line carries
## `beat:first_encounter` and is therefore the only thing in the game that
## opens this door. It was not in this list, so from that beat onward the
## doorway was a silent invisible wall: the player pushed on it and nothing
## at all happened, no callout, no line, no prompt (Grandpa's own 4m radius
## does not reach the door). It behaves like `house` now, which is what spec
## §1D describes and never restricted to the first conversation: walk at the
## door, be called back, end up in the conversation naturally. No picker is
## pending on this beat, so the starvation reasoning above does not apply.
const DOOR_CALLOUT_BEATS := [BEATS.HOUSE, BEATS.RETURN_STARTER]

func _refresh_door_gate() -> void:
	if _house == null or not is_instance_valid(_house):
		return
	var door_open := BEATS.at_or_after(_beat, BEATS.WALK_OUT)
	_house.call("set_door_open", door_open)
	# OWNER-0901: the player's own bed offers "Sleep" (grandpa_house.gd's
	# `_build_sleep_prompt`) on the same gate as the front door — free to
	# leave the house is free to nap in it, and before that the player is
	# still mid-conversation with Grandpa, where a sleep prompt would fire
	# `night_rest.gd::rest()` out from under an unfinished opening beat.
	_house.call("set_sleep_enabled", door_open)
	if door_open or not DOOR_CALLOUT_BEATS.has(_beat):
		return
	if bool(_dialogue.call("is_open")) or _adopting or _picker_pending:
		return
	if bool(_name_prompt.call("is_open")) or bool(_starter_picker.call("is_open")):
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
## encounter_director: `creature_body` and `npc_body` both find the ground by walking
## up the tree looking for `ground_height_at`, and the world root is what offers
## it. A creature hung under a plain Node is also outside the 3D transform chain.
func _spawn_the_cast() -> void:
	var house := await _wait_for_the_house()
	_house = house
	var cfg := BEATS.grandpa()

	if house != null:
		# Into bed, lying down (OF8) rather than standing on top of it. The
		# world's own _place_player already ran (the house is only built after
		# it), so nothing later overwrites this.
		#
		# X centred on the mattress rather than the old +0.6m offset (which
		# put a standing capsule near the mattress edge and relied on being
		# shoved elsewhere by grandpa_house.gd's now-fixed collider); Z
		# shifted BED_LIE_REACH toward the foot of the bed, so set_lying()'s
		# rotation swings the head back to roughly where the marker — and
		# BedPrompt — already are. Y just above the marker's own height: the
		# mattress collider grandpa_house.gd builds now tops out AT that
		# height, so gravity and floor-snap settle the capsule there in the
		# next physics tick rather than fighting a taller box.
		var bed: Vector3 = house.call("marker", "bed")
		_bed_anchor = bed
		_build_bed_prompt(house)
		# A loaded game has already earned its exact saved position. The cast
		# still spawns, but only a genuine wake beat stages the trainer in bed.
		if _beat == BEATS.WAKE:
			_player.global_position = Vector3(bed.x, bed.y + 0.05, bed.z + BED_LIE_REACH)
			_player.velocity = Vector3.ZERO
			_set_player_lying(true)
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
	_set_player_lying(false)
	_set_beat(BEATS.HOUSE)


## OF8. `trainer_model.gd::_process()` also clears this on its own the
## instant the trainer starts moving — belt and suspenders with the explicit
## calls here, not a replacement for them: that self-clear covers the walk-
## off-the-mattress fallback frame by frame, while this is the definitive
## "the wake beat is over" moment either exit routes through.
func _set_player_lying(lying: bool) -> void:
	if _player == null:
		return
	var model := _player.get_node_or_null(^"Model")
	if model != null and model.has_method("set_lying"):
		model.call("set_lying", lying)


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
	_set_player_lying(false)
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
	_start_conversation(_grandpa_conversation_id())


## GATE-F-LEG-S10CDE, extended by F3. `free_play` (opening.json's own terminal
## beat, reached around tournament sign-up) has nothing scripted forever, by
## design — his opening briefing is one immediate purpose at a time, and the
## tournament/quest systems own the broader preparation path from there. But
## the chapter keeps happening around him after that: the tournament is won,
## the South Bridge and the relay open up, the Hall itself becomes reachable,
## and finally SG46's ending changes the world. None of that was ever named in
## `beats.grandpa_conversations`, which only knows the FIRST fifteen minutes.
##
## `grandpa_conversations_when()` (opening_beats.gd) is that missing ladder —
## the same ordered, flag-gated shape `village_npcs.json`'s `greeting_when`
## already gives every villager, with `conversation_for(_beat)` standing in
## for a villager's plain `greeting`. Read through `greeting_for()`, the exact
## function every villager's ladder already goes through, so this is the same
## lookup the audit's own suggested fix named rather than a second one beside
## it.
func _grandpa_conversation_id() -> String:
	var game := get_node_or_null(^"/root/Game")
	var progression: RefCounted = game.get("progression") as RefCounted if game != null else null
	var spec := {
		"greeting": BEATS.conversation_for(_beat),
		"greeting_when": BEATS.grandpa_conversations_when(),
	}
	return VILLAGE_NPCS.greeting_for(spec, progression)


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
	if _starter_already_granted():
		push_warning("refused to reopen starter selection after a starter was already granted")
		_restore_opening_beat()
		return
	if index < 0 or index >= _starter_species.size():
		return
	_choice = index
	# Naming is mandatory, not skippable (docs/OPENING_SEQUENCE.md): a creature you did
	# not name is a creature you did not adopt. The panel has no cancel, and the beat
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
		return
	_persist_opening_fact(STARTER_GRANTED_FLAG)

	# The first time this game says a word the player wrote.
	_dialogue.call("set_value", NAME_KEY, chosen)
	# The player now has one named companion. Do not automatically pile the next
	# instruction over the naming panel: the first-catch supplies come from the
	# required return to Grandpa, which is both the next objective and the point
	# at which the existing inventory system grants the 15 Basic Orbs.
	_set_beat(BEATS.RETURN_STARTER)


func _starter_already_granted() -> bool:
	var game := get_node_or_null(^"/root/Game")
	if game == null:
		return false
	var progression: RefCounted = game.get("progression")
	if progression != null and bool(progression.call("has", STARTER_GRANTED_FLAG)):
		return true
	var party: RefCounted = game.get("party")
	return party != null and int(party.call("size")) > 0


## --- beats 6, 7 and 8: the encounter, the fight and the catch ----------------------------
##
## None of this is reimplemented here. The wild bramblebun, the engage prompt,
## the fight and the throw are `encounter_director.gd` and `combat_manager.gd`
## and they already work; this reads the result and moves the beat.
##
## Nothing gates the encounter either, and nothing needs to: the encounter
## director offers no engagement while the player has no creature, so beats 1 to 5 are
## already unreachable from a fight.

func _on_combat_entered() -> void:
	if _beat == BEATS.WALK_OUT:
		_set_beat(BEATS.ENCOUNTER)
	# OPENING_SEQUENCE.md promises that the authored practice catch cannot fail
	# twice. Species rate alone is probability, not a bound, so opt this exact
	# encounter into CombatManager's narrow landed-throw assist. Checking both
	# beat and configured species prevents another Bramblebun fought later from
	# inheriting tutorial odds. Every other fight actively disables the policy.
	_manager.call(
		"configure_tutorial_catch_assist",
		_is_tutorial_catch(),
		int(BEATS.encounter().get("max_catch_failures", 1))
	)


## The other half of the tutorial's "cannot fail" promise.
##
## `configure_tutorial_catch_assist` bounds LANDED throws, and deliberately so —
## a throw that never reached the creature is not a failed catch. That leaves
## the miss unbounded, and the miss is the one that dead-ends the opening: the
## only orbs before the road gate are Grandpa's fifteen, both resupplies (Tam's
## recipe, the village trader) are past the gate, and the gate is past this
## catch. Run dry and `throw_aim.gd::try_begin_aim()` refuses every further
## press with "no orbs left" while the beat waits for a catch that can no longer
## be attempted. There is no way out of that but a new game.
##
## So while THIS encounter is live, running out tops the satchel back up.
## Deliberately hung off the refusal rather than polled: it fires exactly once
## per dead-end, at the moment the player presses throw and nothing happens,
## which is both the only moment it matters and the only moment they would
## notice. The `_is_tutorial_catch()` predicate is the same beat-and-species one
## the bound uses, so this cannot leak into any later Bramblebun.
func _on_catch_refused(reason: String) -> void:
	if reason != "no orbs left":
		return
	_hold_the_tutorial_orb_floor()


## Keep the practice catch's satchel off empty.
##
## Polled rather than hung off the refusal alone. Reacting to the refusal is one
## beat too late by construction: the refusal only fires when the player PRESSES
## throw with nothing to throw, so the restock lands AFTER a press that visibly
## did nothing. A dead button is the exact failure the opening is supposed not to
## have, and `playground_hud.gd::_swing_equipped_tool()`'s own header makes the
## same argument about the combat buttons -- a press that silently does nothing
## reads as broken. Topping up the moment the count reaches zero means the beat
## simply never runs dry.
##
## The refusal handler stays as the backstop for any drain that lands between
## frames. Both go through here, so there is one rule and one place to change it.
func _hold_the_tutorial_orb_floor() -> void:
	if not _is_tutorial_catch():
		return
	var amount := int(BEATS.encounter().get("catch_orb_floor", 0))
	if amount <= 0:
		return
	var game := get_node_or_null(^"/root/Game")
	if game == null:
		return
	var inventory: RefCounted = game.get("inventory")
	if inventory == null:
		return
	# Every tier counts toward the floor, for `throw_aim.gd::stock()`'s reason:
	# a player carrying only greater orbs is not out of orbs, and handing them
	# basic ones on top would be a restock they did not need.
	var held := 0
	for id: String in CATCH.orb_ids():
		held += int(inventory.call("count", id))
	if held >= amount:
		return
	inventory.call("add", TUTORIAL_ORB, amount - held)


## The third part of the same promise, and the one nothing was keeping.
##
## `configure_tutorial_catch_assist` bounds the LANDED throw and
## `_hold_the_tutorial_orb_floor` bounds the orb supply. Neither bounds the
## FIGHT. `data/config/catching.json` is explicit that your creature is
## undefended while you aim and that the opponent does not stop attacking it --
## "that cost is the whole design" -- and that is right, but nothing anywhere
## bounded the cost. A run of missed throws ends with the starter fainted, and
## a fainted starter at this beat is terminal: `creature_instance.heal()`
## refuses a fainted creature outright (D40), the creature bed that would rest
## it is a buildable needing Tam's tools from past the road gate, and a night
## only heals creatures actually put to bed
## (`night_rest.gd` -> `game_state.complete_creature_bed_rests()`). From there
## `encounter_director.gd::_engageable()` offers no fight in the entire game
## while this beat waits for a catch that can no longer be attempted -- the
## exact dead-end the orb floor exists to prevent, reached through the other
## door. Measured on four fresh runs, two of which ended in it:
## `ralph/reports/gate-f-capstone-1/CAP-1-FINDING.md` (CAP-1).
##
## Polled rather than hung off the fight's own "lost" outcome, for two reasons
## the orb floor's header already gives in its own words. It fires one frame
## after the arena tears down rather than in the middle of `_begin_resolve`,
## which has already decided the outcome and must not have the creature stand
## back up underneath it; and a save made in the broken state (the capstone's
## S03 booted exactly one) recovers on load instead of staying stranded.
##
## Gated on the beat alone, not on beat AND species like the two assists above.
## Those two reach into a LIVE fight, where "which creature is on screen" is
## both knowable and the thing that must not leak. This runs between fights,
## where there is no enemy to name -- and the dead-end it answers does not care
## what fainted the starter. The bound that matters is the same one: the
## opening's encounter beat ends permanently at the first catch, so this cannot
## outlive the tutorial.
func _hold_the_tutorial_team_floor() -> void:
	if _beat != BEATS.WALK_OUT and _beat != BEATS.ENCOUNTER:
		return
	var fraction := float(BEATS.encounter().get("faint_recovery_fraction", 0.0))
	if fraction <= 0.0:
		return
	# Never mid-fight. CombatManager owns the creature for the length of one and
	# has already decided the outcome by the time the faint is visible.
	if _manager == null or bool(_manager.call("is_fighting")):
		return
	if _encounter != null and _encounter.has_method("trainer_battle_active") \
			and bool(_encounter.call("trainer_battle_active")):
		return
	var game := get_node_or_null(^"/root/Game")
	if game == null:
		return
	var party: RefCounted = game.get("party")
	# `all_fainted()` and nothing looser. A player who still has one creature
	# standing has not lost anything they cannot walk out of, and handing them a
	# free heal would be the opening quietly undoing a fight they are still in.
	if party == null or not bool(party.call("all_fainted")):
		return
	for member: Variant in party.call("members"):
		var creature := member as RefCounted
		if creature != null:
			# D40's dedicated un-fainter: it refuses anything still standing, so
			# the loop cannot top up a creature this floor is not about.
			creature.call("revive", fraction)
	game.call("push_world_message", "Your creature is back on its feet. Try again.")


## Is the fight on screen the authored practice catch? Beat AND species, for the
## reason `_on_combat_entered` gives: another Bramblebun fought later must not
## inherit the opening's assists.
func _is_tutorial_catch() -> bool:
	if _beat != BEATS.ENCOUNTER or _manager == null:
		return false
	var enemy: RefCounted = _manager.call("enemy") as RefCounted
	if enemy == null:
		return false
	return str(enemy.get("species_id")) == str(BEATS.encounter().get("species", ""))


func _on_combat_exited(outcome: String) -> void:
	if outcome != CAUGHT:
		# They won it instead of catching it, or ran. The encounter director puts
		# the bramblebun back on its feet after a few seconds, so the beat stays
		# where it is and they get another go — species.json gives that creature
		# the highest catch rate in the game precisely so the tutorial catch does
		# not have to succeed first time.
		#
		# CAP-1: "lost" is the fourth case, and it used to fall through this same
		# return into a beat waiting on a catch the player could no longer
		# attempt. Staying put is still the right move HERE -- what was missing
		# was anyone putting the starter back up, which
		# `_hold_the_tutorial_team_floor()` now does on the next frame, off the
		# party rather than off this outcome so a save reloaded into the broken
		# state recovers too.
		return

	# R4.10: the catch itself reaches `Game.party` through
	# `encounter_director.gd::_resolve_catch()` now — the one path EVERY catch
	# takes, this tutorial one included. This handler used to call
	# `_give_to_party` here because nothing else put a catch anywhere; once the
	# director's own wiring landed, that second add was refused as a duplicate
	# on every single catch and push_error'd about it. The story's only job at
	# this beat is to move the story. (A new capture still keeps its species
	# name by default — GAME_DESIGN.md 10 — because nothing anywhere nicknames
	# it.)
	_set_beat(BEATS.ROAD)


## --- the party -------------------------------------------------------------------

## Into the real party, which is `Game`'s.
##
## Not through `scripts/story/party_seam.gd`. That file was written while there
## was no autoload to hold a party, and it says so in its own TODO; there is one
## now, `autoload/party.gd` enforces the five-creature cap in `add()` and nowhere
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
		push_error("no Game autoload; the creature exists but nobody owns it")
		return false
	var party: RefCounted = game.get("party")
	if party == null:
		push_error("the Game autoload has no party")
		return false

	if bool(party.call("is_full")):
		# The opening cannot reach this — it adds two creatures to an empty party —
		# but the sixth-creature release ceremony is real design (GAME_DESIGN.md 3)
		# and a director that silently dropped a creature would hide the day it starts
		# mattering.
		push_warning("the party is full; %s was not added" % instance.get("display_name"))
		return false
	return bool(party.call("add", instance))
