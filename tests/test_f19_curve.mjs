import assert from 'node:assert/strict';
import fs from 'node:fs';
import {execFileSync} from 'node:child_process';

// F19#1 shipped content proof; every production provider reads these live levels.
const live = name => JSON.parse(fs.readFileSync(`data/config/${name}.json`, 'utf8'));
const candidate = live('redesign_level_curve');
assert.equal(candidate.runtime_enabled, true, 'RD-10 production activation');
const read = name => {
  const data = live(name);
  const path = `data/config/${name}.json`;
  const resolve = tokens => tokens.reduce((node, token) => node?.[token], data);
  for (const row of candidate.overlays[path] || []) {
    for (const anchor of row.anchors) assert.equal(resolve(anchor.at), anchor.value, `${path} stable identity`);
    const parent = resolve(row.at.slice(0, -1));
    const key = row.at.at(-1);
    assert.equal(parent[key], row.value, `${path} materialized live input`);
  }
  if (name === 'chapter_curve') assert.deepEqual(data.biomes, candidate.biomes);
  return data;
};
const curve = read('chapter_curve');
const order = read('biome_order');
assert.deepEqual(order.live, ['meadows', 'tidewake', 'cloudreach', 'stormwood']);
const expected = {
  meadows: [[3, 22], [2, 20], [21, 22]],
  tidewake: [[20, 33], [18, 32], [32, 33]],
  cloudreach: [[31, 44], [29, 43], [43, 44]],
  stormwood: [[42, 55], [40, 54], [54, 55]],
};
for (const [biome, [team, wild, boss]] of Object.entries(expected)) {
  assert.deepEqual(curve.biomes[biome].team, team, biome);
  assert.deepEqual(curve.biomes[biome].wild, wild, biome);
  assert.deepEqual(curve.biomes[biome].boss, boss, biome);
  assert.equal(curve.biomes[biome].recommended_level, team[0], biome);
}
const runtimeOrder = order.live.map(id => order.runtime_aliases[id] || id);
assert.deepEqual(Object.keys(read('realm_hearts').hearts), runtimeOrder, 'relic display order');
assert.deepEqual(Object.keys(read('realm_hearts').realms), runtimeOrder, 'realm map order');
const meadowSpawns = curve.regions.flatMap(r => read(`bands/${r.id}/spawns`).spawns);
let lowerZ = -Infinity;
for (const region of curve.regions) {
  const species = new Set(meadowSpawns.filter(s => s.centre[2] >= lowerZ && s.centre[2] < region.z_to).map(s => s.species));
  assert.ok(species.size >= curve.five_slot.min_distinct_wild_species, `${region.id} replacement choices`);
  assert.ok(region.wild_band[1] >= region.team.enter - curve.five_slot.max_catch_level_deficit, `${region.id} catch deficit`);
  lowerZ = region.z_to;
}
assert.deepEqual(Object.fromEntries(Object.entries(read('chapter_rewards').boss_handoffs).map(([id, r]) => [id, [r.biome, r.key_item, r.relic_biome, r.next_biome]])), {
  warden_aldis: ['meadows', 'tidewake_portal_key', 'meadows', 'tidewake'],
  water_trainer_nerissa: ['tidewake', 'cloudreach_portal_key', 'water', 'cloudreach'],
  captain_veyra_storm_anchor: ['cloudreach', 'stormwood_portal_key', 'cloudreach', 'stormwood'],
  captain_marrow_dynamo_core: ['stormwood', 'fifth_portal_key', 'stormwood', 'biome5'],
}, 'authored boss handoff contract (not runtime delivery proof)');
const handoffs = read('chapter_rewards').boss_handoffs;
for (const [boss, flags] of [
  ['water_trainer_nerissa', ['water_guardian_settled']],
  ['captain_marrow_dynamo_core', ['stormwood:legendary_offer_made']],
]) {
  assert.equal(handoffs[boss].delivery_phase, 'accepted_legendary_settlement', `${boss} must defer boss drops until ceremony settlement`);
  assert.deepEqual(handoffs[boss].delivery_requires_world_flags, flags, `${boss} canonical world settlement marker`);
}
for (const boss of ['warden_aldis', 'captain_veyra_storm_anchor']) {
  assert.equal(handoffs[boss].delivery_phase, 'accepted_boss_victory');
  assert.deepEqual(handoffs[boss].delivery_requires_world_flags, []);
}

