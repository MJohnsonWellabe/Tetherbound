import test from 'node:test';
import assert from 'node:assert/strict';
import {supplyCensus} from '../tools/economy_supply_census.mjs';

// F47#2. Asserts REQUIRED-demand solvency (upgrade 0, attuned pooled). A failure is a
// balance finding, never a reason to tune numbers inside this test.
const census = supplyCensus();

test('census reads real site lists and Master chests for all four live biomes', () => {
  assert.deepEqual(census.bands.map(b => b.realm), ['meadows', 'water', 'cloudreach', 'stormwood']);
  for (const band of census.bands) {
    assert.ok(band.site_kinds.renewable_site > 0, `${band.band} has no renewable material sites`);
    assert.ok(band.site_kinds.essence_node > 0, `${band.band} has no essence nodes`);
    assert.ok(band.route_days > 0 && band.required.materials.length > 0, `${band.band} has no route time or demand`);
    assert.ok(band.required.materials.some(m => m.sources.master_chest > 0), `${band.band} counted no Master chest`);
  }
});

for (const band of census.bands) {
  test(`four-character contention ledger is solvent (required demand): ${band.band}`, () => {
    assert.ok(band.required.solvent, `${band.band} shortfalls: ${JSON.stringify(census.shortfalls.filter(s => s.band === band.band))}`);
  });
}
