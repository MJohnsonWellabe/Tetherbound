// Reproducible F22 authored data. Preserves every existing combat block verbatim.
import fs from 'node:fs';
import path from 'node:path';
const root = process.cwd();
const read = p => JSON.parse(fs.readFileSync(path.join(root,p),'utf8'));
const aliases = {
  WALL:['anchor','tank','wall','bulwark','guardian','counter','interceptor'],
  CHARGER:['bruiser','breaker','gap-closer','punisher'],
  DIVER:['diver','dive','duelist','ambusher','skirmisher','harrier','flanker','pursuit','hunter','scout','runner','spotter','disruptor'],
  CURRENT:['controller','current','ranged','screen','zone','trapper','sweeper','artillery','support','decoy','kiter']
};
const roleOf = text => Object.keys(aliases).find(k=>aliases[k].some(s=>text.toLowerCase().replaceAll('_','-').includes(s))) ?? '';
const speciesRoles = {};
for (const line of fs.readFileSync('docs/design/CREATURES.md','utf8').split('\n')) {
  const columns = line.split('|').map(x=>x.trim());
  const id = columns[1]?.match(/^`([a-z_]+)`$/)?.[1];
  if (!id) continue;
  const role = roleOf(columns.length === 10 ? columns[8].split(';')[0] : columns[6]);
  if (role) speciesRoles[id] = role;
}
// Namespaced Water semantics are current data; normalize underscores before matching.
const water = read('data/config/water_roster.json');
const walk = value => {
  if (Array.isArray(value)) value.forEach(walk);
  else if (value && typeof value === 'object') {
    if (value.id && value.combat_role) {
      const role = roleOf(value.combat_role.replaceAll('_',' '));
      if (!role) throw Error('unmatched role '+value.id);
      speciesRoles[value.id] = role;
    }
    Object.values(value).forEach(walk);
  }
};
walk(water);
const attack = (role, slot, shape, tell, recover, reach, extra={}) => ({
  role,slot,telegraph_shape:shape,telegraph:tell,recovery:recover,
  heavy:slot==='charged',range:reach,cone_degrees:80,lunge:0,
  face_lock_fraction:0.5,attack_cooldown:1.2,reposition_time:0.8,
  reposition_speed:3.8,preferred_range:Math.max(2.5,reach-1),
  safe_escape:shape==='cone'?'side':shape==='lane'?'side':shape==='fan'?'lateral':'outside',
  ...extra
});
const attacks = {
  wall_slam:attack('WALL','charged','cone',1.1,1.2,5,{cone_degrees:85,chase_speed:3.4,reposition_speed:2.5}),
  wall_quake:attack('WALL','charged','ring',1.2,1.25,5.5,{inner_radius_m:0,chase_speed:3.4,reposition_speed:2.5}),
  wall_check:attack('WALL','quick','cone',0.9,0.9,3,{cone_degrees:70,chase_speed:3.4,reposition_speed:2.5}),
  charger_rush:attack('CHARGER','quick','lane',0.9,0.9,7,{lunge:7,lunge_travels:true,lane_half_width_m:1.2,preferred_range:4.5,reposition_time:0.65}),
  charger_double_rush:attack('CHARGER','charged','lane',1.1,1.2,7,{lunge:7,lunge_travels:true,lane_half_width_m:1.2,preferred_range:4.5,repeat_count:2,repeat_reaim_s:0.3,repeat_telegraph_s:1.1,repeat_recovery_s:0.6}),
  charger_check:attack('CHARGER','quick','cone',0.9,0.8,3.5,{cone_degrees:70}),
  diver_leap:attack('DIVER','charged','marker',1.1,1.0,6,{marker_radius_m:2,marker_tracks_fraction:0.5,preferred_range:5.5,lunge:5.5,reposition_time:1.6,reposition_speed:7,reposition_distance:7}),
  diver_retreat:attack('DIVER','quick','cone',0.9,0.8,3.5,{cone_degrees:65,preferred_range:3,retreat_distance_m:3,reposition_time:1.2,reposition_speed:5.5,reposition_distance:6}),
  current_volley:attack('CURRENT','quick','fan',0.9,0.8,8,{cone_degrees:60,projectile_count:3,projectile_spacing_degrees:20,preferred_range:6,reposition_time:0.5,reposition_speed:4}),
  current_zone:attack('CURRENT','charged','field',1.1,0.9,8,{marker_radius_m:2.5,marker_tracks_fraction:0.5,field_duration_s:3,field_hits_per_cast:1,preferred_range:6,reposition_time:0.5}),
  ace_lane:attack('ACE','charged','lane',1.1,1.2,6,{lunge:6,lunge_travels:true,lane_half_width_m:1.3,preferred_range:4.5,first_attack_delay:2.5}),
  ace_exam:attack('ACE','charged','cone',1.2,1.3,6,{cone_degrees:90,preferred_range:4.5,first_attack_delay:2.5}),
  guardian_earth_fist:attack('WALL','charged','cone',1.1,1.2,5,{cone_degrees:85,move_override:'earth_fist',armored_front_degrees:85,front_damage_scale:0.5}),
  hald_reset:attack('WALL','quick','cone',1.0,1.1,4,{reposition_time:1.2,reposition_speed:2.5}),
  oreth_pressure:attack('CURRENT','quick','fan',0.9,0.85,8,{cone_degrees:50,projectile_count:3,projectile_spacing_degrees:16,reposition_time:0.5}),
  halder_range:attack('CHARGER','quick','lane',1.0,1.0,7,{lunge:7,lunge_travels:true,lane_half_width_m:1,preferred_range:5}),
  vess_flank:attack('DIVER','charged','marker',1.1,1.0,6,{marker_radius_m:1.75,reposition_time:1.6,reposition_speed:7,preferred_range:5.5}),
  aquaryn_wake:attack('CURRENT','charged','lane',1.2,1.2,8,{lunge:8,lane_half_width_m:1.5,preferred_range:6}),
  tidecoil_sweep:attack('CURRENT','quick','fan',1.1,1.2,8,{cone_degrees:100,attack_cooldown:1.0,active_s:0.8,eddy_every:3,eddy_duration_s:2,low_hp:{threshold:0.5,attack_cooldown:0.8,eddy_every:2}}),
  nerissa_lane:attack('CHARGER','charged','lane',1.1,0.9,7,{lunge:7,lunge_travels:true,lane_half_width_m:1.2,preferred_range:4.5}),
  veyra_crosswind:attack('CURRENT','quick','fan',1.0,1.0,8,{cone_degrees:70,projectile_count:3,projectile_spacing_degrees:23,preferred_range:6}),
  marrow_bank_answer:attack('ACE','charged','ring',1.2,1.3,5,{inner_radius_m:2,safe_escape:'outside_or_center'})
};
const roles = {
  WALL:['wall_check','wall_slam','wall_quake'],CHARGER:['charger_rush','charger_double_rush','charger_check'],
  DIVER:['diver_retreat','diver_leap'],CURRENT:['current_volley','current_zone'],ACE:['ace_lane','ace_exam']
};
const named = {};
const add = (id,chapter,kernel,sequences,mechanic={}) => {
  const patternId = 'named_'+id;
  named[patternId] = {encounter_id:id,pattern_id:patternId,chapter,kernel,
    sendouts:sequences.map(sequence=>({sequence})),mechanic};
};
add('warrens_guardian','meadows','Sidestep armored front; Earth Fist final cone',[['wall_check','guardian_earth_fist']]);
add('relay_officer_dell','meadows','Two anchored checks then an aerial landing answer',[
  ['wall_check','wall_slam'],['wall_check','wall_quake'],['diver_leap','diver_retreat']]);
