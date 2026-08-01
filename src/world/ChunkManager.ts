import { Matrix, Mesh, Quaternion, Scene, ShadowGenerator, StandardMaterial, Vector3 } from '../core/babylon';
import { buildChunkMesh, chunkMaterial, CHUNK_SIZE } from './ChunkMesh';
import { scatterInRect, type ScatterPoint } from './gen/Scatter';
import type { Terrain } from './gen/Terrain';
import type { PropFamily, Prototype } from './Prototypes';

/**
 * Streams terrain and props around the player.
 *
 * Two rules from ARCHITECTURE.md drive the shape of this file:
 *
 * "Dispose everything. Every geometry, material, and texture created by
 * ChunkManager gets disposed on unload. Leaks kill mobile within minutes."
 *
 * and the 60fps budget, which is why generation is time-sliced. Building every
 * chunk in a 5-chunk radius synchronously is thousands of heightfield samples
 * and thousands of matrix composes in one frame, and the visible result is a
 * hard stutter every time the player crosses a chunk boundary.
 */

export const VIEW_DISTANCE_CHUNKS = 5;
/** Beyond this many chunks, drop to the next LOD. */
export const LOD_DISTANCE_CHUNKS = 3;

/** Milliseconds of chunk work permitted per frame. */
const FRAME_BUDGET_MS = 4;

export interface PropCollider {
  x: number;
  z: number;
  radius: number;
}

interface ScatterPass {
  label: string;
  families: PropFamily[];
  minDistance: number;
  mask: (terrain: Terrain, x: number, z: number) => boolean;
  density?: (terrain: Terrain, x: number, z: number) => number;
  /** Vertical offset applied per family, so a canopy sits on its trunk. */
  yOffset: number[];
  scaleRange: [number, number];
}

/**
 * The scatter passes that define what the Meadows looks like.
 *
 * Data-driven in the sense that matters: adding a prop family is an entry
 * here, not a change to the streaming logic. Moving this into a JSON file is
 * the M6 biome-template job, when a second biome exists to justify the schema.
 */
const PASSES: ScatterPass[] = [
  {
    label: 'oak',
    families: ['tree_trunk', 'tree_canopy'],
    minDistance: 11,
    mask: (t, x, z) => {
      const b = t.biomeAt(x, z);
      return (b === 'meadow' || b === 'grove') && t.slopeAt(x, z) < 24;
    },
    // Sparse oak groves in grassland, per GAME_DESIGN.md section 9. The
    // meadow gets the occasional lone tree; the grove gets a stand.
    density: (t, x, z) => (t.biomeAt(x, z) === 'grove' ? 0.85 : 0.1),
    yOffset: [2.1, 4.6],
    scaleRange: [0.82, 1.25]
  },
  {
    label: 'pine',
    families: ['pine_trunk', 'pine_canopy'],
    minDistance: 13,
    mask: (t, x, z) => t.biomeAt(x, z) === 'grove' && t.slopeAt(x, z) < 28,
    density: () => 0.35,
    yOffset: [2.8, 5.4],
    scaleRange: [0.85, 1.3]
  },
  {
    label: 'rock',
    families: ['rock'],
    minDistance: 7,
    mask: (t, x, z) => {
      const b = t.biomeAt(x, z);
      return b === 'rock' || b === 'meadow' || b === 'riverbank';
    },
    density: (t, x, z) => (t.biomeAt(x, z) === 'rock' ? 0.8 : 0.08),
    yOffset: [0.35],
    scaleRange: [0.6, 2.1]
  },
  {
    label: 'bush',
    families: ['bush'],
    minDistance: 6,
    mask: (t, x, z) => {
      const b = t.biomeAt(x, z);
      return (b === 'meadow' || b === 'grove') && t.slopeAt(x, z) < 30;
    },
    density: () => 0.3,
    yOffset: [0.5],
    scaleRange: [0.7, 1.4]
  },
  {
    label: 'reed',
    families: ['reed'],
    minDistance: 2.2,
    mask: (t, x, z) => t.biomeAt(x, z) === 'riverbank',
    density: () => 0.7,
    yOffset: [0.7],
    scaleRange: [0.7, 1.5]
  },
  {
    label: 'flower',
    families: ['flower'],
    minDistance: 3.4,
    mask: (t, x, z) => t.biomeAt(x, z) === 'meadow' && t.slopeAt(x, z) < 22,
    density: () => 0.45,
    yOffset: [0.17],
    scaleRange: [0.8, 1.3]
  },
  {
    label: 'grass',
    families: ['grass'],
    minDistance: 1.9,
    mask: (t, x, z) => {
      const b = t.biomeAt(x, z);
      return b === 'meadow' || b === 'grove';
    },
    density: () => 0.8,
    yOffset: [0.32],
    scaleRange: [0.7, 1.6]
  }
];

