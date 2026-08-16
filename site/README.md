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
They serve no purpose on a website and get uploaded to Pages.

`shots/` is gitignored and regenerated; `site/img/` is committed, because the
page has to keep working without anyone re-running a survey first.

**Do not touch these up.** A download page that shows something the build does
not do is the fastest way to stop being able to trust your own screenshots —
and the blind visual critic reads the same frames.

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
