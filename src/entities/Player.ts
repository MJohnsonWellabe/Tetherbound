import {
  Color3,
  CreateCapsule,
  CreateSphere,
  FreeCamera,
  Mesh,
  Scene,
  ShadowGenerator,
  StandardMaterial,
  TransformNode,
  Vector3
} from '../core/babylon';
import type { Input } from '../core/input/Input';
import models from '../data/models.json';
import { AnimDriver } from '../anim/AnimDriver';
import { mountRig, type RigEntry } from '../anim/Rigs';
import {
  createState,
  DEFAULT_CONFIG,
  intentToWorld,
  step,
  type ControllerState,
  type ControllerWorld
} from './CharacterController';

/**
 * The player: a capsule the controller drives, plus the third-person camera rig.
 *
 * The physics stays a capsule; the visible body is the rigged character from
 * models.json, mounted async over the capsule placeholder. Locomotion verbs
 * come from controller speed; one-shots (interact, faint) come from the game
 * via `playVerb`.
 */

/** Above this ground speed the walk clip reads wrong and run takes over. */
const RUN_SPEED = 4.6;
/** Below this the player is standing still, whatever the analog stick says. */
const IDLE_SPEED = 0.4;

/** Over-the-shoulder framing. */
const CAMERA_DISTANCE = 5.2;
const CAMERA_HEIGHT = 1.9;
const CAMERA_SHOULDER = 0.65;
const PITCH_MIN = -0.9;
const PITCH_MAX = 1.15;

export class Player {
  readonly root: TransformNode;
  readonly state: ControllerState;
  private readonly body: Mesh;
  private readonly head: Mesh;
  private readonly material: StandardMaterial;
  private readonly driver = new AnimDriver();
  private cancelRig: (() => void) | null = null;
  private yaw = 0;
  private pitch = 0.18;

  constructor(
    scene: Scene,
    private readonly camera: FreeCamera,
    spawn: { x: number; y: number; z: number },
    shadows: ShadowGenerator | null = null
  ) {
    this.root = new TransformNode('player', scene);
    this.state = createState(spawn);

    this.material = new StandardMaterial('mat_player', scene);
    this.material.diffuseColor = new Color3(0.72, 0.6, 0.44);
    this.material.specularColor = new Color3(0, 0, 0);

    this.body = CreateCapsule('player_body', { height: DEFAULT_CONFIG.height, radius: DEFAULT_CONFIG.radius }, scene);
    this.body.material = this.material;
    this.body.parent = this.root;
    // The capsule's origin is its centre; the controller's is the feet.
    this.body.position.y = DEFAULT_CONFIG.height / 2;
    this.body.isPickable = false;

    this.head = CreateSphere('player_head', { diameter: 0.42, segments: 6 }, scene);
    this.head.material = this.material;
    this.head.parent = this.root;
    this.head.position.y = DEFAULT_CONFIG.height - 0.1;
    this.head.position.z = 0.06;
    this.head.isPickable = false;

    shadows?.addShadowCaster(this.body, true);
    this.syncTransform();

    const entry = (models.characters as Record<string, RigEntry | undefined>).player;
    if (entry) {
      this.cancelRig = mountRig(scene, entry, (rig) => {
        this.body.setEnabled(false);
        this.head.setEnabled(false);
        shadows?.removeShadowCaster(this.body, true);
        rig.root.parent = this.root;
        for (const mesh of rig.root.getChildMeshes()) shadows?.addShadowCaster(mesh, false);
        this.driver.attach(rig);
        this.driver.play('idle', performance.now());
      });
    }
  }

  /** One-shot animation from the game: 'interact' on harvest, 'faint', 'wave'. */
  playVerb(verb: string): void {
    this.driver.play(verb, performance.now());
  }

  /** After a faint-and-wake, let animation run again. */
  revive(): void {
    this.driver.revive();
  }

  get position(): Vector3 {
    return new Vector3(this.state.position.x, this.state.position.y, this.state.position.z);
  }

