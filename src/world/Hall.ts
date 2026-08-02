import {
  Color3,
  CreateBox,
  CreateCylinder,
  Mesh,
  Scene,
  ShadowGenerator,
  StandardMaterial,
  TransformNode,
  Vector3
} from '../core/babylon';
import landmarks from '../data/landmarks.json';
import models from '../data/models.json';
import type { Terrain } from './gen/Terrain';
import type { Placement } from './Landmarks';
import { buildPrimitiveHallBanner, buildPrimitiveHallShell } from './HallShell';
import { loadStructureSources, placeStructure } from './StructureModels';
import { structurePalette } from './Structures';

/**
 * The Meadows Hall. A stone longhall with four chained pals in alcoves and
 * Bracken Holt waiting at the far end (GAME_DESIGN.md section 10).
 *
 * The floor sits at the terrain height of the Hall's centre, and the plinth
 * hangs DOWNWARD from it to fill whatever dip the ground has under the
 * footprint.
 *
 * The first version raised the floor above the highest ground instead, which
 * looked correct and was unplayable: the character controller walks on the
 * heightfield and knows nothing about a platform, so the player and every
 * combat pal stood more than a metre below the floor they could see, inside the
 * plinth. There is no physics engine here by design (ARCHITECTURE.md), so the
 * building has to meet the terrain rather than the other way round.
 *
 * Local space runs -z at the door to +z at the Warden, and the whole node is
 * yawed to face the village. Everything inside is positioned in that local
 * frame, so nothing here does trigonometry twice.
 */

const HALL = landmarks.hall;
const HALL_MODELS = models.buildings.hall;
const { width: WIDTH, depth: DEPTH, wallHeight: WALL_HEIGHT } = HALL.footprint;
/** How far the plinth hangs below the floor. Deep enough to bridge a dip. */
const PLATFORM_DEPTH = 8;
const WALL_THICKNESS = 1.2;
const DOOR_WIDTH = 5;

export interface HallAnchor {
  /** World position. */
  position: Vector3;
  /** Facing, radians. */
  yaw: number;
}

export interface BuiltHall {
  root: TransformNode;
  placement: Placement;
  /** Floor height inside, which everything standing in the Hall sits on. */
  floorY: number;
  /** Where the player is standing when a scripted fight triggers. */
  anchors: {
    door: HallAnchor;
    gruntA: HallAnchor;
    gruntB: HallAnchor;
    warden: HallAnchor;
    alcoves: Vector3[];
  };
  colliders: { x: number; z: number; radius: number }[];
  dispose: () => void;
}

/** Convert a point in the Hall's local frame to world space. */
function toWorld(placement: Placement, floorY: number, localX: number, localZ: number): Vector3 {
  const sin = Math.sin(placement.yaw);
  const cos = Math.cos(placement.yaw);
  return new Vector3(
    placement.x + localX * cos + localZ * sin,
    floorY,
    placement.z - localX * sin + localZ * cos
  );
}

