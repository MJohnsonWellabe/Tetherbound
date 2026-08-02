import type { Mesh } from '../core/babylon';
import spawns from '../data/spawns.json';
import type { PalState } from '../party/PalState';
import type { Terrain } from '../world/gen/Terrain';
import { hashSeed, mulberry32 } from '../world/gen/Rng';
import { createAi, stepAi, type AiState } from './PalAI';
import type { PalVisuals } from './PalVisual';
import { createPal, derive, speciesDef, type SpeciesDef } from './Species';

/**
 * Spawns wild pals around the player and drives their AI.
 *
 * Capped at 12 active within view (GAME_DESIGN.md section 9) and pooled from
 * the first frame, so walking across the Meadows does not allocate a mesh per
 * encounter. Spawn choice is seeded per attempt rather than from
 * `Math.random()`, so a seed plus a position plus a time reproduces the same
 * roster and a bug report about a rare spawn is actionable.
 */

export interface WildPal {
  state: PalState;
  ai: AiState;
  mesh: Mesh | null;
  x: number;
  z: number;
  y: number;
  yaw: number;
  active: boolean;
}

interface SpawnRow {
  species: string;
  weight: number;
}

const TABLES = spawns.tables as Record<string, SpawnRow[] | undefined>;
const WINDOWS = spawns.windows as unknown as Record<string, [number, number] | undefined>;

/** Which named window a cycle position falls in. 0 is dawn. */
export function windowAt(cycle: number): string {
  const t = ((cycle % 1) + 1) % 1;
  for (const [name, range] of Object.entries(WINDOWS)) {
    if (!range) continue;
    if (t >= range[0] && t < range[1]) return name;
  }
  return 'day';
}

export class SpawnManager {
  private readonly pool: WildPal[] = [];
  private sinceSpawnMs = 0;
  private counter = 0;

  constructor(
    private readonly terrain: Terrain,
    private readonly visuals: PalVisuals
  ) {
    for (let i = 0; i < spawns.poolSize; i++) {
      this.pool.push({
        state: null as unknown as PalState,
        ai: null as unknown as AiState,
        mesh: null,
        x: 0,
        z: 0,
        y: 0,
        yaw: 0,
        active: false
      });
    }
  }

  get active(): WildPal[] {
    return this.pool.filter((p) => p.active);
  }

  get activeCount(): number {
    return this.pool.reduce((n, p) => n + (p.active ? 1 : 0), 0);
  }

  /** One fixed step. */
  update(playerX: number, playerZ: number, dt: number, cycle: number, day: number): void {
    this.despawnFar(playerX, playerZ);
    this.driveAi(playerX, playerZ, dt);

    this.sinceSpawnMs += dt * 1000;
    if (this.sinceSpawnMs < spawns.spawnIntervalMs) return;
    this.sinceSpawnMs = 0;
    if (this.activeCount >= spawns.maxActive) return;
    this.trySpawn(playerX, playerZ, cycle, day);
  }

  private despawnFar(playerX: number, playerZ: number): void {
    for (const pal of this.pool) {
      if (!pal.active) continue;
      if (Math.hypot(pal.x - playerX, pal.z - playerZ) > spawns.despawnRadius) this.release(pal);
    }
  }

  private driveAi(playerX: number, playerZ: number, dt: number): void {
    for (const pal of this.pool) {
      if (!pal.active || !pal.mesh) continue;
      const def = speciesDef(pal.state.species);
      if (!def) continue;

      const dx = playerX - pal.x;
      const dz = playerZ - pal.z;
      const rng = mulberry32(hashSeed(pal.state.uid, Math.floor(pal.ai.timer * 1000)));
      const out = stepAi(
        pal.ai,
        def,
        {
          distanceToPlayer: Math.hypot(dx, dz),
          bearingToPlayer: Math.atan2(dx, dz),
          distanceFromHome: Math.hypot(pal.x - pal.ai.homeX, pal.z - pal.ai.homeZ),
          headingHome: Math.atan2(pal.ai.homeX - pal.x, pal.ai.homeZ - pal.z)
        },
        dt,
        rng
      );

      if (out.throttle > 0) {
        // Speed stat drives movement, scaled down so a Voltvole is quick
        // without being uncatchable on foot.
        const speed = (derive(pal.state).spd / 14) * out.throttle;
        pal.x += Math.sin(out.heading) * speed * dt;
        pal.z += Math.cos(out.heading) * speed * dt;
        pal.yaw = out.heading;
      }
      pal.y = this.terrain.heightAt(pal.x, pal.z);
      pal.mesh.position.set(pal.x, pal.y, pal.z);
      pal.mesh.rotation.y = pal.yaw;
    }
  }

