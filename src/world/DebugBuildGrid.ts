import {
  Color3,
  CreateBox,
  StandardMaterial,
  TransformNode,
  type Scene,
  type ShadowGenerator
} from '../core/babylon';
import { pieceDef, pieceIds as allPieceIds } from '../building/SnapGrid';
import models from '../data/models.json';
import { loadStructureSources, placeStructure } from './StructureModels';
import type { Terrain } from './gen/Terrain';

/**
 * `?debug=build`: every building, station and build piece laid out on a flat
 * grid, so a solidity or winding problem is checkable in one screenshot
 * instead of a fifteen-minute walk through the real world.
 *
 * Zero cost when the flag is off: `main.ts` never calls this unless the query
 * param is present, and nothing here runs at import time.
 */

const SPACING = 6;
const COLUMNS = 6;
/** Well clear of Hollowbrook and the standing stones, so it never overlaps them. */
const GRID_ORIGIN = { x: 0, z: 260 };

export interface DebugGrid {
  dispose(): void;
}

export async function buildDebugGrid(
  scene: Scene,
  terrain: Terrain,
  shadows: ShadowGenerator | null
): Promise<DebugGrid> {
  const root = new TransformNode('debug_build_grid', scene);

  const houseUrls = models.buildings.houses.variants.map((v) => v.url);
  const stationEntries = Object.entries(models.stations) as [string, { url: string; scale: number }][];
  const dressingUrls = (models.buildings.dressing as { url: string }[]).map((d) => d.url);
  const pieceIds = allPieceIds();

  const cells: { label: string; kind: 'structure' | 'piece'; url?: string; scale?: number }[] = [
    ...models.buildings.houses.variants.map((v, i) => ({
      label: `house_${i}`,
      kind: 'structure' as const,
      url: v.url,
      scale: v.scale
    })),
    { label: 'hall_shell', kind: 'structure', url: models.buildings.hall.shell.url, scale: models.buildings.hall.shell.scale },
    ...stationEntries.map(([id, s]) => ({ label: id, kind: 'structure' as const, url: s.url, scale: s.scale })),
    ...dressingUrls.map((url, i) => ({ label: `dressing_${i}`, kind: 'structure' as const, url, scale: 1 })),
    ...pieceIds.map((id) => ({ label: id, kind: 'piece' as const }))
  ];

  const structureUrls = [...new Set([...houseUrls, models.buildings.hall.shell.url, ...stationEntries.map(([, s]) => s.url), ...dressingUrls])];
  const sources = await loadStructureSources(scene, structureUrls);

  for (let i = 0; i < cells.length; i++) {
    const cell = cells[i];
    if (!cell) continue;
    const gx = GRID_ORIGIN.x + (i % COLUMNS) * SPACING;
    const gz = GRID_ORIGIN.z + Math.floor(i / COLUMNS) * SPACING;
    const gy = terrain.heightAt(gx, gz);

    if (cell.kind === 'structure' && cell.url) {
      const source = sources.get(cell.url);
      if (!source) continue;
      const node = new TransformNode(`debug_${cell.label}`, scene);
      node.parent = root;
      node.position.set(gx, gy, gz);
      const mesh = placeStructure(scene, source, `debug_${cell.label}_mesh`, node);
      mesh.scaling.scaleInPlace(cell.scale ?? 1);
      shadows?.addShadowCaster(mesh, false);
    } else if (cell.kind === 'piece') {
      buildPieceCell(scene, root, cell.label, gx, gy, gz, shadows);
    }
  }

  return {
    dispose(): void {
      root.dispose(false, false);
    }
  };
}

/** A build piece as it actually renders in-game: the same box BuildMode draws. */
function buildPieceCell(
  scene: Scene,
  root: TransformNode,
  pieceId: string,
  x: number,
  y: number,
  z: number,
  shadows: ShadowGenerator | null
): void {
  const size = pieceDef(pieceId)?.size ?? [1, 1, 1];
  const holder = new TransformNode(`debug_piece_holder_${pieceId}`, scene);
  holder.parent = root;
  holder.position.set(x, y, z);

  const mesh = CreateBox(
    `debug_piece_${pieceId}`,
    { width: size[0], height: size[1], depth: size[2] },
    scene
  );
  mesh.parent = holder;
  mesh.position.set(0, size[1] / 2, 0);
  const mat = new StandardMaterial(`mat_debug_piece_${pieceId}`, scene);
  mat.diffuseColor = new Color3(0.55, 0.4, 0.25);
  mat.specularColor = new Color3(0, 0, 0);
  mesh.material = mat;
  mesh.isPickable = false;
  shadows?.addShadowCaster(mesh, false);
}
