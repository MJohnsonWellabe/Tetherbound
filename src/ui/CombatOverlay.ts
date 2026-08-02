import combat from '../data/combat.json';
import { clear, el, setFill, show, tapButton } from './dom';
import { ringQuality, ringRadiusAt, type RingQuality } from '../combat/Throw';
import { POWER_UNLOCK_LEVEL, type Battle } from '../combat/Battle';
import type { PalState } from '../party/Pal';

/**
 * The combat HUD. Swaps in over the exploration HUD when a fight starts.
 *
 * Two decisions here are worth stating.
 *
 * The throw is armed and released by two taps rather than a drag-and-release
 * arc. GAME_DESIGN.md describes a drag with a trajectory preview, but the part
 * that carries the mechanic is the shrinking catch ring, and a drag gesture
 * competes with the camera drag on a phone. Two taps keep the timing skill and
 * lose only the preview line. Logged in DECISIONS.md.
 *
 * The attack button is one button: tap for quick, hold for power. The design
 * asks for exactly that, and it means the primary combat verb never moves.
 */

export interface OrbOption {
  id: string;
  name: string;
  count: number;
  ballMod: number;
}

export class CombatOverlay {
  readonly root: HTMLElement;

  private readonly enemyName: HTMLElement;
  private readonly enemyFill: HTMLElement;
  private readonly enemyTag: HTMLElement;
  private readonly allyName: HTMLElement;
  private readonly allyFill: HTMLElement;
  private readonly chargeFill: HTMLElement;
  private readonly telegraph: HTMLElement;
  private readonly slotRow: HTMLElement;
  private readonly orbRow: HTMLElement;
  private readonly ringWrap: HTMLElement;
  private readonly ring: HTMLElement;
  private readonly log: HTMLElement;
  private readonly attackButton: HTMLButtonElement;

  /** Set while the ring is up, so release knows which orb is in hand. */
  private armedOrb: OrbOption | null = null;
  private ringElapsedMs = 0;
  private holdStartMs = 0;
  private holding = false;

  onQuick: (() => void) | null = null;
  onPower: (() => void) | null = null;
  onDodge: (() => void) | null = null;
  onThrow: ((orb: OrbOption, quality: RingQuality) => void) | null = null;
  onSwap: ((index: number) => void) | null = null;
  onFlee: (() => void) | null = null;

  constructor(parent: HTMLElement = document.body) {
    this.enemyName = el('div', 'cb__name');
    this.enemyFill = el('i', 'bar__fill bar__fill--enemy');
    this.enemyTag = el('span', 'cb__tag');
    this.telegraph = el('div', 'cb__telegraph', 'INCOMING');
    this.telegraph.hidden = true;

    const enemyBlock = el(
      'div',
      'cb__enemy',
      el('div', 'cb__row', this.enemyName, this.enemyTag),
      el('div', 'bar bar--enemy', this.enemyFill),
      this.telegraph
    );

    this.allyName = el('div', 'cb__name');
    this.allyFill = el('i', 'bar__fill bar__fill--health');
    this.chargeFill = el('i', 'bar__fill bar__fill--charge');
    const allyBlock = el(
      'div',
      'cb__ally',
      this.allyName,
      el('div', 'bar', this.allyFill),
      el('div', 'bar bar--charge', this.chargeFill)
    );

    this.log = el('div', 'cb__log');

    // The throw ring. A circle that shrinks; tapping while it is small is the
    // whole skill expression of the capture.
    this.ring = el('div', 'ring__mark');
    this.ringWrap = el(
      'div',
      'ring',
      this.ring,
      el('div', 'ring__hint', 'Tap to release')
    );
    this.ringWrap.hidden = true;
    this.ringWrap.addEventListener('pointerdown', (event) => {
      event.preventDefault();
      this.releaseThrow();
    });

    this.attackButton = this.buildAttackButton();

    const dodge = tapButton('Dodge', 'cb__btn cb__btn--dodge', () => this.onDodge?.());
    const flee = this.buildFleeButton();

    this.orbRow = el('div', 'cb__orbs');
    this.slotRow = el('div', 'cb__slots');

    this.root = el(
      'div',
      'cb',
      enemyBlock,
      this.log,
      this.ringWrap,
      el('div', 'cb__bottom', allyBlock, this.orbRow, el('div', 'cb__actions', dodge, this.attackButton, flee), this.slotRow)
    );
    this.root.hidden = true;
    parent.append(this.root);
  }

  /**
   * One button, two verbs. Held past the charge threshold it becomes the power
   * attack; released before that it is a quick attack.
   */
  private buildAttackButton(): HTMLButtonElement {
    const button = el('button', 'cb__btn cb__btn--attack');
    button.type = 'button';
    button.textContent = 'Attack';

    const down = (event: Event): void => {
      event.preventDefault();
      this.holding = true;
      this.holdStartMs = performance.now();
      button.classList.add('is-charging');
    };
    const up = (event: Event): void => {
      event.preventDefault();
      if (!this.holding) return;
      this.holding = false;
      button.classList.remove('is-charging');
      const held = performance.now() - this.holdStartMs;
      if (held >= combat.charge.holdToChargeMs) this.onPower?.();
      else this.onQuick?.();
    };

    button.addEventListener('pointerdown', down);
    button.addEventListener('pointerup', up);
    // A pointer that leaves the button still has to resolve, or the charge
    // sticks on and the next tap fires a power attack the player did not ask
    // for.
    button.addEventListener('pointercancel', up);
    button.addEventListener('pointerleave', up);
    return button;
  }

