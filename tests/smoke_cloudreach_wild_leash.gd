extends SceneTree

## Focused regression for a peaceful Cloudreach wild displaced by physics.
## One declared fixture write simulates the measured high-roost slide; the
## production CliffWild leash must return that same body to its validated home.

const SCENE:=preload("res://scenes/world/cloudreach_cliffs.tscn")
const SPECIES:=preload("res://scripts/creatures/creature_species.gd")

var failed:=false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game:=root.get_node("Game")
	game.reset_for_new_game()
	game.current_realm="cloudreach"
	for flag: String in ["realm_key_cloudreach","fly_traversal_unlocked"]:
		game.progression.set_flag(flag)
	game.party.add(SPECIES.spawn("sparkit"))
	var world:=SCENE.instantiate()
	root.add_child(world)
	current_scene=world
	for frame in 20:
		await physics_frame
	var director: Node=world.get_node("EncounterDirector")
	var home:=Vector3(0.0,105.0,-245.0)
	var wild: CharacterBody3D=director.spawn_wild("sparkit",home,{
		"name":"peaceful_leash_regression","aggressive":false,"wander_radius":4.0})
	_require(wild!=null,"Cloudreach wild spawned on validated entry-road support")
	if wild==null:
		quit(1)
		return
	home=wild.global_position
	# Fixture injection only: reproduce a body carried well beyond residency.
	wild.global_position=home+Vector3(30.0,12.0,0.0)
	wild.velocity=Vector3.ZERO
	for frame in 8:
		await physics_frame
	_require(wild.global_position.distance_to(home)<0.75,
		"Production leash returned the same peaceful body to validated home")
	_require(int(wild.call("peaceful_leash_recoveries"))==1,
		"Exactly one production leash recovery occurred")
	print("CLOUDREACH WILD LEASH %s home=%s at=%s recoveries=%d"%[
		"FAIL" if failed else "PASS",home,wild.global_position,
		int(wild.call("peaceful_leash_recoveries"))])
	quit(1 if failed else 0)


func _require(condition: bool,label: String) -> void:
	if condition:
		print("PASS: "+label)
	else:
		failed=true
		push_error("FAIL: "+label)
