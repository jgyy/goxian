# Goxian: Xianxia Text Adventure — Design

## Overview

Goxian is a narrative-branching text adventure set in a xianxia (Chinese
cultivation fantasy) world, built in Godot 4 (GDScript). Before the story
begins, the player builds a **fate profile** — a set of character-creation
choices (gender, background, spiritual root, and more) picked from
templates. During play, the player reads story text (personalized by
their fate profile via text substitution), views a stylized procedural
scene backdrop, and picks from a list of choices each turn. Choices can
set narrative flags, and both story text and choice availability can vary
by fate-profile values. There are no numeric combat stats, inventory, or
turn-based combat — cultivation ranks and power are narrative flavor, not
systems, for this MVP.

## Goals (MVP)

- A character-creation screen with **12 fate factors** (see "Fate Profile"
  below), each offering a template list of options, all player-picked.
- Playable single story arc (~10-20 nodes) covering an intro beat: e.g. a
  young outsider seeks to join a cultivation sect, faces a test, and the
  arc ends in one of 2-3 outcomes depending on earlier choices and fate
  profile.
- Story text is personalized per fate factor via `{slot}` template
  substitution (see "Text personalization" below) — not fully separate
  hand-written variants per combination, which would be combinatorially
  infeasible to author.
- Fully data-driven: writing new content, new fate factors, or new flavor
  snippets means editing JSON, not code.
- Procedural scene art (no external image assets) that reacts to a
  per-node "backdrop" key.
- Save/continue single playthrough (JSON save of fate profile + current
  node + flags).

## Non-goals (explicitly out of scope for MVP)

- Numeric combat stats (HP/attack/defense), leveling, turn-based combat,
  inventory/equipment systems.
- Fate factors influencing anything beyond text flavor and simple
  choice-gating (no hidden success/failure rolls derived from them).
- Typed command parser.
- Multiple concurrent save slots or multiple simultaneous characters.
- Audio/music.
- Real illustration assets (photographic/painted art).

## Fate Profile (character creation)

Twelve factors, each defined in `story/fate_factors.json` as a list of
selectable options with an id, a display label, and a short flavor
snippet used for text substitution:

1. `gender` — Male / Female / Non-binary
2. `age` — Child / Youth / Young Adult / Middle-aged / Elder
3. `background` — Orphan / Merchant Family / Farming Family / Fallen
   Noble House / Wandering Performer / Scholar's Household
4. `spiritual_root` — Fire / Water / Wood / Metal / Earth / Heretical
   (multi-element) / Void (rare, near-zero root)
5. `wealth` — Destitute / Modest / Comfortable / Wealthy / Hidden Fortune
6. `moral_alignment` — Righteous / Pragmatic / Ruthless / Compassionate /
   Detached
7. `species` — Human / Half-Spirit-Beast / Demonic Bloodline /
   Reincarnated Soul
8. `birth_location` — Remote Mountain Village / Bustling City / Sect
   Territory / Borderlands Near Wilds / Floating Trade Barge
9. `family_relationships` — Loving Family / Estranged Family / Sole
   Survivor / Large Clan Obligations / Adoptive Family
10. `fengshui_omen` — Auspicious Birth / Cursed Birth / Neutral / Twin-Star
    Omen (marked for a great rival or ally) / Unreadable Fate
11. `appearance` — Striking / Plain / Unsettling / Delicate / Imposing
12. `talent_aptitude` — Slow but Steady / Prodigy / Late Bloomer /
    One-Trick Genius (excels narrowly) / Balanced

Each option's flavor snippet is a short phrase or clause (not a full
sentence) meant to be substituted into a `{slot}` placeholder inside story
node text, e.g. the `spiritual_root` option `fire` has snippet
`"warmth radiates faintly from your core, like a banked coal"`.

The player picks one option per factor on a single character-creation
screen (12 dropdown/option-button rows + a "Begin" button). All 12 are
player-selected — no random rolling for MVP (a "random fate" convenience
button, filling all 12 randomly, is a reasonable *optional* addition but
not required for MVP; if included it must still let the player review/
change the roll before confirming).

