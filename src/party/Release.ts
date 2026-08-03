import { bus } from '../core/EventBus';
import type { PalState } from './PalState';
import type { Party } from './Party';
import { speciesDef } from '../entities/Species';

/**
 * The sixth-capture decision.
 *
 * docs/01_GAME_DESIGN.md section 11: "Release confirmation is deliberately heavy. It
 * shows the pal's level, affinity, time with you, and a two-step confirm. This
 * screen should feel bad."
 *
 * So it is a two-step commit rather than a single click, and the newcomer is
 * one of the six candidates: the player may decide the pal they just caught is
 * the one that goes. Nothing here can be skipped by holding a button, because
 * the whole game is built on this choice costing something.
 */

export interface ReleaseCandidate {
  pal: PalState;
  speciesName: string;
  level: number;
  affinity: number;
  /** Whole in-game days held. 0 for a pal caught moments ago. */
  daysHeld: number;
  /** True for the pal that has not joined yet. */
  isNewcomer: boolean;
}

export type ReleaseStage = 'closed' | 'choosing' | 'confirming';

export class ReleaseFlow {
  stage: ReleaseStage = 'closed';
  private roster: PalState[] = [];
  private newcomer: PalState | null = null;
  private selected: string | null = null;

  constructor(private readonly party: Party) {}

  /** Open on a sixth capture. `roster` is all six, newcomer included. */
  open(roster: PalState[], newcomer: PalState): void {
    this.roster = roster;
    this.newcomer = newcomer;
    this.selected = null;
    this.stage = 'choosing';
    bus.emit('releaseNeeded', {});
  }

  candidates(day: number): ReleaseCandidate[] {
    return this.roster.map((pal) => ({
      pal,
      speciesName: speciesDef(pal.species)?.name ?? pal.species,
      level: pal.level,
      affinity: pal.affinity,
      daysHeld: Math.max(0, day - pal.caughtOnDay),
      isNewcomer: pal.uid === this.newcomer?.uid
    }));
  }

  /** Step one: pick who goes. Does not release anything yet. */
  select(uid: string): boolean {
    if (this.stage !== 'choosing') return false;
    if (!this.roster.some((p) => p.uid === uid)) return false;
    this.selected = uid;
    this.stage = 'confirming';
    return true;
  }

  get selectedUid(): string | null {
    return this.selected;
  }

  /** Back out of the confirm. Always available; this is not a trap. */
  cancel(): void {
    if (this.stage === 'confirming') {
      this.selected = null;
      this.stage = 'choosing';
    }
  }

  /**
   * Step two: commit.
   *
   * Releasing the newcomer means it simply never joins, and the party is
   * untouched. Releasing a held pal frees a slot, and the newcomer takes it
   * through `Party.add()` like everything else, because that is the only path
   * into the party.
   */
  confirm(day: number): boolean {
    if (this.stage !== 'confirming' || !this.selected || !this.newcomer) return false;

    if (this.selected === this.newcomer.uid) {
      // Never joined, so there is nothing to remove. It is still recorded:
      // the player made the choice and the ledger should remember it.
      this.party.releaseUnjoined(this.newcomer, day);
      this.close();
      return true;
    }

    if (!this.party.release(this.selected, day)) return false;
    this.party.add(this.newcomer);
    this.close();
    return true;
  }

  private close(): void {
    this.stage = 'closed';
    this.roster = [];
    this.newcomer = null;
    this.selected = null;
    bus.emit('partyChanged', {});
  }
}
