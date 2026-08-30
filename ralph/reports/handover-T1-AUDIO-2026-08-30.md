# T1-AUDIO handover — 2026-08-30

**Branch:** `ralph/T1-AUDIO` off `origin/main`.
**Lane:** give the Meadows a soundscape. The chapter shipped silent.

---

## 1. What the inventory actually was

The framing this lane was given was that the game contains fifteen audio files.
That is correct, and I verified it independently rather than accepting it:

```
find . -type f \( -iname "*.wav" -o -iname "*.ogg" -o -iname "*.mp3" ... \)
```

returns exactly 15 files — 9 generated UI cues under `assets/ui/audio/`, and 6
Kenney vendor clicks under `assets_raw/` (which is gitignored and ships
nothing). No music, no ambience, no footsteps, no combat audio, no creature
voices. `project.godot` had **no `[audio]` section at all**, and there was no
bus layout, so every sound in the game played on a bare Master bus.

Two corrections to the framing, both worth having on record:

- **There WAS already a synthesis path**, and the lane brief was right to ask.
  `tools/audio/gen_ui_cues.py` generates the nine UI cues from the Python
  standard library, and `docs/ASSET_LEDGER.md` already records them as "written
  for this task". That precedent is the single most important fact for this
  lane, and everything below extends it rather than inventing an approach.
- **The nine UI cues are properly wired**, contrary to my own first reading.
  I initially grepped for `AudioCues.play` and found nothing outside the class
  itself, which looked like nine files and zero call sites. That was my error:
  the four call sites reach it through a preloaded `AUDIO_CUES` const
  (`game_menu.gd`, `build_menu.gd`, `playground_hud.gd`, `build_placer.gd`),
  and there are 21 of them. The UI has sound and always did.

**Real gap found while checking that:** `aim_enter` and `capture_success` are
in `CUE_PATHS` and generated on disk, but nothing plays either one. Two of the
nine cues are dead. Not fixed here (they belong to the combat/catch lanes that
own those moments); recorded in §6.

---

## 2. Approach: synthesised, not sourced

Everything in `assets/audio/` is computed in Python by committed code in
`tools/audio/`. Nothing was downloaded. `docs/ASSET_LEDGER.md` carries one row
covering all 73 files, and **no third-party licence attaches to any of them**.

The reasoning is recorded in `tools/audio/synth.py`'s header so the next session
can disagree with it on the evidence rather than on my say-so. In short:

| | Why it won |
|---|---|
| **Cohesion** | One synthesis chain means the set matches by construction. Ten free packs recorded in ten rooms do not, and reconciling them is a mastering project. |
| **Memory** | ROG Ally is primary and shares VRAM with system RAM. The eight ambience layers are 6.2 MB of PCM on disk but **161 KB each in RAM** after Godot's QOA import — 1.3 MB for the whole ambient bed. |
| **Licence** | No redistributability question to answer, ever. |
| **Parameterisation** | A creature voice takes a pitch and a formant. A `.wav` does not — which is what makes 16 species cost 8 files. |

**Where this is honestly worse, and I have not pretended otherwise:**

- **Birdsong.** `meadow_birds` reads as "small bird", not as a species. A
  recording would be better. It is mixed sparse and quiet partly for realism
  and partly because that flatters the shortfall.
- **Music.** The five cues are short generated loops, not a score.
  `gen_music.py`'s header says outright that they should be replaced. They are
  here because a chapter with wind, footsteps and *no music* still reads as
  unfinished, and because a placeholder in the right mode at the right pacing
  is a better brief for a composer than silence.

Wind, water, stone, impacts and creature voices are cases where synthesis is
genuinely competitive or better. That is the bulk of the set.

**Budget, measured rather than estimated.** 73 files, 17 MB of PCM in the repo,
**3.4 MB after import** (that figure is the whole `.godot/imported` audio set,
including the nine pre-existing UI cues). Godot's default `compress/mode=2`
gives QOA for free, which is where the ~5× comes from.

