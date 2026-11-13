# THINGS-HALLMOSS: less moss on the stronghold's interior stone (F38#28 close-out)

**Row.** F38#28 after TELLDUST: High 7.47, Medium 7.55; it misses on High by 0.03. `G-things-telldust.md`, 2/3: "a translucent green vertical plane behind the dog in the Warden hall, read as exposed geometry".

**What it is.** `_sheet_gpu_main_green_panels.jpg` is a crop of main at High (Warden frame 03): flat, hard-edged green rectangles on the hall wall behind the dog. They are not geometry. The hall's stone shader grows moss from a low-frequency field (`stronghold.json site.weathering`: `moss_amount` 0.46, `moss_scale` 0.3, so patches about 3 m across); where a patch covers one whole recessed wall panel and stops at the pilaster beside it, the panel reads as a green sheet laid over the wall.

**Change** (overlay only, one value): `site.weathering.moss_amount` 0.46 to 0.22. Interior stone only: the exterior block sets its own `moss_amount` (0.78) and is not touched, so the stronghold from outside (F38#20, closed at 7.50 with no margin) does not change. Floors keep their own `floor_moss_amount`.

**Not shown on CPU.** The hall renders too dark on CPU to see the panels on either side; the two CPU frames I took look alike.

**Scope and risk.** Every interior stone wall in the stronghold gets less moss (the hall, the courtyard walls behind Warder Solene, corridors). Less moss also means less colour variation on those walls, which could read as flatter; hence the no-loss frames.

**Ask.** By eye first on Warden 03: the green rectangles behind the dog should be gone or faint. Then F38#28 at High and Medium on camera-matched pairs, with the no-loss frames.
