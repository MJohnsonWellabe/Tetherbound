import { detectDevice } from '../Engine';
import { clearEdges, type Intent, type InputMode, neutralIntent } from './Intent';
import { DesktopLayer } from './DesktopLayer';
import { TouchLayer } from './TouchLayer';

/**
 * The single input entry point. Gameplay reads `input.intent` and nothing else.
 *
 * Both layers mount when the device supports both, rather than picking one at
 * boot. A Windows laptop with a touchscreen, an iPad with a keyboard, and a
 * phone plugged into a monitor are all real, and a capability check that
 * chooses once gets all three wrong. Each layer only claims events its own
 * pointer type produces, so they coexist without fighting.
 */
export class Input {
  readonly intent: Intent = neutralIntent();
  private readonly touch: TouchLayer | null;
  private readonly desktop: DesktopLayer;
  private mode: InputMode = 'explore';

  constructor(canvas: HTMLCanvasElement, overlayTarget: HTMLElement = document.body) {
    const device = detectDevice();
    this.desktop = new DesktopLayer(canvas, this.intent);
    // Mount the touch layer whenever the hardware reports any touch point,
    // which is a wider net than the coarse-pointer check used for render
    // quality. Being wrong here costs an unused listener; being wrong the
    // other way costs a player who cannot move.
    this.touch =
      device.isTouch || navigator.maxTouchPoints > 0
        ? new TouchLayer(overlayTarget, this.intent)
        : null;
  }

  get isTouch(): boolean {
    return this.touch !== null;
  }

  /**
   * Switch how gestures are read. CombatMode calls this on enter and exit.
   * A/D and horizontal swipes mean strafe while exploring and dodge while
   * fighting, and the player never drives pal movement.
   */
  setMode(mode: InputMode): void {
    if (this.mode === mode) return;
    this.mode = mode;
    this.desktop.setMode(mode);
    this.touch?.setMode(mode);
    // Anything mid-gesture belongs to the old mode. Carrying a half-finished
    // swipe across the boundary produces a dodge on the first frame of a fight.
    this.intent.move.x = 0;
    this.intent.move.y = 0;
    this.desktop.move.x = 0;
    this.desktop.move.y = 0;
    if (this.touch) {
      this.touch.move.x = 0;
      this.touch.move.y = 0;
    }
    this.intent.primary.down = false;
    this.intent.primary.heldMs = 0;
    clearEdges(this.intent);
  }

  get currentMode(): InputMode {
    return this.mode;
  }

  /**
   * Combine both layers into the shared Intent. Call once per frame, before
   * update.
   *
   * Each layer owns its own vector and this sums them, rather than each layer
   * writing straight into the Intent. The direct-write version had a bug that
   * made the game unplayable on a phone: both layers mount whenever the
   * hardware reports touch points, `desktop.poll()` runs every frame and
   * unconditionally assigned `intent.move` from held keys, and with no keyboard
   * attached that assignment was always zero. The touch stick wrote a vector
   * and had it erased microseconds later, every frame. Looking around still
   * worked, because `look` accumulates with `+=` and no poll overwrites it, so
   * the symptom was "I can look but not move".
   */
  beginFrame(): void {
    this.desktop.poll();

    let x = this.desktop.move.x + (this.touch?.move.x ?? 0);
    let y = this.desktop.move.y + (this.touch?.move.y ?? 0);
    // Summing can exceed the unit circle if someone drives both at once.
    const mag = Math.hypot(x, y);
    if (mag > 1) {
      x /= mag;
      y /= mag;
    }
    this.intent.move.x = x;
    this.intent.move.y = y;
    this.intent.sprint = this.desktop.sprint || (this.touch?.sprint ?? false);
  }

  /** Clear edge-triggered fields. Call once per frame, after update. */
  endFrame(): void {
    clearEdges(this.intent);
  }

  /** Expose the touch stick position so the HUD can draw its ring. */
  set onStickChange(
    cb: ((origin: { x: number; y: number } | null, dx: number, dy: number) => void) | null
  ) {
    if (this.touch) this.touch.onStickChange = cb;
  }

  dispose(): void {
    this.desktop.dispose();
    this.touch?.dispose();
  }
}

export type { Intent, InputMode } from './Intent';
