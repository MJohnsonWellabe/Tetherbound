/**
 * Hit pause, the freeze frame on impact. Pure: no engine, no clock, no globals.
 *
 * READ THIS BEFORE CHANGING IT. There are two obvious implementations and both
 * are wrong here:
 *
 * 1. **Scaling delta.** Multiplying dt by zero (or by 0.05 for slow motion)
 *    breaks the first rule in docs/03_TECHNICAL_ARCHITECTURE.md: simulation runs at a fixed 60Hz
 *    and gameplay is never scaled by a variable delta. Every constant in the
 *    game (stamina drain, the 0.6s telegraph, the catch-ring shrink) is tuned
 *    against a fixed step, and a variable one silently retunes all of them.
 *
 * 2. **Skipping requestAnimationFrame.** Not rendering during the freeze is
 *    what a hang looks like. It also strands the accumulator in `Loop.ts`: the
 *    banked time is still owed, so the frame after the pause runs a burst of
 *    catch-up steps and the world teleports forward exactly as the player
 *    starts moving again.
 *
 * What is correct: **withhold simulation steps while rendering continues.** The
 * accumulator still spends the time it banked, so nothing accumulates and the
 * spiral-of-death guard in `Loop.ts` is never engaged. The world simply does
 * not advance during those steps, and the time is discarded rather than
 * replayed. The player sees a held frame with a live camera, which is the
 * effect, and the simulation resumes exactly where it stopped.
 *
 * The cap is not politeness. It is the guard that stops a stream of impacts
 * from each extending the freeze until the game stops simulating altogether.
 */

export interface HitPauseConfig {
  /** Hard ceiling on a single freeze, milliseconds. */
  readonly maxMs: number;
}

export interface HitPauseState {
  /** Simulation time still to be withheld, milliseconds. */
  remainingMs: number;
}

export function createHitPause(): HitPauseState {
  return { remainingMs: 0 };
}

/**
 * Ask for a freeze.
 *
 * Takes the maximum of the request and what is already pending, clamped to the
 * configured ceiling. Adding instead of maxing is the bug that turns a busy
 * moment into a lockup: ten impacts at 70ms each would be 700ms of a game that
 * does not respond.
 */
export function requestPause(state: HitPauseState, ms: number, config: HitPauseConfig): void {
  if (!(ms > 0)) return;
  state.remainingMs = Math.min(config.maxMs, Math.max(state.remainingMs, ms));
}

/**
 * Consume one fixed step. Returns true when this step must be withheld.
 *
 * Callers skip their simulation for the step and return; they do NOT skip
 * rendering, and they do not re-run the step later.
 */
export function consumePause(state: HitPauseState, dt: number): boolean {
  if (state.remainingMs <= 0) return false;
  state.remainingMs -= dt * 1000;
  if (state.remainingMs < 0) state.remainingMs = 0;
  return true;
}

export function isPaused(state: HitPauseState): boolean {
  return state.remainingMs > 0;
}

/** Drop any pending freeze. Used when leaving a mode, so it cannot leak. */
export function clearPause(state: HitPauseState): void {
  state.remainingMs = 0;
}
