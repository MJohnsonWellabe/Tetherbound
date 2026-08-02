import { bus } from '../core/EventBus';
import stations from '../data/stations.json';

/**
 * Placeable stations: workbench, campfire, bed, tanning rack, orb bench.
 *
 * A station is a crafting context and a service, not a building piece, so it
 * lives here rather than in BuildMode. The workbench gates tier 1 recipes, the
 * campfire cooks and revives pals, the bed sets the respawn point.
 *
 * PURE. No meshes here: src/survival must run headless under vitest, and
 * tests/bundle.test.ts enforces it. StationViews.ts owns the geometry and
 * subscribes to what this publishes, the same pure/renderer split Scatter.ts
 * and PropBatcher.ts use.
 */

export interface StationDef {
  name: string;
  /** Meters within which the station counts as "in range" for crafting. */
  radius: number;
  color: string;
  size: [number, number, number];
  /** Services this station provides, keyed for the systems that ask. */
  provides: string[];
}

export interface PlacedStation {
  id: string;
  x: number;
  y: number;
  z: number;
  rot: number;
}

const DEFS = stations.stations as unknown as Record<string, StationDef | undefined>;

export function stationDef(id: string): StationDef | undefined {
  return DEFS[id];
}

export class Stations {
  private readonly placed: PlacedStation[] = [];
  constructor() {}

  get all(): readonly PlacedStation[] {
    return this.placed;
  }

  place(id: string, x: number, y: number, z: number, rot = 0): PlacedStation | null {
    const def = stationDef(id);
    if (!def) return null;
    const station: PlacedStation = { id, x, y, z, rot };
    this.placed.push(station);
    bus.emit('stationPlaced', { id });
    return station;
  }

  restore(list: PlacedStation[]): void {
    for (const s of list) {
      const def = stationDef(s.id);
      if (!def) continue;
      this.placed.push(s);
    }
  }

  /**
   * Which services are available at a position.
   *
   * Returns a set rather than a station, because "am I near a campfire" is the
   * question every caller actually has, and two campfires are not more cooking.
   */
  servicesAt(x: number, z: number): Set<string> {
    const out = new Set<string>();
    for (const station of this.placed) {
      const def = stationDef(station.id);
      if (!def) continue;
      if (Math.hypot(station.x - x, station.z - z) > def.radius) continue;
      for (const service of def.provides) out.add(service);
    }
    return out;
  }

  /** Nearest station providing a service, or null. Used by sleep and revive. */
  nearest(x: number, z: number, service: string): PlacedStation | null {
    let best: PlacedStation | null = null;
    let bestDist = Number.POSITIVE_INFINITY;
    for (const station of this.placed) {
      const def = stationDef(station.id);
      if (!def || !def.provides.includes(service)) continue;
      const d = Math.hypot(station.x - x, station.z - z);
      if (d <= def.radius && d < bestDist) {
        bestDist = d;
        best = station;
      }
    }
    return best;
  }

}
