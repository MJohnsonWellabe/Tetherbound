import {
  Color4,
  ColorCurves,
  DefaultRenderingPipeline,
  DirectionalLight,
  Engine,
  FreeCamera,
  HemisphericLight,
  Scene,
  ShadowGenerator,
  Vector3
} from './babylon';
import render from '../data/render.json';

/**
 * Renderer bootstrap: engine, scene, lighting rig, resize handling, and
 * WebGL context-loss recovery.
 *
 * Everything here is display concern only. No gameplay state lives in this
 * file, so the whole renderer can be torn down and rebuilt (which is exactly
 * what context loss makes us do) without touching the simulation.
 */

export interface DeviceProfile {
  readonly isTouch: boolean;
  /** Hard cap on devicePixelRatio. Rendering a phone at 3x is the single
   *  easiest way to miss the frame budget for no visible gain. */
  readonly maxPixelRatio: number;
  readonly shadowMapSize: number;
}

export function detectDevice(): DeviceProfile {
  const isTouch =
    typeof window !== 'undefined' &&
    ('ontouchstart' in window || navigator.maxTouchPoints > 0) &&
    // A touchscreen laptop is not a phone. Coarse pointer is the better signal.
    window.matchMedia('(pointer: coarse)').matches;

  return {
    isTouch,
    maxPixelRatio: isTouch ? 1.5 : 2,
    shadowMapSize: isTouch ? render.shadow.mapSize.touch : render.shadow.mapSize.desktop
  };
}

export interface RendererHandles {
  engine: Engine;
  scene: Scene;
  camera: FreeCamera;
  sun: DirectionalLight;
  sky: HemisphericLight;
  shadows: ShadowGenerator;
  device: DeviceProfile;
}

export class Renderer {
  readonly handles: RendererHandles;
  private readonly canvas: HTMLCanvasElement;
  private readonly teardown: Array<() => void> = [];
  /** Where the shadow box currently sits. NaN forces the first follow. */
  private shadowFocusX = Number.NaN;
  private shadowFocusZ = Number.NaN;
  private shadowFocusY = 0;
  /** Fired when the GPU context is lost and then restored, so the game can
   *  re-upload anything it owns. */
  onContextRestored: (() => void) | null = null;

  constructor(canvas: HTMLCanvasElement) {
    this.canvas = canvas;
    const device = detectDevice();

    const engine = new Engine(canvas, true, {
      // The depth buffer matters more than the alpha channel we never read.
      alpha: false,
      stencil: false,
      antialias: !device.isTouch,
      powerPreference: 'high-performance',
      // Without this a lost context is fatal rather than recoverable.
      doNotHandleContextLost: false,
      preserveDrawingBuffer: false
    });
    engine.setHardwareScalingLevel(1 / Math.min(window.devicePixelRatio || 1, device.maxPixelRatio));

    const scene = new Scene(engine);
    // Clear colour, light colours and light intensities all belong to the
    // day/night palette in lighting.json. TimeOfDay writes every one of them
    // on construction, before the first frame, so there are no colour literals
    // here to drift out of step with the palette.
    scene.clearColor = new Color4(0, 0, 0, 1);
    // Prop collision uses our own sphere/AABB tests against a per-chunk list,
    // so Babylon never needs to consider a mesh for picking.
    scene.skipPointerMovePicking = true;

    const camera = new FreeCamera('camera', new Vector3(0, 8, -12), scene);
    camera.minZ = render.camera.minZ;
    camera.maxZ = render.camera.maxZ;
    camera.fov = render.camera.fov;
    // The camera rig drives this manually from the player transform; Babylon's
    // built-in input would fight it.
    camera.inputs.clear();

    // docs/03_TECHNICAL_ARCHITECTURE.md: a single directional light casting, plus cheap ambient.
    // Direction, colour and intensity are all TimeOfDay's, from lighting.json.
    const sun = new DirectionalLight('sun', new Vector3(-0.45, -0.82, 0.36), scene);
    const sky = new HemisphericLight('sky', new Vector3(0, 1, 0), scene);

    // Pin the shadow frustum to a box around the player. Setting
    // shadowFrustumSize is what takes Babylon off autoUpdateExtends, which
    // fits the box to the caster list and therefore to the whole view
    // distance: a 1024 map spread over ~650m, 0.63m per texel, no shadow small
    // enough to sit under a lamp post. See render.json for the measurements.
    sun.shadowFrustumSize = render.shadow.extent;
    sun.shadowMinZ = render.shadow.minZ;
    sun.shadowMaxZ = render.shadow.maxZ;

    const shadows = new ShadowGenerator(device.shadowMapSize, sun);
    shadows.usePercentageCloserFiltering = !device.isTouch;
    shadows.filteringQuality = ShadowGenerator.QUALITY_LOW;
    // bias is a fraction of (shadowMaxZ - shadowMinZ), so it only means metres
    // once that range is pinned too. Both live in render.json for that reason.
    shadows.bias = render.shadow.bias;
    shadows.normalBias = render.shadow.normalBias;
    shadows.setDarkness(render.shadow.darkness);
    // Which meshes cast is decided by PropBatcher, by distance. Nothing is in
    // the list until it puts something there.
    shadows.getShadowMap()?.renderList?.splice(0);

    this.grade(scene, camera);

    // LAST. Two engine behaviours make the ordering in this constructor
    // load-bearing rather than stylistic:
    //
    // 1. `blockMaterialDirtyMechanism` makes _markAllSubMeshesAsDirty a no-op.
    //    Attaching the pipeline sets imageProcessingConfiguration.
    //    applyByPostProcess, which every material listens for and forwards into
    //    exactly that call. Blocked, materials keep compiling without
    //    toLinearSpace while the post-process still applies toGammaSpace, and
    //    the whole frame comes out washed grey. It reads as a tuning problem
    //    and is not one.
    // 2. Material.freeze() sets checkReadyOnlyOnce, and five call sites freeze.
    //
    // Every material in the game is created after `new Renderer()` in main.ts,
    // so with the pipeline already attached they all compile with the right
    // defines the first time and nothing ever needs marking dirty.
    scene.blockMaterialDirtyMechanism = true;

    this.handles = { engine, scene, camera, sun, sky, shadows, device };

    this.bindResize();

    this.bindContextLoss();
  }

