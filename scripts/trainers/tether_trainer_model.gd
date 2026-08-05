extends "res://scripts/player/trainer_model.gd"

## An opposing trainer's body.
##
## `scripts/player/trainer_model.gd` already knows how to load a Styloo
## character, collapse the props modelled into its mesh, fit it to a height in
## metres, and retarget twenty-five KayKit clips onto a 176-to-191-bone Rigify
## skeleton that shares no bone names with them. That is several hundred lines of
## hard-won correctness (see `docs/decisions/D11`), and a second trainer that
## reimplemented any of it would be a second thing to fix when the animation pack
## changes.
##
## So this SUBCLASSES it and overrides exactly one thing: where the config comes
## from. The base reads `data/config/art.json`'s `trainer` block, which describes
## the player's own trainer; this hands it that same block with the model, the
## height, the yaw and the idle clip swapped for whatever `data/trainers/<id>.json`
## says. Everything else — the libraries, the retarget map, the rest-pose
## alignment, the loop list — is inherited verbatim, which is the point: the
## Warden animates because the player's trainer animates, not because anything
## was set up twice.
##
## The two behavioural differences:
##
##   * NO PLAYER. The base drives its clips from a `CharacterBody3D`'s speed and
##     `is_on_floor()`; this one has no controller, so it idles, and plays a
##     one-shot when the fight tells it to.
##   * IT IS NOT A BODY. A plain `Node3D` with no collider, so nothing can walk
##     into it and — the part that matters — nothing can hit it. `GAME_DESIGN.md`
##     §14's trainer safety rule and CLAUDE.md's "human cannot fight" apply to
##     BOTH humans in a trainer battle, and the cheapest way to guarantee the
##     opposing one is never a target is for there to be nothing there to target.

const DATA := preload("res://scripts/trainers/tether_data.gd")
const DRESS := preload("res://scripts/trainers/tether_dress.gd")
const ART_CONFIG_PATH := "res://data/config/art.json"

## Roles, resolved through the inherited `clips` map so a change of animation
## pack is still one data edit.
const ROLE_IDLE := "idle"
const ROLE_SEND_OUT := "send_out"
const ROLE_CHALLENGE := "challenge"
const ROLE_BEATEN := "beaten"

var _override: Dictionary = {}
## Whether this trainer wears Team Tether's tabard. True for everyone on the
## road; the flag exists so the preview tool can stand the player's own trainer
## beside them without dressing him as the enemy.
var _wears_the_colours: bool = true
var _oneshot_left: float = 0.0


## Must be called BEFORE the node enters the tree: the base class builds
## everything in `_ready()` from whatever `_load_config()` returns.
func configure(definition: Dictionary) -> void:
	var base := _art_trainer_block()
	_override = base.duplicate(true)
	_override["model"] = str(definition.get("model", base.get("model", "")))
	_override["height"] = float(definition.get("height", 1.8))
	_override["model_yaw"] = float(definition.get("model_yaw", 0.0))

	# THE PROPS COME OFF EVERY BODY, and each pack welds different ones on.
	#
	# `art.json`'s `hide_bones` names `DEF-shield` and `DEF-bone.01`, the knight's
	# sword and shield. The mage and the dwarf do not have those bones — they have
	# their own: the mage carries a staff on `DEF-staffMaster` and a spellbook on
	# `DEF-bookMaster`, the dwarf an axe on `DEF-weaponMaster`. All of them hang
	# off `DEF-spine` and no clip in the KayKit library touches any of them, so
	# they float beside the character in bind pose forever — which is exactly what
	# the first render of the Warden showed: a staff and a book standing in the
	# air a metre to his right.
	#
	# They would have to go even if they sat correctly. CLAUDE.md's "human cannot
	# fight" is a hard rule and it is symmetric: `art.json` says arming the
	# player's trainer "promises the wrong game", and a Warden with a staff
	# promises a boss fight where the boss fights you.
	#
	# Named per model here rather than in `art.json`, which is another agent's
	# file and describes the player's trainer.
	_override["hide_bones"] = _props_on(str(_override["model"]), base.get("hide_bones", []))

	# Team Tether's trainers stand about. `Idle_B` is the longer, looser of the
	# two idles the library ships and is deliberately NOT the player's `Idle_A`:
	# two people standing in the same frame doing the identical loop in lockstep
	# is the thing that makes a scene read as a game rather than as a place.
	var clips: Dictionary = (_override.get("clips", {}) as Dictionary).duplicate()
	clips[ROLE_IDLE] = "Idle_B"
	clips[ROLE_SEND_OUT] = "Throw"
	clips[ROLE_CHALLENGE] = "Interact"
	clips[ROLE_BEATEN] = "Hit_A"
	_override["clips"] = clips

	_wears_the_colours = bool(definition.get("tabard", true))


## The bones a given Styloo character hangs its weapon and kit off. Read off the
## three skeletons rather than guessed — the same discipline `art.json`'s
## `retarget_bones` comment insists on, and for the same reason: a bone name
## nobody has produces a warning and a prop that is still there.
##
## Naming the MASTER bone is enough. Godot's bone poses compose down the chain,
## so collapsing `DEF-staffMaster` takes `DEF-staff` through `DEF-staff.004` with
## it, and `trainer_model._hidden_bones()` walks the descendants when it measures.
static func _props_on(model_path: String, knight_default: Array) -> Array:
	if model_path.ends_with("mage.glb"):
		return ["DEF-staffMaster", "DEF-bookMaster"]
	if model_path.ends_with("dwarf.glb"):
		return ["DEF-weaponMaster"]
	if model_path.ends_with("knight.glb"):
		return knight_default
	push_warning("no prop-bone list for '%s'; it may carry a weapon it should not" % model_path)
	return []


func _load_config() -> Dictionary:
	return _override if not _override.is_empty() else super()


func _art_trainer_block() -> Dictionary:
	var file := FileAccess.open(ART_CONFIG_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		return {}
	return (parsed as Dictionary).get("trainer", {})


func _ready() -> void:
	super()
	if _wears_the_colours:
		DRESS.tabard(_art)
	_idle()


## --- what the body does ----------------------------------------------------

func _idle() -> void:
	_oneshot_left = 0.0
	# Guarded because the base class's `_ready` gives up early on a model that
	# would not load, leaving no AnimationPlayer behind. A missing Warden should
	# be one loud error, not that error plus a null dereference on the next line.
	if _anim == null:
		return
	_play(str(_clips.get(ROLE_IDLE, "Idle_B")))


## Play a role's clip once and go back to idling.
##
## The base's `_process` drives clips off a controller and returns immediately
## when there is not one, so nothing here would ever leave a one-shot — a Warden
## who threw an orb would hold the last frame of the throw for the rest of the
## fight. That is what the timer below is for.
func play_role(role: String) -> void:
	var clip := str(_clips.get(role, ""))
	if clip.is_empty() or _anim == null or not _anim.has_animation(clip):
		return
	_play(clip)
	_oneshot_left = _anim.get_animation(clip).length


func _process(delta: float) -> void:
	if _anim == null:
		return
	if _oneshot_left > 0.0:
		_oneshot_left -= delta
		if _oneshot_left <= 0.0:
			_idle()
		return
	# Restart the idle if it ever falls out. `_apply_loops` marks the idle role's
	# clip as looping, so this should not fire; it is here because the base class
	# records, at length, what a clip that quietly stopped looping cost.
	if not _anim.is_playing():
		_idle()
