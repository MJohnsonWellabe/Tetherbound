import { describe, expect, it } from 'vitest';
import {
  createVitals,
  damage,
  eat,
  isStarving,
  maxHealth,
  maxStamina,
  revive,
  spendStamina,
  staminaRegenPerSecond,
  tickVitals,
  VITALS_CONFIG as C
} from '../src/survival/Vitals';

/**
 * Advance in 60Hz steps, the way the real loop does, landing on exactly `ms`.
 *
 * The naive `for (t = 0; t < ms; t += step)` stops a fraction of a step short
 * (450s becomes 449.99s at 16.667ms per step) and every threshold assertion
 * then misses by one. That is a harness artifact, not a system bug, so the
 * harness is what gets fixed.
 */
function run(state: ReturnType<typeof createVitals>, ms: number, sprinting = false): void {
  const step = 1000 / 60;
  let remaining = ms;
  while (remaining > 1e-9) {
    const dt = Math.min(step, remaining);
    tickVitals(state, dt, sprinting);
    remaining -= dt;
  }
}

describe('hunger', () => {
  it('drains one point per 45 seconds', () => {
    const v = createVitals();
    run(v, 45_000);
    expect(v.hunger).toBe(C.maxHunger - 1);
  });

  it('drains ten points in 450 seconds', () => {
    const v = createVitals();
    run(v, 450_000);
    expect(v.hunger).toBe(C.maxHunger - 10);
  });

  it('does not round sub-point steps away to nothing', () => {
    // A 16.7ms step is far smaller than the 45s threshold. Without carrying
    // the remainder, hunger would never move at all.
    const v = createVitals();
    run(v, 90_000);
    expect(v.hunger).toBeLessThan(C.maxHunger);
  });

  it('never goes below zero', () => {
    const v = createVitals();
    run(v, C.maxHunger * C.hungerMsPerPoint * 2);
    expect(v.hunger).toBe(0);
  });
});

describe('starvation', () => {
  it('costs one health per three seconds at zero hunger', () => {
    const v = createVitals();
    v.hunger = 0;
    const before = v.health;
    run(v, 30_000);
    expect(before - v.health).toBeCloseTo(10, 0);
  });

  it('halves stamina regeneration', () => {
    const fed = createVitals();
    const starving = createVitals();
    starving.hunger = 0;
    // Compare at the same hunger scaling by reading the rate directly.
    const ratio = staminaRegenPerSecond(starving) / (C.staminaRegenPerSecond * C.regenHungerFloor);
    expect(ratio).toBeCloseTo(C.starvingRegenMultiplier, 5);
    expect(staminaRegenPerSecond(starving)).toBeLessThan(staminaRegenPerSecond(fed));
  });

  it('faints the player when health reaches zero', () => {
    const v = createVitals();
    v.hunger = 0;
    v.health = 3;
    run(v, 20_000);
    expect(v.fainted).toBe(true);
    expect(v.health).toBe(0);
  });

  it('stops ticking once fainted', () => {
    const v = createVitals();
    v.fainted = true;
    const snapshot = { ...v };
    run(v, 60_000);
    expect(v.hunger).toBe(snapshot.hunger);
    expect(v.playMs).toBe(snapshot.playMs);
  });
});

describe('stamina', () => {
  it('refuses a spend it cannot afford, and spends nothing', () => {
    const v = createVitals();
    v.stamina = 5;
    expect(spendStamina(v, 8)).toBe(false);
    expect(v.stamina).toBe(5);
  });

  it('allows an affordable spend', () => {
    const v = createVitals();
    expect(spendStamina(v, 8)).toBe(true);
    expect(v.stamina).toBe(C.baseMaxStamina - 8);
  });

  it('does not regenerate during the delay after exertion', () => {
    const v = createVitals();
    spendStamina(v, 30);
    const after = v.stamina;
    run(v, C.staminaRegenDelayMs * 0.8);
    expect(v.stamina).toBe(after);
  });

  it('regenerates once the delay has passed', () => {
    const v = createVitals();
    spendStamina(v, 30);
    run(v, C.staminaRegenDelayMs + 1000);
    expect(v.stamina).toBeGreaterThan(C.baseMaxStamina - 30);
  });

  it('restarts the delay on every spend, so tapping cannot dodge it', () => {
    const v = createVitals();
    spendStamina(v, 20);
    run(v, C.staminaRegenDelayMs * 0.9);
    spendStamina(v, 1);
    const after = v.stamina;
    run(v, C.staminaRegenDelayMs * 0.9);
    expect(v.stamina).toBe(after);
  });

  it('regenerates more slowly when hungry', () => {
    const full = createVitals();
    const hungry = createVitals();
    hungry.hunger = 10;
    expect(staminaRegenPerSecond(hungry)).toBeLessThan(staminaRegenPerSecond(full));
  });

  it('still regenerates something at zero hunger', () => {
    // A player who cannot regenerate at all cannot walk home to eat. This is
    // the difference between a hard survival system and a broken one.
    const v = createVitals();
    v.hunger = 0;
    expect(staminaRegenPerSecond(v)).toBeGreaterThan(0);
  });

  it('drains while sprinting', () => {
    const v = createVitals();
    run(v, 3000, true);
    expect(v.stamina).toBeLessThan(C.baseMaxStamina);
  });

  it('never exceeds its maximum', () => {
    const v = createVitals();
    run(v, 60_000);
    expect(v.stamina).toBeLessThanOrEqual(maxStamina(v));
  });
});

