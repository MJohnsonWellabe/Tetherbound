import {
  Color3,
  CreateSphere,
  DynamicTexture,
  Mesh,
  Scene,
  StandardMaterial
} from '../core/babylon';
import type { Palette } from './TimeOfDay';

/**
 * The sky: an inverted sphere with a painted vertical gradient, following the
 * camera at infinite distance.
 *
 * Before this the sky was `scene.clearColor`, one flat colour edge to edge,
 * which is the single strongest "programmer art" tell in a screenshot. A
 * zenith-to-horizon gradient is what makes daylight read as depth.
 *
 * The gradient lives in a 1x128 DynamicTexture ramp, repainted only when the
 * interpolated palette moves past an epsilon: a canvas write a few times per
 * in-game hour instead of per frame. The dome's horizon colour equals the fog
 * colour by data contract (lighting.json, tested), so the fogged terrain and
 * the dome meet without a seam and the horizon line disappears.
 */

const RAMP_HEIGHT = 128;
/** Colour delta (max channel) that justifies repainting the ramp. */
const REPAINT_EPSILON = 0.004;

export class SkyDome {
  private readonly mesh: Mesh;
  private readonly material: StandardMaterial;
  private readonly ramp: DynamicTexture;
  private lastZenith = new Color3(-1, -1, -1);
  private lastHorizon = new Color3(-1, -1, -1);

  constructor(scene: Scene) {
    // Radius only has to beat the camera's near plane comfortably;
    // infiniteDistance pins it to the camera so it never parallaxes.
    this.mesh = CreateSphere('sky', { diameter: 100, segments: 8, sideOrientation: Mesh.BACKSIDE }, scene);
    this.mesh.infiniteDistance = true;
    this.mesh.isPickable = false;
    // The fog would eat the dome (it sits at "infinity"), and the whole point
    // of the horizon-equals-fog contract is that fog and sky agree already.
    this.mesh.applyFog = false;
    // Render first, behind everything.
    this.mesh.renderingGroupId = 0;
    this.mesh.alphaIndex = -1;

    this.ramp = new DynamicTexture('sky_ramp', { width: 1, height: RAMP_HEIGHT }, scene, false);
    this.material = new StandardMaterial('mat_sky', scene);
    this.material.emissiveTexture = this.ramp;
    this.material.disableLighting = true;
    this.material.diffuseColor = new Color3(0, 0, 0);
    this.material.specularColor = new Color3(0, 0, 0);
    this.material.backFaceCulling = false;
    this.mesh.material = this.material;
  }

  /** Follow the lighting palette. Cheap unless the sky actually changed. */
  update(palette: Palette): void {
    const dz = maxDelta(palette.zenith, this.lastZenith);
    const dh = maxDelta(palette.horizon, this.lastHorizon);
    if (dz < REPAINT_EPSILON && dh < REPAINT_EPSILON) return;
    this.lastZenith.copyFrom(palette.zenith);
    this.lastHorizon.copyFrom(palette.horizon);

    const ctx = this.ramp.getContext() as CanvasRenderingContext2D;
    const gradient = ctx.createLinearGradient(0, 0, 0, RAMP_HEIGHT);
    // Sphere UV v runs 0 at the south pole to 1 at the north pole; the canvas
    // y axis runs top-down. Keep the horizon in the middle band so the colour
    // below the horizon (under terrain, visible only through water gaps)
    // stays the horizon tone rather than mirroring the zenith.
    gradient.addColorStop(0, css(palette.zenith));
    gradient.addColorStop(0.45, css(palette.horizon));
    gradient.addColorStop(1, css(palette.horizon));
    ctx.fillStyle = gradient;
    ctx.fillRect(0, 0, 1, RAMP_HEIGHT);
    this.ramp.update(false);
  }

  dispose(): void {
    this.ramp.dispose();
    this.material.dispose();
    this.mesh.dispose();
  }
}

function css(c: Color3): string {
  const r = Math.round(c.r * 255);
  const g = Math.round(c.g * 255);
  const b = Math.round(c.b * 255);
  return `rgb(${r},${g},${b})`;
}

function maxDelta(a: Color3, b: Color3): number {
  return Math.max(Math.abs(a.r - b.r), Math.abs(a.g - b.g), Math.abs(a.b - b.b));
}
