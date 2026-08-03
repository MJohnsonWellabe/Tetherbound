import {
  Color3,
  CreatePlane,
  DynamicTexture,
  Engine,
  Mesh,
  Scene,
  StandardMaterial,
  Vector3,
  type DirectionalLight,
  type FreeCamera
} from '../core/babylon';
import lighting from '../data/lighting.json';
import type { Palette } from './TimeOfDay';

/**
 * A visible sun: a billboarded additive disc parked up the reversed light
 * direction.
 *
 * This exists as much for the grade as for itself. Bloom runs on the raw
 * material output, and every material in the world is StandardMaterial whose
 * lighting term clamps to 1.0 before albedo, so before this there was
 * essentially nothing in any frame bright enough to cross the bloom threshold
 * and the whole effect was invisible. The disc's core is painted at a flat
 * 255 and is unlit, so it is the one thing on screen that reliably blooms.
 * That is the intent, not a side effect.
 *
 * Parked at a fixed distance up the light vector rather than at a real
 * position, so it needs no relationship to world scale and cannot drift out of
 * agreement with the shadow direction.
 */

const SUN = lighting.sunDisc;

export class SunDisc {
  private readonly mesh: Mesh;
  private readonly material: StandardMaterial;
  private readonly texture: DynamicTexture;
  private readonly offset = Vector3.Zero();

  constructor(scene: Scene) {
    this.mesh = CreatePlane('sun_disc', { size: SUN.size }, scene);
    this.mesh.billboardMode = Mesh.BILLBOARDMODE_ALL;
    this.mesh.isPickable = false;
    this.mesh.applyFog = false;
    this.mesh.renderingGroupId = 0;
    // After the dome (-1) and the clouds (0).
    this.mesh.alphaIndex = 1;
    this.mesh.infiniteDistance = true;

    this.texture = paintDisc(scene);

    this.material = new StandardMaterial('mat_sun_disc', scene);
    this.material.emissiveTexture = this.texture;
    this.material.opacityTexture = this.texture;
    this.material.disableLighting = true;
    this.material.diffuseColor = new Color3(0, 0, 0);
    this.material.specularColor = new Color3(0, 0, 0);
    this.material.backFaceCulling = false;
    // Additive, so the disc adds onto the sky instead of compositing over it.
    // A sun that darkens the sky it sits in reads as a sticker.
    this.material.alphaMode = Engine.ALPHA_ADD;
    this.material.disableDepthWrite = true;
    this.mesh.material = this.material;
  }

  /**
   * Re-park the disc. Called per frame: the sun moves through the cycle, and
   * `infiniteDistance` only cancels the camera's translation, not the disc's
   * own position on the dome.
   */
  follow(camera: FreeCamera, sun: DirectionalLight): void {
    // The light direction points the way photons travel, so the sun itself is
    // the other way.
    const elevation = -sun.direction.y;
    // Below the horizon it would otherwise shine up through the terrain.
    if (elevation <= 0) {
      this.mesh.setEnabled(false);
      return;
    }
    this.mesh.setEnabled(true);
    this.offset.copyFrom(sun.direction).scaleInPlace(-SUN.distance);
    this.mesh.position.copyFrom(camera.position).addInPlace(this.offset);
  }

  update(palette: Palette): void {
    // Tinted by the sun's own palette colour, lifted well past 1. Values above
    // 1 survive into the half-float pipeline and are exactly what the bloom
    // threshold is set to catch.
    this.material.emissiveColor.set(
      palette.sun.r * SUN.gain,
      palette.sun.g * SUN.gain,
      palette.sun.b * SUN.gain
    );
  }

  dispose(): void {
    this.texture.dispose();
    this.material.dispose();
    this.mesh.dispose();
  }
}

/**
 * A radial falloff: white core, alpha fading to nothing at the rim.
 *
 * Painted once. The shape never changes; only the tint does, and that is a
 * uniform write in update().
 */
function paintDisc(scene: Scene): DynamicTexture {
  const size = SUN.textureSize;
  const tex = new DynamicTexture('sun_disc_tex', { width: size, height: size }, scene, false);
  const ctx = tex.getContext() as CanvasRenderingContext2D;
  const half = size / 2;

  const gradient = ctx.createRadialGradient(half, half, 0, half, half, half);
  // A hard-ish core with a wide soft halo. A pure linear falloff reads as a
  // smudge; the flat centre is what makes it a sun.
  gradient.addColorStop(0, 'rgba(255,255,255,1)');
  gradient.addColorStop(SUN.coreStop, 'rgba(255,255,255,1)');
  gradient.addColorStop(SUN.haloStop, 'rgba(255,255,255,0.34)');
  gradient.addColorStop(1, 'rgba(255,255,255,0)');
  ctx.fillStyle = gradient;
  ctx.fillRect(0, 0, size, size);

  tex.hasAlpha = true;
  tex.update(false);
  return tex;
}
