import config from '../data/vitals.json';

/**
 * Health, stamina and hunger. docs/01_GAME_DESIGN.md section 4, the middle tier.
 *
 * Pure and engine-free so it runs headless under vitest. Every number comes
 * from src/data/vitals.json; there are no tuning literals in this file.
 *
 * The one piece of design worth restating, because it is easy to "fix" into
 * something worse: stamina regeneration SCALES with hunger rather than
 * switching off at zero. A starving player regenerates slowly, not never. A
 * player who cannot regenerate at all cannot walk home to eat, and a survival
 * system that can strand you is a bug wearing a difficulty costume.
 */

/**
 * Slack on threshold comparisons, in ms.
 *
 * Accumulating 1/60s steps toward a 45,000ms threshold lands a hair under it
 * (44999.9999...) because 16.666... is not representable in binary floating
 * point. Without this, hunger ticks one step late every time, and a test
 * asserting the specified "1 point per 45 seconds" fails at the exact
 * boundary. The drift is self-correcting and harmless in play, but the
 * specified number should be the number that happens.
 */
const EPSILON_MS = 1e-6;

export interface ActiveBuff {
  id: string;
  label: string;
  /** Elapsed play time at which this expires. Never a wall clock. */
  endsAtMs: number;
  maxHealth?: number;
  maxStamina?: number;
  staminaRegenPct?: number;
}

export interface FoodEffect {
  hunger: number;
  buff?: {
    id: string;
    label: string;
    durationMs: number;
    maxHealth?: number;
    maxStamina?: number;
    staminaRegenPct?: number;
  };
}

export interface VitalsState {
  health: number;
  stamina: number;
  hunger: number;
  buffs: ActiveBuff[];
  /** Elapsed play time, ms. The clock every duration here is measured against. */
  playMs: number;
  /** Play time of the last stamina expenditure, for the regen delay. */
  lastExertionMs: number;
  /** Sub-point carry, so a 16ms step does not round to nothing. */
  hungerCarryMs: number;
  starveCarryMs: number;
  fainted: boolean;
}

export function createVitals(): VitalsState {
  return {
    health: config.baseMaxHealth,
    stamina: config.baseMaxStamina,
    hunger: config.maxHunger,
    buffs: [],
    playMs: 0,
    lastExertionMs: -config.staminaRegenDelayMs,
    hungerCarryMs: 0,
    starveCarryMs: 0,
    fainted: false
  };
}

/** Effective maximum health, base plus every active buff. */
export function maxHealth(state: VitalsState): number {
  let max = config.baseMaxHealth;
  for (const b of state.buffs) max += b.maxHealth ?? 0;
  return max;
}

export function maxStamina(state: VitalsState): number {
  let max = config.baseMaxStamina;
  for (const b of state.buffs) max += b.maxStamina ?? 0;
  return max;
}

export function isStarving(state: VitalsState): boolean {
  return state.hunger <= 0;
}

/** Stamina recovered per second right now, after hunger and starvation. */
export function staminaRegenPerSecond(state: VitalsState): number {
  let pct = 0;
  for (const b of state.buffs) pct += b.staminaRegenPct ?? 0;

  const hungerFraction = Math.max(0, Math.min(1, state.hunger / config.maxHunger));
  const hungerScale =
    config.regenHungerFloor + (1 - config.regenHungerFloor) * hungerFraction;

  let rate = config.staminaRegenPerSecond * hungerScale * (1 + pct / 100);
  if (isStarving(state)) rate *= config.starvingRegenMultiplier;
  return rate;
}

/**
 * Spend stamina. Returns false and spends nothing when there is not enough,
 * so callers can refuse the action rather than let it happen for free.
 *
 * Any successful spend restarts the regen delay, which is what stops a player
 * from sprint-tapping to dodge the cooldown.
 */
export function spendStamina(state: VitalsState, amount: number): boolean {
  if (amount <= 0) return true;
  if (state.stamina < amount) return false;
  state.stamina -= amount;
  state.lastExertionMs = state.playMs;
  return true;
}

/** Drain without the affordability check, for continuous costs like sprinting. */
export function drainStamina(state: VitalsState, amount: number): void {
  if (amount <= 0) return;
  state.stamina = Math.max(0, state.stamina - amount);
  state.lastExertionMs = state.playMs;
}

