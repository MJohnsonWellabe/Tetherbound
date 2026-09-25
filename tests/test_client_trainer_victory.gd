extends "res://tests/test_case.gd"

# A records-participant trainer beaten by a CLIENT is journaled by the HOST.
#
# Rule (CLAUDE.md, owner decision): every participant in the fight that freed a
# legendary receives their own offer; a non-participant receives nothing. The
# offer is read off the world's per-character reward journal
# (`trainer:<id>:*` deliveries). Before this change only a HOST-run trainer
# battle wrote those rows (`_pay_every_participant`); a client that fought and
# won locally submitted only the world facts and paid itself, so the journal
# named nobody and the downstream offer went to the wrong people.
#
# Host authority: the client asks with `trainer_victory` carrying ONLY the
# trainer id. The host resolves who asked from the transport sender and its own
# registry, never from the payload, and pays before it commits the world fact so
# a failed journal never leaves a beaten trainer with nobody paid.

const WORLD_LEDGER := preload("res://scripts/net/world_ledger.gd")
const WORLD_STATE := preload("res://autoload/world_state.gd")
const PLAYER_STATE := preload("res://autoload/player_state.gd")
const PROGRESSION_STATE := preload("res://autoload/progression_state.gd")
const PEER_REGISTRY := preload("res://scripts/net/peer_registry.gd")
const ITEM_DB := preload("res://autoload/item_db.gd")
const TRAINERS := preload("res://scripts/world/trainer_npc.gd")
const CLIMAX := preload("res://scripts/world/stronghold_climax.gd")

const HOST := 1
const CLIENT := 424242
const HOST_CHARACTER := "host-a"
const CLIENT_CHARACTER := "client-b"
const WARDEN := "warden_aldis"
const NERISSA := "water_trainer_nerissa"
const NERISSA_FLAG := "water_captain_nerissa_defeated"


class Saver extends RefCounted:
	var fail_world := false
	func save_world(_game: Object, _world_id: String) -> bool:
		return not fail_world
	func save_character(_game: Object, _character_id: String) -> bool:
		return true


## One stub answers both the ledger's `registry()` and the director's
## `peers()`, so the two can never disagree about who is admitted.
class SessionStub extends Node:
	var host := true
	var peer_id := HOST
	var rows: RefCounted = PEER_REGISTRY.new()
	func is_active() -> bool: return true
	func is_host() -> bool: return host
	func is_multi_peer() -> bool: return int(rows.call("size")) > 1
	func mode() -> String: return "host" if host else "client"
	func handshake_snapshot_applied() -> bool: return true
	func snapshot_ready() -> bool: return true
	func local_peer_id() -> int: return peer_id
	func registry() -> RefCounted: return rows
	func peers() -> Array: return rows.call("rows")


class GameFixture extends Node:
	var world: RefCounted = WORLD_STATE.new()
	var local: RefCounted = PLAYER_STATE.new()
	var save_system: RefCounted = Saver.new()
	var session: Node = SessionStub.new()
	var messages: Array = []
	func _init() -> void:
		session.name = "Session"
		add_child(session)
	func is_host() -> bool: return bool(session.host)
	func is_multi_peer() -> bool: return false
	func push_world_message(message: String) -> void: messages.append(message)


class RpcFixture extends "res://scripts/net/ledger_rpc.gd":
	var fixture_game: Node
	func _game() -> Node: return fixture_game
	func _can_rpc() -> bool: return false


