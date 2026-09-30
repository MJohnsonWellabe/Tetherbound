extends RefCounted

## Grandpa acknowledges this portable character's actual return after Stormwood.
## Travel owns the protected arrival receipt; this module only reads it and
## saves this character's conversation and credits acknowledgement.

const HOME_RETURN_PREFIX := "home_return_after_stormwood:"
const STARTER_CHOICE_PREFIX := "starter_choice:"
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
	var local: Variant = game.get("local")
	if game.get("world") == null or local == null or local.get("realm") != "meadows":
		return false
	var personal: Variant = local.get("redesign_character")
	if not personal is Dictionary:
		return false
	var id := character_id(game)
	var receipts: Variant = personal.get("transaction_receipts", [])
	return has_return_receipt(id, receipts) if receipts is Array else false


static func has_return_receipt(id: String, receipts: Array) -> bool:
	if id.is_empty():
		return false
	for raw: Variant in receipts:
		var pieces := str(raw).split(":")
		if pieces.size() == 4 and pieces[0] == HOME_RETURN_PREFIX.trim_suffix(":") \
				and not pieces[1].is_empty() and pieces[2] == id and not pieces[3].is_empty():
			return true
	return false


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
	out["starter_status"] = starter_status(_party(game), character_id(game), _transaction_receipts(game))
	out["bond_memory"] = bond_memory(_party(game))
	out["chapter_choices"] = chapter_choices(_player_flags(game))
	return out


## Opening owns the atomic actual-choice receipt. A current starter species can
## have been traded in; species alone never identifies this character's choice.
static func starter_status(party: Object, id: String = "", receipts: Array = []) -> String:
	var chosen_uid := starter_choice_uid(id, receipts)
	if chosen_uid.is_empty():
		return "I can't tell whether your first companion is still travelling with you. That beginning still matters."
	for member: Object in _members(party):
		if str(member.get("uid")) == chosen_uid:
			return "%s, the companion you chose here, is still beside you." % _name(member)
	# The chosen companion is absent. Its old name/species are not recorded here;
	# acknowledge absence without inventing them or resurrecting that creature.
	return "Your first companion is no longer travelling with you. That beginning still matters."


static func starter_choice_uid(id: String, receipts: Array) -> String:
	if id.is_empty():
		return ""
	var chosen := ""
	for raw: Variant in receipts:
		if not raw is String:
			continue
		var pieces := str(raw).split(":")
		if pieces.size() != 3 or pieces[0] != STARTER_CHOICE_PREFIX.trim_suffix(":") \
				or pieces[1] != id or pieces[2].is_empty():
			continue
		if not chosen.is_empty() and chosen != pieces[2]:
			return "" # Conflicting records cannot identify an original companion.
		chosen = pieces[2]
	return chosen


static func _transaction_receipts(game: Object) -> Array:
	var local: Variant = game.get("local") if game != null else null
	var personal: Variant = local.get("redesign_character") if local is Object else null
	var receipts: Variant = personal.get("transaction_receipts", []) if personal is Dictionary else null
	return receipts.duplicate() if receipts is Array else []


static func bond_memory(party: Object) -> String:
	for member: Object in _members(party):
		var name := _name(member)
		for counter: String in ["landmarks_visited_together", "battles_fought", "rest_nights_together", "feeds_together"]:
			var raw: Variant = member.get(counter)
			var count := int(raw) if raw is int or raw is float else 0
			if count <= 0:
				continue
			match counter:
				"landmarks_visited_together":
					return "%s's story already holds %d landmarks. There is room for more on the road ahead." % [name, count]
				"battles_fought":
					return "%s has fought %d battles. I'm glad their road brought them here." % [name, count]
				"rest_nights_together":
					return "%s has rested through %d nights. A journey is made of quiet care, too." % [name, count]
				"feeds_together":
					return "%s has been fed %d times along the way. Quiet care belongs in their story, too." % [name, count]
	# A newly replaced team may have no earned counters. Never invent a battle,
	# landmark or night's rest to fill the emotional beat.
	return "You brought this company home. There is room here to make more memories together."


static func chapter_choices(flags: Object) -> String:
	var lines: Array[String] = []
	if flags == null or not flags.has_method("has"):
		return "The companions you met had their own wishes. Their invitations were yours to answer."
	for row: Array in [
		["legendary_joined", "legendary_refused", "Veridian"],
		["cloudreach:legendary_joined", "cloudreach:legendary_refused", "Solmane"],
	]:
		if bool(flags.call("has", row[0])):
			lines.append("You chose to welcome %s on your travels." % row[2])
		elif bool(flags.call("has", row[1])):
			lines.append("You let %s stay behind when it offered to follow." % row[2])
	if bool(flags.call("has", "stormwood:legendary_offer_accepted")):
		lines.append("You welcomed the Stormheart when it offered to join you.")
	elif flags.has_method("all_set"):
		for raw: Variant in flags.call("all_set"):
			var flag := str(raw)
			if flag.begins_with("stormwood:legendary_answer:") and flag.ends_with(":refused"):
				lines.append("You let the Stormheart choose its own road.")
				break
	return " ".join(lines) if not lines.is_empty() else \
		"The companions you met had their own wishes. Their invitations were yours to answer."


static func _members(party: Object) -> Array[Object]:
	var out: Array[Object] = []
	if party == null or not party.has_method("members"):
		return out
	for raw: Variant in party.call("members"):
		if raw is Object and out.size() < MAX_PARTY:
			out.append(raw)
	return out


static func _name(member: Object) -> String:
	var raw: Variant = member.get("nickname")
	var nickname := str(raw).strip_edges() if raw is String else ""
	return nickname if not nickname.is_empty() else str(member.get("display_name"))


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


## Set, save, and roll back as one player-local transaction. The protected
## travel receipt is never rewritten here.
static func complete(game: Object, expected_character_id: String) -> bool:
	return _save_player_flag(game, expected_character_id, SEEN_FLAG, SAVE_FAILURE_NOTICE)


## Credits are a local continuation of a homecoming this portable character
## already saved. The character's actual Home return remains the invitation:
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
