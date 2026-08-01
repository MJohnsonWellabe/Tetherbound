import { Matrix, Mesh, Quaternion, Vector3 } from '../core/babylon';
import { scatterInRect } from './gen/Scatter';
import type { BiomeKind, Terrain } from './gen/Terrain';
import type { PropFamilyId, PrototypeSet } from './Prototypes';

/**
 * Builds one (family x spatial cell) batch: its geometry, its colliders and
 * its harvest nodes.
 *
 * Separated from PropBatcher so that file can stay about residency and queries
 * rather than about matrix composition. See PropBatcher.ts for why props are
 * grouped by family cell rather than by terrain chunk.
 */

export interface PropCollider {
  x: number;
  z: number;
  radius: number;
}

/** A harvestable prop instance. Keyed so worldDeltas can record it. */
export interface PropNode {
  key: string;
  family: PropFamilyId;
  resource: string;
  x: number;
  y: number;
  z: number;
}

/** One family's entry in scatter.json. */
export interface FamilyConfig {
  id: string;
  minDistance: number;
  drawDistance: number;
  cellSize: number;
  castsShadow: boolean;
  shadowDistance: number;
  collisionRadius: number;
  harvest: string | null;
  biomes: string[];
  maxSlope: number;
  density: Record<string, number>;
  scaleRange: number[];
}

export interface PropCell {
  readonly family: FamilyConfig;
  mesh: Mesh | null;
  colliders: PropCollider[];
  nodes: PropNode[];
  /** Cell centre, for distance culls. */
  readonly cx: number;
  readonly cz: number;
  /** Whether this cell is currently registered as a shadow caster. */
  casting: boolean;
}

/** Padding on the batch bounding box, in meters. */
const BOUNDS_PAD = 8;
/** Extra headroom above the tallest sampled ground, for tall props. */
const BOUNDS_HEADROOM = 12;

export function buildPropCell(
  terrain: Terrain,
  prototypes: PrototypeSet,
  family: FamilyConfig,
  ix: number,
  iz: number
): PropCell {
  const size = family.cellSize;
  const minX = ix * size;
  const minZ = iz * size;
  const allowedBiomes = new Set(family.biomes as BiomeKind[]);

  const cell: PropCell = {
    family,
    mesh: null,
    colliders: [],
    nodes: [],
    cx: minX + size / 2,
    cz: minZ + size / 2,
    casting: false
  };

  const points = scatterInRect(
    {
      seed: terrain.seed,
      label: family.id,
      mask: (x, z) =>
        allowedBiomes.has(terrain.biomeAt(x, z)) && terrain.slopeAt(x, z) < family.maxSlope,
      density: (x, z) => {
        const biome = terrain.biomeAt(x, z);
        return family.density[biome] ?? family.density['default'] ?? 1;
      },
      minDistance: family.minDistance
    },
    minX,
    minZ,
    minX + size,
    minZ + size
  );
  if (points.length === 0) return cell;

  const proto = prototypes.meshes.get(family.id as PropFamilyId);
  if (!proto) return cell;

  // A clone shares the prototype's geometry and material, so a batch costs one
  // draw call and uploads no new vertex data.
  const mesh = proto.clone(`${family.id}_${ix}_${iz}`, null, true);
  if (!mesh) return cell;
  mesh.setEnabled(true);
  mesh.isPickable = false;
  mesh.receiveShadows = false;

  const matrices = new Float32Array(points.length * 16);
  const minScale = family.scaleRange[0] ?? 1;
  const maxScale = family.scaleRange[1] ?? 1;

  const scale = Vector3.Zero();
  const position = Vector3.Zero();
  const rotation = Quaternion.Identity();
  const matrix = Matrix.Identity();

  let minY = Number.POSITIVE_INFINITY;
  let maxY = Number.NEGATIVE_INFINITY;

  for (let i = 0; i < points.length; i++) {
    const p = points[i];
    if (!p) continue;
    const s = minScale + p.roll * (maxScale - minScale);
    const y = terrain.heightAt(p.x, p.z);

    // Prototype origins are seated at ground level with any vertical offset
    // baked into their vertices, so placement is the ground sample and nothing
    // else, and scaling grows the prop upward rather than sinking it.
    scale.set(s, s, s);
    position.set(p.x, y, p.z);
    Quaternion.RotationYawPitchRollToRef(p.rotation, 0, 0, rotation);
    Matrix.ComposeToRef(scale, rotation, position, matrix);
    matrix.copyToArray(matrices, i * 16);

    if (y < minY) minY = y;
    if (y > maxY) maxY = y;

    if (family.collisionRadius > 0) {
      cell.colliders.push({ x: p.x, z: p.z, radius: family.collisionRadius * s });
    }
    if (family.harvest) {
      cell.nodes.push({
        key: p.key,
        family: family.id as PropFamilyId,
        resource: family.harvest,
        x: p.x,
        y,
        z: p.z
      });
    }
  }

  // `true` marks the buffer static: it never changes after upload, so Babylon
  // keeps it GPU-side instead of re-uploading it every frame.
  mesh.thinInstanceSetBuffer('matrix', matrices, 16, true);

  // Bounds MUST be set explicitly. A clone inherits the prototype's bounding
  // box, which describes one small prop at the origin, so every batch would be
  // frustum-culled the moment the camera looked away from world zero.
  //
  // Built from the cell footprint and the sampled height range rather than by
  // calling thinInstanceRefreshBoundingInfo, which walks every instance matrix
  // on every batch.
  mesh.buildBoundingInfo(
    new Vector3(minX - BOUNDS_PAD, minY - BOUNDS_PAD, minZ - BOUNDS_PAD),
    new Vector3(
      minX + size + BOUNDS_PAD,
      maxY + BOUNDS_PAD + BOUNDS_HEADROOM,
      minZ + size + BOUNDS_PAD
    )
  );
  mesh.alwaysSelectAsActiveMesh = false;

  cell.mesh = mesh;
  return cell;
}
