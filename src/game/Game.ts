import { FreeCamera, Scene, ShadowGenerator, Vector3 } from '../core/babylon';
import items from '../data/items.json';
import { bus } from '../core/EventBus';
import type { Input } from '../core/input/Input';
import { hashSeed, mulberry32, subRng } from '../world/gen/Rng';
import type { Terrain } from '../world/gen/Terrain';
import type { TimeOfDay } from '../world/TimeOfDay';
import type { Player } from '../entities/Player';
import { SpawnManager, type WildPal } from '../entities/SpawnManager';
import { CombatMode } from './CombatMode';
import type { BattleEvent, Outcome } from '../combat/Battle';
import { Party } from '../party/Party';
import { makePal, type PalState } from '../party/Pal';
import { awardXp, benchShare, tickRevive } from '../party/Progression';
import { requireSpecies } from '../party/Species';
import { add as addItem, count as countItem, createInventory, remove as removeItem, type Slots } from '../survival/Inventory';
import { createVitals, tickVitals, revive as revivePlayer } from '../survival/Vitals';
import { HUD, type CompassMarker } from '../ui/HUD';
import { CombatOverlay, type OrbOption } from '../ui/CombatOverlay';
import { DialoguePanel, VictoryScreen } from '../ui/DialoguePanel';
import { PartyScreen, ReleaseScreen } from '../ui/ReleaseScreen';
import { DialogueRunner, parseEffect } from '../ui/DialogueRunner';
import { buildTeam, encounterDef, rewardFor } from './Encounters';
import { buildWorld, type WorldHandle } from './World';
import { SaveManager, type SaveV1 } from '../core/SaveManager';

/**
 * The orchestrator. Owns game state and routes between modes.
 *
 * Everything here is wiring. The rules live in the systems this calls: the cap
 * in Party, the maths in Damage and Throw, the fight in Battle, the words in
 * dialogue.json. If a rule appears in this file it is in the wrong place.
 */

export type Mode = 'explore' | 'dialogue' | 'combat' | 'release' | 'victory' | 'party';

const ORB_IDS = Object.entries(items as Record<string, { kind?: string; orb?: { ballMod: number }; name?: string }>)
  .filter(([id, def]) => !id.startsWith('$') && def.kind === 'orb')
  .map(([id, def]) => ({ id, name: def.name ?? id, ballMod: def.orb?.ballMod ?? 1 }));

export interface GameContext {
  scene: Scene;
  camera: FreeCamera;
  shadows: ShadowGenerator | null;
  terrain: Terrain;
  seed: string;
  player: Player;
  time: TimeOfDay;
  input: Input;
}

export class Game {
  readonly world: WorldHandle;
  readonly party = new Party();
  readonly spawns: SpawnManager;

  private readonly hud = new HUD();
  private readonly overlay = new CombatOverlay();
  private readonly dialoguePanel = new DialoguePanel();
  private readonly victoryScreen = new VictoryScreen();
  private readonly releaseScreen = new ReleaseScreen();
  private readonly partyScreen = new PartyScreen();
  private readonly runner = new DialogueRunner();
  private readonly combatMode: CombatMode;
  private readonly saves = new SaveManager();

  private inventory: Slots = createInventory();
  private vitals = createVitals();
  private readonly flags = new Set<string>();
  private readonly badges: string[] = [];

  mode: Mode = 'explore';
  private activeWild: WildPal | null = null;
  private activeEncounter: string | null = null;
  private fightCount = 0;
  private autosaveMs = 0;
  private hudMs = 0;
  private respawn: Vector3 | null = null;
  private satchel: { pos: Vector3; items: { id: string; n: number; dur?: number }[] } | null = null;

