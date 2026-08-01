import combat from '../data/combat.json';
import { isFainted, type PalState } from './Pal';

/**
 * The party. The five-slot cap lives HERE and nowhere else.
 *
 * ARCHITECTURE.md rule 2 and CLAUDE.md hard constraint 1 both say the same
 * thing, and they say it because the cap is the entire design. Every capture,
 * every gift, every Warden's recruit offer goes through `add`. There is no
 * second write path into `roster`, which is why it is private and why
 * `members` hands back a copy.
 *
 * `add` never throws on a full party. It returns `needsRelease` and parks the
 * newcomer in `pending`, because the design calls for a screen showing all six
 * with a two-step confirm, and a thrown exception cannot carry a pal.
 */

export interface ReleaseRecord {
  species: string;
  name: string;
  level: number;
  affinity: number;
  /** In-game day the pal was released. */
  day: number;
}

export type AddResult =
  | { status: 'added'; index: number }
  | { status: 'needsRelease' };

export class Party {
  private readonly roster: PalState[] = [];
  private readonly released: ReleaseRecord[] = [];
  /** The sixth pal, waiting on the release screen. */
  private pendingPal: PalState | null = null;

  static get cap(): number {
    return combat.party.cap;
  }

  /**
   * Rebuild from a save. Over-long rosters are truncated rather than trusted:
   * a save file is user-editable and a hand-edited party of nine must not be
   * able to walk past the rule the whole game rests on.
   */
  static fromSaved(members: readonly PalState[], ledger: readonly ReleaseRecord[]): Party {
    const party = new Party();
    for (const pal of members.slice(0, Party.cap)) party.roster.push(pal);
    party.released.push(...ledger);
    return party;
  }

  get size(): number {
    return this.roster.length;
  }

  get isFull(): boolean {
    return this.roster.length >= Party.cap;
  }

  /** A copy. Callers must not be able to push into the real roster. */
  get members(): PalState[] {
    return [...this.roster];
  }

  get ledger(): ReleaseRecord[] {
    return [...this.released];
  }

  get pending(): PalState | null {
    return this.pendingPal;
  }

  /** Highest level held, which the catch formula's levelTerm needs. */
  get highestLevel(): number {
    let max = 0;
    for (const pal of this.roster) if (pal.level > max) max = pal.level;
    return max;
  }

  /**
   * True when no pal can fight. An empty party counts, which is what stops a
   * player walking into a Hall with nothing and being unable to act.
   */
  get allFainted(): boolean {
    if (this.roster.length === 0) return true;
    return this.roster.every(isFainted);
  }

  find(uid: string): PalState | undefined {
    return this.roster.find((p) => p.uid === uid);
  }

  firstConscious(): PalState | undefined {
    return this.roster.find((p) => !isFainted(p));
  }

  /**
   * The only way a pal enters the party.
   *
   * At the cap this adds nothing, parks the newcomer, and tells the caller to
   * open the release screen. The roster length after this call is never
   * greater than the cap, under any input.
   */
  add(pal: PalState): AddResult {
    if (this.roster.length >= Party.cap) {
      this.pendingPal = pal;
      return { status: 'needsRelease' };
    }
    this.roster.push(pal);
    return { status: 'added', index: this.roster.length - 1 };
  }

  /**
   * Settle a sixth capture by releasing one of the six, permanently.
   *
   * `uid` may be the newcomer, which is the player deciding the pal they just
   * caught is worth less than everyone they already have. That has to be
   * allowed or the screen is a lie.
   */
  resolvePending(uid: string, day = 0): ReleaseRecord {
    const incoming = this.pendingPal;
    if (!incoming) throw new Error('No pending pal to resolve');

    if (uid === incoming.uid) {
      this.pendingPal = null;
      return this.record(incoming, day);
    }

    const index = this.roster.findIndex((p) => p.uid === uid);
    if (index < 0) {
      throw new Error(`Cannot release "${uid}": not in the party and not the pending pal`);
    }

    const [removed] = this.roster.splice(index, 1, incoming);
    this.pendingPal = null;
    if (!removed) throw new Error(`Release of "${uid}" removed nothing`);
    return this.record(removed, day);
  }

  /** Abandon a pending capture without releasing anyone. The pal goes free. */
  discardPending(day = 0): ReleaseRecord | null {
    const incoming = this.pendingPal;
    if (!incoming) return null;
    this.pendingPal = null;
    return this.record(incoming, day);
  }

  /**
   * Release from a party that is not full. Still permanent, still ledgered:
   * GAME_DESIGN.md section 5 says released pals never return, and there is no
   * path in this class that puts one back.
   */
  release(uid: string, day = 0): ReleaseRecord {
    const index = this.roster.findIndex((p) => p.uid === uid);
    if (index < 0) throw new Error(`Cannot release "${uid}": not in the party`);
    const [removed] = this.roster.splice(index, 1);
    if (!removed) throw new Error(`Release of "${uid}" removed nothing`);
    return this.record(removed, day);
  }

  /** Move a pal to the front so it leads the next fight. */
  setLead(uid: string): boolean {
    const index = this.roster.findIndex((p) => p.uid === uid);
    if (index <= 0) return index === 0;
    const [pal] = this.roster.splice(index, 1);
    if (!pal) return false;
    this.roster.unshift(pal);
    return true;
  }

  private record(pal: PalState, day: number): ReleaseRecord {
    const entry: ReleaseRecord = {
      species: pal.species,
      name: pal.name,
      level: pal.level,
      affinity: pal.affinity,
      day
    };
    this.released.push(entry);
    return entry;
  }
}
