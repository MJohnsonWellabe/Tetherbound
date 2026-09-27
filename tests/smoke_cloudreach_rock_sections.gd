extends SceneTree
const SECTIONS := preload("res://scripts/world/cloudreach_rock_sections.gd")
const BOUNDS := preload("res://scripts/world/building_prefabs.gd")
const FAMILY := [preload("res://assets/environment/stylized_nature/Rock_Medium_1.gltf"),
	preload("res://assets/environment/stylized_nature/Rock_Medium_2.gltf"),
	preload("res://assets/environment/stylized_nature/Rock_Medium_3.gltf")]
var failures: Array[String] = []
var checks := 0
func _init() -> void:
	call_deferred("_run")
func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok: failures.append(what)
func _run() -> void:
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/cloudreach_visual.json")).geology.rock_sections
	for recipe: Array in [[Vector3(59.8,1198,80.5),28],[Vector3(173.6,1048,105),943],[Vector3(60,200,60),31],[Vector3(100,2000,90),13]]:
		var holder := Node3D.new()
		root.add_child(holder)
		var size: Vector3 = recipe[0]
		_check(SECTIONS.build(holder,size,int(recipe[1]),FAMILY,config),"qualified recipe builds")
		var bounds: AABB = BOUNDS.new().combined_aabb(holder)
		_check(absf(bounds.position.y)<0.002 and absf(bounds.end.y-size.y)<0.002,"exact imported vertical extent")
		_check(bounds.position.x >= -size.x*.5 and bounds.end.x <= size.x*.5
			and bounds.position.z >= -size.z*.5 and bounds.end.z <= size.z*.5,"imported horizontal envelope")
		_check(holder.find_children("*","CollisionObject3D",true,false).is_empty()
			and holder.find_children("*","CollisionShape3D",true,false).is_empty(),"no collision introduced")
		_check(holder.get_child_count()>=2 and holder.get_child_count()<=8,"bounded instance count")
		print("ROCK_SECTIONS_NATIVE ",size," count=",holder.get_child_count()," bounds=",bounds)
		holder.free()
	for enabled: bool in [false,true]:
		var holder := Node3D.new()
		var cfg := config.duplicate(true)
		cfg.enabled = enabled
		var size := Vector3(100,150,100) if enabled else Vector3(60,1000,60)
		_check(not SECTIONS.build(holder,size,7,FAMILY,cfg) and holder.get_child_count()==0,"moderate aspect or disabled config uses original branch")
		holder.free()
	print("ROCK_SECTIONS_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
