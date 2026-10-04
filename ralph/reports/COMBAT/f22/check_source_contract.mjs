import fs from 'node:fs';
import {execFileSync} from 'node:child_process';
import crypto from 'node:crypto';
const hash = x=>crypto.createHash('sha256').update(x).digest('hex');
const path='data/config/combat.json';
const original=JSON.parse(execFileSync('git',['show','HEAD:'+path],{encoding:'utf8'}));
const current=JSON.parse(fs.readFileSync(path,'utf8'));
const patterns=current.patterns;
const errors=[];
const check=(value,message)=>{if(!value)errors.push(message)};
delete current.patterns;
delete original.patterns;
check(JSON.stringify(original)===JSON.stringify(current),'Non-owned combat blocks changed');
check(patterns.runtime_enabled===false,'Source candidate enabled without actual proof');
for(const [role,ids] of Object.entries(patterns.roles)) {
  check(ids.length>=2,role+' has fewer than two attacks');
  check(new Set(ids).size===ids.length,role+' repeats an attack ID');
  for(const id of ids)check(patterns.attacks[id]?.role===role,role+' attack belongs to another role: '+id);
}
for(const [id,row] of Object.entries(patterns.attacks)) {
  check(['cone','lane','ring','marker','fan','field'].includes(row.telegraph_shape),id+' unknown geometry');
  check(row.telegraph>=(row.heavy?1.1:0.8),id+' below tell floor');
  check(row.recovery>=0.6,id+' below recovery floor');
  check(['quick','charged'].includes(row.slot),id+' missing owned move binding');
  check(typeof row.safe_escape==='string'&&row.safe_escape.length>0,id+' lacks safe answer');
  check(!('power' in row)&&!('damage_scale' in row)&&!('max_hp' in row),id+' changes stats');
  if(row.repeat_count)check(row.repeat_recovery_s>=0.6&&row.repeat_telegraph_s>=1.1,id+' repeats without a complete read/recovery');
  if(row.telegraph_shape==='lane')check(row.lunge>0&&row.lane_half_width_m>0,id+' has empty lane');
  if(['marker','field'].includes(row.telegraph_shape))check(row.marker_radius_m>0,id+' has empty marker');
}
const encounters=new Set();
for(const [id,row] of Object.entries(patterns.named)) {
  check(row.pattern_id===id,id+' mismatched pattern_id');
  check(!encounters.has(row.encounter_id),id+' shares a named encounter');encounters.add(row.encounter_id);
  check(row.kernel.length>10&&row.sendouts.length>0,id+' missing authored kernel/roster');
  for(const sendout of row.sendouts) {
    check(sendout.sequence.length>0,id+' empty sendout');
    for(const attack of sendout.sequence)check(Boolean(patterns.attacks[attack]),id+' unknown attack '+attack);
  }
}
for(const id of ['warden_aldis','relay_officer_dell','relay_captain','captain_riverwatch','captain_field','captain_ridge','stronghold_elite','tether_lieutenant_senn','keeper_maela_trial','officer_voss_summit_approach','water_trainer_nerissa','water_trainer_venn','captain_veyra_storm_anchor','captain_marrow_dynamo_core'])check(encounters.has(id),'Missing required named '+id);
for(const row of Object.values(patterns.named))for(const sendout of row.sendouts) {
  if(sendout.role==='ACE')check(new Set(sendout.sequence.map(id=>patterns.attacks[id].role)).size>=2,row.encounter_id+' ACE lacks two role patterns');
}
check(patterns.proof.seeds_per_band>=12,'F22 proof fewer than 12 seeds');
check(patterns.proof.reader_win_min>=0.9,'F22 reader bar weakened');
const files=['scripts/combat/combat_ai.gd','scripts/combat/encounter_director.gd','scripts/combat/enemy_pattern_telegraph.gd','scripts/combat/enemy_pattern_cast.gd','tests/helpers/f22_pattern_pilot.gd','tests/smoke_f22_pattern_bands.gd','tests/smoke_f22_pattern_contract.gd','tests/smoke_meadows_named_c2c3.gd',path];
const sources=Object.fromEntries(files.map(p=>[p,hash(fs.readFileSync(p))]));
const receipt={kind:'cheap source structure/ownership check; not GDScript parse or engine/gameplay proof',ok:errors.length===0,roles:Object.keys(patterns.roles).length,attacks:Object.keys(patterns.attacks).length,species:Object.keys(patterns.species_roles).length,named:encounters.size,source_sha256:sources,errors};
fs.writeFileSync('ralph/reports/COMBAT/f22/source-contract.json',JSON.stringify(receipt,null,2)+'\n');
console.log(JSON.stringify(receipt));
process.exitCode=errors.length?1:0;
