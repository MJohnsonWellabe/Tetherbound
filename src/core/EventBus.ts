/**
 * A small typed publish/subscribe bus. Deliberately not a framework.
 *
 * The rule that keeps this from turning into spaghetti: events announce that
 * something HAPPENED. They never ask for something to happen. If you find
 * yourself emitting 'pleaseOpenInventory', call the thing directly instead.
 */

/**
 * The event map. Adding an event here is what makes it type-safe at both ends;
 * `emit` and `on` both key off this, so a typo is a compile error rather than a
 * listener that silently never fires.
 */
export interface GameEvents {
  /** Fixed-step simulation tick. dt is always the same fixed value. */
  tick: { dt: number; elapsedMs: number };
  /** Player vitals changed enough that the HUD should repaint. */
  vitalsChanged: { health: number; stamina: number; hunger: number };
  /** Player hit 0 health. Carries where they fell so the satchel lands there. */
  playerFainted: { pos: { x: number; y: number; z: number } };
  /** In-game day rolled over. */
  dayChanged: { day: number };
  /** A save was attempted. `status` is the honest outcome, never optimistic. */
  saveStatus: { status: string; reason?: string };
  /** Inventory contents changed. */
  inventoryChanged: Record<string, never>;
  /** A tool connected with a node but did not fell it yet. */
  harvestSwing: { key: string; progress: number };
  /** A node was felled. `drops` is what actually fit in the satchel. */
  harvested: { key: string; drops: { id: string; n: number }[] };
  /** Party composition or pal state changed. */
  partyChanged: Record<string, never>;
  /** Combat Mode entered. Not a scene load; the world keeps rendering. */
  combatStarted: { species: string; level: number };
  /** Combat Mode left, with how it ended. */
  combatEnded: { phase: string };
  /** The enemy began a power attack wind-up. This is the dodge window. */
  enemyTelegraph: { ms: number };
  /** A party pal dropped to 0 HP. Fainted, never lost. */
  palFainted: { uid: string };
  /** A neglected pal refused to commit to a power attack. */
  palHesitated: { uid: string };
  /** The fight was won. */
  combatWon: { xp: number; day: number };
  /** An orb bounced off a collared pal. Not a failed roll, a refusal. */
  orbBounced: Record<string, never>;
  /** An orb broke. Carries what the odds actually were. */
  catchFailed: { chance: number; shakes: number };
  /** A sixth capture needs a release decision before it can be resolved. */
  releaseNeeded: Record<string, never>;
  /** A build piece was placed. */
  builtPiece: { pieceId: string };
  /** A placement was refused, with why. */
  buildBlocked: { reason: string };
}

export type EventName = keyof GameEvents;
export type Handler<K extends EventName> = (payload: GameEvents[K]) => void;

type HandlerSet = Set<(payload: never) => void>;

class Bus {
  private readonly handlers = new Map<EventName, HandlerSet>();

  /** Subscribe. Returns an unsubscribe function. Call it on teardown. */
  on<K extends EventName>(event: K, handler: Handler<K>): () => void {
    let set = this.handlers.get(event);
    if (!set) {
      set = new Set();
      this.handlers.set(event, set);
    }
    set.add(handler as (payload: never) => void);
    return () => {
      this.handlers.get(event)?.delete(handler as (payload: never) => void);
    };
  }

  /** Subscribe for exactly one delivery. */
  once<K extends EventName>(event: K, handler: Handler<K>): () => void {
    const off = this.on(event, (payload) => {
      off();
      handler(payload);
    });
    return off;
  }

  /**
   * Publish. A throwing listener is contained and logged rather than allowed
   * to abort delivery to the listeners after it. One broken HUD widget must
   * not stop the save system from hearing that the player fainted.
   */
  emit<K extends EventName>(event: K, payload: GameEvents[K]): void {
    const set = this.handlers.get(event);
    if (!set) return;
    for (const handler of [...set]) {
      try {
        (handler as Handler<K>)(payload);
      } catch (err) {
        console.error(`[bus] listener for "${String(event)}" threw:`, err);
      }
    }
  }

  /** Drop every listener. Used between rounds so nothing accumulates. */
  clear(): void {
    this.handlers.clear();
  }

  /** Listener count, for the disposal soak test. */
  count(): number {
    let n = 0;
    for (const set of this.handlers.values()) n += set.size;
    return n;
  }
}

export const bus = new Bus();
