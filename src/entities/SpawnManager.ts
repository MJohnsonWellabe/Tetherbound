import spawns from '../data/spawns.json';
import combat from '../data/combat.json';
import { Scene, ShadowGenerator } from '../core/babylon';
import { pickWeighted, rangeInt, subRng } from '../world/gen/Rng';
import type { Terrain } from '../world/gen/Terrain';
import { makePal, type PalState } from '../party/Pal';
import { requireSpecies, type SpeciesDef } from '../party/Species';
import { PalMesh, PalMeshPool } from './PalMesh';
import {
  createMotion,
  stepMotion,
  wantsToEngage,
  type AiTraits,
  type WildMotion
} from './PalAI';

/**
 * Wild pals: which ones exist, where, and when they go away again.
 *
 * Everything about placement is seeded. A chunk's spawn roll derives from the
 * world seed and the chunk coordinates, so the same seed puts the same species
 * in the same field on every device, which is what makes a shared seed worth
 * sharing and a bug report worth filing.
 *
 * The active count is capped by the mesh pool rather than by a counter here.
 * Making the pool the authority means the cap cannot drift out of sync with
 * the memory actually allocated.
 */

const TABLES = spawns.tables as unknown as Record<string, Record<string, Record<string, number>>>;
const DENSITY = spawns.density;
const PHASES = spawns.phases as unknown as Record<string, [number, number]>;

export interface WildPal {
  pal: PalState;
  def: SpeciesDef;
  motion: WildMotion;
  mesh: PalMesh | null;
  traits: AiTraits;
  /** Chunk this pal was rolled from, so despawn can free the slot again. */
  chunkKey: string;
}

/** Which spawn table applies at this point in the day. */
export function phaseAt(cycle: number): string {
  const t = ((cycle % 1) + 1) % 1;
  for (const [name, band] of Object.entries(PHASES)) {
    const [from, to] = band;
    if (t >= from && t < to) return name;
  }
  return 'day';
}

export class SpawnManager {
  private readonly pool: PalMeshPool;
  private readonly active: WildPal[] = [];
  /** Chunks already rolled, so walking back and forth does not re-roll them. */
  private readonly rolled = new Set<string>();
  private repopulateMs = 0;

  constructor(
    scene: Scene,
    private readonly terrain: Terrain,
    private readonly seed: string,
    shadows: ShadowGenerator | null
  ) {
    this.pool = new PalMeshPool(scene, shadows, combat.encounter.maxActivePals);
  }

  get pals(): readonly WildPal[] {
    return this.active;
  }

  /**
   * Advance every wild pal, then top up and prune.
   *
   * Spawning is throttled rather than run every frame: at 60Hz a per-frame
   * search over candidate chunks is pure waste when the population only
   * changes as fast as the player can walk.
   */
  update(dtMs: number, playerX: number, playerZ: number, cycle: number, day: number): void {
    const dt = dtMs;
    for (const wild of this.active) {
      stepMotion(
        wild.motion,
        wild.traits,
        wild.pal.hp / Math.max(1, wild.pal.maxHp),
        {
          playerX,
          playerZ,
          dtMs: dt,
          heightAt: (x, z) => this.terrain.heightAt(x, z),
          rng: this.rngFor(wild)
        }
      );
      const m = wild.motion;
      wild.mesh?.setPosition(m.x, m.y, m.z);
      wild.mesh?.setYaw(m.yaw);
    }

    this.despawnDistant(playerX, playerZ);

    this.repopulateMs -= dtMs;
    if (this.repopulateMs > 0) return;
    this.repopulateMs = DENSITY.repopulateMs;
    this.topUp(playerX, playerZ, cycle, day);
  }

  /** Bob every active pal. Separate from update so it runs at render rate. */
  animate(elapsedMs: number): void {
    for (const wild of this.active) wild.mesh?.animate(elapsedMs, wild.motion.moving);
  }

  /** The pal the player has walked into, if any. */
  encounterAt(playerX: number, playerZ: number): WildPal | null {
    for (const wild of this.active) {
      if (wantsToEngage(wild.motion, wild.traits, playerX, playerZ)) return wild;
    }
    return null;
  }

  /** Remove one pal from the world, e.g. after it is caught or beaten. */
  remove(wild: WildPal): void {
    const index = this.active.indexOf(wild);
    if (index < 0) return;
    this.active.splice(index, 1);
    if (wild.mesh) this.pool.release(wild.mesh);
    wild.mesh = null;
    this.rolled.delete(wild.chunkKey);
  }

