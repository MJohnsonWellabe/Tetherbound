// Walks the player 500m in a straight line through the Meadows, capturing a
// frame and a prop-instance count every ~60m, and fails if any stretch shows
// zero resident vegetation near the player. This is the owner's explicit
// verification for "vegetation mostly doesn't render": a gap here means
// instancing or scatter broke again, not that the meadow is meant to be bare.
import { launch, place, stats } from './lib/game.mjs';
import fs from 'node:fs';

const OUT = 'shots-walk';
fs.rmSync(OUT, { recursive: true, force: true });
fs.mkdirSync(OUT, { recursive: true });

const { browser, page } = await launch({ width: 1280, height: 720 });

const STEP_M = 60;
const STEPS = 9; // ~540m
const START = { x: 0, z: 40 }; // just past the village exclusion zone

let failures = 0;
for (let i = 0; i < STEPS; i++) {
  const x = START.x;
  const z = START.z + i * STEP_M;
  await place(page, { x, z, yaw: Math.PI, pitch: 0.15, settleMs: 5000 });
  const s = await stats(page);
  const counts = await page.evaluate(() => window.__tetherbound.props.instanceCountsByFamily());
  const total = Object.values(counts).reduce((a, b) => a + b, 0);
  const file = `${OUT}/walk_${i}_${Math.round(z)}m.png`;
  await page.screenshot({ path: file, timeout: 180000 });
  const bad = total === 0;
  if (bad) failures++;
  console.log(
    `  z=${z.toString().padStart(4)}m  ${bad ? 'GAP  ' : 'ok   '} ` +
      `total=${total}  ${Object.entries(counts).map(([k, v]) => `${k}:${v}`).join(' ')}  ` +
      `${s.drawCalls} draws  ${s.triangles} tris`
  );
}

await browser.close();
console.log('');
if (failures > 0) {
  console.error(`${failures} of ${STEPS} spots along the walk had zero resident vegetation.`);
  process.exit(1);
}
console.log(`Clean 500m+ walk, ${STEPS} spots, vegetation resident at every one. Shots in ${OUT}/`);
