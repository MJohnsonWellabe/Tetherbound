import { Color3, Mesh, CreateBox, Scene, StandardMaterial } from '../core/babylon';
import { bus } from '../core/EventBus';
import type { Intent } from '../core/input/Intent';
import { add, count, remove, type Slots } from '../survival/Inventory';
import {
  BUILD_CONFIG,
  pieceDef,
  pieceIds,
  refundFor,
  resolvePlacement,
  type PlacedPiece
} from './SnapGrid';

/**
 * Build mode: the ghost, the placement, the pieces in the world.
 *
 * Opens when the hammer is equipped, per GAME_DESIGN.md section 8. The snap
 * logic lives in SnapGrid.ts and is pure; this file owns the meshes and the
 * inventory side effects.
 *
 * Pieces are boxes for now. ASSETS.md is explicit that anything missing from a
 * kit "gets built from primitives in code, which is acceptable and fast", and
 * because a piece is referenced by id the M5 model swap is a data change.
 */

export interface WorldProbe {
  heightAt(x: number, z: number): number;
  slopeAt(x: number, z: number): number;
}

export class BuildMode {
  active = false;
  private selected = 0;
  private rot = 0;
  private elevation = 0;
  private ghost: Mesh | null = null;
  private readonly placed: PlacedPiece[] = [];
  private readonly meshes = new Map<PlacedPiece, Mesh>();
  private readonly valid: StandardMaterial;
  private readonly invalid: StandardMaterial;
  private readonly solid: StandardMaterial;
  private readonly ids = pieceIds();

  constructor(
    private readonly scene: Scene,
    private readonly slots: Slots,
    private readonly world: WorldProbe
  ) {
    this.valid = tinted(scene, 'mat_ghost_ok', new Color3(0.45, 0.9, 0.5), 0.42);
    this.invalid = tinted(scene, 'mat_ghost_no', new Color3(0.95, 0.35, 0.3), 0.42);
    this.solid = tinted(scene, 'mat_build', new Color3(0.55, 0.4, 0.25), 1);
  }

  get selectedId(): string {
    return this.ids[this.selected] ?? '';
  }

  get pieceCount(): number {
    return this.placed.length;
  }

  /** Everything placed, for the save. */
  get structures(): readonly PlacedPiece[] {
    return this.placed;
  }

  /**
   * One fixed step.
   *
   * `hammerEquipped` gates the whole mode: no hammer, no ghost, no placement.
   * Section 8 makes building a tool action rather than a menu.
   */
  update(intent: Intent, hammerEquipped: boolean, px: number, pz: number, yaw: number): void {
    if (!hammerEquipped) {
      this.setActive(false);
      return;
    }
    this.setActive(true);

    // The slot input cycles pieces while the hammer is out, so building never
    // needs its own second control scheme.
    if (intent.slot !== null) {
      this.selected = (intent.slot - 1) % this.ids.length;
    }
    if (intent.dodge !== 0) {
      this.rot += intent.dodge * BUILD_CONFIG.rotationStepRadians;
    }
    if (intent.jump) this.elevation += BUILD_CONFIG.elevationStep;

    const reach = BUILD_CONFIG.placeReach;
    const tx = px + Math.sin(yaw) * reach;
    const tz = pz + Math.cos(yaw) * reach;
    const result = resolvePlacement(
      this.selectedId,
      tx,
      this.world.heightAt(tx, tz) + this.elevation,
      tz,
      this.rot,
      this.placed,
      this.world.heightAt(tx, tz),
      this.world.slopeAt(tx, tz)
    );

    this.drawGhost(result.x, result.y, result.z, result.rot, result.valid);

    if (intent.interact && result.valid) {
      this.place(result.x, result.y, result.z, result.rot);
    }
  }

  private place(x: number, y: number, z: number, rot: number): void {
    const def = pieceDef(this.selectedId);
    if (!def) return;
    for (const cost of def.cost) {
      if (count(this.slots, cost.id) < cost.n) {
        bus.emit('buildBlocked', { reason: 'materials' });
        return;
      }
    }
    for (const cost of def.cost) remove(this.slots, cost.id, cost.n);

    const piece: PlacedPiece = { pieceId: this.selectedId, x, y, z, rot, placedAtMs: performance.now() };
    this.placed.push(piece);
    this.meshes.set(piece, this.buildMesh(piece));
    this.elevation = 0;
    bus.emit('builtPiece', { pieceId: piece.pieceId });
  }

  /** Remove the most recently placed piece and refund it. */
  undoLast(): boolean {
    const piece = this.placed.pop();
    if (!piece) return false;
    this.meshes.get(piece)?.dispose();
    this.meshes.delete(piece);
    for (const back of refundFor(piece.pieceId, piece.placedAtMs, performance.now())) {
      add(this.slots, back.id, back.n);
    }
    return true;
  }

  /** Rebuild from a save. */
  restore(pieces: PlacedPiece[]): void {
    for (const piece of pieces) {
      this.placed.push(piece);
      this.meshes.set(piece, this.buildMesh(piece));
    }
  }

  private buildMesh(piece: PlacedPiece): Mesh {
    const def = pieceDef(piece.pieceId);
    const size = def?.size ?? [1, 1, 1];
    const mesh = CreateBox(
      `build_${piece.pieceId}_${this.placed.length}`,
      { width: size[0], height: size[1], depth: size[2] },
      this.scene
    );
    mesh.position.set(piece.x, piece.y + size[1] / 2, piece.z);
    mesh.rotation.y = piece.rot;
    mesh.material = this.solid;
    mesh.isPickable = false;
    mesh.freezeWorldMatrix();
    return mesh;
  }

  private drawGhost(x: number, y: number, z: number, rot: number, valid: boolean): void {
    const def = pieceDef(this.selectedId);
    if (!def) return;
    if (!this.ghost || this.ghost.metadata !== this.selectedId) {
      this.ghost?.dispose();
      this.ghost = CreateBox(
        'build_ghost',
        { width: def.size[0], height: def.size[1], depth: def.size[2] },
        this.scene
      );
      this.ghost.metadata = this.selectedId;
      this.ghost.isPickable = false;
    }
    this.ghost.position.set(x, y + def.size[1] / 2, z);
    this.ghost.rotation.y = rot;
    this.ghost.material = valid ? this.valid : this.invalid;
    this.ghost.setEnabled(true);
  }

  private setActive(on: boolean): void {
    if (this.active === on) return;
    this.active = on;
    if (!on) this.ghost?.setEnabled(false);
  }

  dispose(): void {
    this.ghost?.dispose();
    for (const mesh of this.meshes.values()) mesh.dispose();
    this.meshes.clear();
    this.placed.length = 0;
    this.valid.dispose();
    this.invalid.dispose();
    this.solid.dispose();
  }
}

function tinted(scene: Scene, name: string, color: Color3, alpha: number): StandardMaterial {
  const mat = new StandardMaterial(name, scene);
  mat.diffuseColor = color;
  mat.specularColor = new Color3(0, 0, 0);
  mat.alpha = alpha;
  return mat;
}