class Chunk {
  readonly meshes: Mesh[] = [];
  readonly colliders: PropCollider[] = [];
  /** Scatter points by key, so harvest state can be looked up on interact. */
  readonly nodes = new Map<string, { family: PropFamily; x: number; y: number; z: number }>();

  constructor(
    readonly cx: number,
    readonly cz: number,
    readonly lod: number
  ) {}

  dispose(): void {
    for (const mesh of this.meshes) {
      // Geometry is shared with the prototype for prop meshes, and owned
      // outright for terrain. Babylon refcounts it, so this is correct for
      // both: the prototype keeps prop geometry alive, terrain geometry goes.
      mesh.dispose(false, false);
    }
    this.meshes.length = 0;
    this.colliders.length = 0;
    this.nodes.clear();
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
    private readonly terrain: Terrain,
    private readonly prototypes: Map<PropFamily, Prototype>,
    private readonly shadows: ShadowGenerator | null = null
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
    this.queue.sort(
      (a, b) => Math.hypot(a.cx - cx, a.cz - cz) - Math.hypot(b.cx - cx, b.cz - cz)
    );
  }

  /**
   * Drain the build queue under a per-frame time budget.
   *
   * The budget is the whole point. A 5-chunk radius is 81 chunks, each with a
   * heightfield mesh and seven scatter passes. Building them in one go blocks
   * the main thread long enough to drop a visible number of frames every time
   * the player crosses a boundary.
   */
  processQueue(budgetMs = FRAME_BUDGET_MS): void {
    const deadline = performance.now() + budgetMs;
    while (this.queue.length > 0 && performance.now() < deadline) {
      const next = this.queue.shift();
      if (!next) break;
      const key = ChunkManager.key(next.cx, next.cz);
      this.queued.delete(key);
      if (this.loaded.has(key)) continue;
      this.loaded.set(key, this.buildChunk(next.cx, next.cz, next.lod));
    }
  }

  private buildChunk(cx: number, cz: number, lod: number): Chunk {
    const chunk = new Chunk(cx, cz, lod);

    const terrainMesh = buildChunkMesh(this.scene, this.terrain, cx, cz, lod, this.terrainMat);
    chunk.meshes.push(terrainMesh);

    // Distant chunks get terrain only. Scattering props onto ground that is a
    // few pixels tall is most of the cost of a chunk for none of the benefit.
    if (lod > 1) return chunk;

    const minX = cx * CHUNK_SIZE;
    const minZ = cz * CHUNK_SIZE;

    for (const pass of PASSES) {
      // Ground cover is dense and short. Rendering it beyond the near ring
      // costs thousands of instances for something under a pixel.
      if (lod > 0 && pass.minDistance < 4) continue;

      const points = scatterInRect(
        {
          seed: this.terrain.seed,
          label: pass.label,
          minDistance: pass.minDistance,
          mask: (x, z) => pass.mask(this.terrain, x, z),
          ...(pass.density ? { density: (x: number, z: number) => pass.density!(this.terrain, x, z) } : {})
        },
        minX,
        minZ,
        minX + CHUNK_SIZE,
        minZ + CHUNK_SIZE
      );
      if (points.length === 0) continue;

      pass.families.forEach((family, familyIndex) => {
        const proto = this.prototypes.get(family);
        if (!proto) return;
        const mesh = this.instantiateBatch(proto, family, cx, cz, points, pass, familyIndex);
        if (mesh) chunk.meshes.push(mesh);
      });

      // Colliders and harvest nodes come from the first family only, since the
      // families in a pass are parts of one prop.
      const first = pass.families[0];
      const proto = first ? this.prototypes.get(first) : undefined;
      for (const p of points) {
        const y = this.terrain.heightAt(p.x, p.z);
        if (proto && proto.collisionRadius > 0) {
          chunk.colliders.push({ x: p.x, z: p.z, radius: proto.collisionRadius });
        }
        if (first) chunk.nodes.set(p.key, { family: first, x: p.x, y, z: p.z });
      }
    }

    return chunk;
  }

