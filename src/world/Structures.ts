import {
  Color3,
  CreateBox,
  CreateCylinder,
  Mesh,
  Scene,
  ShadowGenerator,
  StandardMaterial,
  TransformNode,
  Vector3
} from '../core/babylon';
import landmarks from '../data/landmarks.json';
import { subRng } from './gen/Rng';
import type { Terrain } from './gen/Terrain';
import type { Placement } from './Landmarks';

/**
 * Hollowbrook and the standing stones, built from primitives.
 *
 * ASSETS.md places real CC0 models at M5 and is explicit that anything missing
 * from a kit "gets built from primitives in code, which is acceptable and
 * fast". Silhouette is what has to be right at phone size, so these are shaped
 * for readability at distance rather than detail up close.
 *
 * Materials are shared module-wide, per the draw-call budget. One stone
 * material serves every stone in the world.
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
  if (!palette) return;
  for (const mat of Object.values(palette)) mat.dispose();
  palette = null;
}

/** A box with a pyramid roof. The whole village vocabulary. */
function house(
  scene: Scene,
  parent: TransformNode,
  p: Palette,
  width: number,
  depth: number,
  height: number,
  shadows: ShadowGenerator | null
): TransformNode {
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

/**
 * Hollowbrook. Always at the origin, on the plateau Terrain already flattens,
 * so this needs no placement search of its own.
 */
export function buildVillage(
  scene: Scene,
  terrain: Terrain,
  seed: string,
  shadows: ShadowGenerator | null
): BuiltStructure {
  const p = structurePalette(scene);
  const root = new TransformNode('hollowbrook', scene);
  const rng = subRng(seed, 'village');
  const colliders: { x: number; z: number; radius: number }[] = [];
  const meshes: Mesh[] = [];

  const count = landmarks.village.houses;
  const ring = landmarks.village.radius * 0.55;

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

    const node = house(scene, root, p, width, depth, height, shadows);
    node.position.set(x, terrain.heightAt(x, z), z);
    node.rotation.y = angle + Math.PI / 2 + (rng() - 0.5) * 0.4;

    colliders.push({ x, z, radius: Math.max(width, depth) * 0.5 });
  }

  return {
    root,
    colliders,
    dispose: () => {
      for (const m of meshes) m.dispose();
      root.dispose(false, false);
    }
  };
}

/**
 * The standing stones, and the Loamking's ground.
 *
 * A ring of leaning monoliths. The lean is what stops seven identical boxes
 * from reading as a fence.
 */
export function buildStandingStones(
  scene: Scene,
  placement: Placement,
  terrain: Terrain,
  seed: string,
  shadows: ShadowGenerator | null
): BuiltStructure {
  const p = structurePalette(scene);
  const root = new TransformNode('standing_stones', scene);
  const rng = subRng(seed, 'stones');
  const colliders: { x: number; z: number; radius: number }[] = [];

  const count = landmarks.standingStones.stones;
  const radius = landmarks.standingStones.ringRadius;

  for (let i = 0; i < count; i++) {
    const angle = (i / count) * Math.PI * 2;
    const x = placement.x + Math.cos(angle) * radius;
    const z = placement.z + Math.sin(angle) * radius;
    const height = 4.5 + rng() * 2.5;

    const stone = CreateBox(
      'standing_stone',
      { width: 1.5 + rng() * 0.8, depth: 0.9 + rng() * 0.4, height },
      scene
    );
    stone.material = p.stone;
    stone.position.set(x, terrain.heightAt(x, z) + height / 2 - 0.4, z);
    stone.rotation.set((rng() - 0.5) * 0.18, angle, (rng() - 0.5) * 0.18);
    stone.isPickable = false;
    stone.parent = root;
    shadows?.addShadowCaster(stone, false);

    colliders.push({ x, z, radius: 1.1 });
  }

  // A low altar in the middle, so the ring has a centre worth walking to.
  const altar = CreateCylinder(
    'stones_altar',
    { height: 0.7, diameter: 4.4, tessellation: 7 },
    scene
  );
  altar.material = p.stone;
  altar.position.set(placement.x, terrain.heightAt(placement.x, placement.z) + 0.35, placement.z);
  altar.isPickable = false;
  altar.parent = root;
  shadows?.addShadowCaster(altar, false);

  return {
    root,
    colliders,
    dispose: () => root.dispose(false, false)
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
