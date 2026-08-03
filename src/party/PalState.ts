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
   * (docs/01_GAME_DESIGN.md section 5). Stored, because it can never be recomputed.
   */
  variance: number;
  affinity: number;
  currentHp: number;
  fainted: boolean;
  /** In-game day it was caught, for the release screen's "time with you". */
  caughtOnDay: number;
  /** Real ms at capture, for the same reason. */
  caughtAtMs: number;
  /**
   * Team Tether uses collars instead of orbs (docs/01_GAME_DESIGN.md sections 3 and 10).
   *
   * One flag carries three rules: the pal hits harder, it never dodges because
   * its affinity is floored, and an orb thrown at it bounces instead of rolling.
   * Set from `encounters.json`, not from a check on who the trainer is, so a
   * future Warden is a data entry rather than a branch in the combat code.
   *
   * Optional because every pal the player owns is uncollared, and a save
   * written before this existed must still load.
   */
  collared?: boolean;
  /**
   * The opening scene's scripted tuftmoth (docs/01_GAME_DESIGN.md section 3). Set only
   * by `SpawnManager.spawnScripted`, and only while `first_catch` is unset, so
   * the first throw of the game cannot fail. Never true for anything else, and
   * never persisted: a caught pal has no more use for it.
   */
  guaranteedCatch?: boolean;
}

/** One line in the released-pal ledger. Released pals never return. */
export interface ReleaseRecord {
  species: string;
  level: number;
  day: number;
}
