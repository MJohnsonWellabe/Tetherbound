import { bus } from './core/EventBus';
import { Renderer } from './core/Engine';
import { Input } from './core/input/Input';
import { Loop } from './core/Loop';
import { Stats } from './core/Stats';
import { buildWorld } from './game/World';
import { Story } from './game/Story';
import { HUD } from './ui/HUD';
import { DialoguePanel } from './ui/DialoguePanel';
import { Fx } from './fx/Fx';
import { mountHarvestFeel } from './fx/HarvestFeel';
import { InputHint } from './ui/InputHint';
import { HarvestHud } from './ui/HarvestHud';
import { HarvestController } from './survival/HarvestController';
import { add, createInventory } from './survival/Inventory';
import { CombatMode } from './combat/CombatMode';
import { Encounter } from './combat/Encounter';
import { PalVisuals } from './entities/PalVisual';
import { SpawnManager } from './entities/SpawnManager';
import { Party } from './party/Party';
import { ReleaseFlow } from './party/Release';
import { CombatHud } from './ui/CombatHud';
import { BuildMode } from './building/BuildMode';
import { SaveManager, type SaveV1 } from './core/SaveManager';
import { createVitals, tickVitals, spendStamina } from './survival/Vitals';
import { Stations } from './survival/Stations';
import { Satchel } from './survival/Satchel';
import { Homestead } from './survival/Homestead';
import { StationViews } from './world/StationViews';
import { Player } from './entities/Player';
import type { ControllerWorld } from './entities/CharacterController';
import { buildWaterPlane } from './world/ChunkMesh';
import { ChunkManager } from './world/ChunkManager';
import { PropBatcher } from './world/PropBatcher';
import { disposePrototypes } from './world/Prototypes';
import { resolvePrototypes } from './world/PropModels';
import { SkyDome } from './world/SkyDome';
import { Terrain, WATER_LEVEL } from './world/gen/Terrain';
import { TimeOfDay } from './world/TimeOfDay';

/**
 * Boot. Keep this file thin: it wires systems together and owns nothing.
 *
 * Order matters. The canvas has to exist before the engine, the engine before
 * anything that allocates GPU resources, and the first frame has to reach the
 * screen before we start any optional network work. A boot that waits on the
 * network is a boot that looks broken on a bad connection.
 */

const canvas = document.getElementById('scene') as HTMLCanvasElement | null;
const bootEl = document.getElementById('boot');
const bootFill = document.getElementById('bootFill');
const bootMsg = document.getElementById('bootMsg');
const statsEl = document.getElementById('stats');
const fatalEl = document.getElementById('fatal');
const fatalMsg = document.getElementById('fatalMsg');
const fatalReload = document.getElementById('fatalReload');

function progress(pct: number, msg?: string): void {
  if (bootFill) bootFill.style.width = `${Math.round(pct * 100)}%`;
  if (msg && bootMsg) bootMsg.textContent = msg;
}

function fatal(err: unknown): void {
  console.error('[boot] fatal', err);
  if (bootEl) bootEl.classList.add('boot--gone');
  if (fatalMsg) {
    fatalMsg.textContent = err instanceof Error ? `${err.name}: ${err.message}` : String(err);
  }
  if (fatalEl) fatalEl.hidden = false;
}

fatalReload?.addEventListener('click', () => location.reload());

/** Autosave cadence, per ARCHITECTURE.md section "Save". */
const AUTOSAVE_MS = 60_000;
/** Stamina per tool swing. Matches the tool costs in items.json closely enough
 *  that the exact per-tool value can move there when tools get their own pass. */
const HARVEST_STAMINA = 6;

/** The world seed. Overridable with ?seed= so a bug report is reproducible. */
function resolveSeed(): string {
  return new URLSearchParams(location.search).get('seed') ?? 'hollowbrook';
}

