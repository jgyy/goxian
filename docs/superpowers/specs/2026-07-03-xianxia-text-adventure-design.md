# Goxian: Xianxia Text Adventure — Design

## Overview

Goxian is a narrative-branching text adventure set in a xianxia (Chinese
cultivation fantasy) world, built in Godot 4 (GDScript). The player reads
story text, views a stylized procedural scene backdrop, and picks from a
list of choices each turn. Choices can set narrative flags that alter later
text or unlock different story branches/endings. There are no numeric
stats, inventory, or combat — cultivation ranks and power are narrative
flavor, not systems, for this MVP.

## Goals (MVP)

- Playable single story arc (~10-20 nodes) covering an intro beat: e.g. a
  young outsider seeks to join a cultivation sect, faces a test, and the
  arc ends in one of 2-3 outcomes depending on earlier choices.
- Fully data-driven: writing new content means editing JSON, not code.
- Procedural scene art (no external image assets) that reacts to a
  per-node "backdrop" key.
- Save/continue single playthrough (JSON save of current node + flags).

## Non-goals (explicitly out of scope for MVP)

- Cultivation stats, leveling, combat, inventory.
- Typed command parser.
- Multiple concurrent save slots.
- Audio/music.
- Real illustration assets (photographic/painted art).

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
  `next` and flag reference points to a real node/flag, every node is
  reachable from `start`, and every non-empty-choices node has at least
  one valid (non-flag-gated-into-impossibility) path forward. This catches
  broken story data early without needing a full test framework.
- Manual playtesting of the arc's branches for the MVP acceptance check.

## Project structure

```
goxian/
  project.godot
  autoload/
    story_manager.gd
  scenes/
    main_menu.tscn / .gd
    game_screen.tscn / .gd
    scene_art.tscn / .gd
  story/
    intro_arc.json
  tools/
    validate_story.gd   # headless story-data sanity checker
```

## Open questions / future extensions (not MVP)

- Adding real cultivation stats/systems later would layer on top of the
  flag dictionary (flags could hold numeric values, not just booleans) —
  the JSON schema already supports arbitrary flag values.
- Real illustrated art could later replace `SceneArt`'s procedural
  drawing by swapping in a `TextureRect` keyed the same way by backdrop
  id, without changing story data or StoryManager.
