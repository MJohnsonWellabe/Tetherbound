import combat from '../data/combat.json';
import { computeDamage, hasTypeAdvantage, rollDamageVariance, typeMultiplier } from './Damage';
import { requireMove, type MoveDef } from './Moves';
import { catchChance, ringBonusFor, rollCatch, type RingQuality } from './Throw';
import { isCatchable, isFainted, type PalState } from '../party/Pal';
import { affinityAfterFaint, affinityAfterWin, hesitatesOnPower } from '../party/Progression';
import { requireSpecies } from '../party/Species';

/**
 * The fight itself, headless.
 *
 * No meshes, no camera, no DOM. CombatMode drives this and renders whatever it
 * reports, which is what lets the whole of combat be exercised in a test at
 * whatever speed the test likes. Every number comes from combat.json.
 *
 * Real time, no turns: both sides run their own action timer and the player's
 * only inputs are attack, dodge, throw, swap and flee.
 */

export type Side = 'ally' | 'enemy';
export type Outcome = 'won' | 'lost' | 'fled' | 'caught';

export type BattleEvent =
  | { kind: 'hit'; target: Side; amount: number; multiplier: number; move: string }
  | { kind: 'dodged'; by: Side }
  | { kind: 'telegraph'; by: Side; move: string; windupMs: number }
  | { kind: 'faint'; side: Side; uid: string }
  | { kind: 'swap'; uid: string }
  | { kind: 'enemyChanged'; uid: string }
  | { kind: 'riposte'; amount: number }
  | { kind: 'throwFlight' }
  | { kind: 'throwBounced' }
  | { kind: 'throwShake'; index: number }
  | { kind: 'throwCaught'; uid: string }
  | { kind: 'throwBroke' }
  | { kind: 'hesitated' }
  | { kind: 'fleeing' }
  | { kind: 'ended'; outcome: Outcome };

interface PendingAction {
  move: MoveDef;
  /** Time left before the hit resolves. */
  remainingMs: number;
  /** True once the telegraph has been announced, so it fires only once. */
  announced: boolean;
}

interface ThrowState {
  /** Countdown through flight, then one entry per shake. */
  timerMs: number;
  stage: 'flight' | 'shake';
  shakeIndex: number;
  willCatch: boolean;
  /** Collared target: the orb rebounds instead of opening. */
  bounces: boolean;
}

export interface BattleOptions {
  /** Tether fights cannot be fled and their pals cannot be caught. */
  scripted?: boolean;
  /** In-game day, stamped onto a caught pal. */
  day?: number;
}

export class Battle {
  readonly enemies: PalState[];
  private readonly emit: (event: BattleEvent) => void;
  private readonly random: () => number;
  private readonly scripted: boolean;
  private readonly day: number;

  private allies: PalState[];
  private allyIndex = 0;
  private enemyIndex = 0;

  private allyAction: PendingAction | null = null;
  private enemyAction: PendingAction | null = null;
  private enemyThinkMs = 0;

  private allyInvulnMs = 0;
  private dodgeCooldownMs = 0;
  private swapLockMs = 0;
  private throwState: ThrowState | null = null;
  /** Lockout after a failed throw. The enemy's free attack window. */
  private recoveryMs = 0;
  private fleeCarryMs = 0;

  outcome: Outcome | null = null;
  /** Set when a throw succeeds, so the caller can hand it to Party.add. */
  caught: PalState | null = null;
  /** XP the win is worth, filled in when the last enemy drops. */
  xpAward = 0;

  constructor(
    allies: PalState[],
    enemies: PalState[],
    emit: (event: BattleEvent) => void,
    random: () => number,
    options: BattleOptions = {}
  ) {
    this.allies = allies;
    this.enemies = enemies;
    this.emit = emit;
    this.random = random;
    this.scripted = options.scripted ?? false;
    this.day = options.day ?? 0;

    this.allyIndex = Math.max(0, allies.findIndex((p) => !isFainted(p)));
    for (const pal of [...allies, ...enemies]) pal.charge = 0;
    this.resetEnemyThink();
  }

  get activeAlly(): PalState | undefined {
    return this.allies[this.allyIndex];
  }

  get activeEnemy(): PalState | undefined {
    return this.enemies[this.enemyIndex];
  }

  get isOver(): boolean {
    return this.outcome !== null;
  }

  get isThrowing(): boolean {
    return this.throwState !== null;
  }

  /** True while the enemy's power attack tell is showing: the dodge window. */
  get enemyTelegraphing(): boolean {
    return this.enemyAction !== null && this.enemyAction.announced;
  }

