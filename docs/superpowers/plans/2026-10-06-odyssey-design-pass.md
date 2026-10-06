# Odyssey design pass — implementation plan

> Executed inline (native) by the agent, on the user's instruction "fait ce que tu peux sans que le jeu ne soit lancé".
> Spec: `docs/superpowers/specs/2026-10-05-odyssey-design-pass.md`

**Goal:** 4 bar styles, 11 palettes, font choice (game + bundled OFL + LibSharedMedia), a custom "Minimal" tooltip with a Shift detail view, and a scrollable dropdown in the settings.

**Architecture:** same split as v1 — pure modules tested under luajit (`Styles`, `Fonts`, `TooltipContent`, `Defaults` migration), thin WoW layer (`Bar`, `Tooltip`, `Options`, `Core`). Every client API not yet confirmed by the probe is feature-tested at runtime with a fallback.

## Global constraints

- Same as v1 plan (`docs/superpowers/plans/2026-10-05-odyssey.md`): interface 16001, `ns` only, no Blizzard assets, no hard dependency, commits on `feat/odyssey-v1` with trailer `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, no push.
- APIs unconfirmed on this client, each guarded with a fallback: `CreateMaskTexture`/`AddMaskTexture` (fallback: square corners), `Texture:SetGradient` + `CreateColor` (fallback: flat `to` colour), `LibStub` (fallback: no external fonts). They are added to `/odyssey probe`.

## Tasks

1. **Styles & palettes** (`Styles.lua`, tests): `Styles.list = {smooth, segmented, neon, thin}`, `Styles.defs[key] = {texture, border, gloss, ticks, glow, spark, rounded, textPosition ("inside"|"above"), height}`; `Palettes.list` (11 keys: arcane, gold, emerald, frost, ember, rose, night, fel, monochrome, class, faction), `Palettes.defs[key] = {fill = {from, to}, rested, quest, bg, border, accent, text}`, `Palettes.colors(key, ctx)`.
2. **Settings v2 & migration** (`Defaults.lua`, tests): new keys `palette`, `barFont`, `barFontSize`, `barFontOutline`, `tooltipFont`, `tooltipFontSize`, `tooltipFontOutline`; `Defaults.migrate(db)` maps v1 `style` (flat/gradient/glossy → smooth) and `theme` (classic→arcane, class→class, faction→faction, minimal→monochrome) into `palette`, for the account and every character, then sets `version = 2`.
3. **Fonts** (`Fonts.lua`, tests): game fonts + bundled fonts, `Fonts.list(lsm)`, `Fonts.resolve(name, lsm)` (unknown → default), `Fonts.flags(outline)`, `Fonts.registerBundled(lsm)`; fake `lsm` in tests.
4. **Tooltip content** (`TooltipContent.lua`, tests): `TooltipContent.build(snap, settings, store, opts, L, detailed) -> groups`, each group a list of rows `{label, value, color}` or `{kind = "history", level, ratio, duration}`; default view = 3 groups (progress/remaining/rested/quests total; XP per hour/level up in; time played); detailed view adds quest list, kills + last gain, session, this level + average, history; empty rows/groups dropped; tooltip toggles honoured.
5. **Textures** (`tools/make_textures.py`): `fill.tga` (vertical shade), `gloss.tga`, `glow.tga`, `round-mask.tga` (rounded-rect alpha mask), keep `spark.tga`, `tipbar.tga`; drop `flat/gradient/glossy`.
6. **Bar** (`Bar.lua`): styles, palettes (gradient fill), fonts, ticks, glow, gloss, rounded mask, texts above for `thin`.
7. **Tooltip frame** (`Tooltip.lua`): custom frame drawn from `TooltipContent`, accent strip, separators, fonts, anchored above/below the bar, refresh each second and on Shift change.
8. **Options** (`Options.lua`, locales): dropdown control (scrollable list, fonts shown in their own face), new controls (palette, fonts, sizes, outlines), locale keys for all new strings (enUS + frFR, completeness test).
9. **Core, probe, docs**: register bundled fonts in LibSharedMedia at login, run migration, probe the guarded APIs, README/CHANGELOG/spec notes, `.pkgmeta` keeps `Media/Fonts` licences.

In-game verification of tasks 6–8 is batched for the next game session.