describe('food and buffs', () => {
  const stew = {
    hunger: 35,
    buff: { id: 'well_fed', label: 'Well Fed', maxHealth: 30, maxStamina: 20, durationMs: 1_200_000 }
  };
  const meat = {
    hunger: 25,
    buff: { id: 'hearty', label: 'Hearty', maxHealth: 20, durationMs: 600_000 }
  };
  const skewer = {
    hunger: 18,
    buff: { id: 'surefoot', label: 'Surefoot', maxStamina: 15, durationMs: 600_000 }
  };
  const bun = {
    hunger: 20,
    buff: { id: 'second_wind', label: 'Second Wind', staminaRegenPct: 15, durationMs: 720_000 }
  };

  it('restores hunger without exceeding the maximum', () => {
    const v = createVitals();
    v.hunger = 90;
    eat(v, stew);
    expect(v.hunger).toBe(C.maxHunger);
  });

  it('raises the health ceiling', () => {
    const v = createVitals();
    eat(v, stew);
    expect(maxHealth(v)).toBe(C.baseMaxHealth + 30);
    expect(maxStamina(v)).toBe(C.baseMaxStamina + 20);
  });

  it('expires the buff and lowers the ceiling again', () => {
    const v = createVitals();
    eat(v, meat);
    expect(maxHealth(v)).toBe(C.baseMaxHealth + 20);
    run(v, 600_001);
    expect(maxHealth(v)).toBe(C.baseMaxHealth);
  });

  it('clamps health down when a max-health buff expires', () => {
    // Otherwise health briefly reads above its own maximum, which every HUD
    // bar in the game would then draw past 100%.
    const v = createVitals();
    eat(v, meat);
    v.health = maxHealth(v);
    run(v, 600_001);
    expect(v.health).toBeLessThanOrEqual(maxHealth(v));
  });

  it('refreshes rather than stacking the same food', () => {
    // Five stews must not become +150 max health.
    const v = createVitals();
    eat(v, stew);
    eat(v, stew);
    eat(v, stew);
    expect(v.buffs.length).toBe(1);
    expect(maxHealth(v)).toBe(C.baseMaxHealth + 30);
  });

  it('holds three buffs at once', () => {
    const v = createVitals();
    eat(v, meat);
    eat(v, skewer);
    eat(v, bun);
    expect(v.buffs.length).toBe(3);
    expect(maxHealth(v)).toBe(C.baseMaxHealth + 20);
    expect(maxStamina(v)).toBe(C.baseMaxStamina + 15);
  });

  it('displaces the soonest-expiring buff when the slots are full', () => {
    const v = createVitals();
    eat(v, meat); // 10 min
    eat(v, bun); // 12 min
    eat(v, skewer); // 10 min
    run(v, 60_000); // meat and skewer now have less time left than the bun
    eat(v, stew); // 20 min, needs a slot
    expect(v.buffs.length).toBe(C.buffSlots);
    expect(v.buffs.some((b) => b.id === 'well_fed')).toBe(true);
    expect(v.buffs.some((b) => b.id === 'second_wind')).toBe(true);
  });

  it('increases regeneration with a regen buff', () => {
    const plain = createVitals();
    const buffed = createVitals();
    eat(buffed, bun);
    expect(staminaRegenPerSecond(buffed)).toBeGreaterThan(staminaRegenPerSecond(plain));
  });
});

describe('damage and revival', () => {
  it('faints at zero health', () => {
    const v = createVitals();
    damage(v, 999);
    expect(v.health).toBe(0);
    expect(v.fainted).toBe(true);
  });

  it('wakes with partial health and full stamina', () => {
    const v = createVitals();
    damage(v, 999);
    revive(v);
    expect(v.fainted).toBe(false);
    expect(v.health).toBe(Math.round(C.baseMaxHealth * C.faintHealthRestoreFraction));
    expect(v.stamina).toBe(C.baseMaxStamina);
  });

  it('does not restore hunger on revival', () => {
    // The walk back to your satchel is meant to be the cost. Refilling hunger
    // would make fainting a free fast-travel home.
    const v = createVitals();
    v.hunger = 12;
    damage(v, 999);
    revive(v);
    expect(v.hunger).toBe(12);
  });

  it('does not immediately re-faint a starving player on revival', () => {
    const v = createVitals();
    v.hunger = 0;
    damage(v, 999);
    revive(v);
    expect(v.health).toBeGreaterThan(0);
    expect(isStarving(v)).toBe(true);
    run(v, 1000);
    expect(v.fainted).toBe(false);
  });
});
