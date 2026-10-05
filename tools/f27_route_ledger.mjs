import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {fileURLToPath} from 'node:url';
import {ROOT, authoredCurve, levelCost} from './economy_ledger.mjs';

// F27#5 route ledger (PROGRESSION §7 "Essence ledger", TRAINING §1). Read-only
// source arithmetic over authored data: it never tunes game data and is not an
// earned-clear, engine or owner acceptance proof. Every modelling choice that is
// not a source fact is a named constant below and is echoed in report.assumptions.

// ---- Ordinary-path assumptions --------------------------------------------------
// F07 Cloudreach route-ledger precedent (ralph/reports/CLOUDREACH-LANE/f07-route-ledger):
// an ordinary player engages half of the authored wild sites along the main path,
// one defeat per engaged site, and never fights a respawn.
export const ORDINARY_WILD_SITE_FRACTION = 0.5;
export const DEFEATS_PER_ENGAGED_SITE = 1;
// Sensitivity only (not the verdict): a player who engages a quarter of the sites.
export const SENSITIVITY_WILD_SITE_FRACTION = 0.25;
// Tables give ranges; the runtime rolls uniformly. Use floor(midpoint) (conservative
// for the floor(level/10) essence bonus). Fixed authored levels are used as is.
export const WILD_LEVEL_POLICY = 'floor_of_band_midpoint';
// Who lands the killing blow (full award); the other four take the share award.
export const ACTIVE_POLICY = 'round_robin_over_the_five';
export const TEAM_SIZE = 5;
// The starter and the four early catches all enter Meadows at the starter level.
export const STARTING_TEAM_LEVEL = 3;
// Masters supply breakthroughs: each tier's cap lift is fed at the start of the
// region holding its Master (Meadows, from master position z) or at the start of
// its biome (other biomes). Breakthroughs themselves are F28 and are assumed here.
export const BREAKTHROUGH_TIMING = 'cap_lift_at_master_region_or_biome_start';
// PROGRESSION §4 planning estimate lower bounds (opening + Meadows 5–7 h, others 3.5–6 h).
export const TIME_BUDGET_LOW_HOURS = {meadows:5, tidewake:3.5, cloudreach:3.5, stormwood:3.5};
// CODEX_START_HERE §2 core loop is 15–30 minutes, Home Key back each loop: one home
// visit per 30 minutes; each visit lands on a new 600 s world day, grooming all five.
export const CARE_HOME_VISITS_PER_HOUR = 2;
// Research tasks the ordinary path completes by itself: first wild meeting (sight)
// and the third wild defeat of a species. Signature-cast tasks are excluded.
export const RESEARCH_ORDINARY_TASK_KINDS = ['sight','defeat'];
// Master duel XP is not credited (1v1 award path unmeasured); only its authored candy.
export const MASTER_FIGHT_XP_CREDITED = false;
// Mismatch scenario: a plausible starter-led team caught in the Meadows.
export const PLAUSIBLE_TEAM = [
  {species:'terrapup',types:['ground']},{species:'mosshell',types:['water']},
  {species:'galecrest',types:['air']},{species:'mudsnout',types:['ground']},{species:'pipwing',types:['air']}];
// Optional content excluded from the ordinary path.
export const OPTIONAL_MEADOWS_TRAINERS = {
  old_champion_bram:"band1 trainers.json: band1's answer to prompt 62's 'optional thing [that] tempts the player away'",
  patrol_ridgeline:"band4 trainers.json: prompt 65's 'meaningful optional trainer... competing with the captain route'"};
export const OPTIONAL_TIDEWAKE_ISLANDS = {
  lantern_cove:'side island: its only trainer is critical:false and its named encounter optional:true',
  gull_rest:'side island: its only trainer is critical:false and its named encounter optional:true',
  drowned_garden:'side island: its only trainer is critical:false and its named encounter optional:true',
  deep_watch:'side island: its only trainer is critical:false and its named encounter optional:true'};
// On-route found-candy classification per source schema.
export const ON_ROUTE_CANDY_RULES = {
  meadows:'band pickups tier === "critical" (side/detour/secret are optional)',
  tidewake:'water_pickups off_main_route === false (every authored candy is off_main_route:true)',
  cloudreach:'cloudreach_chapter pickups placement === "route_verge" in a non-optional region',
  stormwood:'stormwood_pickups placement === "critical_route_verge"'};
// ---- Optional-grind assumptions (minutes of real play per action) ---------------
export const GRIND_HOURS = 1;
export const MINUTES_PER_WILD_REFIGHT = 1.5;
export const MINUTES_PER_ALPHA = 5;
export const MINUTES_PER_CATCH_RELEASE = 3;
export const ORBS_PER_SUCCESSFUL_CATCH = 2;
export const MINUTES_PER_NODE_HARVEST = 2;
export const MINUTES_PER_BOUNTY = 10;
export const WILD_SITE_RETURN_DAYS = 2; // WORLD §2.5

const digest = bytes => crypto.createHash('sha256').update(bytes).digest('hex');

// ---- Faithful ports of scripts/creatures/progression.gd and essence.gd ----------
export function xpToNext(level, prog) {
  const base = prog.level?.xp_to_next_base ?? 40, exponent = prog.level?.xp_to_next_exponent ?? 1.6;
  return Math.trunc(base * Math.pow(Math.max(level,1), exponent)); // GDScript int() truncates
}
export function rawXpAward(enemyLevel, prog) {
  const base = prog.xp_award?.base ?? 18, per = prog.xp_award?.per_enemy_level ?? 6;
  if (enemyLevel < 1 || enemyLevel > 100) return 0;
  if (![base,per].every(v=>Number.isFinite(v)&&v>=0)) return 0;
  const amount = base + per * enemyLevel;
  return Number.isFinite(amount) && amount <= 2147483647 ? Math.floor(amount) : 0;
}
export function scaledCombatXp(enemyLevel, prog, ess) {
  const raw = ess.auto_xp_scale;
  if (!Number.isFinite(raw) || raw <= 0 || raw >= 1) return 0;
  const amount = rawXpAward(enemyLevel, prog);
  return amount > 0 ? Math.max(1, Math.floor(amount * raw)) : 0;
}
export function partyShare(amount, prog) {
  return Math.floor(amount * (prog.xp_award?.party_share ?? 0.35));
}
export function scaledPartyCombatXp(enemyLevel, prog, ess) {
  const award = scaledCombatXp(enemyLevel, prog, ess);
  if (award <= 0) return 0;
  const share = prog.xp_award?.party_share ?? 0.35;
  if (!Number.isFinite(share) || share <= 0 || share > 1) return 0;
  return Math.max(1, Math.floor(award * share));
}
// staged_xp: level-ups until the cap; at the cap XP is discarded (never banked).
export function stagedXp(row, cap, amount, prog) {
  if (cap < 1 || cap > 100 || amount <= 0 || row.level > cap) throw Error('Invalid staged XP');
  const out = {...row};
  if (out.level === cap) {out.xp = 0; return out;}
  let remaining = out.xp + amount;
  while (out.level < cap) {
    const needed = xpToNext(out.level, prog);
    if (remaining < needed) break;
    remaining -= needed; out.level += 1;
  }
  out.xp = out.level === cap ? 0 : remaining;
  return out;
}
// staged_combat_party_xp in "hybrid": active gets scaled award, others the scaled share.
export function combatPartyXp(team, activeIndex, enemyLevel, cap, prog, ess, mode = ess.wild_victory_xp_mode) {
  if (!['ordinary','hybrid'].includes(mode)) throw Error('Invalid XP mode');
  const full = mode === 'ordinary' ? rawXpAward(enemyLevel,prog) : scaledCombatXp(enemyLevel,prog,ess);
  const share = mode === 'ordinary' ? partyShare(full,prog) : scaledPartyCombatXp(enemyLevel,prog,ess);
  if (full <= 0 || share <= 0) throw Error('Non-positive combat XP');
  return team.map((m,i)=>stagedXp(m, cap, i===activeIndex ? full : share, prog));
}
export function splitPayout(types, total) {
  if (!types.length || types.length > 2 || total < 1) return [];
  const half = Math.floor(total/2);
  return types.map((t,i)=>({type:t,n:types.length===1?total:(i===0?total-half:half)})).filter(r=>r.n>0);
}
export function defeatPayout(level, types, ess) {
  if (!Number.isInteger(level) || level < 1 || level > 100) return [];
  return splitPayout(types, ess.defeat_essence_base + Math.floor(level / ess.defeat_bonus_level_interval));
}
export function releasePayout(level, types, ess) {
  const raw = ess.release_essence_base + ess.release_essence_per_level * level;
  if (!Number.isFinite(raw) || raw < 1) return [];
  return splitPayout(types, Math.floor(raw));
}
export {levelCost};

