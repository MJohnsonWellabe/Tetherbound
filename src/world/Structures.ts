import {
  Color3,
  CreateBox,
  CreateCylinder,
  Mesh,
  PointLight,
  Scene,
  ShadowGenerator,
  StandardMaterial,
  TransformNode,
  Vector3
} from '../core/babylon';
import { bus } from '../core/EventBus';
import { hingeSettled, stepHinge } from '../building/Door';
import { DoorRegistry, type DoorHandle } from '../building/DoorRegistry';
import landmarks from '../data/landmarks.json';
import models from '../data/models.json';
import { subRng } from './gen/Rng';
import type { Terrain } from './gen/Terrain';
import {
  disposeStructureModelMaterial,
  loadStructureSources,
  placeStructure
} from './StructureModels';
import { doorLeafPivotX, toWorld, wallRingColliders, type WallCollider } from './WallRing';

/**
 * Hollowbrook, built from Fantasy Town Kit composites with the original
 * primitive builders kept as the per-slot fallback (same shape as
 * PropModels.ts / Prototypes.ts): placements and colliders are computed
 * synchronously from the same layout numbers as ever, the models arrive
 * async, and a failed download costs one building its silhouette rather than
 * the boot or a collider.
 *
 * Materials are shared module-wide, per the draw-call budget.
 */

interface Palette {
  plaster: StandardMaterial;
  timber: StandardMaterial;
  thatch: StandardMaterial;
  stone: StandardMaterial;
  road: StandardMaterial;
  iron: StandardMaterial;
  /** The one furnished house's blanket, so the bed reads as a bed and not a crate. */
  bedding: StandardMaterial;
  /** Self-lit, since only src/core/babylon.ts may add a real point light and it is off
   * limits mid-edit elsewhere; an emissive glow is the stand-in for "lived-in" warmth. */
  lamp: StandardMaterial;
}

let palette: Palette | null = null;

function flat(scene: Scene, name: string, hex: string): StandardMaterial {
  const mat = new StandardMaterial(name, scene);
  mat.diffuseColor = Color3.FromHexString(hex);
  mat.specularColor = new Color3(0, 0, 0);
  return mat;
}

function glow(scene: Scene, name: string, hex: string): StandardMaterial {
  const mat = new StandardMaterial(name, scene);
  const color = Color3.FromHexString(hex);
  mat.diffuseColor = color;
  mat.emissiveColor = color;
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
    iron: flat(scene, 'mat_tether_iron', '#c25a1e'),
    bedding: flat(scene, 'mat_bedding', '#7a3535'),
    lamp: glow(scene, 'mat_home_lamp', '#ffb066')
  };
  return palette;
}

export function disposeStructurePalette(): void {
  disposeStructureModelMaterial();
  if (!palette) return;
  for (const mat of Object.values(palette)) mat.dispose();
  palette = null;
}

