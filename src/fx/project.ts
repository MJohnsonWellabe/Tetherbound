import { Matrix, Vector3, Viewport, type FreeCamera, type Scene } from '../core/babylon';

/**
 * World position to screen pixels, shared by every pooled-DOM overlay
 * (damage numbers, nameplates). Allocation-free: one scratch set per module
 * consumer via makeProjector().
 */

export interface Projector {
  /**
   * Project a world point. Returns false when the point is behind the camera
   * (in which case x/y are stale and the caller should hide the element).
   */
  toScreen(x: number, y: number, z: number, out: { x: number; y: number }): boolean;
  /** Call once per frame before projecting. */
  begin(scene: Scene, camera: FreeCamera, width: number, height: number): void;
}

export function makeProjector(): Projector {
  const scratch = new Vector3();
  const viewTemp = new Vector3();
  const identity = Matrix.Identity();
  const viewport = new Viewport(0, 0, 0, 0);
  let scene: Scene | null = null;
  let camera: FreeCamera | null = null;

  return {
    begin(s: Scene, c: FreeCamera, width: number, height: number): void {
      scene = s;
      camera = c;
      viewport.width = width;
      viewport.height = height;
    },
    toScreen(x: number, y: number, z: number, out: { x: number; y: number }): boolean {
      if (!scene || !camera) return false;
      scratch.set(x, y, z);
      // A point behind the camera still projects to finite mirrored pixels;
      // view-space depth is the honest visibility test (see DamageNumbers).
      Vector3.TransformCoordinatesToRef(scratch, scene.getViewMatrix(), viewTemp);
      if (viewTemp.z <= camera.minZ) return false;
      const screen = Vector3.Project(scratch, identity, scene.getTransformMatrix(), viewport);
      out.x = screen.x;
      out.y = screen.y;
      return true;
    }
  };
}
