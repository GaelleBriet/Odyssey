# Odyssey customization (settings v3) — implementation plan

> Executed inline (native) by the agent; same working agreement as the design pass (proceed as far as possible without the game).
> Spec: `docs/superpowers/specs/2026-10-06-odyssey-customization.md`

**Goal:** independent bar settings (texture incl. LibSharedMedia, corners, border, background opacity, effects, text position, mouseover visibility), per-element colour overrides, tooltip opacity/scale/anchor, and a tabbed settings panel with dropdowns, checkboxes and colour swatches.

**Architecture:** pure modules extended and tested under luajit (`Styles` presets + textures, `Palettes.effective`, `Defaults` v3 migration, `Visibility`, `Options` control model), WoW layer updated (`Bar`, `Tooltip`, `Options` frames, `Core`).

## Global constraints

As in the previous plans: interface 16001, `ns` only, no Blizzard assets, guarded APIs, commits on `feat/odyssey-v1` with trailer `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, no push.

## Tasks

1. `Styles`: `Styles.TEXTURES` (flat, gradient, glossy, smooth), `Styles.textureList(lsm)`, `Styles.resolveTexture(name, lsm)`, `Styles.PRESETS[key]` and `Styles.applyPreset(settings, key)`.
2. `Palettes.effective(key, ctx, settings)`: palette + `settings.colors` overrides + `borderColor`.
3. `Defaults` v3: new keys, `colors = {}`, migration v2 → v3 (style → preset fields).
4. `Visibility.alpha(settings, state)`.
5. Textures: re-add flat/gradient/glossy (128x32) next to fill (smooth).
6. `Bar`: independent settings, borders, bg opacity, ticks every 10/5 %, text inside/above/below, mouseover fade.
7. `Tooltip`: background opacity, scale, cursor anchor.
8. `Options`: tabs, every multi-value control as a dropdown, checkboxes, colour swatches (ColorPickerFrame, modern and legacy API), reset-colours button.
9. Locales, `Core`, probe, README/CHANGELOG.

In-game verification is batched for the next game session.
