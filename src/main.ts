import { bus } from './core/EventBus';
import { Renderer } from './core/Engine';
import { Input } from './core/input/Input';
import { Loop } from './core/Loop';
import { Stats } from './core/Stats';
import { Game } from './game/Game';
import { Player } from './entities/Player';
import type { ControllerWorld } from './entities/CharacterController';
import { buildWaterPlane } from './world/ChunkMesh';
import { ChunkManager } from './world/ChunkManager';
import { createPrototypes, disposePrototypes } from './world/Prototypes';
import { Terrain, WATER_LEVEL } from './world/gen/Terrain';
import { TimeOfDay } from './world/TimeOfDay';

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
    fatalMsg.textContent = err instanceof Error ? `${err.name}: ${err.message}` : String(err);
  }
  if (fatalEl) fatalEl.hidden = false;
}

fatalReload?.addEventListener('click', () => location.reload());

/** The world seed. Overridable with ?seed= so a bug report is reproducible. */
function resolveSeed(): string {
  return new URLSearchParams(location.search).get('seed') ?? 'hollowbrook';
}

async function boot(): Promise<void> {
  if (!canvas) throw new Error('Canvas #scene is missing from index.html');

  progress(0.1, 'Starting the renderer');
  const renderer = new Renderer(canvas);
  const { scene, camera, sun, sky, shadows } = renderer.handles;

  progress(0.3, 'Shaping the Meadows');
  const terrain = new Terrain(resolveSeed());
  const prototypes = createPrototypes(scene);
  const chunks = new ChunkManager(scene, terrain, prototypes, shadows);
  const water = buildWaterPlane(scene, 4096, WATER_LEVEL);

  // Landmark colliders are fixed and few, so they are appended to whatever the
  // streamed chunks report rather than being registered into the chunk system.
  // Buildings do not unload; chunk props do.
  let fixedColliders: { x: number; z: number; radius: number }[] = [];

  // One adapter, so the controller and the camera both see exactly the terrain
  // the renderer drew rather than a second opinion about it.
  const world: ControllerWorld = {
    heightAt: (x, z) => terrain.heightAt(x, z),
    slopeAt: (x, z) => terrain.slopeAt(x, z),
    collidersNear: (x, z, r) => {
      const near = chunks.collidersNear(x, z, r);
      for (const collider of fixedColliders) {
        if (Math.hypot(collider.x - x, collider.z - z) <= r + collider.radius) near.push(collider);
      }
      return near;
    }
  };

  progress(0.5, 'Waking Hollowbrook');
  // Hollowbrook is at the origin and its plateau is flat, so this is always
  // solid ground regardless of seed.
  const player = new Player(scene, camera, { x: 0, y: terrain.heightAt(0, 0), z: 0 }, shadows);

  // Build the chunks around the spawn before the first frame, so the player
  // never sees themselves standing on nothing.
  chunks.update(0, 0);
  chunks.processQueue(2000);

  progress(0.8, 'Setting the sun');
  const time = new TimeOfDay(scene, sun, sky, 0.2, 1);
  const input = new Input(canvas);

  progress(0.9, 'Raising the Hall');
  const game = new Game({
    scene,
    camera,
    shadows,
    terrain,
    seed: resolveSeed(),
    player,
    time,
    input,
    collidersNear: (x, z, r) => world.collidersNear(x, z, r)
  });
  fixedColliders = game.world.colliders;
  // A reload drops the player back where they were; a cold start meets Orin.
  game.restore();
  game.begin();

  const loop = new Loop({
    update: (dt, elapsedMs) => {
      input.beginFrame();

      // The player keeps simulating during dialogue but not during a fight,
      // where the camera belongs to the arena and a stray stick input would
      // walk them out of it.
      if (game.mode !== 'combat') player.update(input, world, dt);
      game.update(dt * 1000);
      chunks.update(player.state.position.x, player.state.position.z);
      if (time.tick(dt)) bus.emit('dayChanged', { day: time.day });

      // Water follows the player so one plane covers the visible world without
      // being large enough to lose float precision at the horizon.
      water.position.x = player.state.position.x;
      water.position.z = player.state.position.z;

      bus.emit('tick', { dt, elapsedMs });
      input.endFrame();
    },
    render: () => {
      // Streaming runs in the render phase, outside the fixed-step update, so
      // a frame that owes several simulation steps does not also owe several
      // chunk builds.
      chunks.processQueue();
      game.animate(performance.now());
      renderer.render();
      stats?.sample(performance.now());
    }
  });

  const stats = Stats.enabled() && statsEl ? new Stats(scene, loop, statsEl) : null;

  renderer.onContextRestored = (): void => {
    scene.markAllMaterialsAsDirty(1);
  };

  await new Promise<void>((resolve) => {
    scene.onAfterRenderObservable.addOnce(() => resolve());
    loop.start();
  });

  progress(1, 'Ready');
  bootEl?.classList.add('boot--gone');
  window.setTimeout(() => bootEl?.remove(), 450);

  (window as unknown as Record<string, unknown>).__tetherbound = {
    renderer,
    loop,
    scene,
    bus,
    input,
    player,
    chunks,
    terrain,
    time,
    game,
    dispose: (): void => {
      loop.stop();
      game.dispose();
      input.dispose();
      player.dispose();
      chunks.dispose();
      disposePrototypes(prototypes);
      water.dispose();
      renderer.dispose();
    }
  };

  // Autosave on the way out. visibilitychange is the only hook a phone
  // reliably fires; 'beforeunload' does not run when iOS kills a background
  // tab, which is exactly when a save matters most.
  document.addEventListener('visibilitychange', () => {
    if (document.visibilityState === 'hidden') game.save();
  });
}

boot().catch(fatal);
