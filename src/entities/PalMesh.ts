import {
  Color3,
  CreateCapsule,
  CreateCylinder,
  CreateSphere,
  CreateTorus,
  Mesh,
  Scene,
  ShadowGenerator,
  StandardMaterial,
  TransformNode
} from '../core/babylon';
import type { SpeciesDef } from '../party/Species';

/**
 * Placeholder pal geometry, and the pool that recycles it.
 *
 * ASSETS.md says a pal is "a capsule with a tinted sphere head" until M5, and
 * that the 15-species roster should come from a small number of rigs varied by
 * tint, scale and one accessory. That is exactly what this is: ONE rig shape
 * that every species borrows, re-proportioned and re-tinted on acquire.
 *
 * Pooling is not premature here. CLAUDE.md calls out object pools for pals as a
 * day-one requirement because retrofitting them is a rewrite, and spawning is
 * continuous: walking a straight line across the Meadows churns pals in and out
 * of range for as long as the session lasts.
 */

/** Proportions per body shape, as multipliers on the rig's base primitives. */
const BODIES: Record<string, { length: number; girth: number; headSize: number; lift: number }> = {
  hare: { length: 0.9, girth: 1.0, headSize: 1.0, lift: 0.5 },
  canid: { length: 1.35, girth: 0.9, headSize: 0.95, lift: 0.55 },
  newt: { length: 1.5, girth: 0.75, headSize: 0.8, lift: 0.3 },
  moth: { length: 0.7, girth: 1.15, headSize: 0.7, lift: 0.9 },
  bird: { length: 0.85, girth: 0.95, headSize: 0.85, lift: 0.7 },
  bulk: { length: 1.1, girth: 1.5, headSize: 0.85, lift: 0.45 },
  horned: { length: 1.4, girth: 1.25, headSize: 1.0, lift: 0.6 }
};

const DEFAULT_BODY = { length: 1, girth: 1, headSize: 1, lift: 0.5 };

/** One material per tint, shared across every pal wearing it. */
const materials = new Map<string, StandardMaterial>();

function tintMaterial(scene: Scene, hex: string): StandardMaterial {
  const existing = materials.get(hex);
  if (existing) return existing;
  const mat = new StandardMaterial(`mat_pal_${hex}`, scene);
  mat.diffuseColor = Color3.FromHexString(hex);
  // Flat and saturated, matching the scenery. A specular pal reads as plastic
  // next to a flat-shaded tree.
  mat.specularColor = new Color3(0, 0, 0);
  materials.set(hex, mat);
  return mat;
}

/** Drop the shared tint materials. Called once on teardown, not per pal. */
export function disposePalMaterials(): void {
  for (const mat of materials.values()) mat.dispose();
  materials.clear();
}

export class PalMesh {
  readonly root: TransformNode;
  private readonly body: Mesh;
  private readonly head: Mesh;
  private readonly horn: Mesh;
  private readonly ring: Mesh;
  private readonly collar: Mesh;

  constructor(scene: Scene, private readonly shadows: ShadowGenerator | null) {
    this.root = new TransformNode('pal', scene);

    this.body = CreateCapsule('pal_body', { height: 1.1, radius: 0.34 }, scene);
    this.body.rotation.x = Math.PI / 2; // lie the capsule along its length
    this.body.parent = this.root;

    this.head = CreateSphere('pal_head', { diameter: 0.5, segments: 6 }, scene);
    this.head.parent = this.root;

    this.horn = CreateCylinder(
      'pal_horn',
      { height: 0.5, diameterTop: 0, diameterBottom: 0.22, tessellation: 5 },
      scene
    );
    this.horn.parent = this.root;

    this.ring = CreateTorus('pal_ring', { diameter: 0.8, thickness: 0.07, tessellation: 8 }, scene);
    this.ring.parent = this.root;

    // Tether's collar. Deliberately the one part that is never species-tinted:
    // an iron-orange band is the read that this pal cannot be caught, and it
    // has to be legible at phone size before the orb bounces.
    this.collar = CreateTorus(
      'pal_collar',
      { diameter: 0.56, thickness: 0.09, tessellation: 8 },
      scene
    );
    this.collar.parent = this.root;
    const collarMat = tintMaterial(scene, '#d0621f');
    this.collar.material = collarMat;

    for (const mesh of [this.body, this.head, this.horn, this.ring, this.collar]) {
      mesh.isPickable = false;
    }
    shadows?.addShadowCaster(this.body, true);
    this.setEnabled(false);
  }

