# The download page

Published to GitHub Pages by `.github/workflows/release.yml` on every push to
`main`, alongside the Windows build it links to.

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
slice, not a finished game — and it is the only release in the repository, so
there is no "latest" for GitHub to resolve and the URL returns **404**. It did,
for every build up to and including the one that added the produced character
art: the release asset was uploaded and current the whole time, and the button
on this page was dead.

`/releases/download/<tag>/<file>` addresses the release by tag instead. The tag
is literally `latest` and the workflow re-points it at every push, so this form
is exactly as permanent and does not care about the prerelease flag.

Marking the release "not a prerelease" would also have fixed the link, and is
the wrong fix: the flag is telling the truth.

## What the page says now

The page is written around the game's story, not around a feature list:
**Team Tether is back, their pylons are draining the Meadows, Grandpa is a
former trainer who can no longer make the journey, and the player builds a team
of five and goes instead** — village tournament, South Bridge, the quarry and
the Burrow Warrens, the river relay, three regional captains' Sigils, and the
Warden at Meadows Hall, after which the region visibly heals. That is
`docs/TETHERBOUND_GAME_VISION.md` §3 and `docs/MEADOWS_PROGRESSION_SPEC.md`
verbatim in intent; nothing on the page invents a story beat, and the copy is
deliberately vague about what the tether machine is holding because the game
reveals it at the bottom of the hall.

`--tether-teal` keeps its in-game reservation on this page: it appears only in
the Team Tether band and on the road legs where Team Tether is the obstacle.

## The images are real frames

`site/img/*.jpg` are in-game captures, not concept art and not mock-ups. To
refresh them after a visual change:

**Import first.** Godot loads textures from `.godot/`, not from the repo, so a
capture run straight after pulling art changes renders the *old* textures — or
fails to load them at all and renders flat. This has bitten a refresh already:

```bash
godot --headless --path . --import      # ALWAYS, after any pull that touched art
git checkout project.godot              # the import pass strips its comments
```

Then capture. Shoot at 1280x720 and downscale in the conversion step — the
small figures only need 960 wide, and a bigger source survives a re-crop:

```bash
tools/survey.sh                                            # exploration frames
tools/survey_combat.sh                                     # combat frames
for t in capture_site_shots capture_shiny_pairs capture_weather \
         capture_torch_night capture_catch_sequence; do
  xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
    --rendering-driver opengl3 --resolution 1280x720 --script tools/$t.gd
done
```

Never pass `--headless` to anything that renders — it swaps in a no-op renderer
and the run hangs. Check the **file count**, not the exit code: Terrain3D aborts
on shutdown after rendering (D06), so a successful run still exits non-zero.

Conversion is `tools/site_images.py` — it holds the source-to-slot mapping so
this README cannot drift out of sync with it again (it did: it named
`06-charged-attack-lands.png` for a year after the tool started writing
`06-charged-attack-lands-offaxis.png`, so the documented recipe failed outright).

```bash
python3 tools/site_images.py
```

The page is written to survive missing shots: several slots fall back to another
committed frame via CSS multi-background, and each section keeps a palette
gradient as its floor. Skipping a capture degrades the page, it does not break
it.

Do not commit `site/img/*.jpg.import`. They are Godot sidecars — `site/` lives
inside the Godot project, so the editor imports the page's JPEGs as textures.
They serve no purpose on a website and get uploaded to Pages. This paragraph
was here the whole time and all fifteen of them were committed anyway, so
`site/img/*.import` is now in `.gitignore` and the rule enforces itself.

`shots/` is gitignored and regenerated; `site/img/` is committed, because the
page has to keep working without anyone re-running a survey first.

**Do not touch these up.** A download page that shows something the build does
not do is the fastest way to stop being able to trust your own screenshots —
and the blind visual critic reads the same frames.

### The story frames

`tools/capture_site_story.gd` is the sibling of `capture_site_shots.gd` and
shoots what the story sections need: the village square, villagers, a villager
mid-conversation with the real dialogue panel open, a severed outward road, the
Tether Relay from outside its wall and up at its apparatus, Meadows Hall from
the approach, and the Old Mill Crossing. Every eye and target in it is an XZ
plus a height *above the live terrain*, and the landmark coordinates are read
out of `data/config/map_landmarks.json` rather than copied, because the
authored sites have been relocated wholesale before (`OW5D`) and the last set
of hardcoded numbers left a camera inside a roof for months.

