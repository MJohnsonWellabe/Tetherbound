import {
  CreateBox,
  CreateCylinder,
  Scene,
  ShadowGenerator,
  TransformNode
} from '../core/babylon';
import landmarks from '../data/landmarks.json';
import models from '../data/models.json';
import { subRng } from './gen/Rng';
import type { Terrain } from './gen/Terrain';
import type { Placement } from './Landmarks';
import { loadStructureSources, placeStructure } from './StructureModels';
import { structurePalette, type BuiltStructure } from './Structures';

/**
 * The standing stones, and the Loamking's ground.
 *
 * A ring of leaning menhirs cut from the shipped stone_tall props, stretched
 * on Y for monolith proportions (models.json holds the ranges). The lean is
 * what stops seven similar stones from reading as a fence. Positions and the
 * 1.1m colliders are unchanged from the primitive version; if a stone model
 * fails to load, that stone falls back to the old leaning box.
 */

const STONES = models.buildings.stones;

export function buildStandingStones(
  scene: Scene,
  placement: Placement,
  terrain: Terrain,
  seed: string,
  shadows: ShadowGenerator | null
): BuiltStructure {
  const p = structurePalette(scene);
  const root = new TransformNode('standing_stones', scene);
  const rng = subRng(seed, 'stones');
  const colliders: { x: number; z: number; radius: number }[] = [];

  const count = landmarks.standingStones.stones;
  const radius = landmarks.standingStones.ringRadius;

  interface Slot {
    node: TransformNode;
    url: string;
    scaleXZ: number;
    scaleY: number;
    height: number;
    girth: [number, number];
  }
  const slots: Slot[] = [];
  const range = (lo: number, hi: number): number => lo + rng() * (hi - lo);

  for (let i = 0; i < count; i++) {
    const angle = (i / count) * Math.PI * 2;
    const x = placement.x + Math.cos(angle) * radius;
    const z = placement.z + Math.sin(angle) * radius;

    const scaleY = range(STONES.scaleY[0]!, STONES.scaleY[1]!);
    const scaleXZ = range(STONES.scaleXZ[0]!, STONES.scaleXZ[1]!);
    const girth: [number, number] = [1.5 + rng() * 0.8, 0.9 + rng() * 0.4];

    const node = new TransformNode(`stone_slot_${i}`, scene);
    node.parent = root;
    // Sunk slightly, so a leaning stone never shows daylight under its heel.
    node.position.set(x, terrain.heightAt(x, z) - 0.4, z);
    node.rotation.set((rng() - 0.5) * 0.18, angle, (rng() - 0.5) * 0.18);

    slots.push({ node, url: STONES.variants[i % STONES.variants.length]!, scaleXZ, scaleY, height: scaleY, girth });
    colliders.push({ x, z, radius: 1.1 });
  }

  let disposed = false;

  void (async () => {
    const sources = await loadStructureSources(scene, slots.map((s) => s.url));
    if (disposed || scene.isDisposed) return;
    for (const slot of slots) {
      const source = sources.get(slot.url) ?? null;
      if (source) {
        const mesh = placeStructure(scene, source, 'stone_model', slot.node);
        // Per-axis so girth and height tune independently; the clone starts
        // from identity (handedness is baked into the vertices).
        mesh.scaling.set(slot.scaleXZ, slot.scaleY, slot.scaleXZ);
        shadows?.addShadowCaster(mesh, false);
        mesh.freezeWorldMatrix();
      } else {
        const stone = CreateBox(
          'standing_stone',
          { width: slot.girth[0], depth: slot.girth[1], height: slot.height },
          scene
        );
        stone.material = structurePalette(scene).stone;
        stone.position.y = slot.height / 2;
        stone.isPickable = false;
        stone.parent = slot.node;
        shadows?.addShadowCaster(stone, false);
      }
    }
  })();

  // A low altar in the middle, so the ring has a centre worth walking to.
  const altar = CreateCylinder(
    'stones_altar',
    { height: 0.7, diameter: 4.4, tessellation: 7 },
    scene
  );
  altar.material = p.stone;
  altar.position.set(placement.x, terrain.heightAt(placement.x, placement.z) + 0.35, placement.z);
  altar.isPickable = false;
  altar.parent = root;
  shadows?.addShadowCaster(altar, false);

  return {
    root,
    colliders,
    dispose: () => {
      disposed = true;
      root.dispose(false, false);
    }
  };
}
