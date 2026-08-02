import {
  Color3,
  CreateTorus,
  FreeCamera,
  Mesh,
  Scene,
  ShadowGenerator,
  StandardMaterial,
  Vector3
} from '../core/babylon';
import combat from '../data/combat.json';
import { PalMesh } from '../entities/PalMesh';
import type { PalState } from '../party/Pal';
import { requireSpecies } from '../party/Species';
import { Battle, type BattleEvent, type BattleOptions } from '../combat/Battle';

/**
 * Combat Mode: a STATE, not a scene.
 *
 * ARCHITECTURE.md rule 5 and GAME_DESIGN.md section 7 both insist on this. The
 * world keeps rendering, the terrain stays live, chunk streaming keeps running,
 * and no loading screen ever appears. All that changes is where the camera is,
 * what the HUD shows, and how input is read.
 *
 * This file owns presentation only. Every rule about who hits whom for how much
 * lives in Battle, which has no idea a camera exists.
 */

/** How far apart the two combatants stand. */
const SEPARATION = 6.5;
/** Lunge distance when a pal commits to an attack. */
const LUNGE = 1.5;

export interface CombatContext {
  scene: Scene;
  camera: FreeCamera;
  shadows: ShadowGenerator | null;
  heightAt: (x: number, z: number) => number;
}

export class CombatMode {
  private readonly allyMesh: PalMesh;
  private readonly enemyMesh: PalMesh;
  private readonly ring: Mesh;
  private readonly ringMaterial: StandardMaterial;

  private battle: Battle | null = null;
  /** Arena centre, midway between the two fighters. */
  private centreX = 0;
  private centreZ = 0;
  /** Direction from ally to enemy, in radians. */
  private axis = 0;
  private allyLunge = 0;
  private enemyLunge = 0;
  private elapsedMs = 0;
  /** Camera blend so entering and leaving a fight is a move, not a cut. */
  private blend = 0;

  constructor(private readonly ctx: CombatContext) {
    this.allyMesh = new PalMesh(ctx.scene, ctx.shadows);
    this.enemyMesh = new PalMesh(ctx.scene, ctx.shadows);

    // The soft ring that marks the arena bounds. A torus lying flat, big enough
    // to frame the fight without walling the player in visually.
    this.ringMaterial = new StandardMaterial('mat_arena_ring', ctx.scene);
    this.ringMaterial.diffuseColor = new Color3(0.9, 0.85, 0.6);
    this.ringMaterial.emissiveColor = new Color3(0.35, 0.3, 0.18);
    this.ringMaterial.specularColor = new Color3(0, 0, 0);
    this.ringMaterial.alpha = 0.32;

    this.ring = CreateTorus(
      'arena_ring',
      { diameter: combat.encounter.arenaRadius * 2, thickness: 0.5, tessellation: 36 },
      ctx.scene
    );
    this.ring.material = this.ringMaterial;
    this.ring.isPickable = false;
    this.ring.setEnabled(false);
  }

  get isActive(): boolean {
    return this.battle !== null;
  }

  get current(): Battle | null {
    return this.battle;
  }

  /**
   * Frame a fight between the player's party and an enemy team.
   *
   * `atX/atZ` is where the encounter happened, so the arena forms around the
   * spot the player walked into rather than teleporting them somewhere flat.
   */
  enter(
    allies: PalState[],
    enemies: PalState[],
    at: { x: number; z: number },
    playerX: number,
    playerZ: number,
    emit: (event: BattleEvent) => void,
    random: () => number,
    options: BattleOptions = {}
  ): Battle {
    this.centreX = (at.x + playerX) / 2;
    this.centreZ = (at.z + playerZ) / 2;
    this.axis = Math.atan2(at.x - playerX, at.z - playerZ);
    this.elapsedMs = 0;
    this.allyLunge = 0;
    this.enemyLunge = 0;
    this.blend = 0;

    this.battle = new Battle(allies, enemies, emit, random, options);

    this.refreshMeshes();
    this.ring.position.set(
      this.centreX,
      this.ctx.heightAt(this.centreX, this.centreZ) + 0.12,
      this.centreZ
    );
    this.ring.setEnabled(true);
    return this.battle;
  }