  constructor(private readonly ctx: GameContext) {
    this.world = buildWorld(ctx.scene, ctx.terrain, ctx.seed, ctx.shadows);
    this.spawns = new SpawnManager(ctx.scene, ctx.terrain, ctx.seed, ctx.shadows);
    this.combatMode = new CombatMode({
      scene: ctx.scene,
      camera: ctx.camera,
      shadows: ctx.shadows,
      heightAt: (x, z) => ctx.terrain.heightAt(x, z)
    });

    this.wireUi();
    // Three Worn Pact Orbs and a stone axe, per Orin's satchel.
    addItem(this.inventory, 'worn_orb', 3);
    addItem(this.inventory, 'stone_axe', 1);
  }

  // ---- setup -------------------------------------------------------------

  private wireUi(): void {
    this.hud.onInteract = (): void => this.interact();
    this.hud.onPartyTap = (): void => this.openParty();

    this.dialoguePanel.onAdvance = (): void => {
      this.runner.advance();
      this.applyEffects();
      this.drawDialogue();
    };
    this.dialoguePanel.onChoose = (index): void => {
      this.runner.choose(index);
      this.applyEffects();
      this.drawDialogue();
    };

    this.overlay.onQuick = (): void => {
      if (this.combatMode.current?.quickAttack()) this.combatMode.lunge('ally');
    };
    this.overlay.onPower = (): void => {
      if (this.combatMode.current?.powerAttack()) this.combatMode.lunge('ally');
    };
    this.overlay.onDodge = (): void => {
      this.combatMode.current?.dodge();
    };
    this.overlay.onSwap = (index): void => {
      if (this.combatMode.current?.swapTo(index)) this.combatMode.refreshMeshes();
    };
    this.overlay.onFlee = (): void => {
      this.combatMode.current?.flee();
    };
    this.overlay.onThrow = (orb, quality): void => {
      const battle = this.combatMode.current;
      if (!battle) return;
      // The orb is spent on release, before the result is known. A throw that
      // only costs you when it fails is not a decision.
      if (!removeItem(this.inventory, orb.id, 1)) return;
      battle.throwOrb(orb.ballMod, quality, this.party.highestLevel);
      this.overlay.setOrbs(this.orbOptions());
    };

    this.releaseScreen.onRelease = (uid): void => {
      const record = this.party.resolvePending(uid, this.ctx.time.day);
      this.hud.toast(`${record.name} is gone`, 'bad');
      this.hud.updateParty(this.party);
      bus.emit('partyChanged', {});
      this.setMode('explore');
    };

    this.victoryScreen.onDismiss = (): void => this.afterVictory();
  }

  // ---- the frame ---------------------------------------------------------

  /** One fixed simulation step. */
  update(dtMs: number): void {
    const dt = dtMs / 1000;
    const px = this.ctx.player.state.position.x;
    const pz = this.ctx.player.state.position.z;

    if (this.mode === 'combat') {
      this.combatMode.update(dtMs);
      const battle = this.combatMode.current;
      if (battle) {
        this.overlay.update(battle, dtMs);
        if (battle.isOver && battle.outcome) this.endCombat(battle.outcome);
      }
    } else {
      // Vitals only tick outside a fight. Starving to death mid-throw would be
      // a bad way to lose a pal you had already earned.
      tickVitals(this.vitals, dtMs, this.ctx.input.intent.sprint);
      if (this.vitals.fainted) this.faint();
      this.spawns.update(dtMs, px, pz, this.ctx.time.cycle, this.ctx.time.day);
    }

    // Fainted pals recover wherever the player is. The campfire shortcut lands
    // with the rest of M1's stations.
    for (const pal of this.party.members) tickRevive(pal, dtMs, false);

    this.collectSatchel(px, pz);

    // The HUD repaints at 10Hz, not 60. Every one of these rebuilds DOM (the
    // compass drops and recreates a pin per marker), and doing that on every
    // fixed step was measurably starving chunk streaming at boot: the smoke
    // spec's chunk count fell by one. Nothing here changes fast enough for a
    // player to see the difference, and the simulation is untouched.
    this.hudMs -= dtMs;
    if (this.hudMs <= 0) {
      this.hudMs = HUD_REFRESH_MS;
      this.updatePrompt(px, pz);
      this.hud.updateVitals(this.vitals);
      this.hud.updateDay(this.ctx.time.day, this.ctx.time.isNight);
      this.hud.updateCompass(px, pz, this.ctx.player.cameraYaw, this.markers());
    }

    this.autosaveMs -= dtMs;
    if (this.autosaveMs <= 0) {
      this.autosaveMs = 60_000;
      this.save();
    }
    void dt;
  }

