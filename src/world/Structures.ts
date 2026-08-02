import {
  Color3,
  CreateBox,
  CreateCylinder,
  Scene,
  ShadowGenerator,
  StandardMaterial,
  TransformNode,
  Vector3
} from '../core/babylon';
import landmarks from '../data/landmarks.json';
import models from '../data/models.json';
import { subRng } from './gen/Rng';
import type { Terrain } from './gen/Terrain';
import type { Placement } from './Landmarks';
import {
  disposeStructureModelMaterial,
  loadStructureSources,
  placeStructure
} from './StructureModels';

/**
 * Hollowbrook, built from Fantasy Town Kit composites with the original
 * primitive builders kept as the per-slot fallback (same shape as
 * PropModels.ts / Prototypes.ts): placements and colliders are computed
 * synchronously from the same layout numbers as ever, the models arrive
 * async, and a failed download costs one building its silhouette rather than
 * the boot or a collider.
 *
 * Materials are shared module-wide, per the draw-call budget.
 */

interface Palette {
  plaster: StandardMaterial;
  timber: StandardMaterial;
  thatch: StandardMaterial;
  stone: StandardMaterial;
  road: StandardMaterial;
  iron: StandardMaterial;
}

let palette: Palette | null = null;

function flat(scene: Scene, name: string, hex: string): StandardMaterial {
  const mat = new StandardMaterial(name, scene);
  mat.diffuseColor = Color3.FromHexString(hex);
  mat.specularColor = new Color3(0, 0, 0);
  return mat;
}

export function structurePalette(scene: Scene): Palette {
  if (palette) return palette;
  palette = {
    plaster: flat(scene, 'mat_plaster', '#d8cdb4'),
    timber: flat(scene, 'mat_timber', '#5b4227'),
    thatch: flat(scene, 'mat_thatch', '#9a7b3e'),
    stone: flat(scene, 'mat_stone_block', '#7d7a72'),
    road: flat(scene, 'mat_road', '#6b5d47'),
    // The one hot accent ASSETS.md reserves for Tether and danger.
    iron: flat(scene, 'mat_tether_iron', '#c25a1e')
  };
  return palette;
}

export function disposeStructurePalette(): void {
  disposeStructureModelMaterial();
  if (!palette) return;
  for (const mat of Object.values(palette)) mat.dispose();
  palette = null;
}

/** A box with a pyramid roof. The fallback village vocabulary. */
export function primitiveHouse(
  scene: Scene,
  parent: TransformNode,
  width: number,
  depth: number,
  height: number,
  shadows: ShadowGenerator | null
): TransformNode {
  const p = structurePalette(scene);
  const node = new TransformNode('house', scene);
  node.parent = parent;

  const walls = CreateBox('house_walls', { width, depth, height }, scene);
  walls.material = p.plaster;
  walls.position.y = height / 2;
  walls.parent = node;

  const roof = CreateCylinder(
    'house_roof',
    { height: height * 0.7, diameterTop: 0, diameterBottom: Math.max(width, depth) * 1.32, tessellation: 4 },
    scene
  );
  roof.material = p.thatch;
  roof.position.y = height + height * 0.35;
  roof.rotation.y = Math.PI / 4;
  roof.parent = node;

  const beam = CreateBox('house_beam', { width: width * 1.04, depth: 0.18, height: 0.22 }, scene);
  beam.material = p.timber;
  beam.position.set(0, height * 0.98, -depth / 2);
  beam.parent = node;

  for (const mesh of [walls, roof, beam]) {
    mesh.isPickable = false;
    shadows?.addShadowCaster(mesh, false);
  }
  return node;
}

export interface BuiltStructure {
  root: TransformNode;
  /** Sphere colliders the character controller tests against. */
  colliders: { x: number; z: number; radius: number }[];
  dispose: () => void;
}

interface DressingEntry {
  url: string;
  x: number;
  z: number;
  rotY: number;
  collider: number;
}

const HOUSE_VARIANTS = models.buildings.houses.variants;
const DRESSING = models.buildings.dressing as DressingEntry[];

