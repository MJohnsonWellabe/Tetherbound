import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {execFileSync} from 'node:child_process';
import {parseSaveDocument} from './save_document.mjs';

// Promote byte-identical production handoffs only after the continuous fresh
// campaign has completed. No save payload is edited, migrated or synthesized.
// CI artifacts may be downloaded to another host. The explicit relocation
// option keeps the original runner paths in provenance and still requires all
// five receipts and every production byte to match the unedited witness.
// node tools/earned_saves/promote_f19.mjs <campaign.log> <handoffs directory> [--relocated-from-ci]
const [logFile, handoffDirectory, relocation] = process.argv.slice(2);
assert.ok(logFile && handoffDirectory, 'Expected campaign log and immutable handoff directory');
assert.ok(relocation === undefined || relocation === '--relocated-from-ci', 'Unknown promotion option');
const root = process.cwd();
assert.equal(fs.realpathSync(execFileSync('git', ['rev-parse', '--show-toplevel'], {encoding: 'utf8'}).trim()), fs.realpathSync(root), 'Run from the repository root');
const sourceRoot = fs.realpathSync(handoffDirectory);
const targetRoot = path.join(root, 'tests/fixtures/earned_saves/redesign');
const sha256 = file => crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
const log = fs.readFileSync(logFile, 'utf8');
assert.ok(!/(?:SCRIPT ERROR:|^ERROR:)/m.test(log), 'Engine errors invalidate a campaign witness');
const lines = log.split(/\r?\n/);
const readLine = prefix => {
  const found = lines.filter(line => line.startsWith(prefix));
  assert.equal(found.length, 1, `Exactly one ${prefix} required`);
  return JSON.parse(found[0].slice(prefix.length));
};
const result = readLine('FRESH CAMPAIGN RESULT ');
assert.equal(result.counts_as_proof, true, 'A resumed, legacy, dry or failed campaign is not earned proof');
assert.equal(result.campaign_complete, true);
assert.deepEqual(result.failures, []);
assert.equal(result.resumed_from, '');
assert.equal(result.dry_run, false);
const journey = readLine('F49 JOURNEY ');
assert.deepEqual(journey.order, ['meadows', 'tidewake', 'cloudreach', 'stormwood', 'homecoming_credits']);
const offloadLines = lines.filter(line => line.startsWith('F19 FUNCTIONAL OFFLOAD '));
assert.ok(offloadLines.length <= 1, 'A single functional offload configuration is allowed');
const offload = offloadLines.length ? readLine('F19 FUNCTIONAL OFFLOAD ') : null;
if (offload) {
  assert.equal(offload.scenario, 'full_fresh_campaign');
  assert.equal(offload.rendering_method, 'gl_compatibility');
  assert.equal(offload.continuous_drawing, false);
  assert.equal(offload.ordinary_controller_physics_saves, true);
}
const emitted = lines.filter(line => line.startsWith('F49 DISK HANDOFF '))
  .map(line => JSON.parse(line.slice('F49 DISK HANDOFF '.length)));