  /** Render-rate work: pal bobbing only. */
  animate(elapsedMs: number): void {
    if (this.mode !== 'combat') this.spawns.animate(elapsedMs);
  }

  private markers(): CompassMarker[] {
    const base = [...this.world.markers];
    if (this.satchel) {
      base.push({ label: 'Satchel', x: this.satchel.pos.x, z: this.satchel.pos.z, kind: 'satchel' });
    }
    return base;
  }

  // ---- interaction -------------------------------------------------------

  private updatePrompt(px: number, pz: number): void {
    if (this.mode !== 'explore') {
      this.hud.setPrompt(null);
      return;
    }
    const npc = this.world.npcs.nearest(px, pz, 3.4);
    if (npc) {
      this.hud.setPrompt(`Talk to ${npc.name}`);
      return;
    }
    const wild = this.spawns.encounterAt(px, pz);
    this.hud.setPrompt(wild ? `Fight ${wild.pal.name} L${wild.pal.level}` : null);
  }

  private interact(): void {
    if (this.mode !== 'explore') return;
    const px = this.ctx.player.state.position.x;
    const pz = this.ctx.player.state.position.z;

    const npc = this.world.npcs.nearest(px, pz, 3.4);
    if (npc) {
      npc.faceToward(px, pz);
      this.startDialogue(npc.dialogue);
      return;
    }
    const wild = this.spawns.encounterAt(px, pz);
    if (wild) this.startWildFight(wild);
  }

  // ---- dialogue ----------------------------------------------------------

  startDialogue(id: string): void {
    if (!this.runner.start(id)) return;
    this.setMode('dialogue');
    this.applyEffects();
    this.drawDialogue();
  }

  private drawDialogue(): void {
    const line = this.runner.line;
    if (!line || !this.runner.isActive) {
      this.dialoguePanel.hide();
      // A dialogue effect may already have moved us into a fight or a cutscene;
      // only fall back to exploring if nothing else claimed the mode.
      if (this.mode === 'dialogue') this.setMode('explore');
      return;
    }
    this.dialoguePanel.show(line);
  }

  /** Apply whatever the runner produced. Unknown effects are loud, not fatal. */
  private applyEffects(): void {
    for (const raw of this.runner.drainEffects()) {
      const { kind, value } = parseEffect(raw);
      switch (kind) {
        case 'flag':
          this.flags.add(value);
          break;
        case 'starter':
          this.giveStarter(value);
          break;
        case 'fight':
          this.pendingFight = value;
          break;
        case 'recruit':
          this.recruit(value, 17);
          break;
        case 'victory':
          this.pendingVictory = value;
          break;
        default:
          console.error(`[game] unknown dialogue effect "${raw}"`);
      }
    }
  }

  private pendingFight: string | null = null;
  private pendingVictory: string | null = null;

  private giveStarter(speciesId: string): void {
    const def = requireSpecies(speciesId);
    const pal = makePal(def.id, STARTER_LEVEL, subRng(this.ctx.seed, `starter:${def.id}`), {
      caughtDay: this.ctx.time.day
    });
    this.party.add(pal);
    this.hud.updateParty(this.party);
    this.hud.toast(`${def.name} joins you`, 'good');
    bus.emit('partyChanged', {});
  }

  // ---- combat ------------------------------------------------------------

