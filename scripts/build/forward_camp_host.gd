extends RefCounted

## Narrow Foundation integration hook. Call ONLY from authenticated Session
## after resolving its admitted peer/character/revision and mutation fence.
## Neither caller requests nor visible UI certify reach, terrain or inventory.
const RULES := preload("res://scripts/build/forward_camp_rules.gd")
const ACTIONS := preload("res://scripts/build/forward_camp_actions.gd")
const TEACHING := preload("res://scripts/creatures/teaching.gd")

static func placement_context(placer: Node, game: Node, actor: Node3D, character: String,
		revision: int, realm: String, combat: bool, original: Dictionary, observation: Dictionary = {}) -> Dictionary:
	var cfg := RULES.config()
	if cfg.get("runtime_enabled") != true or game == null or game.call("is_host") != true \
			or not is_instance_valid(placer) or not is_instance_valid(actor) or not actor.is_inside_tree() \
			or not placer.get_parent().is_ancestor_of(actor) or not actor.global_position.is_finite() \
			or actor.get_world_3d() != (placer.get_parent() as Node3D).get_world_3d() \
			or character.is_empty() or revision < 0 or combat: return {}
	if original.get("action") != "place" or not RULES.STATIONS.PLOT.numbers(original.get("position"),3): return {}
	var p: Array = original.position
	var at := Vector3(p[0],p[1],p[2])
	if actor.global_position.distance_to(at) > float(cfg.maximum_place_distance_m): return {}
	var checked: Variant = placer.call("validate_forward_camp_ground",game,realm,at,original.get("yaw_deg",NAN),actor)
	observation["ground_validation_code"] = str(checked.get("code", "")) if checked is Dictionary else ""
	if not checked is Dictionary or checked.get("ok") != true: return {}
	return {"character_id":character,"expected_revision":revision,"realm":realm,
		"in_range":true,"in_combat":false,"host_ground_valid":true}

static func context(placer: Node, game: Node, camp: Node3D, actor: Node3D,
		character: String, revision: int, realm: String, combat: bool, part: String) -> Dictionary:
	if game == null or game.call("is_host") != true or not is_instance_valid(placer) \
			or not is_instance_valid(camp) or not is_instance_valid(actor) or not camp.is_inside_tree() \
			or not actor.is_inside_tree() or camp.get_script() != preload("res://scripts/build/forward_camp.gd") \
			or not camp.is_in_group("placed_building") or camp.scale != Vector3.ONE \
			or actor.get_world_3d() != camp.get_world_3d() or not placer.get_parent().is_ancestor_of(camp) \
			or not placer.get_parent().is_ancestor_of(actor): return {}
	var uid := str(camp.get_meta("building_uid",""))
	var source := RULES.record(game.get("placed_buildings"),uid)
	if source.get("ok") != true or camp.get_meta("realm","") != realm \
			or camp.get_meta("placed_index",-1) != source.index: return {}
	var p: Array = source.record.position
	if camp.global_position.distance_to(Vector3(p[0],p[1],p[2])) > 0.01 \
			or absf(wrapf(rad_to_deg(camp.global_rotation.y)-source.record.yaw_deg,-180,180)) > 0.01: return {}
	var count := 0
	for node: Node in camp.get_tree().get_nodes_in_group("placed_building"):
		if placer.get_parent().is_ancestor_of(node) and node.get_meta("building_uid","") == uid: count+=1
	if count != 1: return {}
	return RULES.source_context(RULES.config(),game.get("placed_buildings"),uid,actor.global_position,
		realm,character,revision,combat,part)

static func stage_loadout(creature: RefCounted, original: Dictionary,
		host_context: Dictionary, owned_uids: Array, moves: RefCounted) -> Dictionary:
	if host_context.get("station_kind") != RULES.ID or host_context.get("part") != "workbench":
		return RULES.deny("camp_unavailable")
	var derived := host_context.duplicate(true)
	derived.owned_creature_uids=owned_uids.duplicate()
	return TEACHING.stage_loadout_edit(creature,original,derived,moves)

static func pack_context(placer: Node, game: Node, camp: Node3D, actor: Node3D,
		character: String, revision: int, realm: String, combat: bool,
		admitted_parties: Array, complete_projection: bool) -> Dictionary:
	var actual := context(placer,game,camp,actor,character,revision,realm,combat,"workbench")
	if actual.is_empty() or not complete_projection: return {}
	for party: Variant in admitted_parties:
		if not party is Array or party.size() > 5: return {}
		for row: Variant in party:
			if not row is Dictionary or not row.get("resting") is bool: return {}
			if row.resting and row.get("rest_bed_index") == actual.camp_index: return {}
	actual.all_parties_awake=true
	actual.host_ground_valid=true # Packing validates the existing source, no new terrain claim.
	# HOMESTEAD §8: placing a second camp in a biome packs up the first from
	# wherever the owner stands in that loaded realm (stage_build still checks
	# ownership and that no party rests there); reach gates use, not packing.
	actual.in_range=true
	actual.within_reach=true
	return actual

## Reconcile before resolving the source again: an accepted pack removes it.
## Foundation supplies these bound journal callbacks; no parallel save store.
static func commit(original: Dictionary, reconcile: Callable, restage: Callable,
		journal: Callable, publish: Callable) -> Dictionary:
	if not reconcile.is_valid() or not restage.is_valid() or not journal.is_valid() or not publish.is_valid():
		return RULES.deny("camp_unavailable")
	var prior: Variant = reconcile.call(original.duplicate(true))
	if not prior is Dictionary: return RULES.deny("camp_unavailable")
	if prior.get("found") == true: return prior
	if prior.get("ok") != true: return prior
	var stage: Variant = restage.call(original.duplicate(true))
	if not stage is Dictionary or stage.get("ok") != true: return stage if stage is Dictionary else RULES.deny("camp_unavailable")
	var saved: Variant = journal.call(stage,original.duplicate(true))
	if not saved is Dictionary or saved.get("ok") != true or saved.get("durable") != true:
		return saved if saved is Dictionary else RULES.deny("camp_unavailable")
	# Journal owns rollback, hidden promotion and world+character atomicity.
	# Publish performs ordinary owner-save+ACK. A saved host decision alone
	# does not mean settled; its original ID stays pending across disconnect.
	var result: Variant = publish.call(saved)
	return result if result is Dictionary else {"ok":false,"pending":true,"durable":true,"settled":false}
