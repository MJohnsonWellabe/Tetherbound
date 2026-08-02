import type { FreeCamera, Scene } from '../core/babylon';
import stage from '../data/combatStage.json';
import { makeProjector } from '../fx/project';
import { speciesDef } from '../entities/Species';
import type { SpawnManager } from '../entities/SpawnManager';

/**
 * Name and level floating over nearby wild pals, the way every
 * creature-collector labels what you are looking at.
 *
 * Pooled DOM spans projected per render frame (the D41 pattern): zero draw
 * calls, real text rendering, distance-culled so the meadow does not become a
 * wall of labels.
 */

export class Nameplates {
  private readonly pool: HTMLElement[] = [];
  private readonly projector = makeProjector();
  private readonly point = { x: 0, y: 0 };

  constructor(
    layer: HTMLElement,
    private readonly spawner: SpawnManager
  ) {
    for (let i = 0; i < stage.nameplates.poolSize; i++) {
      const el = document.createElement('span');
      el.className = 'nameplate';
      el.setAttribute('aria-hidden', 'true');
      el.style.display = 'none';
      layer.appendChild(el);
      this.pool.push(el);
    }
  }

  /** Render phase, after the camera has settled. */
  render(
    scene: Scene,
    camera: FreeCamera,
    width: number,
    height: number,
    playerX: number,
    playerZ: number
  ): void {
    this.projector.begin(scene, camera, width, height);
    let used = 0;

    for (const pal of this.spawner.active) {
      if (used >= this.pool.length) break;
      if (Math.hypot(pal.x - playerX, pal.z - playerZ) > stage.nameplates.showWithinM) continue;
      if (!this.projector.toScreen(pal.x, pal.y + 1.6, pal.z, this.point)) continue;

      const el = this.pool[used++] as HTMLElement;
      const name = speciesDef(pal.state.species)?.name ?? pal.state.species;
      const label = `${name} Lv${pal.state.level}`;
      if (el.textContent !== label) el.textContent = label;
      el.style.display = '';
      el.style.transform = `translate3d(${this.point.x.toFixed(1)}px, ${this.point.y.toFixed(1)}px, 0) translate(-50%, -100%)`;
    }

    for (let i = used; i < this.pool.length; i++) {
      const el = this.pool[i] as HTMLElement;
      if (el.style.display !== 'none') el.style.display = 'none';
    }
  }

  dispose(): void {
    for (const el of this.pool) el.remove();
    this.pool.length = 0;
  }
}
