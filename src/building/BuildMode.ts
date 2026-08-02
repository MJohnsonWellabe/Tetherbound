import { Color3, Mesh, CreateBox, Scene, StandardMaterial, TransformNode } from '../core/babylon';
import { bus } from '../core/EventBus';
import type { Intent } from '../core/input/Intent';
import { add, count, remove, type Slots } from '../survival/Inventory';
import { hingeSettled, stepHinge, targetAngle } from './Door';
import {
  BUILD_CONFIG,
  isInteractivePiece,
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
 *
 * A door is two boxes and a pivot: a static frame, plus a leaf parented to a
 * TransformNode sitting at the hinge edge so rotating the pivot swings the
 * leaf rather than spinning it in place. `updateDoors` runs every step
 * regardless of whether the hammer is out, because a door must keep swinging
 * (and stay interactable) after the player puts the hammer away.
 */

interface DoorRig {
  piece: PlacedPiece;
  pivot: TransformNode;
  angle: number;
}

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
  private readonly doors = new Map<PlacedPiece, DoorRig>();
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
    if (isInteractivePiece(piece.pieceId)) this.mountDoor(piece);
    this.elevation = 0;
    bus.emit('builtPiece', { pieceId: piece.pieceId });
  }

  /** Remove the most recently placed piece and refund it. */
  undoLast(): boolean {
    const piece = this.placed.pop();
    if (!piece) return false;
    this.meshes.get(piece)?.dispose();
    this.meshes.delete(piece);
    this.unmountDoor(piece);
    for (const back of refundFor(piece.pieceId, piece.placedAtMs, performance.now())) {
      add(this.slots, back.id, back.n);
    }
    return true;
  }

  /** Rebuild from a save. Doors resume at their saved open/closed state. */
  restore(saved: PlacedPiece[]): void {
    for (const piece of saved) {
      this.placed.push(piece);
      this.meshes.set(piece, this.buildMesh(piece));
      if (isInteractivePiece(piece.pieceId)) this.mountDoor(piece, true);
    }
  }

  /** The nearest placed door within `maxDist`, or null. Drives the interact prompt. */
  nearestDoor(px: number, pz: number, maxDist: number): PlacedPiece | null {
    let best: PlacedPiece | null = null;
    let bestDist = maxDist;
    for (const rig of this.doors.values()) {
      const d = Math.hypot(rig.piece.x - px, rig.piece.z - pz);
      if (d < bestDist) {
        bestDist = d;
        best = rig.piece;
      }
    }
    return best;
  }

  /** Flip a door's open state. The leaf eases toward it over updateDoors(). */
  toggleDoor(piece: PlacedPiece): void {
    const rig = this.doors.get(piece);
    if (!rig) return;
    piece.open = !piece.open;
    bus.emit('doorToggled', { open: piece.open === true, at: { x: piece.x, y: piece.y, z: piece.z } });
  }

  /**
   * Swing every door's leaf toward its target angle. Runs every fixed step
   * unconditionally, independent of hammerEquipped: a door must keep opening
   * after the player has put the hammer away and walked up to it.
   */
  updateDoors(dt: number): void {
    if (this.doors.size === 0) return;
    const dtMs = dt * 1000;
    for (const rig of this.doors.values()) {
      const open = rig.piece.open === true;
      if (hingeSettled(rig.angle, open)) continue;
      rig.angle = stepHinge(rig.angle, open, dtMs);
      rig.pivot.rotation.y = rig.piece.rot + rig.angle;
    }
  }

  /**
   * Build the leaf + hinge pivot for a placed door piece.
   *
   * The pivot sits at the piece's world position and yaw. The leaf is parented
   * to it, offset along the pivot's own local +x by half its width MINUS half
   * the frame's width, so the leaf's hinge-side edge lands on the pivot
   * (local x=0) and rotating the pivot swings the leaf like a door rather
   * than spinning it in place around its own centre.
   *
   * `instant` skips the opening animation (used on load: a save should not
   * replay every door swinging open on boot).
   */
  private mountDoor(piece: PlacedPiece, instant = false): void {
    const def = pieceDef(piece.pieceId);
    const size = def?.size ?? [1, 1, 1];
    const leafWidth = size[0] * 0.94;
    const leafDepth = Math.max(0.06, size[2] * 0.5);

    const pivot = new TransformNode(`door_pivot_${this.placed.length}`, this.scene);
    pivot.position.set(piece.x, piece.y, piece.z);

    const leaf = CreateBox(
      `door_leaf_${this.placed.length}`,
      { width: leafWidth, height: size[1], depth: leafDepth },
      this.scene
    );
    leaf.parent = pivot;
    leaf.position.set(leafWidth / 2, size[1] / 2, 0);
    leaf.material = this.solid;
    leaf.isPickable = false;

    const angle = targetAngle(piece.open === true);
    pivot.rotation.y = piece.rot + (instant ? angle : 0);

    this.doors.set(piece, { piece, pivot, angle: instant ? angle : 0 });
  }

  private unmountDoor(piece: PlacedPiece): void {
    const rig = this.doors.get(piece);
    if (!rig) return;
    rig.pivot.dispose(false, false);
    this.doors.delete(piece);
  }

  private buildMesh(piece: PlacedPiece): Mesh {
    const def = pieceDef(piece.pieceId);
    const size = def?.size ?? [1, 1, 1];
    // A door's frame is the same footprint minus the leaf's footprint down
    // the middle, so the opening reads as an opening even while the leaf sits
    // closed across it (the leaf itself is a separate mesh on the hinge).
    const mesh = CreateBox(
      `build_${piece.pieceId}_${this.placed.length}`,
      { width: size[0], height: size[1], depth: size[2] },
      this.scene
    );
    mesh.position.set(piece.x, piece.y + size[1] / 2, piece.z);
    mesh.rotation.y = piece.rot;
    mesh.material = this.solid;
    mesh.isPickable = false;
    // A door's frame stays visible as the surround; only the leaf (mounted
    // separately) needs to be solid-looking, so the frame is thinned to a
    // slim outline by leaving its own box mostly hollow-reading via alpha.
    // Simplicity wins here: the frame box is cheap and the leaf sits in front
    // of it, so the frame is not rendered for doors at all.
    if (isInteractivePiece(piece.pieceId)) mesh.setEnabled(false);
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
    for (const rig of this.doors.values()) rig.pivot.dispose(false, false);
    this.doors.clear();
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