/** A box with a pyramid roof. The fallback village vocabulary. */
export function primitiveHouse(
  scene: Scene,
  parent: TransformNode,
  width: number,
  depth: number,
  height: number,
  shadows: ShadowGenerator | null
): TransformNode {
  const p = structurePalette(scene);
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

export interface HomeAnchor {
  /** World position, at the house's own ground height. */
  position: Vector3;
  /** Facing, radians, matching the house's own yaw. */
  yaw: number;
}

export interface BuiltStructure {
  root: TransformNode;
  /** Sphere colliders the character controller tests against. */
  colliders: WallCollider[];
  /** Where the player's furnished house sits, for a later milestone's wake-up spawn. Village only. */
  home?: HomeAnchor;
  dispose: () => void;
}

interface DressingEntry {
  url: string;
  x: number;
  z: number;
  rotY: number;
  collider: number;
}

const HOUSE_VARIANTS = models.buildings.houses.variants;
const DRESSING = models.buildings.dressing as DressingEntry[];
type HouseVariant = (typeof HOUSE_VARIANTS)[number];
type HouseDoorConfig = NonNullable<HouseVariant['door']>;
const WALL_STEP = landmarks.village.wallColliderStep;
const HOME = landmarks.village.home;
const DOOR_LEAF = models.buildings.houses.doorLeaf;
const BED_MODEL = models.stations.bed;
/** See landmarks.json's playerRadius comment for why this is duplicated here. */
const PLAYER_RADIUS = landmarks.playerRadius;

/**
 * Hollowbrook. Always at the origin, on the plateau Terrain already flattens,
 * so this needs no placement search of its own.
 *
 * The rng draws are byte-identical to the primitive-only version: every draw
 * still happens, in the same order, so positions and colliders match what
 * every earlier save and screenshot established.
 */
export function buildVillage(
  scene: Scene,
  terrain: Terrain,
  seed: string,
  shadows: ShadowGenerator | null,
  doorRegistry: DoorRegistry
): BuiltStructure {
  const root = new TransformNode('hollowbrook', scene);
  const rng = subRng(seed, 'village');
  const p = structurePalette(scene);
  // A house's OWN circular collider used to be `Math.max(width, depth) * 0.5`
  // of the primitive fallback's dimensions, sized well under the real
  // model's footprint and leaving the corners open no matter how it was
  // sized (D58's inside-out fix addressed the winding; this addresses the
  // gap the camera boom and the player were both walking through). It is
  // replaced below with a wall-ring hugging the REAL loaded footprint, with
  // a gap at the doorway.
  const colliders: WallCollider[] = [];

  const count = landmarks.village.houses;
  const ring = landmarks.village.radius * 0.55;
  const homeIndex = Math.min(HOME.houseIndex, count - 1);

  interface Slot {
    node: TransformNode;
    width: number;
    depth: number;
    height: number;
    variant: HouseVariant;
  }
  const slots: Slot[] = [];

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

    const node = new TransformNode(`house_slot_${i}`, scene);
    node.parent = root;
    node.position.set(x, terrain.heightAt(x, z), z);
    node.rotation.y = angle + Math.PI / 2 + (rng() - 0.5) * 0.4;

    slots.push({ node, width, depth, height, variant: HOUSE_VARIANTS[i % HOUSE_VARIANTS.length]! });
  }

  const dressingColliders: WallCollider[] = [];
  for (const d of DRESSING) {
    if (d.collider > 0) dressingColliders.push({ x: d.x, z: d.z, radius: d.collider });
  }

  // A wall ring from the primitive fallback dimensions, so a collider exists
  // on the very first frame rather than only once the network round trip in
  // the async block below resolves. Solid all the way round (no door gap):
  // the primitive box has no doorway geometry to walk through anyway.
  const placeholderWalls = (): WallCollider[] => {
    const out: WallCollider[] = [];
    for (const slot of slots) {
      out.push(
        ...wallRingColliders({
          halfWidth: slot.width / 2,
          halfDepth: slot.depth / 2,
          originX: slot.node.position.x,
          originZ: slot.node.position.z,
          yaw: slot.node.rotation.y,
          step: WALL_STEP,
          playerRadius: PLAYER_RADIUS
        })
      );
    }
    return out;
  };
  colliders.push(...placeholderWalls(), ...dressingColliders);

  const homeSlot = slots[homeIndex]!;
  const home: HomeAnchor = {
    position: new Vector3(homeSlot.node.position.x, homeSlot.node.position.y, homeSlot.node.position.z),
    yaw: homeSlot.node.rotation.y
  };

  let disposed = false;
  const doorUnregisters: (() => void)[] = [];

  void (async () => {
    const urls = [...slots.map((s) => s.variant.url), ...DRESSING.map((d) => d.url), BED_MODEL.url];
    const sources = await loadStructureSources(scene, urls);
    if (disposed || scene.isDisposed) return;

    // The whole house-collider list is rebuilt in one pass once every URL
    // has resolved (success or fallback), so nothing ever observes a
    // half-updated mix of placeholder and real walls.
    const houseColliders: WallCollider[] = [];

    for (const [i, slot] of slots.entries()) {
      const source = sources.get(slot.variant.url) ?? null;
      let halfWidth = slot.width / 2;
      let halfDepth = slot.depth / 2;
      let door: HouseDoorConfig | undefined = slot.variant.door;

      if (source) {
        const mesh = placeStructure(scene, source, 'house_model', slot.node);
        mesh.scaling.scaleInPlace(slot.variant.scale);
        shadows?.addShadowCaster(mesh, false);
        if (door) {
          // The wall PLANE, not the model's bounding box: the bbox includes
          // the roof overhang (measured ~0.05m wider per side than the walls
          // at house_a's scale), which used to size the collider ring
          // outside the real walls and let both the player and the camera
          // boom stand inside them. door.z is models.json's own name for the
          // front wall's plane, and every shipped house variant is a square
          // footprint (scripts/asset-jobs.mjs's houseA/B/C tile grids), so
          // one measurement doubles as both half-extents.
          halfWidth = Math.abs(door.z) * slot.variant.scale;
          halfDepth = halfWidth;
        } else {
          const box = mesh.getBoundingInfo().boundingBox;
          halfWidth = ((box.maximum.x - box.minimum.x) / 2) * slot.variant.scale;
          halfDepth = ((box.maximum.z - box.minimum.z) / 2) * slot.variant.scale;
        }
        mesh.freezeWorldMatrix();
      } else {
        primitiveHouse(scene, slot.node, slot.width, slot.depth, slot.height, shadows);
        // No aperture geometry on the primitive fallback, so no doorway gap.
        door = undefined;
      }

      houseColliders.push(
        ...wallRingColliders({
          halfWidth,
          halfDepth,
          originX: slot.node.position.x,
          originZ: slot.node.position.z,
          yaw: slot.node.rotation.y,
          step: WALL_STEP,
          playerRadius: PLAYER_RADIUS,
          ...(door ? { doorGapWidth: door.width, doorX: door.x } : {})
        })
      );

      if (door) doorUnregisters.push(mountHouseDoor(scene, slot.node, door, doorRegistry, shadows, p));
      if (i === homeIndex) {
        furnishHome(scene, slot.node, shadows, p, sources.get(BED_MODEL.url) ?? null);
      }
    }

    colliders.length = 0;
    colliders.push(...houseColliders, ...dressingColliders);

    // Dressing is garnish: a piece that failed to load is simply absent. Its
    // collider stands either way, which beats a walk-through stall.
    for (const [i, d] of DRESSING.entries()) {
      const source = sources.get(d.url) ?? null;
      if (!source) continue;
      const node = new TransformNode(`dressing_${i}`, scene);
      node.parent = root;
      node.position.set(d.x, terrain.heightAt(d.x, d.z), d.z);
      node.rotation.y = d.rotY;
      const mesh = placeStructure(scene, source, 'dressing_model', node);
      shadows?.addShadowCaster(mesh, false);
      mesh.freezeWorldMatrix();
    }
  })();

  return {
    root,
    colliders,
    home,
    dispose: () => {
      disposed = true;
      for (const unregister of doorUnregisters) unregister();
      root.dispose(false, false);
    }
  };
}