It is slow — the full playground scene is ~130k scattered props under llvmpipe
— so it skips any frame already on disk and a run can be resumed by simply
running it again.

The starter frame is `tools/capture_starter_picker.gd`, not a staged row of
creatures outside the door: the door staging was reversed on 2026-08-11
(`SA0-orbs`, `docs/OPENING_SEQUENCE.md`) and the choice is three orbs previewed
indoors during Grandpa's briefing. The page showed the old staging for months
after it stopped being true.

The roster frame is `tools/capture_roster_ordinary.gd`. **Do not put
`_shiny_pairs.png` on the page** — it is `OF28`'s internal judging frame, and
publishing it showed every rare colourway in the game to players who had not
caught anything yet. Owner directive, 2026-08-22.

### Frames the page is currently missing, and why

The same rule cuts the other way: a captured frame that misrepresents the game
has to come off the page, even when nothing replaces it.

**SITE-SHOTS (2026-08-23) closed out the list this section used to carry.**
`capture_site_shots.gd`'s own `village-square` viewpoint is still the one
`capture_site_shots.gd:34-37` documents as broken (camera inside a roof) —
that has not been touched, on purpose, per that file's own "not something to
guess at blind" rule. But `capture_site_story.gd` carries an independently
authored `village-square` viewpoint that does not share the bug, and a
now-out-of-date pass of this README never noticed that the fixed one had
already landed on `main` (`6cdf8dc9`) and shipped. `site/img/village-square.jpg`
is real; only this file's own bookkeeping was stale.

- **`opening-bedroom.jpg`** — re-verified, not re-dressed. The old capture
  really was an undressed white blockout, but `grandpa_house.gd`'s furniture
  pass had already given the loft a real `BedTwin` and nightstand by the time
  anyone re-shot it; a fresh capture just confirms that and puts `.s-bedroom`
  back with four figures again.
- **`tether-site.jpg`** — landed. A close pylon-line/cabling/drained-ground
  frame, sited on `tether_relay.json`'s own west-run pylons through that
  file's site frame. First-guess coordinates rendered clean.
- **A Warden frame** — landed, close rather than wide. The Warden Arena has
  no window and only faint trim-light fill (`stronghold.gd`'s `OmniLight`s
  default to energy 0.5), so a wide 3/4 shot was mostly black void; a
  portrait crop is what actually reads. A **Meadows Hall approach** frame is
  still missing — see below.
- **`camp-dusk.jpg`** — re-verified. Whatever produced the "two orange discs"
  this section used to describe does not reproduce on current `main`; a fresh
  capture's sky is clean. Left as-is rather than re-shipped for an
  effectively-identical frame.
- **`weather-rain.jpg`** — re-verified, not re-shot. The rain streaks in a
  fresh capture are near-pixel-identical to the committed frame: real,
  visible on close inspection, and deliberately faint by an already
  blind-pass-validated design (`world_weather.gd`'s own comment: "a faint,
  mostly-transparent line, not a light source"). "No readable rain" was
  never a capture bug to fix; the caption already says "grey", correctly.

Still missing, and gated on someone else's fix rather than a capture run:

- **Meadows Hall approach** (`.s-hall`, `stronghold-approach.jpg`).
  `STRONGHOLD-MAT` landed (`97f4ff32`) — the stronghold has real textured
  masonry now — but `SKY-PLANES` has not, and a fresh capture from the
  approach viewpoint shows it plainly: several large translucent grey quads
  standing directly behind the hall, not a subtle artefact confined to the
  storm_road blocker its root cause names. Wiring the figure back in waits
  on that fix, not on a re-shoot.

## Colours

`index.html` uses `data/config/palette.json` verbatim, the same file the game's
materials, lighting and UI read. The site and the build cannot drift apart in
palette without somebody editing that file.

`--oxblood` is the reserved danger accent. In game it appears only on Team
Tether; here it is used once, on the "vertical slice" mark, which is the single
warning on the page.

## One-time setup

GitHub Pages has to be switched to **GitHub Actions** as its source, in
Settings → Pages. The workflow cannot do that for you.
