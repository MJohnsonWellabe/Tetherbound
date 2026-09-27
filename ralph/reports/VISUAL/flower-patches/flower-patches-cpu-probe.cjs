// CPU-only reproduction of cover_tier.gdshader's unsigned lattice hash.
// Run: node D:/tetherbound/visual-acceptance-local/flower-patches-cpu-probe.cjs
// No project writes, engine, imports or renderer. This is not a GPU precision test.
'use strict';
function bits(v) {
  v = v.map(x => (Math.imul(x, 1664525) + 1013904223) >>> 0);
  v[0] = (v[0] + Math.imul(v[1], v[2])) >>> 0;
  v[1] = (v[1] + Math.imul(v[2], v[0])) >>> 0;
  v[2] = (v[2] + Math.imul(v[0], v[1])) >>> 0;
  v = v.map(x => (x ^ (x >>> 16)) >>> 0);
  v[0] = (v[0] + Math.imul(v[1], v[2])) >>> 0;
  v[1] = (v[1] + Math.imul(v[2], v[0])) >>> 0;
  v[2] = (v[2] + Math.imul(v[0], v[1])) >>> 0;
  return v[0];
}
const oldRand = (cid, tag, salt) => bits([
  (cid[0] + 4194304) >>> 0,
  (cid[1] + 4194304) >>> 0,
  (Math.imul(tag[0] * 131 + tag[1], 9781) + salt) >>> 0
]);
const coverRand = (cid, tag, salt, seed) => oldRand(cid, tag, (salt + seed) >>> 0);
const floatHash = value => Math.fround(value) / 4294967296;
let fixtureSeed = 20260927;
const random = () => ((fixtureSeed = (Math.imul(fixtureSeed, 1664525) + 1013904223) >>> 0) / 4294967296);
const cases = 100000;
let defaultMismatches = 0, sameXY = 0, distanceSum = 0, distanceSquared = 0, sameRank = 0;
for (let i = 0; i < cases; i++) {
  const cid = [Math.floor(random() * 200000) - 100000, Math.floor(random() * 200000) - 100000];
  const tag = [1 + Math.floor(random() * 200), 1 + Math.floor(random() * 16)];
  for (const salt of [11, 29, 53, 71]) {
    if (oldRand(cid, tag, salt) !== coverRand(cid, tag, salt, 0)) defaultMismatches++;
  }
  const lilac = [11, 29].map(salt => floatHash(coverRand(cid, tag, salt, 8830145)));
  const gold = [11, 29].map(salt => floatHash(coverRand(cid, tag, salt, 4417703)));
  if (lilac[0] === gold[0] && lilac[1] === gold[1]) sameXY++;
  // Assumed cell=2 m and lattice_jitter=1, isolating placement decorrelation.
  const distance = Math.hypot((lilac[0] - gold[0]) * 2, (lilac[1] - gold[1]) * 2);
  distanceSum += distance;
  distanceSquared += distance * distance;
  if (coverRand(cid, tag, 71, 8830145) === coverRand(cid, tag, 71, 4417703)) sameRank++;
}
const result = {
  fixture_seed: 20260927,
  cases,
  default_hash_cases: cases * 4,
  default_mismatches: defaultMismatches,
  exact_seeded_xy_matches: sameXY,
  mean_cell2_seed_separation: distanceSum / cases,
  rms_separation: Math.sqrt(distanceSquared / cases),
  same_rank_hash: sameRank,
  shader_float_cast_reproduced: true,
  scope: 'CPU formula reproduction; not GDScript execution, GPU image equality, minimum spacing or mutually exclusive patches'
};
console.log(JSON.stringify(result, null, 2));
if (defaultMismatches !== 0 || sameXY === cases || !Number.isFinite(result.rms_separation)) process.exitCode = 1;