  /** Re-apply species looks after a swap or an enemy change. */
  refreshMeshes(): void {
    const battle = this.battle;
    if (!battle) return;

    const ally = battle.activeAlly;
    if (ally) {
      this.allyMesh.apply(this.ctx.scene, requireSpecies(ally.species), ally.collared);
      this.allyMesh.setEnabled(true);
    } else {
      this.allyMesh.setEnabled(false);
    }

    const enemy = battle.activeEnemy;
    if (enemy) {
      this.enemyMesh.apply(this.ctx.scene, requireSpecies(enemy.species), enemy.collared);
      this.enemyMesh.setEnabled(true);
    } else {
      this.enemyMesh.setEnabled(false);
    }
  }

  /** Play a short lunge on whichever side just committed. */
  lunge(side: 'ally' | 'enemy'): void {
    if (side === 'ally') this.allyLunge = 1;
    else this.enemyLunge = 1;
  }

  /**
   * One fixed step: advance the fight, then place the meshes and the camera.
   *
   * The battle is advanced first so the camera frames the state the player is
   * about to be shown rather than the previous one.
   */
  update(dtMs: number): void {
    const battle = this.battle;
    if (!battle) return;

    this.elapsedMs += dtMs;
    battle.update(dtMs);

    this.blend = Math.min(1, this.blend + dtMs / 420);
    this.allyLunge = Math.max(0, this.allyLunge - dtMs / 260);
    this.enemyLunge = Math.max(0, this.enemyLunge - dtMs / 260);

    this.placeFighters();
    this.placeCamera();
  }

  private placeFighters(): void {
    const sin = Math.sin(this.axis);
    const cos = Math.cos(this.axis);
    const half = SEPARATION / 2;

    const allyOffset = -half + this.allyLunge * LUNGE;
    const enemyOffset = half - this.enemyLunge * LUNGE;

    const ax = this.centreX + sin * allyOffset;
    const az = this.centreZ + cos * allyOffset;
    const ex = this.centreX + sin * enemyOffset;
    const ez = this.centreZ + cos * enemyOffset;

    this.allyMesh.setPosition(ax, this.ctx.heightAt(ax, az), az);
    this.enemyMesh.setPosition(ex, this.ctx.heightAt(ex, ez), ez);

    // Both auto-face. The player never steers a pal (section 7), so facing is
    // never something they can get wrong.
    this.allyMesh.setYaw(this.axis);
    this.enemyMesh.setYaw(this.axis + Math.PI);

    this.allyMesh.animate(this.elapsedMs, this.allyLunge > 0);
    this.enemyMesh.animate(this.elapsedMs, this.enemyLunge > 0);
  }

  /**
   * Arena framing: side-on, slightly above, both fighters in frame.
   *
   * Perpendicular to the fight axis rather than behind the player, because a
   * behind-the-shoulder camera hides the enemy's telegraph behind your own pal,
   * and the telegraph is the one thing the player must be able to read.
   */
  private placeCamera(): void {
    const perpendicular = this.axis + Math.PI / 2;
    const distance = 9.5;
    const height = 4.6;

    const cx = this.centreX + Math.sin(perpendicular) * distance;
    const cz = this.centreZ + Math.cos(perpendicular) * distance;
    const ground = this.ctx.heightAt(cx, cz);
    const cy = Math.max(this.ctx.heightAt(this.centreX, this.centreZ) + height, ground + 1.8);

    const target = this.ctx.camera.position;
    // Ease in on entry so the cut to arena framing reads as the camera moving.
    const k = this.blend;
    target.set(
      target.x + (cx - target.x) * k,
      target.y + (cy - target.y) * k,
      target.z + (cz - target.z) * k
    );
    this.ctx.camera.setTarget(
      new Vector3(
        this.centreX,
        this.ctx.heightAt(this.centreX, this.centreZ) + 1.2,
        this.centreZ
      )
    );
  }

  /** Tear the arena down. The camera rig takes back over from the next frame. */
  exit(): void {
    this.battle = null;
    this.allyMesh.setEnabled(false);
    this.enemyMesh.setEnabled(false);
    this.ring.setEnabled(false);
  }

  dispose(): void {
    this.exit();
    this.allyMesh.dispose();
    this.enemyMesh.dispose();
    this.ring.dispose();
    this.ringMaterial.dispose();
  }
}
