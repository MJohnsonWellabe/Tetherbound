extends "res://tests/test_case.gd"

const POLICY := preload("res://scripts/ui/hud_presentation_policy.gd")
const HUD := preload("res://scripts/ui/combat_hud.gd")

class Manager extends Node:
	var _enemy_owned := false
	func active_creature() -> RefCounted: return null

class Foe extends RefCounted:
	var level := 31

class Director extends Node:
	var _trainer_spec := {"name":"Captain Veyra"}


func test_enemy_identity_distinguishes_ownership_and_omits_missing_level() -> void:
	var manager := Manager.new()
	var director := Director.new()
	var foe := Foe.new()
	assert_eq(HUD.enemy_identity_text(foe,manager,director),"LEVEL 31")
	manager._enemy_owned = true
	assert_eq(HUD.enemy_identity_text(foe,manager,director),"Captain Veyra · LEVEL 31")
	assert_eq(HUD.enemy_identity_text(foe,manager,null),"Trainer-owned · LEVEL 31")
	foe.level = 0
	assert_eq(HUD.enemy_identity_text(foe,manager,director),"Captain Veyra")
	assert_eq(HUD.enemy_identity_text(null,manager,director),"")
	manager.free()
	director.free()


func test_mode_priority_preserves_combat_and_relay_control_surfaces() -> void:
	var combat := POLICY.resolve("exploration",true,false,false)
	assert_true(combat.combat)
	for field: String in ["task","location","hotbar","instruction","human_vitals"]:
		assert_false(combat[field])
	var relays := POLICY.resolve("relays",false,false,false)
	assert_true(relays.party)
	assert_true(relays.prompt)
	assert_true(relays.instruction)
	assert_false(relays.hotbar)
	assert_false(relays.task)
	assert_false(POLICY.resolve("relays",false,false,true).instruction)
	assert_eq(POLICY.resolve("relays",true,true,true).mode,"modal")
	assert_true(POLICY.resolve("exploration",false,false,false).hotbar)


func test_trainer_win_relinquishes_result_but_wild_verdict_remains() -> void:
	var hud:=HUD.new()
	var manager:=Manager.new()
	hud._manager=manager
	var outcome:=Label.new()
	var xp:=Label.new()
	var go:=Label.new()
	var prompt:=RichTextLabel.new()
	hud._outcome=outcome; hud._xp_line=xp; hud._go_text=go; hud._prompt=prompt
	hud._on_exited("won")
	assert_true(outcome.text.contains("wild creature"))
	manager._enemy_owned=true
	xp.text="old XP"; go.text="old GO"
	hud._on_exited("won")
	assert_eq(outcome.text,"")
	assert_eq(xp.text,"")
	assert_eq(go.text,"")
	assert_eq(hud._outcome_left,0.0)
	hud.set_world_presentation_mode("relays")
	hud._on_exited("lost")
	assert_eq(outcome.text,"")
	for node: Node in [outcome,xp,go,prompt,hud,manager]:node.free()
