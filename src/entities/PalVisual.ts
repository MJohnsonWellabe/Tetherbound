import {
  Color3,
  CreateCapsule,
  CreateSphere,
  Mesh,
  Scene,
  StandardMaterial,
  TransformNode
} from '../core/babylon';
import models from '../data/models.json';
import { AnimDriver } from '../anim/AnimDriver';
import { mountRig, type RigEntry } from '../anim/Rigs';
import { speciesDef } from './Species';

/**
 * Pal bodies: one DISTINCT rigged, skeletal-animated creature per species
 * (models.json `pals`), mounted asynchronously over an instant capsule
 * placeholder.
 *
 * `acquire` returns a PalBody synchronously: a root node carrying the old
 * tinted capsule, plus an AnimDriver. When the creature's GLB lands (cached
 * per file after the first spawn of a species), the capsule is swapped for
 * the rigged model and the driver starts resolving verbs. A failed download
 * means that pal stays a capsule; nothing else notices, which is the whole
 * fallback contract (models.json header).
 *
 * Owners write position/yaw to `body.root` and call `body.driver.play(verb)`.
 */

const BODY_TYPES = ['quadruped', 'smallMammal', 'amphibian', 'birdlike', 'horned', 'bulky'] as const;
export type BodyType = (typeof BODY_TYPES)[number];

/** A live pal body: a root the owner moves, and a driver it animates. */
export interface PalBody {
  root: TransformNode;
  driver: AnimDriver;
  speciesId: string;
  dispose(): void;
}

let palSerial = 0;

/** Proportions per body, so six silhouettes read differently at a glance. */
const SHAPE: Record<BodyType, { height: number; radius: number; head: number; headY: number }> = {
  quadruped: { height: 0.9, radius: 0.42, head: 0.44, headY: 0.85 },
  smallMammal: { height: 0.6, radius: 0.3, head: 0.36, headY: 0.6 },
  amphibian: { height: 0.55, radius: 0.4, head: 0.42, headY: 0.5 },
  birdlike: { height: 0.7, radius: 0.26, head: 0.34, headY: 0.72 },
  horned: { height: 1.1, radius: 0.46, head: 0.48, headY: 1.05 },
  bulky: { height: 1.0, radius: 0.6, head: 0.5, headY: 0.95 }
};

export class PalVisuals {
  private readonly prototypes = new Map<BodyType, Mesh>();
  private readonly materials = new Map<string, StandardMaterial>();

  constructor(private readonly scene: Scene) {
    for (const body of BODY_TYPES) {
      const shape = SHAPE[body];
      const trunk = CreateCapsule(
        `proto_pal_${body}`,
        { height: shape.height, radius: shape.radius },
        scene
      );
      trunk.position.y = shape.height / 2;
      trunk.bakeCurrentTransformIntoVertices();

      const head = CreateSphere(`proto_pal_${body}_head`, { diameter: shape.head, segments: 6 }, scene);
      head.position.y = shape.headY;
      head.position.z = shape.radius * 0.7;
      head.bakeCurrentTransformIntoVertices();

      const merged = Mesh.MergeMeshes([trunk, head], true, true, undefined, false, false);
      if (!merged) continue;
      merged.name = `proto_pal_${body}`;
      merged.setEnabled(false);
      merged.isPickable = false;
      this.prototypes.set(body, merged);
    }
  }

  /** A drawable, animatable body for a species. Caller owns disposal. */
  acquire(speciesId: string): PalBody | null {
    const def = speciesDef(speciesId);
    if (!def) return null;
    const bodyType = (BODY_TYPES as readonly string[]).includes(def.model.body)
      ? (def.model.body as BodyType)
      : 'quadruped';
    const proto = this.prototypes.get(bodyType);
    if (!proto) return null;

    const root = new TransformNode(`pal_${speciesId}_${palSerial++}`, this.scene);
    const driver = new AnimDriver();

    // The instant placeholder. Swapped out when the rig mounts.
    const capsule = proto.clone(`${root.name}_placeholder`, root, true);
    if (capsule) {
      capsule.material = this.materialFor(speciesId, def.model.tint);
      capsule.scaling.setAll(def.model.scale);
      capsule.setEnabled(true);
      capsule.isPickable = false;
    }

    const entry = (models.pals as Record<string, RigEntry | undefined>)[speciesId];
    let cancelRig: (() => void) | null = null;
    if (entry) {
      cancelRig = mountRig(this.scene, entry, (rig) => {
        capsule?.dispose(false, false);
        rig.root.parent = root;
        driver.attach(rig);
        driver.play('idle', performance.now());
      });
    }

    return {
      root,
      driver,
      speciesId,
      dispose(): void {
        cancelRig?.();
        driver.dispose();
        root.dispose(false, false);
      }
    };
  }

  /** One material per species, shared by every individual of it. */
  private materialFor(speciesId: string, hex: string): StandardMaterial {
    const existing = this.materials.get(speciesId);
    if (existing) return existing;
    const mat = new StandardMaterial(`mat_pal_${speciesId}`, this.scene);
    mat.diffuseColor = Color3.FromHexString(hex);
    mat.specularColor = new Color3(0, 0, 0);
    mat.freeze();
    this.materials.set(speciesId, mat);
    return mat;
  }

  dispose(): void {
    for (const mesh of this.prototypes.values()) mesh.dispose();
    for (const mat of this.materials.values()) mat.dispose();
    this.prototypes.clear();
    this.materials.clear();
  }
}
