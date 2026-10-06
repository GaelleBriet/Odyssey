# Odyssey reputation bar — implementation plan

> Executed inline; spec `docs/superpowers/specs/2026-10-06-odyssey-reputation.md`.

1. `Sources/Reputation.lua` (injected api: watched(), now()) + tests.
2. `Texts` rep keys + `TooltipContent.buildRep` + tests.
3. `Defaults`: `settings.rep`, `Defaults.repView(xp, rep)` linked-style view + tests.
4. `Compat`: rep api (classic/modern), standing label and colour + tests.
5. `Bar`: settings accessor, kind ("xp"/"rep"), targets, standing fill colour, rep visibility rules.
6. `Tooltip`: content provider per bar.
7. `Options`: bar selector, per-bar pages, bar-specific controls, look controls greyed while linked + model tests.
8. `Core`, probe, locales, docs.
