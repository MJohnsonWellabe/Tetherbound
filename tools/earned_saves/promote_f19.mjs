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
// Explicit --meadows-piece-prefix additionally requires the six original
// --meadows-piece-logs, followed by the ordered chapter --segment-logs.
// node tools/earned_saves/promote_f19.mjs <campaign.log> <handoffs directory> [--relocated-from-ci]
const [logFile, handoffDirectory, ...options] = process.argv.slice(2);
const relocation = options.includes('--relocated-from-ci') ? '--relocated-from-ci' : undefined;
const segmentOption = options.find(option => option.startsWith('--segment-logs='));
const meadowsPrefix = options.includes('--meadows-piece-prefix');
const pieceOption = options.find(option => option.startsWith('--meadows-piece-logs='));
const pieceLogs = pieceOption ? pieceOption.slice('--meadows-piece-logs='.length).split(',') : [];
const segmentLogs = segmentOption && !(meadowsPrefix && segmentOption === '--segment-logs=')
  ? segmentOption.slice('--segment-logs='.length).split(',') : [];
assert.ok(options.every(option => option === '--relocated-from-ci' || option === segmentOption ||
  option === '--meadows-piece-prefix' || option === pieceOption), 'Unknown promotion option');
assert.equal(new Set(options).size, options.length, 'Duplicate promotion option');
assert.ok(!pieceOption || meadowsPrefix, 'Meadows piece logs require explicit --meadows-piece-prefix');
assert.ok(!meadowsPrefix || segmentOption, 'Combined promotion requires explicit ordered --segment-logs (empty only when the final log contains every chapter)');
assert.ok(logFile && handoffDirectory, 'Expected campaign log and immutable handoff directory');
assert.ok(relocation === undefined || relocation === '--relocated-from-ci', 'Unknown promotion option');
const root = process.cwd();
assert.equal(fs.realpathSync(execFileSync('git', ['rev-parse', '--show-toplevel'], {encoding: 'utf8'}).trim()), fs.realpathSync(root), 'Run from the repository root');
const sourceRoot = fs.realpathSync(handoffDirectory);
const meadowsPieces = ['opening_team', 'camp_tournament', 'bridge', 'warrens', 'relay', 'hall'];
if (meadowsPrefix) {
  assert.ok(meadowsPieces.every(boundary => fs.existsSync(path.join(sourceRoot, boundary, 'receipt.json'))),
    'Complete six-piece Meadows prefix required; chapter receipts cannot replace original pieces');
  assert.ok(pieceLogs.length === 6 && pieceLogs.every(Boolean), 'Provide all six ordered original Meadows piece logs');
}
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
if (!segmentOption) {
  assert.equal(result.counts_as_proof, true, 'A resumed, legacy, dry or failed campaign is not earned proof');
  assert.equal(result.campaign_complete, true);
  assert.equal(result.resumed_from, '');
}
assert.deepEqual(result.failures, []);
assert.equal(result.dry_run, false);
const journey = readLine('F49 JOURNEY ');
assert.deepEqual(journey.order, ['meadows', 'tidewake', 'cloudreach', 'stormwood', 'homecoming_credits']);
if (meadowsPrefix) assert.deepEqual(journey.shortcuts, ['agent emits ordinary actions',
  'declines pending legendaries to retain the earned five', 'production saves copied to immutable handoffs',
  'credits skipped by controller after their actual opening',
  'inherited helpers retain their original simulation clocks; wall time is not owner/device timing'],
'Combined proof must retain the actual journey disclosures without undeclared bypasses');
const offloadLines = lines.filter(line => line.startsWith('F19 FUNCTIONAL OFFLOAD '));
assert.ok(offloadLines.length <= 1, 'A single functional offload configuration is allowed');
const offload = offloadLines.length ? readLine('F19 FUNCTIONAL OFFLOAD ') : null;
if (offload) {
  assert.equal(offload.scenario, 'full_fresh_campaign');
  assert.equal(offload.rendering_method, 'gl_compatibility');
  assert.equal(offload.continuous_drawing, false);
  assert.equal(offload.ordinary_controller_physics_saves, true);
}
let emitted = lines.filter(line => line.startsWith('F49 DISK HANDOFF '))
  .map(line => JSON.parse(line.slice('F49 DISK HANDOFF '.length)));
