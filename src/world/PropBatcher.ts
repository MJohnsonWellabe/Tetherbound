import { ShadowGenerator } from '../core/babylon';
import config from '../data/scatter.json';
import type { Terrain } from './gen/Terrain';
import { buildPropCell, type FamilyConfig, type PropCell, type PropCollider, type PropNode } from './PropCell';
import type { PrototypeSet } from './Prototypes';

/**
 * Renders every scatter prop in the world, batched by (family x spatial cell).
 *
 * This is the renderer half that world/gen/Scatter.ts refers to, and it exists
 * because the previous arrangement, one mesh per prop family per TERRAIN chunk,
 * measured 1576 draw calls against ARCHITECTURE.md's budget of 150. Chunks are
 * sized for terrain streaming, and a grass tuft and an oak have no business
 * sharing that size: grass is invisible past ~40m and an oak reads at 200m, so
 * batching both at 64m meant hundreds of near-empty draw calls for the grass
 * and hundreds of redundant ones for the trees.
 *
 * Here each family owns a cell size equal to its own draw distance, from
 * scatter.json. A disc of radius R only ever touches a 3x3 neighbourhood of
 * cells R across, so at most nine cells per family are resident and each is a
 * single draw call.
 *
 * Nothing about generation changed. scatterInRect() is defined on a global
 * jittered grid with no reference to chunks or cells (DECISIONS.md D19), so the
 * same props appear in the same places regardless of how they are grouped for
 * drawing.
 */

/** Milliseconds of batch building permitted per frame. */
const FRAME_BUDGET_MS = 2.5;

export type { PropCollider, PropNode } from './PropCell';

const FAMILIES = config.families as FamilyConfig[];

const MIN_CELL_SIZE = FAMILIES.reduce(
  (min, f) => Math.min(min, f.cellSize),
  Number.POSITIVE_INFINITY
);

function cellKey(family: string, ix: number, iz: number): string {
  return `${family}|${ix},${iz}`;
}

/** Distance from a point to the nearest edge of a cell, 0 if inside. */
function distanceToCell(x: number, z: number, ix: number, iz: number, size: number): number {
  const nearX = Math.max(ix * size, Math.min(x, (ix + 1) * size));
  const nearZ = Math.max(iz * size, Math.min(z, (iz + 1) * size));
  return Math.hypot(x - nearX, z - nearZ);
}

export class PropBatcher {
  private readonly cells = new Map<string, PropCell>();
  private readonly queue: Array<{ family: FamilyConfig; ix: number; iz: number }> = [];
  private readonly queued = new Set<string>();
  /** Node keys the player has harvested. Excluded from every rebuild. */
  private readonly harvested = new Set<string>();
  private lastX = Number.NaN;
  private lastZ = Number.NaN;

  constructor(
    private readonly terrain: Terrain,
    private readonly prototypes: PrototypeSet,
    private readonly shadows: ShadowGenerator | null = null,
    /** Scales every family's draw distance. The quality governor drives it. */
    private drawScale = 1
  ) {}

