import { Mesh, Scene, StandardMaterial } from '../core/babylon';
import { buildChunkMesh, chunkMaterial, CHUNK_SIZE } from './ChunkMesh';
import type { Terrain } from './gen/Terrain';

/**
 * Streams terrain around the player. Terrain only: props live in PropBatcher.
 *
 * The split matters. This used to own scatter props too, batching them per
 * chunk, and that coupling is what put the frame 10x over its draw budget:
 * chunk size is chosen for terrain streaming, and it is the wrong size for
 * every prop family at once. Props are now grouped by their own draw distance
 * and this file went back to doing one job.
 *
 * Two rules from ARCHITECTURE.md still drive the shape of it:
 *
 * "Dispose everything. Every geometry, material, and texture created by
 * ChunkManager gets disposed on unload. Leaks kill mobile within minutes."
 *
 * and the frame budget, which is why generation is time-sliced. Building a
 * whole view radius synchronously is tens of thousands of heightfield samples
 * in one frame, and the visible result is a hard stutter every time the player
 * crosses a chunk boundary.
 */

/**
 * Chunks are 128m and the view radius is 3, covering 384m in 29 meshes.
 *
 * It was 64m at radius 5: 320m in 81 meshes. More ground, 52 fewer draw calls,
 * because terrain draw cost scales with chunk COUNT while terrain detail scales
 * with vertex resolution, and those are independent knobs. LOD_RESOLUTION in
 * ChunkMesh.ts was doubled to match, so the near grid is still 2m.
 */
export const VIEW_DISTANCE_CHUNKS = 3;
/** Beyond this many chunks, drop to the next LOD. */
export const LOD_DISTANCE_CHUNKS = 1;

/**
 * Milliseconds of chunk work permitted per frame.
 *
 * Paired with PropBatcher's own budget, so streaming costs at most ~5ms of a
 * frame and only while something is actually being built.
 */
const FRAME_BUDGET_MS = 2.5;

class Chunk {
  constructor(
    readonly mesh: Mesh,
    readonly lod: number
  ) {}

  dispose(): void {
    // Terrain geometry is owned outright, unlike the prop batches which share
    // theirs with a prototype, so this takes the vertex data with it.
    this.mesh.dispose(false, false);
  }
}

export class ChunkManager {
  private readonly loaded = new Map<string, Chunk>();
  private readonly queue: Array<{ cx: number; cz: number; lod: number }> = [];
  private readonly queued = new Set<string>();
  private readonly terrainMat: StandardMaterial;
  private lastChunkX = Number.NaN;
  private lastChunkZ = Number.NaN;

  constructor(
    private readonly scene: Scene,
    private readonly terrain: Terrain
  ) {
    this.terrainMat = chunkMaterial(scene);
  }

  static key(cx: number, cz: number): string {
    return `${cx},${cz}`;
  }

  /** Chunk coordinates containing a world position. */
  static toChunk(x: number, z: number): { cx: number; cz: number } {
    return { cx: Math.floor(x / CHUNK_SIZE), cz: Math.floor(z / CHUNK_SIZE) };
  }

  /**
   * Reconcile the loaded set against the player position. Cheap: it only
   * enqueues work, and returns immediately if the player has not crossed a
   * chunk boundary since the last call.
   */
  update(playerX: number, playerZ: number): void {
    const { cx, cz } = ChunkManager.toChunk(playerX, playerZ);
    if (cx === this.lastChunkX && cz === this.lastChunkZ) return;
    this.lastChunkX = cx;
    this.lastChunkZ = cz;

    const wanted = new Set<string>();
    for (let dz = -VIEW_DISTANCE_CHUNKS; dz <= VIEW_DISTANCE_CHUNKS; dz++) {
      for (let dx = -VIEW_DISTANCE_CHUNKS; dx <= VIEW_DISTANCE_CHUNKS; dx++) {
        // Circular rather than square: a square view distance loads 27% more
        // chunks for corners the fog hides anyway.
        const dist = Math.hypot(dx, dz);
        if (dist > VIEW_DISTANCE_CHUNKS) continue;
        const key = ChunkManager.key(cx + dx, cz + dz);
        wanted.add(key);

        const lod = dist <= LOD_DISTANCE_CHUNKS ? 0 : dist <= VIEW_DISTANCE_CHUNKS - 1 ? 1 : 2;
        const existing = this.loaded.get(key);
        if (existing) {
          if (existing.lod !== lod) {
            existing.dispose();
            this.loaded.delete(key);
          } else {
            continue;
          }
        }
        if (this.queued.has(key)) continue;
        this.queued.add(key);
        this.queue.push({ cx: cx + dx, cz: cz + dz, lod });
      }
    }

    for (const [key, chunk] of this.loaded) {
      if (!wanted.has(key)) {
        chunk.dispose();
        this.loaded.delete(key);
      }
    }

    // Nearest first, so the ground under the player exists before the horizon.
    this.queue.sort((a, b) => Math.hypot(a.cx - cx, a.cz - cz) - Math.hypot(b.cx - cx, b.cz - cz));
  }

  /** Drain the build queue under a per-frame time budget. */
  processQueue(budgetMs = FRAME_BUDGET_MS): void {
    const deadline = performance.now() + budgetMs;
    while (this.queue.length > 0 && performance.now() < deadline) {
      const next = this.queue.shift();
      if (!next) break;
      const key = ChunkManager.key(next.cx, next.cz);
      this.queued.delete(key);
      if (this.loaded.has(key)) continue;
      const mesh = buildChunkMesh(
        this.scene,
        this.terrain,
        next.cx,
        next.cz,
        next.lod,
        this.terrainMat
      );
      this.loaded.set(key, new Chunk(mesh, next.lod));
    }
  }

  get loadedCount(): number {
    return this.loaded.size;
  }

  get pendingCount(): number {
    return this.queue.length;
  }

  dispose(): void {
    for (const chunk of this.loaded.values()) chunk.dispose();
    this.loaded.clear();
    this.queue.length = 0;
    this.queued.clear();
    this.terrainMat.dispose();
  }
}
