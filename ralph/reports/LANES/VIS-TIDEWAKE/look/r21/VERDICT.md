# VIS-TIDEWAKE look round 21: dimmer moonlit night (CPU); not judged, stays OFF

- Candidate: `ov_r21.json` (`cause_tidewake.night`: moon 1.25 -> 0.95, ambient 0.4 -> 0.3, exposure 0.95 -> 0.84) vs r19b.
- The night frames are nearly identical side by side: the sand still reads pale and the cyan shoreline band is unchanged. Flat by inspection, so no judge round; stays OFF.
- The judges' "snow sand / neon shoreline" is not driven by these night keys. `water.gdshader` has no emission, so the band is the lit shallow colour plus sky reflection. The next lever there would be a night-specific shallow colour or fresnel, which needs a time-of-day input in the water material (code change, not a config arm).