// ---- Team simulation ------------------------------------------------------------
// Essence is spent on the lowest creature able to pay (lowest level first); Tether
// Candy pays a whole level for anyone; found candies (level_up) feed the lowest.
export function simulate(start, events, opts) {
  const {prog, ess, wildcard} = opts;
  const team = start.team.map(m=>({...m}));
  const pool = {...start.pool};
  let tetherCandy = start.tetherCandy, rot = start.rot, cap = start.cap;
  const research = start.research; // shared mutable per-run research state
  const tally = {defeats:0,wild_defeats:0,trainer_defeats:0,xp_events:0,essence:{},
    tether_candy:0,candy_levels:0,care:0,research:0,completion_xp:0,release:0};
  const addEss = (type,n,src)=>{const k=wildcard?'any':type;pool[k]=(pool[k]??0)+n;tally.essence[type]=(tally.essence[type]??0)+n;if(src)tally[src]+=n;};
  for (const e of events) {
    if (e.kind === 'cap') {cap = Math.max(cap, e.cap); continue;}
    if (e.kind === 'defeat') {
      const updated = combatPartyXp(team, rot % team.length, e.level, cap, prog, ess);
      updated.forEach((m,i)=>Object.assign(team[i],{level:m.level,xp:m.xp}));
      rot++; tally.defeats++;
      if (e.essence) {
        tally.wild_defeats++;
        for (const p of defeatPayout(e.level, e.types, ess)) addEss(p.type,p.n);
        if (research && e.species) {
          const r = research.get(e.species) ?? {seen:false,defeats:0};
          if (!r.seen && RESEARCH_ORDINARY_TASK_KINDS.includes('sight')) {r.seen=true; payResearch(e.species,'sight');}
          r.defeats++;
          if (r.defeats===3 && RESEARCH_ORDINARY_TASK_KINDS.includes('defeat')) payResearch(e.species,'defeat');
          research.set(e.species,r);
        }
      } else tally.trainer_defeats++;
      continue;
    }
    if (e.kind === 'xp_all') {
      for (const m of team) Object.assign(m, stagedXp(m, cap, e.amount, prog));
      tally.completion_xp += e.amount; continue;
    }
    if (e.kind === 'candy_levels') {
      for (let k=0;k<e.levels;k++) {const m=lowest(team,cap); if(!m) break; m.level++; if(m.level===cap) m.xp=0; tally.candy_levels++;}
      continue;
    }
    if (e.kind === 'tether_candy') {tetherCandy += e.n; tally.tether_candy += e.n; continue;}
    if (e.kind === 'essence') {addEss(e.type, e.n, e.source); continue;}
    if (e.kind === 'care') {
      // Den grooming pays each groomed creature's own type, capped per character per day.
      for (let v=0; v<e.visits; v++) {
        let left = ess.care_daily_character_cap;
        for (const m of team) {if (left<=0) break; const n=Math.min(ess.care_per_grooming,left); left-=n;
          for (const p of splitPayout(m.types,n)) addEss(p.type,p.n,'care');}
      }
      continue;
    }
    if (e.kind === 'spend') spend();
    else throw Error(`Unknown event ${e.kind}`);
  }
  spend();
  return {team, pool, tetherCandy, rot, cap, research, tally};

  function payResearch(species, kind) {
    const task = opts.researchTasks?.[species]?.find(t=>t.kind===kind);
    const types = opts.speciesTypes[species];
    if (!task || !types) return;
    for (const p of splitPayout(types, task.reward_count)) addEss(p.type,p.n,'research');
  }
  function spend() {
    for (;;) {
      const order = team.filter(m=>m.level<cap).sort((a,b)=>a.level-b.level||a.slot-b.slot);
      let paid = false;
      for (const m of order) {
        const cost = levelCost(m.level, ess, prog);
        const key = wildcard ? ['any'] : m.types;
        const payer = key.find(k=>(pool[k]??0)>=cost);
        if (payer) {pool[payer]-=cost; m.level++; if(m.level===cap) m.xp=0; paid=true; break;}
        if (tetherCandy >= ess.tether_candy_cost) {tetherCandy-=ess.tether_candy_cost; m.level++; if(m.level===cap) m.xp=0; paid=true; break;}
      }
      if (!paid) return;
    }
  }
}
function lowest(team, cap) {return team.filter(m=>m.level<cap).sort((a,b)=>a.level-b.level||a.slot-b.slot)[0];}
export const average = team => team.reduce((s,m)=>s+m.level,0)/team.length;
// Level plus banked XP fraction (XP is zero at a cap), for finer grind deltas.
export const progress = (team, prog) => team.reduce((s,m)=>s+m.level+m.xp/xpToNext(m.level,prog),0)/team.length;
const round2 = n => Math.round(n*100)/100;

// Evenly spaced deterministic selection of floor(n*fraction) of an ordered list.
export function engagedSites(sites, fraction) {
  const out = [];
  sites.forEach((s,i)=>{if (Math.floor((i+1)*fraction) > Math.floor(i*fraction)) out.push(s);});
  return out;
}
// Proportional, deterministic species allocation over a weighted table.
function weightedCycle(entries) {
  const seq = [];
  const total = entries.reduce((s,e)=>s+e.weight,0);
  const acc = entries.map(()=>0);
  for (let k=0;k<total;k++) {
    entries.forEach((e,i)=>{acc[i]+=e.weight;});
    let best=0; acc.forEach((v,i)=>{if(v>acc[best])best=i;});
    acc[best]-=total; seq.push(entries[best].species);
  }
  return seq;
}

// ---- Route construction from authored data ---------------------------------------
export function loadSources(root = ROOT) {
  const manifest = [];
  const raw = p => {const bytes=fs.readFileSync(path.join(root,p)); manifest.push({path:p,sha256:digest(bytes)}); return bytes.toString();};
  const read = p => JSON.parse(raw(p));
  const s = {manifest};
  s.order = read('data/config/biome_order.json');
  s.curve = authoredCurve(read('data/config/chapter_curve.json'), read('data/config/redesign_level_curve.json'));
  s.ess = read('data/config/essence.json');
  s.prog = read('data/config/progression.json');
  s.species = read('data/creatures/species.json').species;
  s.bands = Object.fromEntries(s.curve.regions.map(r=>[r.id,{
    spawns:read(`data/config/bands/${r.id}/spawns.json`).spawns,
    trainers:read(`data/config/bands/${r.id}/trainers.json`).trainers,
    pickups:read(`data/config/bands/${r.id}/pickups.json`).pickups}]));
  s.warrens = read('data/config/burrow_warrens.json');
  s.waterEnc = read('data/config/water_encounters.json');
  s.waterChars = read('data/config/water_characters.json');
  s.waterAlpha = read('data/config/water_alpha.json');
  s.waterPickups = read('data/config/water_pickups.json');
  s.cloudChapter = read('data/config/cloudreach_chapter.json');
  s.cloudEnc = read('data/config/cloudreach_encounters.json');
  s.stormEnc = read('data/config/stormwood_encounters.json');
  s.stormTrainers = read('data/config/stormwood_trainers.json');
  s.stormPickups = read('data/config/stormwood_pickups.json');
  s.masters = read('data/config/masters.json');
  s.nodes = read('data/config/essence_nodes.json');
  s.research = read('data/config/research.json');
  s.bounties = read('data/config/bounties.json');
  s.alphas = read('data/config/alpha_respawns.json');
  s.farm = read('data/config/farm.json');
  s.trade = read('data/config/trade.json');
  s.items = read('data/items/items.json').items;
  const stormCatalogue = raw('scripts/combat/stormwood_encounter_catalogue.gd');
  for (const p of ['scripts/creatures/progression.gd','scripts/creatures/essence.gd','scripts/net/combat_round_reward.gd',
    'scripts/combat/encounter_director.gd','scripts/creatures/research_log.gd']) raw(p);
  const group = stormCatalogue.match(/const ORDINARY_GROUP_COUNT := (\d+)/);
  const weights = {}; for (const w of ['common','uncommon','rare']) {
    const m = stormCatalogue.match(new RegExp(`"${w}": return (\\d+)`)); weights[w] = m ? Number(m[1]) : null;}
  if (!group || Object.values(weights).some(v=>!v)) throw Error('Stormwood catalogue constants not found');
  s.stormGroupCount = Number(group[1]); s.stormWeights = weights;
  s.dayMinutes = s.alphas.day_seconds/60;
  return s;
}