**Determinism is a hard property.** Every generator takes an explicit seed and
its own `numpy.random.Generator`. `python3 tools/audio/gen_all.py` with no
source change produces byte-identical files, so `git status` after a run is the
honest answer to "has anyone hand-edited an asset". numpy is tool-time only —
the `.wav`s are committed, nothing in CI or an export runs these scripts, and
numpy is already a dependency of ten other `tools/*.py`.

---

## 3. What shipped

### Mixer

`default_bus_layout.tres` — six buses, **generated** by
`tools/audio/make_bus_layout.gd` rather than hand-typed, for the same reason
the WAVs carry their own loop metadata: a resource format is the engine's
business.

```
Master
 ├─ Music     -8 dB
 ├─ Ambience -12 dB   (low on purpose: it plays for hours behind everything)
 ├─ SFX       -4 dB
 ├─ Creatures -5 dB
 └─ UI        -6 dB
```

Five children rather than the usual three because the settings screen exposes
one slider per bus, and *Ambience* and *Creatures* are exactly the two a player
is most likely to want to move independently.

### Code

| File | What it is |
|---|---|
| `scripts/audio/audio_manager.gd` | Static core: buses, volumes, stream cache, one-shot pools, variant picking. `RefCounted` + statics, **not an autoload** — D14 keeps the autoload list at one, and `audio_cues.gd` already established this exact shape. |
| `scripts/audio/world_audio.gd` | The per-frame half: ambience beds, footsteps, music, creature voices, combat hooks. A `Node` in `meadows_playground.tscn` beside `WorldLook`/`WorldWeather`, because it is the same kind of thing they are. |
| `data/config/audio.json` | Every tunable. Band layer gains, footstep timing and surfaces, combat signal→sound mapping, creature archetypes and per-species pitch, music priorities and pacing. |

**It subscribes; it does not intrude.** Not one line of `combat_manager.gd` or
`player_controller.gd` was changed. Combat already emitted `hit_landed`,
`hit_effectiveness`, `attack_missed`, `orb_shook`, `catch_resolved`, `entered`
and `exited`; footsteps are derived from distance travelled. Deleting the
`WorldAudio` node degrades the project to exactly where it was, with nothing
else broken.

### Ambience — layers, not beds

Eight looping layers, mixed live at per-band, per-time-of-day gains from
`audio.json`. The obvious build is ten finished beds (5 bands × day/night);
layers won because **a band's identity becomes data** a designer can change and
hear, because most layers appear in several bands so eight cover all ten cases,
and — the deciding reason — because **day and night can crossfade**. Ten beds
can only hard-cut at dusk. Per-layer gains interpolate for free, so dusk is
birds receding while crickets arrive.

Measured separation of the eight layers (spectral centroid):

```
wind_low       126 Hz      quarry_stone     457 Hz
tether_drone  2160 Hz      ironwood_canopy 2640 Hz
meadow_birds  3233 Hz      wind_high       3300 Hz
river_water   3451 Hz      night_insects   5414 Hz
```

### Creature voices — 4 archetypes, not 20 files

Each species names an archetype (`chirp`/`growl`/`rumble`/`trill`) plus a
**pitch**, keyed off size. Pitch is the right differentiator because it is the
real one: within a family, size sets voice. Ashtusk at 0.74 and Sparkit at 1.24
are recognisably different animals and cost one file between them.

Idle and alert within an archetype share their formant structure and differ only
in contour — verifiable in the measurements: each pair's centroid matches
(rumble 455/481, growl 1065/1071, trill 1494/1482, chirp 2500/2201). That is the
"same throat" property the design depends on: a player learns a creature from its
idle call, so the alert must be recognisably the same animal or it teaches
nothing.

One idle timer for the **whole world**, not one per creature — a herd of six
must not vocalise six times as often as a lone one.

### Settings

An `Audio` section in the pause menu, which is exactly the shape
`tab_settings.gd`'s own header already described for it ("Display and audio are
a JSON entry plus a `_build_*` method here") and `key_bindings.gd::save()`'s
payload already reserved a named `audio` key for. Both comments predate this
lane; I filled in the shape the codebase had already designed.