  /** Time until the enemy's committed action lands. The HUD draws the tell from
   *  this, and it is the only honest way to time a dodge. */
  get enemyActionRemainingMs(): number {
    return this.enemyAction?.remainingMs ?? Infinity;
  }

  get canAct(): boolean {
    return (
      !this.isOver &&
      this.allyAction === null &&
      this.throwState === null &&
      this.swapLockMs <= 0 &&
      this.recoveryMs <= 0
    );
  }

  // ---- player input ------------------------------------------------------

  /** Tap. Always available, cheap, builds the power meter. */
  quickAttack(): boolean {
    const ally = this.activeAlly;
    if (!this.canAct || !ally) return false;
    const move = requireMove(requireSpecies(ally.species).moves.quick);
    this.allyAction = { move, remainingMs: move.castMs, announced: false };
    return true;
  }

  /** Hold and release. Costs the full meter and only unlocks at level 8. */
  powerAttack(): boolean {
    const ally = this.activeAlly;
    if (!this.canAct || !ally) return false;
    if (ally.charge < combat.charge.powerCost) return false;
    if (ally.level < POWER_UNLOCK_LEVEL) return false;

    // A pal that does not trust you sometimes refuses the big swing. The charge
    // is spent either way, which is what makes low affinity cost something.
    if (hesitatesOnPower(ally.affinity, this.random)) {
      ally.charge = 0;
      this.emit({ kind: 'hesitated' });
      return false;
    }

    const move = requireMove(requireSpecies(ally.species).moves.power);
    ally.charge = 0;
    this.allyAction = { move, remainingMs: move.castMs, announced: false };
    return true;
  }

  /** Swipe or A/D. Negates the next hit entirely if it lands in the window. */
  dodge(): boolean {
    if (this.isOver || this.dodgeCooldownMs > 0) return false;
    this.allyInvulnMs = combat.dodge.windowMs;
    this.dodgeCooldownMs = combat.dodge.cooldownMs;
    return true;
  }

  /**
   * The throw. Available from the first frame of any fight, which is a core
   * promise of the design and why there is no readiness check here beyond the
   * one that stops two orbs being in the air at once.
   */
  throwOrb(ballMod: number, quality: RingQuality, highestPartyLevel: number): boolean {
    const target = this.activeEnemy;
    if (this.isOver || this.throwState !== null || !target) return false;

    // A collared pal bounces the orb. The orb is still spent: Tether's pals
    // being uncatchable has to cost something or the lesson does not land.
    const bounces = !isCatchable(target);

    const chance = bounces
      ? 0
      : catchChance({
          speciesCatchRate: requireSpecies(target.species).catchRate,
          currentHp: target.hp,
          maxHp: target.maxHp,
          palLevel: target.level,
          highestPartyLevel,
          ringBonus: ringBonusFor(quality),
          ballMod,
          staggered: this.enemyAction !== null
        });

    this.throwState = {
      timerMs: combat.pacing.throwFlightMs,
      stage: 'flight',
      shakeIndex: 0,
      bounces,
      // Rolled now, revealed over three shakes. The shakes are theatre over a
      // decision already made, which is exactly what they are in the games this
      // borrows from.
      willCatch: !bounces && rollCatch(chance, this.random)
    };
    this.emit({ kind: 'throwFlight' });
    return true;
  }

  /** Tap a party pip. Costs a vulnerability window. */
  swapTo(index: number): boolean {
    if (this.isOver || this.throwState !== null) return false;
    const next = this.allies[index];
    if (!next || isFainted(next) || index === this.allyIndex) return false;
    this.allyIndex = index;
    this.allyAction = null;
    this.swapLockMs = combat.swap.vulnerabilityMs;
    this.emit({ kind: 'swap', uid: next.uid });
    return true;
  }

  /** Hold back. Scripted fights refuse: you do not walk out of a Hall fight. */
  flee(): boolean {
    if (this.isOver || this.scripted) return false;
    this.finish('fled');
    return true;
  }

  // ---- simulation --------------------------------------------------------

  update(dtMs: number): void {
    if (this.isOver) return;

    this.allyInvulnMs = Math.max(0, this.allyInvulnMs - dtMs);
    this.dodgeCooldownMs = Math.max(0, this.dodgeCooldownMs - dtMs);
    this.swapLockMs = Math.max(0, this.swapLockMs - dtMs);
    this.recoveryMs = Math.max(0, this.recoveryMs - dtMs);

    if (this.throwState) {
      this.tickThrow(dtMs);
      return;
    }

    this.tickAlly(dtMs);
    if (this.isOver) return;
    this.tickEnemy(dtMs);
    if (this.isOver) return;
    this.tickFlee(dtMs);
  }