  /** Flee is a hold, per the design, so it is never a mis-tap. */
  private buildFleeButton(): HTMLButtonElement {
    const button = el('button', 'cb__btn cb__btn--flee');
    button.type = 'button';
    button.textContent = 'Back';
    let timer = 0;
    const start = (event: Event): void => {
      event.preventDefault();
      button.classList.add('is-holding');
      timer = window.setTimeout(() => {
        button.classList.remove('is-holding');
        this.onFlee?.();
      }, 1000);
    };
    const stop = (): void => {
      window.clearTimeout(timer);
      button.classList.remove('is-holding');
    };
    button.addEventListener('pointerdown', start);
    button.addEventListener('pointerup', stop);
    button.addEventListener('pointerleave', stop);
    button.addEventListener('pointercancel', stop);
    return button;
  }

  open(orbs: OrbOption[], party: readonly PalState[]): void {
    this.root.hidden = false;
    clear(this.log);
    this.setOrbs(orbs);
    this.setSlots(party, 0);
    this.cancelThrow();
  }

  close(): void {
    this.root.hidden = true;
    this.cancelThrow();
  }

  setOrbs(orbs: OrbOption[]): void {
    clear(this.orbRow);
    if (orbs.length === 0) {
      this.orbRow.append(el('div', 'cb__noorbs', 'No orbs'));
      return;
    }
    for (const orb of orbs) {
      const button = tapButton(`${orb.name} ${orb.count}`, 'cb__orb', () => this.armThrow(orb));
      button.disabled = orb.count <= 0;
      this.orbRow.append(button);
    }
  }

  setSlots(party: readonly PalState[], activeIndex: number): void {
    clear(this.slotRow);
    party.forEach((pal, index) => {
      const button = tapButton(
        `${index + 1}`,
        `cb__slot${index === activeIndex ? ' is-active' : ''}${pal.hp <= 0 ? ' is-out' : ''}`,
        () => this.onSwap?.(index)
      );
      button.disabled = pal.hp <= 0 || index === activeIndex;
      this.slotRow.append(button);
    });
  }

  private armThrow(orb: OrbOption): void {
    if (orb.count <= 0) return;
    this.armedOrb = orb;
    this.ringElapsedMs = 0;
    this.ringWrap.hidden = false;
  }

  private releaseThrow(): void {
    const orb = this.armedOrb;
    if (!orb) return;
    const quality = ringQuality(ringRadiusAt(this.ringElapsedMs));
    this.cancelThrow();
    this.onThrow?.(orb, quality);
  }

  cancelThrow(): void {
    this.armedOrb = null;
    this.ringWrap.hidden = true;
  }

  get isArmed(): boolean {
    return this.armedOrb !== null;
  }

  /** Repaint from the live battle. Called every frame while combat runs. */
  update(battle: Battle, dtMs: number): void {
    const enemy = battle.activeEnemy;
    if (enemy) {
      this.enemyName.textContent = `${enemy.name}  L${enemy.level}`;
      setFill(this.enemyFill, enemy.hp / Math.max(1, enemy.maxHp));
      // The collar is the read that says "do not spend an orb here".
      show(this.enemyTag, enemy.collared);
      this.enemyTag.textContent = 'COLLARED';
    }

    const ally = battle.activeAlly;
    if (ally) {
      const locked = ally.level < POWER_UNLOCK_LEVEL;
      this.allyName.textContent = `${ally.name}  L${ally.level}`;
      setFill(this.allyFill, ally.hp / Math.max(1, ally.maxHp));
      setFill(this.chargeFill, ally.charge / combat.charge.max);
      this.attackButton.classList.toggle('is-ready', !locked && ally.charge >= combat.charge.powerCost);
    }

    this.telegraph.hidden = !battle.enemyTelegraphing;
    this.attackButton.disabled = !battle.canAct;

    if (this.armedOrb) {
      this.ringElapsedMs += dtMs;
      const radius = ringRadiusAt(this.ringElapsedMs);
      // Scale from a comfortable maximum down to the tight window.
      this.ring.style.transform = `scale(${0.25 + radius * 0.95})`;
      this.ring.dataset.quality = ringQuality(radius);
    }
  }

  /** One line of combat feedback. Damage numbers arrive properly at M5. */
  say(message: string, tone: 'plain' | 'good' | 'bad' = 'plain'): void {
    const line = el('div', `cb__line cb__line--${tone}`, message);
    this.log.append(line);
    while (this.log.childElementCount > 3) this.log.firstElementChild?.remove();
    window.setTimeout(() => line.remove(), 2600);
  }

  dispose(): void {
    this.root.remove();
  }
}
