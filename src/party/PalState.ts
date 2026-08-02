/**
 * A single pal's persisted state.
 *
 * Separated from Party.ts so the save schema and the cap logic can be imported
 * independently, and so nothing needs to reach through Party to describe a pal.
 *
 * Derived values are NOT here. HP maximum, attack, defence and speed all come
 * from `species.json` plus level plus `variance` through `Damage.statAt`, so a
 * balance change is a data edit and never a save migration. `currentHp` is
 * stored because it is state; `maxHp` is computed because it is not.
 */

export interface PalState {
  /** Stable identity for this individual, distinct from its species. */
  uid: string;
  species: string;
  nickname: string | null;
  level: number;
  xp: number;
  /**
   * The +/-10% roll applied at spawn and locked for life
   * (GAME_DESIGN.md section 5). Stored, because it can never be recomputed.
   */
  variance: number;
  affinity: number;
  currentHp: number;
  fainted: boolean;
  /** In-game day it was caught, for the release screen's "time with you". */
  caughtOnDay: number;
  /** Real ms at capture, for the same reason. */
  caughtAtMs: number;
}

/** One line in the released-pal ledger. Released pals never return. */
export interface ReleaseRecord {
  species: string;
  level: number;
  day: number;
}
