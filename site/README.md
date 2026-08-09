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

```bash
tools/survey.sh                                            # exploration frames
tools/survey_combat.sh                                     # combat frames
xvfb-run -a -s "-screen 0 960x540x24" godot --path . \
  --rendering-driver opengl3 --resolution 960x540 \
  --script tools/capture_site_shots.gd                     # authored page shots
python3 - <<'EOF'
from PIL import Image
for src, out in [
    ("shots/site/hero-meadow.png", "site/img/hero-meadow.jpg"),
    ("shots/site/village-square.png", "site/img/village-square.jpg"),
    ("shots/site/opening-bedroom.png", "site/img/opening-bedroom.jpg"),
    ("shots/site/starters-by-the-door.png", "site/img/starters-by-the-door.jpg"),
    ("shots/site/camp-dusk.png", "site/img/camp-dusk.jpg"),
    ("shots/01-spawn-outward.png", "site/img/01-spawn-outward.jpg"),
    ("shots/03-rise-overlook.png", "site/img/03-rise-overlook.jpg"),
    ("shots/05-spawn-low-sun.png", "site/img/05-spawn-low-sun.jpg"),
    ("shots/combat/02-arena-opens.png", "site/img/02-arena-opens.jpg"),
    ("shots/combat/06-charged-attack-lands.png", "site/img/06-charged-attack-lands.jpg"),
    ("shots/combat/08-orb-in-flight.png", "site/img/08-orb-in-flight.jpg"),
]:
    Image.open(src).convert("RGB").save(out, quality=82, optimize=True)
EOF
```

The page is written to survive missing authored shots: `combat-arena.jpg` and
`aim-arc.jpg` fall back to the survey combat frames via CSS multi-background,
and each section keeps a palette gradient as its floor. Skipping a capture
degrades the page, it does not break it.

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