export function typesOf(s, species) {
  const d = s.species[species];
  if (!d) throw Error(`Unknown species ${species}`);
  return [d.type, d.type_secondary].filter(Boolean);
}
const mid = band => Math.floor((band[0]+band[1])/2);
const regionAtZ = (curve,z) => curve.regions.find(r=>z<r.z_to) ?? curve.regions.at(-1);
const candyLevels = (s,id) => s.items[id]?.level_up ?? 0;

// Returns ordered regions per biome: {biome, region_id, optional, team, sites, trainers,
// candies, optional_*}. Sites carry bodies [{species,level}].
export function buildRoute(s) {
  const regions = [];
  const add = r => {regions.push({sites:[],trainers:[],candies:[],fixed:[],tether:[],caps:[],
    optional_sites:[],optional_trainers:[],optional_candies:[],optional_fixed:[],...r}); return regions.at(-1);};
  // Meadows
  const meadows = {};
  for (const r of s.curve.regions) meadows[r.id] = add({biome:'meadows',region_id:r.id,optional:false,team:[r.team.enter,r.team.exit],wild_band:r.wild_band});
  for (const r of s.curve.regions) for (const sp of s.bands[r.id].spawns) {
    const region = meadows[regionAtZ(s.curve, sp.centre[2]).id];
    let level = Number.isInteger(sp.level) ? sp.level : mid(region.wild_band);
    if (sp.alpha?.level_bonus) level += sp.alpha.level_bonus;
    if (sp.alpha?.level_ceiling) level = Math.min(level, sp.alpha.level_ceiling);
    region.sites.push({id:`${r.id}:${sp.order}`,alpha:!!sp.alpha,bodies:Array.from({length:sp.count},()=>({species:sp.species,level}))});
  }
  const warrens = meadows.band2_stone_and_root;
  for (const sp of s.warrens.spawns) warrens.sites.push({id:`warrens:${sp.chamber}:${sp.species}`,bodies:Array.from({length:sp.count},()=>({species:sp.species,level:sp.level}))});
  warrens.fixed.push({id:'warrens_guardian',species:s.warrens.guardian.species,level:s.warrens.guardian.level});
  for (const r of s.curve.regions) for (const t of s.bands[r.id].trainers) {
    const row = {id:t.id,team:t.team.map(m=>m.level),xp_bonus:t.reward?.xp_bonus??0,
      candy:(t.reward?.items??[]).filter(i=>/_candy$/.test(i.id)).reduce((n,i)=>n+candyLevels(s,i.id)*(i.count??1),0)};
    (OPTIONAL_MEADOWS_TRAINERS[t.id] ? meadows[r.id].optional_trainers : meadows[r.id].trainers).push(row);
  }
  for (const r of s.curve.regions) for (const p of s.bands[r.id].pickups) if (/_candy$/.test(p.item)) {
    const row = {id:p.id,levels:candyLevels(s,p.item)*(p.count??1),tier:p.tier};
    (p.tier==='critical' ? meadows[r.id].candies : meadows[r.id].optional_candies).push(row);
  }
  // Tidewake
  const tide = {};
  for (const r of s.curve.biomes.tidewake.regional_targets) tide[r.region_id] = add({biome:'tidewake',region_id:r.region_id,optional:r.optional===true,team:r.team});
  const waterTables = Object.fromEntries(s.waterEnc.tables.map(t=>[t.id,t]));
  const cycles = {}, cursor = {};
  const pick = (tableId, entries) => {cycles[tableId] ??= weightedCycle(entries); cursor[tableId] = (cursor[tableId] ?? -1) + 1; return cycles[tableId][cursor[tableId] % cycles[tableId].length];};
  const islandRegion = {};
  for (const site of s.waterEnc.wild_sites) {
    islandRegion[site.island_id] = site.region_id;
    const t = waterTables[site.table_id];
    const level = mid(t.level_range);
    const bodies = Array.from({length:site.count},()=>({species:pick(t.id,t.entries.map(e=>({species:e.species_id,weight:e.weight}))),level}));
    (OPTIONAL_TIDEWAKE_ISLANDS[site.island_id] ? tide[site.region_id].optional_sites : tide[site.region_id].sites).push({id:site.id,island:site.island_id,bodies});
  }
  for (const t of s.waterChars.trainers) {
    const row = {id:t.id,team:t.team.map(m=>m.level),xp_bonus:0,candy:0};
    (t.critical ? tide[islandRegion[t.island_id]].trainers : tide[islandRegion[t.island_id]].optional_trainers).push(row);
  }
  for (const n of s.waterEnc.named_encounters) tide[islandRegion[n.island_id]].optional_fixed.push({id:n.id,species:n.species_id,level:n.level});
  tide[islandRegion[s.waterAlpha.island_id]].fixed.push({id:s.waterAlpha.id,species:s.waterAlpha.species_id.replace(/^water_/,''),level:s.waterAlpha.level});
  for (const p of s.waterPickups.pickups) if (/_candy$/.test(p.item_id) && candyLevels(s,p.item_id)) {
    const region = tide[islandRegion[p.island_id]];
    (p.off_main_route===false ? region.candies : region.optional_candies).push({id:p.id,levels:candyLevels(s,p.item_id)*p.quantity});
  }
  // Cloudreach
  const cloud = {};
  for (const r of s.curve.biomes.cloudreach.regional_targets) cloud[r.region_id] = add({biome:'cloudreach',region_id:r.region_id,optional:r.optional===true,team:r.team});
  const cloudTables = Object.fromEntries(s.cloudChapter.encounter_tables.map(t=>[t.id,t]));
  for (const site of s.cloudEnc.wild_sites) {
    const t = cloudTables[site.table_id];
    const level = mid(t.level_range);
    const bodies = Array.from({length:site.count},()=>({species:pick(t.id,t.entries.map(e=>({species:e.placeholder_species,weight:e.weight}))),level}));
    const region = cloud[t.region_ids[0]];
    (region.optional ? region.optional_sites : region.sites).push({id:site.id,bodies});
  }
  for (const t of s.cloudChapter.trainer_ladder) {
    const tier = s.cloudEnc.reward_tiers[t.rank] ?? {};
    const row = {id:t.id,team:t.team_contract.slots.map(m=>m.level),xp_bonus:tier.xp_bonus??0,
      candy:(tier.items??[]).filter(i=>/_candy$/.test(i.id)).reduce((n,i)=>n+candyLevels(s,i.id)*(i.count??1),0)};
    (t.optional||cloud[t.region_id].optional ? cloud[t.region_id].optional_trainers : cloud[t.region_id].trainers).push(row);
  }
  for (const p of s.cloudChapter.pickups) if (/_candy$/.test(p.item_id)) {
    const region = cloud[p.region_id];
    (p.placement==='route_verge' && !region.optional ? region.candies : region.optional_candies).push({id:p.id,levels:candyLevels(s,p.item_id)*p.count});
  }
  // Stormwood
  const storm = {};
  for (const r of s.curve.biomes.stormwood.regional_targets) storm[r.region_id] = add({biome:'stormwood',region_id:r.region_id,optional:r.optional===true,team:r.team});
  const stormTables = Object.fromEntries(s.stormEnc.tables.map(t=>[t.id,t]));
  for (const c of s.stormEnc.wild_clusters) {
    const t = stormTables[c.calm_table_id];
    const level = mid(t.level_range);
    const bodies = Array.from({length:s.stormGroupCount},()=>({species:pick(t.id,t.roles.map(r=>({species:r.placeholder_species,weight:s.stormWeights[r.weight]}))),level}));
    storm[c.region_id].sites.push({id:c.id,bodies});
  }
  for (const t of s.stormTrainers.trainers) {
    const row = {id:t.id,team:t.party.map(m=>m.level),xp_bonus:t.reward?.xp_bonus??0,candy:0};
    (t.route_class==='critical' ? storm[t.region_id].trainers : storm[t.region_id].optional_trainers).push(row);
  }
  for (const n of s.stormEnc.named_encounters) storm[n.region_id].optional_fixed.push({id:n.id,species:n.placeholder_species,level:n.level,
    candy:(n.completion_reward?.items??[]).filter(i=>/_candy$/.test(i.id)).reduce((k,i)=>k+candyLevels(s,i.id)*(i.count??1),0)});
  for (const p of s.stormPickups.pickups) if (/_candy$/.test(p.item_id)) {
    const region = storm[p.region_id];
    (p.placement==='critical_route_verge' ? region.candies : region.optional_candies).push({id:p.id,levels:candyLevels(s,p.item_id)*p.count});
  }
  // Masters: candy and cap lifts.
  for (const m of s.masters.masters) {
    const region = m.biome==='meadows' ? meadows[regionAtZ(s.curve, m.position[2]).id] : regions.find(r=>r.biome===m.biome && !r.optional);
    region.tether.push({id:m.id,n:m.candy});
    region.caps.push({id:m.id,cap:m.next_cap});
  }
  return regions;
}

