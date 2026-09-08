extends SceneTree
## Actual Player/navigation/arbiter regression for the material driver's
## fallback-status policy. Only the status source and recall observation are
## test doubles; no campaign, harvest grants or progression are involved.
const BASE := preload("res://tests/helpers/gate_a_material_route.gd")
const FIXED := preload("res://tests/helpers/meadows_earned_material_segment.gd")
const NAV := preload("res://tests/helpers/stick_navigator.gd")
const ARBITER := preload("res://scripts/world/interaction_arbiter.gd")
const PROMPT := preload("res://scripts/world/interactable.gd")
const OFFERS := preload("res://scripts/world/prompt_arbiter.gd")
const PLAYER := preload("res://scenes/player/player.tscn")
var failures: Array[String] = []
var checks := 0

class OldProbe extends BASE:
	var recalls := 0
	func _tap_action(action: StringName) -> void:
		if action == &"creature_recall": recalls += 1
		await _tree.physics_frame

class FixedProbe extends FIXED:
	var recalls := 0
	func _tap_action(action: StringName) -> void:
		if action == &"creature_recall": recalls += 1
		await _tree.physics_frame

class Rig extends Node3D:
	var yaw := 0.0
	var pitch := 0.0
	func planar_basis() -> Basis: return Basis.IDENTITY

class Status extends Node:
	var priority := -2
	func interaction_offer(_from: Vector3) -> Dictionary:
		return OFFERS.offer("Put companion away",0.0,priority,false)
	func interaction_activate() -> void: pass

func _initialize() -> void: _run.call_deferred()
func _check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message)
	print("PASS: " if value else "FAIL: ",message)

func _run() -> void:
	await _case(false)
	await _case(true)
	print("material prompt priority checks=",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)

func _case(fixed: bool) -> void:
	var world := Node3D.new()
	root.add_child(world)
	var rig := Rig.new()
	rig.name = "CameraRig"
	world.add_child(rig)
	var floor_body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(30,1,30)
	collision.shape = shape
	floor_body.add_child(collision)
	floor_body.position.y = -0.5
	world.add_child(floor_body)
	var player := PLAYER.instantiate() as CharacterBody3D
	world.add_child(player)
	player.position = Vector3(0,0.1,5.29)
	var arbiter := ARBITER.new()
	arbiter.player_path = NodePath("../Player")
	world.add_child(arbiter)
	var status := Status.new()
	status.name = "EncounterDirector"
	world.add_child(status)
	arbiter.register(status)
	var prompt := PROMPT.new()
	prompt.position = Vector3(0,1.4,0)
	world.add_child(prompt)
	prompt.configure("Chop",2.6,true)
	for frame in 15: await physics_frame
	var helper = FixedProbe.new() if fixed else OldProbe.new()
	helper._tree = self
	helper._player = player
	helper._rig = rig
	helper._arbiter = arbiter
	_check(helper._resolve_move_bindings(),"actual controller movement bindings resolve")
	helper._nav = NAV.new(self,player,rig,helper._send_stick)
	_check(arbiter.winning_provider()==status,"5.29m start offers only the low-priority status")
	var initial := player.position
	var reached: bool = await helper._stand_where_it_wins(prompt,Vector3.ZERO)
	print("CASE fixed=",fixed," reached=",reached," recalls=",helper.recalls," start=",initial," end=",player.position)
	if fixed:
		_check(reached and arbiter.winning_provider()==prompt,"corrected driver physically reaches exact harvest offer")
		_check(helper.recalls==0,"low-priority status does not consume approach attempts with recalls")
		status.priority = 100
		for frame in 3: await physics_frame
		_check(await helper._clear_a_statement_off_the_button(),"actual high-priority lockout retains recall policy")
		_check(helper.recalls==1,"high-priority lockout dispatches one recall")
	else:
		_check(not reached and helper.recalls==10,"old policy consumes all ten approach attempts recalling fallback")
		_check(Vector2(player.position.x,player.position.z).distance_to(Vector2(initial.x,initial.z))<0.01,
			"old policy never physically approaches the target")
	helper._release_move()
	world.queue_free()
	await process_frame
