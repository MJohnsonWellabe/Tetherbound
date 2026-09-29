# Audio Direction

## Contract and evidence boundary

Audio makes the current four-biome creature expedition readable without turning every moment into noise. The play order is Meadows → Tidewake → Cloudreach → Stormwood (owner, 2026-09-29, RD-10); §4's subsection numbers are historical and do not imply order. The Crossing Hall and data plan for eight biomes (RD-09), but biomes 5–8 get no audio in this pass beyond the sealed arches. It must identify place, danger, creature action, combat timing, progression and co-op state on ROG Ally speakers and ordinary headphones. No essential mechanic may be sound-only; important cues pair with world/HUD shape and, where appropriate, haptics.

Audio is **not absent** at the baseline. The repository contains a generated, original foundation:

- six buses: Master, Music, Ambience, SFX, Creatures and UI;
- eight Meadows ambience layers;
- four creature voice archetypes with idle/alert files (eight files total);
- five placeholder music loops: exploration, village, combat, Warden and release;
- 54 generated SFX files, including surface steps, gathering, combat, capture and progression;
- nine generated UI cues under `assets/ui/audio/`;
- working `audio_manager.gd`, `world_audio.gd`, `audio_cues.gd`, configuration, settings sliders and focused tests.

These assets establish event routing and a prototype mix. They do not provide final composition, species identity, later-chapter ambience or a four-chapter final mix. Every cue family added by the owner design interview of 2026-09-29 (§4.5, §5.1–§5.3, §7.3, §7.4 and the progression additions in §7.2) is **not built (target)**; its ids live in `data/config/audio.json` (the F25 lane owns the move-effect and ultimate ids there). The five music loops are explicitly replacement placeholders. This document defines the owner-produced replacement and integration work without discarding the functioning foundation or assuming a paid composer, vendor or new expenditure.

## 1. Audio goals and hierarchy

At any moment the mix answers, in this order:

1. **What must I react to now?** Attack tell/shape, damage, burst refusal, faint, drowning/lightning warning, downed teammate.
2. **What did my action do?** Hit weight and effectiveness, crit/stagger, ultimate, Tether Command result or refusal, catch state, build/gather/craft result, objective/reward commit.
3. **Where am I?** Chapter, local habitat, shelter/interior, water/height/storm state and Team Tether intrusion.
4. **Who is here?** Active creature, target, nearby companion, named machine or peer.
5. **How should this moment feel?** Exploration, home, escalation, finale, release and regional resolution.

Critical transients win over music and ambience without making the mix louder each time. An enemy tell always outranks the player's own ultimate and move-effect layers: spectacle never masks a tell. A cue is removed or simplified if it competes with a more important cue in the same 250 ms window. Repetition budgets matter: a creature should sound alive, not like a timer; a UI should acknowledge, not chatter.

## 2. Technical format and mix target

Final source masters are **48 kHz / 24-bit WAV**, mono for point sources unless stereo width is part of the asset, stereo for music and broad ambience beds. Loop assets have sample-accurate loop boundaries, at least 20 ms clean handles where crossfading is used, no DC offset and no baked clipping. Godot import compression is chosen per category after an Ally memory/CPU check; the source master remains archived outside the export path with provenance.

Representative ten-minute gameplay captures target **−18 LUFS-I ±2 LU** at Master with **≤−1 dBTP** true peak. This is a working game-mix target, not a music-streaming standard. A critical attack/downed cue should read roughly **6 dB** above the local music/ambience bed at its onset without clipping the master. Final acceptance uses the same calibration for Ally speakers and headphones and checks that quiet environments remain intentionally quiet.

Existing default bus offsets remain the starting mix:

| Bus | Baseline default | Role |
|---|---:|---|
| Master | 0 dB | Overall ceiling and player master control. |
| Music | −8 dB | Score and authored musical states. |
| Ambience | −12 dB | Continuous world beds and broad local emitters. |
| SFX | −4 dB | Combat, traversal, tools, gathering, build and hazards. |
| Creatures | −5 dB | Creature voices separated from generic effects. |
| UI | −6 dB | Menus, objective/progression and non-positional confirmations. |

Player sliders step by the existing 10% increment and mute at zero; stored values are relative to these authored defaults. The six controls remain separate. A future dialogue/voice bus is added only if recorded human VO becomes real scope; text dialogue does not justify an empty slider.

Mix behavior targets:

