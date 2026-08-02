import { describe, expect, it } from 'vitest';
import { placeStage } from '../src/combat/stagePlacement';
import stageData from '../src/data/combatStage.json';

/**
 * The combat stage: where the ally and enemy stand when a fight starts.
 * Written before the implementation, per the working agreement for combat/.
 */

const CFG = stageData.placement;

describe('placeStage', () => {
  it('puts the ally between the player and the enemy, facing the enemy', () => {
    const p = placeStage(0, 0, 0, 10, CFG);
    // Ally stands allyForward metres from the player, along the line to the enemy.
    expect(p.ally.x).toBeCloseTo(0);
    expect(p.ally.z).toBeCloseTo(CFG.allyForward);
    // Facing +Z, toward the enemy.
    expect(p.ally.yaw).toBeCloseTo(0);
  });

  it('faces the enemy back at the ally', () => {
    const p = placeStage(0, 0, 0, 10, CFG);
    expect(p.enemy.yaw).toBeCloseTo(Math.PI);
  });

  it('pushes a face-to-face enemy out to fighting distance', () => {
    // Encounter triggers at 4m; the stage wants a readable gap.
    const p = placeStage(0, 0, 0, 1, CFG);
    const gap = Math.hypot(p.enemy.x - p.ally.x, p.enemy.z - p.ally.z);
    expect(gap).toBeGreaterThanOrEqual(CFG.gap - 1e-9);
  });

  it('leaves a distant enemy where it stands', () => {
    const p = placeStage(0, 0, 30, 40, CFG);
    expect(p.enemy.x).toBeCloseTo(30);
    expect(p.enemy.z).toBeCloseTo(40);
  });

  it('handles the degenerate zero-distance case without NaN', () => {
    const p = placeStage(5, 5, 5, 5, CFG);
    for (const v of [p.ally.x, p.ally.z, p.ally.yaw, p.enemy.x, p.enemy.z, p.enemy.yaw]) {
      expect(Number.isFinite(v)).toBe(true);
    }
    const gap = Math.hypot(p.enemy.x - p.ally.x, p.enemy.z - p.ally.z);
    expect(gap).toBeGreaterThanOrEqual(CFG.gap - 1e-9);
  });

  it('works at arbitrary angles', () => {
    const p = placeStage(10, -3, -20, 14, CFG);
    // The ally faces along ally->enemy.
    const want = Math.atan2(p.enemy.x - p.ally.x, p.enemy.z - p.ally.z);
    expect(p.ally.yaw).toBeCloseTo(want);
    expect(p.enemy.yaw).toBeCloseTo(want > 0 ? want - Math.PI : want + Math.PI);
  });
});
