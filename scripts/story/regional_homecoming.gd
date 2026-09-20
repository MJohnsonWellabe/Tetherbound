extends RefCounted

## The small, character-local transaction behind Grandpa's Water homecoming.
## Eligibility is a fact of the current world; acknowledgement belongs only to
## the portable character who stood through the conversation and saved it.

const WORLD_FLAG := "water_currents_restored"
const SEEN_FLAG := "homecoming_seen"
const CREDITS_SEEN_FLAG := "regional_credits_seen"
const INITIAL_PREFIX := "regional_homecoming_"
const REPEAT_ID := "regional_homecoming_repeat"
const MAX_PARTY := 5
const SAVE_FAILURE_NOTICE := "Homecoming was not saved. Talk to Grandpa again to keep it."
const CREDITS_SAVE_FAILURE_NOTICE := "The credits acknowledgement was not saved. Talk to Grandpa again to revisit it."


static func conversation_id(game: Object) -> String:
	if not eligible(game):
		return ""
	var flags := _player_flags(game)
	if flags != null and bool(flags.call("has", SEEN_FLAG)):
		return REPEAT_ID
	return INITIAL_PREFIX + str(party_names(_party(game)).size())


static func eligible(game: Object) -> bool:
	if game == null:
		return false
	var world: Variant = game.get("world")
	var local: Variant = game.get("local")
	if world == null or local == null or local.get("realm") != "meadows":
		return false
	var flags: Variant = world.get("flags")
	return flags != null and flags.has_method("has") and bool(flags.call("has", WORLD_FLAG))


static func is_initial(id: String) -> bool:
	if not id.begins_with(INITIAL_PREFIX):
		return false
	var suffix := id.trim_prefix(INITIAL_PREFIX)
	return suffix.is_valid_int() and int(suffix) >= 0 and int(suffix) <= MAX_PARTY


static func substitutions(game: Object) -> Dictionary:
	var out := {}
	var names := party_names(_party(game))
	for index in names.size():
		out["party_%d" % (index + 1)] = names[index]
	return out


static func party_names(party: Object) -> Array[String]:
	var out: Array[String] = []
	if party == null or not party.has_method("members"):
		return out
	for raw: Variant in party.call("members") as Array:
		if out.size() >= MAX_PARTY:
			break
		if not raw is Object:
			continue
		var member: Object = raw as Object
		var nickname_raw: Variant = member.get("nickname")
		var display_raw: Variant = member.get("display_name")
		var nickname: String = nickname_raw.strip_edges() if nickname_raw is String else ""
		var display_name: String = display_raw.strip_edges() if display_raw is String else ""
		var chosen: String = nickname if not nickname.is_empty() else display_name
		if not chosen.is_empty():
			out.append(chosen)
	return out


## Set, save, and roll back as one player-local transaction. The world fact is
## only the invitation to talk; it is never rewritten here.
static func complete(game: Object, expected_character_id: String) -> bool:
	return _save_player_flag(game, expected_character_id, SEEN_FLAG, SAVE_FAILURE_NOTICE)


## Credits are a local continuation of a homecoming this portable character
## already saved. The current world's Water outcome remains the invitation:
## joining an ahead world does not manufacture a personal ending receipt.
static func credits_available(game: Object) -> bool:
	if not eligible(game):
		return false
	var flags := _player_flags(game)
	return flags != null and bool(flags.call("has", SEEN_FLAG))


static func credits_pending(game: Object) -> bool:
	if not credits_available(game):
		return false
	var flags := _player_flags(game)
	return flags != null and not bool(flags.call("has", CREDITS_SEEN_FLAG))


## The roll itself changes no world state. A skipped roll and a watched roll
## both acknowledge the regional ending, then persist that one player-local
## fact. Failure restores the flag so Grandpa remains a retry path.
static func complete_credits(game: Object, expected_character_id: String) -> bool:
	if not credits_available(game):
		_notice(game, CREDITS_SAVE_FAILURE_NOTICE)
		return false
	return _save_player_flag(game, expected_character_id, CREDITS_SEEN_FLAG,
		CREDITS_SAVE_FAILURE_NOTICE)


static func character_id(game: Object) -> String:
	var local: Variant = game.get("local") if game != null else null
	var raw: Variant = local.get("character_id") if local != null else null
	return raw.strip_edges() if raw is String else ""


static func _party(game: Object) -> Object:
	if game == null:
		return null
	var party: Variant = game.get("party")
	return party as Object if party is Object else null


static func _player_flags(game: Object) -> Object:
	if game == null:
		return null
	var local: Variant = game.get("local")
	if local == null:
		return null
	var flags: Variant = local.get("flags")
	return flags as Object if flags is Object else null


static func _save_player_flag(game: Object, expected_character_id: String,
		flag: String, failure_notice: String) -> bool:
	if not eligible(game):
		_notice(game, failure_notice)
		return false
	var flags := _player_flags(game)
	var local: Variant = game.get("local") if game != null else null
	var save_system: Variant = game.get("save_system") if game != null else null
	var character_raw: Variant = local.get("character_id") if local != null else null
	var character_id: String = character_raw.strip_edges() if character_raw is String else ""
	if flags == null or save_system == null or not save_system.has_method("save_character") \
			or character_id.is_empty() or character_id != expected_character_id:
		_notice(game, failure_notice)
		return false
	if bool(flags.call("has", flag)):
		return true
	flags.call("set_flag", flag, true)
	if bool(save_system.call("save_character", game, character_id)):
		return true
	flags.call("set_flag", flag, false)
	_notice(game, failure_notice)
	return false


static func _notice(game: Object, message: String = SAVE_FAILURE_NOTICE) -> void:
	if game != null and game.has_method("push_world_message"):
		game.call("push_world_message", message)
