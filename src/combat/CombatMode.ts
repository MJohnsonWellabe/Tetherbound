import { bus } from '../core/EventBus';
import type { Input } from '../core/input/Input';
import type { PalState } from '../party/PalState';
import type { Party } from '../party/Party';
import { adjustAffinity, awardXp, benchShare, xpForWin } from '../party/Progression';
import { derive, speciesDef } from '../entities/Species';
import type { WildPal } from '../entities/SpawnManager';
import { applyDamage, chargeAfterQuick, resolveAttack, TIMING } from './MoveResolver';
import { catchChance, ringQualityAt, rollCatch, shouldFlee, THROW_CONFIG } from './Throw';

/**
 * Combat Mode: a STATE, not a scene.
 *
 * ARCHITECTURE.md rule 5 and GAME_DESIGN.md section 7. The world keeps
 * rendering, the terrain stays live, no chunk unloads and no loading screen
 * ever appears. Entering a fight changes the camera framing, the input mode and
 * the HUD, and nothing else.
 *
 * The throw is available from the first frame (CLAUDE.md hard constraint 3).
 * There is no wind-up, no cooldown and no gate on enemy health; `tryThrow` can
 * be called on the opening tick and will resolve.
 */

export type CombatPhase = 'idle' | 'fighting' | 'won' | 'lost' | 'fled' | 'caught';

export interface CombatSnapshot {
  phase: CombatPhase;
  enemy: PalState | null;
  enemyMaxHp: number;
  active: PalState | null;
  activeMaxHp: number;
  charge: number;
  /** 0..1, how far the catch ring has closed. */
  ringProgress: number;
  telegraphing: boolean;
}

export class CombatMode {
  phase: CombatPhase = 'idle';
  private enemy: WildPal | null = null;
  private charge = 0;
  private ringMs = 0;
  private enemyCooldownMs = 0;
  private telegraphMs = 0;
  private dodgeMs = 0;
  private swapLockMs = 0;

  constructor(
    private readonly party: Party,
    private readonly input: Input
  ) {}

  get isFighting(): boolean {
    return this.phase === 'fighting';
  }

  get target(): WildPal | null {
    return this.enemy;
  }

  /** Enter a fight. Returns false if the party cannot field anyone. */
  enter(enemy: WildPal): boolean {
    if (this.phase === 'fighting') return false;
    if (this.party.allFainted || this.party.size === 0) return false;

    this.enemy = enemy;
    this.phase = 'fighting';
    this.charge = 0;
    this.ringMs = 0;
    this.enemyCooldownMs = TIMING.quickCastMs;
    this.telegraphMs = 0;
    this.dodgeMs = 0;
    this.swapLockMs = 0;
    this.input.setMode('combat');
    bus.emit('combatStarted', { species: enemy.state.species, level: enemy.state.level });
    return true;
  }

  private exit(phase: CombatPhase): void {
    this.phase = phase;
    this.input.setMode('explore');
    bus.emit('combatEnded', { phase });
  }

  /** One fixed step. */
  update(dt: number, day: number, rand: () => number = Math.random): void {
    if (this.phase !== 'fighting' || !this.enemy) return;
    const dtMs = dt * 1000;
    const enemy = this.enemy.state;
    const active = this.party.active;
    if (!active) {
      this.exit('lost');
      return;
    }

    this.ringMs = (this.ringMs + dtMs) % THROW_CONFIG.ringShrinkMs;
    if (this.swapLockMs > 0) this.swapLockMs -= dtMs;
    if (this.dodgeMs > 0) this.dodgeMs -= dtMs;

    // The player's dodge opens a window; it does not move the pal, because the
    // player never controls pal movement (section 7).
    if (this.input.intent.dodge !== 0) this.dodgeMs = TIMING.dodgeWindowMs;

    // Swapping costs a vulnerability window rather than being free.
    const slot = this.input.intent.slot;
    if (slot !== null && this.party.setActive(slot - 1)) {
      this.swapLockMs = TIMING.swapVulnerabilityMs;
    }

    this.tickEnemy(dtMs, active, enemy, rand);

    // A collared pal cannot flee: it is not there by choice, and a Hall fight
    // that Bracken's Loamking could walk out of at 20% HP is not a boss fight.
    if (!enemy.collared && shouldFlee(enemy.currentHp, derive(enemy).maxHp, dt, rand)) {
      // A flee ends the fight with no rewards, which is the pressure that makes
      // throwing early the right instinct rather than grinding it down.
      this.exit('fled');
      return;
    }

    if (this.party.allFainted) this.exit('lost');
    void day;
  }

  private tickEnemy(dtMs: number, active: PalState, enemy: PalState, rand: () => number): void {
    if (this.telegraphMs > 0) {
      this.telegraphMs -= dtMs;
      if (this.telegraphMs > 0) return;
      // The telegraph just finished: the power attack lands unless the player
      // dodged inside the window.
      const result = resolveAttack(enemy, active, {
        kind: 'power',
        defenderDodged: this.dodgeMs > 0,
        rand
      });
      this.landOnPlayer(active, result.damage, result.dodged, 'power');
      this.enemyCooldownMs = TIMING.quickCastMs * 2;
      return;
    }

    this.enemyCooldownMs -= dtMs;
    if (this.enemyCooldownMs > 0) return;

    // Enemies telegraph power attacks. A wild pal without one just jabs.
    const wantsPower = enemy.level >= 8 && rand() < 0.35;
    if (wantsPower) {
      this.telegraphMs = TIMING.telegraphMs;
      bus.emit('enemyTelegraph', { ms: TIMING.telegraphMs });
      return;
    }

    const result = resolveAttack(enemy, active, { kind: 'quick', defenderDodged: false, rand });
    this.landOnPlayer(active, result.damage, false, 'quick');
    this.enemyCooldownMs = TIMING.quickCastMs + TIMING.quickCastMs * rand();
  }