  private combatRandom(): () => number {
    return mulberry32(hashSeed(`${this.ctx.seed}:fight`, this.fightCount++));
  }

  private canFight(): boolean {
    if (this.party.size === 0) {
      this.hud.toast('You have no pals. Talk to Orin.', 'bad');
      return false;
    }
    if (this.party.allFainted) {
      this.hud.toast('Every pal has fainted. Retreat.', 'bad');
      return false;
    }
    return true;
  }

  private startWildFight(wild: WildPal): void {
    if (!this.canFight()) return;
    this.activeWild = wild;
    this.activeEncounter = null;
    wild.mesh?.setEnabled(false);

    const battle = this.combatMode.enter(
      this.party.members,
      [wild.pal],
      { x: wild.motion.x, z: wild.motion.z },
      this.ctx.player.state.position.x,
      this.ctx.player.state.position.z,
      (event) => this.onBattleEvent(event),
      this.combatRandom(),
      { day: this.ctx.time.day }
    );

    this.setMode('combat');
    this.overlay.open(this.orbOptions(), this.party.members);
    this.overlay.setSlots(this.party.members, this.party.members.indexOf(battle.activeAlly ?? this.party.members[0]!));
  }

  private startScriptedFight(encounterId: string): void {
    const def = encounterDef(encounterId);
    if (!def) {
      console.error(`[game] unknown encounter "${encounterId}"`);
      return;
    }
    if (!this.canFight()) return;

    const npc = this.world.npcs.byId(encounterId);
    const at = npc ? { x: npc.position.x, z: npc.position.z } : {
      x: this.ctx.player.state.position.x,
      z: this.ctx.player.state.position.z + 6
    };

    this.activeWild = null;
    this.activeEncounter = encounterId;

    // Seeded per encounter and slot, so a retry faces the same team.
    const team = buildTeam(def, (index) => subRng(this.ctx.seed, `encounter:${def.id}`, index));

    this.combatMode.enter(
      this.party.members,
      team,
      at,
      this.ctx.player.state.position.x,
      this.ctx.player.state.position.z,
      (event) => this.onBattleEvent(event),
      this.combatRandom(),
      { scripted: true, day: this.ctx.time.day }
    );

    this.setMode('combat');
    this.overlay.open(this.orbOptions(), this.party.members);
  }

  private onBattleEvent(event: BattleEvent): void {
    switch (event.kind) {
      case 'hit':
        if (event.target === 'enemy') {
          const note =
            event.multiplier > 1 ? ' (strong)' : event.multiplier < 1 ? ' (weak)' : '';
          this.overlay.say(`${event.amount}${note}`, event.multiplier > 1 ? 'good' : 'plain');
        } else {
          this.overlay.say(`${event.amount} taken`, 'bad');
          this.combatMode.lunge('enemy');
        }
        break;
      case 'dodged':
        this.overlay.say('Dodged', 'good');
        break;
      case 'riposte':
        this.overlay.say('Counterattacked', 'bad');
        break;
      case 'hesitated':
        this.overlay.say('It hesitated', 'bad');
        break;
      case 'throwBounced':
        this.overlay.say('The orb bounces off the collar', 'bad');
        break;
      case 'throwShake':
        this.overlay.say(`Shake ${event.index + 1}`);
        break;
      case 'throwBroke':
        this.overlay.say('It broke free', 'bad');
        break;
      case 'throwCaught':
        this.overlay.say('Caught', 'good');
        break;
      case 'swap':
      case 'enemyChanged':
        this.combatMode.refreshMeshes();
        this.overlay.setSlots(this.party.members, this.activeAllyIndex());
        break;
      case 'faint':
        this.overlay.say(event.side === 'ally' ? 'Your pal is down' : 'Enemy down', event.side === 'ally' ? 'bad' : 'good');
        break;
      case 'telegraph':
        this.combatMode.lunge('enemy');
        break;
      default:
        break;
    }
  }

