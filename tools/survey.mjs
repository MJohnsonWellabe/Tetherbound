// Photograph the world from a fixed set of places and hours.
//
//   npm run build && npm run preview   (in another shell)
//   node tools/survey.mjs [--w 1280] [--h 720]
//
// The point is REGRESSION and REVIEW, not decoration. The same spots at the
// same hours, every time, so two runs can be compared and a judge can look at
// one directory instead of being walked through the game.
//
// Spots are chosen to cover the things the terrain actually generates: the
// village plateau, a river, a grove, an outcrop, open meadow. If a future
// change flattens the rivers or deletes the groves, these frames say so.
import fs from 'node:fs';
import { launch, place, setTimeOfDay, stats } from './lib/game.mjs';

const args = process.argv.slice(2);
const opt = (k, d) => {
  const i = args.indexOf('--' + k);
  return i >= 0 ? args[i + 1] : d;
};

const OUT = opt('out', 'shots');
const W = +opt('w', 1280);
const H = +opt('h', 720);

// [name, x, z, yaw, timeOfDay]
// 0.20 is mid-morning, 0.62 is late afternoon, 0.78 is night.
const SPOTS = [
  ['village-morning', 0, 0, 0.6, 0.2],
  ['village-dusk', 0, 0, 2.4, 0.66],
  ['meadow-open', 420, -260, 1.1, 0.25],
  ['river-bank', 260, 190, 2.2, 0.3],
  ['river-wide', 300, 240, 0.4, 0.55],
  ['grove', -380, 410, 1.7, 0.28],
  ['outcrop', -1120, -1030, 0.9, 0.35],
  ['far-meadow', 900, -650, 2.9, 0.22],
  ['night-meadow', 420, -260, 1.1, 0.82]
];

fs.rmSync(OUT, { recursive: true, force: true });
fs.mkdirSync(OUT, { recursive: true });

const { browser, page, errors } = await launch({ width: W, height: H });

const manifest = [];
for (const [name, x, z, yaw, tod] of SPOTS) {
  process.stdout.write(`  ${name} ... `);
  await place(page, { x, z, yaw });
  await setTimeOfDay(page, tod);
  const s = await stats(page);
  const file = `${OUT}/${name}.png`;
  await page.screenshot({ path: file });
  manifest.push({ name, file, x, z, ...s });
  console.log(`${s.frameMs}ms  ${s.drawCalls ?? '?'} draws  ${s.triangles} tris`);
}

fs.writeFileSync(`${OUT}/survey.json`, JSON.stringify({ w: W, h: H, shots: manifest }, null, 2));

const real = errors.filter((e) => !/swiftshader|WebGL|GPU stall|Fallback/i.test(e));
if (real.length > 0) {
  console.log(`\n${real.length} console error(s):`);
  for (const e of real.slice(0, 5)) console.log(`  ${e}`);
}

await browser.close();
console.log(`\n${manifest.length} shots -> ${OUT}/`);
console.log('Now: node tools/sheet.mjs');
