# F10 isolated r1 prelaunch failure: no engine result

Preserved original runner, admissions, CPU report and failure review. Assignment to reserved `$home`/`$HOME` failed after project extraction and run-directory creation, before lease claim or engine launch. No runtime receipt was produced. Root execution report was `a6d696`; the retained failure-review records that provenance. The old extracted project and output directory were preserved.

The corrective r2 runner used `$IsolatedRunHome`, fresh paths and an AST reserved-variable fixture; its subsequent engine/API failure is a separate sibling bundle. This original CPU fixture did not detect the reserved-variable defect and must not be presented as runtime success.

[raw-bundle.json](raw-bundle.json) preserves 5 byte-exact base64 payloads; all decoded bytes matched originals. [hash-manifest.json](hash-manifest.json) records lengths and SHA256. Canonical UTF-8/LF bundle SHA256 `2393c070744bb1169c16a816e6f3be234fdc9253100380d289d3cdca6fe8fc33`. Homes, caches and generated `.godot` data are excluded.
