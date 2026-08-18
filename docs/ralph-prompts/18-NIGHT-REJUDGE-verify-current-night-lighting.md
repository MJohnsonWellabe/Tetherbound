# NIGHT-REJUDGE — Verify current night lighting before changing anything

## Goal
Re-judge the current `main` night presentation after the recent NIGHT-LIGHT and torch changes. This is a verification task first, not a new lighting redesign.

The only question this item must answer is:

> **On current main, with the torch genuinely equipped when testing it, does nighttime remain clearly night while still being readable enough to play?**

If yes, close NIGHT-REJUDGE with evidence. If no, identify the specific remaining defect and route it to the correct existing owner (`RG21` for day/night cycle/transition/true-night timing, `RG22` for torch behavior/lighting) rather than creating a third competing night system.

## Owner decisions already locked

- Full day/night cycle target is 10 real minutes.
- True dark night target is about 2 real minutes.
- Dawn/dusk should be gradual transitions rather than hard preset jumps; RG21 owns that implementation.
- The owner has already said the updated torch pictures looked good. Do **not** retune torch brightness merely because older playtest feedback said it was dark.
- The torch must be genuinely equipped/held when judging torch lighting. An unequipped torch being dark is correct behavior.
- Night should be playable and readable, but it must still unmistakably read as night — not simply daytime with lower exposure.
- Do not brighten the world globally until it loses its cool/night mood.

## Why this is verify-first

The original night complaint came from an older build. Since then, NIGHT-LIGHT has already run multiple measured/visual passes and current `art.json` records three rounds of tuning.

Current history in `data/config/art.json` shows:

- original night frames were effectively flat black;
- simple 2–3x lighting increases did not escape ACES' dark toe;
- later rounds deliberately combined ambient, sun/moon, exposure, cooler colour, and desaturation;
- one intermediate pass became too bright and read as "day with the lights off";
- the current pass added explicit colour grading (`adjustment_saturation`, `adjustment_contrast`) to preserve a blue/cool night identity while retaining terrain readability.

Do not discard that work and restart from arbitrary numbers.

## Existing verification tool

Use `tools/capture_night_light.gd` as the baseline automated capture path.

It already provides:

1. same-viewpoint DAY and NIGHT captures at the Old Quarry overlook;
2. same-viewpoint DAY and NIGHT captures at the ranger camp close view;
3. a dedicated torch-at-night frame with the player visible;
4. explicit inventory grant + `equipped_tool = "torch"` before checking/toggling torch state;
5. printed confirmation of whether the torch reports `is_on` and what tool is equipped.

Do not judge the torch from `survey_band2.gd` night shots, because that survey deliberately parks the player far off camera and says nothing about equipped torch behavior.

## Relevant current files

Inspect current `main` before judging:

- `tools/capture_night_light.gd`
- `data/config/art.json`
- `scripts/world/world_look.gd`
- `scripts/world/day_cycle.gd`
- `scripts/player/torch.gd`
- `scripts/player/tool_hold.gd`
- `data/config/movement.json` torch tuning
- RG21 prompt: `docs/ralph-prompts/07-RG21-continuous-day-night-short-night.md`
- RG22 prompt: `docs/ralph-prompts/08-RG22-verify-current-torch-lighting.md`
- current `ralph/BACKLOG.md` notes for NIGHT-LIGHT / NIGHT-REJUDGE
- prior night review/capture evidence under `docs/reviews/` and `shots/night_light/` if still present

If any of these have changed since this prompt was written, current `main` wins.

## Verification sequence

### 1. Establish current state

Before touching values, run the existing capture path on current `main`.

Expected command shape from the file itself:

```bash
xvfb-run -a -s "-screen 0 1280x720x24" \
  godot --path . --rendering-driver opengl3 --resolution 1280x720 \
  --script tools/capture_night_light.gd
```

Then run:

```bash
python3 tools/frame_stats.py shots/night_light/*.png
```

Record the resulting values and compare DAY vs NIGHT at the same viewpoints.

### 2. Verify torch state, not just brightness

For the torch frame, confirm from the capture script/log that:

- the torch exists in inventory;
- `Game.equipped_tool == "torch"`;
- the in-hand prop is actually visible/owned by `tool_hold.gd`;
- `torch.is_on()` is true at the capture moment;
- its SpotLight/OmniLight path is active only while equipped.

If the frame is dark because the torch is not equipped/on, fix the state path first. Do not compensate by making night brighter.

### 3. Judge night as a play state

The important visual bar is not "can frame_stats find nonzero luminance." A playable night should satisfy all of these at once:

- player can read nearby terrain shape;
- obstacles/rocks/trees that matter to traversal are visible before collision distance;
- nearby creatures/NPC silhouettes remain readable enough to play;
- the route/path can be followed without guessing at black pixels;
- sky remains distinctly dark/cool;
- ground is meaningfully darker/cooler/desaturated relative to day;
- night does not look like a daytime palette with the sun disabled;
- torch creates a useful local pool/throw of light without making the entire world look globally illuminated;
- outside the torch's reach, darkness still has meaning.