  /**
   * The colour grade: tone mapping, exposure, contrast, bloom, FXAA, vignette.
   *
   * Ordering inside Babylon's applyImageProcessing is exposure -> vignette ->
   * tonemap -> toGammaSpace -> contrast -> curves, and the tonemap runs in
   * LINEAR space. Worth knowing before tuning, because it means tone mapping
   * barely touches mid-tones here (a gamma 0.5 mid-tone is linear 0.21) and
   * mostly serves to stop bloom-lifted highlights clipping flat. The visible
   * wins in this rig are, in order: bloom, contrast, curves, FXAA.
   *
   * Bloom runs BEFORE exposure, on the raw 0..1 material output, so its
   * threshold has to sit below 1.0 to catch anything at all.
   */
  private grade(scene: Scene, camera: FreeCamera): void {
    const g = render.post;

    // `hdr: true` is not cosmetic. It switches the intermediate targets to
    // half-float; with false you get an 8-bit LINEAR intermediate, and linear
    // 8-bit banding across shadowed grass is glaring.
    const pipeline = new DefaultRenderingPipeline('grade', true, scene, [camera]);

    pipeline.bloomEnabled = g.bloom.enabled;
    pipeline.bloomThreshold = g.bloom.threshold;
    pipeline.bloomWeight = g.bloom.weight;
    pipeline.bloomKernel = g.bloom.kernel;
    pipeline.bloomScale = g.bloom.scale;
    pipeline.fxaaEnabled = g.fxaa;

    // Pinned off rather than left at defaults, so a future Babylon default
    // cannot switch an expensive effect on without anyone choosing it.
    pipeline.depthOfFieldEnabled = false;
    pipeline.grainEnabled = false;
    pipeline.chromaticAberrationEnabled = false;
    pipeline.sharpenEnabled = false;

    const ip = scene.imageProcessingConfiguration;
    ip.toneMappingEnabled = g.toneMapping.enabled;
    ip.toneMappingType = g.toneMapping.type;
    ip.exposure = g.exposure;
    ip.contrast = g.contrast;
    ip.vignetteEnabled = g.vignette.enabled;
    ip.vignetteWeight = g.vignette.weight;
    ip.vignetteStretch = g.vignette.stretch;
    ip.vignetteCameraFov = g.vignette.fov;

    // Saturation lives here rather than in the palettes. The reference frames
    // are considerably more saturated than anything a physically-plausible
    // light rig produces, and lifting every palette to chase that would push
    // the shadowed side to grey. A global curve moves both ends together.
    const curves = new ColorCurves();
    curves.globalSaturation = g.curves.globalSaturation;
    curves.highlightsSaturation = g.curves.highlightsSaturation;
    curves.shadowsSaturation = g.curves.shadowsSaturation;
    curves.globalHue = g.curves.globalHue;
    ip.colorCurves = curves;
    ip.colorCurvesEnabled = true;

    this.teardown.push(() => pipeline.dispose());
  }

