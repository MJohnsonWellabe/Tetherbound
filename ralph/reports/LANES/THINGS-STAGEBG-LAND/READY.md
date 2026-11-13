STATUS: land

# THINGS-STAGEBG landing (pose stage keeps its own backdrop under the graphics preset)

Branch `tb/things-stagebg-land`, cut from main 6906a2eb. Tooling only: `tools/_capture_creature_roster.gd`.

**Regression (GPU lane, from #925).** With the preset applied, the pose stage backdrop renders black on Medium and High where it was dark slate (51, 56, 61). Sheets from before and after #925 are not like for like.

**Likely cause.** `graphics_prefs.apply_environment` does not set the background, but it turns volumetric fog on for the Forward+ presets. The stage has no sky (a `BG_COLOR` backdrop), so the fog's black covers it. **This is a reading of the code, not a reproduction:** the CPU renderer here has no volumetric fog and never showed the black.

**Fix.** The stage records its backdrop mode and colour and its ambient source, colour and energy before the preset call and restores them after it, and switches volumetric and depth fog off (a studio stage has no air). The preset still reaches the stage for shading: glow, SSAO, SSIL, shadow profile, filtering.

**Check (CPU, Low).** Mirejaw hit: `STAGE graphics preset applied: Low` still prints; backdrop pixel (51, 56, 61), the same as the pre-#925 stage; no script errors; the only pixel differences from the pre-#925 frame are the shadow area, as before. **Not verified:** that the backdrop is slate again on Medium and High. Please check one frame on the GPU before re-running the F36 Medium re-verify; if it is still black, the next suspect is glow or SSIL, and the log line shows which preset ran.