One row per bus. **Left/right on a focused row is the whole interaction** — not
a Godot `HSlider`, whose grab handle is a mouse affordance and whose focus
behaviour differs from every other control on that screen. Pointing a Button's
left/right focus neighbours at itself frees `ui_left`/`ui_right` to be the
volume verb, which is the same trick `_link_horizontal_to_self` already used.
Volumes persist in `user://settings.json`'s new `audio` section, written by
`key_bindings.gd`, which stays the file's only writer (D15).

Volume mapping is `fraction²` into the dB range, not linear: a linear dB slider
spends its top half in changes the ear cannot hear. 100% lands *exactly* on the
authored default, so a fresh install and a slider at full are the same mix. 0%
mutes outright.

---

## 4. Evidence

The repo's rule is that evidence which does not show the shipping game is worse
than none. Audio makes that easy to fake — a test asserting a `.wav` exists on
disk passes on a build where nothing plays it, which is *precisely* the state
this lane found the project in.

So `tests/smoke_audio.gd` boots `meadows_playground.tscn` — the real world, the
same scene `smoke_combat.gd` drives — walks the player with real input actions,
fights a real fight, and asserts on **what reached the mixer**.

CI has no audio device, so nothing can measure output. But everything up to the
device is real: streams load, pool nodes exist in the tree, bus indices resolve,
`play()` is called on real `AudioStreamPlayer`s. `AudioManager` records each call
when `logging_enabled` is set. A regression in the wiring — a renamed signal, a
missing file, a bus typo, an ambience layer that never starts — fails there. A
regression only a human ear could catch does not, and the file says so.

**Actual output, `godot --headless --path . --script tests/smoke_audio.gd`:**

```
  ambience playing: Ambience_wind_low, Ambience_wind_high, Ambience_meadow_birds
  5 footsteps over 150 frames
  4 distinct footstep variants used
  combat sounds heard: step_grass, combat_start, impact_normal,
                       growl_idle, damage_taken, combat_win
  band 1 layers: meadow_birds, wind_high, wind_low
  band 2 layers: meadow_birds, quarry_stone, wind_low
smoke_audio: OK -- the shipping game makes sound
```

Reading that line by line, because each one is a claim this lane has to make good on:

- The **Band 1 day mix** is playing in the real world, started by the world's own
  node, at an audible level (the test fails a layer that is `playing` but below
  −60 dB — "playing" and "audible" are not the same claim).
- **Footsteps fire from real movement** and use 4 distinct variants, so the
  no-immediate-repeat rule is working end to end and not just in the unit test.
- **A whole fight is audible**: engaging played `combat_start`, a hit on the
  enemy played `impact_normal`, a hit taken played `damage_taken`, and the
  resolution played `combat_win` — all driven by `combat_manager.gd`'s existing
  signals, with no change to combat.
- `growl_idle` appearing unprompted is the **creature voice system** firing on
  its own during the fight: a real creature, at its own position, in its
  species' archetype and pitch. That was not something the test asked for.
- **Band 1 and Band 2 play genuinely different beds.** `wind_high` drops out and
  `quarry_stone` comes in, which is the configured intent (Band 2 is enclosed,
  so the open-ground wind goes away). This is the check that would catch the
  whole region feature being wired to a constant.



`smoke_audio` is wired into CI as a `verify-core-verb-shard` matrix entry with
two retries (its last section walks to a wild creature and fights it, which
carries the same spawn/pathing variance `catching` is already retried for). **This
takes a full run from 55 jobs to 56** — the brief's 55 is confirmed: 45 static
jobs plus `verify-unit-tests`' 10 shards. An evidence test that is not in CI
rots, which is how a lane like this ends up with a soundscape that stopped
playing three merges ago.

`tests/test_audio.gd` covers the pure half: 22 tests, 334 assertions. It
deliberately does **not** assert the game makes a sound — a green run there on a
build with `WorldAudio` deleted would still pass. Notable checks:

