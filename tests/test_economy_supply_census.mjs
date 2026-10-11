import test from 'node:test';
import assert from 'node:assert/strict';
import {supplyCensus} from '../tools/economy_supply_census.mjs';

// F47#2. Expected to fail while a band is insolvent: that is a balance finding,
// never a reason to tune numbers inside this test.
const census = supplyCensus();

test('census reads real site lists for all four live biomes', () => {
  assert.deepEqual(census.bands.map(b => b.realm), ['meadows', 'water', 'cloudreach', 'stormwood']);
  for (const band of census.bands) {
    assert.ok(band.site_kinds.renewable > 0, `${band.band} has no renewable material sites`);
    assert.ok(band.site_kinds.essence > 0, `${band.band} has no essence nodes`);
    assert.ok(band.route_days > 0 && band.materials.length > 0, `${band.band} has no route time or demand`);
  }
});

for (const band of supplyCensus().bands) {
  test(`four-character contention ledger is solvent: ${band.band}`, () => {
    const short = census.shortfalls.filter(s => s.band === band.band);
    assert.ok(band.solvent, `${band.band} shortfalls: ${JSON.stringify(short)}`);
  });
}
