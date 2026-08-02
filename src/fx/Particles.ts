import {
  Color4,
  DynamicTexture,
  ParticleSystem,
  Scene,
  Vector3,
  type Texture
} from '../core/babylon';
import fx from '../data/fx.json';

/**
 * Pooled burst emitters.
 *
 * CLAUDE.md, performance discipline: "Object pools for pals, orbs, particles,
 * and damage numbers from day one. Retrofitting these is a rewrite." This is
 * that pool, built before M2 needs it rather than after.
 *
 * Constructing a ParticleSystem allocates vertex and index buffers and compiles
 * against the scene's effect cache. Doing that on impact means the first chop
 * of each material stutters, which is exactly the frame the player is looking
 * at. So every system is built at boot, and emitting is a reposition plus a
 * `start()`.
 *
 * Systems per preset are a small ring. When a burst is requested and every
 * system in the ring is still playing, the oldest is restarted rather than a
 * new one being built: the visual cost is one truncated puff, the alternative
 * is an allocation during the busiest frame in the game.
 *
 * The sprite is generated into a DynamicTexture rather than loaded, so the feel
 * layer has no asset dependency and no manifest row. One 32x32 radial dot,
 * shared by every preset and tinted per system.
 */

export type ParticlePreset = keyof typeof fx.particles.presets;

interface PresetConfig {
  readonly count: number;
  readonly lifeMs: readonly number[];
  readonly size: readonly number[];
  readonly speed: readonly number[];
  readonly gravity: number;
  readonly cone: number;
  readonly colorFrom: readonly number[];
  readonly colorTo: readonly number[];
}

interface Ring {
  readonly systems: ParticleSystem[];
  /** Next system to claim, round robin. */
  cursor: number;
}

export class Particles {
  private readonly rings = new Map<string, Ring>();
  private readonly sprite: Texture;
  private readonly scene: Scene;

  constructor(scene: Scene) {
    this.scene = scene;
    this.sprite = createDot(scene, fx.particles.textureSize);

    for (const [id, preset] of Object.entries(fx.particles.presets)) {
      const systems: ParticleSystem[] = [];
      for (let i = 0; i < fx.particles.poolPerPreset; i++) {
        systems.push(this.build(`fx_${id}_${i}`, preset as PresetConfig));
      }
      this.rings.set(id, { systems, cursor: 0 });
    }
  }

  /**
   * Fire one burst of `preset` at a world position.
   *
   * `manualEmitCount` plus `targetStopDuration` is what makes this a burst
   * rather than a stream: the system emits its whole budget on the first frame
   * and stops itself once the last particle has aged out.
   */
  burst(preset: ParticlePreset | string, x: number, y: number, z: number): void {
    const ring = this.rings.get(preset);
    if (!ring) return;

    const system = ring.systems[ring.cursor] as ParticleSystem;
    ring.cursor = (ring.cursor + 1) % ring.systems.length;

    // Restarting a live system is deliberate; see the header. stop() alone
    // leaves the emit count spent, so the reset has to be explicit.
    system.stop();
    system.reset();
    (system.emitter as Vector3).set(x, y, z);
    system.manualEmitCount = (fx.particles.presets[preset as ParticlePreset] as PresetConfig).count;
    system.start();
  }

  private build(name: string, preset: PresetConfig): ParticleSystem {
    // Capacity is the burst size exactly. A CPU particle system allocates its
    // buffers from capacity, so rounding it up wastes memory per preset per
    // pool slot for particles that can never exist.
    const system = new ParticleSystem(name, preset.count, this.scene);
    system.particleTexture = this.sprite;
    system.emitter = new Vector3(0, 0, 0);

    system.color1 = toColor(preset.colorFrom);
    system.color2 = toColor(preset.colorFrom);
    system.colorDead = toColor(preset.colorTo);

    system.minSize = preset.size[0] as number;
    system.maxSize = preset.size[1] as number;
    system.minLifeTime = (preset.lifeMs[0] as number) / 1000;
    system.maxLifeTime = (preset.lifeMs[1] as number) / 1000;
    system.minEmitPower = preset.speed[0] as number;
    system.maxEmitPower = preset.speed[1] as number;
    system.gravity = new Vector3(0, preset.gravity, 0);

    // A cone pointing up, so chips arc off the struck surface rather than
    // spraying evenly in a sphere and reading as a magic effect.
    system.createConeEmitter(preset.cone, Math.PI / 3);

    // Additive would glow, which is wrong for wood chips and stone grit. The
    // sparks in M2 are the case that will want it, per preset.
    system.blendMode = ParticleSystem.BLENDMODE_STANDARD;
    system.emitRate = 0;
    system.manualEmitCount = 0;
    // Without a stop duration the system idles forever once started, keeping
    // itself in the scene's render list for nothing.
    system.targetStopDuration = (preset.lifeMs[1] as number) / 1000;
    system.disposeOnStop = false;
    system.preWarmCycles = 0;

    return system;
  }

  /** Stop everything without disposing. Used on mode changes. */
  stopAll(): void {
    for (const ring of this.rings.values()) {
      for (const system of ring.systems) system.stop();
    }
  }

  dispose(): void {
    for (const ring of this.rings.values()) {
      for (const system of ring.systems) system.dispose();
    }
    this.rings.clear();
    this.sprite.dispose();
  }
}

/**
 * A soft radial dot, drawn once into a DynamicTexture.
 *
 * Hard-edged squares read as compression artefacts at small sizes, and a
 * downloaded sprite would be an asset dependency and a manifest row for
 * thirty-two pixels of gradient.
 */
function createDot(scene: Scene, size: number): Texture {
  const texture = new DynamicTexture(
    'fx_dot',
    { width: size, height: size },
    scene,
    false
  );
  const ctx = texture.getContext() as CanvasRenderingContext2D;
  const r = size / 2;
  const gradient = ctx.createRadialGradient(r, r, 0, r, r, r);
  gradient.addColorStop(0, 'rgba(255,255,255,1)');
  gradient.addColorStop(0.55, 'rgba(255,255,255,0.85)');
  gradient.addColorStop(1, 'rgba(255,255,255,0)');
  ctx.fillStyle = gradient;
  ctx.fillRect(0, 0, size, size);
  texture.update(false);
  texture.hasAlpha = true;
  return texture as unknown as Texture;
}

function toColor(rgba: readonly number[]): Color4 {
  return new Color4(rgba[0] as number, rgba[1] as number, rgba[2] as number, rgba[3] as number);
}
