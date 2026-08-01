# D23. The interface palette does not follow ASSETS.md

Kind: implementation

`ASSETS.md` art direction says "warm meadow greens and golds ... a single hot
accent (Tether iron-orange)". The first UI followed it literally and landed
close enough to the studio's golf game that the owner called it out.

That guidance governs WORLD art, where warm daylight grassland is correct, and
the world keeps it. The interface is a separate surface and now runs on its own
system: near-black green base, accents that read as glowing moss, spores and
night-blooming flowers.

Accents carry meaning rather than decoration, which is the part worth
protecting in review:

- lime `--spore` means "you can act on this"
- magenta `--bloom` means party, pals, affinity
- cyan `--dew` means orbs, capture, the throw
- gold `--sigil` is badges and rewards only, so it stays special
- orange `--tether` is Team Tether, enemies and danger, and nothing friendly
  may ever borrow it

Tokens live in `src/ui/styles/tokens.css` and no component may write a raw hex
value, so a retheme is one file. `styleguide.html` is a second Vite entry
rendering the real shipping `components.css`, because a style guide maintained
separately from the stylesheet drifts within a week and then misleads.
