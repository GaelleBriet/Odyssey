# Odyssey profiles — implementation plan

> Executed inline; spec `docs/superpowers/specs/2026-10-06-odyssey-profiles.md`.

1. `Profiles.lua` (pure, on the db table) + tests.
2. `Defaults` v4 migration + tests (existing v1–v3 migration tests updated to the profile layout).
3. `Core`: `ns.Settings()` through the active profile; profile switches re-merge defaults.
4. `Options`: "Profiles" section (menu, input, confirm buttons), remove "per character"; locales; tests.