- every ambience layer imports with `LOOP_FORWARD` (a bed that does not loop
  leaves the region silent seconds after arrival, which looks exactly like the
  feature failing while every file is present);
- every band has day *and* night ambience, and no two bands share a layer set —
  the audio form of exit criterion **A5**, "different parts felt like distinct
  real places";
- the variant picker never repeats immediately, which is the entire reason
  footsteps ship four variants and which nothing else in the suite would notice
  regressing.

---

## 5. A note on the loop metadata

Ambience beds must loop. The tempting way to guarantee that is to hand-write
`.import` sidecars with `edit/loop_mode` set — which would have been **wrong**:
in Godot 4 that setting's `0` means *"Detect From WAV"*, not *"disabled"*.

So `synth.py` writes a RIFF `smpl` chunk into the WAV itself and lets Godot's
importer read it. Verified in-engine rather than assumed:

```
wind_low       loop_mode=1 begin=0 end=396899 len=18.00s mix_rate=22050 fmt=3
```

`fmt=3` is QOA — Godot's default `compress/mode=2` gives the memory win in §2
for free. The loop also survives anyone deleting `.godot/` and re-importing,
which is a routine thing to do here.

---

## 6. Known limits and what I would do next

**In priority order.**

1. **Footstep surfaces are coarse.** Resolution is water → structure name match
   → band default. Terrain3D carries no per-texture material id here, and
   inventing one for footsteps alone would be a terrain change this lane had no
   business making. So "Band 2 is stone" is the honest available resolution.
   `audio.json`'s `_comment_surfaces` says this in the config rather than hiding
   it. Real fix: a material id on the terrain, which several other systems would
   also want.
2. **Music is placeholder.** See §2. Replace with a composed score; the config's
   priorities and pacing are the useful part and should survive.
3. **`aim_enter` and `capture_success` are still dead cues** (§1). They belong
   to the throw/catch lanes.
4. **The Warden and release cues exist but nothing selects them.**
   `music._wanted_track` returns combat / village / exploration / silence. The
   `warden` and `release` tracks are generated, configured with priorities, and
   unreachable until something tells `WorldAudio` those beats have started. That
   is a hook the stronghold-climax and release-ceremony owners should call; I did
   not want to guess at their state machines.
5. **Music does not truly crossfade** — one player, fade out then fade in. A
   second player is the obvious upgrade and was deliberately skipped: two music
   streams decoding at once on a handheld, for a transition heard a few dozen
   times a run, is not yet a trade worth making.
6. **No compressor on Master.** The obvious next mix step, deliberately absent:
   an unmeasured compressor is how a mix gets quietly worse while looking more
   professional in the editor.
7. **Weather is not audible.** `world_weather.gd` exists and rain has no sound.
   A `rain` layer would drop straight into the existing layer system.
8. **`MEADOWS_EXIT_CRITERION.md` has no audio criteria at all** — zero mentions
   of audio, sound, music or silence. If the chapter's bar is "does it look and
   feel like a finished game", that document should carry a row for whether it
   *sounds* like one. Not added unilaterally; it is a coordinator document.

---

## 7. Files

**New:** `scripts/audio/{audio_manager,world_audio}.gd`,
`data/config/audio.json`, `default_bus_layout.tres`,
`tools/audio/{synth,gen_ambience,gen_sfx,gen_creatures,gen_music,gen_all}.py`,
`tools/audio/make_bus_layout.gd`, `tests/{test_audio,smoke_audio}.gd`,
`assets/audio/` (73 files).

**Modified:** `project.godot` (`[audio]`), `scenes/world/meadows_playground.tscn`
(`WorldAudio` node), `data/config/menu.json` (Audio section),
`scripts/ui/tab_settings.gd` (`_build_audio`), `scripts/ui/key_bindings.gd`
(`audio` preferences section), `scripts/world/water.gd` (`water_level()`
accessor), `scripts/world/harvest_node.gd` (gather + pickup audio),
`scripts/build/build_placer.gd` (placement thud), `scripts/creatures/creature_body.gd`
(voice group), `docs/ASSET_LEDGER.md`.
