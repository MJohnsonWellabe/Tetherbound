Existing Low selection and actual boot-reload proof: narrow PASS.

Source145e14b4c64d62c26cdf57c045b490ba4aefbcc6; existing tests/smoke_graphics_low_persist.gd; fresh isolated sharedprofile. First Forward+ process seedsHigh, uses injected joypad A on production Settings to cycleHigh toLow and persists Compatibility. Second process deliberately has no --rendering-method; loadsLow, resolves preboot project override, actually runs Compatibility and needs no restart. Six selection checks and five reload checks PASS; bothnativeexit0/noERROR. Total24.969s.

Raw logs, exact commands/receipt, canonicalLowcfg and previousHighcfg/profiletext records are preserved byte-identically with ZIP/entry hashes. Existingtestheader says physicalA; orchestration injects joypad events, so no physical-controller hardware proof is claimed. No source/test/harness changes.

FullF26#1 staysOPEN: this does not certify allForward+ featurebuttons, allHigh settings, everyvaluepersistence, GPUranges or visuals. NoFPS/Ally/earned proof. Independent original-byte and narrow-proof audit PASS; see delivery-review.md.
