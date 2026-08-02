import { bus } from '../core/EventBus';
import type { SaveManager, SaveV1 } from '../core/SaveManager';

/**
 * Owns the "has this run been wiped" guard around autosave.
 *
 * Start Over calls `saves.clear()` then reloads the page. Reload is not
 * instant: the 60s autosave timer and the `visibilitychange` handler both
 * call `flush()`, and `visibilitychange` fires DURING a reload. Without a
 * guard, whichever of those lands in the gap between the wipe and the actual
 * navigation writes the in-memory state straight back over it, and Start Over
 * silently does nothing. `wiped` lives here, in one place, rather than as a
 * flag main.ts has to remember to check at every call site.
 *
 * Pulled out of main.ts (already over its line budget) so the guard is
 * testable without booting the renderer.
 */
export class SaveWiring {
  private wiped = false;

  constructor(
    private readonly saves: SaveManager,
    private readonly snapshot: () => SaveV1
  ) {}

  /** True once startOver() has run. Inert forever after; there is no un-wipe. */
  get isWiped(): boolean {
    return this.wiped;
  }

  /**
   * Write the current state to storage, unless the run has been wiped.
   * Returns null when skipped for that reason, so a caller can tell "did not
   * save because wiped" apart from "tried to save and failed".
   */
  flush(): { ok: boolean; reason?: string } | null {
    if (this.wiped) return null;
    const result = this.saves.save(this.snapshot());
    bus.emit(
      'saveStatus',
      result.ok ? { status: 'saved' } : { status: 'failed', reason: result.reason ?? '' }
    );
    return result;
  }

  /** Erase the save and latch flush() off for the rest of this page's life. */
  startOver(): void {
    this.saves.clear();
    this.wiped = true;
  }
}