// Events for one region under a scenario.
export function regionEvents(s, region, scenario) {
  const ev = [];
  for (const c of region.caps) ev.push({kind:'cap',cap:c.cap,id:c.id});
  const fraction = scenario.fraction ?? ORDINARY_WILD_SITE_FRACTION;
  const sites = scenario.allBodies ? region.sites : engagedSites(region.sites, fraction);
  const wildSites = scenario.optionalOneTime ? [...sites, ...(scenario.allBodies ? region.optional_sites : engagedSites(region.optional_sites, fraction))] : sites;
  for (const site of wildSites) {
    const bodies = scenario.allBodies ? site.bodies : site.bodies.slice(0, DEFEATS_PER_ENGAGED_SITE);
    for (const b of bodies) ev.push({kind:'defeat',essence:true,level:b.level,species:b.species,types:typesOf(s,b.species),site:site.id});
  }
  const fixed = scenario.optionalOneTime ? [...region.fixed, ...region.optional_fixed] : region.fixed;
  for (const f of fixed) {
    ev.push({kind:'defeat',essence:true,level:f.level,species:f.species,types:typesOf(s,f.species),site:f.id});
    if (f.candy) ev.push({kind:'candy_levels',levels:f.candy,id:f.id});
  }
  const trainers = scenario.optionalOneTime ? [...region.trainers, ...region.optional_trainers] : region.trainers;
  for (const t of trainers) {
    for (const level of t.team) ev.push({kind:'defeat',essence:false,level,trainer:t.id});
    if (t.xp_bonus) ev.push({kind:'xp_all',amount:t.xp_bonus,id:t.id});
    if (t.candy) ev.push({kind:'candy_levels',levels:t.candy,id:t.id});
  }
  for (const t of region.tether) ev.push({kind:'tether_candy',n:t.n,id:t.id});
  const candies = scenario.optionalOneTime ? [...region.candies, ...region.optional_candies] : region.candies;
  for (const c of candies) ev.push({kind:'candy_levels',levels:c.levels,id:c.id});
  ev.push({kind:'spend'});
  return ev;
}

function careEvent(biome, regionsInBiome) {
  // Spread the biome's home visits evenly across its regions.
  const visits = Math.round(TIME_BUDGET_LOW_HOURS[biome] * CARE_HOME_VISITS_PER_HOUR);
  const per = regionsInBiome.map((_,i)=>Math.floor((i+1)*visits/regionsInBiome.length)-Math.floor(i*visits/regionsInBiome.length));
  return per;
}

export function startTeam(s, scenario) {
  return {team:Array.from({length:TEAM_SIZE},(_,i)=>({slot:i,level:STARTING_TEAM_LEVEL,xp:0,
      types:scenario.team ? scenario.team[i].types : ['any']})),
    pool:{}, tetherCandy:0, rot:0, cap:s.masters.initial_cap, research:new Map()};
}

export function researchTasks(s) {
  return Object.fromEntries(Object.entries(s.research.species).map(([k,v])=>[k,v.tasks]));
}
function speciesTypes(s) {return Object.fromEntries(Object.keys(s.species).map(k=>[k,typesOf(s,k)]));}

// Runs a scenario through the live biome order; returns checkpoints and state.
export function runScenario(s, regions, scenario, hooks = {}) {
  const opts = {prog:s.prog, ess:s.ess, wildcard:!scenario.team, researchTasks:researchTasks(s), speciesTypes:speciesTypes(s)};
  let state = startTeam(s, scenario);
  const checkpoints = [], perRegion = [], states = {};
  const totals = {defeats:0,wild_defeats:0,trainer_defeats:0,candy_levels:0,tether_candy:0,care:0,research:0,completion_xp:0,essence:{}};
  for (const biome of s.order.live) {
    const inBiome = regions.filter(r=>r.biome===biome && (scenario.optionalOneTime || !r.optional));
    checkpoints.push(point(`${biome}_entry`,biome,s.curve.biomes[biome].team[0],state.team));
    states[`${biome}_entry`] = cloneState(state);
    if (hooks.atBiomeEntry) state = hooks.atBiomeEntry(biome, state, opts) ?? state;
    states[`${biome}_after_hook`] = cloneState(state);
    const visits = careEvent(biome, inBiome);
    inBiome.forEach((region,i)=>{
      const ev = regionEvents(s, region, scenario);
      if (visits[i]) ev.splice(ev.length-1,0,{kind:'care',visits:visits[i]});
      const isFinale = biome===s.order.live.at(-1) && i===inBiome.length-1;
      if (isFinale) {
        // Finale readiness: state before the final region's last trainer (the chapter boss).
        const lastTrainer = region.trainers.at(-1)?.id;
        const cut = ev.findIndex(e=>e.trainer===lastTrainer);
        const before = simulate(cloneState(state), ev.slice(0,cut).concat([{kind:'spend'}]), opts);
        checkpoints.push({...point(`${biome}_finale_ready`,biome,s.curve.biomes[biome].boss[0],before.team),boss:lastTrainer,
          note:'state before the final boss fight (boss[0] target), every earlier reward spent'});
      }
      const result = simulate(state, ev, opts);
      for (const k of ['defeats','wild_defeats','trainer_defeats','candy_levels','tether_candy','care','research','completion_xp']) totals[k]+=result.tally[k];
      for (const [k,v] of Object.entries(result.tally.essence)) totals.essence[k]=(totals.essence[k]??0)+v;
      perRegion.push({biome,region:region.region_id,optional:region.optional,target:region.team,
        wild_defeats:result.tally.wild_defeats,trainer_defeats:result.tally.trainer_defeats,essence:result.tally.essence,
        care:result.tally.care,research:result.tally.research,completion_xp:result.tally.completion_xp,candy_levels:result.tally.candy_levels,
        tether_candy:result.tally.tether_candy,levels_after:result.team.map(m=>m.level),average_after:round2(average(result.team)),progress_after:round2(progress(result.team,s.prog)),
        unspent:Object.fromEntries(Object.entries(result.pool).filter(([,v])=>v>0)),cap:result.cap});
      state = {team:result.team,pool:result.pool,tetherCandy:result.tetherCandy,rot:result.rot,cap:result.cap,research:result.research};
    });
  }
  const last = s.order.live.at(-1);
  checkpoints.push(point(`${last}_exit`,last,s.curve.biomes[last].team[1],state.team));
  states[`${last}_exit`] = cloneState(state);
  for (const c of checkpoints) {c.margin = round2(c.reached_average - c.target); c.pass = c.reached_average >= c.target;}
  return {checkpoints, perRegion, totals, states};
  function point(checkpoint, biome, target, team) {
    return {checkpoint,biome,target,reached_average:round2(average(team)),reached_progress:round2(progress(team,s.prog)),
      reached_min:Math.min(...team.map(m=>m.level)),levels:team.map(m=>m.level)};
  }
}
function cloneState(st) {return {team:st.team.map(m=>({...m})),pool:{...st.pool},tetherCandy:st.tetherCandy,rot:st.rot,cap:st.cap,research:new Map([...st.research].map(([k,v])=>[k,{...v}]))};}