add('tether_lieutenant_senn','cloudreach','Disruptor landing followed by a pursuer double lane',[
  ['diver_leap','diver_retreat'],['charger_rush','charger_double_rush']]);
add('keeper_maela_trial','cloudreach','Crosswind sector, marked field, then aerial recovery lesson',[
  ['veyra_crosswind','current_zone'],['diver_leap','diver_retreat']]);
add('officer_voss_summit_approach','cloudreach','Narrow edge denial, heavy pursuit, then ranged switching exam',[
  ['halder_range','charger_check'],['charger_double_rush','charger_check'],['current_zone','current_volley']]);
add('relay_captain','meadows','Air spacing, flank reset, three-type team and charge lane',[
  ['diver_leap','diver_retreat'],['diver_retreat','current_zone'],['wall_check','wall_quake'],['wall_check','wall_slam'],['charger_rush','charger_double_rush']]);
add('captain_riverwatch','meadows','Patience then sustained pressure',[
  ['wall_check','wall_slam'],['oreth_pressure','current_zone'],['diver_retreat','diver_leap'],['wall_check','wall_quake'],['oreth_pressure','current_volley']]);
add('captain_field','meadows','Range control; long narrow charge',[
  ['current_volley','current_zone'],['halder_range','charger_double_rush'],['wall_check','wall_quake'],['diver_retreat','diver_leap'],['charger_check','halder_range']]);
