# Odyssey polish — deferred minors from every review

> Executed inline at the user's request ("on fait les finitions, on rend le truc bien").

Pure (TDD):
1. Reputation session restarts when the watched faction changes.
2. Profiles: renaming to the same name is a no-op success; deleting the default profile hands the role to the first remaining profile (not the current character's); a non-table profile cannot be copied.
3. History: a character recreated with the same name (level lower than recorded) starts a fresh history.
4. Rounded masks and rings in several aspect ratios; the bar picks the closest one (no elliptical corners).
5. Settings window: menu display without rebuilding font/texture lists.

Frames / game (verified in game):
6. Standing colour mode also drives the accent (glow, tooltip strip) and the fill swatch.
7. Reputation bar takes the XP bar's place when the XP bar is hidden at max level.
8. Draw-layer swap only when the top segment changes.
9. Tooltip values slightly larger than labels (emphasis without a bold font file).
10. Preview card tall enough for size-40 bars with size-18 text; open menus close on scroll; scroll indicator on long menus; colour-wheel drags throttled; preview bars redrawn once per change.
11. /played: requested at login and level-up only; chat frames restored only where they were registered.
12. Blizzard XP/rep bar: hidden with Hide (no invisible mouse catcher), re-hidden if the game shows it, alpha/visibility restored only if Odyssey changed it.
13. Dead code: `account` merge in Options.
