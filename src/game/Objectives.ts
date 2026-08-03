import { count, type Slots } from '../survival/Inventory';
import type { Party } from '../party/Party';
import type { CompassMarker } from '../ui/HUD';
import type { HUD } from '../ui/HUD';
import type { Story } from './Story';
import objectivesData from '../data/objectives.json';

/**
 * The opening objective chain: docs/01_GAME_DESIGN.md section 3, "the first fifteen
 * minutes". Wake up, talk to Grandpa Orin, catch a tuftmoth, head east.
 *
 * A short, ordered, one-way list. It never looks backward: once a step's
 * predicate is met the chain advances and does not re-check it, so a flag
 * that later gets cleared (there is no such flag today, but nothing here
 * should assume there never will be) cannot walk the prompt back a step.
 *
 * This owns none of the state it reads. It is a read-only view over Story's
 * flags, the Party's size and the inventory's counts, the same way HUD is a
 * read-only view over the game. That is what keeps a HUD repaint from being
 * able to change the game, and it is exactly as true of the objective prompt.
 */

export type ObjectivePredicate =
  | { kind: 'flag'; flag: string }
  | { kind: 'partySize'; n: number }
  | { kind: 'itemCount'; item: string; n: number };

export interface ObjectiveStep {
  id: string;
  prompt: string;
  marker?: { label: string; x: number; z: number };
  predicate: ObjectivePredicate;
}

export interface ObjectiveContext {
  hasFlag(flag: string): boolean;
  partySize: number;
  itemCount(item: string): number;
}

const STEPS = objectivesData.steps as ObjectiveStep[];

/**
 * Pure. Tested on its own before anything wires it to Story, Party or the
 * inventory (CLAUDE.md: write the test before the formula for anything in
 * combat/ or party/; this is the same discipline applied to the one other
 * place a save-driven predicate decides game state).
 */
export function evaluatePredicate(predicate: ObjectivePredicate, ctx: ObjectiveContext): boolean {
  switch (predicate.kind) {
    case 'flag':
      return ctx.hasFlag(predicate.flag);
    case 'partySize':
      return ctx.partySize >= predicate.n;
    case 'itemCount':
      return ctx.itemCount(predicate.item) >= predicate.n;
  }
}

export class Objectives {
  private index = 0;

  constructor(
    private readonly story: Story,
    private readonly party: Party,
    private readonly slots: Slots,
    private readonly hud: HUD
  ) {
    // Catch up silently on construction, after a save restore. A loaded game
    // that is already past "talk to Orin" must not toast that step complete
    // the moment the world finishes booting.
    while (this.index < STEPS.length && this.currentIsMet()) this.index++;
  }

  /** One fixed step. Advances at most one step per call; the next frame
   *  catches any further step that was also already satisfied. */
  update(): void {
    if (this.index >= STEPS.length) return;
    if (!this.currentIsMet()) return;
    this.hud.toast(STEPS[this.index]!.prompt, 'good');
    this.index++;
  }

  /** The current step's id, or null once the chain is finished. Lets a
   *  caller trigger a one-time side effect (spawning the scripted tuftmoth)
   *  exactly while its step is the active one. */
  get currentId(): string | null {
    return STEPS[this.index]?.id ?? null;
  }

  get prompt(): string | null {
    return STEPS[this.index]?.prompt ?? null;
  }

  get markers(): CompassMarker[] {
    const step = STEPS[this.index];
    if (!step?.marker) return [];
    return [{ label: step.marker.label, x: step.marker.x, z: step.marker.z, kind: 'objective' }];
  }

  get done(): boolean {
    return this.index >= STEPS.length;
  }

  private currentIsMet(): boolean {
    const step = STEPS[this.index];
    if (!step) return false;
    return evaluatePredicate(step.predicate, {
      hasFlag: (flag) => this.story.has(flag),
      partySize: this.party.size,
      itemCount: (item) => count(this.slots, item)
    });
  }
}

/** Where and what the guaranteed opening catch spawns as. Data-driven per
 *  CLAUDE.md: every tunable number lives in src/data/*.json. */
export const TUFTMOTH_SPAWN = objectivesData.tuftmothSpawn as { x: number; z: number; level: number };
