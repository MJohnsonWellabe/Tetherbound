import { bus } from '../core/EventBus';
import type { Intent } from '../core/input/Intent';
import stations from '../data/stations.json';
import type { Party } from '../party/Party';
import { derive } from '../entities/Species';
import type { SpawnManager } from '../entities/SpawnManager';
import { craft, type CraftContext } from './Crafting';
import { Satchel } from './Satchel';
import { Stations, stationDef, type PlacedStation } from './Stations';
import type { Slots } from './Inventory';
import { revive, type VitalsState } from './Vitals';

/**
 * Home base behaviour: placing stations, cooking, sleeping, reviving pals,
 * fainting and respawning.
 *
 * Named for what it is rather than for a pattern. All of it hangs off "am I
 * standing near one of my own structures", which is one question asked in five
 * places, so it is answered once here.
 */

export interface WorldProbe {
  heightAt(x: number, z: number): number;
}

export class Homestead {
  /** Where the player wakes. Null until a bed is placed. */
  respawn: { x: number; y: number; z: number } | null = null;
  private reviveMs = 0;

  constructor(
    private readonly stationsOwned: Stations,
    private readonly satchel: Satchel,
    private readonly party: Party,
    private readonly spawner: SpawnManager,
    private readonly slots: Slots,
    private readonly world: WorldProbe
  ) {}

  /** Services in reach, for the crafting UI and the HUD. */
  servicesAt(x: number, z: number): Set<string> {
    return this.stationsOwned.servicesAt(x, z);
  }

  /**
   * Crafting context for wherever the player is standing.
   *
   * `station` is the single station id the recipe system checks against, so
   * the nearest station providing the richest service wins. Tier 2's roof
   * requirement lands with the Hall; until then nothing is under cover.
   */
  craftContext(x: number, z: number, flags: readonly string[] = []): CraftContext {
    const nearest =
      this.stationsOwned.nearest(x, z, 'craft1') ??
      this.stationsOwned.nearest(x, z, 'cook') ??
      this.stationsOwned.nearest(x, z, 'tan') ??
      this.stationsOwned.nearest(x, z, 'orbs');
    return { station: nearest?.id ?? null, hasRoof: false, flags };
  }

  /**
   * Place a station the player has in their satchel.
   *
   * Stations are items until they are placed, so this consumes the item and
   * puts the structure in the world in one step.
   */
  placeStation(id: string, x: number, z: number): PlacedStation | null {
    const def = stationDef(id);
    if (!def) return null;
    const placed = this.stationsOwned.place(id, x, this.world.heightAt(x, z), z);
    if (placed && def.provides.includes('respawn')) {
      // A bed sets the respawn point the moment it exists, rather than needing
      // a separate "sleep here once" step nobody would discover.
      this.respawn = { x, y: this.world.heightAt(x, z), z };
    }
    return placed;
  }

  /**
   * One fixed step.
   *
   * The interact button does whatever the player is standing next to, in
   * priority order: pick the satchel back up, then sleep. Harvesting and
   * building already claimed it further up the chain, so this only sees a
   * press nothing else wanted.
   */
  update(intent: Intent, x: number, z: number, dt: number): 'collected' | 'slept' | null {
    this.tickRevive(x, z, dt);
    if (!intent.interact) return null;

    if (this.collectSatchel(x, z) > 0) return 'collected';
    if (this.sleep(x, z).ok) return 'slept';
    return null;
  }

  /**
   * A campfire wakes fainted pals, one at a time, 30 seconds each.
   *
   * One at a time on purpose: a camp that revives the whole party at once
   * removes the reason to retreat before the last pal drops.
   */
  private tickRevive(x: number, z: number, dt: number): void {
    if (!this.stationsOwned.nearest(x, z, 'revive')) {
      this.reviveMs = 0;
      return;
    }
    const downed = this.party.members.find((p) => p.fainted);
    if (!downed) {
      this.reviveMs = 0;
      return;
    }
    this.reviveMs += dt * 1000;
    if (this.reviveMs < stations.reviveMsPerPal) return;
    this.reviveMs = 0;
    downed.fainted = false;
    downed.currentHp = derive(downed).maxHp;
    bus.emit('partyChanged', {});
  }

  /**
   * Sleep, if there is a bed and nothing hostile nearby.
   *
   * Returns why it failed rather than silently doing nothing, because a bed
   * that ignores you is indistinguishable from a broken one.
   */
  sleep(x: number, z: number): { ok: boolean; reason?: 'no-bed' | 'threats' } {
    if (!this.stationsOwned.nearest(x, z, 'sleep')) return { ok: false, reason: 'no-bed' };

    const threat = this.spawner.active.some(
      (pal) => Math.hypot(pal.x - x, pal.z - z) < stations.sleepThreatRadius
    );
    if (threat) return { ok: false, reason: 'threats' };
    return { ok: true };
  }

  /** The cycle position to wake at. Morning, per section 8. */
  get wakeCycle(): number {
    return stations.sleepWakeCycle;
  }

  /**
   * The player hit zero.
   *
   * Inventory drops into a satchel here, tools and pals excluded, and they wake
   * at their bed or at Hollowbrook if none is set (section 4).
   */
  faint(vitals: VitalsState, x: number, y: number, z: number): { x: number; y: number; z: number } {
    this.satchel.drop(this.slots, x, y, z);
    revive(vitals);
    bus.emit('playerFainted', { pos: { x, y, z } });
    const bed = this.respawn;
    if (bed) return bed;
    // Hollowbrook sits at the world origin and its plateau is always flat.
    return { x: 0, y: this.world.heightAt(0, 0), z: 0 };
  }

  /** Try to pick the satchel back up. Returns how many items came back. */
  collectSatchel(x: number, z: number): number {
    const marker = this.satchel.marker;
    if (!marker) return 0;
    if (Math.hypot(marker.x - x, marker.z - z) > 3) return 0;
    return this.satchel.collect(this.slots);
  }

  /** Cook or craft at whatever is in reach. */
  craftHere(recipeId: string, x: number, z: number): ReturnType<typeof craft> {
    return craft(this.slots, recipeId, this.craftContext(x, z));
  }
}