  private instantiateBatch(
    proto: Prototype,
    family: PropFamily,
    cx: number,
    cz: number,
    points: ScatterPoint[],
    pass: ScatterPass,
    familyIndex: number
  ): Mesh | null {
    // A clone shares the prototype's geometry and material, so a batch costs
    // one draw call and no new vertex data.
    const mesh = proto.mesh.clone(`${family}_${cx}_${cz}`, null, true);
    if (!mesh) return null;
    mesh.setEnabled(true);
    mesh.isPickable = false;
    mesh.receiveShadows = false;

    const matrices = new Float32Array(points.length * 16);
    const yOffset = pass.yOffset[familyIndex] ?? 0;
    const [minScale, maxScale] = pass.scaleRange;

    const scale = Vector3.Zero();
    const position = Vector3.Zero();
    const rotation = Quaternion.Identity();
    const matrix = Matrix.Identity();

    for (let i = 0; i < points.length; i++) {
      const p = points[i];
      if (!p) continue;
      const s = minScale + p.roll * (maxScale - minScale);
      scale.set(s, s, s);
      position.set(p.x, this.terrain.heightAt(p.x, p.z) + yOffset * s, p.z);
      Quaternion.RotationYawPitchRollToRef(p.rotation, 0, 0, rotation);
      Matrix.ComposeToRef(scale, rotation, position, matrix);
      matrix.copyToArray(matrices, i * 16);
    }

    // `true` marks the buffer static: it never changes after upload, so Babylon
    // keeps it GPU-side instead of re-uploading every frame.
    mesh.thinInstanceSetBuffer('matrix', matrices, 16, true);

    // Bounds MUST be set explicitly. A clone inherits the prototype's bounding
    // box, which describes one small prop at the origin, so every batch would
    // be frustum-culled the moment the camera looked away from world zero.
    //
    // Computed from the chunk footprint rather than by calling
    // thinInstanceRefreshBoundingInfo, which walks every instance matrix on
    // every batch. The footprint is known, generous, and free: chunk extents
    // horizontally, and the terrain's own height range plus headroom for the
    // tallest prop vertically.
    const padding = 8;
    const minX = cx * CHUNK_SIZE;
    const minZ = cz * CHUNK_SIZE;
    const baseY = this.terrain.heightAt(minX + CHUNK_SIZE / 2, minZ + CHUNK_SIZE / 2);
    mesh.buildBoundingInfo(
      new Vector3(minX - padding, baseY - 60, minZ - padding),
      new Vector3(minX + CHUNK_SIZE + padding, baseY + 60, minZ + CHUNK_SIZE + padding)
    );
    mesh.alwaysSelectAsActiveMesh = false;

    if (this.shadows && proto.collisionRadius > 0) {
      this.shadows.addShadowCaster(mesh, false);
    }
    return mesh;
  }

  /** Colliders near a position, for the character controller. */
  collidersNear(x: number, z: number, radius: number): PropCollider[] {
    const out: PropCollider[] = [];
    const { cx, cz } = ChunkManager.toChunk(x, z);
    // One chunk of margin covers any radius smaller than CHUNK_SIZE.
    for (let dz = -1; dz <= 1; dz++) {
      for (let dx = -1; dx <= 1; dx++) {
        const chunk = this.loaded.get(ChunkManager.key(cx + dx, cz + dz));
        if (!chunk) continue;
        for (const c of chunk.colliders) {
          const reach = radius + c.radius;
          if ((c.x - x) ** 2 + (c.z - z) ** 2 <= reach * reach) out.push(c);
        }
      }
    }
    return out;
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
