extends Node3D

## R8.1. The people who challenge you, from data/config/trainers.json.
##
## Same shape as village_npcs.gd, and deliberately so: data describes, code
## places. Each entry becomes an `npc_body.gd` body — the same script Grandpa
## and the villagers already use — stood on the ground synchronously from
## `playground_world._build_settlement()`, well after the terrain's collision
## is confirmed solid.
##
## What a trainer does is exactly three things: stand somewhere, say something
## short, and hand the fight to `encounter_director.gd`. It owns no combat
## state at all. Spec §12 wants 12-17 of these across the chapter (three in
## Band 1, the relay station's, the regional captains', the stronghold's), and
## every one of them is an entry in the table, not a script.
##
## The static half of this file is the table's READER — teams, rewards, flow
## numbers, which conversation a beaten trainer opens. It is static and pure
## (no nodes, no tree, no `/root/Game`) for the same reason
## `village_npcs.greeting_for()` is: `tests/test_trainers_data.gd` can check
## the real table without standing anybody on Terrain3D, and the encounter
## director can read a team without depending on a placed body existing.
##
## SC12/SC13. `build()` below is the PLACER half, and it does not place every
## row of the table any more: an entry naming `placed_by` (Mira, Oskar and
## Tam all name `"village_npcs"`) is a trainer whose body already exists
## elsewhere — spec §3 Band 1 explicitly reuses the three existing village
## NPCs rather than adding a fourth. Their challenge is offered through
## `village_npcs.gd`'s own greeting flow instead of this file's prompt system,
## and their fight is started by `sequence_director.gd`'s `battle:` dialogue
## effect rather than by `_on_challenged`/`_on_conversation_finished` below —
## but it is still THIS table those three read from, and still
## `encounter_director.begin_trainer_battle()` that runs their fight, so
## nothing about a trainer's data or its battle logic forked in two.

const NPC := preload("res://scripts/npc/npc_body.gd")
const CHARACTER_MODEL := preload("res://scripts/characters/character_model.gd")
const NPC_RANKS := preload("res://scripts/characters/npc_ranks.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")

const CONFIG_PATH := "res://data/config/trainers.json"

## Dark-features T1: one generic id every trainer opens (data/dialogue/
## trainers.json) when the player has no usable creature to fight with right
## now -- not a per-trainer pair, so this reaches all ~27 trainers without
## touching every band's own trainers.json.
const NO_USABLE_CREATURE_CONVERSATION := "trainer_no_usable_creature"

## G3-OPENING-FIX-0904 (2.10). The other half of `no_usable_ally()`'s two
## real causes: nothing is out at all, as opposed to something out and
## fainted. `NO_USABLE_CREATURE_CONVERSATION`'s own line ("get it back on
## its feet... a bed will do it") is only true for the fainted case -- a
## healthy party with nothing deployed (a fresh load, a creature put away)
## needs "call one out", not a trip to a bed nothing asked for.
const NO_ALLY_DEPLOYED_CONVERSATION := "trainer_no_ally_deployed"

## CL-W4 / owner amendment A-4 ("gate just make the fight not start unless
## you're a certain level. the guy can just say 'you're too low level...'").
## The fifth reason `can_challenge()` can be false, and -- like the two above
## it -- ONE generic id every trainer opens rather than a per-trainer pair, so
## a `min_level` added to any row of the table already has a line to refuse
## with. `$level` in its text is filled in from the row's own requirement
## (`dialogue_runner.gd::set_value`), which is what carries the remedy the
## owner asked for ("then it would prompt you to go back and fight more to get
## a level up") without a quest-log entry per trainer.
const TOO_LOW_CONVERSATION := "trainer_too_low"

## BAND-SPLIT. The `trainers` array is cut per corridor band under
## `data/config/bands/<band>/trainers.json`; `flow` and `prompts` are global
## and stay in the head file. `band_content.gd` merges them back.
const BAND_CONTENT := preload("res://scripts/data/band_content.gd")

## How far from the trainer the challenge prompt is offered. A little wider
## than a villager's greeting (3.8m): a challenge is a thing you walk up to
## on purpose, and standing close enough to touch someone before the game
## admits they exist reads as the prompt being broken.
const PROMPT_RADIUS := 4.2