- ordinary music transition: existing **3.0 s** fade;
- Meadows band ambience transition: existing **6.0 s**; day/night: **12.0 s**;
- dialogue/modal text entry ducks Music by **3 dB** and Ambience by **2 dB** while leaving attack/downed cues intact; this duck is a target, not built baseline;
- interior baseline keeps outside ambience at **0.25** rather than cutting it to silence, but bridge/wood-floor false positives must be replaced by a real interior signal before final acceptance;
- the current one-shot pool of **16** remains until a four-player stress capture proves voice stealing; increase the pool only with Ally CPU/memory evidence;
- ordinary world point-source rolloff begins from authored emitter size and is inaudible beyond the current **40 m** general ceiling unless a landmark/hazard has an explicit long-range contract.

## 3. Music strategy

Music is intermittent. Ambience carries ordinary travel so the campaign does not become wall-to-wall score. **Superseded (owner, 2026-09-29, RD-01):** "eight good hours is an acceptable first clear". The target normal clear is **15–25 h**, built from a 15–30 minute loop that returns to the village and homestead every visit (CODEX_START_HERE §2). Fatigue therefore matters more than before: the settlement/home cue and village ambience are heard dozens of times and need the longest gaps and the lowest density. Retain the current exploration cadence as a starting point: **95–150 s** of exploration music followed by **70–130 s** of real gap. Tune these ranges per biome after an in-game fatigue pass.

The minimum final score is **22 authored music deliverables**:

- **2 global:** title/main-theme statement; four-chapter credits/regional-resolution suite.
- **5 per chapter:** exploration, settlement/home, ordinary combat, finale/boss, release/aftermath.