  private trySpawn(playerX: number, playerZ: number, cycle: number, day: number): void {
    const slot = this.pool.find((p) => !p.active);
    if (!slot) return;

    this.counter++;
    const rng = mulberry32(
      hashSeed(`${this.terrain.seed}:spawn`, Math.round(playerX), Math.round(playerZ), this.counter)
    );

    // Somewhere in a ring around the player: close enough to find, far enough
    // not to appear in front of their face.
    const angle = rng() * Math.PI * 2;
    const radius =
      spawns.spawnRadiusMin + rng() * (spawns.spawnRadiusMax - spawns.spawnRadiusMin);
    const x = playerX + Math.sin(angle) * radius;
    const z = playerZ + Math.cos(angle) * radius;

    const biome = this.terrain.biomeAt(x, z);
    if (biome === 'water') return;
    const table = TABLES[biome];
    if (!table) return;

    const window = windowAt(cycle);
    const eligible = table.filter((row) => {
      const def = speciesDef(row.species);
      if (!def || def.role === 'boss') return false;
      if (def.timeWindows && !def.timeWindows.includes(window)) return false;
      if (def.biomes && !def.biomes.includes(biome)) return false;
      return true;
    });
    if (eligible.length === 0) return;

    const picked = pickWeighted(eligible, rng);
    if (!picked) return;
    const def = speciesDef(picked.species);
    if (!def) return;

    const level = rollLevel(def, window, rng);
    slot.state = createPal(picked.species, level, day, performance.now(), rng, `wild_${this.counter}`);
    slot.ai = createAi(x, z, rng);
    slot.x = x;
    slot.z = z;
    slot.y = this.terrain.heightAt(x, z);
    slot.yaw = rng() * Math.PI * 2;
    slot.mesh = this.visuals.acquireMesh(picked.species);
    slot.active = slot.mesh !== null;
  }

  /** Take a pal out of the world, after a catch or a despawn. */
  release(pal: WildPal): void {
    pal.mesh?.dispose(false, false);
    pal.mesh = null;
    pal.active = false;
  }

  /** Nearest active pal within `radius`, for the encounter check. */
  nearest(x: number, z: number, radius: number): WildPal | null {
    let best: WildPal | null = null;
    let bestDist = radius;
    for (const pal of this.pool) {
      if (!pal.active) continue;
      const d = Math.hypot(pal.x - x, pal.z - z);
      if (d < bestDist) {
        bestDist = d;
        best = pal;
      }
    }
    return best;
  }

  dispose(): void {
    for (const pal of this.pool) this.release(pal);
    this.pool.length = 0;
  }
}

function pickWeighted(rows: SpawnRow[], rng: () => number): SpawnRow | undefined {
  const total = rows.reduce((n, r) => n + r.weight, 0);
  if (total <= 0) return undefined;
  let roll = rng() * total;
  for (const row of rows) {
    roll -= row.weight;
    if (roll <= 0) return row;
  }
  return rows[rows.length - 1];
}

/** Level inside the species band, raised at night per section 9. */
function rollLevel(def: SpeciesDef, window: string, rng: () => number): number {
  const band = def.levelBand ?? [1, 1];
  const lo = band[0];
  const hi = band[1];
  let level = lo + Math.floor(rng() * (hi - lo + 1));
  if (window === 'night') {
    level +=
      spawns.nightLevelBonusMin +
      Math.floor(rng() * (spawns.nightLevelBonusMax - spawns.nightLevelBonusMin + 1));
  }
  return Math.max(1, level);
}
