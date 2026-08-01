import { Color3, Color4, Mesh, Scene, StandardMaterial, VertexData } from '../core/babylon';
import type { BiomeKind, Terrain } from './gen/Terrain';

/**
 * Terrain geometry for one chunk, built by sampling the heightfield.
 *
 * Vertex colours carry the biome tint, so the whole world renders with one
 * shared material and no textures at all until M5. That keeps draw calls
 * proportional to chunk count rather than to biome variety.
 */

export const CHUNK_SIZE = 64;

/**
 * Quads per chunk edge at each LOD. Halving per level keeps the vertex count
 * dropping fast enough that the outer ring of a 5-chunk view is nearly free.
 * LOD 0 gives a 2m grid, which is fine detail for terrain the player walks on
 * given the heightfield's own detail octave is 42m.
 */
const LOD_RESOLUTION = [32, 16, 8] as const;

const BIOME_COLOR: Record<BiomeKind, Color3> = {
  meadow: new Color3(0.42, 0.55, 0.24),
  grove: new Color3(0.3, 0.44, 0.2),
  rock: new Color3(0.46, 0.45, 0.42),
  riverbank: new Color3(0.56, 0.52, 0.36),
  water: new Color3(0.29, 0.36, 0.3)
};

export function chunkMaterial(scene: Scene): StandardMaterial {
  const mat = new StandardMaterial('mat_terrain', scene);
  mat.diffuseColor = new Color3(1, 1, 1);
  mat.specularColor = new Color3(0, 0, 0);
  return mat;
}

/**
 * Build the mesh for chunk (cx, cz) at a LOD level.
 *
 * Skirts are deliberately omitted. Adjacent chunks at different LODs can leave
 * a hairline crack along the seam; the cheap fix is a downward skirt, but it
 * doubles the edge triangle count on every chunk. Instead the LOD ring is
 * placed far enough out that the crack is sub-pixel, and the fog at that
 * distance covers what remains. Revisit if it shows up on a real device.
 */
export function buildChunkMesh(
  scene: Scene,
  terrain: Terrain,
  cx: number,
  cz: number,
  lod: number,
  material: StandardMaterial
): Mesh {
  const res = LOD_RESOLUTION[Math.min(lod, LOD_RESOLUTION.length - 1)] ?? 8;
  const step = CHUNK_SIZE / res;
  const originX = cx * CHUNK_SIZE;
  const originZ = cz * CHUNK_SIZE;

  const vertexCount = (res + 1) * (res + 1);
  const positions = new Float32Array(vertexCount * 3);
  const normals = new Float32Array(vertexCount * 3);
  const colors = new Float32Array(vertexCount * 4);
  const indices = new Uint32Array(res * res * 6);

  let v = 0;
  for (let iz = 0; iz <= res; iz++) {
    for (let ix = 0; ix <= res; ix++) {
      const x = originX + ix * step;
      const z = originZ + iz * step;
      const y = terrain.heightAt(x, z);

      positions[v * 3] = x;
      positions[v * 3 + 1] = y;
      positions[v * 3 + 2] = z;

      // Sampled from the heightfield rather than computed from the mesh, so
      // lighting stays consistent across LOD changes instead of flattening as
      // the mesh coarsens.
      const n = terrain.normalAt(x, z);
      normals[v * 3] = n.x;
      normals[v * 3 + 1] = n.y;
      normals[v * 3 + 2] = n.z;

      const c = BIOME_COLOR[terrain.biomeAt(x, z)] ?? BIOME_COLOR.meadow;
      colors[v * 4] = c.r;
      colors[v * 4 + 1] = c.g;
      colors[v * 4 + 2] = c.b;
      colors[v * 4 + 3] = 1;

      v++;
    }
  }

  let i = 0;
  for (let iz = 0; iz < res; iz++) {
    for (let ix = 0; ix < res; ix++) {
      const a = iz * (res + 1) + ix;
      const b = a + 1;
      const c = a + (res + 1);
      const d = c + 1;
      // Winding matters and is easy to get backwards. Babylon is left-handed
      // by default, so the order that looks correct under the right-hand rule
      // produces a surface facing DOWN: the ground renders inside-out, is
      // culled from above, and the player appears to float over a grey void
      // with only a distant horizon band visible. Verified by toggling
      // backFaceCulling in a browser smoke run.
      indices[i++] = a;
      indices[i++] = b;
      indices[i++] = c;
      indices[i++] = b;
      indices[i++] = d;
      indices[i++] = c;
    }
  }

  const mesh = new Mesh(`chunk_${cx}_${cz}`, scene);
  const data = new VertexData();
  data.positions = positions as unknown as number[];
  data.normals = normals as unknown as number[];
  data.colors = colors as unknown as number[];
  data.indices = indices as unknown as number[];
  data.applyToMesh(mesh, false);

  mesh.material = material;
  mesh.receiveShadows = true;
  mesh.isPickable = false;
  // Terrain never moves. Freezing means Babylon stops recomputing a matrix
  // that will never change, for every chunk, every frame.
  //
  // `doNotSyncBoundingInfo` is deliberately NOT set here. It looks like a free
  // saving on static geometry, and it is how the first build shipped, but it
  // leaves the mesh with bounds that do not describe where its vertices are,
  // so frustum culling drops the chunks nearest the camera. The visible result
  // is a distant horizon with nothing under the player's feet.
  mesh.freezeWorldMatrix();

  return mesh;
}

/** Water is one shared plane rather than per-chunk geometry. */
export function buildWaterPlane(scene: Scene, size: number, level: number): Mesh {
  const mesh = new Mesh('water', scene);
  const data = new VertexData();
  const h = size / 2;
  data.positions = [-h, level, -h, h, level, -h, h, level, h, -h, level, h];
  data.normals = [0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0];
  // Same left-handed winding as the terrain grid above.
  data.indices = [0, 1, 2, 0, 2, 3];
  data.applyToMesh(mesh, false);

  const mat = new StandardMaterial('mat_water', scene);
  mat.diffuseColor = new Color3(0.18, 0.34, 0.42);
  mat.specularColor = new Color3(0.3, 0.35, 0.38);
  mat.alpha = 0.78;
  mesh.material = mat;
  mesh.isPickable = false;
  mesh.freezeWorldMatrix();
  return mesh;
}

export { LOD_RESOLUTION };
export type { Color4 };
