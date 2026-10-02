import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import crypto from 'node:crypto';
import {spawnSync} from 'node:child_process';

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
function refused(reason) {
  const child = spawnSync(process.execPath, ['tools/earned_saves/promote_f19.mjs', logFile, handoffs], {encoding: 'utf8'});
  assert.notEqual(child.status, 0, reason);
  assert.match(child.stderr, reason);
  assert.ok(!child.stdout.includes('"result":"PASS"'));
  checks++;
}
try {
  fs.mkdirSync(handoffs);
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
  console.log(JSON.stringify({test: 'F19-earned-promotion-negative-controls', checks, result: 'PASS', scope: 'fabricated rejection controls only; no earned saves were generated'}));
} finally {
  assert.ok(path.resolve(dir).startsWith(path.resolve(os.tmpdir()) + path.sep), 'Cleanup stays inside the named temporary root');
  assert.ok(path.basename(dir).startsWith('f19-promotion-negative-'));
  fs.rmSync(dir, {recursive: true, force: true});
}