## Architecture

### Components

0. **Fate factor data (`res://story/fate_factors.json`)**
   ```json
   {
     "spiritual_root": {
       "label": "Spiritual Root",
       "options": [
         { "id": "fire", "label": "Fire", "snippet": "warmth radiates faintly from your core, like a banked coal" },
         { "id": "water", "label": "Water", "snippet": "a cool stillness pools beneath your ribs" }
       ]
     }
   }
   ```
   Loaded once by `ProfileManager` to populate the character-creation
   screen and to resolve `{slot}` substitutions later.

1. **Story data (`res://story/*.json`)**
   One JSON file per arc. Each file is a map of `node_id -> node`. Node
   text may contain `{factor_id}` placeholders (e.g. `{spiritual_root}`,
   `{background}`) that get replaced with the player's chosen option's
   flavor snippet at render time:
   ```json
   {
     "start": {
       "text": "Dawn mist curls around the stone steps... You feel it even now: {spiritual_root}.",
       "backdrop": "mountain_gate",
       "choices": [
         { "label": "Approach boldly", "next": "gate_bold" },
         { "label": "Wait and observe", "next": "gate_wait", "set_flags": {"cautious": true} }
       ]
     },
     "gate_bold": {
       "text": "...",
       "backdrop": "mountain_gate",
       "choices": [ ... ]
     }
   }
   ```
   - A node's `choices` list is filtered at display time: a choice may
     have an optional `requires_flag` (checks the `flags` dictionary set
     by earlier choices) **or** `requires_profile` (checks a fate-profile
     factor value, e.g. only show a choice if `spiritual_root == "heretical"`)
     — both use the same `{name, equals}` shape so one filter function
     handles either.
   - A node with an empty `choices` list is an ending; the UI shows
     "The End" and a "Return to Menu" option instead of choice buttons.

2. **`ProfileManager` (autoload singleton, `profile_manager.gd`)**
   - Loads `fate_factors.json` on startup.
   - `get_factors() -> Dictionary` — the parsed factor definitions, used
     by the character-creation screen to build its UI.
   - Holds `profile: Dictionary` (factor id -> chosen option id) once
     character creation completes.
   - `get_snippet(factor_id: String) -> String` — returns the flavor
     snippet for the player's chosen option of that factor (used for
     `{slot}` substitution).
   - `apply_template(text: String) -> String` — replaces every
     `{factor_id}` occurrence in `text` with `get_snippet(factor_id)`.

3. **`StoryManager` (autoload singleton, `story_manager.gd`)**
   - Loads and parses the arc JSON on `start_arc(arc_name)`.
   - Holds `current_node_id: String` and `flags: Dictionary`.
   - `get_current_node() -> Dictionary` — returns node data with choices
     pre-filtered by flag/profile requirements, and `text` already run
     through `ProfileManager.apply_template()`.
   - `choose(choice_index: int)` — applies `set_flags` from the chosen
     choice, advances `current_node_id`, emits `node_changed` signal.
   - `save_game()` / `load_game()` — writes/reads a small JSON
     (`{arc, current_node_id, flags, profile}`) to `user://save.json`.
     (`profile` is persisted here too, via `ProfileManager.profile`, so a
     continued game keeps the same fate profile.)

4. **`SceneArt` (Control scene, `scene_art.gd`)**
   - Takes a `backdrop` key (e.g. `"mountain_gate"`, `"bamboo_forest"`,
     `"sect_hall"`) and procedurally draws a simple layered scene using
     `_draw()`: gradient sky, silhouette shapes (mountains, roofs, trees,
     moon/sun), no external image files.
   - Backdrop keys map to small drawing "recipes" defined in a lookup
     table in the script — easy to add a new backdrop by adding a key and
     a draw recipe.

5. **`CharacterCreation` (`character_creation.tscn`/`.gd`)**
   - Built dynamically from `ProfileManager.get_factors()`: one row per
     factor (label + `OptionButton` of choices), plus a "Begin Journey"
     button.
   - On confirm, sets `ProfileManager.profile` from the selected options,
     then transitions to `GameScreen` (after `StoryManager.start_arc(...)`
     is called).

