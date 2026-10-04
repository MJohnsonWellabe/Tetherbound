# F17 remote renderer bridge — independent source review

Verdict: **SOURCE PASS** for the pending `.github/workflows/render.yml` diff against HEAD `523cf3445413991ef3c0711ef02e90e91113050e`. This is workflow source review only; F17#6 remains OPEN.

Scope: reviewed the actual 17-addition/2-deletion workflow diff, full surrounding workflow, setup-godot composite action, and the existing native preflight in `tools/capture_f17_visual.gd`. No engine, GPU, desktop, network, dispatch, import or gameplay run was performed. Only this report was written.

- The dispatch choice permits exactly `gl_compatibility` and `forward_plus`, defaults to Compatibility, and flows through environment variables. The shell validator requires an exact match to either literal before checkout or package/run shell use; no wildcard or substring acceptance is introduced.
- Package installation remains render-only. Compatibility installs only xvfb; Forward+ additionally installs `mesa-vulkan-drivers` and `libvulkan1`. The Bash array is passed as individually quoted arguments.
- The render command explicitly pairs Compatibility with `opengl3`, and Forward+ with `vulkan`, using native Godot `--rendering-method` and `--rendering-driver` flags. This removes the former unconditional OpenGL3 constraint for the Forward+ capture lane while preserving the default Compatibility intent.
- The headless command is textually unchanged and receives no new renderer flags. Existing argument splitting and `--` boundary, input guards, checkout restrictions, script-existence check, time cap, exit receipt, log tail, output marker, artifact collection/truncation, artifact name/retention, and final script-failure gate are unchanged.
- The project renderer default and production sources are untouched. Existing native capture preflight still rejects a headless display, a mismatched preset/renderer, non-1920x1080 window, invalid source SHA or reused/nonabsolute output directory; it was not weakened to accommodate the workflow.

Material limits and runtime risks:

- Source inspection cannot establish Mesa Vulkan initialization, native capture completion, readable frames, motion duration, real combat, performance or Bars A/B acceptance on the hosted runner. Vulkan under xvfb/software rendering may fail or exceed the existing budget. Preserve logs and partial artifacts if that happens; do not assign capture credit from a dispatch or import success.
- `setup-godot` still executes its preexisting headless imports before the render-only package step. Those imports are not converted into Forward+ visual proof by this bridge. Local engine hold and main-green import hold remain in force; this review does not authorize either to resume.
- The existing `mode` description still says `render (xvfb + opengl3, the production path)` and is now incomplete for an explicitly selected Forward+ dispatch. This is a minor documentation mismatch, not a runtime blocker or a changed production default.
- The run must use the branch workflow revision containing this input/command change. Merely checking out the branch from an older workflow revision does not update the executing workflow definition.

Validation: `git diff --check -- .github/workflows/render.yml` passed. No implementation-mirroring tests were added or run. No false capture claim appears in the changed workflow.

Required next evidence remains native Medium/High/Low readable ordinary views, weather, reverse views and details; at least 30 seconds of motion and real fight evidence; and independent code-blind full Bars A/B judgment. The bridge alone closes none of that evidence.