var _player: Node3D = null
var _placed: int = 0
## Which trainer opened the conversation that is currently on screen, and
## whether it was the CHALLENGE one. The panel is shared with Grandpa, the
## villagers and the road gate, so this node answers `finished` for one
## conversation only — its own, and only when that one was a challenge.
var _pending_spec: Dictionary = {}
var _pending_conversation: String = ""

## CL-W5(a). The last `Game.progression.revision` `_process()` relabelled for.
## -1 means "never yet", so the first frame with a progression store always
## does one pass and a world built from a LOADED save (trainers already beaten
## before a single body was placed) shows the right labels immediately.
var _progression_revision: int = -1

## `Game.progression`, looked up once. Null until the first frame that finds
## it, and never re-fetched: the autoload outlives every world.
var _progression_cache: RefCounted = null


## `group` selects which rows of the table this placer owns, matched against
## each row's `placed_by`. The default ("") is the world's own pass and places
## exactly the rows that name nobody, which is the behaviour every caller had
## before R8.2 — the three villager-trainers (`placed_by: "village_npcs"`) are
## still skipped here and still greeted through `village_npcs.gd`.
##
## R8.2/SG38 adds the second case: a BUILDING that owns where its own people
## stand. `scripts/world/stronghold.gd` asks for group `"stronghold"` and hands
## in world positions and facings keyed by trainer id, because a room's
## coordinates belong to the room and not to a table of teams and rewards.
## Everything else about those trainers — team, reward, dialogue, defeat flag,
## the fight itself — is the same table and the same encounter director as
## every other trainer in the chapter. `positions` maps id -> Vector2(x, z) and
## `facings` maps id -> degrees; a row not named in them uses its own authored
## `position`/`facing_deg` as usual.
func build(player: Node3D, group: String = "", positions: Dictionary = {},
		facings: Dictionary = {}) -> void:
	_player = player
	var entries := trainers()
	if entries.is_empty():
		push_warning("trainers.json lists nobody; there are no trainer battles in this world")
		return
	for spec: Variant in entries:
		if spec is Dictionary and str((spec as Dictionary).get("placed_by", "")) == group:
			_spawn(spec as Dictionary, positions, facings)
	_watch_the_dialogue_panel()
	print("[trainers] placed %d trainer(s)%s" % [
		_placed, "" if group == "" else " for group '%s'" % group])


func placed() -> int:
	return _placed


## The body standing for a given trainer id, or null. For a test or a tool
## that needs to walk up to somebody by name rather than by position.
func body_for(id: String) -> Node3D:
	for child in get_children():
		var node := child as Node3D
		if node != null and str(node.get_meta("trainer_id", "")) == id:
			return node
	return null


func _spawn(spec: Dictionary, positions: Dictionary = {}, facings: Dictionary = {}) -> void:
	var id := str(spec.get("id", ""))
	var display_name := str(spec.get("name", "Trainer"))
	if id == "":
		push_error("a trainers.json entry has no id; it was not placed")
		return

	var npc: Node3D = NPC.new()
	npc.name = display_name
	npc.set_meta("trainer_id", id)
	add_child(npc)
	if not bool(npc.call("setup_from_config", model_config(spec), _player)):
		push_error("trainer '%s' has no model; nothing will stand there" % id)

	var at: Array = spec.get("position", [])
	var x := float(at[0]) if at.size() > 0 else 0.0
	var z := float(at[1]) if at.size() > 1 else 0.0
	if positions.has(id):
		var override: Vector2 = positions[id]
		x = override.x
		z = override.y
	if not bool(npc.call("stand_at", x, z)):
		push_error("no ground under trainer '%s' at %.0f, %.0f" % [id, x, z])
		return
	npc.rotation.y = deg_to_rad(float(facings.get(id, spec.get("facing_deg", 0.0))))

	# The whole spec is bound rather than a resolved label: whether this person
	# is offering a battle or a nod depends on a progression flag, and that
	# changes while the player is standing in front of them. Resolving it once
	# at build time would freeze a beaten trainer on their challenge line.
	var prompt: Node3D = npc.call("add_prompt", _prompt_for(spec), PROMPT_RADIUS)
	prompt.connect("activated", _on_challenged.bind(spec))
	_placed += 1