add('captain_ridge','meadows','Endurance with a flank/landing ace',[
  ['wall_check','wall_quake'],['current_volley','current_zone'],['charger_check','charger_rush'],['wall_check','wall_slam'],['diver_retreat','vess_flank']]);
add('stronghold_elite','meadows','Movement, reset, patient punish',[
  ['diver_leap','diver_retreat'],['hald_reset','wall_slam'],['diver_retreat','diver_leap'],['current_volley','current_zone'],['hald_reset','wall_quake']]);
add('warden_aldis','meadows','Four learned shapes then Earth Fist exam',[
  ['wall_check','wall_quake'],['diver_retreat','diver_leap'],['charger_rush','charger_double_rush'],['current_volley','current_zone'],['guardian_earth_fist','charger_rush','ace_exam']]);
add('water_aquaryn_alpha','water','Three visible shore/wake phases',[['diver_retreat','aquaryn_wake','diver_leap']],{controller:'aquaryn',phases:['shore','wake','surface_routes']});
add('water_deep_watch_tidecoil','water','Lateral sweep and sheltered eddy',[['tidecoil_sweep']],{controller:'tidecoil',hp_threshold:0.5});
add('water_trainer_venn','water','Wall space, charge lane, current finish',[
  ['wall_check','wall_quake'],['charger_rush','charger_double_rush'],['current_volley','current_zone']]);
add('water_trainer_nerissa','water','Interleaved side-channel sweeps and Pressure Rise',[
  ['wall_check','wall_slam'],['wall_check','wall_quake'],['current_volley','current_zone'],['charger_check','current_zone','nerissa_lane']],
  {controller:'water_veilfall',phases:['channel_cycle','pressure_rise','break_tether'],safe_area_fraction:0.5,suppress_unescapable:true});
add('captain_veyra_storm_anchor','cloudreach','Crosswind, overload, relay movement exam',[
  ['veyra_crosswind','current_zone'],['diver_retreat','diver_leap'],['diver_leap','current_zone','veyra_crosswind']],
  {controller:'cloudreach_anchor',phases:['crosswind','anchor_overload','break_eye']});
add('captain_marrow_dynamo_core','stormwood','Capacitor banks, Overload, four-conduit Break',[
  ['wall_check','wall_quake'],['diver_leap','diver_retreat'],['current_volley','current_zone'],['charger_check','charger_rush'],['wall_quake','charger_rush','marrow_bank_answer']],
  {controller:'stormwood_dynamo',phases:['bank_cycle','overload','break_core'],break_countdown_s:36,distinct_conduits:4});
