import assert from 'node:assert/strict';
import fs from 'node:fs';

// F19#3 authored gate scan. Optional revisits remain optional: do not scan prose as gates.
const prefixes = ['water_', 'cloudreach_', 'stormwood_'];
const forbidden = {
  // Swim equipment and Dive belong to Tidewake itself. Their recipe/equipment
  // requirements are not a later-biome route dependency. Required human-swim
  // route coverage remains an engine witness, separately from this field scan.
  water_: /\bfly\b|fly_|\bwings\b|skyborne|realm_heart_cloudreach|realm_heart_stormwood|\bspark\b|livewire|solmane|stormheart/,
  cloudreach_: /realm_heart_stormwood|\bspark\b|livewire|stormheart|realm_relic_water_placed|water_guardian_joined|\bdive\b|dive_|swim_mount|swim_saddle/,
  stormwood_: /realm_relic_water_placed|water_guardian_joined|\bdive\b|dive_|swim_mount|swim_saddle|legendary_joined|solmane_joined|veridian_joined/,
};
const violations = [], scanned = [];
function walk(value, path, prefix, found = violations, inventory = scanned) {
  if (Array.isArray(value)) return value.forEach((v, i) => walk(v, `${path}[${i}]`, prefix, found, inventory));
  if (!value || typeof value !== 'object') return;
  for (const [key, child] of Object.entries(value)) {
    if (key.startsWith('_')) continue;
    const p = `${path}.${key}`;
    if (/^(requires(_.*)?|required_(flag|traversal)|gate_flag|condition_flag|unless_flag|unlock_flag|unlocked_by|if_flag|traversal_mode)$/.test(key) || (key === 'mode' && path.endsWith('.access'))) {
      inventory.push(p);
      if (forbidden[prefix].test(JSON.stringify(child))) found.push({path: p, value: child});
    }
    walk(child, p, prefix, found, inventory);
  }
}
// Prove that nested authored requirements cannot quietly evade the scan.
for (const [prefix, gate] of [
  ['water_', {requires: {traversal: 'fly'}}],
  ['water_', {access: {mode: 'fly_mount'}}],
  ['water_', {requires_personal_flags: ['realm_heart_cloudreach_placed']}],
  ['cloudreach_', {unless_flag: 'realm_heart_stormwood_placed'}],
  ['stormwood_', {required_flag: 'solmane_joined'}],
]) {
  const found = [];
  walk(gate, 'negative_fixture', prefix, found, []);
  assert.equal(found.length, 1, `${prefix} forbidden prerequisite must be detected`);
}
for (const file of fs.readdirSync('data/config')) {
  const prefix = prefixes.find(p => file.startsWith(p));
  if (prefix && file.endsWith('.json')) walk(JSON.parse(fs.readFileSync(`data/config/${file}`)), file, prefix);
}
assert.ok(scanned.length > 100, 'gate inventory unexpectedly empty');
assert.deepEqual(violations, [], 'later relic/legendary/traversal prerequisite found');
console.log(JSON.stringify({proof: 'F19-authored-gate-scan', gate_fields: scanned.length, result: 'PASS', scope: 'JSON prerequisite fields; runtime route proof still required'}));
