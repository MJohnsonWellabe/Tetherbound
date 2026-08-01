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
    camera.minZ = 0.35;
    camera.maxZ = 900;
    camera.fov = 0.9;
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

    const shadows = new ShadowGenerator(device.shadowMapSize, sun);
    shadows.usePercentageCloserFiltering = !device.isTouch;
    shadows.filteringQuality = ShadowGenerator.QUALITY_LOW;
    shadows.bias = 0.008;
    shadows.normalBias = 0.02;
    // Static scenery dominates the shadow map. Regenerating it every frame is
    // pure waste; world systems call getShadowMap().refreshRate when something
    // actually moves.
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
