import assert from 'node:assert/strict';
import fs from 'node:fs';

// One-time source authoring, never a save migration or runtime scaling pass.
// Without --write this checks that every live provider already reads RD-10.
const write = process.argv.includes('--write');
const manifest = JSON.parse(fs.readFileSync('data/config/redesign_level_curve.json', 'utf8'));
assert.equal(manifest.runtime_enabled, true);
assert.equal(manifest.schema_version, 1);
const number = value => Number.isInteger(value) && value >= 1 && value <= 100;
const key = path => JSON.stringify(path);
const at = (object, path) => path.reduce((node, part) => node?.[part], object);
const validPath = path => {
  if (!Array.isArray(path) || !path.length || path.length > 16) return false;
  if (!path.every(part => typeof part === 'string' || (Number.isInteger(part) && part >= 0))) return false;
  const words = path.filter(part => typeof part === 'string');
  return ['level', 'ace_level', 'level_ceiling', 'warden_level', 'wild_band', 'trainer_levels', 'level_range', 'level_band'].includes(words.at(-1))
    || (words.at(-2) === 'team' && ['enter', 'exit'].includes(words.at(-1)));
};

// Locate JSON values so numeric edits preserve all unrelated source text.
function spans(text) {
  let cursor = 0;
  const result = new Map();
  const whitespace = () => { while (/\s/.test(text[cursor] || '') && cursor < text.length) cursor++; };
  function string() {
    const start = cursor++;
    while (cursor < text.length) {
      if (text[cursor] === '\\') cursor += 2;
      else if (text[cursor++] === '"') return JSON.parse(text.slice(start, cursor));
    }
    throw new Error('Unterminated JSON string');
  }
  function value(path) {
    whitespace();
    const start = cursor;
    if (text[cursor] === '{') {
      cursor++; whitespace();
      while (text[cursor] !== '}') {
        const property = string(); whitespace();
        assert.equal(text[cursor++], ':');
        value([...path, property]); whitespace();
        if (text[cursor] !== ',') break;
        cursor++; whitespace();
      }
      assert.equal(text[cursor++], '}');
    } else if (text[cursor] === '[') {
      cursor++; whitespace();
      let index = 0;
      while (text[cursor] !== ']') {
        value([...path, index++]); whitespace();
        if (text[cursor] !== ',') break;
        cursor++; whitespace();
      }
      assert.equal(text[cursor++], ']');
    } else if (text[cursor] === '"') string();
    else {
      const token = /^(?:-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?|true|false|null)/.exec(text.slice(cursor));
      assert.ok(token, `JSON token at ${cursor}`);
      cursor += token[0].length;
    }
    result.set(key(path), {start, end: cursor});
  }
  value([]); whitespace(); assert.equal(cursor, text.length);
  return result;
}

const outputs = [];
let levels = 0;
for (const [path, rows] of Object.entries(manifest.overlays)) {
  assert.match(path, /^data\/config\/(?:[a-z0-9_]+\/)*[a-z0-9_]+\.json$/);
  const source = fs.readFileSync(path, 'utf8');
  const data = JSON.parse(source);
  const expected = structuredClone(data);
  const locations = spans(source);
  const edits = [];
  const seen = new Set();
  for (const row of rows) {
    assert.ok(validPath(row.at) && number(row.value), `${path}: invalid level edit`);
    assert.ok(!seen.has(key(row.at)), `${path}: duplicate edit`); seen.add(key(row.at));
    assert.ok(Array.isArray(row.anchors), `${path}: missing anchors`);
    for (const anchor of row.anchors) assert.deepEqual(at(data, anchor.at), anchor.value, `${path}: identity ${key(anchor.at)}`);
    const parent = at(expected, row.at.slice(0, -1));
    const property = row.at.at(-1);
    assert.ok(parent && typeof parent === 'object', `${path}: missing parent`);
    const actual = at(data, row.at);
    assert.ok(actual === row.value || (row.legacy === null ? actual === undefined : number(row.legacy) && actual === row.legacy), `${path}: stale value ${key(row.at)}`);
    if (!write) assert.equal(actual, row.value, `${path}: live level is not RD-10 ${key(row.at)}`);
    parent[property] = row.value;
    levels++;
    if (actual === row.value) continue;
    const location = locations.get(key(row.at));
    if (location) edits.push({...location, text: String(row.value)});
    else {
      assert.equal(typeof property, 'string');
      const object = locations.get(key(row.at.slice(0, -1)));
      assert.equal(source[object.end - 1], '}');
      let offset = object.end - 1;
      while (/\s/.test(source[offset - 1])) offset--;
      const closingLine = source.slice(offset, object.end - 1);
      assert.match(closingLine, /\r?\n[ \t]*$/);
      const indent = /[ \t]*$/.exec(closingLine)[0] + '  ';
      const newline = source.includes('\r\n') ? '\r\n' : '\n';
      edits.push({start: offset, end: offset, text: `,${newline}${indent}${JSON.stringify(property)}: ${row.value}`});
    }
  }
  if (path === 'data/config/chapter_curve.json') assert.deepEqual(data.biomes, manifest.biomes, 'live biome envelopes');
  let next = source;
  for (const edit of edits.sort((a, b) => b.start - a.start)) next = next.slice(0, edit.start) + edit.text + next.slice(edit.end);
  assert.deepEqual(JSON.parse(next), expected, `${path}: only manifest level edits are permitted`);
  outputs.push([path, source, next]);
}
// Refuse the entire write before changing any file if a later table is stale.
if (write) for (const [path, before, after] of outputs) if (before !== after) fs.writeFileSync(path, after);
console.log(JSON.stringify({result: 'PASS', mode: write ? 'materialize' : 'verify', tables: outputs.length, levels, changed_files: outputs.filter(([, a, b]) => a !== b).length}));