6. **`GameScreen` (main gameplay scene, `game_screen.tscn`/`.gd`)**
   - Layout: `SceneArt` panel (top ~40% height), `RichTextLabel` story log
     (scrollable, shows current node text, and appends past text so the
     player can scroll back), and a `VBoxContainer` of choice buttons
     (bottom).
   - Listens to `StoryManager.node_changed`, re-renders text/art/choices.
   - Button press calls `StoryManager.choose(index)`.

7. **`MainMenu` (`main_menu.tscn`/`.gd`)**
   - "New Game" (goes to `CharacterCreation`), "Continue" (enabled only if
     a save exists; loads profile + story state directly into
     `GameScreen`), "Quit".

### Text personalization

Node `text` strings may reference any of the 12 factor ids as
`{factor_id}` placeholders. `ProfileManager.apply_template()` does a
straightforward string replacement pass — no nested logic — so authors
write natural sentences with a snippet dropped in, e.g.:

> "You grip the trial stone. Even now, {spiritual_root} You wonder if
> Elder Wren can sense it too."

This keeps authoring linear (one sentence template per node, not 12+
branches) while still making every playthrough read as personalized.
Nodes are **not required** to use any placeholders — most of the intro
arc's nodes can be generic, with placeholders concentrated at a handful of
"reflective" beats where personalization reads naturally (e.g. right after
the trial stone, or when asked to state a reason for seeking the Dao).

### Data flow

```
MainMenu -> CharacterCreation (ProfileManager.profile set) -> StoryManager.start_arc() -> GameScreen
MainMenu -> (Continue) -> StoryManager.load_game() (restores profile + flags + node) -> GameScreen
GameScreen reads StoryManager.get_current_node() (already templated) -> renders SceneArt + text + choices
Player clicks choice -> StoryManager.choose(i) -> node_changed signal -> GameScreen re-renders
On ending node -> GameScreen shows end screen -> back to MainMenu
```

### Error handling

- If a JSON arc file fails to parse or a `next` id doesn't exist in the
  arc, `StoryManager` logs an error via `push_error` and falls back to a
  built-in "story data error" node so the game doesn't crash to a black
  screen.
- If `fate_factors.json` fails to parse, `ProfileManager` logs an error
  and falls back to a minimal built-in factor set (`gender`, `background`)
  so character creation is never a dead end.
- If a node's text references a `{factor_id}` not present in
  `fate_factors.json` (e.g. a typo), `apply_template` leaves the
  placeholder text as-is and logs a warning, rather than crashing.
