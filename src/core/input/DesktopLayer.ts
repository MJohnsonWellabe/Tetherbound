import config from '../../data/input.json';
import type { Intent, InputMode, PartySlot } from './Intent';

/**
 * Keyboard and mouse. Writes into the same Intent the touch layer does.
 *
 * Pointer lock is requested on the first click rather than at boot, because a
 * browser will refuse a lock that did not come from a user gesture, and a
 * refused lock leaves the camera dead with no visible cause.
 *
 * Key handling is by `event.code`, not `event.key`. `code` is physical
 * position, so WASD stays in the same place on AZERTY and Dvorak instead of
 * scattering across the keyboard.
 */

const { mouse: MOUSE } = config;

/** Below this, a keypress is a dodge tap rather than a strafe hold. */
const DODGE_TAP_MS = 180;

const SLOT_CODES: Record<string, PartySlot> = {
  Digit1: 1,
  Digit2: 2,
  Digit3: 3,
  Digit4: 4,
  Digit5: 5
};

export class DesktopLayer {
  private readonly held = new Set<string>();
  private readonly pressedAt = new Map<string, number>();
  private readonly teardown: Array<() => void> = [];
  private mode: InputMode = 'explore';
  private primaryDownMs = 0;
  private primaryActive = false;
  private locked = false;
  /** Right button held: look without pointer lock. */
  private dragging = false;
  /** True once the keyboard or mouse has actually been used. */
  active = false;

  constructor(
    private readonly canvas: HTMLCanvasElement,
    private readonly intent: Intent
  ) {
    this.bind();
  }

  setMode(mode: InputMode): void {
    this.mode = mode;
  }

  private bind(): void {
    const keyDown = (e: KeyboardEvent): void => this.onKeyDown(e);
    const keyUp = (e: KeyboardEvent): void => this.onKeyUp(e);
    const mouseDown = (e: MouseEvent): void => this.onMouseDown(e);
    const mouseUp = (e: MouseEvent): void => this.onMouseUp(e);
    const mouseMove = (e: MouseEvent): void => this.onMouseMove(e);
    const lockChange = (): void => {
      this.locked = document.pointerLockElement === this.canvas;
    };
    const contextMenu = (e: Event): void => e.preventDefault();
    const blur = (): void => this.releaseAll();

    window.addEventListener('keydown', keyDown);
    window.addEventListener('keyup', keyUp);
    this.canvas.addEventListener('mousedown', mouseDown);
    window.addEventListener('mouseup', mouseUp);
    window.addEventListener('mousemove', mouseMove);
    document.addEventListener('pointerlockchange', lockChange);
    this.canvas.addEventListener('contextmenu', contextMenu);
    // Alt-tabbing away while holding W must not leave the player sprinting
    // into a lake forever.
    window.addEventListener('blur', blur);

    this.teardown.push(() => {
      window.removeEventListener('keydown', keyDown);
      window.removeEventListener('keyup', keyUp);
      this.canvas.removeEventListener('mousedown', mouseDown);
      window.removeEventListener('mouseup', mouseUp);
      window.removeEventListener('mousemove', mouseMove);
      document.removeEventListener('pointerlockchange', lockChange);
      this.canvas.removeEventListener('contextmenu', contextMenu);
      window.removeEventListener('blur', blur);
    });
  }

  private onKeyDown(e: KeyboardEvent): void {
    if (e.repeat) return;
    this.active = true;
    this.held.add(e.code);
    this.pressedAt.set(e.code, performance.now());

    if (e.code === 'Space') {
      // Space is jump while exploring and a neutral dodge in a fight.
      if (this.mode === 'combat') this.intent.dodge = 0;
      else this.intent.jump = true;
      e.preventDefault();
    }
    if (e.code === 'KeyE') this.intent.interact = true;

    const slot = SLOT_CODES[e.code];
    if (slot) this.intent.slot = slot;
  }

  private onKeyUp(e: KeyboardEvent): void {
    this.held.delete(e.code);
    const pressedAt = this.pressedAt.get(e.code);
    this.pressedAt.delete(e.code);

    // In combat A/D are dodges rather than strafes, and a dodge is a tap. A
    // held key is the player still thinking, not a commitment.
    if (this.mode === 'combat' && pressedAt !== undefined) {
      const heldMs = performance.now() - pressedAt;
      if (heldMs <= DODGE_TAP_MS) {
        if (e.code === 'KeyA') this.intent.dodge = -1;
        if (e.code === 'KeyD') this.intent.dodge = 1;
      }
    }
  }

