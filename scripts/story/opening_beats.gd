extends RefCounted

## The beat list of the first fifteen minutes, read out of data.
##
## Pure, static, no nodes — so the shape of the opening can be tested without
## booting a world, the same split `prompt_arbiter.gd` has from
## `interaction_arbiter.gd`. `sequence_director.gd` is the node that holds which
## beat is current and does something about it; everything about what the beats
## ARE lives here.
##
## The order is NOT written down in this file. It is the key order of
## `beats.grandpa_conversations` in data/config/opening.json, because the order
## of the beats is the shape of the opening and that is content — the expected
## feedback is "the naming should come before he explains Team Tether", and that
## has to be answerable by editing JSON. data/config/opening.json used to claim
## the order lived here as code; it never did, and the claim outlived the file
## not existing by several milestones.
##
## What IS code, below, is the handful of beat ids the state machine has to
## recognise by name — the beat at which the starters unlock, the beat the fight
## happens in. Those are a contract between this file and the data, so
## `missing_beats()` checks the data still contains them and the director says so
## loudly at boot rather than gating on a beat that was renamed out from under it.

const CONFIG_PATH := "res://data/config/opening.json"

## The beats the machine reacts to by name. Everything else in the list is a
## state the player passes through and this file has no opinion about.
##
## Beat 4: the three starters offer their prompts, and only here.
const CHOOSE := "choose"
## Beat 5: the name has been typed and the pal is theirs. Transient — the
## director moves off it as soon as Grandpa's reply finishes.
const NAMED := "name"
## Beat 6: your pal is following and there is a bramblebun out past the rise.
const WALK_OUT := "walk_out"
## Beats 7 and 8, which are one state as far as the sequence is concerned: the
## fight and the catch both happen inside CombatManager.
const ENCOUNTER := "encounter"
## Beat 9: go back and he points at the ridge.
const ROAD := "road"
## After beat 9. Nothing is scripted from here on and that is the point.
const FREE_PLAY := "free_play"

const NAMED_BEATS := [CHOOSE, NAMED, WALK_OUT, ENCOUNTER, ROAD, FREE_PLAY]

static var _config: Dictionary = {}


static func config() -> Dictionary:
	if not _config.is_empty():
		return _config
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("the opening config is missing at %s" % CONFIG_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("%s is not valid JSON" % CONFIG_PATH)
		return {}
	_config = parsed
	return _config


## The beats, in order.
##
## Keys beginning with an underscore are skipped: every block in
## data/config/opening.json carries `_comment` keys and one of them would
## otherwise become a beat the player has to sit through.
static func order() -> Array[String]:
	var out: Array[String] = []
	for key: String in _conversations():
		if not key.begins_with("_"):
			out.append(key)
	return out


static func first() -> String:
	var beats := order()
	return "" if beats.is_empty() else beats[0]


static func has(beat: String) -> bool:
	return order().has(beat)


static func index_of(beat: String) -> int:
	return order().find(beat)


## The beat after this one, or an empty string at the end of the list.
##
## Empty rather than looping or clamping: running off the end of the opening is
## a mistake worth seeing, and the last beat is free play, which nothing should
## be trying to advance out of.
static func next(beat: String) -> String:
	var beats := order()
	var index := beats.find(beat)
	if index < 0 or index + 1 >= beats.size():
		return ""
	return beats[index + 1]


## Is `beat` at or past `mark` in the order? The gate question, asked by the
## director as "is the choice unlocked yet".
##
## False for either id being unknown, which is the safe direction: an unknown
## beat leaves things locked rather than opening them all at once.
static func at_or_after(beat: String, mark: String) -> bool:
	var here := index_of(beat)
	var there := index_of(mark)
	if here < 0 or there < 0:
		return false
	return here >= there


## What Grandpa says if you walk up to him during this beat. Empty for a beat
## where he has nothing scripted — the director takes his prompt away rather
## than opening a box with nothing in it.
static func conversation_for(beat: String) -> String:
	return str(_conversations().get(beat, ""))


## The reply he gives the moment the name is confirmed, rather than when you
## next talk to him.
static func named_conversation() -> String:
	return str(_beats().get("named_conversation", ""))


## Which beat a dialogue effect asks for. `effect` is the part after the colon:
## `beat:starter_choice` arrives here as "starter_choice".
##
## Empty for an effect nobody has mapped, so the director can say which unknown
## effect it just ignored. dialogue_runner.gd hands effects back as opaque
## strings precisely so an unrecognised one is a loud no-op rather than a crash
## halfway through a conversation.
static func beat_for_effect(effect: String) -> String:
	var table: Variant = _beats().get("effects", {})
	if not table is Dictionary:
		return ""
	return str((table as Dictionary).get(effect, ""))


## Beat ids this file names in code that the data does not contain. Empty when
## the two agree.
static func missing_beats() -> Array[String]:
	var out: Array[String] = []
	var beats := order()
	for beat: String in NAMED_BEATS:
		if not beats.has(beat):
			out.append(beat)
	return out


## Effect targets the data names that are not beats. Same failure as above from
## the other end: an effect pointing at a beat that does not exist is a
## conversation that ends and changes nothing.
static func broken_effects() -> Array[String]:
	var out: Array[String] = []
	var table: Variant = _beats().get("effects", {})
	if not table is Dictionary:
		return out
	var beats := order()
	for key: String in table as Dictionary:
		if key.begins_with("_"):
			continue
		if not beats.has(str((table as Dictionary)[key])):
			out.append(key)
	return out


## --- the placements and the numbers ------------------------------------------
##
## Thin accessors rather than a parsed struct. Every value behind them is TUNABLE
## (CLAUDE.md) and the expected edit is to the JSON, so nothing here should make
## a caller go looking in GDScript for a distance.

static func grandpa() -> Dictionary:
	return _block("grandpa")


static func starters() -> Dictionary:
	return _block("starters")


static func follower() -> Dictionary:
	return _block("follower")


static func encounter() -> Dictionary:
	return _block("encounter")


## Beat 1 is a fade-in from black instead of an interior, which saves an entire
## interior art pass for a beat that lasts forty seconds.
static func fade() -> Dictionary:
	return _block("fade")


## Where the three starters stand: a row `forward` metres in front of Grandpa on
## his own facing, `spread` apart, centred. Returned as offsets from his feet so
## the caller can put them on the ground itself — a Y written down here would rot
## the next time the terrain is baked (docs/decisions/D09).
static func starter_offsets(facing: Vector3) -> Array[Vector3]:
	var cfg := starters()
	var species: Array = cfg.get("species", [])
	var forward := facing
	forward.y = 0.0
	if forward.length() < 0.01:
		forward = Vector3.FORWARD
	forward = forward.normalized()
	var side := forward.cross(Vector3.UP).normalized()

	var spread := float(cfg.get("spread", 3.5))
	var out: Array[Vector3] = []
	for i in species.size():
		var lateral := (float(i) - (species.size() - 1) * 0.5) * spread
		out.append(forward * float(cfg.get("forward", 4.5)) + side * lateral)
	return out


static func _block(key: String) -> Dictionary:
	var entry: Variant = config().get(key, {})
	return entry if entry is Dictionary else {}


static func _beats() -> Dictionary:
	return _block("beats")


static func _conversations() -> Dictionary:
	var entry: Variant = _beats().get("grandpa_conversations", {})
	return entry if entry is Dictionary else {}