## The production director with its transport seams captured. Everything the
## change is about -- the client's submit, the host's arbitration, the grant
## loop, the world facts -- runs as shipped.
class DirectorFixture extends "res://scripts/combat/encounter_director.gd":
	var host := true
	var local_peer := HOST
	var realm := "meadows"
	var ledger_rpc: Node = null
	var progression_store: RefCounted = PROGRESSION_STATE.new()
	var sent: Array = []
	var ledger_submissions: Array = []
	var paid_notices: Array = []
	var local_pays := 0
	## Duck-typed like the Water/Cloudreach directors' own `trainer_specs`.
	## A Meadows director has no such table (null); `_as_water()` installs one.
	var trainer_specs: Variant = null
	func _ensure_encounter_arbiters() -> void:
		pass
	func _is_host() -> bool: return host
	func _is_multi_peer() -> bool: return true
	func _local_peer_id() -> int: return local_peer
	func _encounter_realm() -> String: return realm
	func _can_encounter_rpc() -> bool: return true
	func _realm_rpc_allowed(_peer: int, _completing: bool = false) -> bool: return true
	func _send_realm_rpc(peer: int, method: String, arguments: Array, completing: bool = false) -> bool:
		sent.append({"peer": peer, "method": method, "arguments": arguments.duplicate(true),
			"completing": completing})
		return true
	func _tell_participant_they_were_paid(peer_id: int, payload: Dictionary) -> void:
		paid_notices.append({"peer": peer_id, "payload": payload.duplicate(true)})
	func _pay_trainer_reward(_spec: Dictionary) -> void:
		local_pays += 1
	func _progression() -> RefCounted:
		return progression_store
	func _trainer_reward_line(spec: Dictionary) -> String:
		return "%s's reward" % str(spec.get("name", "Trainer"))
	func _submit_reward_intent(intent: Dictionary) -> Dictionary:
		ledger_submissions.append(intent.duplicate(true))
		if ledger_rpc == null:
			return {"ok": false, "pending": false, "code": "offline", "paid": []}
		return ledger_rpc.call("submit", intent)


var _game: GameFixture
var _rpc: Node
var _director: DirectorFixture


func before_each() -> void:
	_game = GameFixture.new()
	_game.world.world_id = "client-trainer-victory"
	_game.local.configure(ITEM_DB.new())
	_game.local.character_id = HOST_CHARACTER
	_admit(HOST, HOST_CHARACTER, "meadows")
	_admit(CLIENT, CLIENT_CHARACTER, "meadows")
	_rpc = RpcFixture.new()
	_rpc.set("fixture_game", _game)
	_rpc.set("ledger", WORLD_LEDGER.new(_game.world))
	_director = DirectorFixture.new()
	_director.set("_session", _game.session)
	_director.ledger_rpc = _rpc


## The fixture acts as the Water director: its own translated trainer table.
func _as_water() -> void:
	_director.realm = "water"
	_director.trainer_specs = {NERISSA: _nerissa_spec()}


func after_each() -> void:
	for node: Node in [_director, _rpc, _game]:
		if is_instance_valid(node):
			node.free()


func _admit(peer: int, character_id: String, realm: String) -> void:
	assert_false((_game.session.rows.add(peer, character_id, "", realm) as Dictionary).is_empty(),
		"fixture peer %d must be admitted" % peer)


## Nerissa as the Water director translates her: `water_encounter_runtime_data`
## names her by display name, takes her reward from `water_combat.json`'s tier
## for her rank, and Veilfall overrides her defeat flag in place.
func _nerissa_spec() -> Dictionary:
	var tuning: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://data/config/water_combat.json"))
	var reward: Dictionary = ((tuning.get("reward_tiers", {}) as Dictionary).get(
		"captain", {}) as Dictionary).duplicate(true)
	return {"id": NERISSA, "name": "Captain Nerissa", "rank": "captain",
		"chapter_rank": "captain", "rechallenge": false, "defeat_flag": NERISSA_FLAG,
		"reward": reward,
		"team": [{"trainer_owned": true, "species": "cannonback", "level": 55}]}


func _warden() -> Dictionary:
	return TRAINERS.trainer(WARDEN)


func _as_client() -> void:
	_director.host = false
	_director.local_peer = CLIENT
	_director.ledger_rpc = null


func _deliveries() -> Dictionary:
	return _game.world.reward_deliveries


func _rows_for(prefix: String) -> Array:
	var out: Array = []
	for raw: Variant in _deliveries().values():
		if raw is Dictionary and str((raw as Dictionary).get("source", "")).begins_with(prefix):
			out.append(raw)
	return out


func _characters_for(prefix: String) -> Array:
	var out: Array = []
	for row: Dictionary in _rows_for(prefix):
		var character := str(row.get("character_id", ""))
		if not out.has(character):
			out.append(character)
	out.sort()
	return out


func _sources_for(prefix: String) -> Array:
	var out: Array = []
	for row: Dictionary in _rows_for(prefix):
		if not out.has(str(row.get("source", ""))):
			out.append(str(row.get("source", "")))
	out.sort()
	return out


