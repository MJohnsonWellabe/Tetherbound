import { describe, expect, it } from 'vitest';
import combat from '../src/data/combat.json';
import { Battle, type BattleEvent } from '../src/combat/Battle';
import { makePal, type PalState } from '../src/party/Pal';

/**
 * The fight, driven headless.
 *
 * The rules that M4 depends on are the ones worth pinning: a collared pal
 * cannot be caught, a Hall fight cannot be fled, and a multi-pal team advances
 * to its next pal rather than ending at the first faint.
 */

function run(battle: Battle, ms: number): void {
  const step = 1000 / 60;
  let remaining = ms;
  while (remaining > 1e-9 && !battle.isOver) {
    const dt = Math.min(step, remaining);
    battle.update(dt);
    remaining -= dt;
  }
}

function setup(
  allySpec: [string, number][],
  enemySpec: [string, number][],
  random: () => number = () => 0.5,
  options: { scripted?: boolean; collared?: boolean } = {}
): { battle: Battle; events: BattleEvent[]; allies: PalState[]; enemies: PalState[] } {
  const allies = allySpec.map(([s, l]) => makePal(s, l, () => 0.5));
  const enemies = enemySpec.map(([s, l]) =>
    makePal(s, l, () => 0.5, options.collared ? { collared: true } : {})
  );
  const events: BattleEvent[] = [];
  const battle = new Battle(allies, enemies, (e) => events.push(e), random, {
    ...(options.scripted === undefined ? {} : { scripted: options.scripted })
  });
  return { battle, events, allies, enemies };
}

const kinds = (events: BattleEvent[]): string[] => events.map((e) => e.kind);

describe('attacking', () => {
  it('lands a quick attack after its cast time and builds charge', () => {
    const { battle, events, enemies } = setup([['cindercub', 10]], [['pebblit', 5]]);
    const before = enemies[0]!.hp;
    expect(battle.quickAttack()).toBe(true);
    run(battle, 600);
    expect(enemies[0]!.hp).toBeLessThan(before);
    expect(kinds(events)).toContain('hit');
    expect(battle.activeAlly!.charge).toBeGreaterThan(0);
  });

  it('refuses a power attack without a full meter', () => {
    const { battle } = setup([['cindercub', 10]], [['pebblit', 5]]);
    expect(battle.powerAttack()).toBe(false);
  });

  it('refuses a power attack below the unlock level even with a full meter', () => {
    const { battle } = setup([['cindercub', 4]], [['pebblit', 5]]);
    battle.activeAlly!.charge = combat.charge.max;
    expect(battle.powerAttack()).toBe(false);
  });

  it('spends the whole meter on a power attack', () => {
    const { battle } = setup([['cindercub', 12]], [['pebblit', 5]]);
    battle.activeAlly!.charge = combat.charge.max;
    expect(battle.powerAttack()).toBe(true);
    expect(battle.activeAlly!.charge).toBe(0);
  });

  it('lets Thistleback punish a quick attack', () => {
    // riposte fires when random() is below the species chance of 0.35
    const { battle, events } = setup([['cindercub', 10]], [['thistleback', 8]], () => 0.1);
    battle.quickAttack();
    run(battle, 600);
    expect(kinds(events)).toContain('riposte');
  });
});

describe('dodging', () => {
  it('negates a telegraphed power attack dodged inside the window', () => {
    const { battle, events, allies } = setup([['bramblit', 10]], [['pebblit', 10]]);
    // Give the enemy a full meter so it opens with the telegraphed power
    // attack, which is the hit the dodge window is designed around.
    battle.activeEnemy!.charge = combat.charge.max;
    const hp = allies[0]!.hp;

    // Run up to the telegraph, then keep going until the hit is close enough
    // that one dodge covers it. That gap is the actual skill the tell teaches.
    while (!battle.isOver && !events.some((e) => e.kind === 'telegraph')) {
      battle.update(1000 / 60);
    }
    expect(events.find((e) => e.kind === 'telegraph')).toBeDefined();
    while (!battle.isOver && battle.enemyActionRemainingMs > combat.dodge.windowMs / 2) {
      battle.update(1000 / 60);
    }
    expect(battle.dodge()).toBe(true);
    run(battle, 2000);

    expect(kinds(events)).toContain('dodged');
    expect(allies[0]!.hp).toBe(hp);
  });

  it('has a cooldown, so holding the swipe is not permanent immunity', () => {
    const { battle } = setup([['bramblit', 10]], [['pebblit', 6]]);
    expect(battle.dodge()).toBe(true);
    expect(battle.dodge()).toBe(false);
  });
});

