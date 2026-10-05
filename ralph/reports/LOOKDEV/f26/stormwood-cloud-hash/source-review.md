# Independent source review

PASS for the bounded shader hash replacement; native rendering and visual acceptance remain OPEN.

Compared `scripts/world/stormwood_surge.gd` against `64b87b7a50` using read-only Git and inspected `shaders/sky_clouds.gdshader:207–211`. The sole diff replaces the one-line `fract(sin(dot(...)) * 43758.5453)` cell hash with the established sky shader's three-statement non-trigonometric hash. The function bodies match exactly, including constants, swizzles and arithmetic; only the function names differ (`hash` / `hash12`). Replacing each old/new block with a common marker yields identical remaining LF bytes. The inspected working file contains zero CRLF sequences, so newline normalization made no change.

SHA256 of the inspected working source: `311e17315cb0796633cecadf1a44ca3be1a34119fd8275d5f42f7b97af8dcdad`. Baseline Git LF source: `19178a7952d3a8694cf104164debfd0db79d684850c75c545d103e1e2c4aeabb`.

The replacement stays inside the spatial `CEILING_SHADER` string. Its `vec2` input, local `vec3 p3`, `fract`, swizzles and `dot` are consistent with the existing sky shader; its scalar return and call sites are unchanged. No uniforms, render modes, script lifecycle, phase clocks, rain, gameplay authority or configuration values change. No source-level naming/type blocker found. This review does not confirm native shader compilation.

Consumers extend beyond the main cloud body: `noise` feeds five-octave `fbm` and `ridge`. Those drive cloud structure/definition, rim and thin-light masks, sheet-lightning patch/pulse modulation, Fading afterglow, breakup/opacity, and Break crawler warp, ridges, branching, cover and breathing. The deterministic pattern changes wherever those paths are visible. Unchanged thresholds and styling do not guarantee an equivalent appearance, crawler readability or identical luminance.

Removing the trigonometric hash and its large final multiplier is a plausible response to floating-point precision/pattern artifacts. Source inspection does not establish the observed artifact's cause or prove the replacement fixes it. Existing Medium/High native phase/release captures and independent image judgment remain required; no art, FPS, full-bar or acceptance PASS follows from this source verdict. No engine, tests or source/Git mutations were performed by the reviewer; only this authorized evidence note was written.