## --- talking, then fighting ---------------------------------------------------

## Reaches the dialogue panel through the "dialogue_panel" group, the same way
## village_npcs.gd does and for the same reason: this node is built by
## playground_world.gd, which has no business knowing sequence_director.gd's
## wiring.
func _panel() -> Node:
	return get_tree().get_first_node_in_group("dialogue_panel")


func _watch_the_dialogue_panel() -> void:
	var panel := _panel()
	if panel == null or not panel.has_signal("finished"):
		return
	if not panel.is_connected("finished", _on_conversation_finished):
		panel.connect("finished", _on_conversation_finished)


func _on_challenged(spec: Dictionary) -> void:
	var panel := _panel()
	if panel == null:
		push_warning("no node in the 'dialogue_panel' group; a trainer has nothing to say")
		return
	if bool(panel.call("is_open")):
		return

	var director := _director()
	var challenging: bool = director != null and bool(director.call("can_challenge", spec))
	var conversation: String
	if challenging:
		conversation = str(spec.get("challenge", ""))
	elif already_beaten(spec, _progression()):
		# Hoisted above the two refusal branches below. It used to be the
		# `else` fall-through, which was correct while there were only two
		# reasons; with the level gate added it has to be checked FIRST, or a
		# beaten trainer carrying a `min_level` the player is under would taunt
		# somebody who already won -- the exact collapse the dark-features T1
		# note warns about, in the other direction.
		conversation = str(spec.get("defeated", ""))
	elif director != null and bool(director.call("too_low_to_challenge", spec)):
		# CL-W4 / A-4. The gate IS the trainer: the fight does not start and
		# they say why, in character, naming the level that would change it.
		conversation = TOO_LOW_CONVERSATION
		panel.call("set_value", "level", str(required_level(spec)))
	elif director != null and bool(director.call("no_usable_ally")):
		# Dark-features T1: `can_challenge()` is false for four distinct
		# reasons (already beaten, no usable ally, mid-battle, malformed
		# spec) and used to collapse all of them into the "defeated" line.
		# This is the one of those four that is actually a common, ordinary
		# player state (a fainted starter) rather than a real win -- so it
		# gets its own, honest, generic line instead of a false "defeated".
		#
		# G3-OPENING-FIX-0904 (2.10): that one line used to cover BOTH of
		# `no_usable_ally()`'s real causes and was only true for one of
		# them -- "get it back on its feet, a bed will do it" tells a
		# player whose creature is not out, but is not hurt either, to go
		# heal something that does not need healing.
		# `usable_ally_blocker()` names which cause actually applies.
		conversation = NO_USABLE_CREATURE_CONVERSATION
		if str(director.call("usable_ally_blocker")) == "undeployed":
			conversation = NO_ALLY_DEPLOYED_CONVERSATION
	else:
		conversation = str(spec.get("defeated", ""))
	if conversation == "":
		return
	if not bool(panel.call("start", conversation)):
		return

	# Remembered rather than acted on now: the challenge is the WORDS, and the
	# fight opens when they are done. Starting it here would drop an arena on
	# top of an open dialogue box.
	_pending_spec = spec if challenging else {}
	_pending_conversation = conversation if challenging else ""


## The challenge is over; the battle is the answer to it.
##
## Guarded on the exact conversation this node started, because the panel is
## shared: Grandpa's briefing, a villager's banter and the road gate's lock
## message all finish on this same signal.
func _on_conversation_finished(conversation_id: String) -> void:
	if _pending_spec.is_empty() or conversation_id != _pending_conversation:
		return
	var spec := _pending_spec
	_pending_spec = {}
	_pending_conversation = ""

	var director := _director()
	if director == null:
		push_error("no EncounterDirector; trainer '%s' has nobody to run their battle" % str(spec.get("id", "")))
		return
	if not bool(director.call("begin_trainer_battle", spec, body_for(str(spec.get("id", ""))))):
		# Refused between the challenge and the last line — the player's
		# creature fainted to something else, say. Not an error: they can walk
		# back and ask again.
		print("[trainers] '%s' offered a battle that could not start" % str(spec.get("id", "")))


