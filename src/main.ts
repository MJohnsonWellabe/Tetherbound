import { Color3, CreateGround, StandardMaterial } from './core/babylon';
import { Renderer } from './core/Engine';
import { Loop } from './core/Loop';
import { Stats } from './core/Stats';
import { bus } from './core/EventBus';

/**
 * Boot. Keep this file thin: it wires systems together and owns nothing.
 *
 * Order matters. The canvas has to exist before the engine, the engine before
 * anything that allocates GPU resources, and the first frame has to reach the
 * screen before we start any optional network work. A boot that waits on the
 * network is a boot that looks broken on a bad connection.
 */

const canvas = document.getElementById('scene') as HTMLCanvasElement | null;
const bootEl = document.getElementById('boot');
const bootFill = document.getElementById('bootFill');
const bootMsg = document.getElementById('bootMsg');
const statsEl = document.getElementById('stats');
const fatalEl = document.getElementById('fatal');
const fatalMsg = document.getElementById('fatalMsg');
const fatalReload = document.getElementById('fatalReload');

function progress(pct: number, msg?: string): void {
  if (bootFill) bootFill.style.width = `${Math.round(pct * 100)}%`;
  if (msg && bootMsg) bootMsg.textContent = msg;
}

function fatal(err: unknown): void {
  console.error('[boot] fatal', err);
  if (bootEl) bootEl.classList.add('boot--gone');
  if (fatalMsg) {
    const detail = err instanceof Error ? `${err.name}: ${err.message}` : String(err);
    fatalMsg.textContent = detail;
  }
  if (fatalEl) fatalEl.hidden = false;
}

fatalReload?.addEventListener('click', () => location.reload());

async function boot(): Promise<void> {
  if (!canvas) throw new Error('Canvas #scene is missing from index.html');

  progress(0.15, 'Starting the renderer');
  const renderer = new Renderer(canvas);
  const { scene } = renderer.handles;

  progress(0.55, 'Shaping the ground');
  // Placeholder ground so M0 has something to stand on before WorldGen lands
  // in Phase C. Replaced wholesale, not extended.
  const ground = CreateGround('placeholder-ground', { width: 200, height: 200, subdivisions: 32 }, scene);
  const groundMat = new StandardMaterial('placeholder-ground-mat', scene);
  groundMat.diffuseColor = new Color3(0.36, 0.46, 0.24);
  groundMat.specularColor = new Color3(0, 0, 0);
  ground.material = groundMat;
  ground.receiveShadows = true;

  progress(0.85, 'Setting the sun');
  const loop = new Loop({
    update: (dt, elapsedMs) => {
      bus.emit('tick', { dt, elapsedMs });
    },
    render: () => {
      renderer.render();
      stats?.sample(performance.now());
    }
  });

  const stats = Stats.enabled() && statsEl ? new Stats(scene, loop, statsEl) : null;

  // Hand the renderer a way to rebuild after a GPU context loss.
  renderer.onContextRestored = (): void => {
    scene.markAllMaterialsAsDirty(1);
  };

  // Wait for the first real frame before tearing down the boot overlay, so we
  // never flash an empty canvas.
  await new Promise<void>((resolve) => {
    scene.onAfterRenderObservable.addOnce(() => resolve());
    loop.start();
  });

  progress(1, 'Ready');
  bootEl?.classList.add('boot--gone');
  window.setTimeout(() => bootEl?.remove(), 450);

  // Keep a handle for debugging and for the eventual soak test.
  (window as unknown as Record<string, unknown>).__tetherbound = { renderer, loop, scene, bus };
}

boot().catch(fatal);
