extends RefCounted

## F20 presentation adapter. Foundations owns state writes and durable receipts.
## Missing owner integration fails closed; this module never grants rewards.
const WORLD_FLAG := "stormwood:stormheart_freed"
const SEEN_FLAG := "homecoming_seen"
const CREDITS_SEEN_FLAG := "regional_credits_seen"
const INITIAL_PREFIX := "regional_homecoming_"
const REPEAT_ID := "regional_homecoming_repeat"
const MAX_PARTY := 5
const CONFIG_PATH := "res://data/config/regional_credits.json"
const OBJECTIVES_PATH := "res://data/config/regional_ending_objectives.json"
const SAVE_FAILURE_NOTICE := "Homecoming was not saved. Talk to Grandpa again to keep it."
const CREDITS_SAVE_FAILURE_NOTICE := "The credits acknowledgement was not saved. Talk to Grandpa again to revisit it."
const CONTEXT_FIELDS := ["world_instance_id", "session_epoch", "character_id",
	"outcome_id", "home_return_receipt", "party_revision", "party_signature"]


## An original personal finale answer, never a shared world win or roster guess.
static func personal_outcome(flags: Dictionary) -> String:
	if flags.get("stormwood:legendary_ceremony_settled") != true:
		return ""
	var originals: Array[String] = []
	var answers: Array[String] = []
	for flag: String in flags:
		if flags[flag] != true: continue
		if flag.begins_with("stormwood:regional_outcome:"): originals.append(flag)
		if flag.begins_with("stormwood:legendary_answer:"): answers.append(flag)
	if originals.size() > 1 or (originals.is_empty() and answers.size() != 1): return ""
	var outcome: String = answers[0] if originals.is_empty() else originals[0].replace("stormwood:regional_outcome:", "stormwood:legendary_answer:")
	if not answers.has(outcome) or outcome.get_slice(":", outcome.get_slice_count(":") - 1) not in ["accepted", "refused"]: return ""
	return outcome


## Only the authority's grounded Home Key arrival after this finale mints this
## marker. Earlier home visits and the Hall's home portal cannot satisfy F20.
static func return_prefix(world_id: String, outcome: String) -> String:
	if world_id.is_empty() or outcome.is_empty(): return ""
	return "craft:ending_home_return_%s_%s_" % [world_id, outcome.sha256_text()]


static func home_return_receipt(receipts: Array, world_id: String, character: String, outcome: String) -> String:
	var prefix := return_prefix(world_id, outcome)
	if prefix.is_empty() or character.is_empty(): return ""
	var found := ""
	for raw: Variant in receipts:
		if raw is String and raw.begins_with(prefix) and raw.ends_with(":" + character):
			# Both owner and host choose the same marker regardless of receipt order.
			# A new return is disallowed while presentation/ACK owns input.
			if found.is_empty() or raw < found: found = raw
	return found


static func context(game: Object) -> Dictionary:
	var value := journey_context(game)
	if value.is_empty() or value.get("realm") != "meadows" \
			or value.get("at_farm") != true or value.get("safe") != true \
			or value.get("durable_home_return") != true \
			or not value.get("home_return_receipt") is String \
			or str(value.home_return_receipt).strip_edges().is_empty():
		return {}
	return value


## The personal accepted finale outcome can guide Home Key travel before
## arrival. It cannot complete the farm conversation or credits by itself.
static func journey_context(game: Object) -> Dictionary:
	if game == null or not game.has_method("regional_ending_context"):
		return {}
	var raw: Variant = game.call("regional_ending_context")
	if not raw is Dictionary:
		return {}
	var value: Dictionary = raw
	if not value.get("version") is int or value.get("version") != 1 \
			or value.get("character_id") != character_id(game):
		return {}
	if not value.get(SEEN_FLAG) is bool or not value.get(CREDITS_SEEN_FLAG) is bool \
			or not value.get("starter_uid") is String or str(value.starter_uid).strip_edges().is_empty() \
			or not value.get("chapter_choices") is Array:
		return {}
	var answered: Array[String] = []
	for choice: Variant in value.chapter_choices:
		if not choice is String or not _prose().get("choices", {}).has(choice):
			return {}
		var biome := str(choice).get_slice(":", 0)
		if answered.has(biome):
			return {}
		answered.append(biome)
	var party := _party(game)
	if not valid_party(party) or value.get("party_revision") != party.get("revision") \
			or value.get("party_signature") != party_signature(party):
		return {}
	for field: String in CONTEXT_FIELDS:
		if field == "home_return_receipt":
			continue # Only required after the actual Home Key arrival.
		elif field == "party_revision":
			if not value.get(field) is int or int(value[field]) < 0:
				return {}
		elif not value.get(field) is String or str(value[field]).strip_edges().is_empty():
			return {}
	if not value.get("accepted_outcome") is bool or value.get("accepted_outcome") != true:
		return {}
	return value.duplicate(true)