- Save load validates the loaded node id still exists in the arc; if not,
  restarts the arc from `"start"`. It also validates every saved profile
  factor id/option id still exists in `fate_factors.json`; unknown ones
  are dropped (so a future content edit doesn't corrupt an old save).

## Architecture

### Components

1. **Story data (`res://story/*.json`)**
   One JSON file per arc. Each file is a map of `node_id -> node`:
   ```json
   {
     "start": {
       "text": "The gates of Azure Cloud Sect rise before you...",
       "backdrop": "mountain_gate",
       "choices": [
         { "label": "Approach boldly", "next": "gate_bold" },
         { "label": "Wait and observe", "next": "gate_wait", "set_flags": {"cautious": true} }
       ]
     },
     "gate_bold": {
       "text": "...",
       "backdrop": "mountain_gate",
       "choices": [ ... ],
       "requires_flag": null
     }
   }
   ```
   - A node's `choices` list is filtered at display time: a choice may
     have an optional `requires_flag` (only shown if that flag is set/unset
     as specified) so later content can react to earlier decisions.
   - A node with an empty `choices` list is an ending; the UI shows
     "The End" and a "Return to Menu" option instead of choice buttons.

2. **`StoryManager` (autoload singleton, `story_manager.gd`)**
   - Loads and parses the arc JSON on `start_arc(arc_name)`.
   - Holds `current_node_id: String` and `flags: Dictionary`.
   - `get_current_node() -> Dictionary` — returns node data with choices
     pre-filtered by flag requirements.
   - `choose(choice_index: int)` — applies `set_flags` from the chosen
     choice, advances `current_node_id`, emits `node_changed` signal.
   - `save_game()` / `load_game()` — writes/reads a small JSON
     (`{arc, current_node_id, flags}`) to `user://save.json`.

3. **`SceneArt` (Control scene, `scene_art.gd`)**
   - Takes a `backdrop` key (e.g. `"mountain_gate"`, `"bamboo_forest"`,
     `"sect_hall"`) and procedurally draws a simple layered scene using
     `_draw()`: gradient sky, silhouette shapes (mountains, roofs, trees,
     moon/sun), no external image files.
   - Backdrop keys map to small drawing "recipes" defined in a lookup
     table in the script — easy to add a new backdrop by adding a key and
     a draw recipe.

4. **`GameScreen` (main gameplay scene, `game_screen.tscn`/`.gd`)**
   - Layout: `SceneArt` panel (top ~40% height), `RichTextLabel` story log
     (scrollable, shows current node text, and appends past text so the
     player can scroll back), and a `VBoxContainer` of choice buttons
     (bottom).
   - Listens to `StoryManager.node_changed`, re-renders text/art/choices.
   - Button press calls `StoryManager.choose(index)`.

5. **`MainMenu` (`main_menu.tscn`/`.gd`)**
   - "New Game" (starts arc fresh), "Continue" (enabled only if a save
     exists), "Quit".

### Data flow

```
MainMenu -> StoryManager.start_arc()/load_game() -> GameScreen
GameScreen reads StoryManager.get_current_node() -> renders SceneArt + text + choices
Player clicks choice -> StoryManager.choose(i) -> node_changed signal -> GameScreen re-renders
On ending node -> GameScreen shows end screen -> back to MainMenu
```

### Error handling

- If a JSON arc file fails to parse or a `next` id doesn't exist in the
  arc, `StoryManager` logs an error via `push_error` and falls back to a
  built-in "story data error" node so the game doesn't crash to a black
  screen.
- Save load validates the loaded node id still exists in the arc; if not,
  restarts the arc from `"start"`.

### Testing approach

Godot has no bundled unit test framework by default. For this project:
- A lightweight GDScript sanity-check script (run via `--headless` from
  the command line) that loads every arc JSON file and verifies: every
  `next`, flag, and profile-factor reference points to a real
  node/flag/factor+option, every node is reachable from `start`, and
  every non-empty-choices node has at least one valid (non-gated-into-
  impossibility) path forward. It also validates `fate_factors.json`
  itself: every factor has at least one option, every option has a
  non-empty snippet. This catches broken story/profile data early without
  needing a full test framework.
- Manual playtesting of character creation + the arc's branches for the
  MVP acceptance check, spot-checking a few different fate-profile
  combinations to confirm `{slot}` substitution reads naturally.

## Project structure

```
goxian/
  project.godot
  autoload/
    story_manager.gd
    profile_manager.gd
  scenes/
    main_menu.tscn / .gd
    character_creation.tscn / .gd
    game_screen.tscn / .gd
    scene_art.tscn / .gd
  story/
    intro_arc.json
    fate_factors.json
  tools/
    validate_story.gd   # headless story/profile-data sanity checker
```

## Open questions / future extensions (not MVP)

- Adding real cultivation stats/systems later would layer on top of the
  flag dictionary (flags could hold numeric values, not just booleans) —
  the JSON schema already supports arbitrary flag values.
- A "random fate" convenience button on character creation (randomize all
  12 factors, reviewable before confirming) is a natural fast-follow but
  not required for MVP.
- Real illustrated art could later replace `SceneArt`'s procedural
  drawing by swapping in a `TextureRect` keyed the same way by backdrop
  id, without changing story data or StoryManager.
- Deeper personalization (multiple snippets per factor combined, or
  factor combinations unlocking unique paragraphs rather than single
  clauses) could be layered onto `apply_template` later without changing
  the JSON schema.
