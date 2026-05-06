# GDD — slash-dash-slash

A rapid, juicy action roguelike where dashing *is* attacking. One verb, deep mastery, set inside a 1970s corporate office that quietly contains real magic.

Living doc. Update freely; this is the anchor every spec checks against.

## Pillars

1. **Commitment is the verb.** Dash is the only input. Every dash is fully committed — no steering, no cancel, fixed distance. Mastery lives in aim, line-reading, route planning, and stamina — never reflex.
2. **Identity locks, intensity escalates.** Sword + amulet are chosen at run start and never change. In-run progression amplifies who you are; it doesn't rewrite you. Build identity is decided early; the run is about pushing it further.
3. **Flavor over numbers.** Base damage is single-digit. Identity comes from elemental crits, gem combos, and amulet effects — not from stat-stacking. There is no "+10 damage" lane.
4. **Handcrafted bones, procedural dressing.** Levels are learnable across runs. Procgen varies positions and details, never the structure. The world is reliable so the player can be surprised by their own decisions.
5. **No primary platform.** One-thumb touch, controller, and mouse+keyboard are equally first-class. Every design choice respects all three.

## Core Loop

**Moment (~10s).** The character flashes when the sword is loaded. Read enemy positions, pick a vector, dash. The sword damages everything in the path; a gem may proc into a crit; two gems combo into a super-effect. A non-hit dash repositions while the weapon reloads. Stamina caps consecutive hits — at some density, you're forced to break the streak. Walls are hard; corners are deadly.

**Minute (~1min).** Clear a wave or chunk of the floor. An upgrade card appears — lean further into your gems, take a new gem if a slot is open, bank a structural upgrade like a new amulet slot. Notice a side quest (kill a miniboss, destroy three tombstones, find a thing); pursue it now or save it.

**Run (~?min).** Four themed floors of an office building, each with its own enemy pool and main quest. Threat escalates within a floor and resets at the start of the next — explicit rest beats. Each floor has a main quest + 2 optional flavor quests with rewards, and ends in a boss who gates the elevator. Equipment is fixed; gems evolve. Death = restart from floor 1.

**Meta.** Swords unlock through global achievements. Amulets unlock through in-run achievements (defeat boss X, find Y on the map). Successful clears earn persistent shortcuts that shorten future runs (see below). Four endings exist (Pawn, Worker, Runaway, TRUE); the canonical "happy end" is TRUE, reachable only by completing the *Two Weeks' Notice* subquest and refusing the Dark Gem's offer (see *Endings* under Tone & References).

### Persistent shortcuts

Each floor (except Floor 13) has a single shortcut: a fixed door at the edge of the level, visible from run 1 but locked. Its visual state degrades as unlock conditions are met (chains rust, lock loosens, paint flakes) — no UI, no announcement. Discovery is the reward.

**Unlock condition** (per floor): cumulative across runs — every quest on that floor completed at least once *and* the player has progressed past it ≥N times (N is a tunable, default 5).

**Effect.** Using a shortcut transitions the player to the next floor via a staircase (instead of the standard elevator) and spawns them at a "backdoor" entrance — different starting room, neutral threat level, same difficulty. The only cost is missed loot.

**Drop compensation (cap reading).** Skipping a floor via shortcut tops the player up to **70%** of that floor's normal in-run drops, minus what they already collected on this run. Skip cold → get 70%. Already at 50% → get +20%. Already above 70% → get nothing. Meta-unlock progress (amulets, achievements) does **not** compensate — those require being there.

