import { bus } from '../core/EventBus';
import type { Input } from '../core/input/Input';
import type { CombatMode } from '../combat/CombatMode';
import type { WildPal } from '../entities/SpawnManager';
import { createPal } from '../entities/Species';
import type { Party } from '../party/Party';
import type { ReleaseFlow } from '../party/Release';
import type { PalState } from '../party/PalState';
import { add, type Slots } from '../survival/Inventory';
import { DialogueRunner, parseEffect } from '../ui/DialogueRunner';
import type { DialoguePanel } from '../ui/DialoguePanel';
import type { HUD } from '../ui/HUD';
import { hashSeed, mulberry32 } from '../world/gen/Rng';
import { buildTeam, encounterDef, encounterIds, rewardFor } from './Encounters';
import type { WorldHandle } from './World';

/**
 * M3 and M4: the people, the conversations, and the fights that are scripted
 * rather than found.
 *
 * This is the layer that turns a survival sandbox into a game with a beginning
 * and a win state. It owns progress flags, badges, who is standing where, and
 * the Hall sequence. It does NOT own combat: it hands a team to `CombatMode`
 * one pal at a time and watches for the outcome, exactly as a wild encounter
 * does, so there is one fight implementation rather than two.
 *
 * Trainer pals are synthesised into the `WildPal` shape with no mesh.
 * `CombatMode` only ever reads `.state`, so a collared Loamking that exists
 * only as numbers fights identically to one standing in a field. If that ever
 * stops being true, this is the file that has to grow a mesh.
 */

/** Reach for talking to somebody, in metres. Generous, per the harvest reach. */
const TALK_RANGE = 4.5;

export interface StoryProgress {
  badges: string[];
  flags: string[];
}

export class Story {
  private readonly flagSet = new Set<string>();
  private readonly badgeList: string[] = [];
  private readonly runner = new DialogueRunner();

  /** The trainer fight in progress, if any. */
  private activeEncounter: string | null = null;
  private queue: PalState[] = [];
  private interactWasDown = false;

  constructor(
    private readonly world: WorldHandle,
    private readonly party: Party,
    private readonly combat: CombatMode,
    private readonly release: ReleaseFlow,
    private readonly slots: Slots,
    private readonly input: Input,
    private readonly hud: HUD,
    private readonly panel: DialoguePanel,
    private readonly seed: string
  ) {
    // The panel is a view: it renders a line and reports taps. The runner owns
    // where the conversation is. Story is the only thing that knows both.
    this.panel.onAdvance = (): void => this.step(() => this.runner.advance());
    this.panel.onChoose = (index): void => this.step(() => this.runner.choose(index));
  }

  /** Move the conversation, then repaint or close it. */
  private step(move: () => void): void {
    move();
    this.render();
  }

  private render(): void {
    const line = this.runner.line;
    if (!line || !this.runner.isActive) {
      this.panel.hide();
      // Effects are drained on close rather than per line, so a conversation
      // that hands over a starter and then says goodbye does both in order and
      // neither lands while the panel is still covering the screen.
      this.applyEffects();
      return;
    }
    this.panel.show(line);
  }

  get flags(): readonly string[] {
    return [...this.flagSet];
  }

  get badges(): readonly string[] {
    return this.badgeList;
  }

  has(flag: string): boolean {
    return this.flagSet.has(flag);
  }

  get isTalking(): boolean {
    return this.runner.isActive;
  }

  /** True while a scripted fight is running, so the wild spawner stands down. */
  get inScriptedFight(): boolean {
    return this.activeEncounter !== null;
  }

  /** One fixed step. Returns true when it consumed the interact press. */
  update(x: number, z: number, yaw: number): boolean {
    this.hud.updateCompass(x, z, yaw, this.world.markers);

    if (this.activeEncounter) {
      this.advanceScripted();
      return false;
    }

    if (this.runner.isActive) {
      // While talking, interact advances the conversation and nothing else.
      if (this.pressedInteract()) this.step(() => this.runner.advance());
      this.hud.setPrompt(null);
      return true;
    }

    const npc = this.world.npcs.nearest(x, z, TALK_RANGE);
    this.hud.setPrompt(npc ? `Talk to ${npc.name}` : null);
    if (!npc) {
      this.pressedInteract();
      return false;
    }

    if (this.pressedInteract()) {
      npc.faceToward(x, z);
      this.talk(npc.dialogue);
      return true;
    }
    return false;
  }

  /** Rising edge only. A held button must not spam a conversation forward. */
  private pressedInteract(): boolean {
    const down = this.input.intent.interact;
    const pressed = down && !this.interactWasDown;
    this.interactWasDown = down;
    return pressed;
  }

  private talk(conversationId: string): void {
    if (!this.runner.start(conversationId)) return;
    this.render();
  }

  /**
   * Dialogue effects are opaque strings the story applies, so `dialogue.json`
   * can name an outcome without the dialogue system knowing what any of them
   * mean.
   */
  private applyEffects(): void {
    for (const raw of this.runner.drainEffects()) {
      const { kind, value } = parseEffect(raw);
      switch (kind) {
        case 'flag':
          this.flagSet.add(value);
          break;
        case 'starter':
          this.grantStarter(value);
          break;
        case 'give':
          this.give(value);
          break;
        case 'fight':
          this.startScripted(value);
          break;
        default:
          console.warn(`[story] unknown dialogue effect "${raw}"`);
      }
    }
    this.hud.updateParty(this.party);
  }

