import {readFileSync} from 'node:fs';
import assert from 'node:assert/strict';

// Authored-content integrity only: this audit never claims runtime, save,
// multiplayer or visual proof. Run from the feature checkout root.
const json = path => JSON.parse(readFileSync(path.replace(/^res:\/\//, ''), 'utf8'));
const portals = json('data/config/portals.json');
const stones = json('data/config/waystones.json');
const items = json('data/items/items.json').items;
const opening = json('data/dialogue/opening.json').conversations;
const order = json('data/config/biome_order.json');
assert.equal(portals.home_key.raise_seconds, 2);
assert.equal(portals.arches.length, 8);
assert.equal(portals.arches[0].biome, 'meadows');
const ids = new Set();
const counts = Object.fromEntries(order.live.map(id => [id, 0]));
const nested = (row, path) => path.split('.').reduce((value, field) => value[field], row);
for (const row of stones.waystones) {
  assert(!ids.has(row.id), `duplicate waystone ${row.id}`);
  ids.add(row.id);
  assert(order.live.includes(row.biome), `nonlive biome ${row.id}`);
  counts[row.biome]++;
  assert.equal(row.realm_id, order.runtime_aliases[row.biome] ?? row.biome);
  const source = row.source;
  const anchor = nested(json(source.path), source.collection).find(value => value[source.id_field ?? 'id'] === source.id);
  assert(anchor, `missing anchor ${row.id}`);
  const at = nested(anchor, source.coordinate_field);
  assert.deepEqual(row.position_xz, [at[0], at.at(-1)], `stale XZ ${row.id}`);
  if (at.length === 3) assert.equal(row.preferred_y, at[1], `stale platform ${row.id}`);
  assert(row.offset_xz.length === 2 && row.arrival_offset_xz.length === 2);
}
for (const [biome, count] of Object.entries(counts)) assert(count >= 3 && count <= 5, `${biome} count ${count}`);
for (const id of ['home_key','tidewake_portal_key','cloudreach_portal_key','stormwood_portal_key','fifth_portal_key']) {
  assert.equal(items[id].kind, 'key');
  assert.equal(items[id].stack, 1);
  assert.equal(items[id].scope, 'character');
  assert.equal(items[id].protected_key, true);
  for (const flag of ['droppable','sellable','tradeable','death_satchel']) assert.equal(items[id][flag], false);
}
assert.equal(opening.grandpa_first_catch.lines.filter(line => line?.effect === 'home_key:grant').length, 1);
assert.equal(order.legacy_physical_crossings, false);
console.log(JSON.stringify({check: 'F18 authored content integrity', result: 'PASS', counts, total: ids.size,
  limitations: 'No engine, runtime item protection, save, co-op, ordinary input or visual proof.'}, null, 2));
