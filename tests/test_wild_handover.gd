extends "res://tests/test_case.gd"

## When the party takes a wild pal, the world has to let go of it.
##
## This file exists because a comment in `encounter_director.gd` described this
## behaviour for two milestones before anything implemented it. The respawned
## creature was documented as "a different individual from the one now in the
## party"; in fact `populate()` was the only thing that ever assigned
## `instance`, so the body and the party held one object between them.
##
## Two consequences, and the cheap one is what found it. Catching the same
## species twice came back `already_held` — the evidence session could not fill
## a party by catching at all. The expensive one had no symptom: the world went
## on driving a pal the player owned, and `revive_at_home()` calls
## `heal_fully()`, so a wild body respawning silently topped up a party member's
## health while every fight that body took damaged it.
##
## Both are aliasing, and aliasing is not something a play session finds
## reliably — it looks like the game being generous.

const WILD := preload("res://scripts/pals/wild_pal.gd")
const SPECIES := preload("res://scripts/pals/pal_species.gd")

const A_SPECIES := "wild_rabbit"


## A wild body with a live instance, built the way the director builds one, but
## without a player — `populate()` only stores that reference.
func _wild() -> Node3D:
	var body := CharacterBody3D.new()
	body.set_script(WILD)
	body.call("populate", A_SPECIES, null)
	return body


func test_the_handover_gives_the_body_a_different_object() -> void:
	var body := _wild()
	var taken: RefCounted = body.get("instance") as RefCounted
	assert_true(taken != null, "the wild body started with no instance")

	assert_true(bool(body.call("hand_instance_to_owner")), "the handover refused")

	var replacement: RefCounted = body.get("instance") as RefCounted
	assert_true(replacement != null, "the body was left with no instance")
	assert_false(replacement == taken,
		"the body kept the very object the party took")
	body.free()


func test_the_replacement_is_the_same_species() -> void:
	var body := _wild()
	body.call("hand_instance_to_owner")
	var replacement: RefCounted = body.get("instance") as RefCounted
	assert_eq(str(replacement.get("species_id")), A_SPECIES)
	body.free()


## The one that had no symptom. Healing the body must not reach the party.
func test_reviving_the_body_does_not_heal_the_pal_the_party_took() -> void:
	var body := _wild()
	var taken: RefCounted = body.get("instance") as RefCounted
	taken.take_damage(taken.max_hp * 0.9)
	var hurt: float = taken.hp
	assert_true(hurt < taken.max_hp, "the pal was not actually damaged")

	body.call("hand_instance_to_owner")
	# What `revive_at_home()` does to whatever the body is holding.
	(body.get("instance") as RefCounted).heal_fully()

	assert_eq(taken.hp, hurt,
		"the pal the party holds was healed by the world reviving its old body")
	body.free()


## The one the evidence session hit: a second catch of the same species must be
## a catch, not `already_held`.
func test_the_replacement_can_be_caught_by_a_party_that_holds_the_first() -> void:
	var party: RefCounted = (load("res://scripts/pals/party.gd") as GDScript).new()
	var body := _wild()

	var first: RefCounted = body.get("instance") as RefCounted
	assert_true(party.add(first), "the party would not take the first catch")
	body.call("hand_instance_to_owner")

	var second: RefCounted = body.get("instance") as RefCounted
	assert_true(party.add(second),
		"catching the same creature again was refused: %s" % party.last_refusal())
	assert_eq(party.size(), 2)
	body.free()


## Damage to the body's own pal must not reach the party either — the same bug
## in the other direction, and the one a player would actually notice.
func test_fighting_the_body_does_not_hurt_the_pal_the_party_took() -> void:
	var body := _wild()
	var taken: RefCounted = body.get("instance") as RefCounted
	var was: float = taken.hp

	body.call("hand_instance_to_owner")
	(body.get("instance") as RefCounted).take_damage(9999.0)

	assert_eq(taken.hp, was,
		"a fight on the hillside damaged a pal sitting in the party")
	body.free()
