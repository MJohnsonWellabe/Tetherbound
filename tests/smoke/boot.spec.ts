import { expect, test, type ConsoleMessage, type Page } from '@playwright/test';

/**
 * Does the game boot, generate a world, and render it?
 *
 * Everything else in the test suite is pure logic that never touches a canvas.
 * This is the one that would have caught a bad deep import, a disposed-scene
 * crash, or terrain that typechecks and then renders as nothing.
 */

interface Diagnostics {
  loadedChunks: number;
  pendingChunks: number;
  playerY: number;
  groundY: number;
  day: number;
  activeMeshes: number;
  totalVertices: number;
}

/** Collect console errors so a silent runtime failure cannot pass as success. */
function watchConsole(page: Page): string[] {
  const errors: string[] = [];
  page.on('console', (msg: ConsoleMessage) => {
    if (msg.type() === 'error') errors.push(msg.text());
  });
  page.on('pageerror', (err) => errors.push(`pageerror: ${err.message}`));
  return errors;
}

async function bootGame(page: Page, query = ''): Promise<string[]> {
  const errors = watchConsole(page);
  await page.goto(`/${query}`);
  // The boot overlay removes itself only after the first frame has rendered,
  // so waiting on it is a real "we drew something" signal.
  await page.waitForFunction(() => document.getElementById('boot') === null, null, {
    timeout: 60_000
  });
  return errors;
}

async function diagnostics(page: Page): Promise<Diagnostics> {
  return page.evaluate(() => {
    const g = (window as unknown as { __tetherbound: Record<string, never> }).__tetherbound;
    const chunks = g.chunks as unknown as { loadedCount: number; pendingCount: number };
    const player = g.player as unknown as { state: { position: { x: number; y: number; z: number } } };
    const terrain = g.terrain as unknown as { heightAt: (x: number, z: number) => number };
    const time = g.time as unknown as { day: number };
    const scene = g.scene as unknown as {
      getActiveMeshes: () => { length: number };
      getTotalVertices: () => number;
    };
    return {
      loadedChunks: chunks.loadedCount,
      pendingChunks: chunks.pendingCount,
      playerY: player.state.position.y,
      groundY: terrain.heightAt(player.state.position.x, player.state.position.z),
      day: time.day,
      activeMeshes: scene.getActiveMeshes().length,
      totalVertices: scene.getTotalVertices()
    };
  });
}

test('boots to a rendered world with no console errors', async ({ page }) => {
  const errors = await bootGame(page);

  const fatalVisible = await page.locator('#fatal').isVisible();
  expect(fatalVisible, 'the fatal-error overlay should not be showing').toBe(false);

  const d = await diagnostics(page);
  expect(d.loadedChunks, 'chunks should have streamed in around the spawn').toBeGreaterThan(10);
  expect(d.activeMeshes, 'something should be rendering').toBeGreaterThan(5);
  expect(d.totalVertices, 'terrain geometry should exist').toBeGreaterThan(1000);

  // WebGL under SwiftShader emits performance warnings that are not our
  // problem; anything else is.
  const real = errors.filter((e) => !/swiftshader|WebGL|GPU stall|Fallback/i.test(e));
  expect(real, `unexpected console errors:\n${real.join('\n')}`).toEqual([]);
});

test('player stands on the ground rather than through it', async ({ page }) => {
  await bootGame(page);
  // Let gravity settle and the controller take a few steps.
  await page.waitForTimeout(1500);

  const d = await diagnostics(page);
  expect(Math.abs(d.playerY - d.groundY), 'player should be resting on the terrain').toBeLessThan(0.6);
});

test('the same seed rebuilds the same world', async ({ page }) => {
  // The property the whole save format depends on: store a seed, not terrain.
  const sample = async (): Promise<number[]> => {
    await bootGame(page, '?seed=regression-check');
    return page.evaluate(() => {
      const g = (window as unknown as { __tetherbound: Record<string, never> }).__tetherbound;
      const terrain = g.terrain as unknown as { heightAt: (x: number, z: number) => number };
      const out: number[] = [];
      for (let i = 0; i < 40; i++) out.push(terrain.heightAt(i * 37 - 500, i * 91 - 700));
      return out;
    });
  };

  const first = await sample();
  const second = await sample();
  expect(second).toEqual(first);
});

test('streaming keeps up as the player moves', async ({ page }) => {
  await bootGame(page);

  // Teleport well outside the loaded radius, then let the queue drain.
  await page.evaluate(() => {
    const g = (window as unknown as { __tetherbound: Record<string, never> }).__tetherbound;
    const player = g.player as unknown as { state: { position: { x: number; z: number } } };
    player.state.position.x = 900;
    player.state.position.z = -650;
  });
  const first = await diagnostics(page);
  await page.waitForTimeout(5000);
  const second = await diagnostics(page);

  // Assert PROGRESS, not a drained queue. Under SwiftShader the render loop
  // runs at a few frames per second, and the queue is drained from the render
  // phase under a 4ms budget, so a full 81-chunk radius genuinely cannot
  // finish here. On a real GPU it does. What this can honestly verify is that
  // streaming is making forward progress and not wedged.
  expect(second.loadedChunks, 'chunks should keep arriving').toBeGreaterThan(first.loadedChunks);
  expect(second.pendingChunks, 'the queue should be shrinking').toBeLessThan(first.pendingChunks);
  expect(second.loadedChunks, 'the new area should be populated').toBeGreaterThan(10);
});

test('disposes cleanly with no leaked scene resources', async ({ page }) => {
  // CLAUDE.md: "Dispose what you create ... must not accumulate across rounds."
  // Leaks kill mobile within minutes, and they are invisible until they are not.
  await bootGame(page);

  const after = await page.evaluate(() => {
    const g = (window as unknown as { __tetherbound: Record<string, never> }).__tetherbound;
    const scene = g.scene as unknown as {
      meshes: unknown[];
      materials: unknown[];
      textures: unknown[];
    };
    const before = {
      meshes: scene.meshes.length,
      materials: scene.materials.length,
      textures: scene.textures.length
    };
    (g.dispose as unknown as () => void)();
    return {
      before,
      meshes: scene.meshes.length,
      materials: scene.materials.length,
      textures: scene.textures.length
    };
  });

  expect(after.before.meshes, 'the world should have had meshes to dispose').toBeGreaterThan(5);
  expect(after.meshes, 'meshes left after dispose').toBe(0);
  expect(after.materials, 'materials left after dispose').toBe(0);
  expect(after.textures, 'textures left after dispose').toBe(0);
});

test('renders the phone viewport without a horizontal scrollbar', async ({ page }) => {
  await bootGame(page);
  const overflow = await page.evaluate(
    () => document.documentElement.scrollWidth > document.documentElement.clientWidth
  );
  expect(overflow, 'the page must not scroll sideways at 390px').toBe(false);
  await page.screenshot({ path: 'tests/smoke/.output/meadows-390x844.png' });
});
