# Main 8e58444aa release audit — complete

Release34383202336 targets `8e58444aa273430f435ae96a8663c7860850614e`; attempt1 completed successfully at17:45:23 UTC on2026-09-09. Build102572867197 and Pages102576758119 both succeeded. Both full raw logs, total1,654,013 bytes, and metadata are retained under `.artifacts/main-8e58444a-release/`. Neither raw job contains native ERROR/SCRIPT ERROR lines; no retry or stale-publication skip was observed.

The build explicitly updated and verified rolling `latest` at exact8e58444aa at17:40:26. REST independently confirmed both the literal `refs/tags/latest` object and release target commit equal this full SHA. `Tetherbound-windows.zip` metadata:694,326,374 bytes; digest `sha256:feadf2e5b9f072830fa6f45d96039a09f35e7d5071c2b0b36734ac332f9739a2`; asset created17:39:47 and updated17:40:24. The reused release envelope's old published_at is not treated as this upload's timestamp. No archive download was made.

Pages raw records `pages_build_version` equal exact8e58444aa at17:45:14 and reports success at17:45:20. This proves this release and site publication at the recorded time; a later queued main release may supersede rolling latest. No broader gameplay or visual acceptance is implied.
