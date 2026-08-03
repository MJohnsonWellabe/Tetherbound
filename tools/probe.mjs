// Fast look: a few frames, not the whole nine-shot survey.
//
// For iterating on a material, a density or a tint, where waiting out
// `survey.mjs` costs several times more than the change being judged. Same
// harness and same camera framing, so a probe frame and a survey frame of the
// same spot are directly comparable.
//
//   node tools/probe.mjs [outdir] [--close]
//
// `--close` drops the camera to head height a few metres behind the player,
// which is the only framing that shows what ground cover actually looks like:
// the survey's 3.2m eye pitched down flattens a tuft into a speck.
import { mkdirSync } from 'node:fs';
import { launch, place, setTimeOfDay } from './lib/game.mjs';

const args = process.argv.slice(2);
const OUT = args.find((a) => !a.startsWith('--')) ?? 'shots-probe';
const CLOSE = args.includes('--close');
mkdirSync(OUT, { recursive: true });

const SPOTS = [
  ['village', 0, 0, 0.6, 0.2],
  ['meadow', 420, -260, 1.1, 0.25],
  ['grove', -380, 410, 1.7, 0.28]
];

const { browser, page, errors } = await launch({ width: 1280, height: 720 });

for (const [name, x, z, yaw, cycle] of SPOTS) {
  await setTimeOfDay(page, cycle);
  await place(page, { x, z, yaw, pitch: 0.18 });
  await setTimeOfDay(page, cycle);
  if (CLOSE) {
    // Re-pose after place(), never before: the player's camera rig runs every
    // frame, so anything set earlier is gone by the time the shutter opens.
    await page.evaluate(
      ([px, pz, yw]) => {
        const g = window.__tetherbound;
        const cam = g.renderer.handles.camera;
        const y = g.terrain.heightAt(px, pz);
        const dist = 3.4;
        cam.position.set(px - Math.sin(yw) * dist, y + 1.5, pz - Math.cos(yw) * dist);
        const V = Object.getPrototypeOf(cam.position).constructor;
        cam.setTarget(new V(px + Math.sin(yw) * 16, y + 1.2, pz + Math.cos(yw) * 16));
        g.renderer.render();
      },
      [x, z, yaw]
    );
  }
  await page.screenshot({ path: `${OUT}/${name}.png`, timeout: 180_000 });
  console.log(`  ${name}`);
}

if (errors.length) console.log(`page errors: ${errors.slice(0, 3).join(' | ')}`);
await browser.close();
console.log(`-> ${OUT}/`);