  /**
   * Reconcile resident cells against the player position.
   *
   * Called every simulation step, so it early-returns unless the player has
   * moved far enough that the resident set could plausibly have changed.
   */
  update(playerX: number, playerZ: number): void {
    if (Number.isFinite(this.lastX)) {
      const moved = Math.hypot(playerX - this.lastX, playerZ - this.lastZ);
      // The smallest cell decides how often reconciliation is worth doing.
      if (moved < MIN_CELL_SIZE * 0.25) return;
    }
    this.lastX = playerX;
    this.lastZ = playerZ;

    const wanted = new Set<string>();

    for (const family of FAMILIES) {
      const size = family.cellSize;
      const reach = family.drawDistance * this.drawScale;
      const i0x = Math.floor((playerX - reach) / size);
      const i1x = Math.floor((playerX + reach) / size);
      const i0z = Math.floor((playerZ - reach) / size);
      const i1z = Math.floor((playerZ + reach) / size);

      for (let iz = i0z; iz <= i1z; iz++) {
        for (let ix = i0x; ix <= i1x; ix++) {
          // Nearest-edge distance, so a cell clipping the draw radius at one
          // corner still loads rather than popping in later.
          if (distanceToCell(playerX, playerZ, ix, iz, size) > reach) continue;

          const key = cellKey(family.id, ix, iz);
          wanted.add(key);
          if (this.cells.has(key) || this.queued.has(key)) continue;
          this.queued.add(key);
          this.queue.push({ family, ix, iz });
        }
      }
    }

    for (const [key, cell] of this.cells) {
      if (!wanted.has(key)) {
        this.disposeCell(cell);
        this.cells.delete(key);
      }
    }

    // Drop queued work that has gone out of range again. A player sprinting
    // across cell boundaries would otherwise build batches they have left.
    for (let i = this.queue.length - 1; i >= 0; i--) {
      const item = this.queue[i];
      if (!item) continue;
      if (!wanted.has(cellKey(item.family.id, item.ix, item.iz))) {
        this.queue.splice(i, 1);
        this.queued.delete(cellKey(item.family.id, item.ix, item.iz));
      }
    }

    // Nearest first, so what the player is standing in appears before the
    // horizon does.
    this.queue.sort(
      (a, b) =>
        distanceToCell(playerX, playerZ, a.ix, a.iz, a.family.cellSize) -
        distanceToCell(playerX, playerZ, b.ix, b.iz, b.family.cellSize)
    );

    this.updateShadowCasters(playerX, playerZ);
  }

  /**
   * Register only nearby batches as shadow casters.
   *
   * Every collidable batch used to cast, which put 34 meshes in the shadow map
   * and drew them a second time every frame. Shadows past ~140m are a handful
   * of pixels under fog, so the far ones are pure cost. Cells are large, so
   * this toggles at cell granularity rather than per instance.
   */
  private updateShadowCasters(playerX: number, playerZ: number): void {
    if (!this.shadows) return;
    for (const cell of this.cells.values()) {
      if (!cell.mesh || !cell.family.castsShadow) continue;
      const size = cell.family.cellSize;
      const ix = Math.floor(cell.cx / size);
      const iz = Math.floor(cell.cz / size);
      const near = distanceToCell(playerX, playerZ, ix, iz, size) <= cell.family.shadowDistance;
      if (near === cell.casting) continue;
      if (near) this.shadows.addShadowCaster(cell.mesh, false);
      else this.shadows.removeShadowCaster(cell.mesh, false);
      cell.casting = near;
    }
  }

  /** Drain the build queue under a per-frame time budget. */
  processQueue(budgetMs = FRAME_BUDGET_MS): void {
    const deadline = performance.now() + budgetMs;
    while (this.queue.length > 0 && performance.now() < deadline) {
      const next = this.queue.shift();
      if (!next) break;
      const key = cellKey(next.family.id, next.ix, next.iz);
      this.queued.delete(key);
      if (this.cells.has(key)) continue;

      const cell = this.build(next.family, next.ix, next.iz);
      this.cells.set(key, cell);

      // A freshly built cell has to be considered for casting immediately, or
      // it stays shadowless until the player next moves a whole cell.
      if (this.shadows && cell.mesh && cell.family.castsShadow) {
        const near =
          distanceToCell(this.lastX, this.lastZ, next.ix, next.iz, next.family.cellSize) <=
          next.family.shadowDistance;
        if (near) {
          this.shadows.addShadowCaster(cell.mesh, false);
          cell.casting = true;
        }
      }
    }
  }

  private build(family: FamilyConfig, ix: number, iz: number): PropCell {
    return buildPropCell(this.terrain, this.prototypes, family, ix, iz, this.harvested);
  }

  private disposeCell(cell: PropCell): void {
    if (cell.mesh) {
      if (this.shadows && cell.casting) this.shadows.removeShadowCaster(cell.mesh, false);
      // Each cell owns its geometry (PropCell calls makeGeometryUnique, which
      // it must, or cells overwrite each other's instance buffers). Disposing
      // the mesh takes that copy and its instance buffer with it, and leaves
      // the prototype and the shared material alone.
      cell.mesh.dispose(false, false);
    }
    cell.mesh = null;
    cell.casting = false;
    cell.colliders.length = 0;
    cell.nodes.length = 0;
  }