static func aftermath_conversation(game: Object) -> String:
	var value := journey_context(game)
	return "stormwood_homecoming_aftermath" if not value.is_empty() \
		and value.get("realm") == "stormwood" and value.get(SEEN_FLAG) != true else ""


static func handoff_retry_seconds() -> float:
	return maxf(0.1, float(_settings().get("handoff_retry_seconds", 0.5)))


## One presentation reader for the owning quest log's HUD/journal/map/beacon.
## It never grants an ending to a character merely visiting an ahead world.
static func objective_rows(game: Object, authored: Dictionary = {}, realm_id: String = "") -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var current := journey_context(game)
	if current.is_empty() or current.get(CREDITS_SEEN_FLAG) == true:
		return rows
	if authored.is_empty():
		var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(OBJECTIVES_PATH))
		authored = raw if raw is Dictionary else {}
	var realm := str(current.get("realm", ""))
	if not realm_id.is_empty() and realm != realm_id:
		return rows
	var supported: Variant = authored.get("supported_realms", [])
	if not supported is Array or not supported.has(realm):
		return rows
	for raw: Variant in authored.get("rows", []):
		if not raw is Dictionary or raw.get("scope") != "player" \
				or raw.get("flag_id") not in [SEEN_FLAG, CREDITS_SEEN_FLAG]:
			continue
		var row: Dictionary = raw.duplicate(true)
		var by_realm: Variant = row.get("realms", {})
		row.erase("realms")
		if by_realm is Dictionary and by_realm.get(realm) is Dictionary:
			row.merge(by_realm[realm], true)
		if current.get("durable_home_return") != true:
			row.erase("beacon")
			var before_return: Variant = authored.get("before_home_return", {})
			if before_return is Dictionary:
				row.merge(before_return, true)
		rows.append(row)
	return rows


static func valid_party(party: Object) -> bool:
	if party == null or not party.has_method("members"):
		return false
	var raw: Variant = party.call("members")
	if not raw is Array or raw.size() > MAX_PARTY:
		return false
	var uids: Array[String] = []
	for member: Variant in raw:
		if not member is Object or not member.get("uid") is String \
				or str(member.get("uid")).is_empty() or _name(member).is_empty() \
				or uids.has(str(member.get("uid"))):
			return false
		uids.append(str(member.get("uid")))
	return true


## Compare the live speaking roster, names and memory counters against the
## canonical owner view. Never persist a second roster for the ending.
static func party_signature(party: Object) -> String:
	if not valid_party(party):
		return ""
	var rows: Array = []
	for member: Object in _members(party):
		rows.append([member.get("uid"), _name(member),
			member.get("landmarks_visited_together"), member.get("battles_fought"),
			member.get("rest_nights_together"), member.get("feeds_together")])
	return JSON.stringify(rows).sha256_text()


## party_signature without passive care (landmarks walked together), which a
## host copy of a guest's party receives only at owner-passive gates.
static func party_identity_signature(party: Object) -> String:
	if not valid_party(party):
		return ""
	var rows: Array = []
	for member: Object in _members(party):
		rows.append([member.get("uid"), _name(member), member.get("battles_fought"),
			member.get("rest_nights_together"), member.get("feeds_together")])
	return JSON.stringify(rows).sha256_text()


static func eligible(game: Object) -> bool:
	return not context(game).is_empty()


static func context_matches(game: Object, expected: Dictionary) -> bool:
	var current := context(game)
	if current.is_empty() or expected.is_empty():
		return false
	for field: String in CONTEXT_FIELDS:
		if current.get(field) != expected.get(field):
			return false
	if current.get("starter_uid") != expected.get("starter_uid") \
			or current.get("chapter_choices") != expected.get("chapter_choices"):
		return false
	return true


static func conversation_id(game: Object) -> String:
	var current := context(game)
	if current.is_empty():
		return ""
	if current.get(SEEN_FLAG) == true:
		return REPEAT_ID
	return INITIAL_PREFIX + str(party_names(_party(game)).size())