let previousExit = 0, previousWild = [0, 0];
const meadowTrainers = [];
for (const region of curve.regions) {
  assert.ok(region.team.enter >= previousExit, region.id);
  assert.ok(region.wild_band[0] >= previousWild[0] && region.wild_band[1] >= previousWild[1], region.id);
  assert.ok(region.wild_band[0] <= region.team.enter && region.wild_band[1] <= region.team.exit, region.id);
  assert.ok(region.wild_band[1] >= region.team.enter - 1, region.id);
  previousExit = region.team.exit; previousWild = region.wild_band;
  for (const trainer of read(`bands/${region.id}/trainers`).trainers) {
    assert.ok(trainer.team.length > 0 && trainer.team.length <= 5, trainer.id);
    for (const member of trainer.team) assert.ok(member.level >= region.trainer_levels[0] && member.level <= region.trainer_levels[1], trainer.id);
    meadowTrainers.push(trainer);
  }
}
assert.equal(curve.regions[0].team.enter, 3);
assert.equal(previousExit, 22);
assert.deepEqual(meadowTrainers.find(t => t.id === 'warden_aldis').team.map(m => m.level), [21, 21, 21, 22, 22]);
const cloud = read('cloudreach_chapter');
const water = read('water_characters');
const storm = read('stormwood_trainers');
const sets = [
  ['cloudreach', cloud.trainer_ladder, r => r.team_contract.slots],
  ['tidewake', water.trainers, r => r.team],
  ['stormwood', storm.trainers, r => r.party],
];
let namedTeamCount = meadowTrainers.length;
for (const [biome, rows, members] of sets) {
  const [lo, hi] = expected[biome][0];
  for (const trainer of rows) {
    const team = members(trainer); namedTeamCount++;
    assert.ok(team.length > 0 && team.length <= 5, trainer.id);
    for (const member of team) assert.ok(member.level >= lo && member.level <= hi, trainer.id);
    if (trainer.ace_level !== undefined) assert.equal(trainer.ace_level, Math.max(...team.map(m => m.level)), trainer.id);
    if (trainer.level_band) assert.deepEqual(trainer.level_band, [Math.min(...team.map(m => m.level)), Math.max(...team.map(m => m.level))], trainer.id);
  }
}
assert.deepEqual(cloud.trainer_ladder.find(r => r.id === 'captain_veyra_storm_anchor').team_contract.slots.map(r => r.level), [43, 43, 44]);
assert.deepEqual(cloud.final_encounter.opposition_contract.slots.map(r => r.level), [43, 43, 44]);
assert.deepEqual(water.trainers.find(r => r.id === 'water_trainer_nerissa').team.map(r => r.level), [32, 32, 33, 33]);
assert.deepEqual(storm.trainers.find(r => r.id === 'captain_marrow_dynamo_core').party.map(r => r.level), [54, 54, 54, 55, 55]);

const tables = [
  ['cloudreach', cloud.encounter_tables],
  ['tidewake', read('water_encounters').tables],
  ['stormwood', read('stormwood_encounters').tables],
];
let tableCount = 0;
for (const [biome, rows] of tables) {
  const [lo, hi] = expected[biome][1];
  for (const table of rows) {
    assert.ok(table.level_range[0] >= lo && table.level_range[0] <= table.level_range[1] && table.level_range[1] <= hi, table.id);
    tableCount++;
  }
  assert.equal(Math.min(...rows.map(r => r.level_range[0])), lo, biome);
  assert.equal(Math.max(...rows.map(r => r.level_range[1])), hi, biome);
  const tableMap = new Map(rows.map(r => [r.id, r]));
  const assigned = new Set();
  let previousExit = expected[biome][0][0];
  const worldIds = new Set(read(biome === 'tidewake' ? 'water_world' : `${biome}_world`).regions.map(r => r.id));
  for (const region of curve.biomes[biome].regional_targets) {
    assert.ok(worldIds.has(region.region_id), `${biome}:${region.region_id} canonical region`);
    const [entry, exit] = region.team;
    if (!region.optional) {
      assert.equal(entry, previousExit, `${biome}:${region.region_id} contiguous main route`);
      previousExit = exit;
    }
    for (const id of region.tables) {
      assert.ok(tableMap.has(id) && !assigned.has(id), `${biome}:${id} exactly one regional target`);
      assigned.add(id);
      const [low, high] = tableMap.get(id).level_range;
      assert.ok(low <= entry && high <= exit, `${biome}:${id} field within regional team target`);
      assert.ok(high >= entry - curve.five_slot.max_catch_level_deficit, `${biome}:${id} replacement catch deficit`);
    }
  }
  assert.equal(previousExit, expected[biome][0][1], `${biome} regional exit`);
  assert.deepEqual(assigned, new Set(tableMap.keys()), `${biome} all regional wild tables assigned`);
}
// Progression within each route, including weather variants and optional high perches.
for (const rows of [cloud.encounter_tables.filter(r => !r.id.includes('released') && !r.id.includes('restored')), read('water_encounters').tables]) {
  let previous = [0, 0];
  for (const row of rows) {
    assert.ok(row.level_range[0] >= previous[0] && row.level_range[1] >= previous[1], row.id);
    previous = row.level_range;
  }
}
for (const phase of ['calm', 'surge']) {
  let previous = [0, 0];
  for (const row of read('stormwood_encounters').tables.filter(r => r.surge_phase === phase)) {
    assert.ok(row.level_range[0] >= previous[0] && row.level_range[1] >= previous[1], row.id);
    previous = row.level_range;
  }
}
assert.equal(read('stormwood_encounters').legendary_placeholder.placeholder_species, 'fulgocobra');
assert.equal(read('stormwood_encounters').legendary_placeholder.catchable, false);

