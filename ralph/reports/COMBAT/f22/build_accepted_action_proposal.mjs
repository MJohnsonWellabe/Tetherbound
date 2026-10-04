// Frozen Foundation successor input; proposal output is ignored only.
import fs from 'node:fs';
import crypto from 'node:crypto';
import {execFileSync} from 'node:child_process';
const root='.tmp/f22-accepted-actions';
const path='scripts/net/encounter_host.gd';
const source='D:/tetherbound/redesign-foundations/.tmp/shared-successor-r1/after/'+path;
const hash=x=>crypto.createHash('sha256').update(x).digest('hex');
fs.mkdirSync(root+'/before/scripts/net',{recursive:true});
fs.mkdirSync(root+'/after/scripts/net',{recursive:true});
const frozen=root+'/before/'+path;
if(!fs.existsSync(frozen))fs.writeFileSync(frozen,fs.readFileSync(source));
const before=fs.readFileSync(frozen,'utf8');
let after=before.replaceAll('\r\n','\n');
const replace=(a,b)=>{if(!after.includes(a))throw Error('missing frozen anchor '+a.slice(0,70));after=after.replace(a,b);};
// Preserve SAME private accepted state across all legacy deadline updates.
// Canonical flag blocks legacy move admission once an actor is bound.
replace('func validate_strike(intent: Dictionary, peer_id: int, view: Dictionary) -> Dictionary:\n',`func validate_strike(intent: Dictionary, peer_id: int, view: Dictionary) -> Dictionary:
\tif MATH.config().get("move_loadout_runtime_enabled") == true and not _actor_participant(str(intent.get("encounter_id", "")), peer_id).is_empty():
\t\treturn _refuse("strike_intent", peer_id, "canonical_start_required", "Start the equipped move through its canonical action.")
`);
replace('func set_opponent(encounter_id: String, opponent: Dictionary) -> bool:\n','func set_opponent(encounter_id: String, opponent: Dictionary) -> bool:\n\tif move_action_publication_pending(encounter_id): return false\n\tcancel_move_actions(encounter_id, "opponent_replaced")\n');
// Round reset preserves per-UID resources and original action receipts.
after=after.replaceAll('\t_strike_authority[encounter_id] = {}','\tif not _strike_authority.has(encounter_id): _strike_authority[encounter_id] = {}');
// Exact signatures differ by upstream, so locate the first executable line.
const hpStart=after.indexOf('func set_opponent_hp(');
const hpBody=after.indexOf('\n',after.indexOf(') -> void:',hpStart));
after=after.slice(0,hpBody)+'\n\tif move_action_publication_pending(encounter_id): return'+after.slice(hpBody);
replace('func set_phase(encounter_id: String, phase: String) -> void:\n',`func set_phase(encounter_id: String, phase: String) -> void:
\tif move_action_publication_pending(encounter_id): return
\tif phase != "active": cancel_move_actions(encounter_id, "phase_" + phase)
`);
replace('func close(encounter_id: String) -> void:\n','func close(encounter_id: String) -> void:\n\tif move_action_publication_pending(encounter_id): return\n\tcancel_move_actions(encounter_id, "closed")\n');
const closeStart=after.indexOf('func close('), closeEnd=after.indexOf('\n\nfunc ',closeStart+5);
const close=after.slice(closeStart,closeEnd).replace('\t_strike_authority.erase(encounter_id)\n','');
after=after.slice(0,closeStart)+close+after.slice(closeEnd);
replace('func forget(encounter_id: String) -> void:\n','func forget(encounter_id: String) -> void:\n\tif move_action_publication_pending(encounter_id): return\n');
replace('func leave(encounter_id: String, peer_id: int) -> Dictionary:\n', 'func leave(encounter_id: String, peer_id: int) -> Dictionary:\n\tif move_action_publication_pending(encounter_id): return _refuse("disengage", peer_id, "pending_action", "The original action is still settling.")\n\tcancel_move_actions_for_peer(encounter_id, peer_id, "withdrawn")\n');
replace('func bind_actor_vitals(encounter_id: String, peer_id: int, character_id: String,\n\t\towned_row: Dictionary, body_generation: int) -> Dictionary:\n','func bind_actor_vitals(encounter_id: String, peer_id: int, character_id: String,\n\t\towned_row: Dictionary, body_generation: int) -> Dictionary:\n\tif move_action_publication_pending(encounter_id): return {"ok": false, "code": "pending_action"}\n');
replace('\tvar actors: Dictionary = participant.get("actor_vitals", {})','\t_save_move_actor_wind(participant)\n\tvar old_uid := str(participant.get("actor_bound_uid", ""))\n\tvar old_generation := int(participant.get("actor_generation", 0))\n\tvar actors: Dictionary = participant.get("actor_vitals", {})');
replace('\treturn {"ok": true, "vitals": _actor_vitals_view(actor)}\n\nfunc bind_actor_body', '\t_move_actor_rebind(encounter_id, peer_id, old_uid, old_generation)\n\treturn {"ok": true, "vitals": _actor_vitals_view(actor)}\n\nfunc bind_actor_body');
// Every public mutation sharing seq/resources honors the original-outcome fence.
for (const [name, type, result] of [
  ['join','Dictionary','_refuse("engage", peer_id, "pending_action", "The original action is still settling.")'],
  ['authorize_burst','Dictionary','_refuse("burst_intent", peer_id, "pending_action", "The original action is still settling.")'],
  ['preview_wind','Dictionary','{}'], ['commit_wind','Dictionary','{}'],
  ['advance_wind','void',''], ['note_struck','void','']]) {
  const start=after.indexOf('func '+name+'(');
  if(start<0)throw Error('mutation absent '+name);
  const body=after.indexOf('\n',after.indexOf(') -> '+type+':',start));
  after=after.slice(0,body)+'\n\tif move_action_publication_pending(encounter_id): return'+(result?' '+result:'')+after.slice(body);
}
replace('\trow["wind_updated_ms"] = maxi(updated, now_ms)','\trow["wind_updated_ms"] = maxi(updated, now_ms)\n\t_save_move_actor_wind(row)');
replace('\treturn _ok("burst_intent", peer_id, delta)','\tvar active_actor := _move_action_actor(encounter_id, peer_id, now_ms)\n\tif not active_actor.is_empty(): (_actor_participant(encounter_id, peer_id).actor_vitals[str(active_actor.creature_uid)] as Dictionary)["burst_ready_at_ms"] = deadline_ms\n\treturn _ok("burst_intent", peer_id, delta)');
const burstStart=after.indexOf('func authorize_burst(');
const burstBody=after.indexOf('\n',after.indexOf(') -> Dictionary:',burstStart));
after=after.slice(0,burstBody)+'\n\tif _move_actions_enabled():\n\t\tvar current_actor := _move_action_actor(encounter_id, peer_id, now_ms)\n\t\tif current_actor.is_empty() or current_actor.state != "idle": return _refuse("burst_intent", peer_id, "committed", "Your creature is still committed to its move.")'+after.slice(burstBody);
replace('\trow["wind_ready_at_ms"] = now_ms + ceili(1000.0 * (maxf(0.0, recovery_seconds)\n\t\t+ maxf(0.0, regen_delay_seconds)))','\trow["wind_ready_at_ms"] = now_ms + ceili(1000.0 * (maxf(0.0, recovery_seconds)\n\t\t+ maxf(0.0, regen_delay_seconds)))\n\t_save_move_actor_wind(row)');
replace('func _authorize_actor_self_heal(intent: Dictionary, peer_id: int, view: Dictionary,\n\t\tmove: Dictionary, wind_profile: Dictionary) -> Dictionary:\n', 'func _authorize_actor_self_heal(intent: Dictionary, peer_id: int, view: Dictionary,\n\t\tmove: Dictionary, wind_profile: Dictionary) -> Dictionary:\n\tif MATH.config().get("move_loadout_runtime_enabled") == true: return _refuse("utility_intent", peer_id, "canonical_start_required", "Start the equipped utility through its canonical action.")\n');
replace('\t_strike_state_for(id)[peer_id] = {"last_action":action,"accepted_at_ms":now_ms,\n\t\t"deadline_ms":deadline,"cooldown_ms":lock_ms}', '\t_move_action_state(id, peer_id).merge({"last_action":action,"accepted_at_ms":now_ms,\n\t\t"deadline_ms":deadline,"cooldown_ms":lock_ms}, true)');
replace('func commit_actor_vitals(proposal: Dictionary) -> Dictionary:\n','func commit_actor_vitals(proposal: Dictionary) -> Dictionary:\n\tif move_action_publication_pending(str(proposal.get("encounter_id", ""))): return {"ok": false, "code": "pending_action"}\n\treturn _commit_actor_vitals_unfenced(proposal)\n\n\nfunc _commit_actor_vitals_unfenced(proposal: Dictionary) -> Dictionary:\n');
const originalAssignment='\t_strike_state_for(encounter_id)[peer_id] = {\n';
while(after.includes(originalAssignment)){
  const start=after.indexOf(originalAssignment);
  const end=after.indexOf('\n\t}',start);
  if(end<0)throw Error('deadline dictionary end absent');
  const fields=after.slice(start+originalAssignment.length,end);
  after=after.slice(0,start)+'\tvar preserved := _move_action_state(encounter_id, peer_id)\n\tpreserved.merge({\n'+fields+'\n\t}, true)'+after.slice(end+3);
}
after += fs.readFileSync('ralph/reports/COMBAT/f22/accepted-action-extension.gd.txt','utf8').replaceAll('\r\n','\n');
fs.writeFileSync(root+'/after/'+path,after);
const changes=[{path,before_sha256:hash(before),after_sha256:hash(after),source}];
const freeze=(file,input,bytes)=>{
  fs.mkdirSync(root+'/before/'+file.slice(0,file.lastIndexOf('/')),{recursive:true});
  const destination=root+'/before/'+file;
  if(!fs.existsSync(destination))fs.writeFileSync(destination,bytes??fs.readFileSync(input));
  return fs.readFileSync(destination,'utf8').replaceAll('\r\n','\n');
};
const output=(file,content,input)=>{
  fs.mkdirSync(root+'/after/'+file.slice(0,file.lastIndexOf('/')),{recursive:true});
  fs.writeFileSync(root+'/after/'+file,content);
  changes.push({path:file,before_sha256:hash(fs.readFileSync(root+'/before/'+file)),after_sha256:hash(content),source:input});
};
const directorPath='scripts/combat/encounter_director.gd';
let director=freeze(directorPath,directorPath);
const modifyDirector=(a,b)=>{if(!director.includes(a))throw Error('director frozen anchor '+a);director=director.replace(a,b);};
modifyDirector('\tmatch kind:\n','\tmatch kind:\n\t\t"move_action_start":\n\t\t\treturn _host_move_action_start(intent, peer_id)\n');
modifyDirector('\t_tick_encounter(delta)\n','\t_tick_encounter(delta)\n\t_tick_f22_move_actions()\n');
modifyDirector('\tvar card: Dictionary = _creature_card_for(peer_id)\n\tvar burst:', '\tvar card: Dictionary = _creature_card_for(peer_id)\n\tvar canonical_wind := COMBAT_MANAGER.host_wind_profile(card)\n\tif MATH.config().get("move_loadout_runtime_enabled") == true:\n\t\tvar actor_row: Dictionary = (_encounter_host.call("record", encounter_id) as Dictionary).get("participants", {}).get(peer_id, {})\n\t\tvar context := _f22_action_context(encounter_id, peer_id, str(actor_row.get("actor_bound_uid", "")))\n\t\tif context.is_empty(): return _f22_action_refuse("authority_unready", peer_id)\n\t\tcanonical_wind = context.wind_profile\n\tvar burst:');
modifyDirector('peer_id, intent, COMBAT_MANAGER.host_wind_profile(card),','peer_id, intent, canonical_wind,');
modifyDirector('func realm_transition_results_settled() -> bool:\n','func realm_transition_results_settled() -> bool:\n\tif _encounter_host != null:\n\t\tfor action_encounter: String in _encounter_host.get("encounters"):\n\t\t\tif _encounter_host.call("move_action_publication_pending", action_encounter): return false\n');
modifyDirector('\tif str(intent.get("kind", "")) in ["strike_intent", "burst_intent",\n','\tif str(intent.get("kind", "")) in ["move_action_start", "strike_intent", "burst_intent",\n');
modifyDirector('func _deliver_encounter_verdict(verdict: Dictionary) -> void:\n','func _deliver_encounter_verdict(verdict: Dictionary) -> void:\n\tif str(verdict.get("kind", "")) == "move_action_start" or (verdict.get("delta", {}) as Dictionary).get("phase") == "resolved":\n\t\tif _manager != null:\n\t\t\tif verdict.get("ok") == true: _manager.call("apply_host_move_action", verdict.get("delta", {}))\n\t\t\telse: _manager.call("note_encounter_refusal", verdict)\n\t\treturn\n');
director+=fs.readFileSync('ralph/reports/COMBAT/f22/accepted-action-director.gd.txt','utf8').replaceAll('\r\n','\n');
output(directorPath,director,'owned 0453683; frozen local source');
const masteryPath='scripts/creatures/move_mastery.gd';
// Governing helper is the actual ROOT-requested 39ca cut, not live later edits.
let mastery=freeze(masteryPath,null,execFileSync('git',['-C','D:/tetherbound/feature-f23','show','39ca697f87:'+masteryPath]));
const modifyMastery=(a,b)=>{if(!mastery.includes(a))throw Error('mastery frozen anchor '+a);mastery=mastery.replace(a,b);};
modifyMastery('\t\tvar effect_host := {"encounter_id": actor.encounter_id, "generation": actor.generation,','\t\tif not _whole_nonnegative(host.get("utility_generation")): return {"ok": false, "code": "invalid_utility_lifetime"}\n\t\tvar effect_host := {"encounter_id": actor.encounter_id, "generation": int(host.utility_generation),');
modifyMastery('\t\tif utility.get("ok") != true: return utility\n\t\tstatus = utility.state', '\t\tif utility.get("ok") != true:\n\t\t\t# An actual ineffective arrival settles once, without a later reroll.\n\t\t\tif utility.get("code") not in ["miss", "out_of_range", "immune", "already_full"]: return utility\n\t\t\tconnected = false\n\t\telse:\n\t\t\tstatus = utility.state');
output(masteryPath,mastery,'F23 actual39ca697f87; ROOT-requested governing cut, later71bf requires composition');
const managerPath='scripts/combat/combat_manager.gd';
let manager=freeze(managerPath,'D:/tetherbound/feature-f23/.tmp/shared/after/'+managerPath);
if(!manager.includes('"creature_uid": str(creature.uid), "slot": slot, "move_id": move_id})'))throw Error('manager intent anchor');
manager=manager.replace('"creature_uid": str(creature.uid), "slot": slot, "move_id": move_id})','"creature_uid": str(creature.uid), "slot": slot, "move_id": move_id,\n\t\t"start_token": str((_encounter_link.call("local_move_action_view", _encounter_id, str(creature.uid)) as Dictionary).get("start_token", ""))})');
const resolved='\t_f23_pending_action.clear()\n\t_pending_move = {}\n\tstate_changed.emit()';
if(!manager.includes(resolved))throw Error('manager terminal resolution anchor');
manager=manager.replace(resolved,resolved+'\n\t# Actual durable host kill is already captured/published. Resolve the\n\t# presentation/round without calling legacy XP/care/bond award writers.\n\tif delta.get("killed") == true: _begin_resolve("won")');
output(managerPath,manager,'F23 frozen shared manager proposal; token + canonical terminal resolution ONLY, root F21/F24/F25 composition remains');
let patch='';
for(const change of changes){
  try{patch+=execFileSync('git',['diff','--no-index','--',root+'/before/'+change.path,root+'/after/'+change.path],{encoding:'utf8'});}catch(e){if(e.status!==1)throw e;patch+=e.stdout;}
}
fs.writeFileSync(root+'/proposal.patch',patch);
const cut={kind:'ignored exact accepted-action source proposal; no activation, parse, engine or MET',
  foundation_input:source,input_sha256:hash(before),current_foundation_input_sha256:hash(fs.readFileSync(source)),
  changes,patch};
fs.writeFileSync(root+'/source-cut.patch.json',JSON.stringify(cut,null,2)+'\n');
fs.writeFileSync('ralph/reports/COMBAT/f22/accepted-action-source-cut.json',JSON.stringify({
  ...cut,patch:undefined,source_cut:root+'/source-cut.patch.json',source_cut_sha256:hash(fs.readFileSync(root+'/source-cut.patch.json'))},null,2)+'\n');
console.log(JSON.stringify({changes,source_cut_sha256:hash(fs.readFileSync(root+'/source-cut.patch.json'))}));
