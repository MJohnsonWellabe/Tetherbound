import {
  AnimationGroup,
  Mesh,
  TransformNode,
  type AbstractMesh,
  type Scene
} from '../core/babylon';
import { loadContainerOwned } from '../core/AssetLoader';

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

  loadContainerOwned(scene, entry.url)
    .then((container) => {
      if (cancelled) {
        container.dispose();
        return;
      }

      const name = `rig_${mountSerial++}`;
      // The entity OWNS this container outright: no instantiate, no clone, no
      // animation retargeting. Cloning from a shared container mis-maps bone
      // indices on files with multiple skins or bone/joint mismatches, and a
      // few stretched triangles turned birds and deer into screen-filling
      // shards (D56). addAllToScene renders the container's own nodes, whose
      // animation groups already target them.
      container.addAllToScene();
      const instance = {
        rootNodes: container.rootNodes,
        animationGroups: container.animationGroups
      };

      const root = new TransformNode(name, scene);
      // Scale and lift the WHOLE instance from its shared root, never node by
      // node. A rigged model can arrive as several sibling roots (the skinned
      // mesh and its armature are separate roots in some packs), and a
      // skinned mesh is posed by bone matrices resolved in the skeleton's
      // space. Scaling the mesh root and the armature root as independent
      // nodes puts those two spaces at different scales, and the vertices fly
      // apart into the screen-filling shards that were being blamed on the
      // renderer. One transform, applied once, above all of them.
      root.scaling.setAll(entry.scale);
      root.position.y = entry.yOffset ?? 0;
      for (const node of instance.rootNodes) {
        // instantiateModelsToScene returns Node[], but glTF roots are always
        // TransformNodes (the loader synthesizes one when the file lacks it).
        // glTF models arrive Z-forward; the game's entities face +Z with yaw
        // applied by their owners, so nothing is rotated here.
        (node as TransformNode).parent = root;
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
          // The container owns every node, skeleton, group and texture the
          // mount created; one call releases it all.
          root.dispose(false, false);
          container.dispose();
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
