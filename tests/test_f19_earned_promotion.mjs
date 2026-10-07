import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import crypto from 'node:crypto';
import {spawnSync} from 'node:child_process';
import {readCompatibilityManifest, reviewedCompatibilityCut, saveTreeDigest} from '../tools/earned_saves/promote_f19.mjs';

// Deliberately fabricated negative controls, never accepted/earned fixtures.
// The positive production promotion must use an actual continuous campaign.
const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'f19-promotion-negative-'));
const logFile = path.join(dir, 'campaign.log');
const handoffs = path.join(dir, 'handoffs');
const boundaries = ['meadows_settled', 'tidewake_settled', 'cloudreach_settled', 'stormwood_settled', 'completed_world'];
const result = {counts_as_proof: true, campaign_complete: true, failures: [], resumed_from: '', dry_run: false};
const journey = {order: ['meadows', 'tidewake', 'cloudreach', 'stormwood', 'homecoming_credits']};
const sha = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const emitted = [];
let checks = 0;
function writeLog(r = result, j = journey, rows = emitted, errors = '') {
  fs.writeFileSync(logFile, errors + `FRESH CAMPAIGN RESULT ${JSON.stringify(r)}\nF49 JOURNEY ${JSON.stringify(j)}\n` +
    rows.map(row => `F49 DISK HANDOFF ${JSON.stringify(row)}\n`).join(''));
}
function refused(reason, options = []) {
  const child = spawnSync(process.execPath, ['tools/earned_saves/promote_f19.mjs', logFile, handoffs, ...options], {encoding: 'utf8'});
  assert.notEqual(child.status, 0, reason);
  assert.match(child.stderr, reason);
  assert.ok(!child.stdout.includes('"result":"PASS"'));
  checks++;
}
try {
  fs.mkdirSync(handoffs);
  // Evidence-parser controls only. No save payload, earned receipt, fixture or
  // successful campaign is produced; these exact-cut records are fabricated.
  const manifestFile = path.join(dir, 'compatibility.json');
  const producerLog = path.join(dir, 'compatibility-producer.log');
  const producer = '1'.repeat(40), consumer = '2'.repeat(40);
  const binding = {boundary: 'opening_team', producer_commit: producer, run_id: '123', artifact_id: '456',
    artifact_sha256: 'a'.repeat(64), log_path: path.basename(producerLog), log_sha256: '',
    receipt_sha256: 'b'.repeat(64), files_sha256: {'slot_0.json': 'c'.repeat(64)}};
  fs.writeFileSync(producerLog, 'F49 DISK HANDOFF ' + JSON.stringify({boundary: binding.boundary,
    commit: producer, files_sha256: binding.files_sha256}) + '\n');
  binding.log_sha256 = sha(fs.readFileSync(producerLog));
  binding.save_tree_sha256 = saveTreeDigest(binding.files_sha256);
  const manifest = {kind: 'f49_reviewed_cross_cut', version: 1, producer_commit: producer, consumer_commit: consumer,
    imported_boundary: binding.boundary, prefix: [binding]};
  const writeCompatibility = (candidate = manifest, reviewChange = {}) => {
    fs.writeFileSync(manifestFile, JSON.stringify({...candidate, review: {verdict: 'compatible',
      reviewer: 'fabricated negative control', record_url: 'https://example.invalid/negative-control', ...reviewChange}}));
  };
  writeCompatibility();
  const actual = readCompatibilityManifest(manifestFile);
  const prefix = [{receipt: {boundary: binding.boundary, commit: producer, files_sha256: binding.files_sha256},
    receiptHash: binding.receipt_sha256, log_sha256: binding.log_sha256}];
  assert.equal(reviewedCompatibilityCut([actual], prefix, consumer, binding.boundary, actual.digest).digest, actual.digest);
  checks++;
  for (const [changedPrefix, changedConsumer, changedBoundary, digest] of [
    [prefix, '3'.repeat(40), binding.boundary, actual.digest],
    [prefix, consumer, 'camp_tournament', actual.digest],
    [prefix, consumer, binding.boundary, 'd'.repeat(64)],
    [[{...prefix[0], receiptHash: 'e'.repeat(64)}], consumer, binding.boundary, actual.digest],
    [[{...prefix[0], log_sha256: 'e'.repeat(64)}], consumer, binding.boundary, actual.digest],
    [[{...prefix[0], receipt: {...prefix[0].receipt, commit: '4'.repeat(40)}}], consumer, binding.boundary, actual.digest],
    [[{...prefix[0], receipt: {...prefix[0].receipt, files_sha256: {'slot_0.json': 'f'.repeat(64)}}}], consumer, binding.boundary, actual.digest],
    [[...prefix, prefix[0]], consumer, binding.boundary, actual.digest],
  ]) {
    assert.throws(() => reviewedCompatibilityCut([actual], changedPrefix, changedConsumer, changedBoundary, digest), /Missing exact reviewed/);
    checks++;
  }
  assert.throws(() => reviewedCompatibilityCut([], prefix, consumer, binding.boundary), /Missing exact reviewed/); checks++;
  for (const field of ['reviewer', 'record_url', 'verdict']) {
    for (const value of ['', null, 1, ' ']) {
      writeCompatibility(manifest, {[field]: value});
      assert.throws(() => readCompatibilityManifest(manifestFile), /reviewer verdict/); checks++;
    }
  }
  writeCompatibility(manifest, {verdict: 'not_compatible'});
  assert.throws(() => readCompatibilityManifest(manifestFile), /reviewer verdict/); checks++;
  for (const damaged of [null, {...manifest, prefix: null}, {...manifest, prefix: [null]},
    {...manifest, producer_commit: '3'.repeat(40)}]) {
    writeCompatibility(damaged);
    assert.throws(() => readCompatibilityManifest(manifestFile), /cut bindings/); checks++;
  }
  for (const value of [undefined, 'd'.repeat(64)]) {
    writeCompatibility({...manifest, prefix: [{...binding, save_tree_sha256: value}]});
    assert.throws(() => readCompatibilityManifest(manifestFile), /save-tree digest/); checks++;
  }
  for (const field of ['run_id', 'artifact_id', 'artifact_sha256', 'receipt_sha256', 'log_sha256', 'files_sha256']) {
    const damaged = {...manifest, prefix: [{...binding}]}; delete damaged.prefix[0][field];
    writeCompatibility(damaged);
    assert.throws(() => readCompatibilityManifest(manifestFile), /actual producer/); checks++;
  }
  for (const changes of [{boundary: null}, {boundary: ''}, {log_path: null}, {log_path: ' '},
    {run_id: '+123'}, {artifact_id: '0456'}, {files_sha256: null}]) {
    writeCompatibility({...manifest, prefix: [{...binding, ...changes}]});
    assert.throws(() => readCompatibilityManifest(manifestFile), /cut bindings|actual producer/); checks++;
  }
  writeCompatibility(); fs.appendFileSync(manifestFile, '\n');
  assert.throws(() => reviewedCompatibilityCut([actual], prefix, consumer, binding.boundary, actual.digest), /Missing exact reviewed/); checks++;
  writeCompatibility(); fs.appendFileSync(producerLog, '\n');
  assert.throws(() => readCompatibilityManifest(manifestFile), /producer log digest/); checks++;
  assert.throws(() => reviewedCompatibilityCut([actual], prefix, consumer, binding.boundary, actual.digest), /producer log digest/); checks++;
  fs.writeFileSync(producerLog, 'F49 DISK HANDOFF null\n');
  writeCompatibility({...manifest, prefix: [{...binding, log_sha256: sha(fs.readFileSync(producerLog))}]});
  assert.throws(() => readCompatibilityManifest(manifestFile), /Malformed compatibility producer handoff/); checks++;
  // Restore only the fabricated evidence document, never any save bytes.
  fs.writeFileSync(producerLog, 'F49 DISK HANDOFF ' + JSON.stringify({boundary: binding.boundary,
    commit: consumer, files_sha256: binding.files_sha256}) + '\n');
  writeCompatibility({...manifest, prefix: [{...binding, log_sha256: sha(fs.readFileSync(producerLog))}]});
  assert.throws(() => readCompatibilityManifest(manifestFile), /log producer cut/); checks++;
  writeLog(result, journey, [], 'SCRIPT ERROR: deliberately injected negative control\n');
  refused(/Engine errors invalidate/);
  writeLog({...result, counts_as_proof: false, resumed_from: 'water_arrival'});
  refused(/resumed, legacy, dry or failed/);
  writeLog(result, {order: ['meadows', 'cloudreach', 'stormwood', 'tidewake']});
  refused(/deep-equal/);
  writeLog();
  refused(/Each actual new boundary/);
  for (let index = 0; index < boundaries.length; index++) {
    const boundary = boundaries[index];
    const directory = path.join(handoffs, boundary);
    fs.mkdirSync(path.join(directory, 'save'), {recursive: true});
    const bytes = JSON.stringify({version: 28});
    const files_sha256 = {'character.json': sha(bytes), 'world.json': sha(bytes)};
    fs.writeFileSync(path.join(directory, 'save/character.json'), bytes);
    fs.writeFileSync(path.join(directory, 'save/world.json'), bytes);
    const realm = ['meadows', 'water', 'cloudreach', 'stormwood', 'meadows'][index];
    const receipt = {kind: 'f49_ordinary_input_handoff', boundary, commit: '0'.repeat(40), realm, files_sha256,
      state: {realm, character_id: 'negative-control', party: [{}], redesign_character: {
        relics_held: ['meadows', 'tidewake', 'cloudreach', 'stormwood'], relics_hung: [], transaction_receipts: []}}};
    fs.writeFileSync(path.join(directory, 'receipt.json'), JSON.stringify(receipt));
    emitted.push({boundary, commit: receipt.commit, path: directory, files_sha256});
  }
  const firstSave = path.join(handoffs, boundaries[0], 'save/character.json');
  fs.writeFileSync(firstSave, JSON.stringify({version: 28, injected: true}));
  writeLog();
  refused(/Exact production bytes/);
  fs.writeFileSync(firstSave, JSON.stringify({version: 28}));
  writeLog();
  refused(/Exact warden_aldis entitlement receipt required/);
  const firstReceipt = path.join(handoffs, boundaries[0], 'receipt.json');
  const metadata = JSON.parse(fs.readFileSync(firstReceipt, 'utf8'));
  metadata.state.redesign_character.transaction_receipts.push('defeat:boss_warden_aldis:negative-control');
  fs.writeFileSync(firstReceipt, JSON.stringify(metadata));
  writeLog();
  refused(/Exactly one actual saved owner/);
  const remote = emitted.map(row => ({...row, path: `/runner/user/campaign_handoffs/${row.boundary}`}));
  writeLog(result, journey, remote);
  refused(/Exactly one actual saved owner/, ['--relocated-from-ci']);
  writeLog(result, journey, remote.map((row, index) => index === 0 ? {...row, path: '/runner/user/campaign_handoffs/other_boundary'} : row));
  refused(/Original runner path must identify this boundary/, ['--relocated-from-ci']);
  // Codec-wrapped forged evidence must remain rejected; no positive campaign
  // or earned target is constructed by these controls.
  const codec = payload => JSON.stringify({format: 'tetherbound-save', codec_version: 1, payload});
  const wrappedSave = codec({version: 28});
  fs.writeFileSync(firstSave, wrappedSave);
  metadata.files_sha256['character.json'] = sha(wrappedSave);
  emitted[0].files_sha256['character.json'] = sha(wrappedSave);
  fs.writeFileSync(firstReceipt, codec(metadata));
  writeLog();
  refused(/Exactly one actual saved owner/);
  const invalidSave = codec({version: 28, x: {$tb_int64: '9223372036854775808'}});
  fs.writeFileSync(firstSave, invalidSave);
  metadata.files_sha256['character.json'] = sha(invalidSave);
  emitted[0].files_sha256['character.json'] = sha(invalidSave);
  fs.writeFileSync(firstReceipt, codec(metadata));
  writeLog();
  refused(/Invalid production save codec/);
  // Reproduce the real R8 distinction: a saved random population versus
  // capture-only encounter override4. These remain fabricated refusals.
  const party = {uid: 'negative-creature', species_id: 'terrapup', level: 5, xp: 0, hp: 5, fainted: false};
  metadata.state.party = [{uid: party.uid, species: party.species_id, level: 5, xp: 0, hp: 5, fainted: false}];
  metadata.state.inventory = {};
  metadata.state.world_seed = 1434901555;
  const ownerBytes = codec({version: 28, character_id: metadata.state.character_id,
    redesign_character: metadata.state.redesign_character, party: [party], inventory: [], flags: {flags: []}});
  const worldBytes = codec({version: 28, world_seed: 1434901555, flags: {flags: []}, reward_delivery_namespace: 'negative-world'});
  fs.writeFileSync(firstSave, ownerBytes);
  fs.writeFileSync(path.join(handoffs, boundaries[0], 'save/world.json'), worldBytes);
  metadata.files_sha256 = {'character.json': sha(ownerBytes), 'world.json': sha(worldBytes)};
  emitted[0].files_sha256 = metadata.files_sha256;
  metadata.population_provenance = {saved_world_seed: 1434901555, effective_encounter_seed: 4,
    has_environment_override: true, environment_override: '4'};
  emitted[0].population_provenance = metadata.population_provenance;
  const writeMetadata = () => { fs.writeFileSync(firstReceipt, codec(metadata)); writeLog(); };
  writeMetadata();
  refused(/Encounter override differs from saved population/);
  metadata.state.world_seed = 4;
  writeMetadata();
  refused(/Observed world seed must match actual save bytes/);
  metadata.state.world_seed = 1434901555;
  delete metadata.population_provenance;
  writeMetadata();
  refused(/Actual population seed provenance required/);
  metadata.population_provenance = {...emitted[0].population_provenance, effective_encounter_seed: 1434901555};
  writeMetadata();
  refused(/Seed provenance must match actual handoff log/);
  refused(/Provide all ordered preceding segment logs/, ['--segment-logs=']);
  refused(/Segment logs must be distinct original witnesses/, [`--segment-logs=${logFile}`]);
  // The same five fabricated chapter inputs cannot impersonate the original
  // six-piece Meadows lineage; these controls create no additional saves.
  refused(/Meadows piece logs require explicit/, [`--meadows-piece-logs=${logFile}`]);
  refused(/Combined promotion requires explicit ordered/, ['--meadows-piece-prefix']);
  refused(/Complete six-piece Meadows prefix required/, ['--meadows-piece-prefix', '--segment-logs=',
    `--meadows-piece-logs=${Array(6).fill(logFile).join(',')}`]);
  const originalSegment = path.join(dir, 'original-segment.log');
  fs.copyFileSync(logFile, originalSegment);
  writeLog({...result, counts_as_proof: false, campaign_complete: false, requested_prefix_passed: true,
    resumed_from: 'stormwood_settled', reached: 'completed_world_continuation'}, journey, emitted,
    'F49 SEGMENT RESULT ' + JSON.stringify({kind: 'f49_earned_segment', from_boundary: 'stormwood_settled',
      through_boundary: 'completed_world', journey_id: 'negative-control', commit: '0'.repeat(40)}) + '\n');
  refused(/Exactly one F49 SEGMENT RESULT\s+required in every segment/, [`--segment-logs=${originalSegment}`]);
  console.log(JSON.stringify({test: 'F19-earned-promotion-negative-controls', checks, result: 'PASS', scope: 'fabricated rejection controls only; no earned saves were generated'}));
} finally {
  assert.ok(path.resolve(dir).startsWith(path.resolve(os.tmpdir()) + path.sep), 'Cleanup stays inside the named temporary root');
  assert.ok(path.basename(dir).startsWith('f19-promotion-negative-'));
  fs.rmSync(dir, {recursive: true, force: true});
}
