import {
  Color3,
  CreateBox,
  CreateCylinder,
  CreateSphere,
  Mesh,
  Scene,
  StandardMaterial,
  VertexBuffer
} from '../core/babylon';

/**
 * Placeholder prop geometry, built from primitives in code.
 *
 * ASSETS.md is explicit that this is correct and expected through M0 and M1:
 * "A pal is a capsule with a tinted sphere head. A tree is a cylinder and a
 * cone." Real CC0 models arrive in M5, and because every prop is referenced by
 * family id rather than by mesh, that swap is a data change.
 *
 * Two structural decisions worth knowing before editing:
 *
 * 1. A tree is ONE mesh, not a trunk and a canopy. Colour comes from baked
 *    vertex colours rather than from two materials, so trunk and canopy merge
 *    into a single geometry. Separate parts meant every tree cost two draw
 *    calls and two thin instances for one object.
 *
 * 2. Every family shares ONE material. It is white and vertex-coloured, so a
 *    single material describes bark, leaf, needle, stone and bloom at once.
 *    Fewer materials means fewer state changes and no per-family sorting.
 *
 * Every prototype's origin sits at its own base, at ground level, with any
 * vertical offset baked into the vertices. That is what lets the batcher
 * compose a placement matrix from ground height alone, and it makes scaling
 * grow a prop upward from the soil instead of sinking it.
 */

export type PropFamilyId = 'oak' | 'pine' | 'rock' | 'bush' | 'grass' | 'reed' | 'flower';

export interface PrototypeSet {
  readonly meshes: ReadonlyMap<PropFamilyId, Mesh>;
  readonly materials: StandardMaterial[];
}

const BARK = new Color3(0.32, 0.23, 0.15);
const LEAF = new Color3(0.28, 0.45, 0.19);
const NEEDLE = new Color3(0.18, 0.34, 0.21);
const STONE = new Color3(0.45, 0.44, 0.41);
const SCRUB = new Color3(0.31, 0.42, 0.2);
const BLADE = new Color3(0.44, 0.55, 0.24);
const BLOOM = new Color3(0.85, 0.76, 0.35);

/** Write a flat colour into a mesh's colour vertex buffer. */
function paint(mesh: Mesh, color: Color3): Mesh {
  const count = mesh.getTotalVertices();
  const colors = new Float32Array(count * 4);
  for (let i = 0; i < count; i++) {
    colors[i * 4] = color.r;
    colors[i * 4 + 1] = color.g;
    colors[i * 4 + 2] = color.b;
    colors[i * 4 + 3] = 1;
  }
  mesh.setVerticesData(VertexBuffer.ColorKind, colors, false);
  return mesh;
}

/**
 * Lift a mesh so its base sits at y=0 and bake that into the vertices.
 *
 * Baking rather than leaving it on the transform matters because thin
 * instances replace the mesh's world matrix outright; anything left on the
 * node itself is discarded the moment the first instance is placed.
 */
function seat(mesh: Mesh, y: number): Mesh {
  mesh.position.y = y;
  mesh.bakeCurrentTransformIntoVertices();
  return mesh;
}

/** Merge parts into one geometry. Vertex colours survive; materials do not. */
function weld(name: string, parts: Mesh[]): Mesh {
  const merged = Mesh.MergeMeshes(parts, true, true, undefined, false, false);
  if (!merged) throw new Error(`Failed to merge prototype ${name}`);
  merged.name = name;
  return merged;
}

function flatMaterial(scene: Scene, name: string, color: Color3): StandardMaterial {
  const mat = new StandardMaterial(name, scene);
  mat.diffuseColor = color;
  // A specular highlight on a low-poly bush reads as wet plastic.
  mat.specularColor = new Color3(0, 0, 0);
  mat.freeze();
  return mat;
}