/**
 * Hollowbrook. Always at the origin, on the plateau Terrain already flattens,
 * so this needs no placement search of its own.
 *
 * The rng draws are byte-identical to the primitive-only version: every draw
 * still happens, in the same order, so positions and colliders match what
 * every earlier save and screenshot established.
 */
export function buildVillage(
  scene: Scene,
  terrain: Terrain,
  seed: string,
  shadows: ShadowGenerator | null
): BuiltStructure {
  const root = new TransformNode('hollowbrook', scene);
  const rng = subRng(seed, 'village');
  const colliders: { x: number; z: number; radius: number }[] = [];

  const count = landmarks.village.houses;
  const ring = landmarks.village.radius * 0.55;

  interface Slot {
    node: TransformNode;
    width: number;
    depth: number;
    height: number;
    variant: (typeof HOUSE_VARIANTS)[number];
  }
  const slots: Slot[] = [];

  for (let i = 0; i < count; i++) {
    // Spread around a ring with jitter, leaving the middle clear so the village
    // reads as a place with a square rather than a pile of buildings.
    const angle = (i / count) * Math.PI * 2 + (rng() - 0.5) * 0.5;
    const distance = ring * (0.75 + rng() * 0.4);
    const x = Math.cos(angle) * distance;
    const z = Math.sin(angle) * distance;

    const width = 6 + rng() * 3;
    const depth = 7 + rng() * 3;
    const height = 3.4 + rng() * 0.8;

    const node = new TransformNode(`house_slot_${i}`, scene);
    node.parent = root;
    node.position.set(x, terrain.heightAt(x, z), z);
    node.rotation.y = angle + Math.PI / 2 + (rng() - 0.5) * 0.4;

    slots.push({ node, width, depth, height, variant: HOUSE_VARIANTS[i % HOUSE_VARIANTS.length]! });
    colliders.push({ x, z, radius: Math.max(width, depth) * 0.5 });
  }

  for (const d of DRESSING) {
    if (d.collider > 0) colliders.push({ x: d.x, z: d.z, radius: d.collider });
  }

  let disposed = false;

  void (async () => {
    const urls = [...slots.map((s) => s.variant.url), ...DRESSING.map((d) => d.url)];
    const sources = await loadStructureSources(scene, urls);
    if (disposed || scene.isDisposed) return;

    for (const slot of slots) {
      const source = sources.get(slot.variant.url) ?? null;
      if (source) {
        const mesh = placeStructure(scene, source, 'house_model', slot.node);
        mesh.scaling.scaleInPlace(slot.variant.scale);
        shadows?.addShadowCaster(mesh, false);
        mesh.freezeWorldMatrix();
      } else {
        primitiveHouse(scene, slot.node, slot.width, slot.depth, slot.height, shadows);
      }
    }

    // Dressing is garnish: a piece that failed to load is simply absent. Its
    // collider stands either way, which beats a walk-through stall.
    for (const [i, d] of DRESSING.entries()) {
      const source = sources.get(d.url) ?? null;
      if (!source) continue;
      const node = new TransformNode(`dressing_${i}`, scene);
      node.parent = root;
      node.position.set(d.x, terrain.heightAt(d.x, d.z), d.z);
      node.rotation.y = d.rotY;
      const mesh = placeStructure(scene, source, 'dressing_model', node);
      shadows?.addShadowCaster(mesh, false);
      mesh.freezeWorldMatrix();
    }
  })();

  return {
    root,
    colliders,
    dispose: () => {
      disposed = true;
      root.dispose(false, false);
    }
  };
}

/** Where the player stands to talk to someone, offset from a structure centre. */
export function pointNear(placement: Placement, forward: number, side = 0): Vector3 {
  const sin = Math.sin(placement.yaw);
  const cos = Math.cos(placement.yaw);
  return new Vector3(
    placement.x + sin * forward + cos * side,
    placement.y,
    placement.z + cos * forward - sin * side
  );
}

export { buildStandingStones } from './StandingStones';