  private bindResize(): void {
    const { engine, device } = this.handles;
    let raf = 0;
    const onResize = (): void => {
      // iOS fires resize mid-rotation with intermediate sizes. Coalescing to
      // one rAF avoids resizing the framebuffer two or three times per turn.
      cancelAnimationFrame(raf);
      raf = requestAnimationFrame(() => {
        engine.setHardwareScalingLevel(
          1 / Math.min(window.devicePixelRatio || 1, device.maxPixelRatio)
        );
        engine.resize();
      });
    };
    window.addEventListener('resize', onResize);
    window.addEventListener('orientationchange', onResize);
    this.teardown.push(() => {
      cancelAnimationFrame(raf);
      window.removeEventListener('resize', onResize);
      window.removeEventListener('orientationchange', onResize);
    });
  }

  /**
   * A phone that backgrounds the tab, or a driver that resets, drops the WebGL
   * context. Babylon can restore its own resources, but anything we uploaded
   * ourselves (thin-instance buffers, dynamic textures) has to be rebuilt, and
   * without a restore hook the result is a frozen or single-colour screen that
   * looks like a hang.
   */
  private bindContextLoss(): void {
    const onLost = (e: Event): void => {
      e.preventDefault(); // required, or the context is never restored
      console.warn('[renderer] WebGL context lost');
    };
    const onRestored = (): void => {
      console.warn('[renderer] WebGL context restored');
      this.onContextRestored?.();
    };
    this.canvas.addEventListener('webglcontextlost', onLost, false);
    this.canvas.addEventListener('webglcontextrestored', onRestored, false);
    this.teardown.push(() => {
      this.canvas.removeEventListener('webglcontextlost', onLost);
      this.canvas.removeEventListener('webglcontextrestored', onRestored);
    });
  }

  /**
   * Recentre the shadow box on the player.
   *
   * The box is small so shadow texels are small, which means it has to travel
   * with the player or they walk out of their own shadow. Recentring is
   * deliberately hysteretic: moving it every frame makes shadow texels crawl
   * visibly across static geometry, which reads worse than a box that is a few
   * meters off centre.
   */
  focusShadows(x: number, y: number, z: number): void {
    const dx = x - this.shadowFocusX;
    const dz = z - this.shadowFocusZ;
    const moved = !(dx * dx + dz * dz < render.shadow.refollowDistance ** 2);
    if (moved) {
      this.shadowFocusX = x;
      this.shadowFocusZ = z;
      this.shadowFocusY = y;
    }

    // A directional light's position is not where the light is, it is where its
    // shadow frustum is anchored. Lifting it along the reversed light direction
    // keeps the whole scene in front of the near plane, and puts the centre of
    // the pinned box exactly on the focus point.
    //
    // This runs on every call, not only when the player moved. The sun swings
    // through the day, and the anchor is 160m up that direction, so an anchor
    // computed for this morning's sun is tens of metres off centre by noon.
    // With a box only 80m across that walks the player out of their own
    // shadow, which reads as shadows switching off rather than as a bug.
    const dir = this.handles.sun.direction;
    const lift = render.shadow.heightAbovePlayer;
    this.handles.sun.position.set(
      this.shadowFocusX - dir.x * lift,
      this.shadowFocusY - dir.y * lift,
      this.shadowFocusZ - dir.z * lift
    );
  }

  render(): void {
    this.handles.scene.render();
  }

  /** Dispose what we created. CLAUDE.md rule: nothing accumulates. */
  dispose(): void {
    for (const fn of this.teardown.splice(0)) fn();
    this.handles.shadows.dispose();
    this.handles.scene.dispose();
    this.handles.engine.dispose();
  }
}