  private activeAllyIndex(): number {
    const active = this.combatMode.current?.activeAlly;
    if (!active) return 0;
    return Math.max(0, this.party.members.findIndex((p) => p.uid === active.uid));
  }

  private endCombat(outcome: Outcome): void {
    const battle = this.combatMode.current;
    const caught = battle?.caught ?? null;
    const xp = battle?.xpAward ?? 0;
    const wild = this.activeWild;
    const encounterId = this.activeEncounter;

    this.combatMode.exit();
    this.overlay.close();
    this.activeWild = null;
    this.activeEncounter = null;

    if (outcome === 'won' || outcome === 'caught') this.awardParty(xp);

    if (outcome === 'caught' && caught) {
      if (wild) this.spawns.remove(wild);
      this.offer(caught);
      return;
    }

    if (outcome === 'won') {
      if (wild) this.spawns.remove(wild);
      if (encounterId) {
        this.finishScripted(encounterId);
        return;
      }
      this.hud.toast('You win', 'good');
    } else if (outcome === 'fled') {
      this.hud.toast(wild ? 'It fled' : 'You backed off');
      if (wild) this.spawns.remove(wild);
    } else if (outcome === 'lost') {
      this.hud.toast('Your party is down', 'bad');
      if (wild) wild.mesh?.setEnabled(true);
    }

    this.hud.updateParty(this.party);
    this.setMode('explore');
    this.save();
  }

  /** Active pal takes the full award, the bench takes its share. */
  private awardParty(xp: number): void {
    if (xp <= 0) return;
    const activeUid = this.combatMode.current?.activeAlly?.uid;
    for (const pal of this.party.members) {
      const gained = awardXp(pal, pal.uid === activeUid ? xp : benchShare(xp));
      if (gained > 0) this.hud.toast(`${pal.name} reached level ${pal.level}`, 'good');
    }
    bus.emit('partyChanged', {});
  }

  /** A capture, or a Warden's recruit. Both go through Party.add. */
  private offer(pal: PalState): void {
    const result = this.party.add(pal);
    if (result.status === 'added') {
      this.hud.toast(`${pal.name} joins you`, 'good');
      this.hud.updateParty(this.party);
      bus.emit('partyChanged', {});
      this.setMode('explore');
      this.save();
      return;
    }
    // Six. The screen that should feel bad.
    this.setMode('release');
    this.releaseScreen.open(this.party.members, pal, this.ctx.time.day);
  }

  private recruit(speciesId: string, level: number): void {
    const pal = makePal(speciesId, level, subRng(this.ctx.seed, `recruit:${speciesId}`), {
      caughtDay: this.ctx.time.day
    });
    this.offer(pal);
  }

  // ---- the Hall ----------------------------------------------------------

  private finishScripted(encounterId: string): void {
    const def = encounterDef(encounterId);
    if (!def) return;
    this.flags.add(def.flag);

    const npc = this.world.npcs.byId(encounterId);
    if (npc) npc.dialogue = def.afterDialogue;

    this.hud.updateParty(this.party);
    this.save();
    // Straight into the aftermath conversation, which is where the Warden's
    // rewards are handed over.
    this.startDialogue(def.afterDialogue);
  }

  /**
   * The cut-tether sequence. Rewards land HERE rather than on the last hit, so
   * a player who closes the tab mid-cutscene still has the badge.
   */
  private runVictory(encounterId: string): void {
    const reward = rewardFor(encounterId);
    if (!reward) return;

    for (const flag of reward.flags) this.flags.add(flag);
    if (reward.badge) this.badges.push(reward.badge.id);
    for (const item of reward.items) addItem(this.inventory, item.id, item.n);

    // The four freed pals scatter back into the grass.
    for (const post of this.world.hall.anchors.alcoves) void post;

    this.setMode('victory');
    this.victoryScreen.show({
      title: 'The tethers are cut',
      lines: [
        `Four pals go back to the grass. The Hall lights go out for the first time in six years.`,
        `Bracken Holt stands down as Warden of the Meadows.`
      ],
      ...(reward.badge ? { badge: { name: reward.badge.name } } : {}),
      unlocks: ['Orb Bench recipe', 'Truestone Orb']
    });
    this.save();
  }

