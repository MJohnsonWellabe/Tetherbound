import { Vector3, type Engine, type FreeCamera, type Scene } from '../core/babylon';
import fxData from '../data/fx.json';
import { DamageNumbers, type NumberKind } from './DamageNumbers';
import { Particles } from './Particles';
import {
  consumePause,
  createHitPause,
  requestPause,
  type HitPauseState
} from './hitPause';
import {
  addTrauma,
  createShake,
  isShaking,
  shakeOffset,
  stepShake,
  type ShakeOffset,
  type ShakeState
} from './shake';

/**
 * The feel layer, behind one object.
 *
 * The point of this facade is that a call site names an EVENT, not a set of
 * magnitudes: `fx.impact('fell_wood', x, y, z)` rather than four calls that
 * each carry a tuned number. That is what keeps `fx.json` the only place feel
 * is authored, and it is what makes M2 combat a table entry plus a call rather
 * than a second implementation of all of this.
 *
 * Integration contract with `Loop.ts`, which is the part that is easy to get
 * wrong:
 *
 *   update(dt):  if (fx.frozen(dt)) return;   // skip simulation, keep rendering
 *                ...simulate...
 *                fx.update(dt);
 *
 *   render():    fx.render(scene, camera, engine);
 *
 * `frozen()` consumes the step. See `hitPause.ts` for why a freeze may not be
 * implemented by scaling delta or by skipping frames.
 */

export type ImpactId = keyof typeof fxData.impacts;

/** Module-level scratch, so the render phase allocates nothing. */
const LOCAL_RIGHT = new Vector3(1, 0, 0);
const LOCAL_UP = new Vector3(0, 1, 0);
const RIGHT = new Vector3();
const UP = new Vector3();

interface Impact {
  readonly trauma: number;
  readonly pauseMs: number;
  readonly particles: string;
}

export class Fx {
  readonly numbers: DamageNumbers;
  readonly particles: Particles;

  private readonly shakeState: ShakeState = createShake();
  private readonly pauseState: HitPauseState = createHitPause();
  private readonly offset: ShakeOffset = { x: 0, y: 0 };
  /** What was added to the camera last frame, so it can be undone exactly. */
  private appliedX = 0;
  private appliedY = 0;
  private appliedZ = 0;

  constructor(scene: Scene, layer: HTMLElement) {
    this.numbers = new DamageNumbers(layer);
    this.particles = new Particles(scene);
  }

  /**
   * Play a named impact: shake, freeze and particles in one call.
   *
   * An unknown id is ignored rather than thrown. A missing feel entry should
   * cost a dull hit, not a crash in the middle of combat; `tests/fx.test.ts`
   * catches the typo at build time instead.
   */
  impact(id: ImpactId | string, x: number, y: number, z: number): void {
    const impact = (fxData.impacts as Record<string, Impact>)[id];
    if (!impact) return;
    addTrauma(this.shakeState, impact.trauma, fxData.shake);
    requestPause(this.pauseState, impact.pauseMs, fxData.hitPause);
    this.particles.burst(impact.particles, x, y, z);
  }

  /** Shake with no other consequence. For rumbles that are not impacts. */
  shake(trauma: number): void {
    addTrauma(this.shakeState, trauma, fxData.shake);
  }

  /** A floating number at a world position. */
  number(text: string, x: number, y: number, z: number, kind: NumberKind = 'gain'): void {
    this.numbers.spawn(text, x, y, z, kind);
  }

  /**
   * Consume one fixed step of any pending freeze.
   *
   * Returns true when the caller must skip its simulation for this step. The
   * caller must still render.
   */
  frozen(dt: number): boolean {
    return consumePause(this.pauseState, dt);
  }

  /** One fixed simulation step, after the world has advanced. */
  update(dt: number): void {
    stepShake(this.shakeState, dt, fxData.shake);
    this.numbers.update(dt);
  }

  /**
   * Render phase: displace the camera and place the floating numbers.
   *
   * The previous displacement is subtracted before the new one is added. Adding
   * blind would compound frame over frame during a hit pause, when the camera
   * rig is not running to reset the position, and the camera would drift out of
   * the world.
   */
  render(scene: Scene, camera: FreeCamera, engine: Engine): void {
    camera.position.x -= this.appliedX;
    camera.position.y -= this.appliedY;
    camera.position.z -= this.appliedZ;
    this.appliedX = 0;
    this.appliedY = 0;
    this.appliedZ = 0;

    if (isShaking(this.shakeState)) {
      shakeOffset(this.shakeState, fxData.shake, this.offset);
      // Displace along the camera's own right and up axes so the shake reads
      // the same whether the player is looking at the horizon or at their feet.
      // A world-space offset would slide sideways when looking down.
      camera.getDirectionToRef(LOCAL_RIGHT, RIGHT);
      camera.getDirectionToRef(LOCAL_UP, UP);
      this.appliedX = RIGHT.x * this.offset.x + UP.x * this.offset.y;
      this.appliedY = RIGHT.y * this.offset.x + UP.y * this.offset.y;
      this.appliedZ = RIGHT.z * this.offset.x + UP.z * this.offset.y;
      camera.position.x += this.appliedX;
      camera.position.y += this.appliedY;
      camera.position.z += this.appliedZ;
      // The rig already computed this frame's view matrix from the unshaken
      // position. Without the forced recompute the offset lands one frame late.
      camera.getViewMatrix(true);
    }

    this.numbers.project(scene, camera, engine.getRenderWidth(), engine.getRenderHeight());
  }

  dispose(): void {
    this.numbers.dispose();
    this.particles.dispose();
  }
}