  /** Re-proportion and re-tint this rig for a species. */
  apply(scene: Scene, def: SpeciesDef, collared: boolean): void {
    const shape = BODIES[def.look.body] ?? DEFAULT_BODY;
    const scale = def.look.scale;
    const mat = tintMaterial(scene, def.look.tint);

    this.body.material = mat;
    this.head.material = mat;
    this.horn.material = mat;
    this.ring.material = mat;

    this.root.scaling.setAll(scale);

    this.body.scaling.set(shape.girth, shape.length, shape.girth);
    this.body.position.set(0, shape.lift, 0);

    this.head.scaling.setAll(shape.headSize);
    this.head.position.set(0, shape.lift + 0.24, shape.length * 0.52);

    const accessory = def.look.accessory;
    this.horn.setEnabled(accessory === 'horn' || accessory === 'crest' || accessory === 'plume');
    if (accessory === 'horn') {
      this.horn.position.set(0, shape.lift + 0.6, shape.length * 0.5);
      this.horn.rotation.set(0.3, 0, 0);
      this.horn.scaling.setAll(1);
    } else if (accessory === 'crest') {
      this.horn.position.set(0, shape.lift + 0.55, shape.length * 0.2);
      this.horn.rotation.set(-0.2, 0, 0);
      this.horn.scaling.set(0.7, 0.8, 0.7);
    } else if (accessory === 'plume') {
      this.horn.position.set(0, shape.lift + 0.35, -shape.length * 0.55);
      this.horn.rotation.set(-1.1, 0, 0);
      this.horn.scaling.set(0.8, 1.1, 0.8);
    }

    // Moss reuses the ring flattened onto the back rather than adding a sixth
    // primitive to every rig for one species family.
    this.ring.setEnabled(accessory === 'spark_ring' || accessory === 'moss');
    if (accessory === 'spark_ring') {
      this.ring.position.set(0, shape.lift + 0.15, -shape.length * 0.1);
      this.ring.rotation.set(0, 0, 0);
      this.ring.scaling.setAll(1);
    } else if (accessory === 'moss') {
      this.ring.position.set(0, shape.lift + 0.3, 0);
      this.ring.rotation.set(Math.PI / 2, 0, 0);
      this.ring.scaling.set(0.9, 0.9, 0.35);
    }

    this.collar.setEnabled(collared);
    this.collar.position.set(0, shape.lift + 0.16, shape.length * 0.36);
    this.collar.rotation.set(Math.PI / 2, 0, 0);
  }

  setPosition(x: number, y: number, z: number): void {
    this.root.position.set(x, y, z);
  }

  setYaw(yaw: number): void {
    this.root.rotation.y = yaw;
  }

  /** Bob the body slightly. Cheap, and a completely still pal reads as dead. */
  animate(elapsedMs: number, moving: boolean): void {
    const amp = moving ? 0.07 : 0.03;
    const rate = moving ? 0.009 : 0.003;
    this.body.rotation.z = Math.sin(elapsedMs * rate) * amp;
  }

  setEnabled(on: boolean): void {
    this.root.setEnabled(on);
  }

  dispose(): void {
    this.shadows?.removeShadowCaster(this.body, true);
    this.body.dispose();
    this.head.dispose();
    this.horn.dispose();
    this.ring.dispose();
    this.collar.dispose();
    this.root.dispose();
  }
}

/**
 * Fixed-capacity pool. `acquire` returns null when exhausted rather than
 * growing, so the active-pal cap from combat.json is enforced by the thing that
 * owns the memory instead of being a number a caller has to remember.
 *
 * Rigs are built on first use rather than all at boot. Pooling still holds:
 * once a rig exists it is reused forever and never reallocated. Preallocating
 * the full capacity meant 60 meshes in the scene before a single pal had
 * spawned, and Babylon walks `scene.meshes` every frame to pick active meshes,
 * so an empty pool was costing frame time in the village where nothing spawns.
 */
export class PalMeshPool {
  private readonly free: PalMesh[] = [];
  private readonly all: PalMesh[] = [];

  constructor(
    private readonly scene: Scene,
    private readonly shadows: ShadowGenerator | null,
    private readonly capacity: number
  ) {}

  acquire(def: SpeciesDef, collared: boolean): PalMesh | null {
    let mesh = this.free.pop();
    if (!mesh) {
      if (this.all.length >= this.capacity) return null;
      mesh = new PalMesh(this.scene, this.shadows);
      this.all.push(mesh);
    }
    mesh.apply(this.scene, def, collared);
    mesh.setEnabled(true);
    return mesh;
  }

  release(mesh: PalMesh): void {
    mesh.setEnabled(false);
    if (!this.free.includes(mesh)) this.free.push(mesh);
  }

  /** Slots that could still be handed out: idle rigs plus unbuilt capacity. */
  get available(): number {
    return this.free.length + (this.capacity - this.all.length);
  }

  dispose(): void {
    for (const mesh of this.all) mesh.dispose();
    this.all.length = 0;
    this.free.length = 0;
    disposePalMaterials();
  }
}
