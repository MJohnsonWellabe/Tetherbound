import { Scene, ShadowGenerator, Vector3 } from '../core/babylon';
import type { DoorRegistry } from '../building/DoorRegistry';
import landmarks from '../data/landmarks.json';
import { Npc, NpcRegistry } from '../entities/NPC';
import { buildHall, type BuiltHall } from '../world/Hall';
import { hallPlacement, stonesPlacement, type Placement } from '../world/Landmarks';
import {
  buildStandingStones,
  buildVillage,
  disposeStructurePalette,
  pointNear,
  type BuiltStructure,
  type HomeAnchor
} from '../world/Structures';
import type { Terrain } from '../world/gen/Terrain';
import type { CompassMarker } from '../ui/HUD';

/**
 * Everything fixed in the Meadows: Hollowbrook, the standing stones, the Hall,
 * and the people standing in them.
 *
 * Built once at boot. All three landmarks are seeded, so this is deterministic
 * for a given seed and needs no save data of its own beyond the seed itself.
 */

export interface WorldHandle {
  village: BuiltStructure;
  stones: BuiltStructure;
  hall: BuiltHall;
  stonesPlacement: Placement;
  npcs: NpcRegistry;
  /**
   * Every fixed collider, for the character controller. A getter rather than
   * a snapshot array: the village's house colliders start as a placeholder
   * (primitive-sized) ring and are replaced in place once each house's real
   * model has resolved, and this must see that swap rather than the array
   * `buildWorld` happened to have at the moment it returned.
   */
  readonly colliders: { x: number; z: number; radius: number }[];
  /** Where the player's furnished house sits, for the wake-up spawn a later milestone adds. */
  home: HomeAnchor | undefined;
  markers: CompassMarker[];
  dispose: () => void;
}

export function buildWorld(
  scene: Scene,
  terrain: Terrain,
  seed: string,
  shadows: ShadowGenerator | null,
  doorRegistry: DoorRegistry
): WorldHandle {
  const hallAt = hallPlacement(terrain, seed);
  const stonesAt = stonesPlacement(terrain, seed);

  // Only Hollowbrook casts. The Hall is 900 to 1200m out and the stones 500 to
  // 700m, and there is one directional light with a 512px shadow map on mobile
  // covering all of it. At that span a distant building contributes nothing a
  // player can see while costing a shadow-map draw every frame. Measured at 94
  // casters before this; the far landmarks were most of them.
  const village = buildVillage(scene, terrain, seed, shadows, doorRegistry);
  const stones = buildStandingStones(scene, stonesAt, terrain, seed, null);
  const hall = buildHall(scene, hallAt, terrain, null);

  const npcs = new NpcRegistry();

  // Hollowbrook. Orin waits inside the player's own home house rather than
  // walking in to meet them: there is no NPC movement system at all
  // (src/entities/NPC.ts has no per-frame update, NpcRegistry has no tick),
  // so "he comes in to greet you" has to mean "he is already there" instead.
  // Offset from the room's centre (exactly where the player wakes up, see
  // main.ts's wakePos) so the two do not spawn standing inside each other,
  // and faced back toward that centre so he is not turned to the wall.
  const home = village.home;
  const orinOffset = landmarks.village.home.orinOffset;
  const orinPos = home
    ? pointNear(
        { x: home.position.x, y: home.position.y, z: home.position.z, yaw: home.yaw },
        orinOffset.forward,
        orinOffset.side
      )
    : new Vector3(4, terrain.heightAt(4, 6), 6);
  const orinYaw = home
    ? Math.atan2(home.position.x - orinPos.x, home.position.z - orinPos.z)
    : Math.PI;
  npcs.add(
    new Npc(
      scene,
      {
        id: 'orin',
        name: 'Grandpa Orin',
        role: 'elder',
        position: orinPos,
        yaw: orinYaw,
        dialogue: 'orin_intro'
      },
      shadows
    )
  );
  npcs.add(
    new Npc(
      scene,
      {
        id: 'farrow',
        name: 'Farrow',
        role: 'villager',
        position: new Vector3(-14, terrain.heightAt(-14, -8), -8),
        yaw: 0.8,
        dialogue: 'villager_farrow'
      },
      shadows
    )
  );
  npcs.add(
    new Npc(
      scene,
      {
        id: 'mabe',
        name: 'Mabe',
        role: 'villager',
        position: new Vector3(12, terrain.heightAt(12, -14), -14),
        yaw: -1.2,
        dialogue: 'villager_mabe'
      },
      shadows
    )
  );

  // The Hall. Two grunts on the way in, Bracken at the far end. Same reasoning
  // as the building itself: too far out to be worth a shadow-map slot.
  npcs.add(
    new Npc(
      scene,
      {
        id: 'grunt_a',
        name: 'Tether Grunt',
        role: 'tether',
        position: hall.anchors.gruntA.position,
        yaw: hall.anchors.gruntA.yaw,
        dialogue: 'grunt_a'
      },
      null
    )
  );
  npcs.add(
    new Npc(
      scene,
      {
        id: 'grunt_b',
        name: 'Tether Grunt',
        role: 'tether',
        position: hall.anchors.gruntB.position,
        yaw: hall.anchors.gruntB.yaw,
        dialogue: 'grunt_b'
      },
      null
    )
  );
  npcs.add(
    new Npc(
      scene,
      {
        id: 'bracken',
        name: 'Bracken Holt',
        role: 'warden',
        position: hall.anchors.warden.position,
        yaw: hall.anchors.warden.yaw,
        dialogue: 'bracken_intro'
      },
      null
    )
  );

  const markers: CompassMarker[] = [
    { label: 'Hollowbrook', x: 0, z: 0, kind: 'village' },
    { label: landmarks.standingStones.name, x: stonesAt.x, z: stonesAt.z, kind: 'stones' },
    { label: landmarks.hall.name, x: hallAt.x, z: hallAt.z, kind: 'hall' }
  ];

  return {
    village,
    stones,
    hall,
    stonesPlacement: stonesAt,
    npcs,
    get colliders() {
      return [...village.colliders, ...stones.colliders, ...hall.colliders];
    },
    home: village.home,
    markers,
    dispose: (): void => {
      npcs.dispose();
      hall.dispose();
      stones.dispose();
      village.dispose();
      disposeStructurePalette();
    }
  };
}

/** Where the Loamking waits, on the altar at the centre of the ring. */
export function loamkingPost(stones: Placement): Vector3 {
  return pointNear(stones, 0);
}