// ---- Optional grind loops ---------------------------------------------------------
export function grindLoops(s, regions, biome) {
  const main = regions.filter(r=>r.biome===biome && !r.optional);
  const entry = main[0];
  const sites = entry.sites.length;
  const level = Math.floor(entry.sites.reduce((n,x)=>n+x.bodies[0].level,0)/Math.max(1,sites));
  const species = entry.sites.map(x=>x.bodies[0].species);
  const types = typesOf(s, species[0]);
  const dayMin = s.dayMinutes;
  const loops = {};
  // Wild re-fights after the WORLD §2.5 two-day return in the entry region.
  const refightSupply = sites * 60 / (WILD_SITE_RETURN_DAYS * dayMin);
  const refights = Math.floor(Math.min(60/MINUTES_PER_WILD_REFIGHT, refightSupply) * GRIND_HOURS);
  loops.wild_refights = {per_hour:refights,level,types,events:Array.from({length:refights},(_,i)=>({kind:'defeat',essence:true,level,species:species[i%species.length],types:typesOf(s,species[i%species.length])})),
    rule:`min(60/${MINUTES_PER_WILD_REFIGHT} min, ${sites} entry-region sites × 60/(${WILD_SITE_RETURN_DAYS} days × ${dayMin} min))`};
  // Alpha respawns.
  const alphaRows = alphaSites(s, regions, biome);
  const alphaSupply = alphaRows.length * 60 / (s.alphas.respawn_days * dayMin);
  const alphas = Math.floor(Math.min(60/MINUTES_PER_ALPHA, alphaSupply) * GRIND_HOURS);
  loops.alpha_respawns = {per_hour:alphas,sites:alphaRows.length,runtime_enabled:s.alphas.runtime_enabled,
    events:Array.from({length:alphas},(_,i)=>{const a=alphaRows[i%alphaRows.length];return {kind:'defeat',essence:true,level:a.level,species:a.species,types:typesOf(s,a.species)};}),
    rule:`min(60/${MINUTES_PER_ALPHA} min, ${alphaRows.length} sites × 60/(${s.alphas.respawn_days} days × ${dayMin} min))`};
  // Catch and release (payout once per uid; catch path pays no defeat XP/essence).
  const catches = Math.floor(60/MINUTES_PER_CATCH_RELEASE * GRIND_HOURS);
  const orb = s.trade.vendors.mira.goods.orb_basic.buy;
  loops.catch_release = {per_hour:catches,level,coin_cost_per_hour:catches*ORBS_PER_SUCCESSFUL_CATCH*orb,
    events:Array.from({length:catches},(_,i)=>{const sp=species[i%species.length];return releasePayout(level,typesOf(s,sp),s.ess).map(p=>({kind:'essence',type:p.type,n:p.n,source:'release'}));}).flat(),
    rule:`60/${MINUTES_PER_CATCH_RELEASE} min, ${ORBS_PER_SUCCESSFUL_CATCH} × orb_basic ${orb} coins each`};
  // Type crops on the homestead plots, harvested on home visits.
  const crop = s.farm.crops.ground;
  const harvestsPerPlot = Math.min(CARE_HOME_VISITS_PER_HOUR, 60/(crop.grow_days*dayMin)) * GRIND_HOURS;
  const cropEssence = s.farm.plots.length * Math.floor(harvestsPerPlot) * s.ess.crop_essence_yield;
  loops.type_crops = {per_hour_essence:cropEssence,plots:s.farm.plots.length,runtime_enabled:s.farm.runtime_enabled,
    events:[{kind:'essence',type:'team',n:cropEssence,source:'crop'}],
    rule:`${s.farm.plots.length} plots × min(${CARE_HOME_VISITS_PER_HOUR} visits, 60/(${crop.grow_days} days × ${dayMin} min)) × ${s.ess.crop_essence_yield}; crop type chosen to match the team`};
  // Bounties: three per morning, rewards from this biome's templates.
  const templates = s.bounties.templates.filter(t=>t.biome===biome);
  const perHour = Math.floor(Math.min(60/MINUTES_PER_BOUNTY, s.bounties.board_count*60/dayMin) * GRIND_HOURS);
  const bountyEvents = [];
  for (let i=0;i<perHour;i++) for (const r of templates[i%templates.length].rewards) {
    if (r.id==='tether_candy') bountyEvents.push({kind:'tether_candy',n:r.n});
    else if (r.id.startsWith('essence_')) bountyEvents.push({kind:'essence',type:r.id.slice(8),n:r.n,source:'bounty'});
  }
  loops.bounties = {per_hour:perHour,runtime_enabled:s.bounties.runtime_enabled,events:bountyEvents,
    rule:`min(60/${MINUTES_PER_BOUNTY} min, ${s.bounties.board_count} per ${dayMin}-min morning); templates cycled`};
  // Attuned nodes (all authored off-route) on their respawn timer.
  const realm = biome==='tidewake' ? 'water' : biome;
  const nodes = s.nodes.nodes.filter(n=>n.realm===realm);
  const nodeHarvests = Math.floor(Math.min(60/MINUTES_PER_NODE_HARVEST, nodes.length*60/(s.nodes.respawn_days*dayMin)) * GRIND_HOURS);
  loops.attuned_nodes = {per_hour:nodeHarvests,nodes:nodes.length,runtime_enabled:s.nodes.runtime_enabled,
    events:Array.from({length:nodeHarvests},(_,i)=>{const n=nodes[i%nodes.length];return {kind:'essence',type:n.type,n:n.amount,source:'node'};}),
    rule:`min(60/${MINUTES_PER_NODE_HARVEST} min, ${nodes.length} nodes × 60/(${s.nodes.respawn_days} days × ${dayMin} min))`};
  return loops;
}
function alphaSites(s, regions, biome) {
  const out = [];
  for (const site of Object.values(s.alphas.sites).filter(x=>x.biome===biome)) {
    if (biome==='meadows') {
      const reg = regions.find(r=>r.region_id===site.region_id);
      const found = reg.sites.find(x=>x.id===`${site.region_id}:${site.source_order}`);
      if (found) out.push({id:site.id,species:found.bodies[0].species,level:found.bodies[0].level});
    } else {
      const named = [...regions.filter(r=>r.biome===biome).flatMap(r=>[...r.fixed,...r.optional_fixed])].find(f=>f.id===site.id);
      if (named) out.push({id:site.id,species:named.species,level:named.level});
    }
  }
  return out;
}