static func is_initial(id: String) -> bool:
	var suffix := id.trim_prefix(INITIAL_PREFIX)
	return id.begins_with(INITIAL_PREFIX) and suffix.is_valid_int() \
		and int(suffix) >= 0 and int(suffix) <= MAX_PARTY


static func substitutions(game: Object) -> Dictionary:
	var out := {}
	var current := context(game)
	if current.is_empty():
		return out
	var party := _party(game)
	var names := party_names(party)
	for index in names.size():
		out["party_%d" % (index + 1)] = names[index]
	var prose := _prose()
	out["starter_status"] = starter_status(party, str(current.get("starter_uid", "")), prose)
	out["bond_memory"] = bond_memory(party, prose)
	out["chapter_choices"] = chapter_choices(current.get("chapter_choices", []), prose)
	return out


static func starter_status(party: Object, starter_uid: String, prose: Dictionary = {}) -> String:
	if starter_uid.is_empty():
		return str(prose.get("starter_unknown", "That first beginning still matters."))
	for member: Object in _members(party):
		if member.get("uid") == starter_uid:
			return str(prose.get("starter_present", "%s is still beside you.")) % _name(member)
	return str(prose.get("starter_absent", "Your first companion took another road. That beginning still matters."))


static func bond_memory(party: Object, prose: Dictionary = {}) -> String:
	var memories: Variant = prose.get("memories", [])
	if memories is Array:
		for member: Object in _members(party):
			for raw: Variant in memories:
				if not raw is Dictionary:
					continue
				var count: Variant = member.get(str(raw.get("counter", "")))
				if (count is int or count is float) and int(count) > 0:
					return str(raw.get("line", "%s has shared %d moments with you.")) % [_name(member), int(count)]
	return str(prose.get("memory_empty", "There is room here to make more memories together."))


## Canonical personal choices from the owner context; shared offers never
## imply that this character accepted a companion.
static func chapter_choices(choices: Variant, prose: Dictionary = {}) -> String:
	var lines: Array[String] = []
	var authored: Dictionary = prose.get("choices", {})
	if choices is Array:
		for raw: Variant in choices:
			if raw is String and authored.has(raw) and not lines.has(str(authored[raw])):
				lines.append(str(authored[raw]))
	return " ".join(lines) if not lines.is_empty() else str(prose.get("choices_empty",
		"Those you met had their own wishes. Their invitations were yours to answer."))


static func party_names(party: Object) -> Array[String]:
	var names: Array[String] = []
	if not valid_party(party):
		return names
	for member: Object in _members(party):
		names.append(_name(member))
	return names


static func credits_available(game: Object) -> bool:
	var current := context(game)
	return not current.is_empty() and current.get(SEEN_FLAG) == true


static func credits_pending(game: Object) -> bool:
	var current := context(game)
	return not current.is_empty() and current.get(SEEN_FLAG) == true \
		and current.get(CREDITS_SEEN_FLAG) != true


static func complete(game: Object, expected_character_id: String,
		expected_context: Dictionary = {}) -> bool:
	return await _acknowledge(game, expected_character_id, expected_context, SEEN_FLAG)


static func complete_credits(game: Object, expected_character_id: String,
		expected_context: Dictionary = {}) -> bool:
	return await _acknowledge(game, expected_character_id, expected_context, CREDITS_SEEN_FLAG)


static func acknowledgement_intent(expected: Dictionary, flag: String) -> Dictionary:
	if expected.is_empty() or flag not in [SEEN_FLAG, CREDITS_SEEN_FLAG]:
		return {}
	for field: String in CONTEXT_FIELDS:
		if field == "party_revision":
			if not preload("res://scripts/creatures/traits.gd").integer(expected.get(field), 0, 9007199254740991):
				return {}
		elif not expected.get(field) is String or str(expected[field]).strip_edges().is_empty():
			return {}
	var intent := {"kind": "regional_ending_ack", "version": 1, "stage": flag}
	for field: String in CONTEXT_FIELDS:
		intent[field] = expected.get(field)
	intent.party_revision = int(expected.party_revision)
	# Global per-character acknowledgement; changing host cannot replay credits.
	intent["transaction_id"] = "regional_ending:%s:%s" % [expected.get("character_id", ""), flag]
	return intent