  private tickAlly(dtMs: number): void {
    const action = this.allyAction;
    const ally = this.activeAlly;
    if (!action || !ally) return;

    action.remainingMs -= dtMs;
    if (action.remainingMs > 0) return;

    this.allyAction = null;
    const target = this.activeEnemy;
    if (!target) return;

    this.resolveHit(ally, target, action.move, 'enemy');
    if (action.move.kind === 'quick') {
      ally.charge = Math.min(combat.charge.max, ally.charge + action.move.charge);
      this.maybeRiposte(target, ally);
    }
    if (isFainted(target)) this.onEnemyDown();
  }

  private tickEnemy(dtMs: number): void {
    const enemy = this.activeEnemy;
    if (!enemy) return;

    const action = this.enemyAction;
    if (action) {
      action.remainingMs -= dtMs;

      // The tell is the LAST windupMs of the cast, not the first. GAME_DESIGN.md
      // section 7 describes a 0.6s colour flash that a correctly timed dodge
      // negates, which only works if the flash immediately precedes the hit.
      // Announcing it at the start of a 1.2s cast would put the flash a full
      // second before impact and make the dodge window unreachable.
      if (
        !action.announced &&
        action.move.kind === 'power' &&
        action.remainingMs <= action.move.windupMs
      ) {
        action.announced = true;
        this.emit({
          kind: 'telegraph',
          by: 'enemy',
          move: action.move.id,
          windupMs: action.move.windupMs
        });
      }

      if (action.remainingMs > 0) return;

      this.enemyAction = null;
      const ally = this.activeAlly;
      if (!ally) return;

      // The dodge. A correctly timed one negates the hit entirely, per
      // GAME_DESIGN.md section 7, and it works on quick attacks too so the
      // input never feels dead.
      if (this.allyInvulnMs > 0) {
        this.emit({ kind: 'dodged', by: 'ally' });
        this.resetEnemyThink();
        return;
      }

      this.resolveHit(enemy, ally, action.move, 'ally');
      if (action.move.kind === 'quick') {
        enemy.charge = Math.min(combat.charge.max, enemy.charge + action.move.charge);
      }
      if (isFainted(ally)) this.onAllyDown();
      this.resetEnemyThink();
      return;
    }

    this.enemyThinkMs -= dtMs;
    if (this.enemyThinkMs > 0) return;

    const def = requireSpecies(enemy.species);
    // Power attack when the meter is full, otherwise chip away. Collared pals
    // never dodge, so their whole behaviour is this one decision.
    const usePower = enemy.charge >= combat.charge.powerCost && enemy.level >= POWER_UNLOCK_LEVEL;
    const move = requireMove(usePower ? def.moves.power : def.moves.quick);
    if (usePower) enemy.charge = 0;
    this.enemyAction = { move, remainingMs: move.castMs, announced: false };
  }

  /** A hit the player earned by throwing badly. */
  private tickThrow(dtMs: number): void {
    const t = this.throwState;
    if (!t) return;
    t.timerMs -= dtMs;
    if (t.timerMs > 0) return;

    if (t.stage === 'flight') {
      if (t.bounces) {
        this.throwState = null;
        this.emit({ kind: 'throwBounced' });
        this.grantFreeAttack();
        return;
      }
      t.stage = 'shake';
      t.shakeIndex = 0;
      t.timerMs = combat.throw.shakeMs;
      this.emit({ kind: 'throwShake', index: 0 });
      return;
    }

    t.shakeIndex += 1;
    if (t.shakeIndex < combat.throw.shakes) {
      t.timerMs = combat.throw.shakeMs;
      this.emit({ kind: 'throwShake', index: t.shakeIndex });
      return;
    }

    const target = this.activeEnemy;
    this.throwState = null;
    if (t.willCatch && target) {
      target.caughtDay = this.day;
      this.caught = target;
      this.emit({ kind: 'throwCaught', uid: target.uid });
      this.finish('caught');
      return;
    }
    this.emit({ kind: 'throwBroke' });
    this.grantFreeAttack();
  }

  /**
   * A failed throw gives the enemy a free swing, per section 7.
   *
   * Two halves, and both are needed for it to read as a punishment: the enemy
   * acts immediately, and the player cannot act for the length of the window.
   * Without the second half the player just attacks through it and the cost of
   * a missed throw is nothing.
   */
  private grantFreeAttack(): void {
    this.enemyThinkMs = 0;
    this.recoveryMs = combat.throw.freeAttackOnFailMs;
  }

