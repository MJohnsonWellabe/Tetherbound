import type { CombatMode } from '../combat/CombatMode';
import { TIMING } from '../combat/MoveResolver';
import { ringQualityAt } from '../combat/Throw';
import { bus } from '../core/EventBus';
import type { Intent } from '../core/input/Intent';
import { speciesDef } from '../entities/Species';
import type { Party } from '../party/Party';
import { xpToNext } from '../party/Progression';
import { count, type Slots } from '../survival/Inventory';

/**
 * The combat HUD, replacing the ASCII readout: enemy bar up top, ally card and
 * actions along the bottom, the catch ring over everything while a throw is
 * worth timing.
 *
 * DOM, not in-canvas, per ARCHITECTURE.md; every class it emits already exists
 * in game.css. The buttons write into the shared Intent exactly the way the
 * input layers do, so a tap, a key and a trigger all arrive at CombatMode as
 * the same edge. Built once, shown and hidden; a fight must cost zero DOM
 * construction.
 */

const ORB_LABELS: [string, string][] = [
  ['worn_orb', 'Worn'],
  ['keen_orb', 'Keen'],
  ['truestone_orb', 'True']
];

const LOG_LINES = 4;

export class CombatScreen {
  private readonly enemyName: HTMLElement;
  private readonly enemyLevel: HTMLElement;
  private readonly enemyTag: HTMLElement;
  private readonly enemyFill: HTMLElement;
  private readonly telegraph: HTMLElement;
  private readonly log: HTMLElement;
  private readonly allyName: HTMLElement;
  private readonly allyFill: HTMLElement;
  private readonly xpFill: HTMLElement;
  private readonly chargeFill: HTMLElement;
  private readonly attackBtn: HTMLButtonElement;
  private readonly orbBtn: HTMLButtonElement;
  private readonly slots: HTMLButtonElement[] = [];
  private readonly ring: HTMLElement;
  private readonly ringMark: HTMLElement;

  private attackDownAt = 0;
  private attackHeld = false;
  /** Fixed steps the current press has been visible to the sim. */
  private downSteps = 0;
  /** A release waiting until the press has been sampled at least once. */
  private releaseHeldMs: number | null = null;
  private readonly unsubs: (() => void)[] = [];

  constructor(
    private readonly root: HTMLElement,
    private readonly combat: CombatMode,
    private readonly party: Party,
    private readonly intent: Intent,
    private readonly inventory: Slots
  ) {
    root.innerHTML = `
      <div class="cb__enemy">
        <div class="cb__row">
          <span class="cb__name" data-e="name"></span>
          <span class="cb__tag" data-e="tag" hidden>COLLARED</span>
          <span class="cb__line" data-e="level"></span>
        </div>
        <div class="bar bar--enemy"><div class="bar__fill bar__fill--enemy" data-e="hp"></div></div>
        <div class="cb__telegraph" data-e="telegraph" hidden>INCOMING — DODGE</div>
      </div>
      <div class="cb__log" data-e="log"></div>
      <div class="cb__bottom">
        <div class="cb__ally">
          <div class="cb__row"><span class="cb__name" data-e="allyName"></span></div>
          <div class="bar"><div class="bar__fill bar__fill--health" data-e="allyHp"></div></div>
          <div class="bar bar--xp"><div class="bar__fill bar__fill--xp" data-e="xp"></div></div>
          <div class="bar bar--charge"><div class="bar__fill bar__fill--charge" data-e="charge"></div></div>
        </div>
        <div class="cb__slots" data-e="slots"></div>
        <div class="cb__actions">
          <button type="button" class="cb__btn cb__btn--attack" data-e="attack">Attack</button>
          <button type="button" class="cb__btn cb__btn--dodge" data-e="dodge">Dodge</button>
          <button type="button" class="cb__orb" data-e="orb"></button>
        </div>
      </div>
      <div class="ring" data-e="ring" hidden>
        <div class="ring__mark" data-e="ringMark"></div>
        <div class="ring__hint">throw as the ring closes</div>
      </div>`;

    const q = <T extends HTMLElement>(k: string): T =>
      root.querySelector<T>(`[data-e="${k}"]`) as T;
    this.enemyName = q('name');
    this.enemyLevel = q('level');
    this.enemyTag = q('tag');
    this.enemyFill = q('hp');
    this.telegraph = q('telegraph');
    this.log = q('log');
    this.allyName = q('allyName');
    this.allyFill = q('allyHp');
    this.xpFill = q('xp');
    this.chargeFill = q('charge');
    this.attackBtn = q<HTMLButtonElement>('attack');
    this.orbBtn = q<HTMLButtonElement>('orb');
    this.ring = q('ring');
    this.ringMark = q('ringMark');

    const slotsBox = q('slots');
    for (let i = 0; i < 5; i++) {
      const b = document.createElement('button');
      b.type = 'button';
      b.className = 'cb__slot';
      b.textContent = String(i + 1);
      b.addEventListener('pointerdown', (e) => {
        e.preventDefault();
        this.intent.slot = (i + 1) as Intent['slot'];
      });
      slotsBox.appendChild(b);
      this.slots.push(b);
    }

    // Attack: hold to charge, release to commit. Mirrors DesktopLayer's
    // primary handling so Encounter sees identical edges.
    this.attackBtn.addEventListener('pointerdown', (e) => {
      e.preventDefault();
      this.attackDownAt = performance.now();
      this.attackHeld = true;
      this.downSteps = 0;
      this.releaseHeldMs = null;
      this.intent.primary.down = true;
      this.intent.primary.heldMs = 0;
    });
    // A fast click can go down and up between two fixed steps; releasing the
    // intent immediately would mean the sim never saw the press at all. The
    // release waits (in update()) until the press has been sampled once.
    const releaseAttack = (): void => {
      if (!this.attackHeld) return;
      this.attackHeld = false;
      this.releaseHeldMs = performance.now() - this.attackDownAt;
    };
    this.attackBtn.addEventListener('pointerup', releaseAttack);
    this.attackBtn.addEventListener('pointercancel', releaseAttack);
    this.attackBtn.addEventListener('pointerleave', releaseAttack);

    q('dodge').addEventListener('pointerdown', (e) => {
      e.preventDefault();
      this.intent.dodge = 1;
    });
    this.orbBtn.addEventListener('pointerdown', (e) => {
      e.preventDefault();
      this.intent.throwOrb = true;
    });

    this.unsubs.push(
      bus.on('attackResolved', (ev) => {
        if (ev.dodged) this.pushLog('dodged it', 'good');
        else if (ev.damage > 0) {
          this.pushLog(
            ev.attacker === 'ally' ? `hit for ${ev.damage}` : `took ${ev.damage}`,
            ev.attacker === 'ally' ? 'good' : 'bad'
          );
        }
      }),
      bus.on('orbThrown', ({ outcome }) => {
        if (outcome === 'bounced') this.pushLog('the orb bounced off. that one is collared.', 'bad');
        if (outcome === 'missed') this.pushLog('it broke free', 'bad');
        if (outcome === 'caught') this.pushLog('caught', 'good');
      }),
      bus.on('palHesitated', () => this.pushLog('it hesitated…', 'bad')),
      bus.on('combatStarted', () => {
        this.log.textContent = '';
      })
    );
  }

