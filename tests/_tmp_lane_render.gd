extends SceneTree
const WILD := preload("res://scripts/creatures/wild_creature.gd")
const BODY := preload("res://scripts/creatures/creature_body.gd")
const AI := preload("res://scripts/combat/combat_ai.gd")
const SCENE := preload("res://scenes/creatures/creature.tscn")
class Ground extends Node3D:
	func ground_height_at(x: float, z: float) -> float:
		return 0.15 * sin(x * 0.7) * cos(z * 0.5)
func _init():
	call_deferred("_run")
func _run():
	var world := Ground.new(); root.add_child(world)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-50, 30, 0); world.add_child(sun)
	var floor_mesh := MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(60,60); pm.subdivide_width=60; pm.subdivide_depth=60; floor_mesh.mesh = pm
	var mat := StandardMaterial3D.new(); mat.albedo_color = Color(0.3,0.45,0.2); floor_mesh.material_override = mat
	floor_mesh.position.y = 0.05; world.add_child(floor_mesh)
	var sb := StaticBody3D.new(); var cs := CollisionShape3D.new(); var bx := BoxShape3D.new(); bx.size = Vector3(60,1,60); cs.shape = bx; sb.add_child(cs); sb.position.y = -0.5; world.add_child(sb)
	var wild: Node3D = SCENE.instantiate(); wild.set_script(WILD)
	wild.set("combat_override", {"preferred_range": 4.5, "lunge": 7.0, "telegraph": 0.8, "recovery": 0.9, "attack_cooldown": 1.6, "power": 10.4, "lunge_travels": true})
	wild.set("trainer_owned", true)
	world.add_child(wild); wild.call("populate", "tuskroot", null); wild.call("place_on_ground", Vector3.ZERO)
	var ally: Node3D = SCENE.instantiate(); ally.set_script(BODY); world.add_child(ally); ally.call("setup", "terrapup"); ally.call("place_on_ground", Vector3(2.5, 0, 8.0))
	var cam := Camera3D.new(); world.add_child(cam); cam.fov = 46; cam.position = Vector3(6, 6.5, 14); cam.look_at(Vector3(0.5, 0, 4)); cam.current = true
	for i in 10: await physics_frame
	wild.call("set_engaged", true, ally); wild.call("face_towards", ally.global_position)
	wild.set("_cooldown", 0.0); wild.call("_enter", AI.Intent.TELEGRAPH)
	for i in 36: await physics_frame
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(OS.get_cmdline_user_args()[0] + "/lane_mid.png")
	for i in 16: await physics_frame
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(OS.get_cmdline_user_args()[0] + "/lane_charge.png")
	quit()