// ---- Report -----------------------------------------------------------------------
export function routeReport(root = ROOT) {
  const s = loadSources(root);
  const regions = buildRoute(s);
  const scenarios = {
    ordinary_types_match:{label:'ordinary path, every earned essence usable (type-match best case)'},
    ordinary_plausible_team:{label:'ordinary path, plausible starter-led Meadows team (type mismatch case)',team:PLAUSIBLE_TEAM},
    authored_ceiling_types_match:{label:'every authored main-path wild body once (ceiling, still no repeats)',allBodies:true},
    ordinary_plus_optional_one_time:{label:'ordinary path plus optional one-time content (no repeats)',optionalOneTime:true},
    sensitivity_quarter_engagement:{label:`sensitivity: ordinary path at ${SENSITIVITY_WILD_SITE_FRACTION} site engagement (types match)`,fraction:SENSITIVITY_WILD_SITE_FRACTION}};
  const results = {};
  for (const [id,sc] of Object.entries(scenarios)) results[id] = runScenario(s, regions, sc);
  const primary = results.ordinary_types_match;
  const entries = () => true; // every entry, the finale readiness and the exit
  const verdict = sc => {const cps = results[sc].checkpoints.filter(entries); return {
    mandatory_repeat_grinding:!cps.every(c=>c.pass), deficits:cps.filter(c=>!c.pass).map(c=>({checkpoint:c.checkpoint,target:c.target,reached:c.reached_average,margin:c.margin}))};};
  // Optional grind: insert GRIND_HOURS of one loop at a biome's entry, replay the
  // ordinary path, and compare (a) the immediate gain, (b) the next checkpoint and
  // (c) how far into the biome the next target level is first reached.
  const grind = {};
  const live = s.order.live;
  const arrival = (run, biome, target) => {
    const rows = run.perRegion.filter(r=>r.biome===biome);
    const at = run.states[`${biome}_after_hook`];
    if (average(at.team) >= target) return 0;
    const i = rows.findIndex(r=>r.average_after >= target);
    return i < 0 ? null : i+1;
  };
  for (let b=0;b<live.length;b++) {
    const biome = live[b];
    const at = primary.checkpoints.find(c=>c.checkpoint===`${biome}_entry`);
    const next = primary.checkpoints.find(c=>c.checkpoint===(b+1<live.length?`${live[b+1]}_entry`:`${biome}_exit`));
    const nRegions = primary.perRegion.filter(r=>r.biome===biome).length;
    const ordinaryRate = (next.reached_progress-at.reached_progress)/TIME_BUDGET_LOW_HOURS[biome];
    const ordinaryArrival = arrival(primary, biome, next.target);
    const loops = grindLoops(s, regions, biome);
    grind[biome] = {grind_at:`${biome}_entry (entry-region wild levels)`,next_checkpoint:next.checkpoint,next_target:next.target,
      ordinary_reached:next.reached_average,ordinary_progress:next.reached_progress,
      ordinary_levels_per_route_hour:round2(ordinaryRate),
      ordinary_target_reached_after_regions:ordinaryArrival,regions_in_biome:nRegions,loops:{}};
    for (const [name,loop] of Object.entries(loops)) {
      const run = runScenario(s, regions, {}, {atBiomeEntry:(bm,state,opts)=>{
        if (bm!==biome) return state;
        const events = loop.events.map(e=>e.type==='team'?{...e,type:'any'}:e).concat([{kind:'spend'}]);
        const res = simulate(state, events, opts);
        return {team:res.team,pool:res.pool,tetherCandy:res.tetherCandy,rot:res.rot,cap:res.cap,research:res.research};
      }});
      const after = run.checkpoints.find(c=>c.checkpoint===next.checkpoint);
      const immediate = round2(progress(run.states[`${biome}_after_hook`].team,s.prog) - progress(run.states[`${biome}_entry`].team,s.prog));
      const gain = round2(after.reached_progress - next.reached_progress);
      const grindArrival = arrival(run, biome, next.target);
      const hoursSaved = ordinaryArrival!==null && grindArrival!==null ? round2((ordinaryArrival-grindArrival)/nRegions*TIME_BUDGET_LOW_HOURS[biome]) : null;
      const {events,...rest} = loop;
      grind[biome].loops[name] = {...rest,levels_per_grind_hour:immediate,
        progress_gain_at_next_checkpoint:gain,reached_with_grind:after.reached_average,
        target_reached_after_regions:grindArrival,route_hours_saved_to_target:hoursSaved,
        essence_per_hour:events.filter(e=>e.kind==='essence').reduce((n,e)=>n+e.n,0)+
          events.filter(e=>e.kind==='defeat').reduce((n,e)=>n+defeatPayout(e.level,e.types,s.ess).reduce((k,p)=>k+p.n,0),0),
        tether_candy_per_hour:events.filter(e=>e.kind==='tether_candy').reduce((n,e)=>n+e.n,0),
        auto_xp_active_per_hour:events.filter(e=>e.kind==='defeat').reduce((n,e)=>n+scaledCombatXp(e.level,s.prog,s.ess),0),
        measurably_faster:immediate>0 && (gain>0 || (hoursSaved??0)>0)};
    }
    const best = Object.entries(grind[biome].loops).sort((a,b)=>b[1].levels_per_grind_hour-a[1].levels_per_grind_hour)[0];
    grind[biome].best_loop = best[0];
    grind[biome].best_levels_per_grind_hour = best[1].levels_per_grind_hour;
    grind[biome].best_progress_gain_at_next_checkpoint = Math.max(...Object.values(grind[biome].loops).map(l=>l.progress_gain_at_next_checkpoint));
    grind[biome].best_route_hours_saved_to_target = Math.max(...Object.values(grind[biome].loops).map(l=>l.route_hours_saved_to_target??0));
    grind[biome].any_loop_measurably_faster = Object.values(grind[biome].loops).some(l=>l.measurably_faster);
  }
  // Supply census.
  const census = s.order.live.map(biome=>{
    const rs = regions.filter(r=>r.biome===biome);
    const sum = (k,f=x=>1)=>rs.reduce((n,r)=>n+r[k].reduce((m,x)=>m+f(x),0),0);
    const main = rs.filter(r=>!r.optional), opt = rs.filter(r=>r.optional);
    return {biome,main_regions:main.map(r=>r.region_id),optional_regions:opt.map(r=>r.region_id),
      main_wild_sites:main.reduce((n,r)=>n+r.sites.length,0),main_wild_bodies:main.reduce((n,r)=>n+r.sites.reduce((m,x)=>m+x.bodies.length,0),0),
      ordinary_engaged_sites:main.reduce((n,r)=>n+engagedSites(r.sites,ORDINARY_WILD_SITE_FRACTION).length,0),
      optional_wild_sites:sum('optional_sites')+opt.reduce((n,r)=>n+r.sites.length,0),
      required_fixed_fights:main.flatMap(r=>r.fixed.map(f=>f.id)),optional_fixed_fights:rs.flatMap(r=>r.optional_fixed.map(f=>f.id)),
      main_trainers:main.flatMap(r=>r.trainers.map(t=>t.id)),optional_trainers:[...rs.flatMap(r=>r.optional_trainers.map(t=>t.id)),...opt.flatMap(r=>r.trainers.map(t=>t.id))],
      on_route_candy_levels:main.reduce((n,r)=>n+r.candies.reduce((m,c)=>m+c.levels,0),0),
      optional_candy_levels:sum('optional_candies',c=>c.levels)+opt.reduce((n,r)=>n+r.candies.reduce((m,c)=>m+c.levels,0),0),
      master_tether_candy:rs.reduce((n,r)=>n+r.tether.reduce((m,t)=>m+t.n,0),0),
      boss_tether_candy:0,
      attuned_nodes_off_route:s.nodes.nodes.filter(n=>n.realm===(biome==='tidewake'?'water':biome)).length,
      required_catch_releases:0};
  });
  for (const row of census) {
    const fights = primary.perRegion.filter(r=>r.biome===row.biome).reduce((n,r)=>n+r.wild_defeats+r.trainer_defeats,0);
    row.ordinary_defeats = fights;
    row.implied_fight_hours = round2(fights*MINUTES_PER_WILD_REFIGHT/60);
    row.time_budget_hours = s.order.live[0]===row.biome ? [5,7] : [3.5,6];
  }
  // Break-even: the smallest engaged-site fraction (step 0.01) at which every
  // checkpoint still passes with types matching. Reported, never used for the verdict.
  let breakEven = null;
  for (let f=0.01; f<=1.0001; f+=0.01) {
    const run = runScenario(s, regions, {fraction:Math.round(f*100)/100});
    if (run.checkpoints.every(c=>c.pass)) {breakEven = Math.round(f*100)/100; break;}
  }
  const findings = [];
  findings.push({kind:'verdict_depends_on_wild_engagement',detail:`Pass needs at least ${breakEven} of authored main-path wild sites engaged once (primary assumes ${ORDINARY_WILD_SITE_FRACTION}); at ${SENSITIVITY_WILD_SITE_FRACTION} the first failing checkpoint is ${results.sensitivity_quarter_engagement.checkpoints.find(c=>!c.pass)?.checkpoint ?? 'none'}. Implied fight time at ${MINUTES_PER_WILD_REFIGHT} min/fight: `+census.map(c=>`${c.biome} ${c.implied_fight_hours} h of ${c.time_budget_hours.join('–')} h`).join(', ')+'. An agent-piloted normal route (F47#0) must confirm the engagement rate.'});
  for (const [b,g] of Object.entries(grind)) for (const [k,l] of Object.entries(g.loops)) if (k==='alpha_respawns' && l.sites===0)
    findings.push({kind:'no_alpha_respawn_sites',detail:`${b} has no alpha_respawns.json site, so the alpha loop pays nothing there.`});
  for (const [sc,v] of Object.entries({ordinary_types_match:verdict('ordinary_types_match'),ordinary_plausible_team:verdict('ordinary_plausible_team')}))
    if (v.mandatory_repeat_grinding) findings.push({kind:'ordinary_path_entry_deficit',scenario:sc,deficits:v.deficits,
      status:'OPEN: reported, not tuned. F47 owns any reward/curve change.'});
  if (results.ordinary_types_match.checkpoints.some(c=>c.levels.every(l=>l>=s.masters.ceiling)))
    findings.push({kind:'ordinary_path_reaches_pass_ceiling_before_exit',detail:`The ordinary path reaches the L${s.masters.ceiling} pass ceiling by ${results.ordinary_types_match.checkpoints.find(c=>c.levels.every(l=>l>=s.masters.ceiling)).checkpoint} (Stormwood exit target ${s.curve.biomes.stormwood.team[1]}): hybrid auto XP at auto_xp_scale ${s.ess.auto_xp_scale} plus essence overshoots late; F47 owns tuning. Grind cannot add levels at the ceiling.`});
  const over = results.ordinary_types_match.checkpoints.filter(c=>c.margin>=3);
  if (over.length) findings.push({kind:'ordinary_path_overshoots_entry_targets',detail:over.map(c=>`${c.checkpoint} ${c.reached_average} vs ${c.target}`).join('; ')+'. Not a deficit; F47 measures and tunes the curve (PROGRESSION §8).'});
  findings.push({kind:'boss_tether_candy_not_authored',detail:'TRAINING §1/PROGRESSION §5 name bosses as a Tether Candy source; no boss reward row authors tether_candy (only masters.json candy:2 and bounty templates). Counted as 0.'});
  findings.push({kind:'attuned_nodes_all_off_route',detail:`All ${s.nodes.nodes.length} essence_nodes.json nodes are placement.off_route:true with terrain_and_player_path_proven:false; none counted on the ordinary path.`});
  findings.push({kind:'tidewake_found_candy_all_off_route',detail:'Every water_pickups creature_candy row is off_main_route:true; Tidewake ordinary path credits no found candy.'});
  return {schema_version:1,criterion:'F27#5',
    evidence_scope:'source-generated arithmetic over authored data and ported formulas; not an earned clear, engine run or owner verdict',
    manifest:s.manifest,
    formulas:{xp_to_next:'trunc(40 × max(L,1)^1.15)',raw_award:'floor(30 + 16L)',hybrid_active:`max(1, floor(raw × ${s.ess.auto_xp_scale}))`,
      hybrid_share:`max(1, floor(active × ${s.prog.xp_award.party_share}))`,completion:'trainer reward.xp_bonus whole to each living member (combat_round_reward.gd completion phase)',
      defeat_essence:`${s.ess.defeat_essence_base} + floor(L/${s.ess.defeat_bonus_level_interval}), dual split remainder to primary; trainer creatures pay no essence`,
      level_cost:`ceil(xp_to_next(L)/${s.ess.essence_xp_value} × band multiplier)`,release:`floor(${s.ess.release_essence_base} + ${s.ess.release_essence_per_level}L)`,
      xp_mode:s.ess.wild_victory_xp_mode},
    assumptions:assumptionList(s),
    targets:Object.fromEntries(s.order.live.map(b=>[b,{entry:s.curve.biomes[b].team[0],exit:s.curve.biomes[b].team[1],boss:s.curve.biomes[b].boss}])),
    verdict:{primary_scenario:'ordinary_types_match',...verdict('ordinary_types_match'),
      break_even_wild_site_fraction:breakEven,
      plausible_team:verdict('ordinary_plausible_team'),
      optional_grind_measurably_faster_every_biome:Object.values(grind).every(g=>g.any_loop_measurably_faster),
      acceptance_verified:false},
    scenarios:Object.fromEntries(Object.entries(results).map(([k,v])=>[k,{label:scenarios[k].label,checkpoints:v.checkpoints,totals:v.totals,per_region:v.perRegion}])),
    census, grind, findings};
}