  /**
   * True when mouse look is currently engaged, by either route.
   *
   * The HUD uses this to decide whether to tell the player how to look around.
   * Pointer lock needs a click, nothing on screen said so, and the reported
   * symptom was "on pc I don't know how to look around but I can move".
   */
  get isLooking(): boolean {
    return this.locked || this.dragging;
  }

  private onMouseDown(e: MouseEvent): void {
    this.active = true;
    if (e.button === 2) {
      // Right-drag looks without pointer lock. Lock is still the better path,
      // but a game that appears to have no camera control at all is worse than
      // one with a slightly clumsy one, and some setups refuse lock outright.
      this.dragging = true;
    }
    if (!this.locked && e.button === 0 && this.mode === 'explore') {
      void this.canvas.requestPointerLock?.();
    }
    if (e.button === 0) {
      this.intent.primary.down = true;
      this.intent.primary.heldMs = 0;
      this.primaryDownMs = performance.now();
      this.primaryActive = true;
    }
  }

  private onMouseUp(e: MouseEvent): void {
    if (e.button === 2) this.dragging = false;
    if (e.button === 0 && this.primaryActive) {
      this.intent.primary.down = false;
      this.intent.primary.heldMs = performance.now() - this.primaryDownMs;
      this.primaryActive = false;
    }
  }

  private onMouseMove(e: MouseEvent): void {
    if (this.locked) {
      this.intent.look.x += e.movementX * MOUSE.sensX;
      this.intent.look.y += e.movementY * MOUSE.sensY;
      return;
    }
    if (this.dragging) {
      this.intent.look.x += e.movementX * MOUSE.dragSensX;
      this.intent.look.y += e.movementY * MOUSE.dragSensY;
      return;
    }
    // Otherwise the cursor belongs to the UI. Rotating the world under a menu
    // the player is reading is disorienting.
  }

  /**
   * This layer's own movement vector.
   *
   * Deliberately NOT written straight into the shared Intent. Both layers mount
   * whenever the hardware reports touch points, so writing directly meant this
   * poll zeroed the touch stick's vector every single frame: on a phone the
   * player could look around and never move, because `look` accumulates and
   * `move` was overwritten. Input.beginFrame() combines the two.
   */
  readonly move = { x: 0, y: 0 };
  sprint = false;

  /** Fold held keys into this layer's own move/sprint. Called once per frame. */
  poll(): void {
    let x = 0;
    let y = 0;
    if (this.held.has('KeyW') || this.held.has('ArrowUp')) y += 1;
    if (this.held.has('KeyS') || this.held.has('ArrowDown')) y -= 1;
    // Strafing is movement while exploring and dodging while fighting, so the
    // horizontal axis simply goes quiet in combat.
    if (this.mode === 'explore') {
      if (this.held.has('KeyD') || this.held.has('ArrowRight')) x += 1;
      if (this.held.has('KeyA') || this.held.has('ArrowLeft')) x -= 1;
    }

    const mag = Math.hypot(x, y);
    if (mag > 1) {
      x /= mag;
      y /= mag;
    }
    this.move.x = x;
    this.move.y = y;
    this.sprint = this.held.has('ShiftLeft') || this.held.has('ShiftRight');

    // Only advance the charge this layer started. Otherwise a touch-initiated
    // hold gets its heldMs recomputed against a stale mouse-down timestamp.
    if (this.primaryActive && this.intent.primary.down) {
      this.intent.primary.heldMs = performance.now() - this.primaryDownMs;
    }
  }

  private releaseAll(): void {
    this.held.clear();
    this.pressedAt.clear();
    this.dragging = false;
    this.move.x = 0;
    this.move.y = 0;
    this.sprint = false;
    this.primaryActive = false;
    this.intent.primary.down = false;
    this.intent.primary.heldMs = 0;
  }

  dispose(): void {
    for (const fn of this.teardown.splice(0)) fn();
    this.releaseAll();
    if (document.pointerLockElement === this.canvas) document.exitPointerLock?.();
  }
}