### 4. Verify on the real target build

The capture tool uses the Compatibility/software renderer for consistent judged screenshots. Its own header correctly warns that this is not the shipped Forward+ ROG Ally renderer.

Therefore, also perform a real controller play check on the current Windows/ROG Ally build during true night.

Walk through at least:

- village/open meadow;
- a wooded or cluttered route;
- one rocky/terrain-heavy route;
- torch unequipped;
- torch equipped and lit;
- moving/turning with the normal gameplay camera.

The question is practical: can the owner traverse and interact naturally without night becoming either black-screen frustration or a dim daytime filter?

## Classification of any failure

Do not let NIGHT-REJUDGE become a catch-all.

### If the problem is night duration or abrupt transitions
Route to **RG21**.

Examples:

- night lasts too long;
- true dark portion is not ~2 minutes;
- dawn/dusk snap abruptly;
- midnight wrap pops;
- continuous cycle interpolation is missing.

### If the problem is torch equipment/light behavior
Route to **RG22**.

Examples:

- torch does not light when equipped;
- torch does not appear in hand;
- torch stays lit while unequipped;
- local throw/range is materially wrong in the current ROG build.

Remember: owner has already approved the newer torch pictures. Do not retune brightness unless the current playable build actually shows a remaining issue.

### If the problem is global night mood/readability
Only then adjust NIGHT-LIGHT presentation values, and do so minimally.

Use the existing knobs in `art.json` / `world_look.gd`:

- moon/sun energy and pitch;
- ambient energy/colour;
- exposure;
- fog colour/density;
- sky gradient/energy;
- adjustment saturation/contrast.

Do not introduce a parallel night-lighting system.

Preserve the current design intent: cool, desaturated, readable night.

## Visual review requirement

This is visual-affecting work under `ralph/conventions.md`.

If no code/data change is needed, a fresh representative capture plus an explicit current-main judgment is sufficient verification.

If a visual change is made:

1. capture representative frames;
2. run the existing blind visual-judge workflow;
3. iterate while it is measurably improving;
4. stop according to the convergence rules in `ralph/conventions.md`;
5. do not declare success based only on the implementing agent's own opinion.

## Preserve

- current approved torch-in-hand behavior;
- torch only lighting when actually equipped;
- existing night-blue/cool presentation;
- current ACES/Environment pipeline;
- RG21's ownership of timing/continuous transitions;
- RG22's ownership of torch verification;
- day presentation;
- gameplay mechanics that happen at night;
- controller-first ROG Ally behavior.

## Do not

- Do not redesign night from scratch.
- Do not brighten night simply because an old pre-fix report said it was dark.
- Do not judge torch lighting while the torch is unequipped.
- Do not use only numeric frame statistics as proof of visual quality.
- Do not make night read like day with lower brightness.
- Do not tune RG21's cycle duration/transition work inside this verification item.
- Do not create a second torch implementation.
- Do not add stars/moon/new sky assets unless a separate approved art task calls for them.

## Acceptance criteria

NIGHT-REJUDGE may close without code changes if all are true on current `main`:

1. Night is visibly and unmistakably night.
2. Nearby terrain and meaningful obstacles are readable enough for normal traversal.
3. Creatures/NPCs and interaction space remain usable at normal gameplay distances.
4. Torch is confirmed equipped, held, and lit when judging the torch frame.
5. Torch materially improves local visibility.
6. Unequipped torch remains inert.
7. The world outside torch range remains dark enough that night still matters.
8. Same-viewpoint day/night captures show a meaningful mood/value distinction.
9. Current ROG Ally/Windows play confirms the experience, not only the Compatibility capture.
10. Any remaining problem is explicitly classified as RG21, RG22, or a narrowly scoped NIGHT-LIGHT presentation defect.

## Testing / evidence

At minimum retain or produce:

- fresh `shots/night_light/` captures from current `main`;
- `frame_stats.py` output for those captures;
- capture log showing torch `is_on=true` and `equipped_tool=torch` for the torch scenario;
- a short ROG-play verification note;
- if changed, blind visual-judge result and the final representative frames.

Run relevant existing smoke/unit coverage for `world_look`, torch/equipment, and day-cycle code only if those files are modified.

## Definition of done

NIGHT-REJUDGE is done when current `main` has been re-evaluated with the correct equipped-torch setup and there is clear evidence for one of two outcomes:

**A. PASS:** current night is readable, still clearly night, and the equipped torch works — no further NIGHT-REJUDGE changes.

**B. ROUTED REMAINDER:** a specific defect still exists and is assigned to RG21, RG22, or a narrowly defined NIGHT-LIGHT presentation fix with evidence.

The wrong outcome is a speculative fourth lighting pass performed merely because the backlog item exists.