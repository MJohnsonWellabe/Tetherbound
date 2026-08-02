import { applyDeadZone, type Intent, type InputMode } from './Intent';

/**
 * Touch input. Left thumb moves, right thumb looks and fights.
 *
 * Design calls worth knowing before changing anything here:
 *
 * - The stick has NO fixed on-screen position. Wherever the left thumb lands
 *   becomes the origin. A stick painted at a fixed spot demands the player
 *   look at their thumb, and it is wrong for every hand size at once.
 *
 * - Sprint comes from pushing the stick past 92% and holding, not a button.
 *   The thumb is already there. A separate sprint button competes with the
 *   stick for the same thumb, which is why so many mobile games have a sprint
 *   nobody uses.
 *
 * - A dodge is a fast horizontal flick, distinguished from a look-drag by
 *   speed rather than distance. Distance thresholds make a slow deliberate
 *   camera pan register as a dodge partway through.
 *
 * Everything is Pointer Events, so there is no separate mouse path. One
 * pointerId is tracked per role, which is what makes moving and looking at the
 * same time work.
 */

const STICK_RADIUS_PX = 58;
const DEAD_ZONE = 0.18;
const SPRINT_THRESHOLD = 0.92;
const SPRINT_HOLD_MS = 220;

/** Radians of look per screen pixel dragged. */
const LOOK_SENS_X = 0.0052;
const LOOK_SENS_Y = 0.0040;

/** A flick faster than this, mostly horizontal, is a dodge. */
const DODGE_SPEED_PX_PER_MS = 1.1;
const DODGE_MIN_PX = 34;

/** Past this, a right-thumb press is a drag rather than a tap. */
const TAP_SLOP_PX = 12;

interface StickState {
  pointerId: number;
  originX: number;
  originY: number;
  atFullSince: number;
}

interface LookState {
  pointerId: number;
  lastX: number;
  lastY: number;
  startX: number;
  startY: number;
  startMs: number;
  movedPx: number;
  /** Recent horizontal velocity, px/ms, smoothed. Feeds dodge detection. */
  velX: number;
  lastMoveMs: number;
}

export class TouchLayer {
  /**
   * This layer's own movement vector, combined with the desktop layer's by
   * Input.beginFrame(). See the note in DesktopLayer: writing straight into the
   * shared Intent meant whichever layer polled last won, and the keyboard poll
   * runs every frame with no keys held, so the stick was silently zeroed.
   */
  readonly move = { x: 0, y: 0 };
  sprint = false;

  private stick: StickState | null = null;
  private look: LookState | null = null;
  private readonly teardown: Array<() => void> = [];
  private mode: InputMode = 'explore';

  /** Set by the HUD so the stick ring can be drawn. Null when not touching. */
  onStickChange: ((origin: { x: number; y: number } | null, dx: number, dy: number) => void) | null =
    null;

  constructor(
    private readonly target: HTMLElement,
    private readonly intent: Intent
  ) {
    this.bind();
  }

  setMode(mode: InputMode): void {
    this.mode = mode;
  }

  private bind(): void {
    const down = (e: PointerEvent): void => this.onDown(e);
    const move = (e: PointerEvent): void => this.onMove(e);
    const up = (e: PointerEvent): void => this.onUp(e);

    this.target.addEventListener('pointerdown', down);
    // Listen for move/up on the window, not the target. A thumb that slides
    // off the canvas edge mid-drag must not strand the stick in a held state.
    window.addEventListener('pointermove', move);
    window.addEventListener('pointerup', up);
    window.addEventListener('pointercancel', up);

    this.teardown.push(() => {
      this.target.removeEventListener('pointerdown', down);
      window.removeEventListener('pointermove', move);
      window.removeEventListener('pointerup', up);
      window.removeEventListener('pointercancel', up);
    });
  }

  private isLeftHalf(x: number): boolean {
    return x < window.innerWidth * 0.5;
  }