const boundaries = ['meadows_settled', 'tidewake_settled', 'cloudreach_settled', 'stormwood_settled', 'completed_world'];
const bosses = ['warden_aldis', 'water_trainer_nerissa', 'captain_veyra_storm_anchor', 'captain_marrow_dynamo_core'];
assert.deepEqual(emitted.map(row => row.boundary), boundaries, 'Each actual new boundary must be captured in order');
let sourceCommit = '';
let emittedRoot = '';
let savedWorldSeed;
const candidates = [];
for (let index = 0; index < boundaries.length; index++) {
  const boundary = boundaries[index];
  const directory = path.join(sourceRoot, boundary);
  const receiptFile = path.join(directory, 'receipt.json');
  const receipt = parseSaveDocument(fs.readFileSync(receiptFile, 'utf8'));
  assert.equal(receipt.kind, 'f49_ordinary_input_handoff');
  assert.equal(receipt.boundary, boundary);
  assert.match(receipt.commit, /^[0-9a-f]{40}$/);
  sourceCommit ||= receipt.commit;
  assert.equal(receipt.commit, sourceCommit);
  assert.equal(emitted[index].commit, sourceCommit);
  const originalPath = emitted[index].path.replaceAll('\\', '/');
  assert.ok(path.posix.isAbsolute(originalPath) || /^[A-Za-z]:\//.test(originalPath), 'Absolute original runner path required');
  assert.equal(path.posix.normalize(originalPath), originalPath, 'Original paths must be canonical');
  assert.equal(path.posix.basename(originalPath), boundary, 'Original runner path must identify this boundary');
  emittedRoot ||= path.posix.dirname(originalPath);
  assert.equal(path.posix.dirname(originalPath), emittedRoot, 'All five boundaries must come from the same original handoff root');
  if (relocation === undefined) assert.equal(fs.realpathSync(emitted[index].path), fs.realpathSync(directory));
  assert.deepEqual(receipt.files_sha256, emitted[index].files_sha256);
  assert.equal(receipt.realm, ['meadows', 'water', 'cloudreach', 'stormwood', 'meadows'][index]);
  assert.ok(receipt.state.party.length > 0 && receipt.state.party.length <= 5);
  assert.ok(receipt.state.character_id);
  assert.equal(receipt.state.realm, receipt.realm);
  const files = [];
  const walk = dir => {
    for (const item of fs.readdirSync(dir, {withFileTypes: true})) {
      assert.ok(!item.isSymbolicLink(), 'Symlinks cannot redirect earned save bytes');
      const name = path.join(dir, item.name);
      if (item.isDirectory()) walk(name);
      else if (item.isFile()) files.push(name);
      else assert.fail('Unknown handoff entry');
    }
  };
  const saves = path.join(directory, 'save');
  walk(saves);
  const hashes = Object.fromEntries(files.map(file => [path.relative(saves, file).replaceAll('\\', '/'), sha256(file)]));
  assert.deepEqual(hashes, receipt.files_sha256, 'Exact production bytes must match the immutable receipt');
  assert.ok(files.some(file => file.endsWith(`${path.sep}character.json`)));
  assert.ok(files.some(file => file.endsWith(`${path.sep}world.json`)));
  for (const file of files.filter(file => file.endsWith(`${path.sep}character.json`) || file.endsWith(`${path.sep}world.json`))) {
    const envelope = parseSaveDocument(fs.readFileSync(file, 'utf8'));
    assert.equal(envelope.version, 28, `Current split schema required: ${file}`);
  }
  const biome = ['meadows', 'tidewake', 'cloudreach', 'stormwood'][Math.min(index, 3)];
  const held = receipt.state.redesign_character;
  assert.ok(held.relics_held.includes(biome) || held.relics_hung.includes(biome), `Actually earned ${biome} relic`);
  const boss = bosses[Math.min(index, 3)];
  assert.ok(held.transaction_receipts.some(id => id === `defeat:boss_${boss}:${receipt.state.character_id}` ||
    (id.startsWith(`defeat:boss_${boss}_`) && id.endsWith(`:${receipt.state.character_id}`))), `Exact ${boss} entitlement receipt required`);
  const characters = files.filter(file => file.endsWith(`${path.sep}character.json`))
    .map(file => parseSaveDocument(fs.readFileSync(file, 'utf8')))
    .filter(saved => saved.character_id === receipt.state.character_id);
  assert.equal(characters.length, 1, 'Exactly one actual saved owner must match the receipt character');
  const character = characters[0];
  assert.deepEqual(character.redesign_character, held, 'Printed entitlement state must match the production character bytes');
  assert.equal(character.party.length, receipt.state.party.length);
  for (let slot = 0; slot < character.party.length; slot++) {
    const saved = character.party[slot], observed = receipt.state.party[slot];
    assert.equal(saved.uid, observed.uid);
    assert.equal(saved.species_id, observed.species);
    assert.equal(saved.level, observed.level);
    assert.equal(saved.xp, observed.xp);
    assert.ok(Math.abs(saved.hp - observed.hp) <= 0.05001, 'Only disclosed receipt HP rounding is allowed');
    assert.equal(saved.fainted, observed.fainted);
  }
  const inventory = Object.fromEntries(character.inventory.flatMap((stack, slot) => stack ? [[String(slot), stack]] : []));
  assert.deepEqual(inventory, receipt.state.inventory, 'Observed inventory must be in the actual saved character');
  const worlds = files.filter(file => file.endsWith(`${path.sep}world.json`)).map(file => parseSaveDocument(fs.readFileSync(file, 'utf8')));
  assert.equal(worlds.length, 1, 'A fresh campaign must retain exactly its actual world');
  const world = worlds[0];
  const population = receipt.population_provenance;
  assert.ok(population && typeof population === 'object', 'Actual population seed provenance required');
  assert.ok(Number.isSafeInteger(world.world_seed), 'Actual fresh saved world seed required');
  assert.equal(receipt.state.world_seed, world.world_seed, 'Observed world seed must match actual save bytes');
  assert.deepEqual(population, emitted[index].population_provenance, 'Seed provenance must match actual handoff log');
  assert.equal(population.saved_world_seed, world.world_seed, 'Population provenance must name actual saved world');
  assert.equal(population.effective_encounter_seed, world.world_seed,
    'Encounter override differs from saved population; ordinary reload cannot reproduce played population');
  assert.equal(typeof population.has_environment_override, 'boolean');
  assert.equal(typeof population.environment_override, 'string');
  if (population.has_environment_override) {
    assert.match(population.environment_override.trim(), /^[+-]?\d+$/, 'Numeric encounter override required');
    assert.equal(Number(population.environment_override.trim()), world.world_seed, 'Override must match saved population');
  } else assert.equal(population.environment_override, '');
  savedWorldSeed ??= world.world_seed;
  assert.equal(world.world_seed, savedWorldSeed, 'All boundaries retain the original fresh world seed');
  assert.ok(typeof world.reward_delivery_namespace === 'string' && world.reward_delivery_namespace.length > 0);
  const flags = [...new Set([...world.flags.flags, ...character.flags.flags])].sort();
  assert.deepEqual(flags, receipt.state.flags, 'Observed progression must match the actual split files');
  const namespaceHash = crypto.createHash('sha256').update(world.reward_delivery_namespace).digest('hex');
  assert.ok(held.transaction_receipts.includes(`defeat:boss_${boss}:${receipt.state.character_id}`) ||
    held.transaction_receipts.includes(`defeat:boss_${boss}_${namespaceHash}:${receipt.state.character_id}`), 'Boss receipt must name the actual saved host world');
  const destination = path.join(targetRoot, boundary);
  assert.ok(!fs.existsSync(destination), `Never overwrite an existing earned fixture: ${destination}`);
  candidates.push({boundary, directory, destination, receipt});
}
// The evidence source must be committed and available for replay/review.
execFileSync('git', ['cat-file', '-e', `${sourceCommit}^{commit}`], {stdio: 'pipe'});
const provenance = {kind: 'f19_earned_boundary_promotion', source_commit: sourceCommit,
  command: `Godot 4.7 ${/^OpenGL.*(?:API|Renderer)/m.test(log) ? '' : '--headless '}--script tests/${offload ? 'smoke_f19_campaign_functional' : 'smoke_four_biome_continuous'}.gd`,
  functional_offload: offload,
  population_provenance: candidates.map(row => ({boundary: row.boundary, ...row.receipt.population_provenance})),
  source_log_sha256: sha256(logFile), journey, boundaries,
  transport: relocation ? {kind: 'downloaded_ci_artifact', original_handoff_root: emittedRoot, original_paths: emitted.map(row => row.path)} : {kind: 'local_original_paths'},
  disclosures: journey.shortcuts, scope: 'Earned progression/save boundaries; no hardware, timing or visual acceptance claim'};
for (const candidate of candidates) {
  fs.mkdirSync(path.dirname(candidate.destination), {recursive: true});
  fs.cpSync(candidate.directory, candidate.destination, {recursive: true, errorOnExist: true, force: false});
  fs.writeFileSync(path.join(candidate.destination, 'PROVENANCE.json'), JSON.stringify({...provenance, boundary: candidate.boundary}, null, 2) + '\n', {flag: 'wx'});
  for (const [file, hash] of Object.entries(candidate.receipt.files_sha256)) {
    assert.equal(sha256(path.join(candidate.destination, 'save', file)), hash, 'Promoted bytes must remain exact');
  }
}
console.log(JSON.stringify({proof: 'F19-earned-save-promotion', source_commit: sourceCommit, boundaries, result: 'PASS'}));
