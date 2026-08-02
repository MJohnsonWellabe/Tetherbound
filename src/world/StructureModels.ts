import {
  AssetContainer,
  Color3,
  Material,
  Mesh,
  Scene,
  StandardMaterial,
  TransformNode
} from '../core/babylon';
import { loadAll } from '../core/AssetLoader';

/**
 * Shared machinery for placing baked structure GLBs: village houses, the Hall
 * shell, standing stones, dressing, and stations.
 *
 * The pipeline merges every building to ONE vertex-coloured mesh seated at
 * y=0 (scripts/lib/glbtool.mjs). Two things ride on the source's composed
 * node transform that the prop path can afford to drop and this one cannot:
 * the loader's handedness conversion on __root__ (a building's door must not
 * mirror) and the dequantization scale KHR_mesh_quantization puts on the node.
 *
 * That composed transform has a NEGATIVE determinant (the right-to-left-handed
 * flip), and carrying it on every placed clone inverts the triangle winding:
 * outside walls cull away and the building reads as see-through. So it is
 * baked INTO THE VERTICES once per loaded source — bakeTransformIntoVertices
 * flips the faces back when the determinant is negative — and every placed
 * clone starts from an identity transform, same contract as PropModels.ts.
 */

let shared: StandardMaterial | null = null;

/** One white vertex-colour material for every structure model in the world. */
export function structureModelMaterial(scene: Scene): StandardMaterial {
  if (shared) return shared;
  shared = new StandardMaterial('mat_structure_models', scene);
  shared.diffuseColor = new Color3(1, 1, 1);
  shared.specularColor = new Color3(0, 0, 0);
  shared.freeze();
  return shared;
}

export function disposeStructureModelMaterial(): void {
  shared?.dispose();
  shared = null;
  for (const proto of prototypes.values()) proto.dispose();
  prototypes.clear();
}

/** Baked prototypes by url, disposed with the shared material. */
const prototypes = new Map<string, Mesh>();

/** The one merged mesh inside a pipeline-built container, or null. */
export function sourceMesh(container: AssetContainer | null | undefined): Mesh | null {
  if (!container) return null;
  return (
    container.meshes.find((m): m is Mesh => m instanceof Mesh && m.getTotalVertices() > 0) ?? null
  );
}

/**
 * A hidden, world-transform-baked prototype for a loaded container. The
 * container's own geometry stays untouched (the loader caches it), so the
 * bake happens on a unique copy, once per url.
 */
function bakedPrototype(url: string, source: Mesh): Mesh {
  const existing = prototypes.get(url);
  if (existing) return existing;

  const proto = source.clone(`structure_proto_${prototypes.size}`, null);
  proto.makeGeometryUnique();
  proto.bakeTransformIntoVertices(source.computeWorldMatrix(true));
  // The bake flips the indices back to counter-clockwise fronts (negative
  // determinant triggers flipFaces), but the loader stamped the mesh with
  // clockwise-front for the mirrored transform it was born under, and clone()
  // copies that stamp. Left standing, every placed structure renders inside
  // out: the walls you see are the unlit interior faces, and from some angles
  // whole panels vanish. Verified by flipping this live in a browser.
  proto.overrideMaterialSideOrientation = Material.CounterClockWiseSideOrientation;
  // bakeTransformIntoVertices bakes the given matrix but leaves the node's
  // own local transform standing; without this reset it applies twice.
  proto.position.setAll(0);
  proto.rotationQuaternion = null;
  proto.rotation.setAll(0);
  proto.scaling.setAll(1);
  proto.setEnabled(false);
  proto.isPickable = false;
  prototypes.set(url, proto);
  return proto;
}

/**
 * Clone a baked structure mesh under `parent`, identity local transform.
 * Placement (position, yaw, extra scale) belongs on the parent node, which
 * keeps this reusable for every structure type.
 */
export function placeStructure(
  scene: Scene,
  source: Mesh,
  name: string,
  parent: TransformNode
): Mesh {
  const clone = source.clone(name, null);
  clone.parent = parent;
  clone.material = structureModelMaterial(scene);
  clone.isPickable = false;
  clone.setEnabled(true);
  return clone;
}

/**
 * Load a set of structure URLs, degrading per-URL to null exactly like the
 * prop resolver: a missing building costs that building its model, never the
 * boot, and the caller falls back to its primitive builder for that slot.
 */
export async function loadStructureSources(
  scene: Scene,
  urls: readonly string[]
): Promise<Map<string, Mesh | null>> {
  const out = new Map<string, Mesh | null>();
  try {
    const containers = await loadAll(scene, [...new Set(urls)]);
    for (const [url, container] of containers) {
      const source = sourceMesh(container);
      out.set(url, source ? bakedPrototype(url, source) : null);
    }
  } catch {
    // loadAll only throws when the scene died mid-flight; report all-null and
    // let the caller's disposed check make it moot.
  }
  return out;
}
