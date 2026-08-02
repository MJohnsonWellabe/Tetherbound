import {
  AnimationGroup,
  Mesh,
  TransformNode,
  Vector3,
  type AbstractMesh,
  type Scene
} from '../core/babylon';
import { loadContainer } from '../core/AssetLoader';

/**
 * Mounting rigged models onto live entities without making anyone's
 * constructor async.
 *
 * The pattern every consumer uses: build your placeholder primitives NOW, call
 * `mountRig`, keep moving. When the container lands (cached after the first
 * load of each file), the callback swaps the visuals. A pal that spawns before
 * its model arrives walks around as the old capsule for a beat and then
 * becomes a fox; a failed download means it stays a capsule, and nothing else
 * notices. Boot never waits on a creature.
 *
 * Each mount instantiates its own copy of the container (meshes, skeletons and
 * AnimationGroups cloned per entity), so two spawned foxes animate
 * independently.
 */

export interface RigEntry {
  url: string;
  scale: number;
  yOffset?: number;
  clips: Record<string, string | null>;
}

export interface MountedRig {
  root: TransformNode;
  groups: ReadonlyMap<string, AnimationGroup>;
  /** Game verb -> AnimationGroup, resolved through the entry's clips map. */
  verb(name: string): AnimationGroup | null;
  dispose(): void;
}

/** Serial for unique instance names; Babylon warns on duplicates. */
let mountSerial = 0;

/**
 * Load `entry`'s model and hand a per-entity instance to `onReady`.
 *
 * Returns a cancel function. Cancelling after the rig mounted disposes it;
 * cancelling before it mounted makes the pending mount a no-op. Callers store
 * the cancel and run it from their own dispose, which makes the async gap
 * leak-proof.
 */
export function mountRig(
  scene: Scene,
  entry: RigEntry,
  onReady: (rig: MountedRig) => void
): () => void {
  let cancelled = false;
  let mounted: MountedRig | null = null;

  loadContainer(scene, entry.url)
    .then((container) => {
      if (cancelled) return;

      const name = `rig_${mountSerial++}`;
      const instance = container.instantiateModelsToScene((source) => `${name}_${source}`, false, {
        doNotInstantiate: false
      });

      const root = new TransformNode(name, scene);
      for (const node of instance.rootNodes) {
        // instantiateModelsToScene returns Node[], but glTF roots are always
        // TransformNodes (the loader synthesizes one when the file lacks it).
        const t = node as TransformNode;
        t.parent = root;
        // glTF models arrive Z-forward; the game's entities face +Z with yaw
        // applied by their owners, so only scale and lift are baked here.
        t.scaling.scaleInPlace(entry.scale);
        t.position.addInPlace(new Vector3(0, entry.yOffset ?? 0, 0));
      }

      for (const node of root.getChildMeshes()) {
        node.isPickable = false;
        (node as AbstractMesh).doNotSyncBoundingInfo = false;
      }

      const groups = new Map<string, AnimationGroup>();
      for (const group of instance.animationGroups) {
        group.stop();
        // Instantiation prefixes the group name; index by the ORIGINAL name so
        // the clips map in models.json matches.
        const original = group.name.startsWith(`${name}_`)
          ? group.name.slice(name.length + 1)
          : group.name;
        groups.set(original, group);
      }

      mounted = {
        root,
        groups,
        verb(verbName: string): AnimationGroup | null {
          const clip = entry.clips[verbName];
          return clip ? (groups.get(clip) ?? null) : null;
        },
        dispose(): void {
          for (const group of groups.values()) group.dispose();
          root.dispose(false, false);
          for (const node of instance.rootNodes) node.dispose(false, false);
        }
      };
      onReady(mounted);
    })
    .catch(() => {
      // Stays a placeholder. loadContainer already warned.
    });

  return () => {
    cancelled = true;
    mounted?.dispose();
    mounted = null;
  };
}

/** True when a mesh subtree contains real geometry (used by tests/tools). */
export function hasGeometry(root: TransformNode): boolean {
  return root.getChildMeshes().some((m) => m instanceof Mesh && m.getTotalVertices() > 0);
}
