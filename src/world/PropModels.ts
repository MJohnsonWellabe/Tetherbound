import { Color3, Mesh, StandardMaterial, type Scene } from '../core/babylon';
import { loadAll } from '../core/AssetLoader';
import { createPrototypes, type PropFamilyId, type PrototypeSet } from './Prototypes';
import { planProps, propUrls } from './propPlan';

/**
 * Build the prop PrototypeSet from real models, falling back to the
 * primitives per family.
 *
 * The output honours the PropBatcher contract exactly as Prototypes.ts states
 * it: one mesh per family, ONE material per family, origin at the base with
 * everything baked into vertices. The pipeline already merged each model to a
 * single vertex-coloured primitive seated at y=0 (see scripts/lib/glbtool.mjs),
 * so the work left here is instantiation, scale-baking, and bookkeeping.
 *
 * Boot awaits this, but a failed download costs one family its silhouette,
 * never the boot: `loadAll` degrades per-URL to null, and `planProps` sends
 * that family to `createPrototypes`' primitive.
 */
export async function resolvePrototypes(scene: Scene): Promise<PrototypeSet> {
  // The primitive set is built unconditionally. It is the fallback for any
  // family whose model failed, and disabled prototype meshes are near-free.
  const primitives = createPrototypes(scene);

  let containers: Awaited<ReturnType<typeof loadAll>>;
  try {
    containers = await loadAll(scene, propUrls());
  } catch {
    return primitives;
  }

  const loaded = new Map<string, boolean>();
  for (const [url, container] of containers) loaded.set(url, container !== null);

  const meshes = new Map<PropFamilyId, Mesh>(primitives.meshes);
  const materials = [...primitives.materials];

  // One shared white vertex-colour material for every model family; the
  // per-instance tint from scatter.json multiplies it, exactly as the
  // primitive families work.
  const shared = new StandardMaterial('mat_prop_models', scene);
  shared.diffuseColor = new Color3(1, 1, 1);
  shared.specularColor = new Color3(0, 0, 0);
  materials.push(shared);

  for (const plan of planProps(loaded)) {
    if (plan.source !== 'model' || !plan.variant) continue;
    const container = containers.get(plan.variant.url);
    if (!container) continue;

    // The container holds one merged mesh. Take its geometry, leave the
    // container itself for the cache to own.
    const source = container.meshes.find((m): m is Mesh => m instanceof Mesh && m.getTotalVertices() > 0);
    if (!source) continue;

    const proto = source.clone(`proto_${plan.family}_model`, null);
    if (!proto) continue;
    proto.makeGeometryUnique();
    proto.scaling.setAll(plan.variant.scale);
    // Thin instances replace the world matrix outright, so the scale has to
    // live in the vertices, same reason Prototypes.ts bakes its seating. This
    // bakes the full WORLD matrix, which is what we want: the glTF loader puts
    // its right-to-left-handed conversion on the container's `__root__`, and a
    // prop that drops it comes out mirrored.
    proto.bakeCurrentTransformIntoVertices();
    // ...and then the parent MUST go. `clone(name, null)` does not detach: a
    // null parent argument means "leave the parent alone", so the clone stayed
    // a child of `__root__`. With the conversion baked into the vertices AND
    // still applied by the parent at render time, every prop was mirrored
    // across the world origin, which put the trees near the player 2x their
    // distance away and left the Meadows looking empty (D53).
    proto.parent = null;
    proto.material = shared;
    proto.setEnabled(false);
    proto.isPickable = false;
    proto.doNotSyncBoundingInfo = true;
    proto.alwaysSelectAsActiveMesh = false;

    // Retire the primitive this family no longer needs.
    meshes.get(plan.family)?.dispose();
    meshes.set(plan.family, proto);
  }

  return { meshes, materials };
}
