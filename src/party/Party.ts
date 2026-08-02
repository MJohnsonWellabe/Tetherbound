import type { PalState, ReleaseRecord } from './PalState';

/**
 * The party, and the five-slot cap.
 *
 * CLAUDE.md hard constraint 1 and ARCHITECTURE.md rule 2: the cap is enforced
 * in `add()` and nowhere else, and there is no code path that produces a party
 * of six. `members` is exposed read-only for exactly that reason. Anything that
 * wants a pal in the party goes through `add()`, including the Loamking's offer
 * after the Hall and any future gift or trade.
 *
 * `add()` does not throw when full. It returns a `needsRelease` signal carrying
 * all six candidates, because the sixth capture is a decision the player makes
 * (GAME_DESIGN.md section 5) and they are allowed to release the newcomer. A
 * throw would force every caller to handle the game's central mechanic as an
 * error case.
 */

export const MAX_PARTY = 5;

export type AddResult =
  | { ok: true; pal: PalState }
  | { ok: false; needsRelease: true; roster: PalState[] }
  | { ok: false; needsRelease: false; reason: 'duplicate' };

export class Party {
  private readonly pals: PalState[] = [];
  private readonly released: ReleaseRecord[] = [];
  private activeIndex = 0;

  /**
   * Rebuild from a save.
   *
   * Clamps to the cap rather than trusting the file. A save is user-editable
   * and a corrupted or hand-edited one must not be able to smuggle in a sixth
   * pal; ARCHITECTURE.md requires the clamp on load and this is where it lands.
   */
  static fromSave(members: PalState[], ledger: ReleaseRecord[]): Party {
    const party = new Party();
    party.restore(members, ledger);
    return party;
  }

  /**
   * Refill an existing party from a save, in place.
   *
   * The boot sequence builds the party before it knows whether there is a save,
   * because everything downstream holds a reference to it. Handing out a NEW
   * Party from `fromSave` at that point would leave combat, the HUD and the
   * release flow all pointing at the empty one, which is how a loaded save
   * shows up as an empty party in the HUD while the fight still works.
   *
   * Same clamp as `fromSave`, for the same reason: a save is user-editable and
   * must not be able to smuggle in a sixth pal.
   */
  restore(members: PalState[], ledger: ReleaseRecord[]): void {
    this.pals.length = 0;
    this.released.length = 0;
    for (const pal of members.slice(0, MAX_PARTY)) this.pals.push(pal);
    this.released.push(...ledger);
    this.activeIndex = 0;
  }

  get members(): readonly PalState[] {
    return this.pals;
  }

  get size(): number {
    return this.pals.length;
  }

  get isFull(): boolean {
    return this.pals.length >= MAX_PARTY;
  }

  get ledger(): readonly ReleaseRecord[] {
    return this.released;
  }

  /** The only way a pal enters the party. */
  add(pal: PalState): AddResult {
    if (this.pals.some((p) => p.uid === pal.uid)) {
      return { ok: false, needsRelease: false, reason: 'duplicate' };
    }
    if (this.isFull) {
      // All six, newcomer included. The player may decide the newcomer is the
      // one that goes.
      return { ok: false, needsRelease: true, roster: [...this.pals, pal] };
    }
    this.pals.push(pal);
    return { ok: true, pal };
  }

  /**
   * Release a pal into the world, permanently.
   *
   * Recorded in the ledger, which is what makes the sixth-slot decision cost
   * something the player can still see twenty hours later.
   */
  release(uid: string, day: number): boolean {
    const index = this.pals.findIndex((p) => p.uid === uid);
    if (index < 0) return false;
    const [gone] = this.pals.splice(index, 1);
    if (!gone) return false;
    this.released.push({ species: gone.species, level: gone.level, day });
    if (this.activeIndex >= this.pals.length) this.activeIndex = 0;
    return true;
  }

  /**
   * Record a pal that was turned away at the sixth slot.
   *
   * It never joined, so there is nothing to remove, but the player still made
   * the choice and the ledger is the memorial. Kept here rather than in
   * ReleaseFlow so every write to `released` goes through the party.
   */
  releaseUnjoined(pal: PalState, day: number): void {
    this.released.push({ species: pal.species, level: pal.level, day });
  }

  get active(): PalState | null {
    return this.pals[this.activeIndex] ?? null;
  }

  get activeSlot(): number {
    return this.activeIndex;
  }

  /** Swap the active pal. A fainted pal cannot take the field. */
  setActive(slot: number): boolean {
    const pal = this.pals[slot];
    if (!pal || pal.fainted) return false;
    this.activeIndex = slot;
    return true;
  }

  /** All five down means retreat; the player cannot start a Hall fight. */
  get allFainted(): boolean {
    return this.pals.length > 0 && this.pals.every((p) => p.fainted);
  }

  /** Highest level held. Feeds the catch formula's level term. */
  get highestLevel(): number {
    return this.pals.reduce((max, p) => Math.max(max, p.level), 0);
  }

  find(uid: string): PalState | undefined {
    return this.pals.find((p) => p.uid === uid);
  }
}
