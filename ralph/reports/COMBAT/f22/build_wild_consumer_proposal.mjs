// Frozen other-owner consumer proposal; only writes ignored .tmp output.
import fs from 'node:fs';
import crypto from 'node:crypto';
const file='scripts/creatures/wild_creature.gd';
const before=fs.readFileSync(file,'utf8');
let after=before.replaceAll('\r\n','\n');
const replace=(a,b)=>{if(!after.includes(a))throw Error('consumer anchor missing '+a.slice(0,65));after=after.replace(a,b);};
replace('const AI := preload("res://scripts/combat/combat_ai.gd")', 'const AI := preload("res://scripts/combat/combat_ai.gd")\nconst PATTERN_CUE := preload("res://scripts/combat/enemy_pattern_telegraph.gd")');
replace('var _selected_attack_attempts: int = 0',`var _selected_attack_attempts: int = 0
var _patterns: Dictionary = {}
var _pattern_context: Dictionary = {}
var _pattern_observer: Callable
var _pattern_cursor := 0
var _pattern_dodge_left := 0.0
var _pattern_observation_key := ""
var _pattern_observed_s := 0.0
var _pattern_punish_next := false
var _pattern_origin := Vector3.ZERO
var _pattern_marker := Vector3.ZERO
var _pattern_heading := Vector3.FORWARD
var _pattern_cue: Node3D
var _pattern_repeats_left := 0
var _pattern_repeat_next := false
var _pattern_repeat_row: Dictionary = {}
var _pattern_leap_active := false`);
replace('func set_engaged(', `func configure_patterns(patterns: Dictionary, context: Dictionary, observer: Callable = Callable()) -> void:
\t_patterns = patterns.duplicate(true)
\t_pattern_context = context.duplicate(true)
\t_pattern_context["role"] = AI.context_role(patterns, _pattern_context)
\t_pattern_observer = observer


func _pattern_enabled() -> bool:
\treturn _patterns.get("runtime_enabled") == true and not _pattern_context.is_empty()


func pattern_geometry() -> Dictionary:
\treturn {"profile": _selected_attack.duplicate(true), "origin": _pattern_origin,
\t\t"heading": _pattern_heading, "marker": _pattern_marker}


func _pattern_movement_row() -> Dictionary:
\tif not _pattern_enabled(): return _combat_cfg
\tif _intent == AI.Intent.REPOSITION and not _pattern_repeat_row.is_empty(): return _pattern_repeat_row
\tif _intent == AI.Intent.DODGE: return _patterns.get("reactions", {})
\tif not _selected_attack.is_empty(): return _selected_attack
\tvar context := _pattern_context.duplicate(true)
\tcontext["hp_fraction"] = float(instance.call("hp_fraction"))
\tvar preview := AI.select_pattern(_patterns, _combat_cfg, context, _pattern_cursor)
\treturn preview if not preview.is_empty() else _combat_cfg


func _clear_pattern_cue() -> void:
\tif is_instance_valid(_pattern_cue): _pattern_cue.queue_free()
\t_pattern_cue = null


func _pattern_profile() -> Dictionary:
\tvar context := _pattern_context.duplicate(true)
\tcontext["hp_fraction"] = float(instance.call("hp_fraction"))
\tvar selected: Dictionary
\tif _pattern_repeat_next:
\t\tselected = _pattern_repeat_row.duplicate(true)
\t\tselected["telegraph"] = maxf(1.1 if bool(selected.get("heavy", false)) else 0.8,
\t\t\tfloat(selected.get("repeat_telegraph_s", 1.1)))
\t\tselected["route_cue_seconds"] = float(selected.get("repeat_reaim_s", 0.3))
\t\tselected["recovery"] = maxf(0.6, float(selected.get("repeat_recovery_s", 0.6)))
\t\t_pattern_repeat_next = false
\telif _pattern_punish_next:
\t\tselected = AI.punish_profile(_patterns, _combat_cfg, context)
\t\t_pattern_punish_next = false
\telse:
\t\tselected = AI.select_pattern(_patterns, _combat_cfg, context, _pattern_cursor)
\t\t_pattern_cursor += 1
\t\t_pattern_repeats_left = maxi(0, int(selected.get("repeat_count", 1)) - 1)
\t\t_pattern_repeat_row = selected.duplicate(true)
\tif selected.is_empty():
\t\tpush_error("F22 has no valid role/move/sequence for %s" % instance.get("species_id"))
\t\treturn {}
\tselected = AI.chapter_windows(_patterns, context, selected)
\t_pattern_repeat_row = selected.duplicate(true)
\tif str(selected.get("telegraph_shape", "")) == "lane":
\t\tselected["lane_half_width_m"] = body_radius() * float(_lunge_cfg().get("contact_scale", 1.2))
\tvar theirs := float(_opponent.call("body_radius")) if _opponent.has_method("body_radius") else 0.5
\treturn spaced_config_for(selected, body_radius(), theirs, _contact_need(), _contact_reach_need())


func _observe_pattern_response(delta: float) -> void:
\t_pattern_dodge_left = maxf(0.0, _pattern_dodge_left - delta)
\tvar observation: Dictionary = _pattern_observer.call() if _pattern_observer.is_valid() else {}
\tvar key := str(observation.get("creature_uid", "")) + ":" + str(observation.get("action", ""))
\tif observation.is_empty():
\t\t_pattern_observed_s = 0.0
\t\t_pattern_observation_key = ""
\t\treturn
\tif key != _pattern_observation_key:
\t\t_pattern_observation_key = key
\t\t_pattern_observed_s = 0.0
\telse:
\t\t_pattern_observed_s += delta
\tobservation["visible_for_s"] = _pattern_observed_s
\tobservation["dodge_cooldown_s"] = _pattern_dodge_left
\tobservation["attack_cooldown_s"] = _cooldown
\tvar response := AI.reaction(_intent, observation, _patterns)
\tif response == "dodge":
\t\tvar reactions: Dictionary = _patterns.get("reactions", {})
\t\tvar role := str(_pattern_context.get("role", ""))
\t\tvar mobile := trainer_owned and role in ["DIVER", "CHARGER"]
\t\t_pattern_dodge_left = float(reactions.get("mobile_trainer_dodge_cooldown_s" if mobile
\t\t\telse "trainer_dodge_cooldown_s" if trainer_owned else "wild_dodge_cooldown_s", 6.0))
\t\t_side_sign = float(observation.get("side_sign", 1.0))
\t\t_enter(AI.Intent.DODGE)
\t\tbegin_combat_burst(AI.movement_for(AI.Intent.DODGE, _opponent.global_position - global_position,
\t\t\t_side_sign), float(reactions.get("dodge_distance_m", 3.0)), float(reactions.get("dodge_duration_s", 0.2)))
\telif response == "punish":
\t\t_pattern_punish_next = true
\t\t_enter(AI.Intent.TELEGRAPH)


func set_engaged(`);
replace('\tengaged = value\n',`\tengaged = value
\t_clear_pattern_cue()
\t_pattern_cursor = 0
\t_pattern_repeats_left = 0
\t_pattern_repeat_next = false
\t_pattern_punish_next = false
\t_pattern_observation_key = ""
\t_pattern_observed_s = 0.0
\t_pattern_dodge_left = 0.0
\t_pattern_leap_active = false
`);
replace('func _cancel_lunge() -> void:\n',`func _cancel_lunge() -> void:
\tif _pattern_leap_active:
\t\t_pattern_leap_active = false
\t\tcancel_combat_burst()
`);
replace('\t_cooldown = maxf(0.0, _cooldown - delta)',`\tif _pattern_leap_active:
\t\tif combat_burst_active() or not is_on_floor(): return
\t\t_pattern_leap_active = false
\t\t# Terrain may stop the leap short. Never hit the marked destination
\t\t# through a wall: the landing must reach the advertised area.
\t\tif Vector2(global_position.x - _pattern_marker.x, global_position.z - _pattern_marker.z).length() <= float(_selected_attack.get("marker_radius_m", 2.0)):
\t\t\tstrike_ready.emit()
\t\t_beat_left = float(_selected_attack.get("recovery", 1.0))
\t\treturn
\t_cooldown = maxf(0.0, _cooldown - delta)`);
replace('\t_advance_route_cue(delta)',`\tif _pattern_enabled():
\t\t_observe_pattern_response(delta)
\t_advance_route_cue(delta)`);
replace('\tvar next: int = AI.decide(_intent, distance, _beat_left, _cooldown, spaced)',`\tif _pattern_enabled() and _intent == AI.Intent.RECOVER and _beat_left <= 0.0 and _pattern_repeats_left > 0:
\t\t_pattern_repeats_left -= 1
\t\t_pattern_repeat_next = true
\t\t_enter(AI.Intent.TELEGRAPH)
\tvar next: int = AI.decide(_intent, distance, _beat_left, _cooldown, spaced)`);
replace('\t_aim_lunge_lane()',`\t_aim_lunge_lane()
\tif _pattern_enabled() and _intent == AI.Intent.TELEGRAPH and not _selected_heading_is_locked():
\t\t_pattern_heading = facing()
\t\tif str(_selected_attack.get("telegraph_shape", "")) in ["marker", "field"]:
\t\t\t_pattern_marker = _opponent.global_position
\t\tif is_instance_valid(_pattern_cue):
\t\t\t_pattern_cue.call("aim", _pattern_origin, _pattern_heading, _pattern_marker)`);
replace('\tif intent == AI.Intent.TELEGRAPH and named_enabled:',`\tif intent == AI.Intent.TELEGRAPH and _pattern_enabled():
\t\t_selected_attack = _pattern_profile()
\t\tif _selected_attack.is_empty():
\t\t\t_intent = AI.Intent.CLOSE
\t\t\t_cooldown = float(_combat_cfg.get("attack_cooldown", 1.1))
\t\t\treturn
\t\t_selected_heading_locked = false
\t\t_beat_left = float(_selected_attack.telegraph)
\t\t_pattern_origin = global_position
\t\t_pattern_heading = facing()
\t\t_pattern_marker = _opponent.global_position
\t\t_clear_pattern_cue()
\t\t_pattern_cue = PATTERN_CUE.begin(self, _selected_attack, _pattern_origin,
\t\t\t_pattern_heading, _pattern_marker, _patterns.get("presentation", {}),
\t\t\tColor(str(MATH.config().get("telegraph", {}).get("colour", "#ff40e6"))))
\telif intent == AI.Intent.TELEGRAPH and named_enabled:`);
replace('\telif intent == AI.Intent.REPOSITION:\n',`\telif intent == AI.Intent.REPOSITION:
\t\t_clear_pattern_cue()
`);
replace('\tif intent != AI.Intent.TELEGRAPH:\n',`\tif intent != AI.Intent.TELEGRAPH:
\t\t_clear_pattern_cue()
`);
// The lane's commitment must match the per-body frozen strike value (STATE defect).
after=after.replaceAll('float(_lunge_cfg().get("face_lock_fraction", 0.5))','float(_attack_row().get("face_lock_fraction", _lunge_cfg().get("face_lock_fraction", 0.5)))');
replace('\telif previous == AI.Intent.TELEGRAPH and intent == AI.Intent.RECOVER and lunge_travels():',`\telif previous == AI.Intent.TELEGRAPH and intent == AI.Intent.RECOVER and _pattern_enabled() and str(_selected_attack.get("telegraph_shape", "")) == "marker":
\t\tvar leap := _pattern_marker - global_position
\t\tleap.y = 0.0
\t\t_cooldown = float(_selected_attack.get("attack_cooldown", 1.2))
\t\t_pattern_leap_active = begin_combat_burst(leap, leap.length(), float(_patterns.get("casts", {}).get("leap_travel_s", 0.45)))
\t\tif _pattern_leap_active:
\t\t\trequest_jump(float(_patterns.get("casts", {}).get("leap_height_m", 0.75)))
\t\t\tplay_attack()
\t\telse:
\t\t\tstrike_ready.emit()
\telif previous == AI.Intent.TELEGRAPH and intent == AI.Intent.RECOVER and lunge_travels():`);
after=after.replaceAll('AI.speed_for(_intent, _combat_cfg, waiting)','AI.speed_for(_intent, _pattern_movement_row(), waiting)');
after=after.replaceAll('AI.duration_for(intent, _combat_cfg)','AI.duration_for(intent, _pattern_movement_row())');
replace('return spaced_config_for(_combat_cfg, mine, theirs, _contact_need(), _contact_reach_need())','return spaced_config_for(_pattern_movement_row(), mine, theirs, _contact_need(), _contact_reach_need())');
replace('func presentation_shape() -> Dictionary:', 'func presentation_shape() -> Dictionary:');
// Exact extra shape overlay is added before the existing legacy return.
const shapeStart=after.indexOf('func presentation_shape() -> Dictionary:');
const shapeEnd=after.indexOf('\n\nfunc ',shapeStart+10);
const shape=after.slice(shapeStart,shapeEnd);
const lastReturn=shape.lastIndexOf('\treturn shape');
if(lastReturn<0)throw Error('presentation return anchor changed');
const overlay='\tif _pattern_enabled() and not _selected_attack.is_empty():\n\t\tvar geometry := pattern_geometry()\n\t\tshape["pattern_geometry"] = {"profile": geometry.profile, "origin": [_pattern_origin.x, _pattern_origin.y, _pattern_origin.z], "heading": [_pattern_heading.x, _pattern_heading.y, _pattern_heading.z], "marker": [_pattern_marker.x, _pattern_marker.y, _pattern_marker.z]}\n';
after=after.slice(0,shapeStart)+shape.slice(0,lastReturn)+overlay+shape.slice(lastReturn)+after.slice(shapeEnd);
const dir='.tmp/f22-integration/after/scripts/creatures';fs.mkdirSync(dir,{recursive:true});
fs.writeFileSync(dir+'/wild_creature.gd',after);
const hash=s=>crypto.createHash('sha256').update(s).digest('hex');
fs.writeFileSync('.tmp/f22-integration/wild-consumer-receipt.json',JSON.stringify({path:file,before_sha256:hash(before),after_sha256:hash(after),activation:'OFF; unparsed and unrun; ROOT sole integration owner'},null,2));
console.log(JSON.stringify({path:file,before_sha256:hash(before),after_sha256:hash(after)}));