  /** Called once per fixed step. */
  update(): void {
    // The press/release relay for the attack button (see the listener note).
    if (this.intent.primary.down && (this.attackHeld || this.releaseHeldMs !== null)) {
      this.downSteps++;
      if (this.attackHeld) this.intent.primary.heldMs = performance.now() - this.attackDownAt;
    }
    if (this.releaseHeldMs !== null && this.downSteps > 0) {
      this.intent.primary.heldMs = this.releaseHeldMs;
      this.intent.primary.down = false;
      this.releaseHeldMs = null;
    }

    if (!this.combat.isFighting) {
      if (!this.root.hidden) this.root.hidden = true;
      return;
    }
    this.root.hidden = false;

    const s = this.combat.snapshot();
    if (!s.enemy || !s.active) return;

    this.enemyName.textContent = speciesDef(s.enemy.species)?.name ?? s.enemy.species;
    this.enemyLevel.textContent = `Lv${s.enemy.level}`;
    this.enemyTag.hidden = s.enemy.collared !== true;
    this.enemyFill.style.width = pct(s.enemy.currentHp, s.enemyMaxHp);
    this.telegraph.hidden = !s.telegraphing;

    this.allyName.textContent = `${speciesDef(s.active.species)?.name ?? s.active.species} Lv${s.active.level}`;
    this.allyFill.style.width = pct(s.active.currentHp, s.activeMaxHp);
    this.xpFill.style.width = pct(s.active.xp, xpToNext(s.active.level));
    this.chargeFill.style.width = pct(s.charge, TIMING.powerChargeCost);
    this.attackBtn.classList.toggle('is-ready', s.charge >= TIMING.powerChargeCost);
    this.attackBtn.classList.toggle(
      'is-charging',
      this.attackHeld && performance.now() - this.attackDownAt >= 200
    );

    const orbs = ORB_LABELS.map(([id, label]) => [label, count(this.inventory, id)] as const).filter(
      ([, n]) => n > 0
    );
    const first = orbs[0];
    this.orbBtn.disabled = !first;
    this.orbBtn.textContent = first ? `Orb ×${first[1]} (${first[0]})` : 'No orbs';

    for (let i = 0; i < this.slots.length; i++) {
      const btn = this.slots[i];
      const pal = this.party.members[i];
      if (!btn) continue;
      btn.style.display = pal ? '' : 'none';
      btn.classList.toggle('is-active', i === this.party.activeSlot);
      btn.classList.toggle('is-out', pal?.fainted === true);
    }

    // The catch ring: always live during a fight, because the throw is always
    // available. Scale tracks the shrink; colour grades the timing window.
    this.ring.hidden = false;
    const closed = 1 - s.ringProgress;
    this.ringMark.style.transform = `scale(${(0.25 + closed * 0.75).toFixed(3)})`;
    this.ringMark.setAttribute('data-quality', ringQualityAt(s.ringProgress));
  }

  private pushLog(text: string, tone: 'good' | 'bad'): void {
    const line = document.createElement('div');
    line.className = `cb__line cb__line--${tone}`;
    line.textContent = text;
    this.log.appendChild(line);
    while (this.log.children.length > LOG_LINES) this.log.firstChild?.remove();
  }

  dispose(): void {
    for (const un of this.unsubs) un();
    this.unsubs.length = 0;
    this.root.innerHTML = '';
    this.root.hidden = true;
  }
}

function pct(current: number, max: number): string {
  if (max <= 0) return '0%';
  return `${Math.max(0, Math.min(100, (current / max) * 100)).toFixed(1)}%`;
}
