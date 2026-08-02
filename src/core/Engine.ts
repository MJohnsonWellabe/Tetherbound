import {
  Color3,
  Color4,
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
    shadowMapSize: isTouch ? 512 : 1024
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
    scene.clearColor = new Color4(0.42, 0.55, 0.68, 1);
    // Prop collision uses our own sphere/AABB tests against a per-chunk list,
    // so Babylon never needs to consider a mesh for picking.
    scene.skipPointerMovePicking = true;
    scene.blockMaterialDirtyMechanism = true;

    const camera = new FreeCamera('camera', new Vector3(0, 8, -12), scene);
    camera.minZ = render.camera.minZ;
    camera.maxZ = render.camera.maxZ;
    camera.fov = render.camera.fov;
    // The camera rig drives this manually from the player transform; Babylon's
    // built-in input would fight it.
    camera.inputs.clear();

    // ARCHITECTURE.md: a single directional light casting, plus cheap ambient.
    const sun = new DirectionalLight('sun', new Vector3(-0.45, -0.82, 0.36), scene);
    sun.intensity = 1.7;
    sun.diffuse = new Color3(1, 0.96, 0.86);

    const sky = new HemisphericLight('sky', new Vector3(0, 1, 0), scene);
    sky.intensity = 0.55;
    sky.diffuse = new Color3(0.72, 0.8, 0.92);
    sky.groundColor = new Color3(0.28, 0.3, 0.2);

    // The shadow frustum is pinned to a box around the player rather than
    // fitted to the caster list. autoUpdateExtends walks every caster every
    // frame and the bounds it finds span the whole view distance, so a 1024
    // map was spread over 384m at roughly 0.4m per texel. The same map over a
    // 70m box is about 0.07m per texel.
    sun.shadowMinZ = render.shadow.minZ;
    sun.shadowMaxZ = render.shadow.maxZ;

    const shadows = new ShadowGenerator(device.shadowMapSize, sun);
    shadows.usePercentageCloserFiltering = !device.isTouch;
    shadows.filteringQuality = ShadowGenerator.QUALITY_LOW;
    shadows.bias = 0.008;
    shadows.normalBias = 0.02;
    // Which meshes cast is decided by PropBatcher, by distance. Nothing is in
    // the list until it puts something there.
    shadows.getShadowMap()?.renderList?.splice(0);

    this.handles = { engine, scene, camera, sun, sky, shadows, device };

    this.bindResize();
    this.bindContextLoss();
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
    if (dx * dx + dz * dz < render.shadow.refollowDistance ** 2) return;
    this.shadowFocusX = x;
    this.shadowFocusZ = z;

    // A directional light's position is not where the light is, it is where its
    // shadow frustum is anchored. Lifting it along the reversed light direction
    // keeps the whole scene in front of the near plane.
    const dir = this.handles.sun.direction;
    const lift = render.shadow.heightAbovePlayer;
    this.handles.sun.position.set(x - dir.x * lift, y - dir.y * lift, z - dir.z * lift);
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
