# Odyssey leveling tools — implementation plan

> Executed inline; design validated in chat (research ideas 1, 3, 4, 5, 11).

1. Probe: faction list/watch APIs, IsResting, combat/instance/death checks, chat insertion, character pane, sounds.
2. Pure logic + tests: chat progress lines (`Texts.chatLine`), quest level-up detection and level-up summary (`Alerts`), visibility conditions (`Visibility`), rested timing and alt estimates (`Calc.restedTiming`, `Characters`), backup/restore (`Backup`).
3. Settings: per-bar `combatMode`, `instanceMode`, `hideWhenDead`, `strata`, `clickThrough`; profile `alerts`; per-character saved variable `OdysseyCharDB`.
4. Bar: Shift+click to chat, left-click rep → Reputation pane, right-click context menu (settings, watched faction), quest pulse, resting tint, conditions, strata, click-through.
5. Tooltip: click hint line, rested block and alts list (Shift view).
6. Core: events (combat, zone, death, resting, logout), level-up summary, rest reminder, alts recording, backup/restore at load.
7. Options + locales; docs.
