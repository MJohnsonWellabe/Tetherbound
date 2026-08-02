import { describe, expect, it } from 'vitest';
import { CombatMode } from '../src/combat/CombatMode';
import { TIMING } from '../src/combat/MoveResolver';
import { Party } from '../src/party/Party';
import { createPal, derive } from '../src/entities/Species';
import { mulberry32 } from '../src/world/gen/Rng';
import type { WildPal } from '../src/entities/SpawnManager';
import moves from '../src/data/moves.json';
import species from '../src/data/species.json';
import orbs from '../src/data/orbs.json';

/**
 * The combat clock, retuned so a first fight is legible (D55).
 *
 * These assert the PACING contract rather than any single number: that the
 * opening is quiet, that nothing out-paces the cadence floor, and that aiming
 * a throw is never punished. The numbers themselves live in moves.json and are
 * expected to move.
 */

const STEP = 1 / 60;

function wild(speciesId: string, level: number): WildPal {
  const rng = mulberry32(1);
  return {
    state: createPal(speciesId, level, 1, 0, rng, `w_${speciesId}`),
    ai: { mood: 'aggro', timer: 0, heading: 0, homeX: 0, homeZ: 0 },
    body: null,
    x: 0,
    y: 0,
    z: 0,
    yaw: 0,
    active: true,
    held: false,
    docile: false
  };
}

/** A party with one over-levelled pal, so nothing ends by the ally fainting. */
function party(): Party {
  const p = new Party();
  const rng = mulberry32(2);
  const pal = createPal('bramblit', 30, 1, 0, rng, 'ally');
  pal.currentHp = 99_999;
  p.add(pal);
  return p;
}

/** Input stub: never presses anything. */
function idleInput(): { intent: { dodge: number; slot: null }; setMode: () => void } {
  return { intent: { dodge: 0, slot: null }, setMode: () => {} };
}

/** Run `ms` of combat and report how much HP the ally lost. */
function runFor(combat: CombatMode, p: Party, ms: number): number {
  const before = p.active?.currentHp ?? 0;
  const rand = mulberry32(7);
  for (let t = 0; t < ms; t += STEP * 1000) combat.update(STEP, 1, rand);
  return before - (p.active?.currentHp ?? 0);
}

describe('the opening grace', () => {
  it('lets nothing touch the player before it expires', () => {
    const p = party();
    const combat = new CombatMode(p, idleInput() as never);
    combat.enter(wild('tuftmoth', 4));
    // Stop just short of the grace so a cadence roll cannot sneak in.
    expect(runFor(combat, p, TIMING.openingGraceMs - 100)).toBe(0);
  });

  it('is long enough to be usable rather than theoretical', () => {
    expect(TIMING.openingGraceMs).toBeGreaterThanOrEqual(2000);
  });

  it('does not gate the throw, which is always legal', () => {
    const p = party();
    const combat = new CombatMode(p, idleInput() as never);
    combat.enter(wild('tuftmoth', 4));
    // The opening tick, before anything has happened at all.
    const result = combat.tryThrow('worn_orb', 1, 0, mulberry32(3));
    expect(result).toBeDefined();
    expect('caught' in result).toBe(true);
  });
});

describe('attack cadence', () => {
  it('gives every species a cadence at or above the floor', () => {
    const sec = (species as Record<string, unknown>).species ?? species;
    for (const [id, def] of Object.entries(sec as Record<string, { attackCadenceMs?: number }>)) {
      if (!def || typeof def !== 'object' || !('attackCadenceMs' in def)) continue;
      expect(def.attackCadenceMs, `${id} cadence`).toBeGreaterThanOrEqual(
        moves.minAttackIntervalMs
      );
    }
  });

  it('lands at most a couple of hits in ten seconds of Meadows combat', () => {
    const p = party();
    const combat = new CombatMode(p, idleInput() as never);
    const enemy = wild('tuftmoth', 4);
    combat.enter(enemy);
    const hp = derive(enemy.state).maxHp;
    expect(hp).toBeGreaterThan(0);
    // 10s minus the grace leaves room for roughly two attacks at a 4s floor.
    const damage = runFor(combat, p, 10_000);
    const perHit = derive(enemy.state).atk;
    expect(damage).toBeLessThan(perHit * 4);
  });
});

describe('aiming a throw', () => {
  it('holds the enemy while the orb is in the air', () => {
    const p = party();
    const combat = new CombatMode(p, idleInput() as never);
    combat.enter(wild('tuftmoth', 4));
    // Burn the grace first so the enemy is otherwise free to act.
    runFor(combat, p, TIMING.openingGraceMs + 200);
    combat.setAiming(true);
    expect(runFor(combat, p, 8000)).toBe(0);
  });

  it('releases the enemy once the throw resolves', () => {
    const p = party();
    const combat = new CombatMode(p, idleInput() as never);
    combat.enter(wild('grazehorn', 9));
    runFor(combat, p, TIMING.openingGraceMs + 200);
    combat.setAiming(true);
    runFor(combat, p, 3000);
    combat.setAiming(false);
    // With the hold lifted the enemy resumes; over a long window it must land
    // something, or "hold" would be indistinguishable from "disabled".
    expect(runFor(combat, p, 20_000)).toBeGreaterThan(0);
  });
});

describe('fleeing', () => {
  it('starts later and is rarer than the catch window it competes with', () => {
    expect(orbs.fleeHpFraction).toBeLessThanOrEqual(0.1);
    expect(orbs.fleeChancePerSecond).toBeLessThanOrEqual(0.12);
  });
});

describe('Meadows fights last long enough to read', () => {
  it('gives a starter-tier target enough HP to survive several exchanges', () => {
    const sec = (species as Record<string, unknown>).species ?? species;
    const moth = (sec as Record<string, { base: { hp: number } } | undefined>).tuftmoth;
    expect(moth?.base.hp).toBeGreaterThanOrEqual(60);
  });

  it('keeps the telegraph readable', () => {
    expect(TIMING.telegraphMs).toBeGreaterThanOrEqual(1000);
  });
});