function assumptionList(s) {
  return [
    {name:'ORDINARY_WILD_SITE_FRACTION',value:ORDINARY_WILD_SITE_FRACTION,why:'F07 route-ledger precedent: half of the authored main-path wild sites engaged, evenly spaced in authored order'},
    {name:'SENSITIVITY_WILD_SITE_FRACTION',value:SENSITIVITY_WILD_SITE_FRACTION,why:'sensitivity scenario only; not used for the verdict'},
    {name:'DEFEATS_PER_ENGAGED_SITE',value:DEFEATS_PER_ENGAGED_SITE,why:'one defeat per engaged site (F07 precedent); ceiling scenario fights every body once'},
    {name:'WILD_LEVEL_POLICY',value:WILD_LEVEL_POLICY,why:'tables give level_range; runtime rolls uniformly; Meadows uses region wild_band (+alpha level_bonus, capped by level_ceiling); fixed authored levels used directly'},
    {name:'SPECIES_ALLOCATION',value:'weighted round-robin over table entries in authored site order',why:'Meadows uses each spawn\'s authored seed-0 species; Tidewake/Cloudreach entry weights; Stormwood role weights '+JSON.stringify(s.stormWeights)+' from stormwood_encounter_catalogue.gd'},
    {name:'STORMWOOD_GROUP_COUNT',value:s.stormGroupCount,why:'source fact: stormwood_encounter_catalogue.gd ORDINARY_GROUP_COUNT; calm-phase table levels'},
    {name:'ACTIVE_POLICY',value:ACTIVE_POLICY,why:'killing blow rotates across the five; others take the share award'},
    {name:'STARTING_TEAM_LEVEL',value:STARTING_TEAM_LEVEL,why:'progression.json starter_level; the four early catches assumed at the same level'},
    {name:'TEAM_SIZE',value:TEAM_SIZE,why:'five owned creatures, all living for every award (no faints modelled)'},
    {name:'BREAKTHROUGH_TIMING',value:BREAKTHROUGH_TIMING,why:'F28 breakthroughs assumed available as each Master is reached (masters.json next_cap)'},
    {name:'MASTER_FIGHT_XP_CREDITED',value:MASTER_FIGHT_XP_CREDITED,why:'Master 1v1 award path not measured; only masters.json candy (Tether Candy) credited'},
    {name:'TIME_BUDGET_LOW_HOURS',value:TIME_BUDGET_LOW_HOURS,why:'PROGRESSION §4 lower bounds; used for care visits and the ordinary levels-per-hour rate'},
    {name:'CARE_HOME_VISITS_PER_HOUR',value:CARE_HOME_VISITS_PER_HOUR,why:'one Home Key return per 30-minute core loop; each visit is a new 600 s world day; all five groomed up to care_daily_character_cap'},
    {name:'RESEARCH_ORDINARY_TASK_KINDS',value:RESEARCH_ORDINARY_TASK_KINDS,why:'sight and 3-defeat tasks completed by ordinary wild fights; signature-cast and catch tasks excluded'},
    {name:'TRAINER_ESSENCE',value:0,why:'trainer creatures pay hybrid XP only (combat_round_reward.gd); TRAINING §1 excludes trainer essence'},
    {name:'ON_ROUTE_CANDY_RULES',value:ON_ROUTE_CANDY_RULES,why:'found good/great/rare candy (items.json level_up 1/2/3) fed to the lowest creature, respecting the cap'},
    {name:'OPTIONAL_MEADOWS_TRAINERS',value:Object.keys(OPTIONAL_MEADOWS_TRAINERS),why:JSON.stringify(OPTIONAL_MEADOWS_TRAINERS)},
    {name:'OPTIONAL_TIDEWAKE_ISLANDS',value:Object.keys(OPTIONAL_TIDEWAKE_ISLANDS),why:'side islands; water_characters critical:false and named encounters optional:true'},
    {name:'OPTIONAL_CLASSIFICATION',value:'Tidewake trainers critical:false; Cloudreach ladder optional:true or optional region; Stormwood route_class optional; all Tidewake/Stormwood named encounters',why:'authored flags; the mandatory Aquaryn alpha (water_alpha.json) and Burrow Warrens residents + guardian are required fights'},
    {name:'REQUIRED_CATCH_RELEASES',value:0,why:'no authored main-path step requires releasing a caught creature'},
    {name:'PLAUSIBLE_TEAM',value:PLAUSIBLE_TEAM,why:'mismatch case: only essence matching a creature\'s own type (or Tether Candy, care) can raise it'},
    {name:'GRIND_HOURS',value:GRIND_HOURS,why:'one extra hour of a single loop at the biome entry, then the ordinary path replays'},
    {name:'MINUTES_PER_WILD_REFIGHT',value:MINUTES_PER_WILD_REFIGHT,why:'assumed real minutes per wild fight including walking'},
    {name:'WILD_SITE_RETURN_DAYS',value:WILD_SITE_RETURN_DAYS,why:'WORLD §2.5 ordinary wild return after two 600 s world days'},
    {name:'MINUTES_PER_ALPHA',value:MINUTES_PER_ALPHA,why:'assumed minutes per alpha fight including travel'},
    {name:'MINUTES_PER_CATCH_RELEASE',value:MINUTES_PER_CATCH_RELEASE,why:'assumed minutes per catch then release'},
    {name:'ORBS_PER_SUCCESSFUL_CATCH',value:ORBS_PER_SUCCESSFUL_CATCH,why:'assumed throws per success; coin cost reported, not limited'},
    {name:'MINUTES_PER_NODE_HARVEST',value:MINUTES_PER_NODE_HARVEST,why:'assumed minutes per attuned-node harvest including travel'},
    {name:'MINUTES_PER_BOUNTY',value:MINUTES_PER_BOUNTY,why:'assumed minutes to complete one bounty'},
    {name:'CROP_TYPE',value:'matches team',why:'player sows the type it needs (greenhouse for non-native types)'}];
}

