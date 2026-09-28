extends SceneTree
## Evidence-only paired capture at production CameraRig; latest lane world untouched.
const SPECIES = preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION = preload("res://scripts/creatures/progression.gd")
const SAVE = preload("res://scripts/save/save_game.gd")
const STANDS = [
 ["pump_intake", Vector3(-5,.2,16),180.0,-10.0],
 ["pump_return", Vector3(9,.2,43),180.0,-10.0],
 ["gate_intake",Vector3(0,.2,21),180.0,-14.0],
 ["gate_return",Vector3(0,.2,67),180.0,-14.0],
 ["banner_west",Vector3(-8,.2,98),110.0,-8.0],
 ["banner_east",Vector3(8,.2,98),250.0,-8.0],
 ["heart_entry",Vector3(0,.2,86),180.0,-8.0],
 ["intake_gallery",Vector3(0,.2,6),180.0,-8.0],
]
var out = "res://shots/veilfall-new-props"
var rows: Array = []
func _init():
 _run.call_deferred()
func _run():
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
 await process_frame
 var game=root.get_node("Game")
 game.current_realm="water"
 game.local.character_id="veilfall-new-props-capture"
 game.world.world_id="veilfall-new-props-capture-world"
 game.save_system=SAVE.new("user://veilfall_new_props_%d/" % Time.get_ticks_usec())
 for id in ["ripplet","bramblebun","mudsnout","pipwing","trailpup"]:
  var creature=SPECIES.spawn(id)
  creature.set_level(43,PROGRESSION.config())
  game.local.party.add(creature)
 var world=load("res://scenes/world/water_archipelago.tscn").instantiate()
 root.add_child(world)
 current_scene=world
 while not world.shell_build_complete(): await process_frame
 var v=world.get_node("WaterVeilfall")
 var colliders_before=world.find_children("*","CollisionShape3D",true,false).size()
 await _capture(world,v,"before",STANDS)
 var colliders_pre_install=world.find_children("*","CollisionShape3D",true,false).size()
 _install(v)
 var colliders_post_install=world.find_children("*","CollisionShape3D",true,false).size()
 await _capture(world,v,"after",STANDS)
 for flag in ["water_veilfall_intake_stopped","water_veilfall_return_opened"]: game.world.flags.set_flag(flag)
 v._refresh()
 await _capture(world,v,"after-open",[STANDS[2],STANDS[3]])
 var report={"baseline":"e993b8977", "colliders_before":colliders_before,"colliders_pre_install":colliders_pre_install,"colliders_post_install":colliders_post_install,"colliders_after":world.find_children("*","CollisionShape3D",true,false).size(),"fixture":"Declared stand placements, granted five-member party; no summoned companion; closed gate baseline/after then genuine existing flag refresh for open state. No fight or route-completion claim.","frames":rows}
 FileAccess.open(out.path_join("frames.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
 quit(0)
func _capture(world,v,tag,stands):
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out.path_join(tag)))
 var player=world.local_rig()
 var rig=world.get_node("CameraRig")
 for stand in stands:
  player.global_position=v.interior.global_position+stand[1]
  player.velocity=Vector3.ZERO
  rig.yaw=deg_to_rad(stand[2]);rig.pitch=deg_to_rad(stand[3])
  for i in 45: await process_frame
  await RenderingServer.frame_post_draw
  var file=out.path_join(tag).path_join(stand[0]+".png")
  var im=root.get_viewport().get_texture().get_image()
  im.save_png(file)
  var camera=root.get_viewport().get_camera_3d()
  rows.append({"file":file,"viewport":[im.get_width(),im.get_height()],"player":str(player.global_position),"camera":str(camera.global_transform)})
  print("PROP FRAME ",file)
func _install(v):
 var interior=v.interior
 for id in ["intake_pump","sluice_wheel"]:
  var parent=interior.get_node_or_null(NodePath(id))
  if parent==null:
   push_error("Missing pump parent "+id)
   continue
  for mesh in parent.find_children("*","MeshInstance3D",true,false): mesh.hide()
  var pump=load("res://assets/environment/tidewake/pump_station/pump_station.tscn").instantiate()
  parent.add_child(pump)
  pump.position.y=-1.0
  pump.rotation.y=PI
 for child in interior.get_children():
  if child is MeshInstance3D and abs(child.position.x)>19.0 and child.position.y>3.8 and child.position.y<10.5 and child.position.z>102.0 and child.position.z<108.0: child.hide()
 for side in [-1,1]:
  var banner=load("res://assets/environment/tidewake/heart_banner/heart_banner.tscn").instantiate()
  interior.add_child(banner)
  banner.position=Vector3(side*18.0,3.5,105)
  banner.rotation.y=side*PI/2
 _install_gates(v)
func _install_gates(v):
 for gate in v.rules.gates:
  var parent=v.interior.get_node(NodePath(str(gate.id)))
  for mesh in parent.find_children("*","MeshInstance3D",true,false): mesh.hide()
  var asset=load("res://assets/environment/tidewake/sluice_gate/sluice_gate_%d.tscn" % int(gate.width_m)).instantiate()
  v.interior.add_child(asset)
  asset.position.z=float(gate.z)
  asset.get_node("GateLeaf").reparent(parent,false)