func _flag(id: String) -> bool:
	return bool(_game.world.flags.call("has", id))


## What the client's ack does on the host: the sender's registry row names the
## character, never the packet.
func _accept_all_for(peer: int) -> void:
	for id: String in _deliveries().keys():
		_rpc.call("_accept_reward_delivery", id, peer)


## `stronghold_climax.gd::_warden_participant_characters()`'s rule, applied to
## the same journal: accepted `trainer:warden_aldis:*` rows, by character.
func _accepted_warden_characters() -> Array:
	var out: Array = []
	for row: Dictionary in _rows_for("trainer:%s:" % WARDEN):
		if str(row.get("status", "")) == "accepted" \
				and not out.has(str(row.get("character_id", ""))):
			out.append(str(row.get("character_id", "")))
	return out


func _expected_warden_sources() -> Array:
	var out: Array = ["trainer:%s:coins" % WARDEN]
	for entry: Variant in TRAINERS.reward_items(_warden()):
		out.append("trainer:%s:item:%s" % [WARDEN, str((entry as Dictionary).get("id", ""))])
	out.sort()
	return out


# --- the client's side ----------------------------------------------------------

func _assert_client_routes_to_host(spec: Dictionary, trainer_id: String) -> void:
	_as_client()
	_director.call("_record_trainer_defeat", spec)
	assert_eq(_director.sent.size(), 1, "the client sent exactly one request to the host")
	if _director.sent.size() == 1:
		var sent: Dictionary = _director.sent[0]
		assert_eq(int(sent.peer), HOST, "addressed to the host")
		assert_eq(str(sent.method), "_rpc_encounter_intent", "through the encounter intent seam")
		assert_eq(sent.arguments, [{"kind": "trainer_victory", "trainer_id": trainer_id}],
			"carrying only the trainer id -- no character, peers, realm or sources")
		assert_true(bool(sent.completing),
			"sent even while the realm is closing, like every other finishing intent")
	assert_eq(_director.ledger_submissions.size(), 0,
		"the client submits no world facts or grants of its own")
	assert_eq(_director.local_pays, 0, "the client does not pay itself")
	assert_false(bool(_director.progression_store.call("has", str(spec.get("defeat_flag", "")))),
		"and sets no local defeat flag; it arrives as the host's world delta")


func test_client_warden_victory_is_sent_to_the_host_with_only_the_trainer_id() -> void:
	assert_false(_warden().is_empty(), "the Warden row is installed")
	_assert_client_routes_to_host(_warden(), WARDEN)


func test_client_nerissa_victory_is_sent_to_the_host_with_only_the_trainer_id() -> void:
	_as_water()
	_assert_client_routes_to_host(_director.trainer_specs[NERISSA], NERISSA)


func test_a_client_tournament_round_keeps_its_existing_path() -> void:
	_as_client()
	var spec: Dictionary = TRAINERS.trainer("tournament_quarter_mira")
	assert_false(spec.is_empty(), "a tournament round trainer is installed")
	_director.call("_record_trainer_defeat", spec)
	assert_eq(_director.sent.size(), 0, "a tournament round is not re-routed as a trainer victory")


# --- the host's side ------------------------------------------------------------

func test_host_journals_the_warden_for_the_sender_only() -> void:
	# A forged payload: claims to be the host's character, names both peers and
	# another realm. None of it may be read.
	var verdict: Dictionary = _director.call("_host_commit_encounter",
		{"kind": "trainer_victory", "trainer_id": WARDEN, "character_id": HOST_CHARACTER,
		 "peers": [HOST, CLIENT], "peer": HOST, "realm": "cloudreach",
		 "source": "trainer:%s:coins" % WARDEN}, CLIENT)
	assert_true(bool(verdict.get("ok", false)), "the host accepted the client's victory: %s" % str(verdict))
	assert_eq(_characters_for("trainer:%s:" % WARDEN), [CLIENT_CHARACTER],
		"the journal names the SENDER's registry character, not the host or a payload id")
	assert_eq(_sources_for("trainer:%s:" % WARDEN), _expected_warden_sources(),
		"one row per authored item component (coins and every item)")
	assert_true(_flag("defeated_warden"), "the Warden's defeat became a world fact")
	for extra: String in TRAINERS.reward_flags(_warden()):
		if PROGRESSION_STATE.scope_of(extra) == "world":
			assert_true(_flag(extra), "world reward flag '%s' committed once" % extra)
	assert_eq(_director.paid_notices.size(), 1, "exactly one participant was told")
	if _director.paid_notices.size() == 1:
		assert_eq(int(_director.paid_notices[0].peer), CLIENT, "and it was the sender")
		assert_eq(int(_director.paid_notices[0].payload.get("xp", 0)),
			TRAINERS.reward_xp_bonus(_warden()), "carrying the authored XP bonus")
	_accept_all_for(CLIENT)
	var participants := _accepted_warden_characters()
	assert_eq(participants, [CLIENT_CHARACTER], "the client's acks accepted its own rows")
	assert_true(CLIMAX.may_receive(CLIENT_CHARACTER, participants, false),
		"the fighter receives the legendary offer")
	assert_false(CLIMAX.may_receive(HOST_CHARACTER, participants, false),
		"the host, who never fought, receives nothing")


