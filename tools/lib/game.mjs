// Shared harness for the visual tools: boot the game, pose the camera, read
// the frame back.
//
// Every tool in tools/ answers one question about the built game. They all
// need the same three things first, so those live here rather than being
// copy-pasted five times and drifting.
//
// These drive the REAL build (npm run preview), not a test double. A tool that
// inspects a mock tells you about the mock.
import { chromium } from 'playwright';

export const PREVIEW_URL = process.env.TB_URL ?? 'http://localhost:4173/';

/**
 * The pre-installed Chromium. Environments that ship a browser pin a specific
 * revision, and Playwright's own download expects whatever matches its version,
 * so the two disagree and `playwright install` either fails or quietly fetches
 * a second copy.
 */
const EXECUTABLE = process.env.CHROMIUM_PATH;

/** Software WebGL. There is no GPU on a CI box or in a container. */
const GL_ARGS = [
  '--use-gl=angle',
  '--use-angle=swiftshader',
  '--enable-unsafe-swiftshader',
  '--disable-lcd-text'
];

export async function launch({ width = 1280, height = 720, scale = 1 } = {}) {
  const browser = await chromium.launch({
    ...(EXECUTABLE ? { executablePath: EXECUTABLE } : {}),
    args: GL_ARGS
  });
  const context = await browser.newContext({
    viewport: { width, height },
    deviceScaleFactor: scale
  });
  const page = await context.newPage();

  const errors = [];
  page.on('pageerror', (e) => errors.push(String(e.message)));
  page.on('console', (m) => {
    if (m.type() === 'error') errors.push(m.text());
  });

  await page.goto(PREVIEW_URL, { waitUntil: 'domcontentloaded' });
  // The boot overlay removes itself only after the first frame has rendered,
  // so waiting on it is a real "we drew something" signal rather than a guess.
  await page.waitForFunction(() => document.getElementById('boot') === null, null, {
    timeout: 120_000
  });

  return { browser, context, page, errors };
}

/**
 * Move the player and settle the world.
 *
 * `settleMs` matters more than it looks: chunk streaming is time-sliced under a
 * per-frame budget, so a screenshot taken immediately after a teleport is a
 * picture of a half-built world. Under software rendering the frame rate is a
 * few per second, so this needs to be generous.
 */
export async function place(page, { x, z, yaw = 0, pitch = 0.18, settleMs = 6000 }) {
  await page.evaluate(
    ([px, pz]) => {
      const g = window.__tetherbound;
      g.player.state.position.x = px;
      g.player.state.position.z = pz;
      g.player.state.position.y = g.terrain.heightAt(px, pz) + 1;
      g.chunks.update(px, pz);
    },
    [x, z]
  );
  await page.waitForTimeout(settleMs);

  // Pose after settling. The player's own camera rig runs every frame, so this
  // has to be the last thing that touches the camera before the shutter.
  await page.evaluate(
    ([px, pz, yw, pt]) => {
      const g = window.__tetherbound;
      const cam = g.renderer.handles.camera;
      const y = g.terrain.heightAt(px, pz);
      const dist = 9;
      const cx = px - Math.sin(yw) * dist;
      const cz = pz - Math.cos(yw) * dist;
      cam.position.set(cx, y + 3.2 + pt * 8, cz);
      cam.setTarget(new (Object.getPrototypeOf(cam.position).constructor)(px, y + 1.4, pz));
      g.renderer.render();
    },
    [x, z, yaw, pitch]
  );
}

/** Freeze the clock at a point in the day/night cycle. 0 is dawn. */
export async function setTimeOfDay(page, cycle) {
  await page.evaluate((c) => {
    const g = window.__tetherbound;
    g.time.cycle = c;
    g.time.tick(0);
    g.renderer.render();
  }, cycle);
}

/** Draw calls, triangles, active meshes and measured frame time. */
export async function stats(page, sampleMs = 2500) {
  return page.evaluate(async (ms) => {
    const g = window.__tetherbound;
    const scene = g.scene;
    const engine = g.renderer.handles.engine;

    // Time explicit render() calls. A headless tab is throttled to roughly one
    // rAF per second, so engine.getFps() measures the throttle, not the game.
    const frames = 40;
    const t0 = performance.now();
    for (let i = 0; i < frames; i++) scene.render();
    const frameMs = (performance.now() - t0) / frames;

    await new Promise((r) => setTimeout(r, Math.min(ms, 50)));
    return {
      frameMs: +frameMs.toFixed(2),
      drawCalls: engine._drawCalls?.current ?? null,
      triangles: Math.round(scene.getActiveIndices() / 3),
      activeMeshes: scene.getActiveMeshes().length,
      totalMeshes: scene.meshes.length,
      loadedChunks: g.chunks.loadedCount
    };
  }, sampleMs);
}