describe('the throw', () => {
  it('is available on the first frame of a fight', () => {
    const { battle } = setup([['cindercub', 10]], [['tuftmoth', 4]]);
    expect(battle.throwOrb(1, 'none', 10)).toBe(true);
  });

  it('catches, ends the fight and hands the pal over', () => {
    const { battle, events, enemies } = setup([['cindercub', 10]], [['tuftmoth', 4]], () => 0);
    battle.throwOrb(2.4, 'great', 10);
    run(battle, 5000);
    expect(kinds(events)).toContain('throwCaught');
    expect(battle.outcome).toBe('caught');
    expect(battle.caught?.uid).toBe(enemies[0]!.uid);
  });

  it('bounces off a collared pal and never catches it', () => {
    const { battle, events } = setup([['cindercub', 10]], [['cragpup', 8]], () => 0, {
      collared: true
    });
    expect(battle.throwOrb(2.4, 'great', 50)).toBe(true);
    run(battle, 5000);
    expect(kinds(events)).toContain('throwBounced');
    expect(kinds(events)).not.toContain('throwCaught');
    expect(battle.caught).toBeNull();
  });

  it('shakes three times before breaking', () => {
    const { battle, events } = setup([['cindercub', 10]], [['ashmane', 16]], () => 0.99);
    battle.throwOrb(1, 'none', 3);
    run(battle, 5000);
    expect(events.filter((e) => e.kind === 'throwShake')).toHaveLength(combat.throw.shakes);
    expect(kinds(events)).toContain('throwBroke');
  });

  it('locks the player out while the enemy takes its free swing', () => {
    const { battle } = setup([['cindercub', 10]], [['ashmane', 16]], () => 0.99);
    battle.throwOrb(1, 'none', 3);
    run(battle, combat.pacing.throwFlightMs + combat.throw.shakeMs * combat.throw.shakes + 50);
    expect(battle.canAct).toBe(false);
  });
});

describe('teams', () => {
  it('advances to the next enemy instead of ending at the first faint', () => {
    const { battle, events, enemies } = setup(
      [['cindercub', 30]],
      [
        ['tuftmoth', 2],
        ['tuftmoth', 2]
      ]
    );
    enemies[0]!.hp = 1;
    battle.quickAttack();
    run(battle, 800);
    expect(kinds(events)).toContain('enemyChanged');
    expect(battle.isOver).toBe(false);
    expect(battle.activeEnemy?.uid).toBe(enemies[1]!.uid);
  });

  it('wins only when the last enemy is down, and banks the xp', () => {
    const { battle, enemies } = setup([['cindercub', 30]], [['tuftmoth', 2], ['tuftmoth', 2]]);
    for (const e of enemies) e.hp = 1;
    battle.quickAttack();
    run(battle, 800);
    battle.quickAttack();
    run(battle, 800);
    expect(battle.outcome).toBe('won');
    expect(battle.xpAward).toBeGreaterThan(0);
  });

  it('sends in the next ally when one faints', () => {
    const { battle, events, allies } = setup(
      [
        ['tuftmoth', 2],
        ['bramblit', 20]
      ],
      [['ashmane', 30]]
    );
    allies[0]!.hp = 1;
    // Stop at the moment of the faint. Running longer just measures how fast an
    // Ashmane can also kill the second pal, which is not what this asserts.
    while (!battle.isOver && !events.some((e) => e.kind === 'faint')) {
      battle.update(1000 / 60);
    }
    expect(kinds(events)).toContain('faint');
    expect(battle.outcome).not.toBe('lost');
    expect(battle.activeAlly?.uid).toBe(allies[1]!.uid);
  });

  it('loses when every ally is down', () => {
    const { battle, allies } = setup([['tuftmoth', 2]], [['ashmane', 40]]);
    allies[0]!.hp = 1;
    run(battle, 8000);
    expect(battle.outcome).toBe('lost');
  });
});

describe('fleeing', () => {
  it('lets a wild pal bolt once it is hurt', () => {
    const { battle, events, enemies } = setup([['cindercub', 10]], [['sparrowick', 5]], () => 0.01);
    enemies[0]!.hp = 1;
    run(battle, 4000);
    expect(kinds(events)).toContain('fleeing');
    expect(battle.outcome).toBe('fled');
  });

  it('does not let a healthy wild pal flee', () => {
    const { battle } = setup([['cindercub', 1]], [['pebblit', 3]], () => 0.01);
    battle.update(1000);
    expect(battle.outcome).not.toBe('fled');
  });

  it('refuses to let the player walk out of a Hall fight', () => {
    const { battle } = setup([['cindercub', 10]], [['cragpup', 14]], () => 0.5, {
      scripted: true,
      collared: true
    });
    expect(battle.flee()).toBe(false);
    expect(battle.isOver).toBe(false);
  });

  it('does not let a collared pal flee when it is nearly down', () => {
    const { battle, enemies } = setup([['cindercub', 10]], [['cragpup', 14]], () => 0.01, {
      scripted: true,
      collared: true
    });
    enemies[0]!.hp = 1;
    run(battle, 3000);
    expect(battle.outcome).not.toBe('fled');
  });
});

describe('swapping', () => {
  it('costs a vulnerability window', () => {
    const { battle } = setup([['cindercub', 10], ['bramblit', 10]], [['pebblit', 6]]);
    expect(battle.swapTo(1)).toBe(true);
    expect(battle.canAct).toBe(false);
    run(battle, combat.swap.vulnerabilityMs + 50);
    expect(battle.activeAlly?.species).toBe('bramblit');
  });

  it('refuses to swap to a fainted pal', () => {
    const { battle, allies } = setup([['cindercub', 10], ['bramblit', 10]], [['pebblit', 6]]);
    allies[1]!.hp = 0;
    expect(battle.swapTo(1)).toBe(false);
  });
});