// Preserve the historical fixture as evidence. Only its level fields differ
// from current production; encounter identity and every other field stay exact.
const fixture = JSON.parse(fs.readFileSync('tests/fixtures/band_split_baseline/trainers.json')).trainers;
const merged = curve.regions.flatMap(region => live(`bands/${region.id}/trainers`).trainers).toSorted((a, b) => a.order - b.order);
const pinnedFixture = JSON.parse(execFileSync('git', ['show', '5c2c964ebaa8e25f933355324725be324218bc44:tests/fixtures/band_split_baseline/trainers.json'], {encoding: 'utf8'}));
assert.deepEqual(fixture.map(r => r.id), pinnedFixture.trainers.map(r => r.id), 'preserve pre-split mirror census and identity');
for (let i = 0; i < fixture.length; i++) {
  const {order, ...entry} = merged[i];
  assert.equal(order, i, `baseline seeded trainer order ${i}`);
  const withoutLevels = value => JSON.parse(JSON.stringify(value, (key, v) => key === 'level' ? undefined : v));
  assert.deepEqual(withoutLevels(entry), withoutLevels(fixture[i]), `baseline trainer ${i} non-level behavior`);
}
for (const [name, sitesKey, tableRows, tableFields] of [
  ['cloudreach_encounters', 'wild_sites', cloud.encounter_tables, ['table_id']],
  ['water_encounters', 'wild_sites', read('water_encounters').tables, ['table_id']],
  ['stormwood_encounters', 'wild_clusters', read('stormwood_encounters').tables, ['calm_table_id', 'surge_table_id']],
]) {
  const ids = new Set(tableRows.map(r => r.id));
  const used = new Set();
  for (const site of read(name)[sitesKey]) for (const field of tableFields) {
    assert.ok(ids.has(site[field]), `${name}:${site.id}:${field} missing authored table`);
    used.add(site[field]);
  }
  assert.deepEqual(used, ids, `${name} unused authored wild table`);
}
const cloudTrainerIds = new Set(cloud.trainer_ladder.map(r => r.id));
assert.deepEqual(new Set(read('cloudreach_encounters').trainers.map(r => r.id)), cloudTrainerIds, 'Cloudreach placement/ladder linkage');
const baseline = process.env.F19_BASELINE || '5c2c964ebaa8e25f933355324725be324218bc44';
for (const region of curve.regions) {
  const path = `data/config/bands/${region.id}/trainers.json`;
  const old = JSON.parse(execFileSync('git', ['show', `${baseline}:${path}`], {encoding: 'utf8'}));
  const current = read(`bands/${region.id}/trainers`);
  const withoutLevels = value => JSON.parse(JSON.stringify(value, (key, v) => key === 'level' ? undefined : v));
  assert.deepEqual(withoutLevels(current.trainers), withoutLevels(old.trainers), `${region.id} trainer identity and non-level behavior`);
}
for (const [name, key] of [['cloudreach_encounters', 'wild_sites'], ['stormwood_encounters', 'wild_clusters'], ['water_encounters', 'wild_sites']]) {
  const old = JSON.parse(execFileSync('git', ['show', `${baseline}:data/config/${name}.json`], {encoding: 'utf8', maxBuffer: 4 * 1024 * 1024}));
  assert.deepEqual(read(name)[key], old[key], `${name} seeded placement identity`);
}
console.log(JSON.stringify({proof: 'F19-live-curve', named_teams: namedTeamCount, regional_wild_tables: tableCount, biome_order: order.live, result: 'PASS', scope: 'enabled authored content only; historical fixture retained; no engine, earning, transaction or legendary-offer proof'}));