func test_host_journals_nerissa_through_the_water_director_spec() -> void:
	_as_water()
	_game.session.rows.call("set_realm", CLIENT, "water")
	var verdict: Dictionary = _director.call("_host_commit_encounter",
		{"kind": "trainer_victory", "trainer_id": NERISSA}, CLIENT)
	assert_true(bool(verdict.get("ok", false)), "the host accepted Nerissa's defeat: %s" % str(verdict))
	assert_eq(_characters_for("trainer:%s:" % NERISSA), [CLIENT_CHARACTER],
		"Nerissa's rows name only the sender's character")
	assert_eq(_sources_for("trainer:%s:" % NERISSA),
		["trainer:%s:coins" % NERISSA, "trainer:%s:item:revive" % NERISSA],
		"the captain tier's coins and revives")
	var coins := 0
	var revives := 0
	for row: Dictionary in _rows_for("trainer:%s:" % NERISSA):
		for stack: Dictionary in (row.get("stacks", []) as Array):
			if str(stack.get("id", "")) == "coin":
				coins += int(stack.get("n", 0))
			if str(stack.get("id", "")) == "revive":
				revives += int(stack.get("n", 0))
	assert_eq(coins, 150, "the authored 150 coin, undivided")
	assert_eq(revives, 2, "the authored 2 revives, undivided")
	assert_true(_flag(NERISSA_FLAG), "the Veilfall defeat flag, not the generic one, is the world fact")
	assert_false(_flag("defeated_" + NERISSA), "the translated default flag is not what Veilfall reads")
	assert_eq(_director.paid_notices.size(), 1, "only the sender was told")


func test_a_replayed_victory_pays_nobody_twice() -> void:
	var first: Dictionary = _director.call("_host_commit_encounter",
		{"kind": "trainer_victory", "trainer_id": WARDEN}, CLIENT)
	assert_true(bool(first.get("ok", false)), "the first claim is accepted")
	var rows_before := _deliveries().duplicate(true)
	var notices_before := _director.paid_notices.size()
	var second: Dictionary = _director.call("_host_commit_encounter",
		{"kind": "trainer_victory", "trainer_id": WARDEN}, CLIENT)
	assert_false(str(second.get("code", "")) == "journal_failed", "a replay is not a failure")
	assert_eq(_deliveries(), rows_before, "a replay journals no new rows")
	assert_eq(_director.paid_notices.size(), notices_before, "and tells nobody a second time")


func _assert_refused_without_writes(intent: Dictionary, peer: int, why: String) -> void:
	var verdict: Dictionary = _director.call("_host_commit_encounter", intent, peer)
	assert_false(bool(verdict.get("ok", true)), "%s is refused" % why)
	assert_eq(str(verdict.get("kind", "")), "trainer_victory", "%s: the refusal names its intent" % why)
	assert_false(str(verdict.get("reason", "")).is_empty(), "%s: with a reason a player can read" % why)
	assert_true(_deliveries().is_empty(), "%s: no row was journaled" % why)
	assert_eq(_director.ledger_submissions.size(), 0, "%s: nothing was submitted to the ledger" % why)
	assert_eq(_director.paid_notices.size(), 0, "%s: nobody was told they were paid" % why)
	assert_false(_flag("defeated_warden"), "%s: the world fact was not written" % why)