  private landOnPlayer(
    active: PalState,
    amount: number,
    dodged: boolean,
    kind: 'quick' | 'power'
  ): void {
    if (dodged || amount <= 0) {
      bus.emit('attackResolved', { attacker: 'enemy', kind, damage: 0, dodged, defeated: false });
      return;
    }
    // A pal caught mid-swap eats extra, which is what makes the swap a cost.
    const scaled = this.swapLockMs > 0 ? Math.ceil(amount * 1.5) : amount;
    const fainted = applyDamage(active, scaled);
    bus.emit('attackResolved', {
      attacker: 'enemy',
      kind,
      damage: scaled,
      dodged: false,
      defeated: fainted
    });
    if (fainted) {
      adjustAffinity(active, -12);
      bus.emit('palFainted', { uid: active.uid });
      // Fall through to the next healthy pal, or lose.
      const next = this.party.members.findIndex((p) => !p.fainted);
      if (next >= 0) this.party.setActive(next);
    }
  }

  /** Player attacks. `kind` is decided by how long primary was held. */
  attack(kind: 'quick' | 'power', day: number, rand: () => number = Math.random): void {
    if (this.phase !== 'fighting' || !this.enemy) return;
    const active = this.party.active;
    if (!active || active.fainted) return;
    if (kind === 'power' && this.charge < TIMING.powerChargeCost) return;

    const result = resolveAttack(active, this.enemy.state, {
      kind,
      defenderDodged: false,
      rand
    });
    if (result.hesitated) {
      bus.emit('palHesitated', { uid: active.uid });
      return;
    }

    if (kind === 'power') this.charge = 0;
    else this.charge = chargeAfterQuick(this.charge);

    const defeated = applyDamage(this.enemy.state, result.damage);
    bus.emit('attackResolved', {
      attacker: 'ally',
      kind,
      damage: result.damage,
      dodged: false,
      defeated
    });
    if (defeated) {
      this.win(active, this.enemy.state, result.typeAdvantage, day);
    }
  }

  private win(active: PalState, defeated: PalState, advantage: boolean, day: number): void {
    const award = xpForWin(defeated.level, advantage);
    awardXp(active, award);
    adjustAffinity(active, 4);
    for (const pal of this.party.members) {
      if (pal.uid !== active.uid) awardXp(pal, benchShare(award));
    }
    bus.emit('combatWon', { xp: award, day });
    this.exit('won');
  }

  /**
   * Throw an orb. Always legal while a fight is running, including the opening
   * frame, per CLAUDE.md hard constraint 3.
   */
  tryThrow(orbId: string, day: number, nowMs: number, rand: () => number = Math.random):
    | { caught: false; bounced: boolean; chance: number }
    | { caught: true; pal: PalState } {
    if (this.phase !== 'fighting' || !this.enemy) {
      return { caught: false, bounced: false, chance: 0 };
    }
    const enemy = this.enemy.state;
    const input = {
      speciesCatchRate: speciesCatchRate(enemy),
      currentHp: enemy.currentHp,
      maxHp: derive(enemy).maxHp,
      palLevel: enemy.level,
      highestPartyLevel: this.party.highestLevel,
      ring: ringQualityAt(this.ringProgress),
      orb: orbId,
      staggered: false,
      // Was `species === 'collared'`, which no species is ever named, so the
      // bounce could never fire and every Tether pal was quietly catchable.
      // The collar is a flag on the pal now, set from encounters.json.
      collared: this.enemy.state.collared === true
    };

    // A collared pal bounces the orb. Distinguishable from a bad roll, because
    // the HUD has to say something different (section 10).
    if (catchChance(input) === 0) {
      bus.emit('orbBounced', {});
      return { caught: false, bounced: true, chance: 0 };
    }

    const result = rollCatch(input, rand);
    if (!result.caught) {
      // A failed throw grants the enemy a free attack window.
      this.enemyCooldownMs = 0;
      bus.emit('catchFailed', { chance: result.chance, shakes: result.shakes });
      return { caught: false, bounced: false, chance: result.chance };
    }

    enemy.caughtOnDay = day;
    enemy.caughtAtMs = nowMs;
    this.exit('caught');
    return { caught: true, pal: enemy };
  }

  get ringProgress(): number {
    return this.ringMs / THROW_CONFIG.ringShrinkMs;
  }

  snapshot(): CombatSnapshot {
    const active = this.party.active;
    return {
      phase: this.phase,
      enemy: this.enemy?.state ?? null,
      enemyMaxHp: this.enemy ? derive(this.enemy.state).maxHp : 0,
      active,
      activeMaxHp: active ? derive(active).maxHp : 0,
      charge: this.charge,
      ringProgress: this.ringProgress,
      telegraphing: this.telegraphMs > 0
    };
  }

  /** Clear after the caller has dealt with the outcome. */
  reset(): void {
    this.enemy = null;
    this.phase = 'idle';
  }
}

function speciesCatchRate(pal: PalState): number {
  return speciesDef(pal.species)?.catchRate ?? 0.3;
}