func _director() -> Node:
	var world := get_parent()
	return world.get_node_or_null(^"EncounterDirector") if world != null else null


## `Game.progression`, SB9's flat flag store -- same null-tolerant `/root/Game`
## lookup `encounter_director.gd::_progression()` uses, needed here so
## `_on_challenged` can tell a genuinely-beaten trainer apart from one the
## player simply has no usable creature for right now.
func _progression() -> RefCounted:
	var game := get_node_or_null(^"/root/Game")
	return game.get("progression") if game != null else null


func _prompt_for(spec: Dictionary) -> String:
	return prompt_for(spec, _progression())


## CL-W5(a). Keep every placed trainer's prompt LABEL honest as the world
## changes underneath it.
##
## `_spawn()` resolves a label once, at build time, and `interactable.gd`
## stores that string -- so the beaten half of `prompt_for()` below would never
## have reached a player who beat somebody after the world was built, which is
## every player. Progression's own `revision` counter (bumped only when a flag
## actually changes state) is what makes this cheap: on the overwhelming
## majority of frames this is one integer compare and nothing else, and the
## relabel walk only runs on the frames a flag genuinely flipped.
func _process(_delta: float) -> void:
	# The `/root/Game` lookup is cached rather than repeated per frame: this
	# runs on every frame of the game, and `playground_hud.gd` caches the same
	# autoload for the same reason. `_placed == 0` skips the stronghold/village
	# placer instances that stood nobody up.
	if _placed == 0:
		return
	if _progression_cache == null:
		_progression_cache = _progression()
		if _progression_cache == null:
			return
	var revision := int(_progression_cache.get("revision"))
	if revision == _progression_revision:
		return
	_progression_revision = revision
	_refresh_prompts(_progression_cache)


## Re-label every body this node placed. Public so a test can force the pass
## without waiting on a frame.
func _refresh_prompts(progression: RefCounted) -> void:
	for child in get_children():
		var body := child as Node3D
		if body == null or not body.has_method("prompt_node"):
			continue
		var prompt: Node3D = body.call("prompt_node")
		if prompt == null:
			continue
		var spec := trainer(str(body.get_meta("trainer_id", "")))
		if spec.is_empty():
			continue
		prompt.set("label", prompt_for(spec, progression))


## --- the table ----------------------------------------------------------------

static var _config: Dictionary = {}


static func config() -> Dictionary:
	if not _config.is_empty():
		return _config
	_config = BAND_CONTENT.load_config(CONFIG_PATH, "trainers")
	return _config


static func trainers() -> Array:
	return config().get("trainers", []) as Array


static func trainer(id: String) -> Dictionary:
	for entry: Variant in trainers():
		if entry is Dictionary and str((entry as Dictionary).get("id", "")) == id:
			return entry as Dictionary
	return {}


static func flow() -> Dictionary:
	return config().get("flow", {}) as Dictionary


static func prompts() -> Dictionary:
	return config().get("prompts", {}) as Dictionary


static func team_of(spec: Dictionary) -> Array:
	var team: Variant = spec.get("team", [])
	return team as Array if team is Array else []


static func reward_items(spec: Dictionary) -> Array:
	var reward: Variant = spec.get("reward", {})
	if not reward is Dictionary:
		return []
	var items: Variant = (reward as Dictionary).get("items", [])
	return items as Array if items is Array else []


static func reward_flags(spec: Dictionary) -> Array[String]:
	var out: Array[String] = []
	var reward: Variant = spec.get("reward", {})
	if not reward is Dictionary:
		return out
	for entry: Variant in ((reward as Dictionary).get("flags", []) as Array):
		if typeof(entry) == TYPE_STRING and not (entry as String).is_empty():
			out.append(entry as String)
	return out


## SC15/D39: coins are an ordinary satchel item (`coin`, items.json), granted
## alongside whatever else the trainer names. 0 (not paying coins) is the
## honest default rather than an error -- most of the table will name none.
static func reward_coins(spec: Dictionary) -> int:
	var reward: Variant = spec.get("reward", {})
	if not reward is Dictionary:
		return 0
	return int((reward as Dictionary).get("coins", 0))


