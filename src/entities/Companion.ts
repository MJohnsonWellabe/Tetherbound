import companion from '../data/companion.json';
import { stepFollow, type FollowConfig, type FollowState } from '../anim/Follow';
import type { Party } from '../party/Party';
import type { PalBody, PalVisuals } from './PalVisual';

/**
 * The active party pal, out of its orb and at the player's heel.
 *
 * The single loudest "this is a creature-collector" signal on screen: your
 * starter visibly walks with you. The body comes from the same PalVisuals pool
 * path wild pals use, the steering from the pure math in Follow.ts, and the
 * animation verb from how fast that math moved it this step.
 *
 * Hidden during combat (the stage presents the pal itself) and conversations.
 * Swaps automatically when the active slot changes, and despawns when the
 * party is empty.
 */

const FOLLOW = companion.follow as FollowConfig;

export class Companion {
  private body: PalBody | null = null;
  private uid: string | null = null;
  private readonly state: FollowState = { x: 0, z: 0 };
  private shown = true;

  constructor(
    private readonly visuals: PalVisuals,
    private readonly heightAt: (x: number, z: number) => number
  ) {}

  /** One fixed step. `hidden` while combat or dialogue owns the screen. */
  update(
    party: Party,
    playerX: number,
    playerZ: number,
    playerYaw: number,
    dt: number,
    hidden: boolean
  ): void {
    const active = party.active;
    if (!active) {
      this.clear();
      return;
    }

    if (active.uid !== this.uid) {
      this.clear();
      this.body = this.visuals.acquire(active.species);
      this.uid = active.uid;
      // Materialise beside the player, not at the world origin.
      this.state.x = playerX;
      this.state.z = playerZ;
    }
    if (!this.body) return;

    if (hidden === this.shown) {
      this.shown = !hidden;
      this.body.root.setEnabled(this.shown);
    }
    if (!this.shown) return;

    const before = { x: this.state.x, z: this.state.z };
    const out = stepFollow(this.state, playerX, playerZ, playerYaw, dt, FOLLOW);

    this.body.root.position.set(out.x, this.heightAt(out.x, out.z), out.z);
    if (out.speed > 0) {
      this.body.root.rotation.y = Math.atan2(out.x - before.x, out.z - before.z);
    } else {
      // Standing still, look where the player looks; heel position is behind
      // the player, so matching yaw reads as walking together, not staring.
      this.body.root.rotation.y = playerYaw;
    }

    const verb =
      out.speed > companion.verbs.runAbove
        ? 'run'
        : out.speed > companion.verbs.walkAbove
          ? 'walk'
          : 'idle';
    this.body.driver.play(verb, performance.now());
  }

  private clear(): void {
    this.body?.dispose();
    this.body = null;
    this.uid = null;
    this.shown = true;
  }

  dispose(): void {
    this.clear();
  }
}
