// Prove the feel layer actually renders, rather than merely compiling.
//
//   npm run build && npm run preview   (in another shell)
//   node tools/feelcheck.mjs
//
// Unit tests cover the shake and pause maths, but they cannot see whether a
// particle burst reaches the screen, whether a floating number lands on the
// right pixel, or whether the camera offset is applied to the frame it was
// computed for. Those are exactly the failures that ship silently.
//
// Three frames, written to shots-feel/:
//   1. baseline   - the scene at rest
//   2. burst      - mid-impact: particles alive, numbers up, camera displaced
//   3. settled    - after everything has decayed, to prove nothing leaks
//
// The camera must return to the baseline position in frame 3. A shake that
// does not undo itself drifts the camera out of the world over a session, and
// that bug is invisible in any single screenshot.
import fs from 'node:fs';
import { launch, place, stats } from './lib/game.mjs';

const OUT = 'shots-feel';
fs.rmSync(OUT, { recursive: true, force: true });
fs.mkdirSync(OUT, { recursive: true });

const { browser, page, errors } = await launch({ width: 1280, height: 720 });

// A grove, so there are real props to spray debris against.
await place(page, { x: -380, z: 410, yaw: 1.7 });

const camAt = () =>
  page.evaluate(() => {
    const c = window.__tetherbound.renderer.handles.camera.position;
    return { x: c.x, y: c.y, z: c.z };
  });

// `place()` poses the camera by hand, but the player's own rig re-poses it on
// every simulation step, so that pose is gone within a frame. Measuring shake
// against it would measure the rig instead. Wait for the player to land and the
// rig to reach a fixed point, then confirm it IS fixed before trusting it as a
// baseline; otherwise a still-settling camera reads as displacement.
await page.waitForTimeout(2000);
let before = await camAt();
for (let i = 0; i < 20; i++) {
  await page.waitForTimeout(250);
  const next = await camAt();
  if (dist(before, next) < 1e-4) break;
  before = next;
}
const recheck = await camAt();
if (dist(before, recheck) > 1e-4) {
  console.error(`FAIL  camera never came to rest, still moving ${dist(before, recheck)}m/frame`);
  await browser.close();
  process.exit(1);
}
await page.screenshot({ path: `${OUT}/1-baseline.png` });
console.log(`  baseline    camera ${fmt(before)}`);

// Fire the heaviest harvest impact plus a spread of numbers, at the point the
// camera is actually looking at.
await page.evaluate(() => {
  const g = window.__tetherbound;
  const p = g.player.state.position;
  const y = g.terrain.heightAt(p.x, p.z);
  g.fx.impact('fell_wood', p.x, y + 1.2, p.z);
  g.fx.number('+4 Wood', p.x, y, p.z, 'gain');
  g.fx.number('+2 Fiber', p.x + 1.4, y, p.z + 0.6, 'gain');
  g.fx.number('-12', p.x - 1.4, y, p.z - 0.4, 'damage');
  g.fx.impact('fell_stone', p.x + 2.2, y + 0.6, p.z + 1.1);
});

// Let a few frames run so particles have travelled and the numbers have risen,
// while trauma is still high enough to displace the camera.
await page.waitForTimeout(220);
const during = await camAt();
const burst = await stats(page);
await page.screenshot({ path: `${OUT}/2-burst.png` });
console.log(
  `  burst       camera ${fmt(during)}  ${burst.drawCalls ?? '?'} draws  ${burst.triangles} tris`
);

// Everything must decay: trauma at 1.6/s is done inside a second, the longest
// particle lifetime is 1.5s and a number lives 1.1s.
await page.waitForTimeout(2600);
const after = await camAt();
const settled = await stats(page);
await page.screenshot({ path: `${OUT}/3-settled.png` });
console.log(
  `  settled     camera ${fmt(after)}  ${settled.drawCalls ?? '?'} draws  ${settled.triangles} tris`
);

const displaced = dist(before, during);
const residual = dist(before, after);
const live = await page.evaluate(() => {
  const layer = document.getElementById('fx');
  return [...layer.children].filter((el) => el.style.display !== 'none').length;
});

console.log('');
let failed = false;

// The shake has to be visible. A silently zeroed offset is the failure this
// whole tool exists to catch.
if (displaced < 0.01) {
  console.error(`FAIL  camera never moved during the burst (${displaced.toFixed(4)}m)`);
  failed = true;
} else {
  console.log(`ok    camera displaced ${displaced.toFixed(3)}m at peak trauma`);
}

// And it has to undo itself exactly, or the camera walks away over a session.
if (residual > 0.001) {
  console.error(`FAIL  camera did not return to rest, ${residual.toFixed(4)}m of drift left`);
  failed = true;
} else {
  console.log(`ok    camera returned to rest, ${residual.toFixed(5)}m residual`);
}

if (live > 0) {
  console.error(`FAIL  ${live} floating numbers never retired`);
  failed = true;
} else {
  console.log('ok    every floating number retired to the pool');
}

const real = errors.filter((e) => !/swiftshader|WebGL|GPU stall|Fallback/i.test(e));
if (real.length > 0) {
  console.error(`FAIL  ${real.length} console errors:`);
  for (const e of real.slice(0, 8)) console.error(`      ${e}`);
  failed = true;
} else {
  console.log('ok    no console errors');
}

await browser.close();
console.log(`\n3 frames -> ${OUT}/`);
process.exit(failed ? 1 : 0);

function fmt(p) {
  return `${p.x.toFixed(2)},${p.y.toFixed(2)},${p.z.toFixed(2)}`;
}

function dist(a, b) {
  return Math.hypot(a.x - b.x, a.y - b.y, a.z - b.z);
}