export function buildHall(
  scene: Scene,
  placement: Placement,
  terrain: Terrain,
  shadows: ShadowGenerator | null
): BuiltHall {
  const p = structurePalette(scene);
  const root = new TransformNode('meadows_hall', scene);
  const meshes: Mesh[] = [];

  // The floor is the ground at the centre, because that is where the player
  // actually stands. Local Y in this node is measured from the floor.
  const floorY = terrain.heightAt(placement.x, placement.z);

  root.position.set(placement.x, floorY, placement.z);
  root.rotation.y = placement.yaw;

  const add = (mesh: Mesh, cast = true): Mesh => {
    mesh.material = mesh.material ?? p.stone;
    mesh.isPickable = false;
    mesh.parent = root;
    if (cast) shadows?.addShadowCaster(mesh, false);
    meshes.push(mesh);
    return mesh;
  };

  // Plinth, hanging below the floor to bridge whatever the ground does under
  // the footprint. Slightly larger than the building so it reads as a step up.
  const platform = CreateBox(
    'hall_platform',
    { width: WIDTH + 6, depth: DEPTH + 6, height: PLATFORM_DEPTH },
    scene
  );
  platform.position.y = -PLATFORM_DEPTH / 2;
  add(platform, false);

  // The floor slab is flush with the ground, set just into it so no seam shows.
  const floor = CreateBox('hall_floor', { width: WIDTH, depth: DEPTH, height: 0.3 }, scene);
  floor.position.y = -0.06;
  floor.material = p.road;
  add(floor, false);

  // The shell: walls, roof and banner from the Fantasy Town Kit composite,
  // arriving async so the boot never waits on it. Its 28m width overhangs the
  // 26m collider footprint by a metre a side, which reads as wall thickness
  // from inside; the door gap in the composite sits exactly where the collider
  // gap and door anchor already are. On any load failure the old primitive
  // shell goes up instead, so the smoke spec has a building either way.
  let shellDisposed = false;
  const shellDims = {
    width: WIDTH,
    depth: DEPTH,
    wallHeight: WALL_HEIGHT,
    wallThickness: WALL_THICKNESS,
    doorWidth: DOOR_WIDTH
  };
  void (async () => {
    const sources = await loadStructureSources(scene, [
      HALL_MODELS.shell.url,
      HALL_MODELS.banner.url
    ]);
    if (shellDisposed || scene.isDisposed) return;

    const shell = sources.get(HALL_MODELS.shell.url) ?? null;
    if (shell) {
      const mesh = placeStructure(scene, shell, 'hall_shell', root);
      mesh.scaling.scaleInPlace(HALL_MODELS.shell.scale);
      shadows?.addShadowCaster(mesh, false);
      mesh.freezeWorldMatrix();
    } else {
      buildPrimitiveHallShell(scene, root, shellDims);
    }

    // Tether's banner behind the Warden: the red kit banner when it loaded,
    // the old iron-orange slab when it did not. Either way the far end of the
    // room reads as theirs.
    const banner = sources.get(HALL_MODELS.banner.url) ?? null;
    if (banner) {
      const slot = new TransformNode('hall_banner_slot', scene);
      slot.parent = root;
      slot.position.set(
        0,
        HALL_MODELS.banner.baseY,
        (DEPTH - WALL_THICKNESS) / 2 - HALL_MODELS.banner.inset
      );
      slot.rotation.y = Math.PI / 2;
      const mesh = placeStructure(scene, banner, 'hall_banner', slot);
      mesh.scaling.scaleInPlace(HALL_MODELS.banner.scale);
      mesh.freezeWorldMatrix();
    } else {
      buildPrimitiveHallBanner(scene, root, shellDims);
    }
  })();

  // Four alcoves down the long walls, each with a tether post. These are the
  // chained pals the whole milestone is about cutting loose.
  const alcoves: Vector3[] = [];
  const alcoveCount = HALL.alcoves;
  for (let i = 0; i < alcoveCount; i++) {
    const side = i % 2 === 0 ? -1 : 1;
    const row = Math.floor(i / 2);
    const localZ = -DEPTH * 0.16 + row * DEPTH * 0.3;
    const localX = (side * (WIDTH - WALL_THICKNESS * 2 - 2.4)) / 2;

    const post = CreateCylinder(
      'hall_tether_post',
      { height: 2.6, diameter: 0.5, tessellation: 6 },
      scene
    );
    post.position.set(localX, 1.3, localZ);
    post.material = p.iron;
    add(post);

    alcoves.push(toWorld(placement, floorY, localX, localZ));
  }

  // The road stub, pointing back at Hollowbrook. Laid in segments that follow
  // the ground rather than one long box, or it floats over every dip.
  const roadRoot = new TransformNode('hall_road', scene);
  const SEGMENTS = 26;
  const segmentLength = 9;
  for (let i = 0; i < SEGMENTS; i++) {
    const t = i + 1;
    const distance = DEPTH / 2 + 4 + t * segmentLength;
    const wx = placement.x + Math.sin(placement.yaw) * distance;
    const wz = placement.z + Math.cos(placement.yaw) * distance;
    const segment = CreateBox(
      'road_segment',
      { width: HALL.roadWidth, depth: segmentLength + 0.6, height: 0.25 },
      scene
    );
    segment.position.set(wx, terrain.heightAt(wx, wz) + 0.08, wz);
    segment.rotation.y = placement.yaw;
    segment.material = p.road;
    segment.isPickable = false;
    segment.parent = roadRoot;
    meshes.push(segment);
  }

  // Colliders: the four walls as spheres along their length. Cheap, and at this
  // density the controller's per-chunk list handles it without a broadphase.
  const colliders: { x: number; z: number; radius: number }[] = [];
  const pushWallColliders = (
    fromX: number,
    fromZ: number,
    toX: number,
    toZ: number,
    step: number
  ): void => {
    const length = Math.hypot(toX - fromX, toZ - fromZ);
    const steps = Math.max(1, Math.round(length / step));
    for (let i = 0; i <= steps; i++) {
      const lx = fromX + ((toX - fromX) * i) / steps;
      const lz = fromZ + ((toZ - fromZ) * i) / steps;
      const world = toWorld(placement, floorY, lx, lz);
      colliders.push({ x: world.x, z: world.z, radius: step * 0.75 });
    }
  };
  const halfW = (WIDTH - WALL_THICKNESS) / 2;
  const halfD = (DEPTH - WALL_THICKNESS) / 2;
  pushWallColliders(-halfW, -halfD, -halfW, halfD, 3);
  pushWallColliders(halfW, -halfD, halfW, halfD, 3);
  pushWallColliders(-halfW, halfD, halfW, halfD, 3);
  // Front wall, skipping the doorway so the player can get in.
  pushWallColliders(-halfW, -halfD, -DOOR_WIDTH / 2, -halfD, 3);
  pushWallColliders(DOOR_WIDTH / 2, -halfD, halfW, -halfD, 3);

  const facing = placement.yaw + Math.PI; // into the Hall, away from the village

  return {
    root,
    placement,
    floorY,
    anchors: {
      door: { position: toWorld(placement, floorY, 0, -DEPTH / 2 - 3), yaw: facing },
      gruntA: { position: toWorld(placement, floorY, 0, -DEPTH * 0.24), yaw: placement.yaw },
      gruntB: { position: toWorld(placement, floorY, 0, DEPTH * 0.08), yaw: placement.yaw },
      warden: { position: toWorld(placement, floorY, 0, DEPTH * 0.38), yaw: placement.yaw },
      alcoves
    },
    colliders,
    dispose: (): void => {
      shellDisposed = true;
      for (const m of meshes) m.dispose();
      roadRoot.dispose(false, false);
      root.dispose(false, false);
    }
  };
}

/** Placeholder material for a freed tether, used by the victory sequence. */
export function tetherMaterial(scene: Scene): StandardMaterial {
  const mat = new StandardMaterial('mat_tether', scene);
  mat.diffuseColor = Color3.FromHexString('#c25a1e');
  mat.emissiveColor = Color3.FromHexString('#3a1a08');
  mat.specularColor = new Color3(0, 0, 0);
  return mat;
}