static func _acknowledge(game: Object, id: String, expected: Dictionary, flag: String) -> bool:
	# Retain our own snapshot across the authority callback and frame waits.
	# Dictionary arguments are references; neither the caller nor an owner
	# implementation may rewrite the envelope we later verify.
	expected = expected.duplicate(true)
	var failure := CREDITS_SAVE_FAILURE_NOTICE if flag == CREDITS_SEEN_FLAG else SAVE_FAILURE_NOTICE
	if id.is_empty() or id != character_id(game) or not context_matches(game, expected) \
			or not game.has_method("commit_regional_ending_ack"):
		_notice(game, failure)
		return false
	if flag == CREDITS_SEEN_FLAG and not credits_available(game):
		_notice(game, failure)
		return false
	var intent := acknowledgement_intent(expected, flag)
	var raw: Variant = game.call("commit_regional_ending_ack", intent.duplicate(true))
	var deadline := Time.get_ticks_msec() + ack_timeout_ms(game)
	while raw is Dictionary and raw.get("status") == "pending":
		if not context_matches(game, expected) or Time.get_ticks_msec() >= deadline \
				or not game is Node or not game.is_inside_tree() \
				or not game.has_method("regional_ending_ack_result"):
			_notice(game, failure)
			return false
		await game.get_tree().process_frame
		if not is_instance_valid(game) or not context_matches(game, expected):
			return false
		raw = game.call("regional_ending_ack_result", intent.transaction_id)
	if receipt_matches(raw, intent) and context_matches(game, expected) \
			and context(game).get(flag) == true:
		return true
	_notice(game, failure)
	return false


static func receipt_matches(raw: Variant, intent: Dictionary) -> bool:
	if not raw is Dictionary or intent.is_empty():
		return false
	var expected := acknowledgement_intent(intent, str(intent.get("stage", "")))
	if expected.is_empty() or intent.get("kind") != "regional_ending_ack" \
			or not intent.get("version") is int or intent.get("version") != 1 \
			or intent.get("transaction_id") != expected.get("transaction_id"):
		return false
	if acknowledgement_intent(raw, str(raw.get("stage", ""))).is_empty() \
			or not raw.get("version") is int \
			or not raw.get("party_revision") is int \
			or raw.get("status") != "committed" or not raw.get("durable") is bool \
			or raw.get("durable") != true \
			or raw.get("kind") != intent.get("kind") or raw.get("version") != intent.get("version") \
			or raw.get("transaction_id") != intent.get("transaction_id") \
			or raw.get("stage") != intent.get("stage"):
		return false
	for field: String in CONTEXT_FIELDS:
		if raw.get(field) != intent.get(field):
			return false
	return true


static func character_id(game: Object) -> String:
	var local: Variant = game.get("local") if game != null else null
	var raw: Variant = local.get("character_id") if local is Object else null
	return raw.strip_edges() if raw is String else ""


static func _party(game: Object) -> Object:
	var party: Variant = game.get("party") if game != null else null
	return party as Object if party is Object else null


static func _members(party: Object) -> Array[Object]:
	var members: Array[Object] = []
	if party != null and party.has_method("members"):
		for raw: Variant in party.call("members"):
			if raw is Object and members.size() < MAX_PARTY:
				members.append(raw)
	return members


static func _name(member: Object) -> String:
	var nick: Variant = member.get("nickname")
	if nick is String and not nick.strip_edges().is_empty():
		return nick.strip_edges()
	var display: Variant = member.get("display_name")
	return display.strip_edges() if display is String else ""


static func _prose() -> Dictionary:
	return _settings().get("homecoming", {})


## How long an acknowledgement may stay pending. A guest's is a host round
## trip, so it gets its own (longer) window; the host's commits in-frame.
static func ack_timeout_ms(game: Object) -> int:
	var settings := _settings()
	var session: Variant = game.get("session") if game != null else null
	var guest: bool = session is Node and session.has_method("is_host") and session.call("is_host") != true
	var seconds: Variant = settings.get("guest_ack_timeout_seconds" if guest else "ack_timeout_seconds", 8.0)
	if not (seconds is float or seconds is int): seconds = 8.0
	return int(float(seconds) * 1000.0)


static func _settings() -> Dictionary:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	return raw if raw is Dictionary else {}


static func _notice(game: Object, message: String) -> void:
	if game != null and game.has_method("push_world_message"):
		game.call("push_world_message", message)