// Relay officers each ask a different position question; sequence is authored
// from actual ordered roster, without touching F19 level/reward ownership.
for (const [file,chapter] of [['data/config/cloudreach_encounters.json','cloudreach'],['data/config/stormwood_trainers.json','stormwood']]) {
  const catalog = read(file);
  const candidates = [];
  const visit = value => {
    if (Array.isArray(value)) value.forEach(visit);
    else if(value && typeof value==='object') {
      if(value.id && /officer|lieutenant|keeper/.test(value.id) && (value.team || value.party)) candidates.push(value);
      Object.values(value).forEach(visit);
    }
  };
  visit(catalog);
  for(const row of candidates) {
    const team = row.team ?? row.party;
    const index = Object.keys(named).length;
    add(row.id,chapter,'Ordered relay spacing exam '+row.id,team.map((member,i)=>{
      const id = member.species ?? member.species_id ?? member.placeholder_species;
      const role = speciesRoles[id];
      if(!role) throw Error('no role for named member '+id);
      const set = roles[role];
      const shift = (index+i)%set.length;
      return [...set.slice(shift),...set.slice(0,shift)];
    }),{controller:'existing_relay',relay_id:row.id});
  }
}
for(const id of ['warden_aldis','water_trainer_nerissa','captain_veyra_storm_anchor','captain_marrow_dynamo_core']) {
  const rows=named['named_'+id].sendouts;
  rows[rows.length-1].role='ACE';
}
const patterns = {
  schema_version:1,runtime_enabled:false,
  _activation:'F22 source candidate. Enable only after ROOT integrates actual geometry/node/actor contracts and named engine/player/code-blind proofs pass.',
  role_aliases:aliases,species_roles:speciesRoles,roles,attacks,named,
  heavy_tell_floor_s:1.1,
  chapter_floors:{meadows:{telegraph:1,recovery:0.9},meadows_late:{telegraph:0.9,recovery:0.75},water:{telegraph:0.85,recovery:0.7},cloudreach:{telegraph:0.8,recovery:0.6},stormwood:{telegraph:0.8,recovery:0.6}},
  reactions:{observation_s:0.25,dodge_min_range_m:3,wild_dodge_cooldown_s:6,trainer_dodge_cooldown_s:6,mobile_trainer_dodge_cooldown_s:4,dodge_distance_m:3,dodge_duration_s:0.2},
  low_hp_fraction:0.3,low_hp_tradeoffs:{WALL:{telegraph_add_s:0.2},DIVER:{reposition_add_s:0.4},CURRENT:{reposition_add_s:-0.2,third_recovery_add_s:0.15}},
  presentation:{ground_lift_m:0.09,segments:48,fill_alpha:0.18,edge_width_m:0.12},
  casts:{fan_travel_s:0.3,leap_travel_s:0.45,leap_height_m:0.75},settlement:{retry_s:1},
  proof:{seeds_per_band:12,reader_win_min:0.9,masher_lead_faint_gap_min:0.25,switch_reader_hp_ratio_max:0.9,named_top_seeds:24,codeblind_roles:['WALL','CHARGER','DIVER','CURRENT','ACE']}
};
const file='data/config/combat.json';
let before=fs.readFileSync(file,'utf8');
const original=JSON.parse(before);
if(original.patterns) {
  const start=before.lastIndexOf(',\n  "patterns":');
  if(start<0)throw Error('owned patterns boundary changed');
  before=before.slice(0,start)+'\n}\n';
}
const insert=',\n  "patterns": '+JSON.stringify(patterns,null,2).replaceAll('\n','\n  ')+'\n';
fs.writeFileSync(file,before.replace(/\s*}\s*$/,insert+'}\n'));
console.log(JSON.stringify({roles:Object.keys(roles),species:Object.keys(speciesRoles).length,attacks:Object.keys(attacks).length,named:Object.keys(named).length}));
