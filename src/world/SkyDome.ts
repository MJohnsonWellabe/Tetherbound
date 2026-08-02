import {
  Color3,
  CreateSphere,
  DynamicTexture,
  Mesh,
  Scene,
  StandardMaterial
} from '../core/babylon';
import lighting from '../data/lighting.json';
import type { Palette } from './TimeOfDay';

/**
 * The sky: an inverted sphere with a painted vertical gradient, following the
 * camera at infinite distance.
 *
 * Before this the sky was `scene.clearColor`, one flat colour edge to edge,
 * which is the single strongest "programmer art" tell in a screenshot.
 *
 * The gradient is painted against ELEVATION, not against texture rows. That
 * distinction is the whole fix. A linear zenith-to-horizon ramp spends most of
 * its range on the top of the dome, and a third person camera at head height
 * pitched down never looks above ~25 degrees: every survey frame came back
 * with the zenith sample and the horizon sample byte-identical, because both
 * were sampling the same near-horizon slice of a ramp whose interesting part
 * was overhead. `sky.horizonFalloff` in lighting.json pulls the gradient down
 * into the band the camera can actually see.
 *
 * The ramp lives in a 1xN DynamicTexture, repainted only when the interpolated
 * palette moves past an epsilon: a canvas write a few times per in-game hour
 * instead of per frame. The dome's horizon colour equals the fog colour by
 * data contract (lighting.json, tested), so the fogged terrain and the dome
 * meet without a seam and the horizon line disappears.
 */

const SKY = lighting.sky;

export class SkyDome {
  private readonly mesh: Mesh;
  private readonly material: StandardMaterial;
  private readonly ramp: DynamicTexture;
  private readonly pixels: ImageData;
  private lastZenith = new Color3(-1, -1, -1);
  private lastHorizon = new Color3(-1, -1, -1);

  constructor(scene: Scene) {
    // Radius only has to beat the camera's near plane comfortably;
    // infiniteDistance pins it to the camera so it never parallaxes. Segments
    // matter now that the gradient is steep near the horizon: too few and the
    // linear UV interpolation across each band shows as visible stripes.
    this.mesh = CreateSphere(
      'sky',
      { diameter: SKY.diameter, segments: SKY.segments, sideOrientation: Mesh.BACKSIDE },
      scene
    );
    this.mesh.infiniteDistance = true;
    this.mesh.isPickable = false;
    // The fog would eat the dome (it sits at "infinity"), and the whole point
    // of the horizon-equals-fog contract is that fog and sky agree already.
    this.mesh.applyFog = false;
    // Render first, behind everything.
    this.mesh.renderingGroupId = 0;
    this.mesh.alphaIndex = -1;

    this.ramp = new DynamicTexture('sky_ramp', { width: 1, height: SKY.rampHeight }, scene, false);
    const ctx = this.ramp.getContext() as CanvasRenderingContext2D;
    this.pixels = ctx.createImageData(1, SKY.rampHeight);

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
    if (dz < SKY.repaintEpsilon && dh < SKY.repaintEpsilon) return;
    this.lastZenith.copyFrom(palette.zenith);
    this.lastHorizon.copyFrom(palette.horizon);

    const height = SKY.rampHeight;
    const data = this.pixels.data;
    for (let y = 0; y < height; y++) {
      // Babylon's sphere runs v from 0 at the apex to 1 at the base, and
      // `ramp.update(false)` uploads canvas row 0 as v 0, so row 0 is straight
      // up. cos gives sin(elevation): +1 overhead, 0 at the horizon line.
      const up = Math.cos((Math.PI * y) / (height - 1));
      const k = up > 0 ? Math.pow(up, SKY.horizonFalloff) : 0;
      const i = y * 4;
      data[i] = channel(palette.horizon.r, palette.zenith.r, k);
      data[i + 1] = channel(palette.horizon.g, palette.zenith.g, k);
      data[i + 2] = channel(palette.horizon.b, palette.zenith.b, k);
      data[i + 3] = 255;
    }
    const ctx = this.ramp.getContext() as CanvasRenderingContext2D;
    ctx.putImageData(this.pixels, 0, 0);
    // invertY false: canvas row 0 must stay v 0, which is the top of the dome.
    this.ramp.update(false);
  }

  dispose(): void {
    this.ramp.dispose();
    this.material.dispose();
    this.mesh.dispose();
  }
}

function channel(low: number, high: number, k: number): number {
  return Math.round(Math.min(1, Math.max(0, low + (high - low) * k)) * 255);
}

function maxDelta(a: Color3, b: Color3): number {
  return Math.max(Math.abs(a.r - b.r), Math.abs(a.g - b.g), Math.abs(a.b - b.b));
}
