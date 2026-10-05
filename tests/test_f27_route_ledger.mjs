import test from 'node:test';
import assert from 'node:assert/strict';
import * as L from '../tools/f27_route_ledger.mjs';

const s = L.loadSources();
const report = L.routeReport();

// Expected values were printed by a headless Godot run calling the GDScript
// functions themselves (progression.gd xp_to_next/raw_xp_award_for/scaled_combat_xp/
// scaled_party_combat_xp/staged_xp, essence.gd level_cost/defeat_payout/release_payout)
// against the current data/config/progression.json and essence.json.
const GODOT = {
  xp:[40,88,141,196,254,314,374,437,500,565,630,696,764,831,900,970,1040,1110,1182,1253,1326,1399,1472,1546,1620,1695,1770,1846,1922,1998,2075,2152,2230,2308,2386,2464,2543,2623,2702,2782,2862,2943,3023,3104,3186,3267,3349,3431,3513,3596,3679,3762,3845,3929,4013,4097,4181,4265,4350,4435],
  raw:[46,62,78,94,110,126,142,158,174,190,206,222,238,254,270,286,302,318,334,350,366,382,398,414,430,446,462,478,494,510,526,542,558,574,590,606,622,638,654,670,686,702,718,734,750,766,782,798,814,830,846,862,878,894,910,926,942,958,974,990],
  scaled:[16,21,27,32,38,44,49,55,60,66,72,77,83,88,94,100,105,111,116,122,128,133,139,144,150,156,161,167,172,178,184,189,195,200,206,212,217,223,228,234,240,245,251,256,262,268,273,279,284,290,296,301,307,312,318,324,329,335,340,346],
  share:[8,10,13,16,19,22,24,27,30,33,36,38,41,44,47,50,52,55,58,61,64,66,69,72,75,78,80,83,86,89,92,94,97,100,103,106,108,111,114,117,120,122,125,128,131,134,136,139,142,145,148,150,153,156,159,162,164,167,170,173],
  cost:[2,4,6,8,11,13,15,18,20,23,26,28,31,34,36,39,42,45,48,51,54,56,59,62,65,68,71,74,77,80,83,87,90,93,96,99,102,105,109,112,115,118,121,125,128,131,134,138,141,144,148,151,154,158,161,164,168,171,174],
  payouts:{'mudsnout@9':[[{type:'ground',n:1}],[{type:'ground',n:7}]],
    'nightburrow@13':[[{type:'ground',n:1},{type:'dark',n:1}],[{type:'ground',n:5},{type:'dark',n:4}]],
    'cannonback@26':[[{type:'water',n:3}],[{type:'water',n:16}]],
    'voltarach@54':[[{type:'electric',n:6}],[{type:'electric',n:30}]],
    'ashtusk@21':[[{type:'ground',n:2},{type:'fire',n:1}],[{type:'ground',n:7},{type:'fire',n:6}]]},
};

test('JS ports match the GDScript level, award, cost and payout arithmetic', () => {
  for (let l=1; l<=60; l++) {
    assert.equal(L.xpToNext(l,s.prog), GODOT.xp[l-1], `xp_to_next ${l}`);
    assert.equal(L.rawXpAward(l,s.prog), GODOT.raw[l-1], `raw award ${l}`);
    assert.equal(L.scaledCombatXp(l,s.prog,s.ess), GODOT.scaled[l-1], `hybrid award ${l}`);
    assert.equal(L.scaledPartyCombatXp(l,s.prog,s.ess), GODOT.share[l-1], `hybrid share ${l}`);
    if (l < 60) assert.equal(L.levelCost(l,s.ess,s.prog), GODOT.cost[l-1], `level cost ${l}`);
  }
  for (const [key,[defeat,release]] of Object.entries(GODOT.payouts)) {
    const [species,level] = key.split('@');
    assert.deepEqual(L.defeatPayout(Number(level),L.typesOf(s,species),s.ess), defeat, key);
    assert.deepEqual(L.releasePayout(Number(level),L.typesOf(s,species),s.ess), release, key);
  }
  assert.deepEqual(L.stagedXp({level:3,xp:0},10,500,s.prog), {level:5,xp:163});
  assert.deepEqual(L.stagedXp({level:9,xp:0},10,100000,s.prog), {level:10,xp:0}, 'a capped creature banks no XP');
  assert.deepEqual(L.stagedXp({level:10,xp:0},10,50,s.prog), {level:10,xp:0});
  assert.equal(s.ess.wild_victory_xp_mode, 'hybrid');
  assert.equal(L.scaledCombatXp(1,s.prog,{auto_xp_scale:0.0001}), 1, 'a positive award never floors to zero');
});

test('party award: active takes the hybrid award, each other member the share', () => {
  const team = Array.from({length:5},()=>({level:20,xp:0}));
  const next = L.combatPartyXp(team, 2, 30, 30, s.prog, s.ess);
  assert.deepEqual(next.map(m=>m.xp), [GODOT.share[29],GODOT.share[29],GODOT.scaled[29],GODOT.share[29],GODOT.share[29]]);
});

