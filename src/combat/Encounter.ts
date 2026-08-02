import { bus } from '../core/EventBus';
import type { Input } from '../core/input/Input';
import type { PalState } from '../party/PalState';
import type { Party } from '../party/Party';
import type { ReleaseFlow } from '../party/Release';
import type { SpawnManager } from '../entities/SpawnManager';
import moves from '../data/moves.json';
import { TIMING } from './MoveResolver';
import type { CombatMode } from './CombatMode';
import { remove, count, type Slots } from '../survival/Inventory';
import type { HUD } from '../ui/HUD';

/**
 * Glue between exploring and fighting.
 *
 * Decides when a fight starts and ends, reads the four combat buttons, spends
 * orbs on throws, and routes a sixth capture into the release flow. Kept out
 * of CombatMode so that file stays about the fight itself.
 */

/** Walking within this many meters of a pal starts a fight (section 7). */
const APPROACH_METERS = moves.approachMeters;
/**
 * Past this many meters from the target, a running fight ends on its own.
 * Nothing used to check distance once a fight had started, so walking away
 * left the combat HUD up forever.
 */
const LEASH_METERS = moves.leashMeters;

/** Orbs in the order the game will spend them: worst first. */
const ORB_PRIORITY = ['worn_orb', 'keen_orb', 'truestone_orb'];

export class Encounter {
  /** Fires once per session, the first time an empty party stands next to a
   *  wild pal, so the fight-is-unreachable state never reads as a bug. */
  private toldToSeeOrin = false;

  constructor(
    private readonly combat: CombatMode,
    private readonly spawns: SpawnManager,
    private readonly party: Party,
    private readonly release: ReleaseFlow,
    private readonly slots: Slots,
    private readonly input: Input,
    private readonly hud: HUD
  ) {}

  /**
   * One fixed step. `busyTalking` comes from Story: a conversation owns the
   * interact button outright, and now it also owns whether a NEW fight is
   * allowed to start, so a wild pal wandering into range mid-conversation
   * cannot interrupt it. A fight already running keeps ticking either way,
   * because the gate is on starting one, not on finishing one.
   */
  update(x: number, z: number, dt: number, day: number, busyTalking = false): void {
    // The release screen is modal: it pauses the loop below it, because the
    // decision is the point and it must not be resolvable by walking away.
    if (this.release.stage !== 'closed') return;

    if (this.combat.isFighting) {
      this.combat.update(dt, day);
      this.readAttacks(day);
      this.checkLeash(x, z);
      return;
    }

    // Clear a finished fight BEFORE looking for a new one. Doing it after meant
    // settle() tore down the fight maybeStart() had just begun, in the same
    // tick, and combat could never last longer than one step.
    this.settle();
    if (busyTalking) return;
    this.maybeStart(x, z);
  }

  private maybeStart(x: number, z: number): void {
    if (this.party.size === 0) {
      // Before the starter is granted, a fight is silently unreachable. Say
      // why, once, rather than let a new player think walking into a pal is
      // supposed to do nothing.
      if (!this.toldToSeeOrin && this.spawns.nearest(x, z, APPROACH_METERS)) {
        this.hud.toast('Talk to Grandpa Orin first.', 'plain');
        this.toldToSeeOrin = true;
      }
      return;
    }
    if (this.party.allFainted) return;
    const near = this.spawns.nearest(x, z, APPROACH_METERS);
    if (near) this.combat.enter(near);
  }

  /** Ends a running fight once the player has walked far enough from it. */
  private checkLeash(x: number, z: number): void {
    const target = this.combat.target;
    if (!target) return;
    if (Math.hypot(target.x - x, target.z - z) <= LEASH_METERS) return;
    if (this.combat.leave()) this.hud.toast('Too far to keep fighting.', 'plain');
  }

  /**
   * Retreat on request (the Run button). Always instant outside a scripted
   * duel; see CombatMode.leave() for the collared refusal.
   */
  flee(): 'left' | 'refused' | 'not-fighting' {
    if (!this.combat.isFighting) return 'not-fighting';
    if (this.combat.leave()) {
      this.hud.toast('You pulled back.', 'plain');
      return 'left';
    }
    this.hud.toast('Cannot retreat from this fight.', 'bad');
    return 'refused';
  }

  /**
   * Quick and power are each their own button now (A and B, or the on-screen
   * Quick/Power buttons), committed the instant they are pressed. Nothing
   * left here to time: CombatMode.attack() decides whether a power attack
   * actually lands. Both can legally edge-trigger the same tick (a click and
   * a key landing together), so both are read rather than picking one.
   */
  private readAttacks(day: number): void {
    const intent = this.input.intent;
    if (intent.quickAttack) this.combat.attack('quick', day);
    if (intent.powerAttack) this.combat.attack('power', day);
  }

  /** Throw the cheapest orb the player has. */
  throwOrb(day: number): 'no-orbs' | 'bounced' | 'missed' | 'caught' | 'not-fighting' {
    if (!this.combat.isFighting) return 'not-fighting';
    const orb = ORB_PRIORITY.find((id) => count(this.slots, id) > 0);
    if (!orb) {
      // The button has to say something happened, not nothing: the throw
      // being always LEGAL (CLAUDE.md hard constraint 3) is a different
      // promise than there being an orb to spend.
      bus.emit('orbThrown', { outcome: 'no-orbs', shakes: 0 });
      return 'no-orbs';
    }

    // The orb is spent whether or not it holds. A failed throw costing nothing
    // would make throwing strictly better than fighting.
    remove(this.slots, orb, 1);
    // The enemy holds from here until the orb lands. CombatStage releases it
    // when the arc finishes, so a throw is never punished mid-flight.
    this.combat.setAiming(true);
    const result = this.combat.tryThrow(orb, day, performance.now());
    if (!result.caught) {
      const outcome = result.bounced ? 'bounced' : 'missed';
      bus.emit('orbThrown', { outcome, shakes: result.bounced ? 0 : 1 });
      return outcome;
    }

    bus.emit('orbThrown', { outcome: 'caught', shakes: 3 });
    bus.emit('palCaught', { species: result.pal.species });
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
  private settle(): void {
    const phase = this.combat.phase;
    if (phase === 'idle' || phase === 'fighting') return;

    const target = this.combat.target;
    // A defeated, caught or (wild-)fled pal leaves the world. A loss does
    // not, and neither does the player's own retreat ('left'): the enemy
    // that beat you, or the one you walked away from, is still standing
    // there.
    if (target && phase !== 'lost' && phase !== 'left') this.spawns.release(target);
    this.combat.reset();
  }

  get swapVulnerabilityMs(): number {
    return TIMING.swapVulnerabilityMs;
  }

  get leashMeters(): number {
    return LEASH_METERS;
  }
}
