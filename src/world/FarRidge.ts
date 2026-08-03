import {
  Color3,
  Mesh,
  Scene,
  StandardMaterial,
  VertexData,
  type FreeCamera
} from '../core/babylon';
import lighting from '../data/lighting.json';
import { hashSeed, mulberry32 } from './gen/Rng';
import type { Palette } from './TimeOfDay';

/**
 * Distant mountains: concentric bands of ridgeline silhouette, locked to the
 * camera.
 *
 * Every reference frame is anchored by a hazy range on the horizon, and this
 * game had nothing out there at all. Terrain draws to 384m and the world just
 * stopped.
 *
 * TWO THINGS HERE LOOK WRONG AND ARE DELIBERATE.
 *
 * **It does not sample the real heightfield.** It cannot. The continent octave
 * is +/-24m over 900m, so a genuine hill at a genuine 2km subtends about one
 * degree: a bump, not a mountain. These bands run their own ridged noise at a
 * nominal amplitude an order of magnitude past anything walkable. Nothing here
 * has to agree with the terrain, because it is camera-locked and unreachable,
 * and "fixing" it to sample `terrain.heightAt` would delete the whole effect.
 *
 * **It is camera-locked, so it has no parallax.** `render.json` caps
 * `camera.maxZ` at 900, and EXP2 fog at the day density erases anything past
 * ~400m to exactly the horizon colour, so a world-anchored range would be
 * either outside the far plane or invisible. Raising maxZ instead would wreck
 * depth precision against a 0.35 near plane. Over a 200m walk the parallax
 * being given up is about six degrees against a nominal 2km range. Every
 * stylised game ships this.
 *
 * Aerial perspective is baked into the vertex colours rather than left to the
 * fog, since the bands opt out of fog for the same reason the sky dome does.
 * Being opaque and sitting inside the cloud shell and the dome, depth sorts the
 * three correctly with no ordering hack, and real terrain always wins.
 */

const RIDGE = lighting.ridge;

export class FarRidge {
  private readonly meshes: Mesh[] = [];
  private readonly material: StandardMaterial;

  constructor(scene: Scene, seed: string) {
    this.material = new StandardMaterial('mat_far_ridge', scene);
    this.material.disableLighting = true;
    this.material.specularColor = new Color3(0, 0, 0);
    // Unlit, so the whole band is emissiveColor * vertexColour. That makes the
    // per-palette tint a single Color3 write and the haze gradient free.
    this.material.emissiveColor = new Color3(1, 1, 1);
    this.material.diffuseColor = new Color3(0, 0, 0);

    RIDGE.bands.forEach((band, index) => {
      const mesh = buildBand(scene, seed, index, band);
      mesh.material = this.material;
      this.meshes.push(mesh);
    });
  }

  /** Bands are `infiniteDistance`, so this only has to keep them centred. */
  follow(camera: FreeCamera): void {
    for (const mesh of this.meshes) mesh.position.y = camera.position.y + RIDGE.baseOffsetY;
  }

  update(palette: Palette): void {
    // Sat between the horizon and the zenith. Pure horizon colour makes the
    // range vanish into the sky; pure zenith makes it a hard cutout. The lerp
    // is what reads as distance.
    this.material.emissiveColor.set(
      palette.horizon.r + (palette.zenith.r - palette.horizon.r) * RIDGE.zenithMix,
      palette.horizon.g + (palette.zenith.g - palette.horizon.g) * RIDGE.zenithMix,
      palette.horizon.b + (palette.zenith.b - palette.horizon.b) * RIDGE.zenithMix
    );
  }

  dispose(): void {
    for (const mesh of this.meshes) mesh.dispose();
    this.material.dispose();
  }
}

interface BandConfig {
  readonly radius: number;
  readonly height: number;
  readonly columns: number;
  readonly roughness: number;
  /** Vertex-colour value at the ridge top. Lower is hazier, so further. */
  readonly peakHaze: number;
  readonly baseHaze: number;
}

/**
 * One cylindrical curtain of ridgeline.
 *
 * Two rows of vertices: a skirt well below the horizon so no gap can ever show
 * under the terrain edge, and a top row whose height is the noise.
 */
function buildBand(scene: Scene, seed: string, index: number, band: BandConfig): Mesh {
  const mesh = new Mesh(`far_ridge_${index}`, scene);
  mesh.infiniteDistance = true;
  mesh.isPickable = false;
  mesh.applyFog = false;
  mesh.renderingGroupId = 0;
  mesh.alphaIndex = -1 + (index + 1) * 0.001;

  const columns = band.columns;
  const positions: number[] = [];
  const colors: number[] = [];
  const indices: number[] = [];

  const rng = mulberry32(hashSeed(`${seed}:far-ridge`, index));
  // A short table of octave phases, sampled around the circle. Cheaper than a
  // simplex import and it must close on itself exactly at column 0 == columns,
  // or the range has a visible vertical seam at due east.
  const phases = [rng() * Math.PI * 2, rng() * Math.PI * 2, rng() * Math.PI * 2];

  for (let c = 0; c <= columns; c++) {
    const t = (c / columns) * Math.PI * 2;
    const h = ridgeHeight(t, phases, band.roughness) * band.height;

    const x = Math.cos(t) * band.radius;
    const z = Math.sin(t) * band.radius;

    positions.push(x, -RIDGE.skirt, z);
    colors.push(band.baseHaze, band.baseHaze, band.baseHaze, 1);

    positions.push(x, h, z);
    colors.push(band.peakHaze, band.peakHaze, band.peakHaze, 1);

    if (c < columns) {
      const b = c * 2;
      // Wound to face inward: the camera is inside the cylinder.
      indices.push(b, b + 1, b + 2, b + 1, b + 3, b + 2);
    }
  }

  const data = new VertexData();
  data.positions = positions;
  data.indices = indices;
  data.colors = colors;
  data.normals = [];
  VertexData.ComputeNormals(positions, indices, data.normals);
  data.applyToMesh(mesh, false);
  mesh.useVertexColors = true;

  return mesh;
}

/**
 * Ridged multifractal, in one dimension, closed over the circle.
 *
 * `1 - |sin|` is what makes a ridge rather than a rolling hill: the absolute
 * value creases the wave at every zero crossing, and squaring sharpens the
 * crease into a peak while flattening the valleys.
 */
function ridgeHeight(t: number, phases: number[], roughness: number): number {
  let sum = 0;
  let amplitude = 1;
  let norm = 0;
  for (let octave = 0; octave < phases.length; octave++) {
    const frequency = Math.pow(2, octave) * RIDGE.baseFrequency;
    const ridged = 1 - Math.abs(Math.sin(t * frequency + (phases[octave] ?? 0)));
    sum += ridged * ridged * amplitude;
    norm += amplitude;
    amplitude *= roughness;
  }
  return sum / norm;
}