/**
 * A house door: a hinge pivot parented to the house's own node (so it
 * inherits the house's position and yaw for free, unlike BuildMode's
 * player-placed doors which carry their own absolute world transform) with
 * a procedural leaf, same shape as `BuildMode.mountDoor`. Registers into the
 * shared DoorRegistry so it is reachable through the same E-to-open path as
 * a player-built door. Returns the unregister function for `dispose()`.
 */
function mountHouseDoor(
  scene: Scene,
  houseNode: TransformNode,
  door: HouseDoorConfig,
  doorRegistry: DoorRegistry,
  shadows: ShadowGenerator | null,
  p: Palette
): () => void {
  const leafWidth = door.width * DOOR_LEAF.widthFraction;
  const leafHeight = door.height * DOOR_LEAF.heightFraction;

  const pivot = new TransformNode('house_door_pivot', scene);
  pivot.parent = houseNode;
  // door.x is the APERTURE's centre; the pivot is the LEAF's own left edge
  // (same convention BuildMode.mountDoor uses below, leaf.position.x =
  // leafWidth/2 relative to the pivot). Placing the pivot straight at the
  // aperture centre put every leaf half a width to the right of where it
  // belonged: it covered the right half of the hole and continued across
  // solid wall. doorLeafPivotX centres the (slightly narrower) leaf on the
  // aperture instead.
  pivot.position.set(doorLeafPivotX(door.x, leafWidth), 0, door.z);

  const leaf = CreateBox('house_door_leaf', { width: leafWidth, height: leafHeight, depth: DOOR_LEAF.depth }, scene);
  leaf.parent = pivot;
  leaf.position.set(leafWidth / 2, leafHeight / 2, 0);
  leaf.material = p.timber;
  leaf.isPickable = false;
  shadows?.addShadowCaster(leaf, false);

  let angle = 0;
  let open = false;
  pivot.rotation.y = door.yaw;

  const worldOrigin = () => toWorld(houseNode.position.x, houseNode.position.z, houseNode.rotation.y, door.x, door.z);

  const handle: DoorHandle = {
    // Fixed at mount time: houses never move, so this needs no per-query recompute.
    position: worldOrigin(),
    isOpen: () => open,
    toggle: () => {
      open = !open;
      const world = worldOrigin();
      bus.emit('doorToggled', { open, at: { x: world.x, y: houseNode.position.y, z: world.z } });
    },
    step: (dtMs: number) => {
      if (hingeSettled(angle, open)) return;
      angle = stepHinge(angle, open, dtMs);
      pivot.rotation.y = door.yaw + angle;
    }
  };
  return doorRegistry.register(handle);
}

