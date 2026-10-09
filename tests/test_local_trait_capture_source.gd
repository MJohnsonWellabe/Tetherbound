extends "res://tests/test_case.gd"

## Production retention/retry control flow with an explicit refusing journal
## witness. This unit claims no disk write, receipt acceptance or played catch.
const DIRECTOR := preload("res://scripts/combat/encounter_director.gd")
const HOST := preload("res://scripts/combat/accepted_action_host.gd")

class GameWitness extends Node:
	var world := preload("res://autoload/world_state.gd").new()

class JournalWitness extends Node:
	var fixture: Node
	var refused := true
	var attempts: Array[Dictionary] = []
	func _game() -> Node: return fixture
	func _altar_current_epoch() -> String: return "original-solo-epoch"
	func is_active() -> bool: return false
	func is_host() -> bool: return true
	func foundation_research_source(director: Node, encounter: String, peer: int, kind: String,
			source: String, species: String, move: String, night: Variant) -> Dictionary:
		var original: Dictionary = director.call("retained_research_source", source)
		attempts.append({"encounter": encounter, "peer": peer, "kind": kind, "source": source,
			"species": species, "move": move, "night": night, "original": original})
		return {"ok": not refused, "durable": not refused}

class SoloDirector extends DIRECTOR:
	var owned_id := ""
	var owns := true
	func _is_host() -> bool: return false
	func _owns_canonical_wild(encounter: String) -> bool:
		return owns and not owned_id.is_empty() and encounter == owned_id
	func _encounter_realm() -> String: return "meadows"

func _fixture() -> Dictionary:
	var game := GameWitness.new()
	game.world.world_id = "solo-source-world"
	game.world.reward_delivery_namespace = "solo-source-namespace"
	var session := JournalWitness.new()
	session.fixture = game
	var director := SoloDirector.new()
	director.set("_session", session)
	var host := HOST.new()
	director.set("_encounter_host", host)
	var record: Dictionary = host.open(1, "meadows", "wild",
		{"species_id": "bramblebun", "hp": 23.0, "hp_max": 105.0},
		"owned-starter-uid", "actual-solo-character")
	director.owned_id = record.encounter_id
	return {"game": game, "session": session, "director": director, "host": host, "id": record.encounter_id}

func _close(f: Dictionary) -> void:
	f.director.free()
	f.session.free()
	f.game.free()

func test_inactive_solo_canonical_retention_waits_for_original_journal_then_retries_same_source() -> void:
	var f := _fixture()
	var card := {"uid": "actual-caught-uid", "species_id": "bramblebun"}
	var offer := {"source_key": "capture:actual-retained-offer", "offer_id": "actual-retained-offer"}
	assert_false(f.director._retain_research(f.id, 1, "catch", "bramblebun", "actual-claim", "",
		false, card, offer), "inactive solo cannot claim a skipped journal is durable")
	assert_eq(f.session.attempts.size(), 1)
	var original: Dictionary = f.session.attempts[0].original
	assert_false(original.is_empty())
	assert_eq(original.capture_card, card)
	assert_eq(original.capture_offer, offer)
	assert_eq(original.session_id, "original-solo-epoch")
	f.director._retry_research_sources()
	assert_eq(f.session.attempts.size(), 2)
	assert_eq(f.session.attempts[1].original, original, "failure retry preserves original accepted source")
	f.session.refused = false
	f.director._retry_research_sources()
	assert_eq(f.session.attempts.size(), 3)
	assert_eq(f.session.attempts[2].original, original)
	assert_true(f.director.retained_research_source(original.source_id).is_empty(), "durable ACK retires exact source")
	_close(f)

func test_retained_solo_source_does_not_retry_after_its_canonical_runtime_ownership_is_lost() -> void:
	var f := _fixture()
	assert_false(f.director._retain_research(f.id, 1, "catch", "bramblebun", "actual-claim"))
	var original: Dictionary = f.session.attempts[0].original
	f.director.owns = false
	f.director._retry_research_sources()
	assert_eq(f.session.attempts.size(), 1, "canonical ownership is rechecked per retained source")
	assert_eq(f.director.retained_research_source(original.source_id), original, "lost scope cannot erase an unacknowledged source")
	_close(f)
