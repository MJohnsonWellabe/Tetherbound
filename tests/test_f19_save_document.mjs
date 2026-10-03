import assert from 'node:assert/strict';
import fs from 'node:fs';
import {parseSaveDocument} from '../tools/earned_saves/save_document.mjs';

// Codec parity only. This creates no campaign or earned save fixture.
const golden = JSON.parse(fs.readFileSync('tests/fixtures/save-codec-v1.json', 'utf8'));
const value = parseSaveDocument(JSON.stringify(golden));
const bits = number => { const bytes = Buffer.alloc(8); bytes.writeDoubleLE(number); return bytes.toString('hex'); };
for (const key of ['float32_height', 'care', 'negative_zero', 'subnormal']) {
  assert.equal(bits(value[key]), golden.payload[key].$tb_float64);
}
assert.equal(value.min_int, -(2n ** 63n));
assert.equal(value.max_int, 2n ** 63n - 1n);
assert.equal(value.safe_int, Number.MAX_SAFE_INTEGER);
assert.deepEqual(value.collision, {$tb_float64: 'original text'});
assert.deepEqual(value.nested, [true, null, 1]);
assert.deepEqual(parseSaveDocument('{"version":28,"$tb_float64":"original text","hp":1.25}'),
  {version: 28, $tb_float64: 'original text', hp: 1.25});
let rejected = 0;
function refuse(payload, version = 1, extra = {}) {
  assert.throws(() => parseSaveDocument(JSON.stringify({format: 'tetherbound-save', codec_version: version, payload, ...extra})), /Invalid production save codec/);
  rejected++;
}
for (const tag of [{$tb_float64: '000000000000f07f'}, {$tb_float64: '000000000000f87f'},
  {$tb_float64: 'xyz'}, {$tb_float64: 123}, {$tb_float64: '000000000000f03f', other: 1},
  {$tb_float64: '000000000000F03F'}, {$tb_int64: '9223372036854775808'},
  {$tb_int64: '-9223372036854775809'}, {$tb_int64: '01'}, {$tb_int64: '-0'}, {$tb_int64: '1'},
  {$tb_dictionary: [['$tb_float64', 'a'], ['$tb_float64', 'b']]},
  {$tb_dictionary: [['ordinary', 1]]}, {$tb_dictionary: [1]},
  {$tb_dictionary: [['$tb_int64', 'a']], other: 1}]) refuse({x: tag});
refuse({x: 1.25});
refuse({x: 9007199254740992});
for (const version of [true, 2, '1']) refuse({}, version);
refuse({}, 1, {extra: true});
refuse([]);
let deep = {};
for (let index = 0; index < 130; index++) deep = {nested: deep};
refuse(deep);
const original = parseSaveDocument(JSON.stringify({format: 'tetherbound-save', codec_version: 1,
  payload: {$tb_dictionary: [['$tb_float64', 'literal'], ['__proto__', {safe: true}]]}}));
assert.ok(Object.hasOwn(original, '__proto__'));
assert.equal(Object.getPrototypeOf(original), Object.prototype);
assert.deepEqual(original.__proto__, {safe: true});
console.log(JSON.stringify({test: 'F19-production-save-codec-parity', golden: 'save-codec-v1.json',
  exact_float_bits: 4, signed_int64_boundaries: 2, rejection_controls: rejected, result: 'PASS',
  scope: 'Node reader matches production wire values; no earned progression claim'}));
