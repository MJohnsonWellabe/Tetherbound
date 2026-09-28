# Independent source review

Reviewer cloudreach_buttress_review: clean, no concrete blocker.

The new rules use the existing repaint tool’s first-match behavior, protecting dark features before applying amber, violet, and ivory recoloring. `--only shiny cloudfang` leaves ordinary `vivid_rules`, finish settings, and tracked ordinary textures unchanged.

The PNG filename exactly matches `_texture_for()`’s extracted-texture fallback, and its `.import` references the correct source. The generated unsuffixed source PNG is reproducible from the tracked GLB and is not a runtime dependency. Existing emission fallback supports the single shiny albedo output.

No shared runtime or generator changes. Shiny PNG and .import must accompany config. No visual acceptance claimed by source review.

Root verification: 2 existing source-colourway tests, 76 assertions, 0 failed; six native frames and two studio frames opened individually. Actual runtime shiny and ordinary paths exercised; old placeholder reproduced explicitly in a diagnostic fixture. Full suite not run for this bounded texture change; required before full F08#4 READY.
