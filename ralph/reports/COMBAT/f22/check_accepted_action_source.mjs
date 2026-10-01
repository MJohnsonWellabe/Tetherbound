// Named bounded SOURCE check only; no GDScript parser, execution or simulation.
import fs from 'node:fs';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
const root='.tmp/f22-accepted-actions';
const sha=x=>crypto.createHash('sha256').update(x).digest('hex');
const report=JSON.parse(fs.readFileSync('ralph/reports/COMBAT/f22/accepted-action-source-cut.json'));
const packet=JSON.parse(fs.readFileSync(root+'/source-cut.patch.json'));
assert.equal(sha(fs.readFileSync(root+'/source-cut.patch.json')),report.source_cut_sha256);
assert.equal(packet.changes.length,4);
assert.equal(packet.input_sha256,sha(fs.readFileSync(packet.foundation_input)),'Foundation input changed; do not silently rebase');
for(const row of packet.changes){
  assert.equal(sha(fs.readFileSync(root+'/before/'+row.path)),row.before_sha256);
  assert.equal(sha(fs.readFileSync(root+'/after/'+row.path)),row.after_sha256);
  const source=fs.readFileSync(root+'/after/'+row.path,'utf8');
  const functions=[...source.matchAll(/^(?:static )?func (\w+)\(/gm)].map(x=>x[1]);
  assert.equal(new Set(functions).size,functions.length,'duplicate function '+row.path);
}
const host=fs.readFileSync(root+'/after/scripts/net/encounter_host.gd','utf8');
for(const token of ['accepted_actions','start_token','_freeze_action_value(bundle)','release_move_action',
  'stage_move_action_outcome','publish_move_action_outcome','ACTION_COMMANDS.stage_landed',
  'command_meter_credited','receipt_budget','move_action_publication_pending','visual_cancel_pending',
  'delivery_pending','acknowledge_move_action_delivery','out.erase("settled_revision")',
  'UTILITY_EFFECTS.empty_state(id, 0)','_save_move_actor_wind','_move_actor_rebind']) assert(host.includes(token),token);
assert(!host.includes('_strike_state_for(encounter_id)[peer_id] = {'),'legacy assignment overwrites map');
assert(!host.includes('_strike_state_for(id)[peer_id] = {'),'legacy heal overwrites map');
const mastery=fs.readFileSync(root+'/after/scripts/creatures/move_mastery.gd','utf8');
assert(mastery.includes('"generation": int(host.utility_generation)'));
assert(mastery.includes('["miss", "out_of_range", "immune", "already_full"]'));
const director=fs.readFileSync(root+'/after/scripts/combat/encounter_director.gd','utf8');
for(const token of ['_host_move_action_context','_commit_host_move_action_outcome','_tick_f22_move_actions()',
  'F22_ACTION_TRAVEL.launch','"source_ground"','"target_ground"','confirm_impact',
  '_capture_wild_victory_source(id, verdict)','acknowledge_move_action_delivery']) assert(director.includes(token),token);
const cfg=JSON.parse(fs.readFileSync('data/config/combat.json'));
const manager=fs.readFileSync(root+'/after/scripts/combat/combat_manager.gd','utf8');
assert(manager.includes('if delta.get("killed") == true: _begin_resolve("won")'),'killing move must finish current manager/round');
assert.equal(cfg.patterns.runtime_enabled,false);assert.equal(cfg.actor_vitals.runtime_enabled,false);
console.log('PASS SOURCE ONLY: exact 4-path ignored cut, original-state/fence/marker hooks and OFF flags; no parse/engine/runtime/MET.');