export function damage(state: VitalsState, amount: number): void {
  if (amount <= 0) return;
  state.health = Math.max(0, state.health - amount);
  if (state.health <= 0) state.fainted = true;
}

export function heal(state: VitalsState, amount: number): void {
  state.health = Math.min(maxHealth(state), state.health + amount);
}

/**
 * Eat. Restores hunger and applies the food's buff if it has one.
 *
 * Re-eating the same food refreshes its timer rather than stacking a second
 * copy, so a player cannot hoard five Meadow Stews into +150 max health. When
 * all buff slots are full and the food brings a new one, the buff expiring
 * soonest is displaced.
 */
export function eat(state: VitalsState, food: FoodEffect): void {
  state.hunger = Math.min(config.maxHunger, state.hunger + food.hunger);

  const buff = food.buff;
  if (!buff) return;

  const next: ActiveBuff = {
    id: buff.id,
    label: buff.label,
    endsAtMs: state.playMs + buff.durationMs,
    ...(buff.maxHealth === undefined ? {} : { maxHealth: buff.maxHealth }),
    ...(buff.maxStamina === undefined ? {} : { maxStamina: buff.maxStamina }),
    ...(buff.staminaRegenPct === undefined ? {} : { staminaRegenPct: buff.staminaRegenPct })
  };

  const existing = state.buffs.findIndex((b) => b.id === buff.id);
  if (existing >= 0) {
    state.buffs[existing] = next;
    return;
  }

  if (state.buffs.length >= config.buffSlots) {
    let soonest = 0;
    for (let i = 1; i < state.buffs.length; i++) {
      if ((state.buffs[i]?.endsAtMs ?? 0) < (state.buffs[soonest]?.endsAtMs ?? 0)) soonest = i;
    }
    state.buffs[soonest] = next;
    return;
  }
  state.buffs.push(next);
}

/**
 * Advance one fixed simulation step.
 *
 * `sprinting` is passed in rather than read from anywhere, so this stays pure
 * and the caller owns the question of what counts as exertion.
 */
export function tickVitals(state: VitalsState, dtMs: number, sprinting = false): void {
  if (state.fainted) return;

  state.playMs += dtMs;

  // Buffs first: an expiring +max-health buff must lower the ceiling before
  // anything clamps against it, or health briefly reads above its maximum.
  if (state.buffs.length > 0) {
    state.buffs = state.buffs.filter((b) => b.endsAtMs > state.playMs);
  }

  if (sprinting) {
    drainStamina(state, (config.sprintStaminaPerSecond * dtMs) / 1000);
  }

  // Hunger. Carried in ms so a 16.7ms step is not rounded away to nothing.
  state.hungerCarryMs += dtMs;
  while (state.hungerCarryMs >= config.hungerMsPerPoint - EPSILON_MS && state.hunger > 0) {
    state.hungerCarryMs -= config.hungerMsPerPoint;
    state.hunger = Math.max(0, state.hunger - 1);
  }
  if (state.hunger <= 0) state.hungerCarryMs = 0;

  if (isStarving(state)) {
    state.starveCarryMs += dtMs;
    while (state.starveCarryMs >= config.starveMsPerDamage - EPSILON_MS) {
      state.starveCarryMs -= config.starveMsPerDamage;
      damage(state, config.starveDamage);
      if (state.fainted) return;
    }
  } else {
    state.starveCarryMs = 0;
  }

  if (state.playMs - state.lastExertionMs >= config.staminaRegenDelayMs - EPSILON_MS) {
    const max = maxStamina(state);
    state.stamina = Math.min(max, state.stamina + (staminaRegenPerSecond(state) * dtMs) / 1000);
  }

  // Clamp last, after buff expiry may have lowered the ceilings.
  state.health = Math.min(state.health, maxHealth(state));
  state.stamina = Math.min(state.stamina, maxStamina(state));
}

/**
 * Wake at the bed. docs/01_GAME_DESIGN.md section 4: inventory drops to a satchel at
 * the faint location (the caller handles that), pals are never dropped, and
 * hunger is deliberately NOT restored, because the walk back to your satchel
 * is meant to be the cost.
 */
export function revive(state: VitalsState): void {
  state.fainted = false;
  state.health = Math.max(1, Math.round(maxHealth(state) * config.faintHealthRestoreFraction));
  state.stamina = maxStamina(state);
  state.starveCarryMs = 0;
}

export const VITALS_CONFIG = config;
