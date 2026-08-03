import { Scene, SceneInstrumentation } from './babylon';
import type { Loop } from './Loop';
import type { ChunkManager } from '../world/ChunkManager';
import type { PropBatcher } from '../world/PropBatcher';
import type { Input } from './input/Input';

/**
 * The ?stats=1 performance readout.
 *
 * CLAUDE.md: "Check ?stats=1 at the end of every session. If draw calls pass
 * 150 or frame time passes 16ms on a phone, fix it before adding the next
 * feature." So this shows those two numbers first, and colours them, because a
 * budget you have to interpret is a budget nobody enforces.
 *
 * Instrumentation is only constructed when the flag is on. SceneInstrumentation
 * hooks per-frame observables and is not free; a released player pays nothing.
 */

/** docs/03_TECHNICAL_ARCHITECTURE.md performance budget. */
const BUDGET = {
  frameMs: 16,
  drawCalls: 150,
  triangles: 300_000
} as const;

/** Median of the last N frames. One 400ms hitch must not repaint the whole
 *  overlay red and train you to ignore it. */
const SAMPLE_WINDOW = 30;

export class Stats {
  private readonly el: HTMLElement;
  private readonly instrumentation: SceneInstrumentation;
  private readonly frameSamples: number[] = [];
  private lastPaintMs = 0;

  static enabled(search: string = location.search): boolean {
    return new URLSearchParams(search).get('stats') === '1';
  }

  constructor(
    private readonly scene: Scene,
    private readonly loop: Loop,
    el: HTMLElement,
    private readonly chunks: ChunkManager,
    private readonly props: PropBatcher,
    private readonly input: Input
  ) {
    this.el = el;
    this.el.hidden = false;
    this.instrumentation = new SceneInstrumentation(scene);
    this.instrumentation.captureFrameTime = true;
  }

  /** Call once per rendered frame. Repaints the DOM at ~5Hz, not 60. */
  sample(nowMs: number): void {
    this.frameSamples.push(this.loop.frameMs);
    if (this.frameSamples.length > SAMPLE_WINDOW) this.frameSamples.shift();

    // Writing to the DOM every frame is itself a measurable cost, and a
    // number that changes 60 times a second is unreadable anyway.
    if (nowMs - this.lastPaintMs < 200) return;
    this.lastPaintMs = nowMs;
    this.paint();
  }

  private median(): number {
    if (this.frameSamples.length === 0) return 0;
    const sorted = [...this.frameSamples].sort((a, b) => a - b);
    return sorted[Math.floor(sorted.length / 2)] ?? 0;
  }

  private paint(): void {
    const frameMs = this.median();
    const fps = frameMs > 0 ? 1000 / frameMs : 0;
    const drawCalls = this.instrumentation.drawCallsCounter.current;
    // getActiveIndices is indices actually submitted this frame, so it tracks
    // what is on screen rather than what exists in the scene.
    const triangles = Math.round(this.scene.getActiveIndices() / 3);
    const meshes = this.scene.getActiveMeshes().length;

    const over =
      (frameMs > BUDGET.frameMs ? 1 : 0) +
      (drawCalls > BUDGET.drawCalls ? 1 : 0) +
      (triangles > BUDGET.triangles ? 1 : 0);

    this.el.className = over >= 2 ? 'stats stats--bad' : over === 1 ? 'stats stats--warn' : 'stats';

    // Per-family instance counts, so a family reading zero near the player
    // while others read normally is diagnosable at a glance (the instancing
    // symptom this line exists to catch, per CLAUDE.md's own note that
    // "vegetation mostly doesn't render" means instancing, not scatter).
    const counts = this.props.instanceCountsByFamily();
    const families = Object.keys(counts).sort();
    const propsLine =
      families.length > 0
        ? families.map((f) => `${f}:${counts[f]}`).join(' ')
        : '(none resident)';

    this.el.textContent = [
      `${fps.toFixed(0).padStart(3)} fps   ${frameMs.toFixed(1)} ms`,
      `draws  ${String(drawCalls).padStart(5)} / ${BUDGET.drawCalls}`,
      `tris   ${fmtK(triangles).padStart(5)} / ${fmtK(BUDGET.triangles)}`,
      `meshes ${String(meshes).padStart(5)}`,
      `chunks ${String(this.chunks.loadedCount).padStart(5)} loaded  ${this.chunks.pendingCount} pending`,
      `props  ${propsLine}`,
      `pad    ${padLine(this.input.gamepadStatus)}`
    ].join('\n');
  }

  dispose(): void {
    this.instrumentation.dispose();
    this.el.hidden = true;
    this.el.textContent = '';
  }
}

function fmtK(n: number): string {
  return n >= 1000 ? `${Math.round(n / 1000)}k` : String(n);
}

/**
 * One line for whichever pad GamepadLayer picked, so the exact ROG Ally
 * defect (a vendor HID interface selected over the standard-mapping pad,
 * leaving every button and the right stick wrong) is visible without a
 * repro. A non-standard mapping is flagged loudly: it is the one state that
 * produces "only the left stick works".
 */
function padLine(pad: { id: string; mapping: string } | null): string {
  if (!pad) return '(none connected)';
  const id = pad.id.length > 40 ? `${pad.id.slice(0, 37)}...` : pad.id;
  const flag = pad.mapping === 'standard' ? 'standard' : 'NON-STANDARD';
  return `${flag}  ${id}`;
}