func test_refusals_write_nothing() -> void:
	_assert_refused_without_writes({"kind": "trainer_victory", "trainer_id": WARDEN,
		"character_id": CLIENT_CHARACTER}, 777, "an unregistered sender")
	_admit(555, "", "meadows")
	_assert_refused_without_writes({"kind": "trainer_victory", "trainer_id": WARDEN,
		"character_id": CLIENT_CHARACTER}, 555, "a sender with no character")
	_game.session.rows.call("set_realm", CLIENT, "cloudreach")
	_assert_refused_without_writes({"kind": "trainer_victory", "trainer_id": WARDEN,
		"realm": "meadows"}, CLIENT, "a sender standing in another realm")
	_game.session.rows.call("set_realm", CLIENT, "meadows")
	_assert_refused_without_writes({"kind": "trainer_victory", "trainer_id": "no_such_trainer"},
		CLIENT, "an unknown trainer")
	_assert_refused_without_writes({"kind": "trainer_victory", "trainer_id": ""},
		CLIENT, "a missing trainer id")
	_assert_refused_without_writes({"kind": "trainer_victory",
		"trainer_id": "tournament_quarter_mira"}, CLIENT, "a tournament round")
	_assert_refused_without_writes({"kind": "trainer_victory", "trainer_id": WARDEN},
		HOST, "the host's own id")
	_assert_refused_without_writes({"kind": "trainer_victory", "trainer_id": WARDEN},
		0, "a zero sender")


func test_a_failed_journal_commits_no_world_fact() -> void:
	(_game.save_system as Saver).fail_world = true
	var verdict: Dictionary = _director.call("_host_commit_encounter",
		{"kind": "trainer_victory", "trainer_id": WARDEN}, CLIENT)
	assert_false(bool(verdict.get("ok", true)), "a journal that cannot save refuses the victory")
	assert_eq(str(verdict.get("code", "")), "journal_failed", "and says why")
	assert_true(_deliveries().is_empty(), "no row survived the rollback")
	assert_false(_flag("defeated_warden"),
		"the Warden is NOT marked beaten while nobody could be paid for it")
	assert_eq(_director.paid_notices.size(), 0, "nobody was told they were paid")
	assert_false(str(verdict.get("reason", "")).contains("Nothing was delivered"),
		"the refusal never claims nothing landed: components journal one at a time")
	assert_true(str(verdict.get("reason", "")).contains("still unbeaten"),
		"it tells the player the trainer can be fought again: %s" % str(verdict.get("reason", "")))


func test_a_chapter_host_never_resolves_another_chapters_trainer() -> void:
	# A Water host fights only its own translated table; a guest standing in
	# Water must not be able to claim the Meadows Warden through the shared
	# trainers.json fallback.
	_as_water()
	_game.session.rows.call("set_realm", CLIENT, "water")
	_assert_refused_without_writes({"kind": "trainer_victory", "trainer_id": WARDEN}, CLIENT,
		"the Warden claimed in a Water host")
	assert_true(_rows_for("trainer:%s:" % WARDEN).is_empty(), "no Warden row exists")
	# And a Water client never routes a trainer its own director cannot fight.
	_as_client()
	assert_false(bool(_director.call("_routes_trainer_victory_to_host", _warden(), "water")),
		"a Water client does not route the Warden to the host")


# --- regression: the host-run fight is unchanged -------------------------------

func test_a_host_run_fight_still_pays_every_participant() -> void:
	_director.set("_encounter_host", RefCounted.new())
	_director.set("_trainer_battle_participants", {HOST: true, CLIENT: true})
	_director.call("_record_trainer_defeat", _warden())
	assert_eq(_characters_for("trainer:%s:" % WARDEN), [CLIENT_CHARACTER, HOST_CHARACTER],
		"a host-run Warden still journals both participants")
	assert_true(_flag("defeated_warden"), "and the defeat is a world fact")
	var told: Array = []
	for notice: Dictionary in _director.paid_notices:
		told.append(int(notice.peer))
	told.sort()
	assert_eq(told, [HOST, CLIENT], "and both participants are told")
	assert_eq(_director.local_pays, 0, "and nobody took the solo payout as well")
