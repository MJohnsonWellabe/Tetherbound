import { Matrix, Vector3, Viewport, type FreeCamera, type Scene } from '../core/babylon';
import fx from '../data/fx.json';

/**
 * Floating numbers: "+3 Wood" now, damage in M2.
 *
 * These are pooled DOM nodes, not meshes or sprites. docs/03_TECHNICAL_ARCHITECTURE.md already
 * puts the HUD in an HTML overlay, and the same reasoning applies harder here:
 * text in-canvas needs a font atlas, a material and a draw call per batch,
 * while a `<span>` costs nothing against the 150-draw-call budget, gets real
 * font rendering at any resolution, and inherits `tokens.css` for free.
 *
 * The pool is fixed and pre-created. At capacity the OLDEST live number is
 * recycled rather than a node being created mid-frame; twenty simultaneous
 * numbers are unreadable anyway, so the visible cost of recycling is nothing
 * and the alternative is a DOM insertion during a burst of impacts.
 *
 * Only two properties are written per frame, `transform` and `opacity`, both of
 * which the compositor can animate without laying the page out again. Writing
 * `left`/`top` instead would force a layout pass per number per frame.
 *
 * Ages advance on the fixed simulation step, not on wall clock, so numbers hold
 * still during a hit pause along with everything else.
 */

export type NumberKind = 'gain' | 'loss' | 'damage' | 'info';

interface Floater {
  readonly el: HTMLElement;
  active: boolean;
  ageMs: number;
  /** Ascending stamp, so "oldest" is a comparison rather than a search. */
  serial: number;
  x: number;
  y: number;
  z: number;
  /** Deterministic horizontal offset so stacked numbers stay legible. */
  jitter: number;
}

export class DamageNumbers {
  private readonly pool: Floater[] = [];
  private readonly layer: HTMLElement;
  private serial = 0;
  private readonly scratch = new Vector3();
  private readonly identity = Matrix.Identity();
  private readonly viewport = new Viewport(0, 0, 0, 0);

  constructor(layer: HTMLElement) {
    this.layer = layer;
    for (let i = 0; i < fx.numbers.poolSize; i++) {
      const el = document.createElement('span');
      el.className = 'floater';
      el.setAttribute('aria-hidden', 'true');
      el.style.display = 'none';
      this.layer.appendChild(el);
      this.pool.push({ el, active: false, ageMs: 0, serial: 0, x: 0, y: 0, z: 0, jitter: 0 });
    }
  }

  /** Show `text` rising from a world position. */
  spawn(text: string, x: number, y: number, z: number, kind: NumberKind = 'gain'): void {
    // Lift this one clear of anything spawned a moment ago. Counting live young
    // floaters is done before claiming a slot, so a recycled slot cannot count
    // itself.
    const stack = this.recentCount();

    const slot = this.claim();
    slot.active = true;
    slot.ageMs = 0;
    slot.serial = ++this.serial;
    slot.x = x;
    slot.y = y + fx.numbers.worldOffsetY + stack * fx.numbers.staggerMetres;
    slot.z = z;
    // Hash the serial rather than calling Math.random, so a survey screenshot
    // of the same moment is the same screenshot.
    slot.jitter = (fract(Math.sin(slot.serial * 12.9898) * 43758.5453) * 2 - 1) * fx.numbers.spread;

    slot.el.textContent = text;
    slot.el.className = `floater floater--${kind}`;
    slot.el.style.display = '';
    slot.el.style.opacity = '1';
  }

  /** One fixed simulation step: age and retire. */
  update(dt: number): void {
    const dtMs = dt * 1000;
    for (const slot of this.pool) {
      if (!slot.active) continue;
      slot.ageMs += dtMs;
      if (slot.ageMs >= fx.numbers.lifeMs) this.release(slot);
    }
  }

  /** Render phase: project every live number to a pixel and place it. */
  project(scene: Scene, camera: FreeCamera, width: number, height: number): void {
    this.viewport.x = 0;
    this.viewport.y = 0;
    this.viewport.width = width;
    this.viewport.height = height;
    const view = scene.getViewMatrix();
    const transform = scene.getTransformMatrix();

    for (const slot of this.pool) {
      if (!slot.active) continue;

      const t = slot.ageMs / fx.numbers.lifeMs;
      const rise = t * fx.numbers.riseMetres;
      this.scratch.set(slot.x + slot.jitter, slot.y + rise, slot.z);

      // Project() alone is not enough: a point behind the camera still yields
      // finite screen coordinates, mirrored into view, so a chop at your back
      // paints a number in front of you. The view-space depth is the honest
      // test, and it is one matrix transform we already need.
      Vector3.TransformCoordinatesToRef(this.scratch, view, TEMP);
      if (TEMP.z <= camera.minZ) {
        slot.el.style.opacity = '0';
        continue;
      }

      const screen = Vector3.Project(this.scratch, this.identity, transform, this.viewport);
      const fade =
        slot.ageMs <= fx.numbers.fadeStartMs
          ? 1
          : 1 - (slot.ageMs - fx.numbers.fadeStartMs) / (fx.numbers.lifeMs - fx.numbers.fadeStartMs);

      slot.el.style.transform = `translate3d(${screen.x.toFixed(1)}px, ${screen.y.toFixed(1)}px, 0) translate(-50%, -50%)`;
      slot.el.style.opacity = fade.toFixed(3);
    }
  }

  /** Retire everything immediately. */
  clear(): void {
    for (const slot of this.pool) this.release(slot);
  }

  dispose(): void {
    for (const slot of this.pool) slot.el.remove();
    this.pool.length = 0;
  }

  /** Live floaters young enough that a new one would land on top of them. */
  private recentCount(): number {
    let n = 0;
    for (const slot of this.pool) {
      if (slot.active && slot.ageMs < fx.numbers.staggerWindowMs) n++;
    }
    return n;
  }

  /** A free slot, or the oldest live one. Never allocates. */
  private claim(): Floater {
    let oldest: Floater = this.pool[0] as Floater;
    for (const slot of this.pool) {
      if (!slot.active) return slot;
      if (slot.serial < oldest.serial) oldest = slot;
    }
    return oldest;
  }

  private release(slot: Floater): void {
    slot.active = false;
    slot.el.style.display = 'none';
  }
}

/** Reused across every projection so the render phase allocates nothing. */
const TEMP = new Vector3();

function fract(n: number): number {
  return n - Math.floor(n);
}