  /** `give:worn_orb:3` */
  private give(value: string): void {
    const [id, n] = value.split(':');
    if (!id) return;
    add(this.slots, id, Number(n ?? 1));
    bus.emit('inventoryChanged', {});
  }

  private grantStarter(speciesId: string): void {
    if (this.party.size > 0 && this.has('took_starter')) return;
    const rand = mulberry32(hashSeed(this.seed, `starter:${speciesId}`.length));
    const pal = createPal(speciesId, 5, 1, performance.now(), rand, `starter:${speciesId}`);
    this.party.add(pal);
    this.flagSet.add('took_starter');
    this.hud.toast(`${pal.species} joined you`, 'good');
  }

  // ---- scripted fights ----------------------------------------------------

  private startScripted(encounterId: string): void {
    const def = encounterDef(encounterId);
    if (!def) {
      console.error(`[story] unknown encounter "${encounterId}"`);
      return;
    }
    if (this.party.size === 0 || this.party.allFainted) {
      this.hud.toast('Your pals cannot fight', 'bad');
      return;
    }

    this.activeEncounter = encounterId;
    this.queue = buildTeam(
      def,
      (index) => mulberry32(hashSeed(this.seed, `${def.id}:${index}`.length + index)),
      1,
      performance.now()
    );
    this.sendNext();
  }

  /** Put the next collared pal in front of the player. */
  private sendNext(): boolean {
    const next = this.queue.shift();
    if (!next) return false;
    this.combat.enter(asWild(next));
    return true;
  }

  /**
   * Watch the fight the trainer is running.
   *
   * Losing to a trainer ends the whole encounter; winning sends the next pal
   * until the team is empty. Nothing here touches the fight itself.
   */
  private advanceScripted(): void {
    const phase = this.combat.phase;
    if (phase === 'fighting') return;

    const encounterId = this.activeEncounter;
    if (!encounterId) return;

    if (phase === 'won') {
      this.combat.reset();
      if (this.sendNext()) return;
      this.finish(encounterId);
      return;
    }

    if (phase === 'lost' || phase === 'fled') {
      this.combat.reset();
      this.queue = [];
      this.activeEncounter = null;
      this.hud.toast('You were driven back', 'bad');
      return;
    }

    // 'caught' is unreachable: every pal here is collared and the orb bounces.
    this.combat.reset();
  }

  private finish(encounterId: string): void {
    const def = encounterDef(encounterId);
    this.activeEncounter = null;
    this.queue = [];
    if (!def) return;

    this.flagSet.add(def.flag);
    const npc = this.world.npcs.byId(encounterId);
    if (npc) npc.dialogue = def.afterDialogue;

    const reward = rewardFor(encounterId);
    if (!reward) {
      this.hud.toast(`${def.name} defeated`, 'good');
      return;
    }

    // Rewards land on the victory, not on the last hit, so closing the tab
    // mid-sequence cannot cost the badge.
    for (const flag of reward.flags) this.flagSet.add(flag);
    for (const item of reward.items) add(this.slots, item.id, item.n);
    if (reward.badge) {
      this.badgeList.push(reward.badge.id);
      this.hud.toast(`${reward.badge.name} earned`, 'sigil');
    }
    if (reward.freed > 0) {
      this.hud.toast(`${reward.freed} pals cut free`, 'good');
    }
    if (reward.recruit) this.offerRecruit(reward.recruit);
    bus.emit('inventoryChanged', {});
  }

  /**
   * The Warden's own pal asks to come along. If the party is full this is the
   * five-slot rule at its sharpest, so it goes through `Party.add()` like every
   * other capture and opens the release screen when it is refused.
   */
  private offerRecruit(recruit: { species: string; level: number; dialogue: string }): void {
    const rand = mulberry32(hashSeed(this.seed, `recruit:${recruit.species}`.length));
    const pal = createPal(
      recruit.species,
      recruit.level,
      1,
      performance.now(),
      rand,
      `recruit:${recruit.species}`
    );
    const added = this.party.add(pal);
    if (added.ok) {
      this.hud.toast(`${recruit.species} joined you`, 'good');
      return;
    }
    if (added.needsRelease) this.release.open(added.roster, pal);
  }

  // ---- save ---------------------------------------------------------------

  snapshot(): StoryProgress {
    return { badges: [...this.badgeList], flags: [...this.flagSet] };
  }

  restore(progress: StoryProgress): void {
    this.flagSet.clear();
    for (const flag of progress.flags) this.flagSet.add(flag);
    this.badgeList.length = 0;
    this.badgeList.push(...progress.badges);
    this.syncNpcDialogue();
  }

  /** A beaten trainer says something different next time. */
  private syncNpcDialogue(): void {
    for (const id of encounterIds()) {
      const def = encounterDef(id);
      const npc = this.world.npcs.byId(id);
      if (def && npc && this.flagSet.has(def.flag)) npc.dialogue = def.afterDialogue;
    }
  }
}

/**
 * Wrap a bare pal in the shape `CombatMode` expects.
 *
 * No mesh, because a trainer's pal is never in the world to be walked up to;
 * it exists for the length of one fight. `CombatMode` reads only `.state`.
 */
function asWild(state: PalState): WildPal {
  return {
    state,
    ai: { mood: 'aggro', timer: 0, heading: 0, homeX: 0, homeZ: 0 },
    mesh: null,
    x: 0,
    y: 0,
    z: 0,
    yaw: 0,
    active: true
  };
}