test('simulation spends essence on the lowest creature and Tether Candy pays a whole level', () => {
  const start = {team:[0,1,2,3,4].map(i=>({slot:i,level:i===0?3:5,xp:0,types:['any']})),pool:{},tetherCandy:0,rot:0,cap:10,research:new Map()};
  const out = L.simulate(start,[{kind:'essence',type:'ground',n:L.levelCost(3,s.ess,s.prog)},{kind:'tether_candy',n:1},{kind:'spend'}],
    {prog:s.prog,ess:s.ess,wildcard:true});
  assert.deepEqual(out.team.map(m=>m.level),[5,5,5,5,5]);
  const typed = L.simulate({...start,team:start.team.map(m=>({...m,types:['water']}))},[{kind:'essence',type:'ground',n:50},{kind:'spend'}],
    {prog:s.prog,ess:s.ess,wildcard:false});
  assert.deepEqual(typed.team.map(m=>m.level),[3,5,5,5,5],'mismatched essence cannot raise a creature');
});

test('report covers all four live biomes, the finale and the exit', () => {
  assert.deepEqual(s.order.live, ['meadows','tidewake','cloudreach','stormwood']);
  for (const sc of Object.values(report.scenarios)) {
    assert.deepEqual(sc.checkpoints.map(c=>c.checkpoint),
      ['meadows_entry','tidewake_entry','cloudreach_entry','stormwood_entry','stormwood_finale_ready','stormwood_exit']);
    for (const c of sc.checkpoints) assert.equal(c.pass, c.reached_average >= c.target);
  }
  assert.deepEqual(report.census.map(c=>c.biome), s.order.live);
  assert.deepEqual(Object.keys(report.grind), s.order.live);
  const targets = report.scenarios.ordinary_types_match.checkpoints.map(c=>c.target);
  assert.deepEqual(targets.slice(0,4), s.order.live.map(b=>s.curve.biomes[b].team[0]));
  assert.equal(report.manifest.length > 20 && report.manifest.every(m=>/^[0-9a-f]{64}$/.test(m.sha256)), true);
  assert.equal(report.verdict.acceptance_verified, false);
  assert.ok(report.assumptions.length >= 20);
});

test('ordinary path counts each authored encounter once and never optional content', () => {
  const regions = L.buildRoute(s);
  const optionalTrainers = new Set(regions.flatMap(r=>[...r.optional_trainers.map(t=>t.id),...(r.optional?r.trainers.map(t=>t.id):[])]));
  const optionalSites = new Set(regions.flatMap(r=>[...r.optional_sites.map(x=>x.id),...(r.optional?r.sites.map(x=>x.id):[]),...r.optional_fixed.map(f=>f.id)]));
  assert.ok(optionalTrainers.has('old_champion_bram') && optionalTrainers.has('patrol_ridgeline'));
  assert.ok(optionalTrainers.has('young_trainer_tavi_upper_ring') && optionalTrainers.has('water_trainer_tess') && optionalTrainers.has('rook_circuit_lantern'));
  assert.ok([...optionalSites].some(id=>id.startsWith('water_deep_watch_wild')));
  let defeats = 0;
  for (const region of regions.filter(r=>!r.optional)) {
    const ev = L.regionEvents(s, region, {});
    const sites = ev.filter(e=>e.kind==='defeat'&&e.essence).map(e=>e.site);
    assert.equal(new Set(sites).size, sites.length, `${region.region_id}: a wild site is fought twice`);
    for (const id of sites) assert.ok(!optionalSites.has(id), `${id} is optional`);
    for (const e of ev.filter(e=>e.trainer)) assert.ok(!optionalTrainers.has(e.trainer), `${e.trainer} is optional`);
    assert.equal(ev.filter(e=>e.kind==='defeat'&&e.essence).length,
      L.engagedSites(region.sites, L.ORDINARY_WILD_SITE_FRACTION).length*L.DEFEATS_PER_ENGAGED_SITE + region.fixed.length);
    defeats += ev.filter(e=>e.kind==='defeat').length;
  }
  for (const region of regions.filter(r=>r.optional)) for (const c of region.candies) assert.ok(!regions.filter(r=>!r.optional).some(r=>r.candies.includes(c)));
  const totals = report.scenarios.ordinary_types_match.totals;
  assert.equal(totals.defeats, defeats, 'the run fights exactly the enumerated ordinary encounters');
  assert.equal(report.census.find(c=>c.biome==='tidewake').on_route_candy_levels, 0);
  assert.ok(report.census.every(c=>c.required_catch_releases===0));
});

test('optional grinding pays in every biome and measurably speeds progress', () => {
  for (const biome of s.order.live) {
    const g = report.grind[biome];
    assert.ok(g.best_levels_per_grind_hour > 0, `${biome} grind rate`);
    assert.ok(Object.values(g.loops).some(l=>l.essence_per_hour > 0), `${biome} essence per hour`);
    assert.equal(g.any_loop_measurably_faster, true, `${biome} measurably faster`);
  }
  assert.equal(report.verdict.optional_grind_measurably_faster_every_biome, true);
});

test('verdict is derived from every checkpoint of the primary scenario', () => {
  const cps = report.scenarios.ordinary_types_match.checkpoints;
  assert.equal(report.verdict.mandatory_repeat_grinding, !cps.every(c=>c.pass));
  assert.equal(report.verdict.deficits.length, cps.filter(c=>!c.pass).length);
  assert.ok(report.verdict.break_even_wild_site_fraction > 0 && report.verdict.break_even_wild_site_fraction <= 1);
});
