import type { AnimationGroup } from '../core/babylon';
import type { MountedRig } from './Rigs';

/**
 * Plays one entity's animations by game verb, with crossfades.
 *
 * Consumers never touch AnimationGroups: they say `driver.play('run')` and the
 * driver resolves the verb through the model's clips map, fades the old group
 * out and the new one in, and keeps one-shot verbs (attack, hit, faint) from
 * being stomped by the locomotion verb that follows every frame.
 *
 * A driver without a rig (model still downloading, or download failed) accepts
 * every call and does nothing. That is the whole fallback story: callers never
 * check.
 */

const FADE_MS = 180;
/** Verbs that play once and hold or finish; locomotion may not interrupt. */
const ONE_SHOT = new Set(['attack', 'hit', 'faint', 'interact', 'dodge', 'wave']);

export class AnimDriver {
  private rig: MountedRig | null = null;
  private current: AnimationGroup | null = null;
  private currentVerb = '';
  /** While set, locomotion verbs are ignored. Cleared when the shot ends. */
  private oneShotUntilMs = 0;
  /** Faint is terminal: nothing plays over it until revive(). */
  private fainted = false;

  attach(rig: MountedRig): void {
    this.rig = rig;
    this.current = null;
    this.currentVerb = '';
    this.fainted = false;
  }

  get hasRig(): boolean {
    return this.rig !== null;
  }

  /**
   * Play a verb. Locomotion verbs (idle/walk/run) repeat-call safely: the
   * same verb twice is a no-op, and a one-shot in flight wins until done.
   */
  play(verb: string, nowMs: number, speedRatio = 1): void {
    if (!this.rig) return;
    if (this.fainted) return;
    const oneShot = ONE_SHOT.has(verb);
    if (!oneShot && nowMs < this.oneShotUntilMs) return;
    if (!oneShot && verb === this.currentVerb) return;

    const group = this.rig.verb(verb);
    if (!group) return;

    if (verb === 'faint') this.fainted = true;

    const previous = this.current;
    this.current = group;
    this.currentVerb = verb;

    group.stop();
    group.start(!oneShot, speedRatio);
    if (oneShot) {
      const durationMs = (group.getLength() / Math.max(0.0001, speedRatio)) * 1000;
      this.oneShotUntilMs = nowMs + durationMs;
      if (verb === 'faint') {
        // Hold the last frame instead of snapping back to bind pose.
        group.onAnimationGroupEndObservable.addOnce(() => {
          group.start(false, 0.001, group.to, group.to);
        });
      }
    } else {
      this.oneShotUntilMs = 0;
    }

    // A short manual crossfade: start the new group at 0 weight and ramp.
    // AnimationGroup has built-in weight support; the ramp runs on the
    // group's own observable to stay off the game loop.
    if (previous && previous !== group) {
      fade(previous, group);
    } else {
      group.setWeightForAllAnimatables(1);
    }
  }

  /** After a faint, allow animation again (revive at campfire). */
  revive(): void {
    this.fainted = false;
    this.currentVerb = '';
    this.oneShotUntilMs = 0;
  }

  dispose(): void {
    this.rig = null;
    this.current = null;
  }
}

function fade(from: AnimationGroup, to: AnimationGroup): void {
  const started = performance.now();
  to.setWeightForAllAnimatables(0);
  const step = (): void => {
    const t = Math.min(1, (performance.now() - started) / FADE_MS);
    to.setWeightForAllAnimatables(t);
    from.setWeightForAllAnimatables(1 - t);
    if (t < 1) requestAnimationFrame(step);
    else from.stop();
  };
  requestAnimationFrame(step);
}
