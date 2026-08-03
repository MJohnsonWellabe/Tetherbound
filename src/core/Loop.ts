/**
 * Fixed-timestep simulation with decoupled, interpolated rendering.
 *
 * docs/03_TECHNICAL_ARCHITECTURE.md is unambiguous: never scale gameplay by raw frame delta. A
 * 144Hz desktop and a thermally-throttled phone must run the same simulation,
 * or every tuned constant in the game (stamina drain, the 0.6s telegraph, the
 * catch-ring shrink) means something different per device.
 *
 * The accumulator pattern: bank real elapsed time, spend it in whole 1/60s
 * steps, and hand the leftover fraction to the renderer as `alpha` so motion
 * stays smooth between steps.
 *
 * This module is engine-free on purpose: pure timing, unit tested in
 * tests/loop.test.ts by driving `advance()` by hand.
 */

export const FIXED_HZ = 60;
export const FIXED_DT = 1 / FIXED_HZ;

/**
 * Ceiling on how much time one frame may bank. Without it, a tab restored
 * after five minutes in the background hands us 300 seconds, we try to run
 * 18,000 steps in one frame, the page locks, the next delta is even bigger,
 * and the loop never recovers. This is the classic "spiral of death"; clamping
 * means a backgrounded tab resumes with a small time skip instead of a hang.
 */
export const MAX_FRAME_MS = 250;

export interface LoopCallbacks {
  /** Fixed-step simulation. Called 0..n times per frame, always with FIXED_DT. */
  update: (dt: number, elapsedMs: number) => void;
  /** Render. Called once per frame. `alpha` is 0..1 between the last two steps. */
  render: (alpha: number) => void;
}

/**
 * Pure accumulator state, separated from requestAnimationFrame so the stepping
 * maths can be tested without a browser.
 */
export class FixedStepAccumulator {
  private accumulator = 0;
  private elapsedMs = 0;
  private stepsTaken = 0;

  /**
   * Bank `frameMs` and report how many fixed steps should run this frame.
   * Clamped to MAX_FRAME_MS. Callers must actually run that many steps.
   */
  advance(frameMs: number): number {
    // Negative deltas are possible if a clock is adjusted mid-session.
    const clamped = Math.min(Math.max(frameMs, 0), MAX_FRAME_MS);
    this.accumulator += clamped / 1000;
    let steps = 0;
    while (this.accumulator >= FIXED_DT) {
      this.accumulator -= FIXED_DT;
      this.elapsedMs += FIXED_DT * 1000;
      steps++;
    }
    this.stepsTaken += steps;
    return steps;
  }

  /** Fraction of a step banked but not yet spent. Feeds render interpolation. */
  get alpha(): number {
    return this.accumulator / FIXED_DT;
  }

  /** Simulated time, in ms. Advances only in whole steps, never wall clock. */
  get simulatedMs(): number {
    return this.elapsedMs;
  }

  get totalSteps(): number {
    return this.stepsTaken;
  }

  reset(): void {
    this.accumulator = 0;
    this.elapsedMs = 0;
    this.stepsTaken = 0;
  }
}

export class Loop {
  private readonly acc = new FixedStepAccumulator();
  private rafId: number | null = null;
  private lastMs = 0;
  private running = false;

  /** Wall-clock ms of the most recent frame. The stats overlay reads this. */
  frameMs = 0;

  constructor(private readonly callbacks: LoopCallbacks) {}

  start(): void {
    if (this.running) return;
    this.running = true;
    this.lastMs = performance.now();
    this.rafId = requestAnimationFrame(this.frame);
  }

  stop(): void {
    this.running = false;
    if (this.rafId !== null) {
      cancelAnimationFrame(this.rafId);
      this.rafId = null;
    }
  }

  get isRunning(): boolean {
    return this.running;
  }

  get simulatedMs(): number {
    return this.acc.simulatedMs;
  }

  private readonly frame = (now: number): void => {
    if (!this.running) return;
    this.rafId = requestAnimationFrame(this.frame);

    this.frameMs = now - this.lastMs;
    this.lastMs = now;

    const steps = this.acc.advance(this.frameMs);
    for (let i = 0; i < steps; i++) {
      this.callbacks.update(FIXED_DT, this.acc.simulatedMs);
    }
    this.callbacks.render(this.acc.alpha);
  };
}