  private afterVictory(): void {
    const reward = this.pendingRecruit;
    this.pendingRecruit = null;
    if (reward) {
      this.startDialogue(reward);
      return;
    }
    this.setMode('explore');
  }

  private pendingRecruit: string | null = null;

  // ---- player state ------------------------------------------------------

  private faint(): void {
    const pos = this.ctx.player.state.position;
    const drained: { id: string; n: number; dur?: number }[] = [];
    for (let i = 0; i < this.inventory.length; i++) {
      const stack = this.inventory[i];
      // Equipped tools are never dropped, per section 4.
      if (stack && stack.id !== 'stone_axe') {
        drained.push({ ...stack });
        this.inventory[i] = null;
      }
    }
    // Only one satchel exists at a time; a new faint moves the old contents.
    if (this.satchel) drained.push(...this.satchel.items);
    this.satchel = { pos: new Vector3(pos.x, pos.y, pos.z), items: drained };

    revivePlayer(this.vitals);
    const wake = this.respawn ?? new Vector3(0, this.ctx.terrain.heightAt(0, 0), 0);
    this.ctx.player.state.position.x = wake.x;
    this.ctx.player.state.position.y = wake.y;
    this.ctx.player.state.position.z = wake.z;

    bus.emit('playerFainted', { pos: { x: pos.x, y: pos.y, z: pos.z } });
    this.hud.toast('You wake at Hollowbrook. Your satchel is where you fell.', 'bad');
    this.save();
  }

  private collectSatchel(px: number, pz: number): void {
    const satchel = this.satchel;
    if (!satchel) return;
    if (Math.hypot(px - satchel.pos.x, pz - satchel.pos.z) > 2.5) return;
    for (const stack of satchel.items) addItem(this.inventory, stack.id, stack.n);
    this.satchel = null;
    this.hud.toast('Satchel recovered', 'good');
    bus.emit('inventoryChanged', {});
  }

  private orbOptions(): OrbOption[] {
    return ORB_IDS.map((orb) => ({
      id: orb.id,
      name: orb.name,
      ballMod: orb.ballMod,
      count: countItem(this.inventory, orb.id)
    })).filter((orb) => orb.count > 0);
  }

  private openParty(): void {
    if (this.mode !== 'explore') return;
    this.setMode('party');
    this.partyScreen.open(this.party.members, this.party.ledger, this.ctx.time.day);
  }

  /**
   * Mode switching, and the one place input mode changes. Combat reads a swipe
   * as a dodge; exploring reads it as a camera turn.
   */
  private setMode(mode: Mode): void {
    this.mode = mode;
    this.ctx.input.setMode(mode === 'combat' ? 'combat' : 'explore');
    this.hud.setVisible(mode === 'explore');

    if (mode !== 'party') this.partyScreen.close();
    if (mode !== 'release') this.releaseScreen.close();

    // A dialogue effect queued a fight or a cutscene; run it now that the
    // conversation has closed rather than on top of it.
    if (mode === 'explore') this.flushPending();
  }

  private flushPending(): void {
    const fight = this.pendingFight;
    const victory = this.pendingVictory;
    this.pendingFight = null;
    this.pendingVictory = null;

    if (fight) {
      this.startScriptedFight(fight);
      return;
    }
    if (victory) {
      const reward = rewardFor('bracken');
      this.pendingRecruit = reward?.recruit?.dialogue ?? null;
      this.runVictory('bracken');
    }
  }

  // ---- persistence -------------------------------------------------------

