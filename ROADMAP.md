# Roadmap — slash-dash-slash

Build order. Each milestone is a *demoable build state* answering one specific question. Specs map to milestones. Reorder freely as we learn things.

Conventions:
- Each milestone lists its specs and the **question** it answers (does this *feel* right? does the loop close? etc.).
- Content specs (rosters) often appear *initially* in an early milestone with a tiny set, then *fully* in a later expansion milestone.
- A milestone is "done" when its question can be answered yes by playing the build, not when its specs are merged.
- Numbering is preserved across deletions so cross-references stay stable.

**Completed:** M1 Foundations · M2 Dash skeleton · M3 Combat verb · M4 First enemy AI · M5 Equipment basics · M6 First gem · M8 Amulet gems · M10 (interaction-system half). See git history + `specs/` for the shipped specs.

---

## M7. Gem combos + mega
*Is the combo layer compelling — does landing a 2-element proc feel like a moment?*
- `gem-combo-proc`
- `gem-combo-content` (initial: a handful of combos)
- `gem-mega-combo` (mechanic + 1 mega effect)

## M9. Arena with threat escalation
*Is sustained combat across a ~2-minute escalation satisfying?*
- `level-scene-base`
- `threat-escalation`

## M10. Universal props (the rest)
*Does the prop set deliver beyond the water cooler — vending machine drops loot, filing cabinet upgrades, etc.?*
- `universal-props`

## M11. Look generator + first speaking NPC
*Does the world feel alive — random workers, speech bubbles, character clack?*
- `look-generator`
- `speaking-system-bubbles`
- `speaking-audio-clack`

## M12. Cutscene engine + opening cinematic
*Does the narrative framing land — does the opening set the tone in under 30s?*
- `cutscene-engine`
- `cutscene-opening`
- `pa-voice-system` (basic: per-floor PA palette playing)

## M13. Floor B prototype (one complete floor)
*Is a single full floor — start to boss — satisfying?*
- `floor-content-b`
- `enemy-content-floor-b`
- `boss-base`
- `boss-archives`
- `floor-transition` (placeholder destination)

## M14. Quest system + Floor B quests
*Do quests add meaningfully to the floor — main quest gates boss, side quests reward exploration?*
- `quest-system`
- `quest-content-floor-b`

## M15. In-run upgrade draft
*Does progression feel earned — do upgrade cards offer real, distinct choices?*
- `upgrade-types`
- `upgrade-card-draft`
- `upgrade-rarity-system`
- `upgrade-magnitude-formulas`
- `upgrade-eligibility`

## M16. Procedural variation on Floor B
*Does randomized object placement keep replays fresh without sprawling?*
- `procgen-positions`

## M17. Save state + Pawn ending
*Does meta-state persist correctly? Is the Pawn ending readable as the bad-because-compliant path?*
- `save-state`
- `ending-pawn`
- `cutscene-pawn-ending`

## M18. Full equipment + gem rosters
*Does the build space feel rich — do enough swords/amulets/gems exist for varied replays?*
- Expand `equipment` (sword + amulet rosters), `gems` (amulet-gem roster), `gem-combo-content` to full intended catalog. (Weapon-gem roster already shipped at full catalog in M6.)

## M19. Floor 1 + Manager boss
*Does the second floor feel distinct from the first — different enemies, theme, quest, boss continuity?*
- `floor-content-1`
- `enemy-content-floor-1`
- `boss-manager`
- `quest-content-floor-1`

## M20. Floor 7 + boss
*Does the third floor keep the escalation going?*
- `floor-content-7`
- `enemy-content-floor-7`
- `boss-floor-7`
- `quest-content-floor-7`

## M21. Floor 13 + final boss
*Does a complete B → 1 → 7 → 13 run land?*
- `floor-content-13`
- `enemy-content-floor-13`
- `boss-floor-13` (no promoter overlay yet)
- `quest-content-floor-13`

## M22. Achievements + sword/amulet unlocks
*Does meta progression motivate replays?*
- `achievement-system`
- `sword-unlock-conditions`
- `amulet-unlock-conditions`

## M23. Persistent shortcuts
*Are shortcuts a real reward — door state changes, drop compensation balanced, no UI noise?*
- `shortcut-mechanic`
- `shortcut-content`

## M24. Worker ending + boss-promoter overlay
*Does the cycle close — defeat boss, touch gem, next run's boss IS the previous winner, world is harder?*
- `ending-worker`
- `world-state-modifiers`
- `boss-promoter-overlay`
- `cutscene-gem-speech`
- `cutscene-worker-ending`

## M25. Two Weeks' Notice subquest
*Does the form → pen → stamp chain feel coherent and bureaucratic? Does the executive elevator door open visibly?*
- `two-weeks-notice-subquest`

## M26. Runaway + TRUE endings
*Does the full ending loop close — Runaway exits cleanly; TRUE destroys the gem and reverts the world?*
- `ending-runaway`
- `ending-true`
- `cutscene-runaway-ending`
- `cutscene-true-ending`

## M27. Audio direction full pass
*Does the soundscape carry the mood — warped muzak degrades on threat, refined SFX palette across all floors?*
- `audio-music-bed`
- `audio-sfx-palette` (refined)

## M28. Polish + tuning
*Is the game ship-shape on mobile?*
- Number tuning across all systems
- Visual polish pass
- Mobile mix validation
- Final procgen variety pass

---

## Reading the build order

- **Through M8** (complete) — input, dash, combat verb, enemy AI, equipment + selection, weapon gems with combo dispatch, amulet gems. The combat identity exists and is testable.
- **M7, M9–M12** — gem combos with real content, arena escalation, remaining props, NPCs + speech, opening cutscene. The world starts to exist around the combat.
- **M13–M16** — Floor B as the prototype. Quests, upgrades, procgen variation. By end of M16 the *micro loop* is testable end-to-end.
- **M17–M18** — save state, first ending, full rosters. Replay value emerges.
- **M19–M21** — full vertical slice. By end of M21 the *macro arc* is playable.
- **M22–M26** — unlocks, shortcuts, all endings. By end of M26 the game is *narratively complete*.
- **M27–M28** — audio richness, tuning, mobile validation.

## Notes

- **Spec splitting**: some specs may merge in practice (e.g., `gem-combo-proc` + `gem-combo-content` if they fit one effort). Don't be precious.
- **Content specs are easy to defer or expand**: M7/M8 ship with tiny rosters; M18 expands. Don't block early milestones on content breadth.
- **Question over checklist**: a milestone is done when the demo question can be answered yes. If specs are merged but the feel is wrong, milestone isn't done.
- **Reorder permissively**: if M9 feels needed before M7 to validate combat against waves, swap. The order here is a starting hypothesis.
