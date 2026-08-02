import {
  CreateBox,
  CreateCylinder,
  Mesh,
  Scene,
  TransformNode
} from '../core/babylon';
import { structurePalette } from './Structures';

/**
 * The Meadows Hall's primitive shell: walls, lintel, roof and banner, exactly
 * as they shipped before the Fantasy Town Kit composite existed. Hall.ts
 * attaches this when the hall GLB fails to load, so the fallback keeps the
 * building the smoke spec walks through. Geometry only; the plinth, floor,
 * tether posts, road, colliders and anchors never left Hall.ts because they
 * are the part that has to stay identical either way.
 */
export function buildPrimitiveHallShell(
  scene: Scene,
  root: TransformNode,
  dims: { width: number; depth: number; wallHeight: number; wallThickness: number; doorWidth: number }
): void {
  const p = structurePalette(scene);
  const { width: WIDTH, depth: DEPTH, wallHeight: WALL_HEIGHT, wallThickness: WALL_THICKNESS, doorWidth: DOOR_WIDTH } = dims;

  const add = (mesh: Mesh): Mesh => {
    mesh.material = mesh.material ?? p.stone;
    mesh.isPickable = false;
    mesh.parent = root;
    return mesh;
  };

  const wallY = WALL_HEIGHT / 2;

  // Long walls.
  for (const side of [-1, 1]) {
    const wall = CreateBox(
      'hall_wall_long',
      { width: WALL_THICKNESS, depth: DEPTH, height: WALL_HEIGHT },
      scene
    );
    wall.position.set((side * (WIDTH - WALL_THICKNESS)) / 2, wallY, 0);
    add(wall);
  }

  // Back wall, behind the Warden.
  const back = CreateBox(
    'hall_wall_back',
    { width: WIDTH, depth: WALL_THICKNESS, height: WALL_HEIGHT },
    scene
  );
  back.position.set(0, wallY, (DEPTH - WALL_THICKNESS) / 2);
  add(back);

  // Front wall, split around the doorway.
  const frontSegment = (WIDTH - DOOR_WIDTH) / 2;
  for (const side of [-1, 1]) {
    const wall = CreateBox(
      'hall_wall_front',
      { width: frontSegment, depth: WALL_THICKNESS, height: WALL_HEIGHT },
      scene
    );
    wall.position.set(side * (DOOR_WIDTH + frontSegment) * 0.5, wallY, -(DEPTH - WALL_THICKNESS) / 2);
    add(wall);
  }

  // Lintel over the door, so the opening reads as a doorway and not a gap.
  const lintel = CreateBox(
    'hall_lintel',
    { width: DOOR_WIDTH, depth: WALL_THICKNESS, height: 1.4 },
    scene
  );
  lintel.position.set(0, WALL_HEIGHT - 0.7, -(DEPTH - WALL_THICKNESS) / 2);
  add(lintel);

  // Roof: a shallow ridge. Left open at the door end so the interior is lit and
  // the player can actually see the fight they walked into.
  const roof = CreateCylinder(
    'hall_roof',
    { height: DEPTH * 0.82, diameterTop: 0, diameterBottom: WIDTH * 1.14, tessellation: 4 },
    scene
  );
  roof.rotation.set(Math.PI / 2, Math.PI / 4, 0);
  roof.position.set(0, WALL_HEIGHT + 0.6, DEPTH * 0.09);
  roof.material = p.timber;
  add(roof);
}

/** The primitive banner: the only large flat iron-orange in the world. */
export function buildPrimitiveHallBanner(
  scene: Scene,
  root: TransformNode,
  dims: { depth: number; wallHeight: number; wallThickness: number }
): void {
  const p = structurePalette(scene);
  const banner = CreateBox('hall_banner', { width: 5.5, depth: 0.2, height: 5 }, scene);
  banner.position.set(0, dims.wallHeight * 0.6, (dims.depth - dims.wallThickness) / 2 - 0.8);
  banner.material = p.iron;
  banner.isPickable = false;
  banner.parent = root;
}
