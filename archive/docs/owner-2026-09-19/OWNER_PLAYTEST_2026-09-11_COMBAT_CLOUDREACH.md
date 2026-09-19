# Owner playtest — combat placement, Peblik, and Cloudreach riding

Recorded from the active owner conversation on 2026-09-11.

> In some fights like near the water or South ridge the creatures or characters get put in impossible situations like underwater or in the ravine. It messes up the game. After the first time it happened I couldn't fight anymore. The buttons didn't register.
>
> Also peblik or whatever the name of the common cloudreach creature is has weird texture and painting. It doesn't look good.
>
> I couldn't get back on the creatures with the saddle after going into cloudreach.
>
> Everything else seemed pretty good.

These observations reopen production behavior even where isolated tests previously
passed. Treat invalid combat placement and the persistent post-fight input lock as
P0 reliability defects. Treat the Cloudreach saddle remount failure as a progression
and traversal blocker. Peblik's material/paint is an explicit visual rejection and
cannot receive creature PASS until a fresh production render is independently
accepted. Preserve the current named-location sprint, but do not count that visual
progress as resolving these gameplay defects.
