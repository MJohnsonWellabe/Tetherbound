import {
  Color3,
  CreateBox,
  CreateCylinder,
  CreateSphere,
  Mesh,
  Scene,
  StandardMaterial,
  TransformNode
} from '../core/babylon';
import models from '../data/models.json';
import type { Satchel } from '../survival/Satchel';
import { stationDef, type PlacedStation, type Stations } from '../survival/Stations';
import { loadStructureSources, placeStructure } from './StructureModels';

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
 * Each station type is one Survival/Furniture Kit GLB (models.json),
 * downloaded once via loadContainer and cloned per placement; the old
 * primitive box stands in per type while the model is in flight or if it
 * never arrives. The campfire's ember glow and the orb bench's floating orb
 * stay code-built primitives on top of the models, because emissives are a
 * gameplay signal, not kit dressing.
 */

interface StationModel {
  url: string;
  scale: number;
  ember?: { diameter: number; y: number };
  orb?: { diameter: number; y: number };
}

const STATION_MODELS = models.stations as Record<string, StationModel | undefined>;

export class StationViews {
  private readonly views = new Map<PlacedStation, TransformNode>();
  private readonly materials = new Map<string, StandardMaterial>();
  /** One shared download per station type; null means "use the primitive". */
  private readonly sources = new Map<string, Promise<Mesh | null>>();
  private satchelMesh: Mesh | null = null;
  private disposed = false;

  constructor(
    private readonly scene: Scene,
    private readonly stations: Stations,
    private readonly satchel: Satchel
  ) {}

  /** Called once per frame. Cheap when nothing has changed. */
  sync(): void {
    for (const station of this.stations.all) {
      if (this.views.has(station)) continue;
      const def = stationDef(station.id);
      if (!def) continue;
      this.views.set(station, this.build(station, def.size, def.color));
    }

    // Anything whose station is gone goes with it.
    for (const [station, view] of this.views) {
      if (!this.stations.all.includes(station)) {
        view.dispose();
        this.views.delete(station);
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

  private build(station: PlacedStation, size: [number, number, number], color: string): TransformNode {
    const view = new TransformNode(`station_${station.id}`, this.scene);
    view.position.set(station.x, station.y, station.z);
    view.rotation.y = station.rot;

    const spec = STATION_MODELS[station.id];
    if (spec) {
      void this.sourceFor(station.id, spec.url).then((source) => {
        if (this.disposed || view.isDisposed()) return;
        if (source) {
          const mesh = placeStructure(this.scene, source, `station_${station.id}_model`, view);
          mesh.scaling.scaleInPlace(spec.scale);
          mesh.freezeWorldMatrix();
        } else {
          this.buildPrimitive(station.id, size, color, view);
        }
        this.addGlowAccents(station.id, spec, view);
      });
    } else {
      this.buildPrimitive(station.id, size, color, view);
    }
    return view;
  }

  /** The pre-model station look, kept as the per-type fallback. */
  private buildPrimitive(
    id: string,
    size: [number, number, number],
    color: string,
    view: TransformNode
  ): void {
    const mesh =
      id === 'campfire'
        ? CreateCylinder(
            `station_${id}_prim`,
            { height: size[1], diameter: size[0], tessellation: 8 },
            this.scene
          )
        : CreateBox(
            `station_${id}_prim`,
            { width: size[0], height: size[1], depth: size[2] },
            this.scene
          );
    mesh.position.y = size[1] / 2;
    // The campfire glows, so it reads as lit rather than merely orange, and so
    // it is findable at night when it is the only thing that matters.
    mesh.material = this.materialFor(id, color, id === 'campfire');
    mesh.isPickable = false;
    mesh.parent = view;
    mesh.freezeWorldMatrix();
  }

  /** Emissive primitives on top of the models: the fire and the orb. */
  private addGlowAccents(id: string, spec: StationModel, view: TransformNode): void {
    if (spec.ember) {
      const ember = CreateSphere(
        `station_${id}_ember`,
        { diameter: spec.ember.diameter, segments: 4 },
        this.scene
      );
      ember.scaling.y = 0.45;
      ember.position.y = spec.ember.y;
      ember.material = this.materialFor(`${id}_glow`, '#d2712f', true);
      ember.isPickable = false;
      ember.parent = view;
      ember.freezeWorldMatrix();
    }
    if (spec.orb) {
      const orb = CreateSphere(
        `station_${id}_orb`,
        { diameter: spec.orb.diameter, segments: 6 },
        this.scene
      );
      orb.position.y = spec.orb.y;
      orb.material = this.materialFor(`${id}_glow`, '#7fd8a8', true);
      orb.isPickable = false;
      orb.parent = view;
      orb.freezeWorldMatrix();
    }
  }

  private sourceFor(id: string, url: string): Promise<Mesh | null> {
    const hit = this.sources.get(id);
    if (hit) return hit;
    // Through loadStructureSources so the clone comes from the world-baked
    // prototype (handedness and dequantization live in the vertices).
    const pending = loadStructureSources(this.scene, [url]).then(
      (sources) => sources.get(url) ?? null,
      () => null
    );
    this.sources.set(id, pending);
    return pending;
  }

  private materialFor(id: string, hex: string, glowing: boolean): StandardMaterial {
    const existing = this.materials.get(id);
    if (existing) return existing;
    const mat = new StandardMaterial(`mat_station_${id}`, this.scene);
    mat.diffuseColor = Color3.FromHexString(hex);
    mat.specularColor = new Color3(0, 0, 0);
    // Glow follows the diffuse so the orb reads green and the fire orange.
    if (glowing) mat.emissiveColor = mat.diffuseColor.scale(0.5);
    mat.freeze();
    this.materials.set(id, mat);
    return mat;
  }

  dispose(): void {
    this.disposed = true;
    for (const view of this.views.values()) view.dispose();
    for (const mat of this.materials.values()) mat.dispose();
    this.satchelMesh?.dispose();
    this.satchelMesh = null;
    this.views.clear();
    this.materials.clear();
    this.sources.clear();
  }
}
