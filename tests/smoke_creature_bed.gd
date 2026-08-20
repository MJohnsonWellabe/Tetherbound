extends SceneTree

const BED := preload("res://scripts/build/creature_bed.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")


func _init() -> void:
	var bed := BED.new()
	root.add_child(bed)
	bed.build_real()
	var creature: RefCounted = SPECIES.spawn("terrapup")
	creature.take_damage(creature.max_hp * 0.8)
	if not bed.assign(creature):
		_fail("physical bed refused a valid injured creature")
		return
	await process_frame
	if not creature.resting or bed.occupant() != creature:
		_fail("assignment did not make the creature resting and occupy the bed")
		return
	var body: Node3D = bed.resting_body()
	if body == null or not is_instance_valid(body) or not body.visible:
		_fail("resting creature has no visible physical body in the bed")
		return
	var before: float = creature.hp
	creature.tick_bed_rest(5.0)
	if creature.hp <= before or creature.hp >= creature.max_hp:
		_fail("bed recovery was not gradual after five world-seconds")
		return
	var partial: float = creature.hp
	bed.wake()
	if creature.resting or creature.hp != partial or creature.rest_complete:
		_fail("early wake did not preserve partial HP without completing rest")
		return
	if not bed.assign(creature):
		_fail("empty bed refused reassignment")
		return
	creature.complete_bed_rest()
	if creature.hp != creature.max_hp or creature.resting or not creature.rest_complete:
		_fail("overnight completion did not fully recover and release the creature")
		return
	if bed.occupant() != null or bed.resting_body() != null:
		_fail("completed rest left stale bed occupancy or a stale visual body")
		return
	print("creature bed smoke passed: physical body, gradual HP, early wake, overnight completion")
	quit()


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
