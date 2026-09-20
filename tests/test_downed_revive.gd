extends "res://tests/test_case.gd"

const PROMPT_ARBITER := preload("res://scripts/world/prompt_arbiter.gd")


class CompetingProvider extends RefCounted:
	var activations := 0

	func interaction_offer(_from: Vector3) -> Dictionary:
		return PROMPT_ARBITER.offer("Use another world target", 0.0, 100, true)

	func interaction_activate() -> void:
		activations += 1


class DownedProbe extends "res://scripts/player/downed_state.gd":
	func _game() -> Node:
		return null

	func _sync_channel_provider() -> void:
		pass

	func _unregister_channel_provider() -> void:
		pass

	func _revive_refusal(_peer_id: int, _starting: bool = false) -> String:
		return ""

	func _registry_peer_ids() -> Array:
		return [1, 2]

	func _body_for(_peer_id: int) -> Node3D:
		return null


## The active channel is itself an arbiter provider. Its offer must beat a
## priority-100 competing world action, and activating the selected provider
## must cancel without calling the competitor. The two-peer smoke drives the
## corresponding selection through a real fresh input edge.
func test_active_channel_owns_cancel_over_competing_provider() -> void:
	var downed := DownedProbe.new()
	downed.set("_downed_peers", {2: "Friend"})
	downed.set("_progress_peer", 2)
	downed.set("_progress_s", 0.5)
	var competitor := CompetingProvider.new()
	var providers: Array = [competitor, downed]
	var offers: Array = [
		competitor.interaction_offer(Vector3.ZERO),
		downed.call("interaction_offer", Vector3.ZERO),
	]
	var winner := PROMPT_ARBITER.choose_index(offers)
	assert_eq(winner, 1, "the active revive channel owns cancel over a priority-100 offer")
	providers[winner].call("interaction_activate")

	assert_eq(int(downed.call("status").get("progress_peer", -1)), 0,
		"the fresh second tap cancels the active channel")
	assert_eq(competitor.activations, 0,
		"the cancel edge must not activate the competing world provider")
	downed.free()


## A released button is irrelevant once the tap has established state. The
## channel advances from process time alone, retaining the historical status
## aliases for probes that have not migrated yet.
func test_released_button_continues_progress_and_status_aliases_match() -> void:
	var downed := DownedProbe.new()
	downed.set("_downed_peers", {2: "Friend"})
	downed.set("_progress_peer", 2)
	downed.set("_progress_s", 0.25)
	downed.call("_process", 0.5)
	var status: Dictionary = downed.call("status")
	assert_almost_eq(float(status.get("progress_s", 0.0)), 0.75, 0.001)
	assert_eq(status.get("hold_s"), status.get("progress_s"),
		"historical hold_s now aliases proximity progress")
	assert_eq(status.get("hold_peer"), status.get("progress_peer"),
		"historical hold_peer now aliases the active progress target")
	assert_eq(status.get("revive_hold_s"), status.get("revive_progress_s"),
		"historical config/status duration remains compatible")
	downed.free()
