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

### Frames the page is currently missing, and why

The same rule cuts the other way: a captured frame that misrepresents the game
has to come off the page, even when nothing replaces it. Two did, in the story
rewrite, and both are deleted rather than left committed-and-broken so that the
layered fallbacks do their job and a fresh capture drops straight back in:

- **`opening-bedroom.jpg`** — the capture was an undressed white blockout room
  with a bed in it, captioned "First light in Grandpa's farmhouse". The section
  keeps the copy and has three figures instead of four until the interior is
  dressed and re-shot. `tools/capture_site_shots.gd` still knows the viewpoint.
- **`village-square.jpg`** — the `village-square` viewpoint in
  `capture_site_shots.gd` puts the camera *inside a roof*: the frame is 70%
  roof tiles. Its coordinates are unchanged here because re-aiming a camera in
  a 3D scene is not something to guess at blind; it needs one Godot run. The
  slot falls through to `01-spawn-outward.jpg` meanwhile.

Wanted and never captured:

- **`tether-site.jpg`** — a close frame of a relay site: pylon ring, cabling,
  drained ground. `.s-tether` is already wired for it and falls through to
  `03-rise-overlook.jpg`, which contains all three in the middle distance. This
  is the single highest-value shot the story page does not have.
- A **Meadows Hall approach** frame and a **Warden** frame. The road section
  ends at both and shows neither.

Also worth a re-shoot when someone is in there: `camp-dusk.jpg` has untextured
orange spheres floating over the horizon, and `weather-rain.jpg` is flat
overcast with no readable rain (the caption was rewritten to say "grey" rather
than promise rain it does not show).

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
