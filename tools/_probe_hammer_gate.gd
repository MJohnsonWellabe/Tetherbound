extends SceneTree

## GATEB-COORD diagnostic. Who owns Interact in the open field with a creature
## out and the hammer in hand?
##
##   godot --headless --path . --script tools/_probe_hammer_gate.gd
##
## `archive/ralph/DONE.md`'s GATEB-TAIL entry blames the "Put <name> away" fallback,
## but `encounter_director.gd::_creature_control_offer()` builds that with
## `actionable: false` and `playground_hud.gd::_hammer_opens_the_catalogue()`
## explicitly stopped deferring to non-actionable lines. So the line the hammer
## actually loses to is unidentified. This prints every registered provider's
## offer and the arbiter's winner, once with the creature away and once with it
## deployed, and then asks the HUD's own gate.
##
## A probe, not evidence.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const PROMPTS := preload("res://scripts/world/prompt_arbiter.gd")
const CREATURE := preload("res://scripts/creatures/creature_instance.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node3D = (load(SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(world)
	for _i in 300:
		await physics_frame

	var game := root.get_node_or_null(^"/root/Game")
	var player := _find(world, "locomotion_enabled") as Node3D
	var arbiter := get_first_node_in_group(&"interaction_arbiter")
	var director := world.get_node_or_null(^"EncounterDirector")
	if game == null or player == null or arbiter == null or director == null:
		print("PROBE: missing game/player/arbiter/director")
		quit(1)
		return

	# A party with one creature, and the hammer in hand: the state a player is
	# in when they walk into open meadow meaning to build.
	var party: RefCounted = game.get("party")
	# `meadowhart` on purpose: `riding_controller.gd` is the other provider that
	# follows the player around, and unlike the creature-control line its "Ride"
	# offer IS actionable. A probe that only ever holds a Terrapup cannot see it.
	var species := "meadowhart"
	if int(party.call("size")) == 0:
		party.call("add", _starter(species))
	inventory_saddle(game)
	var inventory: RefCounted = game.get("inventory")
	inventory.call("add", "hammer", 1)
	game.set("equipped_tool", "hammer")
	# Out of the opening bedroom: the spawn point has a "Get up" bed prompt
	# 1.5m away, which is not the open field the defect is reported in.
	player.global_position = Vector3(-25.0, 5.0, -60.0)
	for _i in 90:
		await physics_frame
	print("PROBE party=%d equipped=%s at %s" % [
		int(party.call("size")), str(game.get("equipped_tool")),
		str(player.global_position.round())])

	await _report("creature PUT AWAY", arbiter, player)

	director.call("summon_active_creature")
	for _i in 120:
		await physics_frame
	await _report("creature DEPLOYED", arbiter, player)

	# The other half of the directive: standing down is for the hammer only.
	# Put it away and riding must come straight back, or "Build wins while the
	# hammer is out" has quietly become "riding is gone".
	game.set("equipped_tool", "")
	for _i in 30:
		await physics_frame
	await _report("creature DEPLOYED, hammer PUT AWAY", arbiter, player)
	quit(0)


func _report(what: String, arbiter: Node, player: Node3D) -> void:
	print("\n=== %s ===" % what)
	var providers: Array = arbiter.get("_providers")
	for provider: Variant in providers:
		if provider == null or not is_instance_valid(provider as Object):
			continue
		var node := provider as Node
		if not node.has_method("interaction_offer"):
			continue
		var offer: Dictionary = node.call("interaction_offer", player.global_position)
		if offer.is_empty():
			continue
		print("  %-24s %-42s d=%6.2f prio=%3d actionable=%s" % [
			node.name, str(offer.get("label", "")), float(offer.get("distance", 0.0)),
			int(offer.get("priority", 0)), str(offer.get("actionable", true))])
	var winner: Dictionary = arbiter.call("winner")
	var who: Variant = arbiter.call("winning_provider")
	print("  WINNER: '%s' from %s | is_actionable=%s" % [
		str(winner.get("label", "<none>")),
		str((who as Node).name) if who is Node else "<none>",
		str(PROMPTS.is_actionable(winner))])
	print("  -> the hammer gate would %s" % (
		"FORFEIT the interact press" if PROMPTS.is_actionable(winner)
		else "OPEN the build catalogue"))


func _starter(species: String) -> RefCounted:
	return CREATURE.from_species(species, SPECIES.definition(species))


## The saddle `meadowhart` needs before "Ride" becomes an OFFER rather than a
## statement. Both shapes matter: the statement is non-actionable and should be
## harmless, the offer is the one that takes the button.
func inventory_saddle(game: Node) -> void:
	var inventory: RefCounted = game.get("inventory")
	inventory.call("add", "saddle", 1)


func _find(node: Node, method: String) -> Node:
	if node.has_method(method):
		return node
	for child: Node in node.get_children():
		var found := _find(child, method)
		if found != null:
			return found
	return null
