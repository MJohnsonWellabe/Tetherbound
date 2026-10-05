extends "res://tests/test_case.gd"

## F01#6a, host side. A guest's original starter enters the host's admitted
## record only through the staged full-character transaction
## (`scripts/net/starter_choice_action.gd` via `foundation_actions.gd`), which
## validates the guest-claimed card instead of trusting it. Each case runs the
## real `foundation_actions.stage()` against a real admitted record with the
## real schema check, then the owner-side `foundation_delivery.valid()`
## re-run that every owner applies to a saved row.

const ACTIONS := preload("res://scripts/net/foundation_actions.gd")
const STARTER := preload("res://scripts/net/starter_choice_action.gd")
const DELIVERY := preload("res://scripts/net/foundation_delivery.gd")
const RECORD := preload("res://scripts/net/character_record_rules.gd")
const PLAYER := preload("res://autoload/player_state.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const TEACHING := preload("res://scripts/creatures/teaching.gd")
const CODEC := preload("res://scripts/save/water_capture_codec.gd")
const OPENING := preload("res://scripts/story/opening_beats.gd")
const ESSENCE := preload("res://scripts/creatures/essence.gd")

const CHARACTER := "starter-guest"
const NAMESPACE := "starter-world"
const WORLD := "starter-slot"
const EPOCH := "starter-session"


func _player(with_creature: bool = false) -> RefCounted:
	var player := PLAYER.new()
	player.configure(preload("res://autoload/item_db.gd").new())
	player.character_id = CHARACTER
	if with_creature:
		player.party.add(SPECIES.spawn("bramblebun"))
	return player


func _admitted(player: RefCounted) -> Dictionary:
	var saved: Dictionary = player.save_data()
	saved.redesign_character = TEACHING.character_loadout_mirror(saved.party, saved.redesign_character)
	return RECORD.portable_projection(saved)


func _starter_level() -> int:
	return int(PROGRESSION.config().get("level", {}).get("starter_level", 3))


## Built exactly as `encounter_director.adopt_starter()` builds the real one.
func _card(species: String = "terrapup", level: int = -1) -> Dictionary:
	var creature: RefCounted = SPECIES.spawn(species)
	creature.set_level(_starter_level() if level < 0 else level, PROGRESSION.config())
	creature.nickname = "Bud"
	return CODEC.encode(creature)


func _context(revision: int = 0) -> Dictionary:
	var context := STARTER.host_context(CHARACTER, revision,
		OPENING.config().get("starters", {}).get("species", []), _starter_level())
	context.foundation_runtime_authorized = true
	return context


func _stage(current: Dictionary, card: Dictionary, revision: int = 0) -> Dictionary:
	return ACTIONS.stage(current, revision, "starter_choice", STARTER.intent(card), _context(revision), RECORD.errors)


func test_a_fresh_starter_is_admitted_with_its_receipt() -> void:
	var before := _admitted(_player())
	var card := _card()
	assert_false(card.is_empty(), "the real starter card encodes")
	var staged := _stage(before, card)
	assert_true(staged.get("ok") == true, "a fresh starter of a starter species is admitted (%s)" % str(staged))
	if staged.get("ok") != true:
		return
	var uid := str(card.uid)
	assert_eq(staged.receipt, STARTER.receipt(CHARACTER, uid))
	assert_eq((staged.state.party as Array).size(), 1)
	assert_eq(staged.state.party[0].uid, uid, "the admitted party holds exactly the claimed starter")
	assert_true(staged.state.redesign_character.transaction_receipts.has(staged.receipt),
		"the admitted record carries the starter_choice receipt")
	assert_true(staged.state.redesign_character.creatures.has(uid), "the loadout mirror is derived, not imported")
	assert_true(RECORD.errors(staged.state, CHARACTER).is_empty(), "the after-state is a valid admitted record")


func test_the_owner_side_rerun_accepts_the_staged_row() -> void:
	var before := _admitted(_player())
	var staged := _stage(before, _card())
	assert_true(staged.get("ok") == true, str(staged))
	if staged.get("ok") != true:
		return
	staged.character_revision = 1
	var row := DELIVERY.make_record(WORLD, NAMESPACE, EPOCH, staged, null, RECORD.errors)
	assert_false(row.is_empty(), "the host journals the staged starter as an ordinary character-action row")
	assert_true(DELIVERY.valid(row, RECORD.errors, CHARACTER, NAMESPACE, WORLD),
		"every owner's re-run of the same callback reproduces the saved row")
	var plan := DELIVERY.owner_plan(before, row, RECORD.errors)
	assert_true(plan.get("ok") == true and plan.get("duplicate") == false,
		"the guest's own pre-commit record matches the row's baseline: no owner_action_baseline_conflict")
	var after_plan := DELIVERY.owner_plan(row.after, row, RECORD.errors)
	assert_true(after_plan.get("ok") == true and after_plan.get("duplicate") == true,
		"an owner already holding the after-state is an idempotent duplicate")


func test_a_non_starter_species_is_refused() -> void:
	var staged := _stage(_admitted(_player()), _card("bramblebun"))
	assert_eq(staged.get("code"), "not_a_starter_species")


func test_a_second_original_starter_is_refused() -> void:
	var player := _player()
	player.redesign_character.transaction_receipts.append(STARTER.receipt(CHARACTER, "an-earlier-starter"))
	var staged := _stage(_admitted(player), _card())
	assert_eq(staged.get("code"), "original_starter_already_chosen",
		"a character that already chose an original starter can never be granted another or a conflicting one")


func test_a_non_empty_admitted_party_is_refused() -> void:
	var staged := _stage(_admitted(_player(true)), _card())
	assert_eq(staged.get("code"), "starter_requires_empty_party")


func test_a_tampered_card_is_refused() -> void:
	var before := _admitted(_player())
	assert_eq(_stage(before, _card("terrapup", _starter_level() + 7)).get("code"), "starter_not_fresh",
		"a starter above the configured starter level is not the opening's starter")
	var wounded := _card()
	wounded.hp = 1.0
	assert_true(_stage(before, wounded).get("ok") != true, "a wounded or reinterpreted card is not a fresh starter")
	var no_uid := _card()
	no_uid.erase("uid")
	assert_eq(_stage(before, no_uid).get("code"), "invalid_starter_card")
	var extra := _card()
	extra["smuggled"] = true
	assert_true(_stage(before, extra).get("ok") != true, "an extra field cannot ride into the admitted record")


func test_host_context_is_required() -> void:
	var before := _admitted(_player())
	var context := _context()
	context.source_key = "starter_choice:someone-else"
	var staged := ACTIONS.stage(before, 0, "starter_choice", STARTER.intent(_card()), context, RECORD.errors)
	assert_true(staged.get("ok") != true, "the host's own source key binds the decision to this character")
	var unauthorized := _context()
	unauthorized.erase("foundation_runtime_authorized")
	assert_true(ACTIONS.stage(before, 0, "starter_choice", STARTER.intent(_card()), unauthorized, RECORD.errors).get("ok") != true)


## The exact baseline condition the live smoke tripped over: the guest commits
## its starter locally first, so when the host's row arrives the guest's own
## projection must already equal the row's after-state, or `owner_plan` reports
## `owner_action_baseline_conflict` and the opening never finishes.
func test_the_guests_own_post_commit_record_equals_the_staged_after_state() -> void:
	var player := _player()
	var before := _admitted(player)
	var creature: RefCounted = SPECIES.spawn("terrapup")
	creature.set_level(_starter_level(), PROGRESSION.config())
	creature.nickname = "Bud"
	var card := CODEC.encode(creature)
	player.party.add(creature)
	player.redesign_character.transaction_receipts.append(STARTER.receipt(CHARACTER, str(creature.get("uid"))))
	var guest_after_local_commit := RECORD.portable_projection(player.save_data())
	var staged := _stage(before, card)
	assert_true(staged.get("ok") == true, str(staged))
	if staged.get("ok") != true:
		return
	assert_true(ESSENCE.owner_matches_after(guest_after_local_commit, staged.state),
		"the host's staged after-state is exactly the guest's own committed record")
	staged.character_revision = 1
	var row := DELIVERY.make_record(WORLD, NAMESPACE, EPOCH, staged, null, RECORD.errors)
	var plan := DELIVERY.owner_plan(guest_after_local_commit, row, RECORD.errors)
	assert_true(plan.get("ok") == true and plan.get("duplicate") == true,
		"the committed guest takes owner_plan's duplicate path: save and ACK, no rebuilt instance (%s)" % str(plan))
	assert_true(player.party.call("at", 0) == creature,
		"the party still holds the very instance the follower pilots")
