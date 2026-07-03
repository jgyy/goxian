# Goxian

A narrative-branching xianxia (Chinese cultivation fantasy) text adventure, built in Godot 4.

Before the story begins, you build a **fate profile** — 12 factors (gender,
age, background, spiritual root, wealth, moral alignment, species, birth
location, family relationships, fengshui omen, appearance, talent aptitude)
picked from templates. Story text is personalized to your profile, and some
choices only appear depending on your fate. There are no numeric stats,
inventory, or combat — this is pure narrative branching.

## Requirements

- [Godot 4.x](https://godotengine.org/download) (developed against 4.7)

## Running the game

Open the project folder in the Godot editor and press F5, or from the
command line:

```bash
godot --path . 
```

## Project structure

```
goxian/
  project.godot
  autoload/
    story_manager.gd      # loads story arcs, tracks node/flags, save/load
    profile_manager.gd     # loads fate factors, holds player's profile, {slot} templating
  scenes/
    main_menu.tscn/.gd         # New Game / Continue / Quit
    character_creation.tscn/.gd # 12-factor fate profile picker
    game_screen.tscn/.gd        # story log + choice buttons
    scene_art.tscn/.gd          # procedural (no image assets) backdrops
  story/
    intro_arc.json         # story content: nodes, choices, branching
    fate_factors.json      # the 12 fate factors and their options/flavor text
  tools/
    validate_story.gd      # headless checker for story/fate-factor data
```

## Writing new story content

Story arcs and fate factors are plain JSON — no code changes needed to add
content. After editing `story/*.json`, validate it with:

```bash
godot --headless --script res://tools/validate_story.gd
```

This checks that every choice points to a real node, every node is
reachable, every `requires_profile`/`{slot}` reference resolves to a real
fate factor and option, and every fate factor has at least one option with
a non-empty flavor snippet.

## Design docs

- [Design spec](docs/superpowers/specs/2026-07-03-xianxia-text-adventure-design.md)
- [Implementation plan](docs/superpowers/plans/2026-07-03-xianxia-text-adventure.md)