  /** Colliders near a position, for the character controller. */
  collidersNear(x: number, z: number, radius: number): PropCollider[] {
    const out: PropCollider[] = [];
    const pad = config.colliderQueryPadding;
    for (const cell of this.cells.values()) {
      if (cell.colliders.length === 0) continue;
      // Reject the whole cell before touching its contents.
      const half = cell.family.cellSize / 2 + radius + pad;
      if (Math.abs(x - cell.cx) > half || Math.abs(z - cell.cz) > half) continue;
      for (const c of cell.colliders) {
        const reach = radius + c.radius;
        if ((c.x - x) ** 2 + (c.z - z) ** 2 <= reach * reach) out.push(c);
      }
    }
    return out;
  }

  /** Harvestable nodes near a position, nearest first. For M1 interaction. */
  nodesNear(x: number, z: number, radius: number): PropNode[] {
    const out: PropNode[] = [];
    const rSq = radius * radius;
    for (const cell of this.cells.values()) {
      if (cell.nodes.length === 0) continue;
      const half = cell.family.cellSize / 2 + radius;
      if (Math.abs(x - cell.cx) > half || Math.abs(z - cell.cz) > half) continue;
      for (const n of cell.nodes) {
        if ((n.x - x) ** 2 + (n.z - z) ** 2 <= rSq) out.push(n);
      }
    }
    out.sort(
      (a, b) => (a.x - x) ** 2 + (a.z - z) ** 2 - ((b.x - x) ** 2 + (b.z - z) ** 2)
    );
    return out;
  }

  /**
   * Remove a harvested node from the world.
   *
   * The instance lives inside a packed matrix buffer, so the cell it belongs to
   * is rebuilt rather than patched. That is one scatter pass and one buffer
   * upload, which is fine for something that only happens when a player
   * deliberately swings a tool, and much simpler than maintaining a free list
   * inside the instance buffer.
   *
   * `harvested` is consulted by buildPropCell, so a rebuild for any other
   * reason keeps the node gone, and a save that restores the set restores the
   * stumps with it.
   */
  markHarvested(node: PropNode): void {
    if (this.harvested.has(node.key)) return;
    this.harvested.add(node.key);

    const size = node.cellSize;
    const ix = Math.floor(node.x / size);
    const iz = Math.floor(node.z / size);
    const key = cellKey(node.family, ix, iz);
    const cell = this.cells.get(key);
    if (!cell) return;
    const family = cell.family;
    this.disposeCell(cell);
    this.cells.set(key, this.build(family, ix, iz));
  }

  /** Restore harvested state from a save, before the first update(). */
  restoreHarvested(keys: Iterable<string>): void {
    for (const k of keys) this.harvested.add(k);
    this.lastX = Number.NaN;
  }

  get harvestedKeys(): string[] {
    return [...this.harvested];
  }

  /** Rescale every family's draw distance. The quality governor calls this. */
  setDrawScale(scale: number): void {
    if (Math.abs(scale - this.drawScale) < 0.01) return;
    this.drawScale = scale;
    // Force the next update() to reconcile rather than early-returning.
    this.lastX = Number.NaN;
  }

  get batchCount(): number {
    let n = 0;
    for (const cell of this.cells.values()) if (cell.mesh) n++;
    return n;
  }

  get shadowCasterCount(): number {
    let n = 0;
    for (const cell of this.cells.values()) if (cell.casting) n++;
    return n;
  }

  get pendingCount(): number {
    return this.queue.length;
  }

  /**
   * Live thin-instance count per family, summed across every resident cell.
   * For the `?stats=1` readout: a family whose count reads zero near the
   * player while others read normally is the instancing-broke symptom, not a
   * scatter-density one.
   */
  instanceCountsByFamily(): Record<string, number> {
    const out: Record<string, number> = {};
    for (const cell of this.cells.values()) {
      const id = cell.family.id;
      out[id] = (out[id] ?? 0) + (cell.mesh?.thinInstanceCount ?? 0);
    }
    return out;
  }

  dispose(): void {
    for (const cell of this.cells.values()) this.disposeCell(cell);
    this.cells.clear();
    this.queue.length = 0;
    this.queued.clear();
  }
}
