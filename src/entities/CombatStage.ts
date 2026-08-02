import {
  Color3,
  CreateSphere,
  Mesh,
  Scene,
  StandardMaterial,
  Vector3
} from '../core/babylon';
import stage from '../data/combatStage.json';
import { bus } from '../core/EventBus';
import type { Fx } from '../fx/Fx';
import type { Party } from '../party/Party';
import type { Player, CameraFraming } from './Player';
import type { PalBody, PalVisuals } from './PalVisual';
import type { WildPal } from './SpawnManager';
import type { CombatMode } from '../combat/CombatMode';
import { facingYaw, placeStage } from '../combat/stagePlacement';

/**
 * The renderer side of a fight. CombatMode stays pure and event-driven; this
 * listens and moves bodies.
 *
 * On combatStarted: the party's active pal finally takes the field as a real
 * body, the enemy is held in place (its slot flagged `held` so AI and despawn
 * leave it alone), both face each other on the line from the player, and the
 * camera pulls back to frame the pair. Events during the fight become clips
 * and impacts. On combatEnded everything restores.
 *
 * Wall-clock timers (setTimeout) are fine here: this is presentation, and a
 * hit pause freezing the sim mid-choreography is exactly when a clip should
 * keep holding rather than advance.
 */

export class CombatStage {
  private ally: PalBody | null = null;
  private enemy: WildPal | null = null;
  private orb: Mesh;
  private orbTimer: number | null = null;
  private readonly unsubs: (() => void)[] = [];

  constructor(
    scene: Scene,
    private readonly combat: CombatMode,
    private readonly party: Party,
    private readonly visuals: PalVisuals,
    private readonly player: Player,
    private readonly fx: Fx,
    private readonly heightAt: (x: number, z: number) => number
  ) {
    // One pooled orb, reused every throw.
    this.orb = CreateSphere('combat_orb', { diameter: stage.orb.radius * 2, segments: 8 }, scene);
    const mat = new StandardMaterial('mat_combat_orb', scene);
    mat.diffuseColor = Color3.FromHexString('#7ec8d8');
    mat.emissiveColor = Color3.FromHexString('#2a4a55');
    this.orb.material = mat;
    this.orb.isPickable = false;
    this.orb.setEnabled(false);

    this.unsubs.push(
      bus.on('combatStarted', () => this.begin()),
      bus.on('combatEnded', ({ phase }) => this.end(phase)),
      bus.on('attackResolved', (e) => this.onAttack(e)),
      bus.on('enemyTelegraph', ({ ms }) => this.onTelegraph(ms)),
      bus.on('orbThrown', ({ outcome }) => this.onThrow(outcome)),
      bus.on('palFainted', () => this.onAllyFainted())
    );
  }

  private begin(): void {
    const enemy = this.combat.target;
    const active = this.party.active;
    if (!enemy) return;
    this.enemy = enemy;
    enemy.held = true;

    const p = placeStage(
      this.player.state.position.x,
      this.player.state.position.z,
      enemy.x,
      enemy.z,
      stage.placement
    );

    enemy.x = p.enemy.x;
    enemy.z = p.enemy.z;
    enemy.y = this.heightAt(p.enemy.x, p.enemy.z);
    enemy.yaw = p.enemy.yaw;
    if (enemy.body) {
      enemy.body.root.position.set(enemy.x, enemy.y, enemy.z);
      enemy.body.root.rotation.y = enemy.yaw;
      enemy.body.driver.play('idle', performance.now());
    }

    if (active) {
      this.ally = this.visuals.acquire(active.species);
      if (this.ally) {
        this.ally.root.position.set(p.ally.x, this.heightAt(p.ally.x, p.ally.z), p.ally.z);
        this.ally.root.rotation.y = p.ally.yaw;
      }
    }

    this.player.setCameraFraming(stage.camera as CameraFraming);
  }

  /**
   * One fixed step while a fight is running. Pins the player's own camera
   * yaw at the enemy every tick, rather than leaving it to free look: the
   * owner's ROG Ally playtest asked for the target to stay centre-framed for
   * the whole fight, and `intent.look` keeps accumulating in combat (mouse
   * drag, the right stick) with nothing else to stop it drifting off the
   * enemy over a long fight. The enemy is `held` and does not move, so this
   * is exact and cheap: recompute the angle, hand it to the one legal camera
   * writer (D46) the same way a spawn already seeds facing with `setYaw`,
   * just every step instead of once. Pitch is left alone; that is still the
   * player's, per D46's "look input cancels the pitch blend".
   */
  update(playerX: number, playerZ: number): void {
    const enemy = this.enemy;
    if (!enemy) return;
    this.player.setYaw(facingYaw(playerX, playerZ, enemy.x, enemy.z));
  }

  private end(phase: string): void {
    this.player.setCameraFraming(null);
    this.combat.setAiming(false);

    const enemy = this.enemy;
    this.enemy = null;
    if (enemy) {
      // The defeat/caught puff. Encounter.settle() releases the slot right
      // after this event, so the send-off has to render from here.
      if (phase === 'won' || phase === 'caught') {
        const at = enemy.body?.root.position;
        if (at) this.fx.impact(phase === 'caught' ? 'catch_success' : 'faint', at.x, at.y + 0.6, at.z);
      }
      enemy.held = false;
    }

    this.ally?.dispose();
    this.ally = null;
    if (this.orbTimer !== null) {
      clearTimeout(this.orbTimer);
      this.orbTimer = null;
    }
    this.orb.setEnabled(false);
  }

