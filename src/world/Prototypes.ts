import {
  Color3,
  CreateBox,
  CreateCylinder,
  CreateSphere,
  Mesh,
  Scene,
  StandardMaterial
} from '../core/babylon';

/**
 * Placeholder prop geometry, built from primitives in code.
 *
 * ASSETS.md is explicit that this is correct and expected through M0 and M1:
 * "A pal is a capsule with a tinted sphere head. A tree is a cylinder and a
 * cone." Real CC0 models arrive in M5, and because every prop is referenced by
 * family name rather than by mesh, that swap is a data change.
 *
 * One material per family, shared across every chunk. ARCHITECTURE.md's draw
 * call budget is 150, and a per-instance material would blow it with the first
 * grove.
 */

export type PropFamily =
  | 'tree_trunk'
  | 'tree_canopy'
  | 'pine_trunk'
  | 'pine_canopy'
  | 'rock'
  | 'bush'
  | 'grass'
  | 'reed'
  | 'flower';

export interface Prototype {
  mesh: Mesh;
  /** Approximate radius for the controller's prop collision test. 0 means
   *  the player walks through it, which is right for grass and flowers. */
  collisionRadius: number;
}

function flatMaterial(scene: Scene, name: string, color: Color3): StandardMaterial {
  const mat = new StandardMaterial(name, scene);
  mat.diffuseColor = color;
  // Flat-shaded and saturated per ASSETS.md. A specular highlight on a
  // low-poly bush reads as wet plastic.
  mat.specularColor = new Color3(0, 0, 0);
  // Instance colour lets one material tint thousands of props individually.
  mat.freeze();
  return mat;
}

/**
 * Build every prototype once per scene. Each returned mesh is disabled and
 * never rendered itself; chunks clone it, share its geometry, and drive copies
 * through thin instances.
 */
export function createPrototypes(scene: Scene): Map<PropFamily, Prototype> {
  const out = new Map<PropFamily, Prototype>();

  const add = (family: PropFamily, mesh: Mesh, material: StandardMaterial, radius: number): void => {
    mesh.material = material;
    mesh.setEnabled(false);
    mesh.isPickable = false;
    mesh.doNotSyncBoundingInfo = true;
    // Scenery never moves, so its world matrix never needs recomputing.
    mesh.alwaysSelectAsActiveMesh = false;
    out.set(family, { mesh, collisionRadius: radius });
  };

  const bark = flatMaterial(scene, 'mat_bark', new Color3(0.32, 0.23, 0.15));
  const leaf = flatMaterial(scene, 'mat_leaf', new Color3(0.28, 0.45, 0.19));
  const needle = flatMaterial(scene, 'mat_needle', new Color3(0.18, 0.34, 0.21));
  const stone = flatMaterial(scene, 'mat_stone', new Color3(0.45, 0.44, 0.41));
  const scrub = flatMaterial(scene, 'mat_scrub', new Color3(0.31, 0.42, 0.2));
  const blade = flatMaterial(scene, 'mat_blade', new Color3(0.44, 0.55, 0.24));
  const bloom = flatMaterial(scene, 'mat_bloom', new Color3(0.85, 0.76, 0.35));

  // Oak: a trunk cylinder and a wide low canopy sphere.
  add('tree_trunk', CreateCylinder('proto_oak_trunk', { height: 4.2, diameterTop: 0.42, diameterBottom: 0.66, tessellation: 6 }, scene), bark, 0.5);
  add('tree_canopy', CreateSphere('proto_oak_canopy', { diameter: 5.2, segments: 5 }, scene), leaf, 0);

  // Pine: a taller trunk and a cone, kept as a separate family so groves can
  // mix silhouettes without a second material.
  add('pine_trunk', CreateCylinder('proto_pine_trunk', { height: 5.6, diameterTop: 0.26, diameterBottom: 0.52, tessellation: 6 }, scene), bark, 0.45);
  add('pine_canopy', CreateCylinder('proto_pine_canopy', { height: 5.4, diameterTop: 0, diameterBottom: 3.1, tessellation: 7 }, scene), needle, 0);

  add('rock', CreateSphere('proto_rock', { diameter: 1.8, segments: 2 }, scene), stone, 0.8);
  add('bush', CreateSphere('proto_bush', { diameter: 1.5, segments: 3 }, scene), scrub, 0.55);

  // Ground cover. No collision: walking through long grass should not feel
  // like walking through a fence.
  add('grass', CreateBox('proto_grass', { width: 0.08, height: 0.7, depth: 0.5 }, scene), blade, 0);
  add('reed', CreateBox('proto_reed', { width: 0.06, height: 1.5, depth: 0.3 }, scene), needle, 0);
  add('flower', CreateBox('proto_flower', { width: 0.16, height: 0.34, depth: 0.16 }, scene), bloom, 0);

  return out;
}

export function disposePrototypes(prototypes: Map<PropFamily, Prototype>): void {
  for (const { mesh } of prototypes.values()) {
    mesh.material?.dispose();
    mesh.dispose();
  }
  prototypes.clear();
}
