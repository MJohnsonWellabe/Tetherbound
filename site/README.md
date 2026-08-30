# The Tetherbound website

Published to GitHub Pages by `.github/workflows/release.yml` on every push to
`main`, alongside the Windows build it links to.

## 2026-08-30 redesign

The page was rebuilt from scratch per
`docs/website/redesign-2026-08-30/01_CLAUDE_PROMPT_REDO_WEBSITE.md` (the
owner's brief — it wins on any conflict with this file): a much simpler,
image-first landing page. Gone: Steam language and buttons, fake social
links, the detailed chapter roadmap, patch-note-style homepage content, exact
hour claims, and long story exposition. Nav is HOME · CREATURES · WORLD ·
DEVELOPMENT · DOWNLOAD, all anchors on the one page.
`docs/website/redesign-2026-08-30/02_WEBSITE_ART_BOARD_FINAL.png` set the
layout/style direction only — none of its environment art is used; every
image on the page is a real capture of the current build.

The page is now: hero, four feature cards, a one-screen Team Tether story
beat, the creature roster, the world map (Meadows real, the other seven
regions a plain locked treatment — CLAUDE.md forbids faking an unbuilt
biome), a short honest development note, and one final call to action. No
per-slot CSS-background archaeology from the previous story-driven page
survives this rewrite; the images below are simply what each section uses
today.

## The download link never needs editing

The button points at:

```
https://github.com/MJohnsonWellabe/Tetherbound/releases/download/latest/Tetherbound-windows.zip
```

That URL is permanent and always resolves to the newest release asset, so
shipping a new build is a push and nothing else. It also needs no login, which
is the whole reason this exists — CI already uploaded a Windows build, but as a
GitHub *artifact*, which expires after 14 days and requires signing in.

### Why `/releases/download/latest/` and not `/releases/latest/download/`

The two read almost identically and only one of them works here.

`/releases/latest/download/<file>` resolves through GitHub's idea of *the
latest release*, and that expressly **excludes prereleases**. The workflow
publishes this build with `prerelease: true`, correctly — it is a vertical
slice, not a finished game — so this form 404s. `/releases/download/<tag>/<file>`
addresses the release by tag instead; the tag is literally `latest` and the
workflow re-points it at every push, so this form is exactly as permanent and
does not care about the prerelease flag.

## What each section uses today

| Section | Image(s) | Source |
|---|---|---|
| Hero | `hero-meadow.jpg` | `tools/capture_site_shots.gd`, re-captured 2026-08-30 |
| Feature: Find your five | `aim-arc.jpg` | `tools/capture_catch_sequence.gd` (`catch_high.png`) |
| Feature: Explore the wild | `01-spawn-outward.jpg` | `tools/survey.sh` |
| Feature: Fight together | `02-arena-opens.jpg` | `tools/survey_combat.sh` |
| Feature: Build a home | `village-square.jpg` | `tools/capture_site_story.gd` |
| Story band (Team Tether) | `tether-site.jpg` | `tools/capture_site_story.gd` |
| Creature roster | `roster.jpg` | `tools/capture_roster_ordinary.gd` (ordinary colourways only — see below) |
| World overlook | `03-rise-overlook.jpg` | `tools/survey.sh` |
| Final CTA | `camp-dusk.jpg` | `tools/capture_site_shots.gd`, re-captured 2026-08-30 |

Everything else under `site/img/` is a real frame from an earlier capture
pass, kept committed but currently unused by the page — a future CREATURES,
WORLD or DEVELOPMENT expansion can draw on them (or a fresh capture) without
starting from nothing. Nothing here is concept art or a mock-up.

**`village-square.jpg` is not from `capture_site_shots.gd`'s own
`village-square` viewpoint.** That viewpoint is still the one
`capture_site_shots.gd:34-37` documents as broken (camera inside a roof) —
reproduced again on a fresh 2026-08-30 capture, unchanged. The committed file
comes from `capture_site_story.gd`'s independently authored `village-square`
shot instead, which does not share the bug.

**Do not put `_shiny_pairs.png` on the page.** It is `OF28`'s internal judging
frame, and publishing it would show every rare colourway in the game to
players who have not caught anything yet. Owner directive, 2026-08-22.
`roster.jpg` is `capture_roster_ordinary.gd`'s output for exactly this
reason.

**Build a home** is the one card without a dedicated capture. `village-square.jpg`
shows real, in-world buildings, but it's the village, not a player-placed
structure. `tools/capture_build_kit_house.gd` renders the real build-kit
pieces at real placement transforms, but on an isolated dark studio
background rather than in the Meadows — the clear next capture is a
player-built house shot in the actual terrain, once there's a good one to
point a camera at.

## Refreshing the captures

**Import first.** Godot loads textures from `.godot/`, not from the repo, so a
capture run straight after pulling art changes renders the *old* textures — or
fails to load them at all and renders flat. This has bitten a refresh already:

```bash
godot --headless --path . --import      # ALWAYS, after any pull that touched art
git checkout project.godot              # the import pass strips its comments
```

Then capture. Shoot at 1280x720 and downscale in the conversion step — the
small figures only need 960 wide, and a bigger source survives a re-crop.
`tools/capture_site_shots.gd` and `tools/capture_site_story.gd` load the full
~130k-scattered-prop playground scene, which is slow under software
rendering (llvmpipe/Compatibility) — tens of minutes, not seconds, per run;
both are resumable (they skip any frame already on disk in `shots/site/` or
`shots/story/`).

```bash
xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
  --rendering-driver opengl3 --resolution 1280x720 \
  --script tools/capture_site_shots.gd
tools/survey.sh                                            # exploration frames
tools/survey_combat.sh                                     # combat frames
for t in capture_site_story capture_shiny_pairs capture_weather \
         capture_torch_night capture_catch_sequence capture_roster_ordinary \
         capture_starter_picker; do
  xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
    --rendering-driver opengl3 --resolution 1280x720 --script tools/$t.gd
done
```

Never pass `--headless` to anything that renders — it swaps in a no-op renderer
and the run hangs. Check the **file count**, not the exit code: Terrain3D aborts
on shutdown after rendering (D06), so a successful run still exits non-zero.

Conversion is `tools/site_images.py` — it holds the source-to-slot mapping so
this README cannot drift out of sync with it again (it did once: it named a
source file the capture tool had already renamed, so the documented recipe
failed outright).

```bash
python3 tools/site_images.py
```

`shots/` is gitignored and regenerated; `site/img/` is committed, because the
page has to keep working without anyone re-running a capture first.

Do not commit `site/img/*.jpg.import`. They are Godot sidecars — `site/` lives
inside the Godot project, so the editor imports the page's JPEGs as textures.
They are gitignored and the rule enforces itself.

**Do not touch these up.** A page that shows something the build does not do
is the fastest way to stop being able to trust your own screenshots — and the
blind visual critic reads the same frames. Sanity-check every frame before it
ships: real grass geometry, real lighting, not black or hazy.

**Renderer caveat**, which belongs in any critique made from these frames:
capture uses Godot's COMPATIBILITY renderer, not the Forward+ the game ships
(software Vulkan/lavapipe renders Forward+ fine but Terrain3D segfaults under
it during region streaming — reproduced consistently). So these frames are
trustworthy for composition, terrain shape, silhouette, colour relationships
and camera framing, and not trustworthy for fine judgements about lighting
quality or post-processing. On a machine with a real GPU, switch to `vulkan`
and the caveat lifts.

## Colours

`index.html` uses `data/config/palette.json` verbatim, the same file the game's
materials, lighting and UI read. The site and the build cannot drift apart in
palette without somebody editing that file.

`--tether-teal` and `--oxblood` keep their in-game reservation: teal only in
the Team Tether story band, oxblood only as that band's ground tint.

## One-time setup

GitHub Pages has to be switched to **GitHub Actions** as its source, in
Settings → Pages. The workflow cannot do that for you.