const chapterBoundaries = ['meadows_settled', 'tidewake_settled', 'cloudreach_settled', 'stormwood_settled', 'completed_world'];
const boundaries = meadowsPrefix ? [...meadowsPieces, ...chapterBoundaries] : chapterBoundaries;
const bosses = ['warden_aldis', 'water_trainer_nerissa', 'captain_veyra_storm_anchor', 'captain_marrow_dynamo_core'];
let segmentWitnesses = [];
const pieceWitnesses = [];
if (segmentOption) {
  assert.ok((meadowsPrefix || segmentLogs.length > 0) && segmentLogs.length < 5 && segmentLogs.every(Boolean), 'Provide all ordered preceding segment logs');
  const allLogs = [...pieceLogs, ...segmentLogs, logFile];
  assert.equal(new Set(allLogs.map(file => fs.realpathSync(file))).size, allLogs.length, 'Segment logs must be distinct original witnesses');
  let previous = '';
  let campaignIdentity;
  emitted = [];
  for (const file of allLogs) {
    const text = fs.readFileSync(file, 'utf8');
    assert.ok(!/(?:SCRIPT ERROR:|^ERROR:)/m.test(text), 'Engine errors invalidate every segment witness');
    const rows = text.split(/\r?\n/);
    const one = prefix => {
      const matches = rows.filter(line => line.startsWith(prefix));
      assert.equal(matches.length, 1, `Exactly one ${prefix} required in every segment`);
      return JSON.parse(matches[0].slice(prefix.length));
    };
    if (meadowsPrefix) {
      const functional = rows.filter(line => line.startsWith('F19 FUNCTIONAL OFFLOAD '));
      assert.ok(functional.length <= 1);
      if (functional.length) {
        const configured = one('F19 FUNCTIONAL OFFLOAD ');
        assert.equal(configured.scenario, 'full_fresh_campaign');
        assert.equal(configured.rendering_method, 'gl_compatibility');
        assert.equal(configured.continuous_drawing, false);
        assert.equal(configured.ordinary_controller_physics_saves, true);
      }
      if (pieceWitnesses.length < meadowsPieces.length) {
        const boundary = meadowsPieces[pieceWitnesses.length];
        const proof = one('EARNED PIECE PROOF ');
        const final = one('EARNED CHAIN RESULT ');
        const produced = one('F49 DISK HANDOFF ');
        const receipt = parseSaveDocument(fs.readFileSync(path.join(sourceRoot, boundary, 'receipt.json'), 'utf8'));
        assert.equal(proof.segment, boundary, 'Original Meadows piece logs must remain in earned order');
        assert.equal(proof.mode, 'new_order_meadows_piece');
        assert.equal(proof.passed, true);
        assert.deepEqual(proof.failures, []);
        assert.equal(proof.world_seed_env, '');
        assert.equal(proof.free_build, false);
        assert.equal(proof.functional_offload, functional.length === 1);
        assert.equal(receipt.kind, 'earned_meadows_piece', 'Never relabel original piece receipts as chapters');
        assert.equal(receipt.boundary, boundary);
        // The human-readable log rounds clocks/positions. Bind the discrete
        // proof exactly; the original receipt hash retains every full value.
        for (const field of ['segment', 'mode', 'functional_offload', 'handoff_from', 'passed', 'failures',
          'world_seed_env', 'saved_world_seed', 'game_day', 'flags_gained', 'flags_total', 'party_before',
          'party_after', 'inventory', 'key_items', 'free_build', 'disclosures', 'helper_receipts']) {
          assert.deepEqual(proof[field], receipt.piece_proof[field], `Original piece log must bind saved ${field}`);
        }
        assert.equal(proof.location.realm, 'meadows');
        assert.equal(proof.location.realm, receipt.piece_proof.location.realm);
        assert.equal(proof.location.scene, receipt.piece_proof.location.scene);
        const helpers = boundary === 'opening_team' ? ['opening', 'road_gate', 'village', 'team'] :
          boundary === 'camp_tournament' ? ['materials', 'camp', 'rest', 'tournament'] : [boundary];
        assert.deepEqual(proof.helper_receipts.map(row => row.segment), helpers, 'Every strict piece helper must pass in order');
        for (const helper of proof.helper_receipts) {
          assert.equal(helper.passed, true);
          if (helper.segment === 'village') continue;
          assert.ok(Array.isArray(helper.receipts) && helper.receipts.length > 0, 'Actual helper receipts required');
          for (const row of helper.receipts) {
            assert.ok(typeof row === 'string' || (row && typeof row === 'object' && !Array.isArray(row)));
            const claim = typeof row === 'string' ? row : String(row.beat || '');
            // These names describe authored walking detours, not waived
            // assertions. Bind only their exact owning helper and waypoint list.
            const authoredVia = helper.segment === 'warrens' && claim === 'spike_bypass' ? [[-409, 2512]] :
              helper.segment === 'warrens' && claim === 'station_bypass' ? [[405, 1796.8], [409.5, 1797], [409.5, 1808.5]] :
              ['relay', 'hall'].includes(helper.segment) && claim === 'overlook_bypass' ? [[-122, 3443]] : null;
            if (authoredVia) {
              assert.deepEqual(Object.keys(row).sort(), ['beat', 'from', 'to', 'via']);
              assert.ok(Array.isArray(row.via));
              assert.equal(row.via.length, authoredVia.length, 'Authored detour must retain every waypoint in order');
              // Godot JSON emits Vector2 as a string. Preserve the original
              // log/receipt match above and compare the actual float32 values.
              const points = [row.from, row.to, ...row.via].map(value => {
                assert.equal(typeof value, 'string');
                const match = value.match(/^\(\s*([+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?)\s*,\s*([+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?)\s*\)$/);
                assert.ok(match, 'Authored detour requires the original finite Vector2 from/to/via strings');
                const point = match.slice(1).map(Number).map(Math.fround);
                assert.ok(point.every(Number.isFinite), 'Authored detour coordinates must be finite');
                return point;
              });
              assert.deepEqual(points.slice(2), authoredVia.map(point => point.map(Math.fround)),
                'Only the exact authored detour waypoints are allowed');
            } else assert.ok(!/(?:bypass|skipped|synthe|inject|teleport|legacy_order|veridian_accepted)/i.test(claim),
              'Bypassed, skipped, synthetic or legacy helper proof cannot be promoted');
            // An ordinary lost catch/retry may retain its failed-attempt
            // observation. The containing strict helper must actually pass.
          }
        }
        // These are the runner's ordinary-input disclosures. Unknown claims
        // need review; ordinary care, real-panel retries and detours remain valid.
        const lawfulDisclosures = ['warrens: added an ordinary controller-walk detour west of the Warrens mound',
          'warrens: added an ordinary controller-walk detour east of the quarry pylon',
          'hall: earned rest at the authored riverwatch_rest',
          `${boundary}: the exact Interact press opened its dialogue without the arbiter's activated signal; accepted on the real panel opening`,
          `${boundary}: an Interact press did not activate the exact offered provider and was retried with no side effect`,
          `${boundary}: ordinary Satchel care (helper's own _prepare) run before a road leg`];
        assert.ok(Array.isArray(proof.disclosures) && proof.disclosures.every(disclosure =>
          typeof disclosure === 'string' && lawfulDisclosures.some(prefix => disclosure.startsWith(prefix))),
        'Unknown, skipped or bypassed piece disclosure requires review');
        assert.equal(final.segment, boundary);
        assert.equal(final.passed, true);
        assert.deepEqual(final.failures, []);
        assert.deepEqual(final.party, proof.party_after);
        assert.deepEqual(final.location, proof.location);
        assert.equal(final.flags_gained, proof.flags_gained.length);
        assert.equal(produced.boundary, boundary);
        assert.match(receipt.commit, /^[0-9a-f]{40}$/);
        assert.ok(typeof receipt.journey_id === 'string' && receipt.journey_id.length > 0);
        campaignIdentity ||= [receipt.commit, receipt.journey_id];
        assert.deepEqual([receipt.commit, receipt.journey_id], campaignIdentity);
        assert.equal(produced.commit, receipt.commit);
        const chain = meadowsPieces.slice(0, pieceWitnesses.length).map(boundary => ({boundary,
          receipt_sha256: sha256(path.join(sourceRoot, boundary, 'receipt.json'))}));
        assert.deepEqual(receipt.predecessors, chain, 'Every original piece binds the full immutable prefix');
        if (previous) {
          const input = one('F49 SEGMENT INPUT ');
          assert.equal(input.boundary, previous);
          assert.deepEqual([input.commit, input.journey_id], campaignIdentity);
          assert.deepEqual(input.predecessors, chain, 'Piece production Load must bind the complete original prefix');
          assert.equal(path.posix.basename(proof.handoff_from.replaceAll('\\', '/').replace(/\/$/, '')), previous);
          const inputPath = input.path.replaceAll('\\', '/');
          assert.ok(path.posix.isAbsolute(inputPath) || /^[A-Za-z]:\//.test(inputPath), 'Actual production Load input path must be absolute');
          assert.equal(path.posix.normalize(inputPath), inputPath);
          assert.equal(path.posix.basename(inputPath), previous);
          const requested = proof.handoff_from.replaceAll('\\', '/').replace(/\/$/, '');
          if (path.posix.isAbsolute(requested) || /^[A-Za-z]:\//.test(requested)) assert.equal(path.posix.normalize(requested), inputPath);
        } else {
          assert.equal(proof.handoff_from, '');
          assert.deepEqual(proof.party_before, []);
          assert.ok(!rows.some(line => line.startsWith('F49 SEGMENT INPUT ')), 'Opening must be genuinely fresh');
        }
        assert.ok(!rows.some(line => /^(?:FRESH CAMPAIGN RESULT |F49 SEGMENT RESULT )/.test(line)), 'A piece log cannot stand in for a chapter');
        emitted.push(produced);
        pieceWitnesses.push({boundary, commit: receipt.commit, journey_id: receipt.journey_id,
          log_sha256: sha256(file), receipt_sha256: sha256(path.join(sourceRoot, boundary, 'receipt.json')),
          functional_offload: functional.length === 1});
        previous = boundary;
        continue;
      }
    }
    const final = one('FRESH CAMPAIGN RESULT ');
    const segment = one('F49 SEGMENT RESULT ');
    assert.equal(final.requested_prefix_passed, true, 'Every original segment must pass');
    assert.deepEqual(final.failures, []);
    assert.equal(final.counts_as_proof, false, 'A segment is never uninterrupted proof');
    assert.equal(final.campaign_complete, false);
    assert.equal(final.dry_run, false);
    assert.equal(final.resumed_from, previous, 'Each segment resumes the preceding earned boundary');
    if (meadowsPrefix) {
      assert.equal(final.resume.source_kind, 'f49_complete_meadows_piece_and_chapter_prefix');
      assert.deepEqual(final.resume.meadows_pieces, meadowsPieces);
      assert.equal(final.resume.boundary, previous);
    }
    assert.equal(segment.kind, 'f49_earned_segment');
    assert.equal(segment.from_boundary, previous);
    assert.equal(segment.counts_as_uninterrupted_proof, false);
    assert.match(segment.commit, /^[0-9a-f]{40}$/);
    assert.ok(segment.journey_id);
    campaignIdentity ||= [segment.commit, segment.journey_id];
    assert.deepEqual([segment.commit, segment.journey_id], campaignIdentity);
    const through = boundaries.indexOf(segment.through_boundary);
    const from = boundaries.indexOf(previous);
    assert.ok(through > from, 'Every segment advances in new chapter order');
    const produced = rows.filter(line => line.startsWith('F49 DISK HANDOFF '))
      .map(line => JSON.parse(line.slice('F49 DISK HANDOFF '.length)));
    assert.deepEqual(produced.map(row => row.boundary), boundaries.slice(from + 1, through + 1));
    const chain = boundaries.slice(0, through + 1).map(boundary => ({boundary,
      receipt_sha256: sha256(path.join(sourceRoot, boundary, 'receipt.json'))}));
    assert.deepEqual(segment.predecessors, chain, 'Segment output must match the final immutable chain');
    if (previous) {
      const input = one('F49 SEGMENT INPUT ');
      assert.equal(input.boundary, previous);
      assert.deepEqual([input.commit, input.journey_id], campaignIdentity);
      assert.deepEqual(input.predecessors, chain.slice(0, from + 1), 'Original segment input must bind every preceding receipt');
      if (meadowsPrefix) {
        assert.equal(final.resume.journey_id, campaignIdentity[1]);
        const inputPath = input.path.replaceAll('\\', '/');
        assert.ok(path.posix.isAbsolute(inputPath) || /^[A-Za-z]:\//.test(inputPath));
        assert.equal(path.posix.normalize(inputPath), inputPath);
        assert.equal(path.posix.basename(inputPath), previous);
        const requested = final.resume.source.replaceAll('\\', '/').replace(/\/$/, '');
        assert.equal(path.posix.basename(requested), previous);
        if (path.posix.isAbsolute(requested) || /^[A-Za-z]:\//.test(requested)) assert.equal(path.posix.normalize(requested), inputPath);
      }
    } else assert.ok(!rows.some(line => line.startsWith('F49 SEGMENT INPUT ')), 'Exactly one fresh first producer');
    assert.equal(segment.completed_world_reloaded, file === logFile, 'Only the terminal segment proves completed-world reload and continuation');
    assert.equal(final.reached, file === logFile ? 'completed_world_continuation' : segment.through_boundary,
      'Every original segment must reach its reported boundary or terminal continuation');
    const functional = rows.filter(line => line.startsWith('F19 FUNCTIONAL OFFLOAD '));
    assert.ok(functional.length <= 1);
    if (functional.length) {
      const configured = one('F19 FUNCTIONAL OFFLOAD ');
      assert.equal(configured.scenario, 'full_fresh_campaign');
      assert.equal(configured.rendering_method, 'gl_compatibility');
      assert.equal(configured.continuous_drawing, false);
      assert.equal(configured.ordinary_controller_physics_saves, true);
    }
    emitted.push(...produced);
    segmentWitnesses.push({log_sha256: sha256(file), ...segment});
    previous = segment.through_boundary;
  }
  assert.equal(previous, 'completed_world', 'The chain must finish its actual completed-world continuation');
}
assert.deepEqual(emitted.map(row => row.boundary), boundaries, 'Each actual new boundary must be captured in order');
let sourceCommit = '';
let emittedRoot = '';
let retainedIdentity;
let savedWorldSeed;
const candidates = [];
for (let index = 0; index < boundaries.length; index++) {
  const boundary = boundaries[index];
  const directory = path.join(sourceRoot, boundary);
  const receiptFile = path.join(directory, 'receipt.json');
  const receiptHash = sha256(receiptFile);
  const receipt = parseSaveDocument(fs.readFileSync(receiptFile, 'utf8'));
  const chapterIndex = chapterBoundaries.indexOf(boundary);
  const meadowPiece = meadowsPrefix && chapterIndex < 0;
  assert.equal(receipt.kind, meadowPiece ? 'earned_meadows_piece' : 'f49_ordinary_input_handoff');
  if (meadowsPrefix) assert.equal(receipt.save_slot, 0, 'Combined lineage explicitly retains its actual autosave slot');
  assert.equal(receipt.boundary, boundary);
  assert.match(receipt.commit, /^[0-9a-f]{40}$/);
  sourceCommit ||= receipt.commit;
  assert.equal(receipt.commit, sourceCommit);
  assert.equal(emitted[index].commit, sourceCommit);
  if (segmentOption) assert.equal(sourceCommit, segmentWitnesses[0].commit, 'Original segment logs must name the actual saved receipt source');
  const originalPath = emitted[index].path.replaceAll('\\', '/');
  assert.ok(path.posix.isAbsolute(originalPath) || /^[A-Za-z]:\//.test(originalPath), 'Absolute original runner path required');
  assert.equal(path.posix.normalize(originalPath), originalPath, 'Original paths must be canonical');
  assert.equal(path.posix.basename(originalPath), boundary, 'Original runner path must identify this boundary');
  emittedRoot ||= path.posix.dirname(originalPath);
  if (!segmentOption) assert.equal(path.posix.dirname(originalPath), emittedRoot, 'All five boundaries must come from the same original handoff root');
  if (relocation === undefined) assert.equal(fs.realpathSync(emitted[index].path), fs.realpathSync(directory));
  assert.deepEqual(receipt.files_sha256, emitted[index].files_sha256);
  assert.equal(receipt.realm, meadowPiece ? 'meadows' : ['meadows', 'water', 'cloudreach', 'stormwood', 'meadows'][chapterIndex]);
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
  for (const file of files.filter(file => file.endsWith(`${path.sep}character.json`) || file.endsWith(`${path.sep}world.json`) ||
    (meadowsPrefix && /^slot_[0-4]\.json$/.test(path.basename(file))))) {
    const envelope = parseSaveDocument(fs.readFileSync(file, 'utf8'));
    assert.equal(envelope.version, 28, `Current split schema required: ${file}`);
  }
  const biome = ['meadows', 'tidewake', 'cloudreach', 'stormwood'][Math.min(chapterIndex, 3)];
  const held = receipt.state.redesign_character;
  const boss = bosses[Math.min(chapterIndex, 3)];
  if (!meadowPiece) {
    assert.ok(held.relics_held.includes(biome) || held.relics_hung.includes(biome), `Actually earned ${biome} relic`);
    assert.ok(held.transaction_receipts.some(id => id === `defeat:boss_${boss}:${receipt.state.character_id}` ||
      (id.startsWith(`defeat:boss_${boss}_`) && id.endsWith(`:${receipt.state.character_id}`))), `Exact ${boss} entitlement receipt required`);
  }
  const characters = files.filter(file => file.endsWith(`${path.sep}character.json`))
    .map(file => parseSaveDocument(fs.readFileSync(file, 'utf8')))
    .filter(saved => saved.character_id === receipt.state.character_id);
  assert.equal(characters.length, 1, 'Exactly one actual saved owner must match the receipt character');
  const character = characters[0];
  if (meadowsPrefix) {
    const uids = character.party.map(member => member.uid);
    assert.equal(uids.length, 5, 'Combined lineage retains exactly the original five');
    assert.equal(new Set(uids).size, 5);
    assert.ok(uids.every(uid => typeof uid === 'string' && uid.length > 0));
  }
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
  let world;
  if (meadowsPrefix) {
    const flat = parseSaveDocument(fs.readFileSync(path.join(saves, 'slot_0.json'), 'utf8'));
    assert.equal(flat.version, 28, 'Actual production Load slot must use the current schema');
    assert.equal(flat.current_realm, receipt.realm);
    assert.equal(character.realm, receipt.realm, 'Observed realm must match the saved portable character');
    assert.deepEqual(flat.split_locator, {world_id: receipt.state.world_id, character_id: receipt.state.character_id},
      'Actual Load locator must select the saved owner and host world');
    for (const id of Object.values(flat.split_locator)) assert.match(id, /^[A-Za-z0-9_-]+$/, 'Safe production split ID required');
    assert.deepEqual(parseSaveDocument(fs.readFileSync(path.join(saves, 'characters', flat.split_locator.character_id, 'character.json'), 'utf8')), character);
    const selected = worlds.filter(saved => saved.world_id === flat.split_locator.world_id);
    assert.equal(selected.length, 1, 'Exactly one actual autosave world must match the receipt');
    world = selected[0];
    assert.deepEqual(parseSaveDocument(fs.readFileSync(path.join(saves, 'worlds', flat.split_locator.world_id, 'world.json'), 'utf8')), world);
    // Production autosave and manual slots may coexist. Retain and hash them
    // all, but refuse a foreign population/host hidden in that saved tree.
    for (const saved of worlds) {
      assert.equal(saved.reward_delivery_namespace, world.reward_delivery_namespace);
      assert.equal(saved.world_seed, world.world_seed);
    }
  } else {
    assert.equal(worlds.length, 1, 'A fresh campaign must retain exactly its actual world');
    world = worlds[0];
  }
  if (segmentOption) {
    const identity = [character.character_id, world.world_id, world.reward_delivery_namespace, character.party.map(member => member.uid)];
    retainedIdentity ||= identity;
    assert.deepEqual(identity, retainedIdentity, 'Segments retain the original character, world and five');
    assert.equal(receipt.journey_id, segmentWitnesses[0].journey_id);
    assert.equal(receipt.state.world_id, world.world_id);
    assert.equal(receipt.state.reward_delivery_namespace, world.reward_delivery_namespace);
    assert.deepEqual(receipt.predecessors, boundaries.slice(0, index).map(boundary => ({boundary,
      receipt_sha256: sha256(path.join(sourceRoot, boundary, 'receipt.json'))})), 'Each boundary binds the preceding original receipts');
  }
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
  if (meadowsPrefix) assert.equal(population.has_environment_override, false, 'Meadows-rooted proof refuses encounter overrides');
  if (population.has_environment_override) {
    assert.match(population.environment_override.trim(), /^[+-]?\d+$/, 'Numeric encounter override required');
    assert.equal(Number(population.environment_override.trim()), world.world_seed, 'Override must match saved population');
  } else assert.equal(population.environment_override, '');
  savedWorldSeed ??= world.world_seed;
  assert.equal(world.world_seed, savedWorldSeed, 'All boundaries retain the original fresh world seed');
  assert.ok(typeof world.reward_delivery_namespace === 'string' && world.reward_delivery_namespace.length > 0);
  const flags = [...new Set([...world.flags.flags, ...character.flags.flags])].sort();
  assert.deepEqual(flags, receipt.state.flags, 'Observed progression must match the actual split files');
  if (meadowPiece) {
    const proof = receipt.piece_proof;
    assert.equal(receiptHash, pieceWitnesses[index].receipt_sha256, 'Original piece receipt must remain unchanged');
    assert.equal(proof.saved_world_seed, world.world_seed);
    assert.deepEqual(proof.party_after, character.party.map(member => ({uid: member.uid, species: member.species_id,
      nickname: member.nickname, level: member.level, hp: Math.trunc(member.hp)})), 'Piece party proof must match actual saved five');
    if (index > 0) assert.deepEqual(proof.party_before.map(member => member.uid), retainedIdentity[3], 'Production Load preserves original ordered five');
    const stacks = {};
    for (const stack of character.inventory) if (stack && Object.keys(stack).length) stacks[stack.id] = (stacks[stack.id] || 0) + stack.n;
    assert.deepEqual(proof.inventory, stacks, 'Piece inventory must match actual saved stacks');
    assert.deepEqual(proof.key_items, Object.fromEntries(Object.entries(stacks).filter(([id]) => /key|sigil|recipe|gear/.test(id))));
    assert.equal(proof.flags_total, flags.length);
    const preceding = index ? candidates[index - 1].receipt.state.flags : [];
    assert.deepEqual(proof.flags_gained, flags.filter(flag => !preceding.includes(flag)), 'Piece progression must match its actual saved flag delta');
  }
  const namespaceHash = crypto.createHash('sha256').update(world.reward_delivery_namespace).digest('hex');
  if (!meadowPiece) assert.ok(held.transaction_receipts.includes(`defeat:boss_${boss}:${receipt.state.character_id}`) ||
    held.transaction_receipts.includes(`defeat:boss_${boss}_${namespaceHash}:${receipt.state.character_id}`), 'Boss receipt must name the actual saved host world');
  const destination = path.join(targetRoot, boundary);
  assert.ok(!fs.existsSync(destination), `Never overwrite an existing earned fixture: ${destination}`);
  candidates.push({boundary, directory, destination, receipt, receiptHash});
}
// The evidence source must be committed and available for replay/review.
execFileSync('git', ['cat-file', '-e', `${sourceCommit}^{commit}`], {stdio: 'pipe'});
const provenance = {kind: 'f19_earned_boundary_promotion', source_commit: sourceCommit,
  command: `Godot 4.7 ${/^OpenGL.*(?:API|Renderer)/m.test(log) ? '' : '--headless '}--script tests/${offload ? 'smoke_f19_campaign_functional' : 'smoke_four_biome_continuous'}.gd`,
  functional_offload: offload,
  population_provenance: candidates.map(row => ({boundary: row.boundary, ...row.receipt.population_provenance})),
  source_log_sha256: sha256(logFile), segment_witnesses: segmentWitnesses, journey, boundaries,
  transport: relocation ? {kind: 'downloaded_ci_artifact', original_handoff_root: emittedRoot, original_paths: emitted.map(row => row.path)} : {kind: 'local_original_paths'},
  disclosures: journey.shortcuts, scope: 'Earned progression/save boundaries; no hardware, timing or visual acceptance claim'};
if (meadowsPrefix) {
  provenance.meadows_piece_prefix = true;
  provenance.meadows_piece_witnesses = pieceWitnesses;
  provenance.command += ' -- --meadows-piece-prefix --handoff-from=<preceding earned boundary>';
  provenance.scope = 'Earned pieces joined through production Load and chapter continuation; not an uninterrupted run, hardware, timing or visual acceptance claim';
  // Finish validation of the entire eleven-boundary lineage before installing
  // any fixture. Receipt files themselves are immutable evidence too.
  for (const candidate of candidates) {
    assert.equal(sha256(path.join(candidate.directory, 'receipt.json')), candidate.receiptHash);
    for (const [file, hash] of Object.entries(candidate.receipt.files_sha256)) {
      assert.equal(sha256(path.join(candidate.directory, 'save', file)), hash, 'Original production bytes changed during promotion validation');
    }
  }
}
for (const candidate of candidates) {
  fs.mkdirSync(path.dirname(candidate.destination), {recursive: true});
  fs.cpSync(candidate.directory, candidate.destination, {recursive: true, errorOnExist: true, force: false});
  fs.writeFileSync(path.join(candidate.destination, 'PROVENANCE.json'), JSON.stringify({...provenance, boundary: candidate.boundary}, null, 2) + '\n', {flag: 'wx'});
  for (const [file, hash] of Object.entries(candidate.receipt.files_sha256)) {
    assert.equal(sha256(path.join(candidate.destination, 'save', file)), hash, 'Promoted bytes must remain exact');
  }
  if (meadowsPrefix) assert.equal(sha256(path.join(candidate.destination, 'receipt.json')), candidate.receiptHash,
    'Promotion must preserve each original receipt without relabelling');
}
console.log(JSON.stringify({proof: 'F19-earned-save-promotion', source_commit: sourceCommit, boundaries, result: 'PASS'}));
