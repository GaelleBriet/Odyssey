# Odyssey settings window — implementation plan

> Executed inline; spec: `docs/superpowers/specs/2026-10-06-odyssey-settings-window.md`.

1. Model (`Options.lua`, tests): `Options.SECTIONS` (key, label, preview, cards), controls carry `section` + `card`, action controls (`resetSession`, `clearHistory`, `resetColors`), info control (version); translations.
2. Bar preview mode (`Bar.create(source, { parent, width })`): no drag, no tooltip, no native-bar handling, fixed width; `ns.Refresh` updates it.
3. Tooltip preview placement inside a frame.
4. Window (`Options.lua` frames): title bar, sidebar, scrolling content with card layout, flat widgets, Blizzard Settings stub with an "Open Odyssey" button, saved position.
5. Docs.
