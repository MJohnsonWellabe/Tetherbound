/**
 * One place every door in the world registers into, so `main.ts` has a
 * single interaction path regardless of which system built the door.
 *
 * Before this, only BuildMode's player-placed doors were reachable: it owned
 * its own nearest/toggle/step methods and `main.ts` called them directly.
 * `src/world/Structures.ts`'s house doors need the exact same E-to-open
 * behaviour, so both push `DoorHandle`s in here instead of `main.ts` knowing
 * two different door systems.
 */

export interface DoorHandle {
  /** World position, for the nearest-door search. */
  readonly position: { x: number; z: number };
  isOpen(): boolean;
  /** Flip the open/closed state. The hinge eases toward it over `step`. */
  toggle(): void;
  /** Advance the hinge one fixed step. `dtMs` is real milliseconds elapsed. */
  step(dtMs: number): void;
}

export class DoorRegistry {
  private readonly doors = new Set<DoorHandle>();

  /** Register a door. Call the returned function when it is removed or disposed. */
  register(door: DoorHandle): () => void {
    this.doors.add(door);
    return () => this.doors.delete(door);
  }

  /** The nearest registered door within `maxDist`, or null. Drives the interact prompt. */
  nearest(px: number, pz: number, maxDist: number): DoorHandle | null {
    let best: DoorHandle | null = null;
    let bestDist = maxDist;
    for (const door of this.doors) {
      const d = Math.hypot(door.position.x - px, door.position.z - pz);
      if (d < bestDist) {
        bestDist = d;
        best = door;
      }
    }
    return best;
  }

  /**
   * Swing every registered door's leaf toward its target angle. Runs every
   * fixed step unconditionally, independent of whatever tool is out: a door
   * must keep opening after the player has put the hammer away and walked up
   * to it.
   */
  stepAll(dtMs: number): void {
    for (const door of this.doors) door.step(dtMs);
  }

  get size(): number {
    return this.doors.size;
  }
}