**Stacking.** Shortcuts chain (B → 1's backdoor, then 1's shortcut to 7's backdoor) but can never skip more than one floor per shortcut. A shortcut is always "skip this floor," never "skip ahead arbitrarily."

**Diegetic detail.** Each time the door opens, small environmental clues appear: a dirty handprint, a propped chair, cigarette ash. Implies another worker uses this path. Builds lore without UI.

**Audio.** The staircase has its own treatment: louder fluorescent hum, echoing footsteps, no music. The alternate path *feels* different.

## Tone & References

**Setting.** A 1970s-era accounting firm that is secretly a covert occult operations facility. Magic is real, and the office *bureaucratizes* it: sacred artifacts catalogued in HR's classified taxonomy, requisitioned via interoffice memo, audited by middle management. The gap between *sacred* and *stapled* is the dread engine.

**Premise.** Each run, the player wakes as a randomly-generated junior archive worker. A manager assigns them an inventory task: a mystic katana. An internal monologue notes the worker doesn't quite remember being hired, the desk feels unfamiliar, and the math of the day doesn't add up. The first input the player makes — any input — has the worker pick up the katana and slash. The fight begins. The corporation has no memory of prior runs and treats every worker as new; **bosses remember**, and their dialogue can reference past defeats. Bosses are *defeated*, never killed — they recur with cumulative memory across runs. The roguelite structure is diegetic: every run is a different employee, and the office has an inexhaustible supply.

The opening cutscene is skippable from run 2+. Worker name and one mundane detail (mug design, family photo on desk, etc.) randomize per run; manager dialogue and katana task are constant. Observant players can catch the variation.

**Mood.** Liminal corporate occult. Fluorescent hum, grainy yellow tint, dry humor riding on quiet dread. Mundane objects are the supernatural in disguise: water cooler = healing shrine, vending machine = loot box, filing cabinet = upgrade source. The horror is that no one finds any of it strange.

**Visual.** Pixel art. Grainy, slightly yellowish retro-office palette. Cutscenes are simple semistatic slides — a tiny in-engine system, not animation pipeline.

**References (spirit, not target):**
- *Vampire Survivors* — run structure, simplicity, escalating chaos.
- *Inscryption* — mystery, metafiction, mundane-becomes-eldritch.
- *Severance* — uncanny corporate space, ritualized work.
- *Control* — bureaucratized paranormal, brutalist mood.

Visual identity is original; these are vibes, not styling guides.

### Floors

Four floors, non-contiguous numbering. The skipped numbers signal that the building isn't really four floors — it's a slice the player is allowed to see. The floor numbers themselves track escalating awareness: how much the Building *notices* you.

1. **Floor B — The Archives.** Sub-basement. Endless filing cabinets, dot-matrix printers spitting forms with the player's name, dim flickering fluorescents. Lowest corporate tier: janitors, mail clerks, workers who've been here too long. Tutorial-feeling but unsettling. *The Building doesn't notice you yet — you're below notice.* Signature object: paper shredder. Ambient: distant intercom paging.
2. **Floor 1 — The Cubicle Farm.** Severance-style open-plan. Identical workstations, beige and grey, the longer the fight, the more the cubicles seem to repeat. Coworker drones, accountants, photocopier-spawned doppelgangers. *The Building processes you as routine.* Signature object: photocopier. Ambient: cheery intercom voice with normal announcements. **Boss: The Manager** — the same one who assigned the katana task on Floor B, now pursuing the player personally after their escape from the archives.
3. **Floor 7 — Middle Management.** Wood paneling, name placards, closed conference-room doors with rituals visible through the slats. HR enforcers, audit teams, suited security. *The Building has flagged you — irregularities reported.* Signature object: conference table. Ambient: terse executive memo voice over PA.
4. **The 13th Floor — The Board.** Not on the directory. Brutalist or impossibly-large boardroom; the city view through the windows is wrong. The long table seats things you don't want to see. *The Building addresses you directly.* Signature object: the table itself. Ambient: distorted, the announcement voice now speaks to you by name. Endings happen here.

Universal props (water cooler heal shrine, vending machine loot box) appear on every floor but their visual treatment shifts: normal on Floor 1, slightly wrong on 7, openly hostile on 13.

### Audio direction

**Music bed.** Warped 1970s library music / muzak. Each floor has its own track — beige instrumentals, elevator jazz, hold-music vibes — that *degrades* as threat escalates within the floor (cassette warble, slowing, layers dropping out) and resets clean at floor transition. The track itself encodes escalation; combat does not get its own song. The office's own ambient just gets *worse*.

**SFX is the juice.** Dash is the entire input vocabulary, so its audio carries the game.
- **Sword-loaded chime** — audio twin of the color flash. Short, distinct, satisfying.
- **Per-element crit signatures** — fire sizzle, water drip, ice crack, wind gust, metal clang, lightning zap. Each gem proc is identifiable by ear alone.
- **Combo proc** — procedural blend of the two element sounds.
- **Mega combo (3+)** — single, thick, memorable chord-like hit.
- **Armor feedback** — front-armor "thunk" (stops short) vs back "splat" (clean kill). Teaches directional armor without UI.
- **Stamina exhausted** — soft heartbeat / alarm thump.
- **Wall stop** — sharp, anticlimactic. Failure has a sound.

**Voice / PA.** All per-floor announcements are muffled / behind-walls treated — preserves mystery, dodges voice-acting scope. Floor 13's clarity (addresses the player by name) hits harder by contrast. No real VO; processed TTS or vocal samples.

**Mix priority.** Cross-platform demands clarity over richness. Sharp transients, distinct frequency bands per element, no muddy sub-mixes. Test on a phone speaker, not headphones.

**Mood references (vibe, not sourcing).** Late-night radio in an empty office; dial-tone hold music; the demo loop on a hardware-store cassette; *Twin Peaks*'s Audrey theme at half speed.

### Endings

The game has multiple endings. Each is a slide-cutscene; reaching one does not end persistent meta-state — the player can keep running.

**1. Pawn ending.** Sit still 5 minutes from the start of a run, taking *no input whatsoever*. The first move (dash, menu interaction, anything) locks this ending out for the run; it can only be attempted again on a fresh run. The manager (and the corporation) becomes pleased; the worker is processed as compliant. The act of *playing* is the act of refusing this ending.

**2. Worker ending.** Defeat the Floor 13 boss. The boss arena's doors immediately lock and a **Dark Gem** appears in the room. It speaks, proposing the worker take its place as the new boss by touching it. The room offers no other interaction.
- Touching the gem → **Worker ending**: the worker becomes the next Floor 13 final boss. On subsequent runs, the boss takes this worker's name and visual identity (most recent overwrites; never a chimera of multiple winners). *(Stretch: partial ability transfer; locked at visuals/name only for v1.)* The world also becomes permanently harder — all enemies and bosses gain strength.
- **Refusing to touch the gem is an intentional softlock.** The doors do not open; nothing else interacts. The player must quit to the menu. This is a tonal feature: the corporation traps compliance. The only escape from the room is the path that bypasses this trap entirely (see TRUE ending).

**3. Runaway ending.** Complete the *Two Weeks' Notice* subquest within a run, then take the **private executive elevator** down from Floor 7. Bypasses the final boss entirely — the corporation simply releases you. Requires the subquest unlocked (one prior Worker ending).

**4. TRUE ending.** Complete the same subquest, but instead of taking the executive elevator down, take the regular elevator up to Floor 13 and fight the final boss. With stamped paperwork carried, the Dark Gem becomes vulnerable: slashing it destroys it → **TRUE ending** — the canonical real happy end. The game is over.
- Post-TRUE: the world reverts to its normal state. Enemies return to base strength, the Floor 13 final boss is restored, the worker-overwrites-boss chain resets. TRUE ending is preserved as a permanent unlock; replay is free-play.

#### *Two Weeks' Notice* subquest

Unlocked after the player's first Worker ending. The subquest must be completed entirely within a single run; nothing carries between runs. Strict sequence — each step gates the next.

1. **Find the Form** on **Floor B**. A "Form 1099-2W: Notice of Resignation" — manila envelope on a randomized desk, visually distinct, no UI marker. Player picks it up; carried for the rest of the run.
2. **Find the Pen** on **Floor 1**. A specific resignation pen — fountain pen on a leather desk pad, single instance per run, randomized desk among the cubicle sea. Picking it up while carrying the form triggers an automatic signing animation. Form is now *signed*.
3. **Stamp at HR Outbox** on **Floor 7**. A fixed-location desk. Interacting stamps the form. Form is now *stamped*.

After stamping, the **private executive elevator** (a second elevator door, physically adjacent to the HR Outbox) becomes operable. The player now has two visible doors:
- Private executive elevator → Runaway ending
- Standard elevator up → Floor 13 boss → Dark Gem (vulnerable) → TRUE ending

**Diegetic world reaction (PA voice).** The PA on each floor reacts as the subquest progresses:
- On form pickup: faintly murmurs an HR memo about separation paperwork.
- On signing: the voice glitches mid-announcement; tone shifts from cheery to wary.
- On stamping: the voice addresses the worker by job title — *"Junior Archivist, please report to HR for exit interview"* — distorted.

Worker enemies may also briefly pause and stare when encountering a player carrying signed or stamped paperwork. Pure flavor; no combat impact.

#### Persistent meta-state introduced by endings

The save file must carry, across runs:
- Pawn ending unlocked (boolean)
- Worker ending count + most recent winning worker's name/visuals → drives next final boss identity
- World-harder modifier active (boolean) → set by any Worker ending, cleared by TRUE ending
- Two Weeks' Notice subquest unlocked (boolean) → set after first Worker ending
- Runaway ending unlocked (boolean)
- TRUE ending reached (boolean) → free-play mode

## Supporting systems

System-direction notes — not full specs, but the pitched shapes for the engine pieces every other system depends on. Each becomes a spec when picked up. Recommended build order: Look Generator → Interaction → Speaking → Cutscene.

### Character look generator

Drives every randomized worker (player protagonist each run, NPC drones) and the corrupted-promotion overlay on Worker-ending bosses. Layered pixel-art sprite: base body, hair (style + color), glasses, shirt (color + pattern), pants, one accessory. Random combination per run. The same params produce both an in-world sprite and a cutscene portrait. Procedural names from a corporate-bland first × last table; one randomized desk detail (mug, photo) for the opening.

A **boss-promoter overlay** takes a stored worker's params and adds corruption layers (warped suit, shadow effects, scale-up, executive accessories). Same generator powers both the worker who killed last run's boss and next run's boss. Diegetic continuity for the cycle.

### Interaction system — *dash IS interact*

Pillar 1 says dash is the only verb, so interaction is dash-based. Interactable nodes carry an `Interaction` resource defining `on_dash_into` behavior:
- Form / pen → pickup
- HR Outbox → stamp form
- Water cooler → heal
- Vending machine → drop loot
- Door / elevator → open / use
- Dark Gem → destroyed if vulnerable, touch-promotes-to-boss if not

NPCs are flagged non-hostile and dash-immune; dashing into them triggers dialogue instead of damage. The Dark Gem dual-state is the proof of the pattern: same input, different outcome based on game state (paperwork). One verb, one input, every ending.

### Speaking system

**Cutscene speech** lives inside the cutscene engine (typewriter text). **In-world speech** is a small floating speech bubble above NPCs, bosses, the Dark Gem — auto-positioned, auto-dismissed. Used for boss banter, dialogue triggered by dash-interact, manager mid-fight quips.

**Speech audio**: per-character pitched clack track — letters bleat as text reveals (Animal Crossing / Banjo style). Each archetype has a voice palette: high coworker, low manager, distorted gem, garbled PA. No real words; tonal only. Cheap, on-brand, scales infinitely.

### Cutscene engine

Linear slide sequences only — no branching, no animated portraits, no video. A `Cutscene` resource defines an ordered list of slides. Each slide carries: image (full-screen or framed), speaker tag, dialogue text (typewriter reveal), one audio cue, advance condition (input or auto-timer). A small `CutscenePlayer` scene reads the resource and walks slides; tap advances, long-press skips. Simple fade between slides.

Used for: opening (every run, skippable from run 2+), each of the 4 ending sequences, the Dark Gem speech in the boss room (doors lock — cutscene territory). Form-pickup auto-sign can be a 1-slide cutscene if needed. Out of scope: branching dialogue, animated portraits, video.

## Non-goals

- **Not procgen-first.** Levels are crafted; procgen is dressing.
- **Not narrative-heavy.** Lore is mood and mystery — no long dialogue, no exposition dumps. Story emerges through environment, slides, and endings.
- **Not multi-button combat.** Dash is the only input. No second weapon, no abilities, no parry, no block.
- **Not numbers-stacking.** Builds differ in flavor, not arithmetic.
- **Not multiplayer or co-op.** Single-player only.
- **Not high-fidelity.** Pixel art, low fidelity by design.
- **Not platform-exclusive.** No platform is "primary"; none is an afterthought.

## Deferred / open

Tracked here so the parking lot is visible. Each becomes a spec when picked up.

- Specific sword roster + their special abilities and splash sizes
- Specific amulet roster + their unique gem effects
- Element-pair super-effect content (21 combinations) and the single 3+ "mega" effect
- Specific gem upgrades (per-element bespoke upgrades, type #7)
- Upgrade magnitude formulas (rarity → effect size)
- Upgrade offering logic (frequency, draft size, eligibility ordering)
- Per-floor enemy roster and main/flavor quest content (themes now locked)
- Boss roster and bespoke behaviors
- Combat tuning numbers (dash distance, weapon cooldown, stamina rate)