## SC15's optional flat top-up, on top of the XP the fight itself already
## paid per creature felled. 0 by default -- most trainers need nothing here,
## the ordinary victory award already does the work.
static func reward_xp_bonus(spec: Dictionary) -> int:
	var reward: Variant = spec.get("reward", {})
	if not reward is Dictionary:
		return 0
	return int((reward as Dictionary).get("xp_bonus", 0))


## Has this trainer already been beaten, and does that stop them being fought?
##
## A null `progression` (no Game autoload — a bare test scene, a capture tool)
## reads as "not beaten", which is the cautious direction here: the worst it
## can do is offer a battle in a scene that has no save to record it against.
static func already_beaten(spec: Dictionary, progression: RefCounted) -> bool:
	if bool(spec.get("rechallenge", false)):
		return false
	var flag := str(spec.get("defeat_flag", ""))
	if flag == "" or progression == null:
		return false
	return bool(progression.call("has", flag))


## The conversation this trainer opens right now. Static and pure so
## `tests/test_dialogue_runner.gd`-style checks and the smoke test can ask it
## without a body in the world — the same split `village_npcs.greeting_for()`
## keeps.
static func conversation_for(spec: Dictionary, progression: RefCounted) -> String:
	return str(spec.get("defeated" if already_beaten(spec, progression) else "challenge", ""))


## CL-W5(a), owner amendment A-2: "you can still hit challenge someone else
## after you beat them. maybe it doesn't let you fight again but you shouldn't
## even see the challenge button anymore. just talk to or whatever."
##
## `interactable.gd`'s own rule, quoted in that amendment: "a visible prompt
## the button refuses is worse than no prompt." The button is not removed --
## a beaten trainer is still a person you can walk up to and get a word out of
## -- but it stops advertising a fight that will not happen.
##
## NEVER "Talk to" or "Choose": `tests/smoke_opening.gd` finds Grandpa and the
## three starters by exactly those substrings, so a beaten trainer worded that
## way would be picked up as a starter and the opening smoke would start
## failing for a reason nothing about the opening changed. Both defaults here,
## and both `prompts()` entries in `data/config/trainers.json`, are chosen
## clear of those two words.
static func prompt_for(spec: Dictionary, progression: RefCounted) -> String:
	var beaten := already_beaten(spec, progression)
	var fallback := "Greet %s" if beaten else "Challenge %s"
	var template := str(prompts().get("defeated" if beaten else "challenge", fallback))
	if not template.contains("%s"):
		# A mis-authored template would otherwise throw at format time and take
		# the whole placement pass with it.
		push_error("trainers.json prompts.%s has no %%s for the trainer's name" % [
			"defeated" if beaten else "challenge"])
		template = fallback
	return template % str(spec.get("name", "Trainer"))


## CL-W4. The level this trainer refuses to fight below, or 0 for the ordinary
## case: no level condition at all.
##
## Two spellings are read because the closure plan and the brief name different
## ones (`min_level`, `challenge_level`) and a row authored with either should
## work rather than silently gate nothing. `min_level` is the canonical one and
## the one `data/config/trainers.json` documents.
##
## NOTHING SHIPPED CARRIES ONE YET, deliberately: `docs/FINISH_THE_MEADOWS.md`
## ("the dependency to state plainly") wants wild density landed before a level
## gate exists on the route, or the gate becomes the wall D-0904B-4 explicitly
## says it must not be. This is the mechanism, ready for the row that turns it on.
static func required_level(spec: Dictionary) -> int:
	if spec.has("min_level"):
		return maxi(0, int(spec.get("min_level", 0)))
	return maxi(0, int(spec.get("challenge_level", 0)))


## The number `required_level()` is measured against: the HIGHEST level in the
## party, not the active creature's and not an average.
##
## D79 records why. The player owns five creatures total and switches mid-fight
## (`combat_manager.gd::switchable_indices`), so the team that would actually
## answer a challenge is the whole party; gating on whoever happens to be
## deployed would refuse a player whose strongest creature is one button press
## away, and gating on an average would punish carrying a freshly-caught
## low-level creature -- the exact thing the chapter wants the player doing.
##
## A null party (a bare test scene, the unit runner with no autoloads) reads as
## 0. That is the cautious direction only once paired with `below_challenge_level()`
## below, which refuses to gate at all when there is no party to measure.
static func party_high_level(party: RefCounted) -> int:
	if party == null:
		return 0
	var highest := 0
	for member: Variant in (party.call("members") as Array):
		var creature := member as RefCounted
		if creature != null:
			highest = maxi(highest, int(creature.get("level")))
	return highest