export function createPrototypes(scene: Scene): PrototypeSet {
  const materials: StandardMaterial[] = [];
  const meshes = new Map<PropFamilyId, Mesh>();

  /**
   * Vertex colours are used ONLY by the welded trees, which genuinely need two
   * colours in one geometry. Everything else gets a plain flat material.
   *
   * Painting every family and sharing one white vertex-coloured material was
   * the first attempt and it rendered the rock batch as two screen-filling
   * triangles: `proto_rock` is a sphere at `segments: 2`, which is degenerate
   * enough that adding a colour buffer to it produced garbage geometry. A
   * single-colour prop has nothing to gain from vertex colours anyway, so the
   * cheap fix is also the correct one.
   */
  const foliage = new StandardMaterial('mat_foliage', scene);
  foliage.diffuseColor = new Color3(1, 1, 1);
  foliage.specularColor = new Color3(0, 0, 0);
  foliage.freeze();
  materials.push(foliage);

  const register = (family: PropFamilyId, mesh: Mesh, material: StandardMaterial): void => {
    mesh.material = material;
    mesh.setEnabled(false);
    mesh.isPickable = false;
    mesh.doNotSyncBoundingInfo = true;
    mesh.alwaysSelectAsActiveMesh = false;
    meshes.set(family, mesh);
  };

  const flat = (name: string, color: Color3): StandardMaterial => {
    const mat = flatMaterial(scene, name, color);
    materials.push(mat);
    return mat;
  };

  register(
    'oak',
    weld('proto_oak', [
      seat(
        paint(
          CreateCylinder(
            'oak_trunk',
            { height: 4.2, diameterTop: 0.42, diameterBottom: 0.66, tessellation: 6 },
            scene
          ),
          BARK
        ),
        2.1
      ),
      seat(paint(CreateSphere('oak_canopy', { diameter: 5.2, segments: 5 }, scene), LEAF), 4.6)
    ]),
    foliage
  );

  register(
    'pine',
    weld('proto_pine', [
      seat(
        paint(
          CreateCylinder(
            'pine_trunk',
            { height: 5.6, diameterTop: 0.26, diameterBottom: 0.52, tessellation: 6 },
            scene
          ),
          BARK
        ),
        2.8
      ),
      seat(
        paint(
          CreateCylinder(
            'pine_canopy',
            { height: 5.4, diameterTop: 0, diameterBottom: 3.1, tessellation: 7 },
            scene
          ),
          NEEDLE
        ),
        5.4
      )
    ]),
    foliage
  );

  // `segments: 2` here was not merely ugly, it was broken. Babylon's sphere
  // builder degenerates at that subdivision, and the batcher then scales rocks
  // up to 2.1x (scatter.json), which stretched one of the bad triangles into a
  // fog-coloured wedge that cut across the whole frame from a distance. It was
  // visible in three of the nine survey shots and read as a rendering fault
  // rather than as a rock. `segments: 3` is the lowest value that produces a
  // closed solid, and costs 8 triangles per rock prototype, not per instance.
  register(
    'rock',
    seat(CreateSphere('proto_rock', { diameter: 1.8, segments: 3 }, scene), 0.35),
    flat('mat_stone', STONE)
  );
  register(
    'bush',
    seat(CreateSphere('proto_bush', { diameter: 1.5, segments: 3 }, scene), 0.5),
    flat('mat_scrub', SCRUB)
  );

  // Ground cover. No collision: walking through long grass should not feel
  // like walking through a fence.
  register(
    'grass',
    seat(CreateBox('proto_grass', { width: 0.08, height: 0.7, depth: 0.5 }, scene), 0.32),
    flat('mat_blade', BLADE)
  );
  register(
    'reed',
    seat(CreateBox('proto_reed', { width: 0.06, height: 1.5, depth: 0.3 }, scene), 0.7),
    flat('mat_reed', NEEDLE)
  );
  register(
    'flower',
    seat(CreateBox('proto_flower', { width: 0.16, height: 0.34, depth: 0.16 }, scene), 0.17),
    flat('mat_bloom', BLOOM)
  );

  return { meshes, materials };
}

export function disposePrototypes(set: PrototypeSet): void {
  for (const mesh of set.meshes.values()) mesh.dispose();
  for (const mat of set.materials) mat.dispose();
}
