import { Color3, Color4, DynamicTexture, Mesh, Scene, StandardMaterial, Texture, VertexData } from '../core/babylon';
import render from '../data/render.json';
import type { BiomeKind, Terrain } from './gen/Terrain';

/**
 * Terrain geometry for one chunk, built by sampling the heightfield.
 *
 * Vertex colours carry the biome tint, so the whole world renders with one
 * shared material and no textures at all until M5. That keeps draw calls
 * proportional to chunk count rather than to biome variety.
 */

export const CHUNK_SIZE = 128;

/**
 * Quads per chunk edge at each LOD. Halving per level keeps the vertex count
 * dropping fast enough that the outer ring of the view is nearly free. LOD 0
 * gives a 2m grid, which is fine detail for terrain the player walks on given
 * the heightfield's own detail octave is 42m.
 *
 * Doubled alongside CHUNK_SIZE going 64 -> 128, so the grid spacing at every
 * level is unchanged and only the number of draw calls moved.
 */
const LOD_RESOLUTION = [64, 32, 16] as const;

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
  // A near-grey tiling texture multiplied under the vertex biome colours.
  // It only adds surface frequency; the palette stays in the vertex data, so
  // a failed download silently degrades to today's flat-colour terrain.
  const detail = new Texture(
    render.terrain.detailTexture,
    scene,
    false,
    false,
    Texture.TRILINEAR_SAMPLINGMODE,
    null,
    () => {
      mat.diffuseTexture = null;
      detail.dispose();
    }
  );
  mat.diffuseTexture = detail;
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
  const uvs = new Float32Array(vertexCount * 2);
  const indices = new Uint32Array(res * res * 6);
  // World-planar UVs: u = x / tile, v = z / tile. Continuous across chunk
  // borders by construction, so the detail texture never seams.
  const tile = render.terrain.tileMeters;

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

      uvs[v * 2] = x / tile;
      uvs[v * 2 + 1] = z / tile;

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
  data.uvs = uvs as unknown as number[];
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

/**
 * Water is one shared plane rather than per-chunk geometry.
 *
 * SUBDIVIDED, and that is not cosmetic. Babylon's StandardMaterial computes fog
 * in the vertex shader and interpolates it across the triangle, so a quad with
 * four corners 4096m apart interpolates one fog value over the entire visible
 * world. The result was a pale sheet lying across the landscape with a hard
 * diagonal seam down the middle: the boundary between the quad's two triangles.
 * It only became obvious when the fog was thickened to match the new prop draw
 * distances, but the geometry was always wrong.
 *
 * The mesh is also NOT world-matrix frozen. It follows the player, and freezing
 * silently discarded every position update, which is why a plane meant to track
 * the camera had sat at the world origin since it was written.
 */
export function buildWaterPlane(scene: Scene, size: number, level: number, segments = 24): Mesh {
  const mesh = new Mesh('water', scene);
  const data = new VertexData();

  const h = size / 2;
  const step = size / segments;
  const positions: number[] = [];
  const normals: number[] = [];
  const indices: number[] = [];

  for (let iz = 0; iz <= segments; iz++) {
    for (let ix = 0; ix <= segments; ix++) {
      positions.push(-h + ix * step, level, -h + iz * step);
      normals.push(0, 1, 0);
    }
  }
  for (let iz = 0; iz < segments; iz++) {
    for (let ix = 0; ix < segments; ix++) {
      const a = iz * (segments + 1) + ix;
      const b = a + 1;
      const c = a + (segments + 1);
      const d = c + 1;
      // Same left-handed winding as the terrain grid above.
      indices.push(a, b, c, b, d, c);
    }
  }

  data.positions = positions;
  data.normals = normals;
  data.indices = indices;
  data.applyToMesh(mesh, false);

  const mat = new StandardMaterial('mat_water', scene);
  mat.diffuseColor = new Color3(0.18, 0.34, 0.42);
  mat.specularColor = new Color3(0.3, 0.35, 0.38);
  mat.alpha = 0.78;

  // A procedural sparkle layer, scrolled slowly. Generated rather than
  // downloaded: 64px of soft blobs is not worth an asset and a manifest row.
  // It rides in the emissive slot so it brightens the surface instead of
  // darkening it the way a multiplied diffuse texture would.
  const caustic = buildCausticTexture(scene);
  const w = render.water;
  caustic.uScale = size / w.causticTileM;
  caustic.vScale = size / w.causticTileM;
  mat.emissiveTexture = caustic;
  mat.emissiveColor = new Color3(w.causticStrength, w.causticStrength, w.causticStrength);

  // UVs for the scroll. The grid loop above produced positions/normals only.
  const uvs = new Float32Array((segments + 1) * (segments + 1) * 2);
  let uv = 0;
  for (let iz = 0; iz <= segments; iz++) {
    for (let ix = 0; ix <= segments; ix++) {
      uvs[uv++] = ix / segments;
      uvs[uv++] = iz / segments;
    }
  }
  mesh.setVerticesData('uv', uvs as unknown as number[], false);

  // Scroll and bob per rendered frame. Wall-clock driven on purpose: this is
  // pure presentation, and pausing the SIMULATION (hit pause) should not
  // freeze the water any more than it freezes the camera.
  const basePositions = mesh.getVerticesData('position')?.slice() ?? null;
  const observer = scene.onBeforeRenderObservable.add(() => {
    const t = performance.now() / 1000;
    caustic.uOffset = t * w.scrollU;
    caustic.vOffset = t * w.scrollV;
    if (!basePositions) return;
    const positions = mesh.getVerticesData('position');
    if (!positions) return;
    const k = (Math.PI * 2) / w.bobWavelengthM;
    for (let i = 0; i < positions.length; i += 3) {
      const px = basePositions[i] ?? 0;
      const pz = basePositions[i + 2] ?? 0;
      positions[i + 1] = level + Math.sin((px + pz) * k + t * w.bobSpeed * Math.PI * 2) * w.bobAmplitude;
    }
    mesh.updateVerticesData('position', positions, false, false);
  });
  mesh.onDisposeObservable.add(() => {
    scene.onBeforeRenderObservable.remove(observer);
    caustic.dispose();
  });

  mesh.material = mat;
  mesh.isPickable = false;
  return mesh;
}

/** Soft light blobs on transparent-black, tiled as the water sparkle. */
function buildCausticTexture(scene: Scene): DynamicTexture {
  const size = 64;
  const texture = new DynamicTexture('water_caustic', { width: size, height: size }, scene, true);
  const ctx = texture.getContext() as CanvasRenderingContext2D;
  ctx.fillStyle = 'rgb(0,0,0)';
  ctx.fillRect(0, 0, size, size);
  // Deterministic blob field, so every boot sparkles identically.
  let seed = 7;
  const rand = (): number => {
    seed = (seed * 16807) % 2147483647;
    return seed / 2147483647;
  };
  for (let i = 0; i < 26; i++) {
    const x = rand() * size;
    const y = rand() * size;
    const r = 2 + rand() * 5;
    const g = ctx.createRadialGradient(x, y, 0, x, y, r);
    const a = 0.10 + rand() * 0.22;
    g.addColorStop(0, `rgba(255,255,255,${a.toFixed(2)})`);
    g.addColorStop(1, 'rgba(255,255,255,0)');
    ctx.fillStyle = g;
    ctx.fillRect(0, 0, size, size);
  }
  texture.update(false);
  texture.wrapU = 1;
  texture.wrapV = 1;
  return texture;
}

export { LOD_RESOLUTION };
export type { Color4 };
