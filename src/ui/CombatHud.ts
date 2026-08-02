import type { CombatMode } from '../combat/CombatMode';
import { TIMING } from '../combat/MoveResolver';
import { speciesDef } from '../entities/Species';
import type { Party } from '../party/Party';
import type { ReleaseFlow } from '../party/Release';

/**
 * The combat overlay: enemy bar, active pal bar, charge, catch ring, party pips.
 *
 * DOM, not in-canvas, per ARCHITECTURE.md. Shown and hidden rather than built
 * and torn down, because Combat Mode is a state and the HUD swap should cost
 * nothing.
 */

export class CombatHud {
  private lastText = '';
  private throwNote = '';
  private throwSteps = 0;

  constructor(
    private readonly root: HTMLElement,
    private readonly combat: CombatMode,
    private readonly party: Party,
    private readonly release: ReleaseFlow
  ) {}

  /** Report what a throw did, so a bounce reads differently from a miss. */
  reportThrow(outcome: string): void {
    const notes: Record<string, string> = {
      'no-orbs': 'No orbs left',
      bounced: 'The orb bounced off. That one is collared.',
      missed: 'It broke free',
      caught: 'Caught',
      'not-fighting': ''
    };
    this.throwNote = notes[outcome] ?? '';
    this.throwSteps = this.throwNote ? 180 : 0;
  }

  /** Called once per fixed step. */
  update(day: number): void {
    if (this.throwSteps > 0) this.throwSteps--;
    if (this.release.stage !== 'closed') {
      this.root.hidden = false;
      this.paintRelease(day);
      return;
    }

    if (!this.combat.isFighting) {
      if (!this.root.hidden) {
        this.root.hidden = true;
        this.lastText = '';
      }
      return;
    }

    this.root.hidden = false;
    this.paintFight();
  }

  private paintFight(): void {
    const s = this.combat.snapshot();
    if (!s.enemy || !s.active) return;

    const enemyName = speciesDef(s.enemy.species)?.name ?? s.enemy.species;
    const activeName = speciesDef(s.active.species)?.name ?? s.active.species;
    const charged = s.charge >= TIMING.powerChargeCost;

    const lines = [
      `${enemyName} Lv${s.enemy.level}   ${bar(s.enemy.currentHp, s.enemyMaxHp)}`,
      s.telegraphing ? 'INCOMING  dodge now' : '',
      `${activeName} Lv${s.active.level}   ${bar(s.active.currentHp, s.activeMaxHp)}`,
      `charge ${Math.round(s.charge)}${charged ? '  POWER READY' : ''}`,
      `ring ${bar(Math.round((1 - s.ringProgress) * 100), 100)}   R / B to throw`,
      this.throwSteps > 0 ? this.throwNote : '',
      this.pips()
    ].filter(Boolean);

    this.paint(lines.join('\n'));
  }

  /**
   * The release screen. Level, affinity and time held, exactly as section 11
   * asks, because the whole point is that the player sees what they are giving
   * up rather than a list of names.
   */
  private paintRelease(day: number): void {
    const candidates = this.release.candidates(day);
    const header =
      this.release.stage === 'confirming'
        ? 'RELEASE  this is permanent. Confirm again, or cancel.'
        : 'PARTY FULL  choose who walks away. This cannot be undone.';

    const rows = candidates.map((c, i) => {
      const mark = c.pal.uid === this.release.selectedUid ? '>' : ' ';
      const tag = c.isNewcomer ? '  (new)' : '';
      return `${mark}${i + 1}. ${c.speciesName} Lv${c.level}   affinity ${c.affinity}   ${c.daysHeld}d${tag}`;
    });

    this.paint([header, ...rows].join('\n'));
  }

  private pips(): string {
    return this.party.members
      .map((p, i) => {
        const active = i === this.party.activeSlot ? '*' : ' ';
        return `${active}${i + 1}${p.fainted ? 'x' : ''}`;
      })
      .join(' ');
  }

  private paint(text: string): void {
    if (text === this.lastText) return;
    this.lastText = text;
    this.root.textContent = text;
  }
}

function bar(current: number, max: number, width = 14): string {
  if (max <= 0) return '';
  const filled = Math.max(0, Math.min(width, Math.round((current / max) * width)));
  return `${'#'.repeat(filled)}${'.'.repeat(width - filled)} ${current}/${max}`;
}
