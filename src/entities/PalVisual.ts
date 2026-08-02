import {
  Color3,
  CreateCapsule,
  CreateSphere,
  Mesh,
  Scene,
  StandardMaterial
} from '../core/babylon';
import { speciesDef } from './Species';

/**
 * Placeholder pal geometry, and the pool that draws it.
 *
 * ASSETS.md: "A pal is a capsule with a tinted sphere head." Real CC0 models
 * arrive in M5, and because every pal is described by `model.body`, `tint`,
 * `scale` and `accessory` in species.json, that swap is a data change.
 *
 * One mesh per body type, cloned per active pal, one material per species.
 * With the spawn cap at 12 that is at most 12 extra draw calls on top of the
 * world's 67, which keeps the whole frame inside ARCHITECTURE.md's 150.
 *
 * Pooled from the first frame, per CLAUDE.md's performance discipline:
 * allocating a mesh every time something spawns is the thing you cannot
 * retrofit later.
 */

const BODY_TYPES = ['quadruped', 'smallMammal', 'amphibian', 'birdlike', 'horned', 'bulky'] as const;
export type BodyType = (typeof BODY_TYPES)[number];

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

  /** A drawable body for a species. Caller owns disposal via releaseMesh. */
  acquireMesh(speciesId: string): Mesh | null {
    const def = speciesDef(speciesId);
    if (!def) return null;
    const body = (BODY_TYPES as readonly string[]).includes(def.model.body)
      ? (def.model.body as BodyType)
      : 'quadruped';
    const proto = this.prototypes.get(body);
    if (!proto) return null;

    const mesh = proto.clone(`pal_${speciesId}_${Math.floor(performance.now())}`, null, true);
    if (!mesh) return null;
    mesh.material = this.materialFor(speciesId, def.model.tint);
    mesh.scaling.setAll(def.model.scale);
    mesh.setEnabled(true);
    mesh.isPickable = false;
    return mesh;
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