  get cameraYaw(): number {
    return this.yaw;
  }

  /** One fixed simulation step. */
  update(input: Input, world: ControllerWorld, dt: number): void {
    const intent = input.intent;

    this.yaw += intent.look.x;
    this.pitch = Math.min(PITCH_MAX, Math.max(PITCH_MIN, this.pitch + intent.look.y));

    const { forward, right } = intentToWorld(intent.move.x, intent.move.y, this.yaw);
    step(
      this.state,
      { forward, right, sprint: intent.sprint, jump: intent.jump },
      world,
      dt,
      DEFAULT_CONFIG
    );

    // The body faces where it is going, not where the camera looks, so
    // strafing reads as strafing.
    const speed = Math.hypot(this.state.velocity.x, this.state.velocity.z);
    if (speed > IDLE_SPEED) {
      const target = Math.atan2(this.state.velocity.x, this.state.velocity.z);
      this.state.yaw = angleLerp(this.state.yaw, target, Math.min(1, 12 * dt));
    }

    this.driver.play(
      speed > RUN_SPEED ? 'run' : speed > IDLE_SPEED ? 'walk' : 'idle',
      performance.now()
    );

    this.syncTransform();
    this.updateCamera(world);
  }

  private syncTransform(): void {
    this.root.position.set(this.state.position.x, this.state.position.y, this.state.position.z);
    this.root.rotation.y = this.state.yaw;
  }

  /**
   * Orbit the camera behind the player, then pull it in if terrain would be
   * between it and the head. Without the pullback, walking backwards into a
   * hillside puts the camera underground and the screen fills with dirt.
   */
  private updateCamera(world: ControllerWorld): void {
    const focusX = this.state.position.x;
    const focusY = this.state.position.y + CAMERA_HEIGHT;
    const focusZ = this.state.position.z;

    const cosPitch = Math.cos(this.pitch);
    const dirX = -Math.sin(this.yaw) * cosPitch;
    const dirZ = -Math.cos(this.yaw) * cosPitch;
    const dirY = Math.sin(this.pitch);

    // Shoulder offset, perpendicular to the view direction.
    const shoulderX = Math.cos(this.yaw) * CAMERA_SHOULDER;
    const shoulderZ = -Math.sin(this.yaw) * CAMERA_SHOULDER;

    let distance = CAMERA_DISTANCE;
    // March along the boom and stop short of the ground. Cheaper than a ray
    // cast against chunk meshes, and the heightfield is the only thing big
    // enough to matter at this distance.
    const STEPS = 6;
    for (let i = 1; i <= STEPS; i++) {
      const d = (CAMERA_DISTANCE * i) / STEPS;
      const px = focusX + dirX * d + shoulderX;
      const pz = focusZ + dirZ * d + shoulderZ;
      const py = focusY + dirY * d;
      const ground = world.heightAt(px, pz) + 0.5;
      if (py < ground) {
        distance = Math.max(1.4, (CAMERA_DISTANCE * (i - 1)) / STEPS);
        break;
      }
    }

    this.camera.position.set(
      focusX + dirX * distance + shoulderX,
      Math.max(focusY + dirY * distance, world.heightAt(focusX + dirX * distance + shoulderX, focusZ + dirZ * distance + shoulderZ) + 0.4),
      focusZ + dirZ * distance + shoulderZ
    );
    this.camera.setTarget(new Vector3(focusX + shoulderX * 0.5, focusY, focusZ + shoulderZ * 0.5));
  }

  dispose(): void {
    this.cancelRig?.();
    this.driver.dispose();
    this.body.dispose();
    this.head.dispose();
    this.material.dispose();
    this.root.dispose();
  }
}

/** Shortest-path angle interpolation, so turning never takes the long way. */
function angleLerp(from: number, to: number, t: number): number {
  let diff = ((to - from + Math.PI) % (Math.PI * 2)) - Math.PI;
  if (diff < -Math.PI) diff += Math.PI * 2;
  return from + diff * t;
}