async function boot(): Promise<void> {
  if (!canvas) throw new Error('Canvas #scene is missing from index.html');

  progress(0.1, 'Starting the renderer');
  const renderer = new Renderer(canvas);
  const { scene, camera, sun, sky, shadows } = renderer.handles;

  progress(0.3, 'Shaping the Meadows');
  const terrain = new Terrain(resolveSeed());
  // Real prop models, with the primitives as a per-family fallback. Awaited
  // before chunk streaming so the first-built cells already carry the real
  // silhouettes; a failed download costs one family its look, never the boot.
  const prototypes = await resolvePrototypes(scene);
  const chunks = new ChunkManager(scene, terrain);
  // Props stream independently of terrain chunks, batched by their own draw
  // distance. See the header of PropBatcher.ts for why they are separate.
  const props = new PropBatcher(terrain, prototypes, shadows);
  // 1024m is comfortably past the 384m terrain view distance, and small enough
  // that its subdivisions are ~43m, so per-vertex fog interpolates sensibly.
  // It follows the player, so it never needs to be world-sized.
  const water = buildWaterPlane(scene, 1024, WATER_LEVEL);

  // Hollowbrook, the standing stones, the Hall, and the people in them. All
  // three are seeded, so this is deterministic for a seed and needs no save
  // data of its own.
  const built = buildWorld(scene, terrain, resolveSeed(), shadows);

  // One adapter, so the controller and the camera both see exactly the terrain
  // the renderer drew rather than a second opinion about it.
  //
  // Landmark colliders are appended to whatever the streamed props report:
  // buildings are fixed and few and never unload, so registering them into the
  // streaming system would be bookkeeping for no gain.
  const world: ControllerWorld = {
    heightAt: (x, z) => terrain.heightAt(x, z),
    slopeAt: (x, z) => terrain.slopeAt(x, z),
    collidersNear: (x, z, r) => {
      const near = props.collidersNear(x, z, r);
      for (const collider of built.colliders) {
        if (Math.hypot(collider.x - x, collider.z - z) <= r + collider.radius) near.push(collider);
      }
      return near;
    }
  };

  progress(0.5, 'Waking Hollowbrook');
  // Hollowbrook is at the origin and its plateau is flat, so this is always
  // solid ground regardless of seed.
  const player = new Player(scene, camera, { x: 0, y: terrain.heightAt(0, 0), z: 0 }, shadows);

  // Build the ground around the spawn before the first frame, so the player
  // never sees themselves standing on nothing. Props can arrive a frame or two
  // later; bare terrain reads as "still loading", a hole reads as broken.
  chunks.update(0, 0);
  chunks.processQueue(2000);
  props.update(0, 0);
  props.processQueue(1500);

  progress(0.8, 'Setting the sun');
  const dome = new SkyDome(scene);
  const time = new TimeOfDay(scene, sun, sky, 0.2, 1, dome);
  const input = new Input(canvas);

  // Grandpa Orin's satchel. M3 hands these over in the opening scene; until
  // that scene exists the player starts with them so gathering is reachable.
  const inventory = createInventory();
  add(inventory, 'stone_axe', 1);
  add(inventory, 'stone_pick', 1);
  add(inventory, 'flint_knife', 1);
  add(inventory, 'worn_orb', 3);
  add(inventory, 'hammer', 1);
  add(inventory, 'wood', 40);
  const harvest = new HarvestController(inventory, props);

  // Pals, combat and the party. The party starts EMPTY: Grandpa Orin hands
  // over the starter, and which one is the player's first real decision
  // (GAME_DESIGN.md section 3). A pal granted here would make that choice
  // decorative, which is what it was while M3 did not exist yet.
  const party = new Party();

  const palVisuals = new PalVisuals(scene);
  const spawner = new SpawnManager(terrain, palVisuals);
  const combat = new CombatMode(party, input);
  const release = new ReleaseFlow(party);
  const encounter = new Encounter(combat, spawner, party, release, inventory, input);
  const vitals = createVitals();
  const build = new BuildMode(scene, inventory, world);
  const saves = new SaveManager();
  const stationsOwned = new Stations();
  const satchel = new Satchel();
  const stationViews = new StationViews(scene, stationsOwned, satchel);
  const homestead = new Homestead(stationsOwned, satchel, party, spawner, inventory, world);

  const combatHud = new CombatHud(
    document.getElementById('combat') as HTMLElement,
    combat,
    party,
    release
  );
  const harvestHud = new HarvestHud(
    document.getElementById('gather') as HTMLElement,
    harvest
  );
  const hint = new InputHint(
    document.getElementById('hint') as HTMLElement,
    input,
    document.getElementById('fullscreen')
  );

  const fx = new Fx(scene, document.getElementById('fx') as HTMLElement);
  const unmountFeel = mountHarvestFeel(fx);

  // M3 and M4: the compass and party HUD, the conversations, and the Hall.
  const hud = new HUD();
  const dialoguePanel = new DialoguePanel();
  const story = new Story(
    built,
    party,
    combat,
    release,
    inventory,
    input,
    hud,
    dialoguePanel,
    resolveSeed()
  );
  hud.updateParty(party);

  // Load before the first frame, so the player never sees the default world
  // flash before their own.
  const loaded = saves.load();
  if (loaded.ok) {
    player.state.position.x = loaded.save.player.pos.x;
    player.state.position.y = loaded.save.player.pos.y;
    player.state.position.z = loaded.save.player.pos.z;
    vitals.health = loaded.save.player.health;
    vitals.stamina = loaded.save.player.stamina;
    vitals.hunger = loaded.save.player.hunger;
    props.restoreHarvested(loaded.save.worldDeltas.harvested);
    build.restore(loaded.save.structures);
    stationsOwned.restore(loaded.save.stations ?? []);
    homestead.respawn = loaded.save.respawn ?? null;
    satchel.restore(loaded.save.satchel ?? null);
    for (let i = 0; i < loaded.save.inventory.length && i < inventory.length; i++) {
      inventory[i] = loaded.save.inventory[i] ?? null;
    }
    // The party and the story were being written to the save and never read
    // back: a reload returned you to Hollowbrook with no pals and Orin ready to
    // hand over a starter you already had.
    party.restore([...loaded.save.party], [...loaded.save.releasedLedger]);
    story.restore(loaded.save.progress);
    time.day = loaded.save.progress.day;
    time.cycle = loaded.save.progress.timeOfDay;
    hud.updateParty(party);
    chunks.update(player.state.position.x, player.state.position.z);
    chunks.processQueue(2000);
    props.update(player.state.position.x, player.state.position.z);
    props.processQueue(1500);
  }

  function snapshotSave(): SaveV1 {
    return {
      schemaVersion: 1,
      seed: resolveSeed(),
      createdAt: loaded.ok ? loaded.save.createdAt : Date.now(),
      savedAt: Date.now(),
      player: {
        pos: {
          x: player.state.position.x,
          y: player.state.position.y,
          z: player.state.position.z
        },
        rot: player.state.yaw,
        health: vitals.health,
        stamina: vitals.stamina,
        hunger: vitals.hunger
      },
      inventory: [...inventory],
      party: [...party.members],
      releasedLedger: [...party.ledger],
      structures: [...build.structures],
      stations: [...stationsOwned.all],
      respawn: homestead.respawn,
      satchel: satchel.marker,
      worldDeltas: { harvested: props.harvestedKeys, bossesDown: {} },
      progress: { ...story.snapshot(), day: time.day, timeOfDay: time.cycle }
    };
  }

  // Autosave every 60s and on visibility change, per ARCHITECTURE.md.
  let sinceSaveMs = 0;
  const flush = (): void => {
    const result = saves.save(snapshotSave());
    bus.emit('saveStatus', result.ok ? { status: 'saved' } : { status: 'failed', reason: result.reason ?? '' });
  };
  document.addEventListener('visibilitychange', () => {
    if (document.visibilityState === 'hidden') flush();
  });

  const loop = new Loop({
    update: (dt, elapsedMs) => {
      input.beginFrame();

      // A hit pause withholds simulation steps; it never scales dt and never
      // skips a frame. See src/fx/hitPause.ts for why both alternatives are
      // wrong. Input still runs, so its edge detection does not bank a press
      // for the moment the world resumes.
      if (fx.frozen(dt)) {
        input.endFrame();
        return;
      }

      player.update(input, world, dt);
      chunks.update(player.state.position.x, player.state.position.z);
      props.update(player.state.position.x, player.state.position.z);
      renderer.focusShadows(
        player.state.position.x,
        player.state.position.y,
        player.state.position.z
      );
      if (time.tick(dt)) bus.emit('dayChanged', { day: time.day });

      // Stamina is not wired to vitals yet, so swings are free for now. The
      // signature already takes it so that hooking Vitals up is one argument.
      tickVitals(vitals, dt * 1000, input.intent.sprint && !combat.isFighting);

      // People first. A conversation, or a Hall fight, owns the interact
      // button outright: talking to Orin while chopping the tree behind him
      // would fire both, and the Hall sequence must not be walkable-away-from
      // by swinging an axe.
      const busyTalking = story.update(
        player.state.position.x,
        player.state.position.z,
        player.cameraYaw
      );
      hud.updateVitals(vitals);
      hud.updateDay(time.day, time.isNight);

      // Building takes over the interact button while the hammer is out, so
      // the two never compete for the same press.
      const hammerOut = harvest.equippedId === 'hammer';
      build.update(
        input.intent,
        hammerOut,
        player.state.position.x,
        player.state.position.z,
        player.cameraYaw
      );

      const swing = hammerOut || busyTalking
        ? null
        : harvest.update(
            input.intent,
            player.state.position.x,
            player.state.position.z,
            time.day,
            vitals.stamina
          );
      // Charge the swing only once it actually connected.
      if (swing && !swing.refusal) spendStamina(vitals, HARVEST_STAMINA);
      harvestHud.report(swing);
      harvestHud.update(player.state.position.x, player.state.position.z, vitals);

      spawner.update(
        player.state.position.x,
        player.state.position.z,
        dt,
        time.cycle,
        time.day
      );
      // A scripted Hall fight drives CombatMode itself, so the wild encounter
      // loop stands down. Without this the two race for the same fight and a
      // wandering Tuftmoth can interrupt Bracken.
      if (story.inScriptedFight) combat.update(dt, time.day);
      else encounter.update(player.state.position.x, player.state.position.z, dt, time.day);
      if (input.intent.throwOrb) combatHud.reportThrow(encounter.throwOrb(time.day));

      // The release screen is driven by the same slot input the party uses:
      // pick a number to select, press it again to confirm, throw to cancel.
      if (release.stage !== 'closed') {
        const slot = input.intent.slot;
        if (input.intent.throwOrb) release.cancel();
        else if (slot !== null) {
          const candidate = release.candidates(time.day)[slot - 1];
          if (candidate) {
            if (release.stage === 'confirming' && release.selectedUid === candidate.pal.uid) {
              release.confirm(time.day);
            } else {
              release.select(candidate.pal.uid);
            }
          }
        }
      }
      combatHud.update(time.day);

      // Water follows the player so one plane covers the visible world without
      // being large enough to lose float precision at the horizon.
      water.position.x = player.state.position.x;
      water.position.z = player.state.position.z;

      const homeAction = homestead.update(
        input.intent,
        player.state.position.x,
        player.state.position.z,
        dt
      );
      if (homeAction === 'slept') {
        // Skip to morning. TimeOfDay owns the cycle, so this asks it rather
        // than rewriting the clock in two places.
        time.cycle = homestead.wakeCycle;
        time.tick(0);
        bus.emit('slept', { day: time.day });
      }

      // Fainting: satchel drops here, the player wakes at their bed.
      if (vitals.health <= 0) {
        const wake = homestead.faint(
          vitals,
          player.state.position.x,
          player.state.position.y,
          player.state.position.z
        );
        player.state.position.x = wake.x;
        player.state.position.y = wake.y + 1;
        player.state.position.z = wake.z;
        player.state.velocity.x = 0;
        player.state.velocity.y = 0;
        player.state.velocity.z = 0;
      }

      sinceSaveMs += dt * 1000;
      if (sinceSaveMs >= AUTOSAVE_MS) {
        sinceSaveMs = 0;
        flush();
      }

      fx.update(dt);

      bus.emit('tick', { dt, elapsedMs });
      input.endFrame();
    },
    render: () => {
      // Streaming runs in the render phase, outside the fixed-step update, so
      // a frame that owes several simulation steps does not also owe several
      // chunk builds.
      chunks.processQueue();
      props.processQueue();
      stationViews.sync();
      hint.update();
      // After the camera rig has run and before the draw, so the shake offset
      // lands in the frame it was computed for.
      fx.render(scene, camera, renderer.handles.engine);
      renderer.render();
      stats?.sample(performance.now());
    }
  });

  const stats = Stats.enabled() && statsEl ? new Stats(scene, loop, statsEl) : null;

  renderer.onContextRestored = (): void => {
    scene.markAllMaterialsAsDirty(1);
  };

  await new Promise<void>((resolve) => {
    scene.onAfterRenderObservable.addOnce(() => resolve());
    loop.start();
  });

  progress(1, 'Ready');
  bootEl?.classList.add('boot--gone');
  window.setTimeout(() => bootEl?.remove(), 450);

  (window as unknown as Record<string, unknown>).__tetherbound = {
    renderer,
    loop,
    scene,
    bus,
    input,
    player,
    harvest,
    inventory,
    party,
    spawner,
    combat,
    encounter,
    release,
    build,
    stationsOwned,
    satchel,
    homestead,
    vitals,
    saves,
    // The story and the built world, so the smoke tools can drive the Hall
    // spine without walking 1100m and winning three fights by hand.
    story,
    built,
    hud,
    snapshotSave,
    chunks,
    props,
    terrain,
    time,
    fx,
    dispose: (): void => {
      loop.stop();
      unmountFeel();
      fx.dispose();
      dialoguePanel.dispose();
      hud.dispose();
      built.dispose();
      hint.dispose();
      input.dispose();
      player.dispose();
      chunks.dispose();
      props.dispose();
      spawner.dispose();
      palVisuals.dispose();
      build.dispose();
      stationViews.dispose();
      disposePrototypes(prototypes);
      dome.dispose();
      water.dispose();
      renderer.dispose();
    }
  };
}

boot().catch(fatal);