  snapshot(): SaveV1 {
    const pos = this.ctx.player.state.position;
    return {
      schemaVersion: 1,
      seed: this.ctx.seed,
      createdAt: Date.now(),
      savedAt: Date.now(),
      player: {
        pos: { x: pos.x, y: pos.y, z: pos.z },
        rot: this.ctx.player.state.yaw,
        health: this.vitals.health,
        stamina: this.vitals.stamina,
        hunger: this.vitals.hunger,
        buffs: this.vitals.buffs,
        playMs: this.vitals.playMs
      },
      inventory: this.inventory,
      party: this.party.members,
      releasedLedger: this.party.ledger,
      structures: [],
      worldDeltas: { harvested: {}, bossesDown: {} },
      progress: {
        badges: [...this.badges],
        flags: [...this.flags],
        day: this.ctx.time.day,
        timeOfDay: this.ctx.time.cycle,
        respawn: this.respawn ? { x: this.respawn.x, y: this.respawn.y, z: this.respawn.z } : null,
        satchel: this.satchel
          ? {
              pos: { x: this.satchel.pos.x, y: this.satchel.pos.y, z: this.satchel.pos.z },
              items: this.satchel.items
            }
          : null
      }
    };
  }

  save(): void {
    const ok = this.saves.save(this.snapshot());
    bus.emit('saveStatus', ok ? { status: 'saved' } : { status: 'failed', reason: 'storage' });
  }

  /** Restore. Returns false when there is nothing valid to restore from. */
  restore(): boolean {
    const state = this.saves.load();
    if (!state || state.seed !== this.ctx.seed) return false;

    this.inventory = state.inventory.length > 0 ? state.inventory : createInventory();
    this.vitals = { ...createVitals(), ...state.player, fainted: false } as typeof this.vitals;
    this.flags.clear();
    for (const flag of state.progress.flags) this.flags.add(flag);
    this.badges.length = 0;
    this.badges.push(...state.progress.badges);

    const restored = Party.fromSaved(state.party, state.releasedLedger);
    for (const pal of restored.members) this.party.add(pal);

    this.ctx.player.state.position.x = state.player.pos.x;
    this.ctx.player.state.position.y = state.player.pos.y;
    this.ctx.player.state.position.z = state.player.pos.z;
    this.ctx.time.cycle = state.progress.timeOfDay;
    this.ctx.time.day = state.progress.day;

    if (state.progress.respawn) {
      const r = state.progress.respawn;
      this.respawn = new Vector3(r.x, r.y, r.z);
    }
    if (state.progress.satchel) {
      const s = state.progress.satchel;
      this.satchel = { pos: new Vector3(s.pos.x, s.pos.y, s.pos.z), items: s.items };
    }

    // Anyone already beaten should be past tense when the player walks back in.
    for (const id of ['grunt_a', 'grunt_b', 'bracken']) {
      const def = encounterDef(id);
      const npc = this.world.npcs.byId(id);
      if (def && npc && this.flags.has(def.flag)) npc.dialogue = def.afterDialogue;
    }

    this.hud.updateParty(this.party);
    return true;
  }

  /** Open the game: Orin if this is a cold start, nothing if it is a reload. */
  begin(): void {
    this.hud.updateParty(this.party);
    this.hud.setVisible(true);
    if (!this.flags.has('met_orin') && this.party.size === 0) {
      this.startDialogue('orin_intro');
    }
  }

  hasFlag(flag: string): boolean {
    return this.flags.has(flag);
  }

  dispose(): void {
    this.save();
    this.combatMode.dispose();
    this.spawns.dispose();
    this.world.dispose();
    this.hud.dispose();
    this.overlay.dispose();
    this.dialoguePanel.dispose();
    this.victoryScreen.dispose();
    this.releaseScreen.dispose();
    this.partyScreen.dispose();
  }
}

/** Orin's starters arrive at level 5, high enough to survive the first field. */
const STARTER_LEVEL = 5;

/** HUD repaint interval. Fast enough to read as live, slow enough to be free. */
const HUD_REFRESH_MS = 100;
