import { bus } from '../core/EventBus';
import type { Input } from '../core/input/Input';
import type { PalState } from '../party/PalState';
import type { Party } from '../party/Party';
import type { ReleaseFlow } from '../party/Release';
import type { SpawnManager } from '../entities/SpawnManager';
import { TIMING } from './MoveResolver';
import type { CombatMode } from './CombatMode';
import { remove, count, type Slots } from '../survival/Inventory';

/**
 * Glue between exploring and fighting.
 *
 * Decides when a fight starts, translates the primary input into quick versus
 * power, spends orbs on throws, and routes a sixth capture into the release
 * flow. Kept out of CombatMode so that file stays about the fight itself.
 */

/** Walking within this many meters of a pal starts a fight (section 7). */
const APPROACH_METERS = 4;
/** Held longer than this, the primary input is a power attack. */
const POWER_HOLD_MS = 420;

/** Orbs in the order the game will spend them: worst first. */
const ORB_PRIORITY = ['worn_orb', 'keen_orb', 'truestone_orb'];

export class Encounter {
  private primaryWasDown = false;

  constructor(
    private readonly combat: CombatMode,
    private readonly spawns: SpawnManager,
    private readonly party: Party,
    private readonly release: ReleaseFlow,
    private readonly slots: Slots,
    private readonly input: Input
  ) {}

  /** One fixed step. */
  update(x: number, z: number, dt: number, day: number): void {
    // The release screen is modal: it pauses the loop below it, because the
    // decision is the point and it must not be resolvable by walking away.
    if (this.release.stage !== 'closed') return;

    if (this.combat.isFighting) {
      this.combat.update(dt, day);
      this.readAttacks(day);
      return;
    }

    // Clear a finished fight BEFORE looking for a new one. Doing it after meant
    // settle() tore down the fight maybeStart() had just begun, in the same
    // tick, and combat could never last longer than one step.
    this.settle(day);
    this.maybeStart(x, z);
  }

  private maybeStart(x: number, z: number): void {
    if (this.party.size === 0 || this.party.allFainted) return;
    const near = this.spawns.nearest(x, z, APPROACH_METERS);
    if (near) this.combat.enter(near);
  }

  /**
   * Quick versus power comes from how long the button was held, which is the
   * same gesture on a mouse, a thumb and a trigger. The decision happens on
   * RELEASE, so the charge is visible before it commits.
   */
  private readAttacks(day: number): void {
    const primary = this.input.intent.primary;
    if (primary.down) {
      this.primaryWasDown = true;
      return;
    }
    if (!this.primaryWasDown) return;
    this.primaryWasDown = false;
    this.combat.attack(primary.heldMs >= POWER_HOLD_MS ? 'power' : 'quick', day);
  }

  /** Throw the cheapest orb the player has. */
  throwOrb(day: number): 'no-orbs' | 'bounced' | 'missed' | 'caught' | 'not-fighting' {
    if (!this.combat.isFighting) return 'not-fighting';
    const orb = ORB_PRIORITY.find((id) => count(this.slots, id) > 0);
    if (!orb) return 'no-orbs';

    // The orb is spent whether or not it holds. A failed throw costing nothing
    // would make throwing strictly better than fighting.
    remove(this.slots, orb, 1);
    const result = this.combat.tryThrow(orb, day, performance.now());
    if (!result.caught) {
      const outcome = result.bounced ? 'bounced' : 'missed';
      bus.emit('orbThrown', { outcome, shakes: result.bounced ? 0 : 1 });
      return outcome;
    }

    bus.emit('orbThrown', { outcome: 'caught', shakes: 3 });
    this.accept(result.pal, day);
    return 'caught';
  }

  /**
   * Put a caught pal in the party, or open the release screen.
   *
   * Everything goes through `Party.add()`, which is the only place the cap
   * exists. This method cannot add a sixth even if it wanted to.
   */
  private accept(pal: PalState, day: number): void {
    const added = this.party.add(pal);
    if (added.ok) return;
    if (added.needsRelease) this.release.open(added.roster, pal);
    void day;
  }

  /**
   * Clear a finished fight and take its target out of the world.
   *
   * Only acts on terminal phases. Anything else is either not a fight or a
   * fight in progress, and tearing either of those down is how a fight ends
   * before it starts.
   */
  private settle(day: number): void {
    const phase = this.combat.phase;
    if (phase === 'idle' || phase === 'fighting') return;

    const target = this.combat.target;
    // A defeated, caught or fled pal leaves the world. A loss does not: the
    // pal that beat you is still standing there.
    if (target && phase !== 'lost') this.spawns.release(target);
    this.combat.reset();
    void day;
  }

  get powerHoldMs(): number {
    return POWER_HOLD_MS;
  }

  get swapVulnerabilityMs(): number {
    return TIMING.swapVulnerabilityMs;
  }
}
