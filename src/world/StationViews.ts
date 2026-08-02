import {
  Color3,
  CreateBox,
  CreateCylinder,
  Mesh,
  Scene,
  StandardMaterial
} from '../core/babylon';
import type { Satchel } from '../survival/Satchel';
import { stationDef, type PlacedStation, type Stations } from '../survival/Stations';

/**
 * Draws stations and the satchel marker.
 *
 * The renderer half of survival/Stations.ts and survival/Satchel.ts, which are
 * pure because src/survival has to run headless under vitest and
 * tests/bundle.test.ts fails the build if it imports the engine. Same split as
 * gen/Scatter.ts and PropBatcher.ts.
 *
 * It reconciles against the state each frame rather than being told about
 * changes, which is a few comparisons on a list that is only ever a handful of
 * entries long, and removes a whole class of "the mesh and the state disagree"
 * bugs.
 *
 * Primitives for now. ASSETS.md allows it explicitly, and because a station is
 * referenced by id the M5 swap is a data change.
 */

export class StationViews {
  private readonly meshes = new Map<PlacedStation, Mesh>();
  private readonly materials = new Map<string, StandardMaterial>();
  private satchelMesh: Mesh | null = null;

  constructor(
    private readonly scene: Scene,
    private readonly stations: Stations,
    private readonly satchel: Satchel
  ) {}

  /** Called once per frame. Cheap when nothing has changed. */
  sync(): void {
    for (const station of this.stations.all) {
      if (this.meshes.has(station)) continue;
      const def = stationDef(station.id);
      if (!def) continue;
      this.meshes.set(station, this.build(station, def.size, def.color));
    }

    // Anything whose station is gone goes with it.
    for (const [station, mesh] of this.meshes) {
      if (!this.stations.all.includes(station)) {
        mesh.dispose();
        this.meshes.delete(station);
      }
    }

    this.syncSatchel();
  }

  private syncSatchel(): void {
    const marker = this.satchel.marker;
    if (!marker) {
      this.satchelMesh?.setEnabled(false);
      return;
    }
    if (!this.satchelMesh) {
      this.satchelMesh = CreateBox('satchel', { width: 0.6, height: 0.5, depth: 0.45 }, this.scene);
      this.satchelMesh.material = this.materialFor('satchel', '#b8944d', true);
      this.satchelMesh.isPickable = false;
    }
    this.satchelMesh.position.set(marker.x, marker.y + 0.25, marker.z);
    this.satchelMesh.setEnabled(true);
  }

  private build(station: PlacedStation, size: [number, number, number], color: string): Mesh {
    const mesh =
      station.id === 'campfire'
        ? CreateCylinder(
            `station_${station.id}`,
            { height: size[1], diameter: size[0], tessellation: 8 },
            this.scene
          )
        : CreateBox(
            `station_${station.id}`,
            { width: size[0], height: size[1], depth: size[2] },
            this.scene
          );
    mesh.position.set(station.x, station.y + size[1] / 2, station.z);
    mesh.rotation.y = station.rot;
    // The campfire glows, so it reads as lit rather than merely orange, and so
    // it is findable at night when it is the only thing that matters.
    mesh.material = this.materialFor(station.id, color, station.id === 'campfire');
    mesh.isPickable = false;
    mesh.freezeWorldMatrix();
    return mesh;
  }

  private materialFor(id: string, hex: string, glowing: boolean): StandardMaterial {
    const existing = this.materials.get(id);
    if (existing) return existing;
    const mat = new StandardMaterial(`mat_station_${id}`, this.scene);
    mat.diffuseColor = Color3.FromHexString(hex);
    mat.specularColor = new Color3(0, 0, 0);
    if (glowing) mat.emissiveColor = new Color3(0.55, 0.28, 0.08);
    mat.freeze();
    this.materials.set(id, mat);
    return mat;
  }

  dispose(): void {
    for (const mesh of this.meshes.values()) mesh.dispose();
    for (const mat of this.materials.values()) mat.dispose();
    this.satchelMesh?.dispose();
    this.satchelMesh = null;
    this.meshes.clear();
    this.materials.clear();
  }
}
