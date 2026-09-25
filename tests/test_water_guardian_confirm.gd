extends "res://tests/test_case.gd"

## ACCEPTANCE F14: "Each actual freeing-fight participant's capacity/space
## accept/refuse decision grants at most their own once-only creature." With a
## free holder a presented Guardian claim is never auto-accepted: the Creatures
## tab asks Accept (complete_pending_capture), Decline (decline_pending, the
## host-journaled refusal) or puts it off with menu_cancel (defer_pending: still
## pending, not declined). A put-off offer is answered again only through Edda
## or the Deep Watcher's chamber (water_veilfall.gd request_guardian_offer ->
## resume_deferred), never by merely opening the Creatures tab.
## Ordinary (non-Guardian) Water captures with room still complete at once, and
## a full belt is still left to the five-slot release choice.
##
## Fixtures: fake Game/realm/bridge nodes around the REAL claim service and
## reward/transaction code. The unit runner has no SceneTree, so the real tab's
## buttons, focus and menu_cancel are driven by smoke_water_guardian_ceremony.

const REWARD := preload("res://scripts/world/water_guardian_reward.gd")
const WORLD := preload("res://autoload/world_state.gd")
const LEDGER := preload("res://scripts/net/world_ledger.gd")
const SAVE := preload("res://scripts/save/world_save.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const CODEC := preload("res://scripts/save/water_capture_codec.gd")
const PARTY := preload("res://autoload/party.gd")
const FLAGS := preload("res://autoload/progression_state.gd")
const INVENTORY := preload("res://autoload/inventory.gd")
const ITEM_DB := preload("res://autoload/item_db.gd")

class Saver extends RefCounted:
	var character_writes := 0
	var store: RefCounted = SAVE.new("user://guardian_confirm_%d/" % Time.get_ticks_usec())
	func save_world(game: Object, id: String) -> bool:
		var snapshot: Dictionary = game.world.save_data()
		snapshot.progression = game.world.flags.save_data()
		return store.write(id, SAVE.partition(snapshot))
	func save_character(_game: Object, _id: String) -> bool:
		character_writes += 1
		return true

class LocalFixture extends RefCounted:
	var character_id := "host-char"
	var party := PARTY.new()
	var flags := FLAGS.new()

class FakeSession extends RefCounted:
	func local_peer_id() -> int: return 1
	func peers_in_realm(_realm: String) -> Array: return [1]

class FakeGame extends Node:
	var world: RefCounted = WORLD.new()
	var local: RefCounted = LocalFixture.new()
	var save_system: RefCounted = Saver.new()
	var pending_catch: RefCounted = null
	var current_realm := "water"
	var day := 3
	var session: RefCounted = FakeSession.new()
	var inventory: RefCounted = INVENTORY.new(ITEM_DB.new())
	var messages: Array = []
	var ledger: Node = null
	var party: RefCounted:
		get: return local.party
	func is_host() -> bool: return true
	func push_world_message(text: String) -> void: messages.append(text)

class FakeBridge extends Node:
	var ledger: RefCounted
	func _water_actor_context(peer: int, _intent: Dictionary) -> Dictionary:
		return {"character_id": "host-char"} if peer == 1 else {}
	func publish_journaled_delta(_delta: Dictionary) -> void:
		pass

class FakeCombat extends Node:
	func is_fighting() -> bool: return false

class FakeRealm extends Node:
	var simulation_only := false
	var built := true
	func shell_build_complete() -> bool: return built

## The shell the Creatures tab talks to (state(), say(), input hold).
class FakeMenu extends Node:
	var game: Node
	var said: Array = []
	var held := false
	func say(text: String) -> void: said.append(text)
	func hold_input(on: bool) -> void: held = on
	func override_footer(_text: String) -> void: pass
	func is_open() -> bool: return true
	func close() -> void: pass

## The real tab script; only its node-path lookups are pointed at fixtures.
class Tab extends "res://scripts/ui/tab_creatures.gd":
	var fake_claims: Node = null
	func _water_capture_service(creature: RefCounted) -> Node:
		return fake_claims if fake_claims != null and fake_claims.owns_pending(creature) else null
	func _water_claims() -> Node: return fake_claims
	func _water_veilfall() -> Node: return null

class Claims extends "res://scripts/net/water_capture_claims.gd":
	var fake_game: Node
	var fake_bridge: Node
	var fake_realm: Node
	func _game() -> Node: return fake_game
	func _bridge() -> Node: return fake_bridge
	func _realm() -> Node: return fake_realm

var _nodes: Array = []

func after_each() -> void:
	for node: Node in _nodes:
		if is_instance_valid(node):
			if node.is_inside_tree():
				node.get_parent().remove_child(node)
			node.free()
	_nodes.clear()
	Input.action_release("menu_cancel")

func _keep(node: Node) -> Node:
	_nodes.append(node)
	return node

## A solo freed-Guardian world whose host character has `members` companions.
func _setup(members: int) -> Claims:
	var game := _keep(FakeGame.new()) as FakeGame
	game.world.world_id = "guardian-confirm-world"
	game.world.flags.set_flag("water_captain_nerissa_defeated")
	game.world.flags.set_flag("water_tether_disabled")
	game.world.flags.set_flag("water_guardian_freed")
	for i in members:
		game.local.party.add(SPECIES.spawn("water_mosshell"))
	var bridge := _keep(FakeBridge.new()) as FakeBridge
	bridge.ledger = LEDGER.new(game.world)
	var realm := _keep(FakeRealm.new()) as FakeRealm
	var combat := FakeCombat.new()
	combat.name = "CombatManager"
	realm.add_child(combat)
	var claims := _keep(Claims.new()) as Claims
	claims.fake_game = game
	claims.fake_bridge = bridge
	claims.fake_realm = realm
	return claims

## Mint this character's own Guardian claim and let the service present it.
func _offer(claims: Claims) -> String:
	var game: FakeGame = claims.fake_game
	var begun := REWARD.begin(game, claims.fake_bridge.ledger, "host-char", SPECIES.spawn("water_abyssal_guardian"))
	assert_true(begun.ok, "fixture: the solo host character's own offer is minted")
	claims.receive_claim(game.world.water_capture_claims[begun.id])
	claims._offer_pending()
	return str(begun.id)

func _receipt(game: FakeGame, id: String) -> bool:
	return game.local.flags.has("water_capture_receipt:" + id)

func test_guardian_with_room_waits_for_accept_and_accept_completes_exactly_once() -> void:
	var claims := _setup(4)
	var game: FakeGame = claims.fake_game
	var id := _offer(claims)
	var pending: RefCounted = game.pending_catch
	assert_true(pending != null and str(pending.species_id) == "water_abyssal_guardian", "the offer is presented")
	assert_true(claims.is_guardian_offer(pending), "the Creatures tab is told this is a Guardian offer to confirm")
	assert_eq(game.local.party.size(), 4, "a free holder no longer auto-accepts the Guardian")
	assert_true(game.world.water_capture_claims.has(id) and not _receipt(game, id), "nothing is settled before the answer")
	assert_eq(game.save_system.character_writes, 0)
	claims._offer_pending()
	claims._process(2.0)
	assert_eq(game.local.party.size(), 4, "later polls never answer it either")
	assert_eq(game.pending_catch, pending, "the same offer stays on screen")
	# Accept (the tab's Accept button calls exactly this).
	assert_true(claims.complete_pending_capture(-1).ok)
	assert_eq(game.local.party.size(), 5, "Accept adds the Guardian")
	assert_eq(game.local.party.at(4), pending)
	assert_true(game.pending_catch == null and _receipt(game, id), "receipt flag set")
	assert_eq(game.save_system.character_writes, 1, "the receipt is saved once")
	assert_false(game.world.water_capture_claims.has(id), "the host settles this character's own claim")
	assert_false(claims.complete_pending_capture(-1).ok, "a second Accept has nothing to complete")
	claims.receive_claim({"id": id, "source": "guardian", "world_id": game.world.world_id,
		"world_instance": REWARD.world_instance(game.world), "character_id": "host-char",
		"creature": CODEC.encode(SPECIES.spawn("water_abyssal_guardian"))})
	claims._offer_pending()
	assert_eq(game.pending_catch, null, "a stale resend of the answered claim is not re-presented")
	assert_eq(game.local.party.size(), 5, "exactly once")
	assert_eq(game.save_system.character_writes, 1)

func test_decline_refuses_through_the_host_and_grants_nothing() -> void:
	var claims := _setup(4)
	var game: FakeGame = claims.fake_game
	var id := _offer(claims)
	assert_true(claims.decline_pending().ok, "Decline is the existing refuse path")
	assert_eq(game.local.party.size(), 4, "Decline grants nothing")
	assert_true(game.pending_catch == null and not _receipt(game, id))
	assert_eq(game.save_system.character_writes, 0)
	assert_true(claims.is_declined(id) and claims.decline_settled(id), "refusal sent and host-confirmed")
	assert_false(game.world.water_capture_claims.has(id), "the host journaled the refusal")
	assert_true(game.world.flags.has(REWARD.offered_flag("host-char")))
	assert_eq(REWARD.begin(game, claims.fake_bridge.ledger, "host-char", SPECIES.spawn("water_abyssal_guardian")).code,
		"already_resolved", "no second offer to this character")
	assert_false(claims.is_guardian_offer(game.pending_catch))

func test_cancel_puts_the_offer_off_without_declining_it() -> void:
	var claims := _setup(4)
	var game: FakeGame = claims.fake_game
	var id := _offer(claims)
	assert_true(claims.defer_pending().ok, "B on the confirm puts the offer off")
	assert_eq(game.pending_catch, null, "so Game does not force the menu straight back")
	assert_eq(game.local.party.size(), 4, "nothing granted")
	assert_false(claims.is_declined(id), "nothing refused")
	assert_true(game.world.water_capture_claims.has(id), "the host still holds the offer")
	assert_eq(claims.pending_guardian_id(), id, "still this character's pending offer")
	assert_true(claims.has_deferred())
	claims._offer_pending()
	assert_eq(game.pending_catch, null, "the poll does not re-present a put-off offer")
	claims.receive_claim(game.world.water_capture_claims[id])
	claims._offer_pending()
	assert_eq(game.pending_catch, null, "nor does the host's resend")
	assert_false(claims.defer_pending().ok, "nothing on screen to put off")
	# The player asks to answer it (Edda / the chamber): the same question returns.
	assert_true(claims.resume_deferred(), "asking to answer it re-presents the offer")
	assert_true(claims.is_guardian_offer(game.pending_catch))
	assert_eq(game.local.party.size(), 4, "re-presenting still answers nothing")
	assert_false(claims.resume_deferred(), "nothing left deferred")
	assert_true(claims.complete_pending_capture(-1).ok)
	assert_eq(game.local.party.size(), 5)
	assert_true(_receipt(game, id) and not game.world.water_capture_claims.has(id))

func test_a_put_off_offer_can_still_be_declined_from_the_chamber() -> void:
	var claims := _setup(4)
	var game: FakeGame = claims.fake_game
	var id := _offer(claims)
	claims.defer_pending()
	assert_true(claims.decline_pending().ok)
	assert_false(claims.has_deferred())
	assert_false(claims.resume_deferred(), "a declined offer never comes back")
	assert_eq(game.pending_catch, null)
	assert_eq(game.local.party.size(), 4)
	assert_false(game.world.water_capture_claims.has(id))

func test_non_guardian_water_capture_with_room_still_completes_at_once() -> void:
	var claims := _setup(4)
	var game: FakeGame = claims.fake_game
	var id := "wild-capture-claim"
	var claim := {"id": id, "source": "wild", "world_id": game.world.world_id,
		"character_id": "host-char", "creature": CODEC.encode(SPECIES.spawn("water_mosshell"))}
	game.world.water_capture_claims[id] = claim
	claims.receive_claim(claim)
	claims._offer_pending()
	assert_eq(game.local.party.size(), 5, "an ordinary capture joins a free holder without a question")
	assert_true(game.pending_catch == null and _receipt(game, id))
	assert_false(game.world.water_capture_claims.has(id), "and is acknowledged to the host")

func test_non_guardian_capture_cannot_be_put_off() -> void:
	var claims := _setup(5)
	var game: FakeGame = claims.fake_game
	var id := "wild-full-belt-claim"
	var claim := {"id": id, "source": "wild", "world_id": game.world.world_id,
		"character_id": "host-char", "creature": CODEC.encode(SPECIES.spawn("water_mosshell"))}
	game.world.water_capture_claims[id] = claim
	claims.receive_claim(claim)
	claims._offer_pending()
	assert_true(game.pending_catch != null and not claims.is_guardian_offer(game.pending_catch))
	assert_false(claims.defer_pending().ok, "only a Guardian offer is a question that can wait")
	assert_true(game.pending_catch != null)

func test_full_party_guardian_is_left_to_the_release_choice() -> void:
	var claims := _setup(5)
	var game: FakeGame = claims.fake_game
	var id := _offer(claims)
	assert_true(game.pending_catch != null and claims.owns_pending(game.pending_catch), "presented for the release choice")
	assert_eq(game.local.party.size(), 5)
	assert_true(game.world.water_capture_claims.has(id) and not _receipt(game, id), "never completed without a choice")
	assert_false(claims.complete_pending_capture(-1).ok, "a full belt needs a release index")
	# Releasing the Guardian's own extended row (index 5) keeps the five.
	assert_true(claims.complete_pending_capture(5).ok)
	assert_eq(game.local.party.size(), 5)
	for member: RefCounted in game.local.party.members():
		assert_ne(str(member.species_id), "water_abyssal_guardian")

## Review M1/m1: resume_deferred only clears the put-off state once the offer
## is actually on screen; while it cannot be shown it stays put off.
func test_resume_keeps_the_offer_put_off_until_it_is_really_presented() -> void:
	var claims := _setup(4)
	var game: FakeGame = claims.fake_game
	var id := _offer(claims)
	assert_true(claims.defer_pending().ok)
	game.current_realm = "meadows"
	assert_false(claims.resume_deferred(), "outside Water nothing can be presented")
	assert_true(claims.has_deferred(), "so the offer is still put off, not lost to the ordinary queue")
	game.current_realm = "water"
	claims.fake_realm.built = false
	assert_false(claims.resume_deferred(), "nor before the shell is built")
	assert_true(claims.has_deferred())
	claims._process(2.0)
	assert_eq(game.pending_catch, null, "the ordinary poll still does not present a put-off offer")
	claims.fake_realm.built = true
	claims._process(2.0)
	assert_eq(game.pending_catch, null, "not even once presentation is possible again")
	assert_true(claims.resume_deferred(), "only asking to answer it presents it")
	assert_false(claims.has_deferred())
	assert_true(claims.is_guardian_offer(game.pending_catch) and claims.pending_guardian_id() == id)
	assert_eq(game.local.party.size(), 4)

## Review m2: a put-off Guardian lives in its own slot, so the host's resend of
## it never overwrites (starves) another claim of the same character.
func test_a_put_off_guardian_does_not_starve_other_claims() -> void:
	var claims := _setup(3)
	var game: FakeGame = claims.fake_game
	var guardian_id := _offer(claims)
	assert_true(claims.defer_pending().ok)
	var wild_id := "wild-while-guardian-put-off"
	var wild := {"id": wild_id, "source": "wild", "world_id": game.world.world_id,
		"character_id": "host-char", "creature": CODEC.encode(SPECIES.spawn("water_mosshell"))}
	game.world.water_capture_claims[wild_id] = wild
	# The host's poll delivers both; the Guardian's resend arrives LAST.
	claims.receive_claim(wild)
	claims.receive_claim(game.world.water_capture_claims[guardian_id])
	claims._offer_pending()
	assert_true(_receipt(game, wild_id), "the ordinary capture is presented and completed")
	assert_eq(game.local.party.size(), 4, "it takes a free holder")
	assert_false(game.world.water_capture_claims.has(wild_id))
	assert_true(claims.has_deferred() and claims.pending_guardian_id() == guardian_id, "the Guardian is still put off")
	assert_eq(game.pending_catch, null, "and still not re-presented by the poll")
	assert_true(claims.resume_deferred())
	assert_true(claims.is_guardian_offer(game.pending_catch))

## Review M1 (tab): opening the Creatures tab with an offer put off leaves the
## ordinary tab usable -- no confirm, nothing presented, the offer still waits.
func test_opening_the_tab_does_not_re_present_a_put_off_offer() -> void:
	var claims := _setup(4)
	var game: FakeGame = claims.fake_game
	var tab := _tab(claims)
	_offer(claims)
	assert_true(claims.defer_pending().ok)
	for i in 5:
		tab._maybe_begin_release()
	assert_eq(str(tab.get("_release_stage")), "", "no confirm is put back up")
	assert_eq(game.pending_catch, null, "nothing is presented by the tab")
	assert_false(tab.get("menu").held, "the shell's input stays free")
	assert_true(claims.has_deferred(), "the offer still waits for a deliberate answer")

## Review M1 (veilfall): asking Edda / the chamber to answer re-presents the
## put-off offer from the claim service, without a new host intent.
func test_the_veilfall_answer_path_re_presents_a_put_off_offer() -> void:
	var claims := _setup(4)
	var game: FakeGame = claims.fake_game
	var ledger := _keep(Node.new()) as Node
	claims.name = "WaterCaptureClaims"
	ledger.add_child(claims)
	game.ledger = ledger
	var cave: Node = _keep(load("res://scripts/world/water_veilfall.gd").new()) as Node
	cave.set("_game", game)
	var id := _offer(claims)
	assert_true(claims.defer_pending().ok)
	cave.request_guardian_offer()
	assert_true(claims.is_guardian_offer(game.pending_catch) and claims.pending_guardian_id() == id,
		"Edda's request / the chamber prompt puts the same offer back on screen")
	assert_false(claims.has_deferred())
	assert_eq(game.local.party.size(), 4, "re-presenting answers nothing")
	ledger.remove_child(claims)

## Review m3: a creature carrying a durable Water claim that the claim service
## does not own is never added by the tab's "room opened" fallback (no receipt,
## no host settlement: a second grant). It is taken off the screen instead and
## the host's claim is left to the service.
func test_tab_fallback_refuses_a_claim_creature_the_service_does_not_own() -> void:
	var claims := _setup(4)
	var game: FakeGame = claims.fake_game
	var tab := _tab(claims)
	var stale: RefCounted = SPECIES.spawn("water_abyssal_guardian")
	stale.set_meta("water_capture_claim", "some-guardian-claim")
	game.pending_catch = stale
	tab._maybe_begin_release()
	assert_eq(game.local.party.size(), 4, "the fallback does not add a claim creature")
	assert_eq(game.pending_catch, null, "it is taken off the screen for the service to present again")
	assert_eq(str(tab.get("_release_stage")), "")
	# Full belt: never staged for a service-less release either.
	game.local.party.add(SPECIES.spawn("water_mosshell"))
	game.pending_catch = stale
	tab._maybe_begin_release()
	assert_eq(str(tab.get("_release_stage")), "", "no release choice for a claim the service does not own")
	assert_eq(game.pending_catch, null)
	assert_eq(game.local.party.size(), 5)
	# An ordinary pending catch (no claim) still takes a free holder, as before.
	game.local.party.remove_at(4)
	var plain: RefCounted = SPECIES.spawn("water_mosshell")
	game.pending_catch = plain
	tab._maybe_begin_release()
	assert_eq(game.local.party.size(), 5, "the fallback still serves ordinary pending catches")
	assert_eq(game.pending_catch, null)

## Review m3: the confirm's own no-service branches (Accept/Confirm-decline and
## "Decide later") clear a stale claim creature instead of leaving it for the
## fallback, and grant nothing.
func test_confirm_no_service_branches_clear_the_stale_claim_creature() -> void:
	var claims := _setup(4)
	var game: FakeGame = claims.fake_game
	var tab := _tab(claims)
	for answer: String in ["accept", "decline", "later"]:
		var stale: RefCounted = SPECIES.spawn("water_abyssal_guardian")
		stale.set_meta("water_capture_claim", "stale-" + answer)
		game.pending_catch = stale
		tab.set("_release_stage", "guardian_decline" if answer == "decline" else "guardian")
		match answer:
			"accept": tab._answer_guardian(true)
			"decline": tab._answer_guardian(false)
			"later": tab._put_off_guardian()
		assert_eq(game.pending_catch, null, "%s: the stale claim creature is cleared" % answer)
		assert_eq(str(tab.get("_release_stage")), "", "%s: the confirm ends" % answer)
		tab._maybe_begin_release()
		assert_eq(game.local.party.size(), 4, "%s: and nothing is granted afterwards" % answer)
	assert_true(game.messages.is_empty(), "no 'waits for your answer' message for an offer that is not there")

func _tab(claims: Claims) -> Tab:
	var menu := _keep(FakeMenu.new()) as FakeMenu
	menu.game = claims.fake_game
	var tab := _keep(Tab.new()) as Tab
	tab.menu = menu
	tab.fake_claims = claims
	return tab