  private onDown(e: PointerEvent): void {
    if (e.pointerType === 'mouse') return; // desktop layer owns the mouse

    if (this.isLeftHalf(e.clientX) && !this.stick) {
      this.stick = {
        pointerId: e.pointerId,
        originX: e.clientX,
        originY: e.clientY,
        atFullSince: 0
      };
      this.onStickChange?.({ x: e.clientX, y: e.clientY }, 0, 0);
      return;
    }

    if (!this.isLeftHalf(e.clientX) && !this.look) {
      this.look = {
        pointerId: e.pointerId,
        lastX: e.clientX,
        lastY: e.clientY,
        startX: e.clientX,
        startY: e.clientY,
        startMs: performance.now(),
        movedPx: 0,
        velX: 0,
        lastMoveMs: performance.now()
      };
      // In combat the throw and both attacks live under this thumb, so the
      // press begins a charge immediately. GAME_DESIGN.md section 7: the throw
      // is available from the first frame of a fight.
      if (this.mode === 'combat') {
        this.intent.primary.down = true;
        this.intent.primary.heldMs = 0;
      }
    }
  }

  private onMove(e: PointerEvent): void {
    if (this.stick && e.pointerId === this.stick.pointerId) {
      const dx = e.clientX - this.stick.originX;
      const dy = e.clientY - this.stick.originY;
      const nx = Math.max(-1, Math.min(1, dx / STICK_RADIUS_PX));
      const ny = Math.max(-1, Math.min(1, dy / STICK_RADIUS_PX));
      const moved = applyDeadZone(nx, ny, DEAD_ZONE);

      // Screen y grows downward; forward is negative y.
      this.move.x = moved.x;
      this.move.y = -moved.y;

      const mag = Math.hypot(moved.x, moved.y);
      if (mag >= SPRINT_THRESHOLD) {
        if (this.stick.atFullSince === 0) this.stick.atFullSince = performance.now();
        this.sprint = performance.now() - this.stick.atFullSince >= SPRINT_HOLD_MS;
      } else {
        this.stick.atFullSince = 0;
        this.sprint = false;
      }

      this.onStickChange?.({ x: this.stick.originX, y: this.stick.originY }, dx, dy);
      return;
    }

    if (this.look && e.pointerId === this.look.pointerId) {
      const dx = e.clientX - this.look.lastX;
      const dy = e.clientY - this.look.lastY;
      const now = performance.now();
      const elapsed = Math.max(now - this.look.lastMoveMs, 1);

      // Exponential smoothing. A single jittery sample should not trigger a
      // dodge, but the response still has to be immediate.
      this.look.velX = this.look.velX * 0.5 + (dx / elapsed) * 0.5;
      this.look.lastMoveMs = now;
      this.look.movedPx += Math.hypot(dx, dy);
      this.look.lastX = e.clientX;
      this.look.lastY = e.clientY;

      if (this.mode === 'combat') {
        this.tryDodge(e.clientX);
      } else {
        this.intent.look.x += dx * LOOK_SENS_X;
        this.intent.look.y += dy * LOOK_SENS_Y;
      }
    }
  }

  private tryDodge(clientX: number): void {
    if (!this.look || this.intent.dodge !== 0) return;
    const totalDx = clientX - this.look.startX;
    const speed = Math.abs(this.look.velX);
    if (speed >= DODGE_SPEED_PX_PER_MS && Math.abs(totalDx) >= DODGE_MIN_PX) {
      this.intent.dodge = totalDx > 0 ? 1 : -1;
      // A committed dodge cancels the charge. Otherwise releasing after the
      // flick would also fire an attack the player never asked for.
      this.intent.primary.down = false;
      this.intent.primary.heldMs = 0;
      this.look.startX = clientX;
      this.look.velX = 0;
    }
  }

  private onUp(e: PointerEvent): void {
    if (this.stick && e.pointerId === this.stick.pointerId) {
      this.stick = null;
      this.move.x = 0;
      this.move.y = 0;
      this.sprint = false;
      this.onStickChange?.(null, 0, 0);
      return;
    }

    if (this.look && e.pointerId === this.look.pointerId) {
      const wasTap = this.look.movedPx < TAP_SLOP_PX;
      this.look = null;

      if (this.mode === 'combat') {
        // The system reading primary sees the release edge via `down` going
        // false while heldMs still holds the charge duration.
        this.intent.primary.down = false;
      } else if (wasTap) {
        // A tap that did not become a drag is "use the thing in front of me".
        this.intent.interact = true;
      }
    }
  }

  dispose(): void {
    for (const fn of this.teardown.splice(0)) fn();
    this.stick = null;
    this.look = null;
    this.onStickChange = null;
  }
}