export function summaryMarkdown(report) {
  const p = report.scenarios.ordinary_types_match.checkpoints;
  const m = report.scenarios.ordinary_plausible_team.checkpoints;
  const c = report.scenarios.authored_ceiling_types_match.checkpoints;
  const lines = ['# F27#5 route ledger','',
    `Generated by \`node tools/f27_route_ledger.mjs --write\`. Scope: ${report.evidence_scope}.`,'',
    `Verdict (primary: ${report.verdict.primary_scenario}): mandatory repeat grinding = **${report.verdict.mandatory_repeat_grinding}** (break-even engaged wild-site fraction ${report.verdict.break_even_wild_site_fraction}); plausible-team case = **${report.verdict.plausible_team.mandatory_repeat_grinding}**; optional grind measurably faster in every biome = **${report.verdict.optional_grind_measurably_faster_every_biome}**. acceptance_verified=false.`,'',
    '| Checkpoint | Target | Ordinary (types match) | Margin | Plausible team | Margin | Ceiling (all bodies) |','|---|---:|---:|---:|---:|---:|---:|'];
  p.forEach((x,i)=>lines.push(`| ${x.checkpoint} | ${x.target} | ${x.reached_average} | ${x.margin} | ${m[i].reached_average} | ${m[i].margin} | ${c[i].reached_average} |`));
  const q = report.scenarios.sensitivity_quarter_engagement.checkpoints;
  lines.push('',`Sensitivity (${q.length} checkpoints, quarter engagement): `+q.map(x=>`${x.checkpoint} ${x.reached_average} (${x.margin>=0?'+':''}${x.margin})`).join('; '));
  lines.push('','| Biome (+1 h grind at entry) | Next checkpoint | Ordinary levels/route-h | Best loop | Levels per grind hour | Gain at next checkpoint | Route hours saved to target | Per-loop levels/h |','|---|---|---:|---|---:|---:|---:|---|');
  for (const [b,g] of Object.entries(report.grind)) lines.push(`| ${b} | ${g.next_checkpoint} (${g.next_target}) | ${g.ordinary_levels_per_route_hour} | ${g.best_loop} | ${g.best_levels_per_grind_hour} | ${g.best_progress_gain_at_next_checkpoint} | ${g.best_route_hours_saved_to_target} | ${Object.entries(g.loops).map(([k,v])=>`${k} ${v.levels_per_grind_hour}`).join(', ')} |`);
  lines.push('','| Biome | Ordinary defeats | Implied fight hours | Budget hours | On-route candy levels | Master Tether Candy |','|---|---:|---:|---|---:|---:|');
  for (const c of report.census) lines.push(`| ${c.biome} | ${c.ordinary_defeats} | ${c.implied_fight_hours} | ${c.time_budget_hours.join('–')} | ${c.on_route_candy_levels} | ${c.master_tether_candy} |`);
  lines.push('','Findings:',...report.findings.map(f=>`- ${f.kind}: ${f.detail ?? JSON.stringify(f.deficits)}`),'',
    'Assumptions are listed in full in report.json `assumptions`; inputs are pinned by sha256 in `manifest`.');
  return lines.join('\n')+'\n';
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const report = routeReport();
  const json = JSON.stringify(report,null,2)+'\n';
  if (process.argv.includes('--write')) {
    const dir = path.join(ROOT,'ralph/reports/TRAINING/f27/route-ledger');
    fs.mkdirSync(dir,{recursive:true});
    fs.writeFileSync(path.join(dir,'report.json'),json);
    fs.writeFileSync(path.join(dir,'report.md'),summaryMarkdown(report));
  }
  process.stdout.write(json);
}