/**
 * Furniture for the player's home: a floor slab, a bed, and a warm point
 * light by it, so this one house reads as lived-in rather than a gray shell
 * like every other one. Everything here is a child of the house's own node
 * so it disposes with the house automatically (TransformNode.dispose walks
 * every descendant Node, lights included, not only meshes).
 *
 * `bedSource` is the real furniture-kit bed model once it has loaded
 * (models.stations.bed, the same GLB the bed station already places, so this
 * needs no new asset job); a box frame and a bedding slab stand in per the
 * D44 degrade-one-thing rule while it is in flight or if it never arrives.
 */
function furnishHome(
  scene: Scene,
  houseNode: TransformNode,
  shadows: ShadowGenerator | null,
  p: Palette,
  bedSource: Mesh | null
): void {
  const node = new TransformNode('home_furniture', scene);
  node.parent = houseNode;

  const floor = CreateBox('home_floor', { width: HOME.floor.width, depth: HOME.floor.depth, height: 0.1 }, scene);
  floor.position.set(0, 0.05, HOME.floor.depth / 2 - HOME.floor.inset);
  floor.material = p.road;
  floor.isPickable = false;
  floor.parent = node;

  const yaw = (HOME.bed.yawDeg * Math.PI) / 180;
  const bedSlot = new TransformNode('home_bed_slot', scene);
  bedSlot.parent = node;
  bedSlot.position.set(HOME.bed.x, 0, HOME.bed.z);
  bedSlot.rotation.y = yaw;

  if (bedSource) {
    const mesh = placeStructure(scene, bedSource, 'home_bed_model', bedSlot);
    mesh.scaling.scaleInPlace(BED_MODEL.scale);
    shadows?.addShadowCaster(mesh, false);
    mesh.freezeWorldMatrix();
  } else {
    const frame = CreateBox(
      'home_bed_frame',
      { width: HOME.bed.width, depth: HOME.bed.length, height: HOME.bed.height },
      scene
    );
    frame.position.set(0, HOME.bed.height / 2, 0);
    frame.material = p.timber;
    frame.isPickable = false;
    frame.parent = bedSlot;
    shadows?.addShadowCaster(frame, false);

    const beddingHeight = HOME.bed.height * 0.4;
    const bedding = CreateBox(
      'home_bedding',
      { width: HOME.bed.width * 0.92, depth: HOME.bed.length * 0.92, height: beddingHeight },
      scene
    );
    bedding.position.set(0, HOME.bed.height + beddingHeight / 2, 0);
    bedding.material = p.bedding;
    bedding.isPickable = false;
    bedding.parent = bedSlot;
  }

  const lamp = CreateCylinder(
    'home_lamp',
    { height: HOME.lamp.radius * 2, diameter: HOME.lamp.radius * 2, tessellation: 8 },
    scene
  );
  lamp.position.set(HOME.lamp.x, HOME.lamp.y, HOME.lamp.z);
  lamp.material = p.lamp;
  lamp.isPickable = false;
  lamp.parent = node;

  // The only PointLight in the game (a handheld target keeps it to one):
  // the emissive cylinder above reads as a lamp but casts nothing, which is
  // why the room read as pitch black even standing right beside it.
  const light = new PointLight(
    'home_lamp_light',
    new Vector3(HOME.lamp.x, HOME.lamp.y, HOME.lamp.z),
    scene
  );
  light.diffuse = Color3.FromHexString(HOME.lamp.light.color);
  light.specular = new Color3(0, 0, 0);
  light.intensity = HOME.lamp.light.intensity;
  light.range = HOME.lamp.light.range;
  light.parent = node;
}

/**
 * A structure's own placement, narrowed to only what `pointNear` needs:
 * `Placement` (Landmarks.ts) satisfies this structurally, and so does a
 * `HomeAnchor` spread with its x/z pulled out of `position`, without either
 * caller owing this file a `slope` it has no use for.
 */
export interface PointNearAnchor {
  x: number;
  y: number;
  z: number;
  yaw: number;
}

/** Where the player stands to talk to someone, offset from a structure centre. */
export function pointNear(placement: PointNearAnchor, forward: number, side = 0): Vector3 {
  const sin = Math.sin(placement.yaw);
  const cos = Math.cos(placement.yaw);
  return new Vector3(
    placement.x + sin * forward + cos * side,
    placement.y,
    placement.z + cos * forward - sin * side
  );
}

export { buildStandingStones } from './StandingStones';
