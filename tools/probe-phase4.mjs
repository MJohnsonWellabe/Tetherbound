// Phase 4 close-ups: village houses, Hall exterior, Hall interior.
// Throwaway verification probe; not part of the survey loop.
import { mkdirSync } from 'node:fs';
import { launch, place } from './lib/game.mjs';

const OUT = process.argv[2] ?? 'shots-phase4-probe';
mkdirSync(OUT, { recursive: true });

const { browser, page, errors } = await launch({ width: 1280, height: 720 });

// Village square, looking across the ring.
await place(page, { x: 0, z: -14, yaw: Math.PI, pitch: 0.12, settleMs: 9000 });
await page.screenshot({ path: `${OUT}/village_a.png` });
await place(page, { x: -12, z: 10, yaw: Math.PI * 0.3, pitch: 0.1, settleMs: 5000 });
await page.screenshot({ path: `${OUT}/village_b.png` });

// The Hall. Find its placement from the live game, stand outside the door.
const hall = await page.evaluate(() => {
  const g = window.__tetherbound;
  const p = g.built.hall.placement;
  return { x: p.x, z: p.z, yaw: p.yaw, floorY: g.built.hall.floorY };
});
console.log('hall placement', hall);

// Outside the door: the door is at local -z, world offset by placement yaw.
const doorDist = 34;
const dx = hall.x + Math.sin(hall.yaw) * -doorDist * -1 - Math.sin(hall.yaw) * doorDist * 0;
const outside = {
  x: hall.x - Math.sin(hall.yaw) * doorDist,
  z: hall.z - Math.cos(hall.yaw) * doorDist
};
void dx;
await place(page, { x: outside.x, z: outside.z, yaw: hall.yaw, pitch: 0.3, settleMs: 12000 });
await page.screenshot({ path: `${OUT}/hall_exterior.png` });

// Inside, at the grunt A anchor, looking toward the warden.
const inside = await page.evaluate(() => {
  const g = window.__tetherbound;
  const a = g.built.hall.anchors.gruntA.position;
  return { x: a.x, z: a.z };
});
await place(page, { x: inside.x, z: inside.z, yaw: hall.yaw + Math.PI, pitch: 0.15, settleMs: 5000 });
await page.screenshot({ path: `${OUT}/hall_interior.png` });

// Back toward the door from inside, to check the door gap and lintel.
await place(page, { x: hall.x, z: hall.z, yaw: hall.yaw, pitch: 0.2, settleMs: 4000 });
await page.screenshot({ path: `${OUT}/hall_interior_door.png` });

// The standing stones.
const stones = await page.evaluate(() => {
  const g = window.__tetherbound;
  return { x: g.built.stonesPlacement.x, z: g.built.stonesPlacement.z };
});
await place(page, { x: stones.x - 18, z: stones.z, yaw: Math.PI / 2, pitch: 0.15, settleMs: 12000 });
await page.screenshot({ path: `${OUT}/stones.png` });

console.log('page errors:', errors);
await browser.close();
