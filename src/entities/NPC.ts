import {
  Color3,
  CreateCapsule,
  CreateSphere,
  Mesh,
  Scene,
  ShadowGenerator,
  StandardMaterial,
  TransformNode,
  Vector3
} from '../core/babylon';

/**
 * People. Grandpa Orin, two villagers, two Tether grunts, and Bracken Holt.
 *
 * ASSETS.md says to retexture one humanoid base for all of them, so that is
 * what this is: one capsule-and-sphere rig, tinted per role. Tether wears the
 * iron-orange accent the palette reserves for enemies and danger, which is the
 * only cue the player needs to know who is going to stop them.
 */

export type NpcRole = 'elder' | 'villager' | 'tether' | 'warden';

const ROLE_TINT: Record<NpcRole, string> = {
  elder: '#6a6f8c',
  villager: '#7a8a5c',
  tether: '#8a8f96',
  warden: '#4a4f58'
};

/** Tether's accent, worn as a sash so a grunt reads as Tether at distance. */
const TETHER_ACCENT = '#c25a1e';

const materials = new Map<string, StandardMaterial>();

function tint(scene: Scene, hex: string): StandardMaterial {
  const existing = materials.get(hex);
  if (existing) return existing;
  const mat = new StandardMaterial(`mat_npc_${hex}`, scene);
  mat.diffuseColor = Color3.FromHexString(hex);
  mat.specularColor = new Color3(0, 0, 0);
  materials.set(hex, mat);
  return mat;
}

export interface NpcSpec {
  id: string;
  name: string;
  role: NpcRole;
  position: Vector3;
  yaw: number;
  /** Conversation to open on interact. Swapped as the story advances. */
  dialogue: string;
  /** Hidden until the game sets a flag, e.g. Bracken after the grunts. */
  hidden?: boolean;
}

export class Npc {
  readonly id: string;
  readonly name: string;
  readonly role: NpcRole;
  dialogue: string;
  private readonly root: TransformNode;
  private readonly parts: Mesh[] = [];
  private visible = true;

  constructor(scene: Scene, spec: NpcSpec, shadows: ShadowGenerator | null) {
    this.id = spec.id;
    this.name = spec.name;
    this.role = spec.role;
    this.dialogue = spec.dialogue;

    this.root = new TransformNode(`npc_${spec.id}`, scene);
    this.root.position.copyFrom(spec.position);
    this.root.rotation.y = spec.yaw;

    const body = CreateCapsule(`npc_${spec.id}_body`, { height: 1.7, radius: 0.32 }, scene);
    body.material = tint(scene, ROLE_TINT[spec.role]);
    body.position.y = 0.85;
    body.parent = this.root;

    const head = CreateSphere(`npc_${spec.id}_head`, { diameter: 0.44, segments: 6 }, scene);
    head.material = tint(scene, '#c9a887');
    head.position.y = 1.78;
    head.parent = this.root;

    this.parts.push(body, head);

    if (spec.role === 'tether' || spec.role === 'warden') {
      const sash = CreateSphere(`npc_${spec.id}_sash`, { diameter: 0.5, segments: 6 }, scene);
      sash.material = tint(scene, TETHER_ACCENT);
      sash.scaling.set(1.35, 0.28, 1.35);
      sash.position.y = 1.3;
      sash.parent = this.root;
      this.parts.push(sash);
    }

    for (const mesh of this.parts) {
      mesh.isPickable = false;
      shadows?.addShadowCaster(mesh, false);
    }

    if (spec.hidden) this.setVisible(false);
  }

  get position(): Vector3 {
    return this.root.position;
  }

  get isVisible(): boolean {
    return this.visible;
  }

  setVisible(on: boolean): void {
    this.visible = on;
    this.root.setEnabled(on);
  }

  distanceTo(x: number, z: number): number {
    return Math.hypot(this.root.position.x - x, this.root.position.z - z);
  }

  /** Turn to face the player while they are being spoken to. */
  faceToward(x: number, z: number): void {
    this.root.rotation.y = Math.atan2(x - this.root.position.x, z - this.root.position.z);
  }

  dispose(): void {
    for (const mesh of this.parts) mesh.dispose();
    this.parts.length = 0;
    this.root.dispose();
  }
}

/**
 * Everyone in the world, and the nearest-interactable query the HUD prompt and
 * the interact button both read from.
 */
export class NpcRegistry {
  private readonly npcs: Npc[] = [];

  add(npc: Npc): Npc {
    this.npcs.push(npc);
    return npc;
  }

  get all(): readonly Npc[] {
    return this.npcs;
  }

  byId(id: string): Npc | undefined {
    return this.npcs.find((n) => n.id === id);
  }

  /** Closest visible NPC inside `range`, or null. */
  nearest(x: number, z: number, range: number): Npc | null {
    let best: Npc | null = null;
    let bestDistance = range;
    for (const npc of this.npcs) {
      if (!npc.isVisible) continue;
      const d = npc.distanceTo(x, z);
      if (d <= bestDistance) {
        best = npc;
        bestDistance = d;
      }
    }
    return best;
  }

  dispose(): void {
    for (const npc of this.npcs) npc.dispose();
    this.npcs.length = 0;
    for (const mat of materials.values()) mat.dispose();
    materials.clear();
  }
}