  private tickFlee(dtMs: number): void {
    const enemy = this.activeEnemy;
    if (!enemy || this.scripted) return;
    if (enemy.hp > enemy.maxHp * combat.flee.hpFraction) {
      this.fleeCarryMs = 0;
      return;
    }
    // 25% per second, evaluated once per whole second so the rate is the rate
    // rather than an artifact of the step size.
    this.fleeCarryMs += dtMs;
    while (this.fleeCarryMs >= 1000) {
      this.fleeCarryMs -= 1000;
      if (this.random() < combat.flee.chancePerSecond) {
        this.emit({ kind: 'fleeing' });
        this.finish('fled');
        return;
      }
    }
  }

  private resolveHit(attacker: PalState, defender: PalState, move: MoveDef, target: Side): void {
    const multiplier = typeMultiplier(attacker.type, defender.type);
    const amount = computeDamage(
      {
        atk: attacker.atk,
        def: defender.def,
        movePower: move.power,
        attackerType: attacker.type,
        defenderType: defender.type,
        affinity: attacker.affinity,
        levelDiff: attacker.level - defender.level,
        collared: attacker.collared
      },
      rollDamageVariance(this.random)
    );

    defender.hp = Math.max(0, defender.hp - Math.round(amount));
    this.emit({ kind: 'hit', target, amount: Math.round(amount), multiplier, move: move.id });
  }

  /** Thistleback punishes quick attacks. Data driven, not a species check. */
  private maybeRiposte(defender: PalState, attacker: PalState): void {
    if (isFainted(defender)) return;
    const chance = requireSpecies(defender.species).riposte;
    if (chance === undefined || this.random() >= chance) return;

    const move = requireMove(requireSpecies(defender.species).moves.quick);
    const before = attacker.hp;
    this.resolveHit(defender, attacker, move, 'ally');
    this.emit({ kind: 'riposte', amount: before - attacker.hp });
    if (isFainted(attacker)) this.onAllyDown();
  }

  private onEnemyDown(): void {
    const downed = this.enemies[this.enemyIndex];
    if (downed) {
      this.emit({ kind: 'faint', side: 'enemy', uid: downed.uid });
      const ally = this.activeAlly;
      this.xpAward += Math.floor(
        combat.xp.winBase *
          downed.level *
          (ally && hasTypeAdvantage(ally.type, downed.type) ? combat.xp.typeAdvantageBonus : 1)
      );
      if (ally) ally.affinity = affinityAfterWin(ally.affinity);
    }

    const next = this.enemies.findIndex((p) => !isFainted(p));
    if (next < 0) {
      this.finish('won');
      return;
    }
    this.enemyIndex = next;
    this.enemyAction = null;
    this.resetEnemyThink();
    const upNext = this.enemies[next];
    if (upNext) this.emit({ kind: 'enemyChanged', uid: upNext.uid });
  }

  private onAllyDown(): void {
    const downed = this.activeAlly;
    if (downed) {
      downed.affinity = affinityAfterFaint(downed.affinity);
      this.emit({ kind: 'faint', side: 'ally', uid: downed.uid });
    }

    const next = this.allies.findIndex((p) => !isFainted(p));
    if (next < 0) {
      this.finish('lost');
      return;
    }
    this.allyIndex = next;
    this.allyAction = null;
    const upNext = this.allies[next];
    if (upNext) this.emit({ kind: 'swap', uid: upNext.uid });
  }

  /**
   * Delay before the enemy's next action, from its SPD. A fast pal acts more
   * often rather than hitting harder, which is what keeps SPD from being a
   * stat nobody reads.
   */
  private resetEnemyThink(): void {
    const enemy = this.activeEnemy;
    const spd = enemy ? Math.max(1, enemy.spd) : combat.pacing.enemyThinkReferenceSpd;
    const base = combat.pacing.enemyThinkBaseMs * (combat.pacing.enemyThinkReferenceSpd / spd);
    this.enemyThinkMs = Math.max(combat.pacing.enemyThinkFloorMs, base);
  }

  private finish(outcome: Outcome): void {
    if (this.outcome !== null) return;
    this.outcome = outcome;
    this.allyAction = null;
    this.enemyAction = null;
    this.throwState = null;
    this.emit({ kind: 'ended', outcome });
  }
}

/** Power attacks unlock at level 8. GAME_DESIGN.md section 5, via combat.json. */
export const POWER_UNLOCK_LEVEL = combat.charge.powerUnlockLevel;
