# F26 computer route candidate

`tools/capture_lookdev_route.gd` extends the existing production-scene survey
and uses the existing physical InputMap navigator. Route poses, warmup, image
size, seed and budgets live in `data/config/lookdev_routes.json`. The route
walks through live collision after one declared initial setup teleport.

`tools/run_lookdev_routes.py` runs only the requested combinations, serially,
with an isolated device/save directory for each renderer process. Medium
and High now share one Forward+ scene mount, with a declared initial pose
reset and fresh preset application/warmup for each route. Each writes its
own raw frames and screenshots. The world ecology and resource caches stay
warm across those two cases; this is disclosed in both receipts and summary,
and is not an independent cold-start benchmark. Low uses its own process.
The tool preserves native logs,
actual renderer/adapter, source commit, route configuration hash, ordinary
production-camera metadata, environment at start/end, screenshots and every
raw wall/process/physics frame sample. Screenshot I/O brackets the timed
interval. Wall-frame percentiles are derived from raw samples; they are not
GPU-only measurements. A first failure stops the batch without a retry.

Start with one route after the coordinator grants the Godot writer slot:

```powershell
python tools/run_lookdev_routes.py --godot <Godot-console-executable> --biome water --preset Low --output <new-evidence-directory>
```

Omit `--biome` and `--preset` for the full four-biome, three-preset computer
matrix only once the initial setup works. Each native capture uses 1920×1080;
Low requires Compatibility and Medium/High require Forward+. A clean source
checkout is mandatory. Existing evidence directories are never overwritten.

Status: **source candidate only; native capture and independent source review
are pending.** This helper does not satisfy F26#4 by itself. The current
Meadows route precedes the F17 farmhouse/street/Hall layout and must be
replaced before integrated acceptance. The Hall is not yet rendered. Fresh
production-scene setup is not an earned campaign run. Combat, owner Ally
performance, code-blind visual matrices, High/Medium look approval, every
material path and the F49 integrated run need their own evidence.

Non-Stormwood routes initialize day/clear using the existing survey helper,
then restore normal live clock/weather callbacks for the timed route. This
includes production clock blending, camera quality updates and weather work
in the measured frames. Stormwood keeps its Surge clock and weather live;
the receipt records the observed phase at both ends. A fight or dialogue that
holds locomotion consumes the declared route budget and can fail the route;
the tool never dismisses it, grants progress or teleports past it. Samples
include any such hold and possible stationary padding to the minimum frame
count; they are not a claim of continuous-motion-only timing.

Independent VFX source review of `d9cdb9788` identified inherited callback
suppression as a timing blocker before any native capture. This candidate
restores both callback sets and unfreezes the clock before measurement.
Malformed sample structures now produce a preserved failed matrix summary.
Independent VFX source re-check passed the route timing repair at
`1186526b921f7746dbaf514f0b7f7ac0649640f7`. The runner now also rejects
non-finite samples and distinguishes requested-case completion from all
twelve route cases. This small summary-only change has not rerun the native
route; its prior raw evidence remains pinned to the executed source.

Visual matrix adapters `capture_lookdev_catalogue.gd` and
`capture_lookdev_stormwood.gd` select actual device presets before mounting
the existing production-camera capture paths. Stormwood uses the existing
four-phase and aftermath fixture, always-purple grade, ordinary HUD and
declared phase/health staging. These adapters are pending native validation;
their stills are separate from performance samples and earned player proof.
The independent review identified zero-frame completion, overwriting,
receipt-write failure and early null-world failure paths. The current delta
requires fresh explicit output paths, all five Stormwood stands and all
phases, and checked receipt writes. Failure completion never dereferences a
missing world. These adapter guards remain pending strict re-check/native
validation and do not change the executed route.

Independent VFX source re-check passed the adapter guards at `358bc68b5`.
It also verified the retained native Water/Low receipt: 201 finite positive
frames, two reached waypoints, clean native exit and 1920×1080 PNG headers.
Images have not been code-blind judged. Medium/High Water now has independent
receipt verification and a native passing run at `840ede55d`, retained in
`routes/water-forward-r1`; together with Low, this is three of twelve cases.
It does not replay unchanged Water evidence or certify the other biomes.

Preflight of the remaining routes found the shared 3600-physics-frame leg
deadline shorter than ordinary 5 m/s walking for the longest Cloudreach and
Stormwood legs. Their data now declares 7200/9000 frames respectively, while
the route wall deadline remains 900 seconds. The route reader uses this
per-route override; Water/Meadows retain the original deadline. No movement
speed, collision behavior, route distance or completion assertion changed.
This prevents a known harness-only timeout before the first long-route run;
it is not evidence that those routes pass.
