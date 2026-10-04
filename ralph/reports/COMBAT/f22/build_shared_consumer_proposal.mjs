// Exact other-owner proposals. Only ignored output is mutated.
import fs from 'node:fs';
import crypto from 'node:crypto';
const hash=x=>crypto.createHash('sha256').update(x).digest('hex');
const edits=[];
function proposal(path, transform, requires) {
  const before=fs.readFileSync(path,'utf8');
  let after=before.replaceAll('\r\n','\n');
  const replace=(from,to)=>{
    if(!after.includes(from))throw Error(path+' anchor absent: '+from.slice(0,70));
    after=after.replace(from,to);
  };
  transform(replace,()=>after,s=>{after=s});
  const destination='.tmp/f22-integration/after/'+path;
  fs.mkdirSync(destination.slice(0,destination.lastIndexOf('/')),{recursive:true});
  fs.writeFileSync(destination,after);
  const baseline='.tmp/f22-integration/before/'+path;
  fs.mkdirSync(baseline.slice(0,baseline.lastIndexOf('/')),{recursive:true});
  fs.writeFileSync(baseline,before);
  edits.push({path,before_sha256:hash(before),after_sha256:hash(after),requires});
}
proposal('scripts/combat/combat_manager.gd',(replace,get,set)=>{
  replace('var _enemy_owned', 'var _f22_canonical_wild := false\nvar _enemy_owned');
  replace('\t_enemy_owned = opponent_owned','\t_enemy_owned = opponent_owned\n\t_f22_canonical_wild = not opponent_owned and wild.get_meta(&"canonical_wild_runtime", false) == true');
  replace('func _award_victory() -> void:\n','func _award_victory() -> void:\n\tif _f22_canonical_wild: return  # SAME Foundation journal owns XP/care/bond/history.\n');
  set(get().replaceAll('\t\tCONDITION.note_faint(creature, CONDITION.config())','\t\tif not _f22_canonical_wild:\n\t\t\tCONDITION.note_faint(creature, CONDITION.config())'));
  replace('else MATH.move_connects(cfg, origin, facing, target)',`else _f22_pattern_connects(cfg, origin, facing, target)`);
  replace('\tif not travelled:\n', '\tif not travelled and str(cfg.get("telegraph_shape", "")) != "marker":\n');
  set(get()+`

func _f22_pattern_connects(cfg: Dictionary, origin: Vector3, heading: Vector3, target: Vector3) -> bool:
\tif not cfg.has("pattern_attack_id"): return MATH.move_connects(cfg, origin, heading, target)
\tif not is_instance_valid(_wild) or not _wild.has_method("pattern_geometry"): return false
\tvar geometry: Dictionary = cfg.get("_pattern_geometry", {})
\tif geometry.is_empty(): geometry = _wild.call("pattern_geometry")
\tif not geometry.get("profile") is Dictionary or geometry.profile.get("pattern_attack_id") != cfg.get("pattern_attack_id"): return false
\tvar ai: Script = preload("res://scripts/combat/combat_ai.gd")
\treturn ai.pattern_contains(cfg, geometry.origin, geometry.heading, geometry.marker,
\t\ttarget, float(_ally_body.call("body_radius")))
`);
},['ROOT frozen F21 manager composition','Actual actor incoming-HP proposal/settlement producer','F27 same-journal canonical victory producer','F24 joint-combo and request/observation adapters']);
proposal('scripts/creatures/shared_opponent_proxy.gd',(replace,get,set)=>{
  replace('func _present_shape(shape: Dictionary) -> void:\n',`func _present_shape(shape: Dictionary) -> void:
\tif shape.get("pattern_geometry") is Dictionary:
\t\tpresent_pattern_pose(shape)
\t\t_free_shape_lane()
\t\t_hide_guard_cone()
\t\treturn
`);
  replace('func _clear_shape() -> void:\n','func _clear_shape() -> void:\n\t_clear_pattern_cue()\n');
  replace('func _release_shape() -> void:\n','func _release_shape() -> void:\n\t_clear_pattern_cue()\n');
  set(get()+`

## Host presentation only. Same generation/pose sequence fence is checked
## by Director before this call. No AI, strike signal, HP or durable write.
func present_pattern_pose(shape: Dictionary) -> void:
\tvar wire: Dictionary = shape.get("pattern_geometry", {})
\tvar profile: Dictionary = wire.get("profile", {})
\tvar id := str(profile.get("pattern_attack_id", ""))
\tif not (MATH.config().get("patterns", {}).get("attacks", {}) as Dictionary).has(id): return
\tvar points: Array[Vector3] = []
\tfor key: String in ["origin", "heading", "marker"]:
\t\tvar row: Variant = wire.get(key)
\t\tif not row is Array or row.size() != 3: return
\t\tfor value: Variant in row:
\t\t\tif not (value is float or value is int) or not is_finite(float(value)): return
\t\tpoints.append(Vector3(float(row[0]), float(row[1]), float(row[2])))
\tif not is_instance_valid(_pattern_cue):
\t\t_pattern_cue = PATTERN_CUE.begin(self, profile, points[0], points[1], points[2],
\t\t\tMATH.config().get("patterns", {}).get("presentation", {}),
\t\t\tColor(str(MATH.config().get("telegraph", {}).get("colour", "#ff40e6"))))
\telse:
\t\t_pattern_cue.call("aim", points[0], points[1], points[2])
`);
},['F22 wild consumer defines inherited PATTERN_CUE and _pattern_cue','ROOT actual live marker pose/cue fence integration','ROOT persistent field/fan cast presentation and reconnect snapshot']);
proposal('scripts/combat/stormwood_hosted_trainer.gd',(replace,get,set)=>{
  const anchor='\tengine.start_opponent(opponent, hub.body_for(participants[0]), centre, radius, self, str(record.encounter_id))';
  replace(anchor,`\t_configure_f22_opponent()
${anchor}`);
  replace('if is_instance_valid(body) and MATH.move_connects(cfg, origin, facing, body.call("centre")):',`if is_instance_valid(body) and _f22_connects(cfg, origin, facing, body):`);
  set(get()+`

func _configure_f22_opponent() -> void:
\tvar patterns: Dictionary = MATH.config().get("patterns", {})
\tif patterns.get("runtime_enabled") != true or not opponent.has_method("configure_patterns"): return
\tvar pattern_id := "named_" + str(spec.id)
\tif not (patterns.get("named", {}) as Dictionary).has(pattern_id): return
\tvar card: RefCounted = opponent.get("instance")
\tvar ai: Script = preload("res://scripts/combat/combat_ai.gd")
\topponent.call("configure_patterns", patterns, {"chapter": "stormwood",
\t\t"trainer_owned": true, "species_id": str(card.get("species_id")),
\t\t"role": ai.species_role(str(card.get("species_id")), patterns),
\t\t"pattern_id": pattern_id, "sendout_index": round_index,
\t\t"move_quick": str(card.get("move_quick")), "move_charged": str(card.get("move_charged"))})


func _f22_connects(cfg: Dictionary, origin: Vector3, heading: Vector3, body: Node3D) -> bool:
\tif not cfg.has("pattern_attack_id"): return MATH.move_connects(cfg, origin, heading, body.call("centre"))
\tif not opponent.has_method("pattern_geometry"): return false
\tvar geometry: Dictionary = cfg.get("_pattern_geometry", {})
\tif geometry.is_empty(): geometry = opponent.call("pattern_geometry")
\tvar ai: Script = preload("res://scripts/combat/combat_ai.gd")
\treturn ai.pattern_contains(cfg, geometry.origin, geometry.heading, geometry.marker,
\t\tbody.call("centre"), float(body.call("body_radius")))
`);
},['ROOT hosted trainer actual admitted actor/HP path','ROOT observed remote action reaction adapter','ROOT host cast consumer in stormwood_authoritative_fight']);
fs.writeFileSync('.tmp/f22-integration/shared-consumer-receipt.json',JSON.stringify({activation:'OFF; unparsed/unrun; ROOT composition only',edits},null,2)+'\n');
console.log(JSON.stringify({edits}));