Stingers are not loops and do not count toward the 22: a **Master duel** intro and win stinger per biome (five Masters, owner, 2026-09-29, RD-06; the duel itself uses that biome's ordinary combat loop), a breakthrough/feast stinger and an evolution stinger (§7.2), and the Home Key homecoming lead-in (§7.3). The village road, homestead and Crossing Hall use the Meadows settlement/home cue at reduced density; the Hall itself is ambience-led (§4.5).

| Cue class | Minimum authored length | Loop/state requirement |
|---|---:|---|
| Title/main theme | 90–150 s | Clean loop or held menu tail; introduces the five-companion motif. |
| Chapter exploration | 150–240 s | Seamless loop, written to tolerate intermittent entry and long silence. Optional stems may expose threat/traversal without a second composition. |
| Settlement/home | 90–180 s | Seamless loop; lower density and smaller range than exploration. |
| Ordinary combat | 90–150 s | Seamless loop with a readable downbeat but no fake hit timing. May share a Team Tether motif within the chapter, not one generic loop across all four. |
| Finale/boss | 150–240 s | Phase-safe loop points; chapter-specific climax. Music never masks the mechanical tell. |
| Release/aftermath | 90–180 s | Non-looping opening plus loopable tail, or a single authored non-loop used once. Resolves the chapter rather than teasing the next. Tidewake's now closes only its own chapter (RD-22). |
| Credits | 180–300 s | Non-loop; follows the Stormwood finale and the Home Key homecoming (owner, 2026-09-29, RD-22); recalls all four chapter colours and resolves at Grandpa's home. No musical sequel sting. The fifth arch's later *stir* is a diegetic world sound (§4.5), not part of the credits and not a tease. |

The score shares a small melodic identity for the trainer/five companions and a restrained Team Tether interval/timbre, then changes instrumentation by chapter:

- **Meadows:** warm acoustic/plucked body, light wood/percussion and open melodic space. Village is safe without becoming nursery music; Team Tether's Hall (not the Crossing Hall) introduces the Tether colour before the Warden cue.
- **Cloudreach:** airy plucks/bowed tones, breath and light metallic resonance; strong silence and wide register suggest height. Avoid constant piercing wind-chime energy on handheld speakers.
- **Stormwood:** low wood resonance, mossy sustained colour, copper/glass percussion and controlled electrical pulses. Surge intensity comes primarily from ambience/stems, not restarting a track every phase.
- **Tidewake:** fluid pulse, warm dock/settlement material and broad suspended harmony; no generic pirate shorthand. Veilfall/finale adds white-noise/waterfall mass without masking speech/tells.

The existing five generated loops remain implementation placeholders mapped to these states until final compositions are accepted. They are never advertised as final score and are not deleted before replacements prove looping, state priority and memory behavior.

## 4. Four chapter soundscapes

### 4.1 Meadows

The existing eight-layer system is the built foundation: low/high wind, meadow birds, night insects, river water, quarry stone, Ironwood canopy and Tether drone. "Hall" in this subsection means Team Tether's stronghold where the Warden fights, not the village's Crossing Hall (§4.5). Preserve its five-band identities and current 6/12 s fades while replacing synthetic timbre only after an A/B implementation test.

- Lower Meadows: open, gentle birds by day; insects at night; no threat drone.
- Stone & Root: air thins, hollow stone and enclosed reflections replace busyness.
- River Lock: water is a navigational landmark audible before visible, with local rather than map-wide volume.
- Upper/Ironwood: stronger canopy creak and high wind; giant-tree scale comes from low resonances and distance.
- Hall approach: wind plus machinery; Tether drone is audible before the structure without becoming a global hum.

Required additions for final Meadows mix: localized village life at restrained density; tournament crowd/round transitions; Warrens interior/guardian grammar; campfire/tent shelter treatment; relay shutdown/healed-land before/after; Hall machinery and release aftermath.

### 4.2 Cloudreach

Cloudreach has no final chapter bed at baseline. Build a layered system rather than one wind loop:

- low-altitude crosswind, high-altitude thin wind and cliff-slot whistle;
- rope/wood bridge strain, mooring hawser and loose banner motion as local emitters;
- sparse highland birds/creatures, settlement activity and shrine resonance;
- authored current updraft cue with a clear centre/edge and fade;
- launch, valid climb, current exit, unsafe landing and restored-wind state;
- summit extraction engine and three relay exposures with distinct spatial positions;
- post-finale calmer routes and reconnected settlement life.

Wind cannot be the loudest layer everywhere. A player should identify lower cliffs, a rope crossing, an authored current and summit machinery without looking at the map.

### 4.3 Stormwood

Stormwood audio is mechanically load-bearing. The Surge must be nameable from sound and light alone:

| Phase | Audio contract |
|---|---|
| Calm, 240 s baseline | Rain/drip and low moss/forest life; distant thunder with long spacing; arches idle softly. |
| Building, 90 s | Copper-vine ticks, increasing canopy motion and rising electrical bed; birds/insects fall away; no strike yet. |
| Break, 120 s | Each strike uses a spatial **1.2 s** warning whose direction and ground location are readable, followed by strike/body/decay layers. Break rhythm follows authored **4–8 s** strike spacing. |
| Fading, 60 s | Strike density stops; steam, glass and low rolling thunder decay; charged nodes/afterglow remain audible locally. |

Rod safe areas reduce warning density and electrical pressure rather than muting the whole forest. Stormglass arches need idle, relight, paired-ready, walk-through and blocked-in-combat cues. The Dynamo has distinct bank, grounded-plate, overload, conduit-success and reset states. The Stormheart release removes the oppressive rod-line bed and opens ordinary forest/sky sound; it does not leave the same loop under brighter lighting.

### 4.4 Tidewake

Tidewake needs location and traversal identity without an underwater/diving mix:

- sheltered shore, marsh/reed, open-water surface, rock terrace, dock/settlement, sluice/pump, current and Veilfall waterfall layers;
- human swim stroke, exhaustion warning and safe-ground exit;
- each compatible mount's surface movement, effort and exhaustion without replacing its creature voice identity;
- currents with directional entry, sustained flow and exit cues; hazardous current remains visible and audible;
- occupied pump/Tether machinery and restored-current/civilian dock variants;
- Aquaryn's shore/water phase distinction, Tidecoil's optional apex identity, Nerissa's interior control phases and the Abyssal Guardian release;
- Veilfall heard at long range but dynamically bounded so it does not flatten combat/dialogue near the falls.

**Superseded in part (owner, 2026-09-29, RD-32):** the starter Ripplet dives after its L30 breakthrough (TRAINING §9). Diving gets a minimal state, not a system: submerge and surface transitions, a low-pass filter and level drop on the Ambience and SFX buses while submerged (starting 900 Hz cutoff, −6 dB, `audio.json`), a muffled underwater bed for Tidewake, Ripplet's underwater movement layer and cache/node pickups heard through the filter. Critical tells and UI stay unfiltered. There is still no oxygen, breath meter, boat, fishing or universal wetness audio.

### 4.5 Village road, homestead and Crossing Hall (target, F17, F18, F31)

The village is one straight road (owner, 2026-09-29, RD-29) heard many times per session, so it stays restrained:

- **Road and houses:** localized village life at low density, by house (Mira's shop, Tam's workshop, the inn, Halda's board); day/night variants; no looping crowd walla.
- **Homestead:** the farm yard bed plus local station emitters only while a station is working (§7.3); nothing hums while idle, because nothing produces while the player is away.
- **Crossing Hall:** a large stone nave with long reverb and low air; the home arch has a warm low tone; each live arch idles with its biome's colour (tide wash, high wind, copper tick) only once unlocked; locked live arches are near-silent; the four sealed arches are silent. The Shrine Room is quieter than the nave; each hung relic adds one soft sustained tone at its pedestal.
- **The fifth arch stir (RD-22):** a one-time diegetic event, low hum rising and decaying, stone grit and dust, then silence; played once per character. It uses no melodic motif from the score and no music-bus sting.

## 5. Combat and action cue grammar

Audio follows authoritative resolved events. It never awards damage, capture, progression or rewards. Local input acknowledgement may play immediately, but the hit/result layer waits for the host result in co-op.

| Event family | Minimum cue requirement |
|---|---|
| Quick / charged / utility / ultimate | Distinct commitment cue by slot; charged is not a stretched quick. Each utility move has a readable start and resolved effect. **Superseded (owner, 2026-09-29, RD-11):** the five Y skill families; they are now utility moves (COMBAT §6). The body of each move sounds like its effect archetype (§5.1). |
| Enemy tell | Standard interruptible tell; protected-heavy tell with an added white-ring timbre; enough onset definition to locate within **100 ms** of the visual telegraph start. |
| Burst | Start/air/landing or stop as appropriate; dry Wind refusal is short and quiet; no dodge-invulnerability “whoosh” implication. |
| Hit | Existing weak/neutral/super-effective families retain at least **3 variants** each; player-creature damage is a separate layer. Critical stagger punish has a distinct transient. Target layering is in §5.2. |
| Miss / collision | At least **3** miss variants; world collision never plays a hit-confirm. |
| Poise/stagger | Break onset, punish-ready window and protected resistance are distinguishable but restrained. No permanent stun loop. |
| Switch/faint/flee | Withdraw, deploy, faint and legal wild flee; trainer-flee refusal uses UI feedback without a victory cadence. |
| Catch | Throw has at least **2** variants; shakes rise by current **1.06** pitch step; success, break/fail and illegal-target refusal are distinct. Success is not double-played by world and UI systems. |
| Hazard | Storm strike, drowning/exhaustion and current danger each have pre-danger, active and resolution layers paired with visuals. |

Keep baseline move timings in `COMBAT.md` (quick and charged keep their timings under the new X/Y bindings); audio conforms to commitment/hit/recovery instead of changing mechanics to fit a clip. A move's impact layer plays on the effect's arrival (COMBAT §13.2), never at the button press, so the sound, number and flash agree. Hitstop pauses only affected presentation timing. A reduced-motion setting may reduce camera impulse and visual flash, but it does not move the authoritative cue/result.

The wind-up ring remains magenta and the HUD currently uses amber wording. Audio uses one warning family for the same semantic event so it does not deepen that visual inconsistency; the visual integration must still be fixed. Each role's enemy patterns (COMBAT §12.2) keep that one warning family and vary only a small role layer (a lane whoosh for CHARGER, a ground rumble for WALL rings, a rising whistle for DIVER leaps, a volley tick for CURRENT) so the pattern is readable by ear without new warning semantics.

### 5.1 Move effects and ultimates (target, F25, F35; owner, 2026-09-29, RD-23, RD-27)

Each of the ~24 effect archetypes (COMBAT §13.1) has its own cue set: **launch**, **travel** (only where travel lasts long enough to hear, e.g. fireball, tornado, boulder) and **impact**. Parameters that change the visual change the sound: pebble toss is several small ticks, rock throw one heavy thud; mastery tiers add a layer rather than raising level. Non-damaging archetypes (heal pulse, buff aura, debuff hex, guard flash, catch/tether beam) have soft cues well below hit layers. Guard flash never sounds like a block.

Budget: one archetype firing uses at most **2** simultaneous one-shot voices (a volley is one layered sample, not one voice per pebble). Impacts pull from the existing 16-voice pool under the priority order in §8.

Ultimates: each of the **16–20 shared type × role ultimates** takes its type's archetype colour plus a role layer; each of the **twelve unique ultimates** (Terrapup, Ripplet, Galewisp, Veridian, Abyssal Guardian, Solmane, the Stormwood legendary, Tuskroot, Ashtusk, Cannonback, Stormcapra, the storm bear) gets a bespoke 2–3 s cue that shares a motif with that creature's voice recipe (§6). Meter full is a short, quiet readiness cue; arming (RB) a click; firing a build that lands its peak on the ultimate's arrival. During an ultimate, Music ducks by 3 dB (starting value) for its presentation; tells and teammate-down cues are never ducked. Each ultimate grows at breakthroughs with one added layer, not more loudness.

### 5.2 Hit impact layers (target, F21; owner, 2026-09-29, RD-13)

A landed hit is built from layers chosen by resolved facts, played once from the host result:

| Layer | Plays when | Rule |
|---|---|---|
| Body | every hit | weight-scaled: light, medium, heavy, ultimate (COMBAT §11) |
| Effectiveness | super-effective or resisted | existing strong/weak families; neutral adds nothing |
| Crit | stagger-punish crit | a sharp bright transient above the body |
| Stagger | poise break | break onset, then a restrained punish-window cue; protected resistance keeps its distinct timbre |
| Receiver | the local player's creature is hit | the existing separate player-damage layer |

Hitstop freezes presentation only (COMBAT §4): the impact plays at hitstop start, and nothing retriggers at its end. Rumble pairs with body/crit/stagger on the local player's controller (UX §18) and never replaces sound.

### 5.3 Tether Commands (target, F24; owner, 2026-09-29, RD-12)

The command meter fills silently; reaching each command's cost plays nothing, and only a full meter gives one very quiet tick. Each command has one short, trainer-voiced (non-speech) gesture cue plus a result: Rally a bright lift on the player's creature; Item throw a toss and the item's use sound; Tag-switch a two-note swap into the joint strike's impact; Tether Snare a line cast and a taut hold loop for its duration. A refused command uses the ordinary UI error cue, rate-limited. None of these sound like the trainer striking anything, because the trainer never deals damage.


## 6. Creature voice strategy

The current four archetypes (chirp, growl, rumble, trill), pitch offsets, **9–22 s** idle interval, **30 m** idle distance, **2.5 s** alert cooldown and ±5% pitch jitter are acceptable prototype infrastructure. Four pitched files are not final identity for a 57-species base roster plus realm adapters.

Every final species needs an identity recipe with four event roles:

1. idle/social;
2. alert/engage;
3. action/exertion;
4. hurt/faint/recovery.

Recipes may share recorded/synth source layers, but each species needs at least one unique motif, formant, rhythm or material layer so adjacent roster choices do not sound like the same file at another pitch. A blind listener should distinguish the active member from its common same-chapter alternatives in a controlled set. Size influences pitch and body resonance without making every large creature a slowed rumble.

Named alphas, chapter guardians and the four offered legendaries (Veridian, Abyssal Guardian, Solmane and the Stormwood legendary) require dedicated additions for their encounter identity and release/aftermath. A legendary's release voice is not its faint sound. Companion contextual reactions use the same identity recipe, obey cooldowns and yield to combat/dialogue. Ordinary reactions are reusable and low-noise; high bond unlocks stronger/richer variants without increasing the reaction frequency or bypassing the same cooldown.

The new evolved forms (Tuskroot and Ashtusk at L20, Cannonback, Stormcapra and the new Stormwood storm bear; owner, 2026-09-29, RD-28) each need a recipe that keeps a recognisable motif of the pre-evolution creature, so the player hears their companion grow rather than a stranger. The storm bear is a new species and needs a full four-role recipe. Masters' aces use their species recipes; the Master is a person and uses text dialogue.

No creature call plays simply because a model is loaded off-screen. In co-op, voice events are realm- and distance-scoped and emitted once per authoritative event.

## 7. World, tool and UI cue requirements

### 7.1 Movement and materials

The baseline surface sets are grass 4 variants, stone 4, wood 3 and water 3; stride is **1.85 m**, sprint stride scale **0.78**, minimum interval **0.18 s**, pitch jitter ±7%, landing +4 dB. Final chapter coverage adds at least three variants each for sand/salt shore, wet rock/mud and Stormglass/metal where those materials recur. Surface resolution must come from real material/contact state, not a whole-band guess. Animation-event foot plants are preferred when the final rig supports them; distance timing remains fallback.

Mount, swim and fly movement use separate cadence/body layers and do not trigger human ground footsteps. Teleport/debug relocation never emits a machine-gun stride burst.

### 7.2 Gathering, building and objects

Retain at least three variations for chop, mine and gather, plus two placement thuds. Add repair, dismantle/refund, invalid placement, snap-step, crafting start/complete, bed assign/rest complete, saddle fit and relic place/select. A resource's audio follows the actual tool/material, not item rarity alone.

The current UI set remains the minimum: focus, accept, cancel, tab, error, aim-enter, build-snap, build-place and capture-success. Add distinct but related cues for objective update/completion, map marker, teammate/downed, host-pending/committed transaction and accessibility test. UI focus is rate-limited; analogue navigation cannot fire every frame.

Progression requires separate level, bond-node, skill-level, evolution, rare pickup/relic and chapter-resolution moments. Ordinary XP/bond ticks remain silent or very restrained. Reusing combat-win/craft-done as final level/bond cues is placeholder behavior.

**Target progression additions (owner, 2026-09-29, RD-03, RD-06, RD-11, RD-28, RD-30, RD-31):**

| Event | Cue rule |
|---|---|
| Essence gain in the field | silent, or one very soft tick per pickup, rate-limited |
| Essence spend at the Altar | a short resonant pour per press; one press, one cue |
| Level up from a spend | the existing level cue; repeated spends in a row reuse it at reduced level, never stacking |
| Cap reached ("breakthrough needed") | a low, closed two-note figure once per creature per cap |
| Master duel | intro stinger at admission; win stinger at the chest; a loss uses the ordinary defeat cue (§3) |
| Feast recipe learned | the major-recipe moment |
| Feast cooked | Kitchen completion (§7.4) plus a warm rising accent |
| Breakthrough (feast fed, cap lifted) | a distinct rising stinger, larger than level up, smaller than evolution |
| Evolution | the evolution moment, followed by the evolved form's first call |
| Evolve-or-stay: stay | a quiet confirm; staying is not a failure and never sounds like one |
| Mastery rank up | a short bright tick on the move's archetype colour |
| Trait Seed distilled / taught | a soft seed "pop" / a settling tone |
| Research task paid | a soft journal stroke; biome 100% plays a title moment |
| Bounty complete (progress reached) | a small feed cue |
| Bounty claimed at the board | a coin-and-paper reward cue, once per bounty instance |

### 7.3 Home Key, portals, waystones and shrine (target, F17, F18, F20, F31; owner, 2026-09-29, RD-18..RD-22)

| Event | Cue rule |
|---|---|
| Home Key raise | ~2 s build synchronized to the raise animation: a warm shimmer rising to a bloom at the fade. Spatial for nearby peers, attenuated. |
| Home Key cancel / refusal | the build stops with a soft falling tail / the ordinary UI error cue, rate-limited |
| Home Key arrival | the bloom resolves into the Hall's nave reverb and the home arch tone |
| Homecoming (Stormwood finale → Home Key) | the same raise, with the homecoming music lead-in beginning at arrival |
| Portal key used / arch unlocked | a heavy lock turn, then the arch igniting into its biome's idle colour; a moment-level cue |
| Enter portal | a travel whoosh into the destination's ambience; no reward cue |
| Locked arch refusal | a dull stone knock plus the UI line; no error buzzer |
| Fifth arch stir | §4.5; once per character; a later press is silent apart from a faint hum |
| Waystone activated | a spatial chime and stone hum at the waystone, audible within its local radius, once per activation; "return point" updates are silent apart from the feed |
| Relic hung | relic set on stone, then a resonant bloom; the pedestal keeps its soft sustained tone |
| Relic power selected | a short confirm on the relic's tone |

### 7.4 Homestead stations (target, F31, F32, F34; owner, 2026-09-29, RD-15, RD-16)

Each station has start, working and complete cues. Working loops play only while the player is interacting (nothing runs unattended) and stop cleanly on leaving.

| Station | Working | Complete | Attachment layer |
|---|---|---|---|
| Workbench | saw, plane, hammer taps | a small hammer ring | none (no attachments) |
| Forge | bellows, fire roar, anvil strikes | quench hiss and ingot clink | Bellows (air), Tide quench tank (deeper water hiss), Wind furnace (high draught), Storm coil (electric crackle) |
| Kitchen | sizzle, pot bubble, knife | a lid clink and warm chime | Spice rack, Smoker, Cold cellar, Storm oven each add one texture |
| Altar | resonant tone and flowing essence | a settling chord | Meadow, Tide, Sky and Storm lenses shift the chord's colour |
| Den | straw rustle, brush strokes, contented creature sounds from the species recipe | shed-drop pickup | Straw bedding, Hot spring, Cliff perches, Grounded bedding change the bed texture |
| Farm plots | till, plant, water | harvest pluck per plot | Greenhouse adds glass and damp air |
| Chests | open/close by material | — | — |
| Forward camp | portable cookpot and field workbench use lighter versions of the Kitchen and Workbench sets | same | — |

Station ambience is local to the homestead and never plays in another realm.

## 8. Multiplayer and authority

Current remote combat presentation routes several peer events through non-positional bus playback. Final target uses authoritative event position and realm for remote hit, faint, catch, victory, creature call, hazard, ultimate, Tether Command, Home Key raise and major world state.

**Voice priority under the 16-voice pool (target):** enemy tells and teammate-down → the local player's hit results → the local player's move launches, ultimates and commands → peers' combat → station and world one-shots → ambience details. Personal receipts (keys, relics, recipes, bounty claims, research titles, credits) are local UI cues for the character who earned them; a peer's receipt never plays on another player's UI bus (owner, 2026-09-29, RD-21). UI cues remain local/non-positional. A client never plays both predicted and confirmed result layers for one event.

Required mix behavior:

- local attack tells and the local creature remain foreground;
- nearby peer combat is spatial and attenuated, not mixed like the local fight;
- another realm is silent except explicit UI notifications;
- four simultaneous encounters do not steal local critical cues or exceed master peak;
- teammate-down warning and tap-start revive progress are identifiable but paired with HUD/world icons;
- one shared boss phase transition plays once per peer, synchronized to authoritative state;
- reconnect reconstructs continuous ambience/music state without replaying one-shot rewards or release stingers.

Built-in voice chat, public matchmaking audio and platform party-chat processing are outside this plan.

## 9. Accessibility and captions

All critical mechanical cues have visual equivalents. Optional closed captions describe non-speech events that carry navigation or danger, with a direction wedge when the sound is spatial: `[lightning building, left]`, `[teammate down, behind]`, `[strong current ahead]`. Essential captions add `[waystone nearby]` for an unactivated waystone within its radius and `[the fifth arch stirs]`; Full adds station working states and ultimate names. Captions do not transcribe every footstep or ambient bird by default. Players may select Off / Essential / Full environmental captions.

Dialogue text is complete without recorded speech. If partial VO is later added, every spoken line is subtitled and partial coverage is labeled consistently by role rather than randomly voiced scenes.

Accessibility settings include six bus volumes, subtitle/caption size and background, essential-caption mode, reduced high-frequency warning option and mono downmix. Combat tells remain distinguishable in mono and on Ally speakers. Haptics reinforce but never replace sound/visual cues; a no-vibration setting remains fully playable.

## 10. Asset and provenance strategy

Current generated audio provenance is recorded in `archive/docs/specs-2026-09-19/ASSET_LEDGER.md`; ART_DIRECTION carries the live asset dispositions. Every retained, processed, recorded or generated source receives provenance before commit: creator/source, acquisition date, exact licence or ownership basis, allowed redistribution, modification and attribution. File presence does not establish those rights. Do not train on or repackage assets whose terms prohibit it. Raw source sessions stay out of exports; credited names survive even where a licence does not mandate credit.

Acquisition priority is:

1. keep, repair and remix a current cue when it communicates the right event and its provenance permits the use;
2. author the score, creature and signature chapter assets with the existing generated/installed sources and available tools, recording prompts, source inputs and the processing chain where applicable;
3. record original material where useful, without assuming paid performers, libraries, vendors or new expenditure;
4. avoid replacing a functioning event system with bespoke middleware before the mix proves it necessary.

The authoring pass uses the theme/state matrix, gameplay captures without placeholder score, loop/state requirements and practical stem limits. The 22-deliverable bar remains; the production plan changes, not the required chapter identity, transition quality or fatigue result. Acceptance is based on in-game transitions and fatigue, not a standalone music player render.

## 11. Current implementation matrix

| Feature | Baseline | Required work |
|---|---|---|
| Buses/settings/one-shot routing | **Built.** Six buses, persisted sliders, 16-player pool and event API. | Final calibration, dialogue duck target, four-player voice-steal and device proof. |
| Meadows ambience | **Built prototype.** Eight layers, five bands, day/night/interior fades. | Replace coarse surface/interior inference; add location/finale/aftermath; final timbre/mix. |
| Cloudreach/Stormwood/Tidewake ambience | **Not a complete integrated chapter system.** Some world/hazard sources may emit local sound, but `audio.json` is Meadows-band centric. | Implement the chapter layers and state graphs in §4, realm scoped. |
| Music | **Five generated placeholder loops built.** State priority and intermittent exploration work. | Deliver/integrate the 22-cue minimum, chapter identities, boss/release/credits and final transitions. |
| Combat/catch SFX | **Substantial generated foundation built.** Hits, miss, damage, start/win, Orb and ability hooks exist. | Utility-move cues (Y-skill families superseded), protected tells, stagger/burst/hazard grammar, spatial remote events and final assets. |
| Move effects and ultimates | **Not built.** Projectile/melee hit cues only. | ~24 archetype cue sets, 16–20 shared and 12 unique ultimates (§5.1); F25#0, F35. |
| Impact layers and commands | **Not built.** Weak/neutral/strong families exist. | Weight, crit and stagger layers (§5.2); Tether Command cues (§5.3); F21#1, F24. |
| Hub, travel and homestead | **Not built.** | Village road, Crossing Hall, Home Key, portals, waystones, shrine and station cues (§4.5, §7.3, §7.4); F17, F18, F31. |
| New progression moments | **Not built.** Level and bond files exist. | Essence, breakthrough, feast, evolution, mastery, seed, research, Master and bounty cues (§7.2). |
| Ripplet dive | **Not built.** | Minimal submerged state (§4.4); F37. |
| Creature voices | **Prototype.** Four archetypes, idle/alert and per-species pitch for a subset. | Four-role species recipes, later-chapter coverage and unique named/legendary layers. |
| UI/progression | **Nine UI cues plus generated level/bond files.** | Rebound/accessibility flows, distinct final progression set and no duplicate success cues. |
| Multiplayer audio | **Partial.** Remote events are subscribed but several play non-positionally. | Authoritative realm/position routing, concurrency priorities, reconnect/state reconstruction. |
| Accessibility | **Partial.** Independent volume sliders exist. | Essential/full captions, mono validation, high-frequency reduction and subtitle/caption controls. |

## 12. Acceptance

Audio acceptance uses the shipping build and reports exact commit/package:

1. **Routing:** every required event fires once from the correct owner; no stale audio survives realm teardown or menu/state exit.
2. **Mix:** ten-minute exploration and combat captures meet the working loudness/peak target; no bus clips; critical cues remain readable at default and 50% master volume.
3. **Chapter identity:** blinded listeners correctly distinguish all four representative chapter beds and Stormwood's four Surge phases above chance, then name the evidence they heard.
4. **Mechanic readability:** players react to standard/protected tells, Wind refusal, drowning/lightning and teammate down with HUD temporarily obscured, while the paired visual test separately ensures sound is not required.
5. **Fatigue:** a 3–4 hour chapter session has no audible loop seam, UI chatter, creature-call repetition or continuous exploration-score fatigue called out by representative players. Because the redesign loop returns home every 15–30 minutes (RD-01), the session includes at least six homestead visits and the village/home material must not be called out as repetitive.
6. **Species identity:** controlled comparisons distinguish an active creature from its common chapter alternatives; pitch-only failures return to asset work.
7. **Co-op:** two- and four-player same-/split-realm tests prove position, priority, single playback, down/revive and reconnect behavior, including simultaneous ultimates and commands from four players without a tell being lost, and personal receipts playing only for their owner.
8. **Hardware:** on the currently unproven **1920×1080, 15 W ROG Ally** target, the canonical 30-minute representative run must retain the 30 fps floor (P95≤33.3 ms, P99≤50 ms) with no audio dropout while combat/weather/co-op run together. A separate three-hour session checks memory growth, streaming/transitions and audio-provider leaks. Ally-speaker and ordinary-headphone passes also verify low-volume cues and mono compatibility. The 3–4 hour fatigue listen above is a content/listening judgment, not the platform telemetry run.

Automated cue counts and dummy-driver tests prove wiring, not sound quality. Final mix, score and creature identity require human listening.

## 13. Out of scope

- Full human dialogue VO for minimum release.
- Built-in voice chat, public matchmaking or platform-party audio processing.
- Dynamic music middleware replacement before the current state system proves insufficient.
- Oxygen or breath systems, boats, fishing or a fifth-chapter music suite. **Superseded (owner, 2026-09-29, RD-32):** the exclusion of diving; Ripplet's dive has the minimal submerged state in §4.4.
- Any music-bus sting or motif on the fifth arch; the stir is a world sound only (RD-22).
- Sounds that imply the trainer strikes, blocks or deals damage (RD-12).
- Making a warning sound-only, or using haptics as the only signal.
- Treating the five generated music loops or four pitched creature archetypes as final four-chapter assets.
- Reopening an accepted world/water visual ceiling by adding unsupported renderer effects for audio reactivity.

## 14. Recovery dispositions

- **Phase 1 finding §6 (audio/accessibility):** correct “audio absent” to generated foundation; retain the missing later-chapter integration, spatial remote-cue and final-mix work.
- **Asset Ledger audio row:** preserve deterministic/original provenance, generic bird limitation and five replacement loops. No third-party licence is inferred from file presence.
- **9/7 playable-first directive:** audio/VFX polish was deferred for that milestone, not deleted from product acceptance.
- **B11:** Stormwood's Surge must be nameable through sound and light; exact phase/strike timings above remain synchronized with WORLD/SYSTEMS.
- **B04/B17/B24:** Cloudreach height/wind, Tidewake islands/currents/Veilfall and every chapter aftermath receive distinct audio state rather than a Meadows loop reuse.
- **Owner redesign (2026-09-29):** biome order, 15–25 h clear, homestead loop, Home Key and portals, Masters and feasts, move archetypes, ultimates, impact feedback and Tether Commands add the target cue families in §4.5, §5.1–§5.3 and §7.2–§7.4; the credits move after Stormwood and the fifth arch stir replaces "no fifth-chapter sting" as a world sound only (RD-22).
- **DR21/D80 and DR24/D94:** resolved combat events drive per-instance presentation; tell and capture audio align with the established magenta/gold visual semantics.
- **MP authority recovery:** host result/position controls remote result cues, one event plays once, realm teardown clears providers and reconnect does not replay rewards.
- **Owner visual/performance recovery:** final listening remains a human/device bar. Structural buses and generated files are evidence of implementation, not a final four-chapter sound identity.
