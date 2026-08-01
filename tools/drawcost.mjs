// Is the frame bound by fill rate or by draw submission?
//
//   node tools/drawcost.mjs
//
// The two have opposite fixes and look identical from a frame-time number, so
// guessing wrong means optimising the thing that was never the problem.
//
//   Fill-bound   -> frame time tracks pixel count. Fix with resolution scale,
//                   cheaper shaders, less overdraw, smaller shadow maps.
//   Draw-bound   -> frame time barely moves with resolution. Fix by merging
//                   meshes, batching instances, cutting material count.
//
// ARCHITECTURE.md budgets 150 draw calls and 16ms. This says which of those two
// numbers is actually costing the frame.
//
// Software rendering exaggerates fill cost badly, so treat the ratio as the
// signal and the absolute milliseconds as meaningless. On a real GPU the
// conclusion usually holds; the magnitudes do not.
//
// KNOWN LIMITATION, do not trust a number this tool has not earned. The draw
// call figure comes from engine._drawCalls, which accumulates rather than
// resetting per frame, so it reads far too high and climbs across a run. The
// honest source is SceneInstrumentation.drawCallsCounter, which src/core/Stats.ts
// already uses for the ?stats=1 overlay; wiring that through to here is unfinished.
// Until then this tool refuses to conclude when its own data is incoherent.
import { launch, place, stats } from './lib/game.mjs';

const { browser, page } = await launch({ width: 1280, height: 720 });

// A dense spot rather than the flat village plateau, so the measurement
// reflects a frame with actual content in it.
await place(page, { x: -380, z: 410, yaw: 1.7 });

async function atScale(scale) {
  await page.evaluate((s) => {
    window.__tetherbound.renderer.handles.engine.setHardwareScalingLevel(s);
  }, scale);
  await page.waitForTimeout(400);
  const s = await stats(page);
  // Hardware scaling level is a DIVISOR: 2 means render at half linear
  // resolution, so a quarter of the pixels.
  return { scale, pixels: 1 / (scale * scale), ...s };
}

const full = await atScale(1);
const half = await atScale(2);
const quarter = await atScale(4);
await page.evaluate(() => {
  window.__tetherbound.renderer.handles.engine.setHardwareScalingLevel(1);
});

await browser.close();

const rows = [full, half, quarter];
console.log('\n  scale   pixels   frameMs   draws   tris');
for (const r of rows) {
  console.log(
    `  1/${r.scale}    ${(r.pixels * 100).toFixed(0).padStart(4)}%   ${String(r.frameMs).padStart(7)}   ${String(r.drawCalls ?? '?').padStart(5)}   ${r.triangles}`
  );
}

// If a quarter of the pixels costs about a quarter of the time, the frame is
// fill-bound. If it costs about the same, the cost is per-draw and resolution
// is not the lever.
const ratio = quarter.frameMs / full.frameMs;
console.log(`\n  quarter-res frame time is ${(ratio * 100).toFixed(0)}% of full-res`);

// Sanity gate. Rendering a quarter of the pixels cannot cost MORE, and draw
// calls cannot rise as resolution falls. When either happens the measurement is
// wrong, and announcing "draw bound" from it would send the next person
// optimising the wrong half of the renderer.
const incoherent =
  ratio > 1.05 ||
  (full.drawCalls != null && quarter.drawCalls != null && quarter.drawCalls > full.drawCalls * 1.2);
if (incoherent) {
  console.log('\n  MEASUREMENT UNRELIABLE, no conclusion drawn.');
  console.log('  Frame time rose or draw calls climbed as pixels fell, which is impossible.');
  console.log('  Likely the cumulative _drawCalls counter and resize churn under SwiftShader.');
  console.log('  Use ?stats=1 in a real browser on a real device instead.');
  process.exit(0);
}

if (ratio < 0.45) {
  console.log('  -> FILL BOUND. Resolution scale, overdraw and shader cost are the levers.');
} else if (ratio > 0.8) {
  console.log('  -> DRAW BOUND. Batching and material count are the levers, not resolution.');
} else {
  console.log('  -> MIXED. Both matter; attack whichever budget is closer to its ceiling.');
}

const budget = { triangles: 300_000 };
if (full.triangles > budget.triangles) {
  console.log(`  !! ${full.triangles} triangles, over the ${budget.triangles} budget`);
}