  private onAttack(e: {
    attacker: 'ally' | 'enemy';
    kind: 'quick' | 'power';
    damage: number;
    dodged: boolean;
    defeated: boolean;
  }): void {
    const now = performance.now();
    const attacker = e.attacker === 'ally' ? this.ally : this.enemy?.body ?? null;
    const defender = e.attacker === 'ally' ? this.enemy?.body ?? null : this.ally;

    attacker?.driver.play('attack', now, e.kind === 'power' ? 0.85 : 1.15);

    const at = defender?.root.position;
    if (e.dodged) {
      defender?.driver.play('dodge', now);
      if (at) this.fx.number('dodged', at.x, at.y + 1, at.z, 'info');
      return;
    }
    if (e.damage > 0 && at) {
      this.fx.impact(e.kind === 'power' ? 'power_hit' : 'quick_hit', at.x, at.y + 0.7, at.z);
      this.fx.number(String(e.damage), at.x, at.y + 1.1, at.z, 'damage');
      defender?.driver.play(e.defeated ? 'faint' : 'hit', now);
    }
  }

  private onTelegraph(ms: number): void {
    // The tell: a crouch that swells into the strike. Root scale, so it works
    // on every model without knowing its rig.
    const body = this.enemy?.body;
    if (!body) return;
    const root = body.root;
    const base = 1;
    root.scaling.setAll(base * stage.telegraph.crouchScale);
    window.setTimeout(() => {
      root.scaling.setAll(base * stage.telegraph.swellScale);
      window.setTimeout(() => root.scaling.setAll(base), 180);
    }, Math.max(60, ms - 180));
  }

  /** Fly the orb from the player to the enemy, then show the outcome. */
  private onThrow(outcome: 'bounced' | 'missed' | 'caught' | 'no-orbs'): void {
    // Pressing throw with an empty satchel is a refusal, not a throw. There is
    // no orb to fly and nothing was spent, so the fight carries on untouched.
    if (outcome === 'no-orbs') return;
    const enemy = this.enemy;
    if (!enemy) {
      // Nothing to fly at, so do not leave the enemy held forever.
      this.combat.setAiming(false);
      return;
    }
    const from = new Vector3(
      this.player.state.position.x,
      this.player.state.position.y + 1.4,
      this.player.state.position.z
    );
    const to = new Vector3(enemy.x, enemy.y + 0.8, enemy.z);

    this.orb.setEnabled(true);
    const started = performance.now();
    const step = (): void => {
      const t = Math.min(1, (performance.now() - started) / stage.orb.flightMs);
      // A parabolic arc: lerp plus a sin bump.
      this.orb.position.set(
        from.x + (to.x - from.x) * t,
        from.y + (to.y - from.y) * t + Math.sin(t * Math.PI) * stage.orb.arcHeight,
        from.z + (to.z - from.z) * t
      );
      if (t < 1) {
        requestAnimationFrame(step);
        return;
      }
      this.orb.setEnabled(false);
      // The orb has landed: the enemy is free again, whatever the outcome.
      this.combat.setAiming(false);
      this.landOrb(outcome, to);
    };
    requestAnimationFrame(step);
  }

  private landOrb(outcome: 'bounced' | 'missed' | 'caught', at: Vector3): void {
    const now = performance.now();
    if (outcome === 'bounced') {
      // The collar teaching moment: a hard clank, no shakes, unmistakably
      // different from a near miss.
      this.fx.impact('orb_bounce', at.x, at.y, at.z);
      this.fx.number('bounced', at.x, at.y + 0.5, at.z, 'loss');
      return;
    }
    if (outcome === 'missed') {
      this.fx.impact('catch_shake', at.x, at.y, at.z);
      this.enemy?.body?.driver.play('hit', now);
      this.fx.number('broke free', at.x, at.y + 0.5, at.z, 'loss');
      return;
    }
    // Caught: combatEnded('caught') already restored the stage; the puff from
    // end() covers the suck-in. Nothing further here.
  }

  private onAllyFainted(): void {
    // The driver holds the faint pose; the swap to the next pal replaces the
    // body a beat later so the fall is visible.
    const fallen = this.ally;
    if (!fallen) return;
    window.setTimeout(() => {
      if (this.ally !== fallen) return;
      const next = this.party.active;
      this.ally = null;
      const pos = fallen.root.position.clone();
      const yaw = fallen.root.rotation.y;
      fallen.dispose();
      if (!next || next.fainted || !this.combat.isFighting) return;
      this.ally = this.visuals.acquire(next.species);
      this.ally?.root.position.copyFrom(pos);
      if (this.ally) this.ally.root.rotation.y = yaw;
    }, 900);
  }

  dispose(): void {
    for (const un of this.unsubs) un();
    this.unsubs.length = 0;
    this.ally?.dispose();
    this.ally = null;
    this.orb.material?.dispose();
    this.orb.dispose();
  }
}