  private despawnDistant(playerX: number, playerZ: number): void {
    for (let i = this.active.length - 1; i >= 0; i--) {
      const wild = this.active[i];
      if (!wild) continue;
      const distance = Math.hypot(playerX - wild.motion.x, playerZ - wild.motion.z);
      if (distance <= DENSITY.despawnDistance) continue;
      this.remove(wild);
    }
  }

  /**
   * Fill empty pool slots from chunks in the spawn band.
   *
   * Candidates come from a ring around the player rather than everything in
   * view, so pals appear at a distance and walk in rather than materialising in
   * front of the camera.
   */
  private topUp(playerX: number, playerZ: number, cycle: number, day: number): void {
    if (this.pool.available <= 0) return;

    const phase = phaseAt(cycle);
    const chunkSize = 64;
    const reach = Math.ceil(DENSITY.spawnRadiusMax / chunkSize);
    const centreX = Math.floor(playerX / chunkSize);
    const centreZ = Math.floor(playerZ / chunkSize);

    for (let cz = centreZ - reach; cz <= centreZ + reach && this.pool.available > 0; cz++) {
      for (let cx = centreX - reach; cx <= centreX + reach && this.pool.available > 0; cx++) {
        const key = `${cx},${cz}`;
        if (this.rolled.has(key)) continue;

        const x = (cx + 0.5) * chunkSize;
        const z = (cz + 0.5) * chunkSize;
        const distance = Math.hypot(playerX - x, playerZ - z);
        if (distance < DENSITY.spawnRadiusMin || distance > DENSITY.spawnRadiusMax) continue;

        this.rolled.add(key);
        this.rollChunk(cx, cz, phase, day);
      }
    }
  }

  private rollChunk(cx: number, cz: number, phase: string, day: number): void {
    // One stream per chunk per day: the same chunk repopulates differently
    // tomorrow without the placement ever depending on wall-clock time.
    const rng = subRng(this.seed, `spawn:${phase}:${day}`, cx, cz);
    if (rng() > DENSITY.perChunkChance) return;

    const chunkSize = 64;
    const x = (cx + rng()) * chunkSize;
    const z = (cz + rng()) * chunkSize;
    const biome = this.terrain.biomeAt(x, z);
    if (biome === 'water') return;

    const table = TABLES[biome]?.[phase];
    if (!table) return;

    const ids = Object.keys(table);
    const speciesId = pickWeighted(rng, ids, (id) => table[id] ?? 0);
    if (!speciesId) return;

    const def = requireSpecies(speciesId);
    const band = def.levels;
    if (!band) return;

    let level = rangeInt(rng, band[0], band[1]);
    // Night is more dangerous, not just darker.
    if (phase === 'night') {
      const [lo, hi] = spawns.nightLevelBonus as [number, number];
      level += rangeInt(rng, lo, hi);
    }

    // Herd species arrive as a group, which is what makes Grazehorn read
    // differently from everything else at the same level.
    const count = def.herd ?? 1;
    for (let i = 0; i < count; i++) {
      if (this.pool.available <= 0) return;
      const ox = x + (i === 0 ? 0 : (rng() - 0.5) * 12);
      const oz = z + (i === 0 ? 0 : (rng() - 0.5) * 12);
      if (this.terrain.heightAt(ox, oz) <= 0) continue;
      this.spawn(def, level, ox, oz, rng, `${cx},${cz}`);
    }
  }

  private spawn(
    def: SpeciesDef,
    level: number,
    x: number,
    z: number,
    rng: () => number,
    chunkKey: string
  ): void {
    const mesh = this.pool.acquire(def, false);
    if (!mesh) return;

    const pal = makePal(def.id, level, rng);
    const y = this.terrain.heightAt(x, z);
    const motion = createMotion(x, y, z, rng() * Math.PI * 2);

    mesh.setPosition(x, y, z);
    mesh.setYaw(motion.yaw);

    this.active.push({
      pal,
      def,
      motion,
      mesh,
      traits: { aggressive: def.aggressive ?? false, skittish: def.skittish ?? false },
      chunkKey
    });
  }

  /**
   * A per-pal RNG stream for wander decisions.
   *
   * Derived from the pal's uid so two pals sharing a chunk do not walk in
   * lockstep, and so a wander choice never reaches for Math.random.
   */
  private rngFor(wild: WildPal): () => number {
    let stream = STREAMS.get(wild.pal.uid);
    if (!stream) {
      stream = subRng(this.seed, `wander:${wild.pal.uid}`);
      STREAMS.set(wild.pal.uid, stream);
    }
    return stream;
  }

  dispose(): void {
    for (const wild of this.active) wild.mesh = null;
    this.active.length = 0;
    this.rolled.clear();
    STREAMS.clear();
    this.pool.dispose();
  }
}

const STREAMS = new Map<string, () => number>();

export { PalMeshPool };
export type { Scene };
