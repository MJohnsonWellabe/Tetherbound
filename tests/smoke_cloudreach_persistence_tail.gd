extends "res://tests/smoke_cloudreach_continuous.gd"

## Exact production save/load regression for the continuous acceptance tail.
## The fixture varies durable fields across all five members, then freezes only
## the observation window so real-time condition decay cannot race the reads.


func _run() -> void:
	start_usec=Time.get_ticks_usec()
	output_dir="res://ralph/reports/CLOUDREACH-CONTINUOUS-0905/persistence-tail-regression"
	DirAccess.make_dir_recursive_absolute(output_dir)
	game=root.get_node("Game")
	game.reset_for_new_game()
	game.save_system=SAVE.new("user://cloudreach_persistence_tail_regression")
	for index in 5:
		var species: String=["sparkit","mudsnout","bramblebun","terrapup","brooktail"][index]
		var member: RefCounted=SPECIES.spawn(species)
		member.set_level(22+index,PROGRESSION.config())
		member.set("xp",101+index*37)
		member.set("hp",float(member.get("max_hp"))-(index+1)*7.25)
		member.set("energy",17.5+index)
		member.set("nickname","Tail%d"%index)
		member.set("bond",index*3)
		member.set("battles_fought",index+4)
		member.set("distance_m_together",1234.56789+index*0.125)
		member.set("nourishment",0.375+index*7.125)
		member.set("happiness",44.875+index*3.25)
		member.set("rested",index<2)
		member.set("rested_seconds_left",987.654321-index*11.25 if index<2 else 0.0)
		game.party.add(member)
	stage="persistence_tail_exact"
	paused=true
	var before:=_party_persistence_snapshot()
	var save_ok: bool=game.save_game(0)
	var load_ok: bool=save_ok and game.load_game(0)
	var after:=_party_persistence_snapshot()
	var differences:=_party_persistence_differences(before,after)
	paused=false
	_require(save_ok,"Production save wrote the five-member tail fixture")
	_require(load_ok,"Production load restored the five-member tail fixture")
	_log("persistence_party_diff",{"differences":differences,"before":before,"after":after})
	_require(differences.is_empty(),"All declared persisted fields round-tripped exactly")
	_require(game.party.size()==5,"Round-trip retained exactly five party members")
	print("CLOUDREACH PERSISTENCE TAIL %s members=%d differences=%d"%[
		"FAIL" if failed else "PASS",game.party.size(),differences.size()])
	quit(1 if failed else 0)