## Is this trainer's level condition currently refusing the player?
##
## False whenever the row names no level (every shipped row today) and false
## whenever there is no party object to measure at all -- a scene with no
## `Game` autoload must not invent a gate, for the same reason
## `already_beaten()` reads a null progression as "not beaten".
static func below_challenge_level(spec: Dictionary, party: RefCounted) -> bool:
	var need := required_level(spec)
	if need <= 0 or party == null:
		return false
	return party_high_level(party) < need


## One of the trainer's creatures, built from its table entry.
##
## A real `creature_instance`, levelled through D30's own arithmetic — the
## same `set_level()` a starter goes through — so a trainer's creature is
## stronger for the same reasons the player's is, and nothing here invents a
## second stat curve. `moves` is an optional pair overriding the species' own,
## for a trainer whose battle is about a specific move.
static func creature_for(entry: Dictionary) -> RefCounted:
	var species := str(entry.get("species", ""))
	var creature: RefCounted = SPECIES.spawn(species)
	if creature == null:
		return null
	creature.set_level(maxi(1, int(entry.get("level", 1))), PROGRESSION.config())
	var moves: Variant = entry.get("moves", {})
	if moves is Dictionary:
		var quick := str((moves as Dictionary).get("quick", ""))
		var charged := str((moves as Dictionary).get("charged", ""))
		if quick != "":
			creature.move_quick = quick
		if charged != "":
			creature.move_charged = charged
	# G-2: the entry's optional per-creature behaviour override, read beside
	# `moves` because it is the same kind of thing -- this individual fights
	# differently, and nothing about the species changes.
	var combat: Variant = entry.get("combat", {})
	if combat is Dictionary and not (combat as Dictionary).is_empty():
		creature.combat_override = (combat as Dictionary).duplicate(true)
	return creature


## The character config a trainer's body is built from: an art.json block
## (`config_key`) or a Team Tether rank (`rank`, data/config/npc_ranks.json),
## with the entry's own per-part variants laid over it.
##
## Per-part, never a global tint: CLAUDE.md and spec §21 both say human NPCs
## are differentiated by hair, palette entries and accessories on a rig that
## already exists, and no trainer in this table is a reason to generate a new
## human.
static func model_config(spec: Dictionary) -> Dictionary:
	var rank := str(spec.get("rank", ""))
	var cfg := NPC_RANKS.config_for(rank, str(spec.get("base", ""))) if rank != "" \
		else CHARACTER_MODEL.config_for(str(spec.get("config_key", "")))
	if cfg.is_empty():
		return cfg
	cfg = cfg.duplicate(true)
	for key: String in ["hair", "accessories", "tint", "height"]:
		if spec.has(key):
			cfg[key] = spec[key]
	# `palette` LAYERS; everything above still replaces. A site entry that names
	# one surface must not silently discard the rank's own colours for every
	# other surface -- which is exactly what a whole-dictionary assignment did,
	# and it is how `captain_field`/`captain_ridge`/`captain_riverwatch` each
	# spent a whole chapter rendering in their old olive/tan/slate: NP2-grunt-wire
	# moved the captain RANK to the faction's oxblood, and these three overrode
	# `palette` wholesale, so the faction colour reached the generic
	# `relay_captain` and never reached a single captain the player actually
	# fights. Merging per key means a site accent adds to the rank rather than
	# erasing it, and a site that deliberately wants the whole body (a `"*"` key,
	# which is what today's single-fused-material rigs can address) still wins
	# that key outright -- the mechanism is the same one `npc_ranks.gd` uses to
	# lay a rank over its base.
	if spec.has("palette"):
		var merged: Dictionary = (cfg.get("palette", {}) as Dictionary).duplicate(true)
		for surface: Variant in (spec["palette"] as Dictionary):
			merged[surface] = (spec["palette"] as Dictionary)[surface]
		cfg["palette"] = merged
	return cfg
