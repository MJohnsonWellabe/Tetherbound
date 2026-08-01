// Find holes in the world.
//
//   node tools/holes.mjs [--save]
//
// The clear colour is set to magenta and the camera is pointed straight down at
// ground the player is standing on. Terrain is opaque, so the only way magenta
// reaches the frame is through a gap: a chunk that never streamed in, a seam
// between two LOD levels, or geometry facing the wrong way.
//
// This is the check that would have caught the inside-out terrain immediately.
// That bug shipped through a typecheck, 99 unit tests and five browser smoke
// specs, and was only found by a human looking at a screenshot and asking why
// the ground was missing. An unambiguous pass/fail beats an eyeball every time.
//
// Borrowed from TheLongSilence's tools/leaks.mjs, which does the same thing to
// find gaps in a ship hull.
import fs from 'node:fs';
import { launch, place } from './lib/game.mjs';

const SAVE = process.argv.includes('--save');
/**
 * Prove the detector can fail.
 *
 * `--selftest` hides the terrain, so every spot SHOULD report a hole. A check
 * that cannot fail is worthless, and this repo has already shipped one: a
 * deploy job piped into `tail`, which made the pipeline exit 0 and reported a
 * failed deploy as green. Run this after touching the detector.
 */
const SELFTEST = process.argv.includes('--selftest');
const OUT = 'shots/holes';

// Somewhere in the middle of each terrain feature, plus the spawn point.
// [name, x, z]
const SPOTS = [
  ['village', 0, 0],
  ['meadow', 420, -260],
  ['river', 300, 240],
  ['grove', -380, 410],
  ['outcrop', -1120, -1030],
  ['far', 900, -650],
  ['negative-quadrant', -700, -700]
];

/** Anything above this fraction of magenta pixels is a hole, not an artefact. */
const TOLERANCE = 0.001;

const { browser, page } = await launch({ width: 640, height: 640 });

if (SAVE) fs.mkdirSync(OUT, { recursive: true });

// Drop the water plane, which is legitimately translucent and would otherwise
// read as a hole over every river.
//
// The magenta clear colour is NOT set here. TimeOfDay.apply() reassigns
// scene.clearColor on every tick to match the fog, so anything set outside the
// shot is gone by the time the frame renders. That is why the first version of
// this tool reported 0% magenta even with the terrain explicitly hidden: the
// clear colour was never magenta at the moment of capture.
await page.evaluate(() => {
  const g = window.__tetherbound;
  for (const m of g.scene.meshes) if (m.name === 'water') m.setEnabled(false);
});

if (SELFTEST) {
  // Hidden per spot rather than once up front. place() calls chunks.update(),
  // which streams NEW chunk meshes in enabled, so a single disable pass at the
  // start is undone by the first teleport. The first version of this selftest
  // reported 0/7 for exactly that reason, which is the detector failing to
  // detect a hole it had itself created.
  console.log('  [selftest] terrain hidden per spot, every spot should report HOLE\n');
}

let failures = 0;
for (const [name, x, z] of SPOTS) {
  await place(page, { x, z });

  // Straight down from 40m. The whole frame should be ground.
  const result = await page.evaluate(
    async ([px, pz, hideTerrain]) => {
      const g = window.__tetherbound;
      // Stop the loop first. While it runs, TimeOfDay repaints the clear colour
      // and the player rig repossesses the camera between our writes and the
      // render.
      g.loop.stop();
      if (hideTerrain) {
        for (const m of g.scene.meshes) if (m.name.startsWith('chunk_')) m.setEnabled(false);
      }
      const C4 = Object.getPrototypeOf(g.scene.clearColor).constructor;
      g.scene.clearColor = new C4(1, 0, 1, 1);
      g.scene.fogMode = 0; // fog would tint magenta toward the fog colour
      const cam = g.renderer.handles.camera;
      const V3 = Object.getPrototypeOf(cam.position).constructor;
      const y = g.terrain.heightAt(px, pz);
      cam.position.set(px, y + 40, pz);
      cam.setTarget(new V3(px, y, pz));
      g.renderer.render();

      const engine = g.renderer.handles.engine;
      const w = engine.getRenderWidth();
      const h = engine.getRenderHeight();
      const px4 = await engine.readPixels(0, 0, w, h);
      const data = new Uint8Array(px4.buffer ?? px4);

      let magenta = 0;
      const total = w * h;
      for (let i = 0; i < data.length; i += 4) {
        // Generous threshold: nothing in the meadow palette is anywhere near
        // full red plus full blue with no green.
        if ((data[i] ?? 0) > 200 && (data[i + 1] ?? 0) < 60 && (data[i + 2] ?? 0) > 200) magenta++;
      }
      g.loop.start(); // let the next teleport stream chunks again
      return { magenta, total, fraction: magenta / total };
    },
    [x, z, SELFTEST]
  );

  const bad = result.fraction > TOLERANCE;
  if (bad) failures++;
  if (SAVE) await page.screenshot({ path: `${OUT}/${name}.png` });

  console.log(
    `  ${bad ? 'HOLE' : 'ok  '}  ${name.padEnd(20)} ${(result.fraction * 100).toFixed(3)}% magenta`
  );
}

await browser.close();

if (SELFTEST) {
  if (failures === SPOTS.length) {
    console.log('\n[selftest] passed: the detector reports a hole when there is one.');
    process.exit(0);
  }
  console.error(`\n[selftest] FAILED: only ${failures}/${SPOTS.length} spots detected the hole.`);
  console.error('The detector is not measuring what it claims to measure.');
  process.exit(1);
}

if (failures > 0) {
  console.error(`\n${failures} location(s) show through to the clear colour.`);
  console.error('Re-run with --save and look at shots/holes/ to see where.');
  process.exit(1);
}
console.log('\nNo holes. Every sampled location is covered by opaque terrain.');
