# Xianxia Text Adventure Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a playable Godot 4 xianxia text-adventure MVP: character creation with a 12-factor fate profile, a data-driven choice-based story engine with per-node `{slot}` text personalization, a procedurally-drawn scene backdrop, driven by a single JSON story arc.

**Architecture:** A `ProfileManager` autoload loads fate-factor definitions from JSON and holds the player's chosen profile after character creation. A `StoryManager` autoload loads a JSON arc file, tracks `current_node_id` + a `flags` dictionary, and renders node text through `ProfileManager.apply_template()` for `{factor_id}` substitution. `CharacterCreation` builds its UI dynamically from `ProfileManager.get_factors()`. `GameScreen` renders the current node's text, a procedurally-drawn `SceneArt` backdrop, and choice buttons; clicking a choice calls into `StoryManager`, which advances state and emits a signal the screen listens to. `MainMenu` offers New Game (→ CharacterCreation) / Continue / Quit. A headless GDScript tool validates both the story JSON and the fate-factor JSON for broken links/missing data.

**Tech Stack:** Godot 4.x, GDScript. No external dependencies. No unit test framework (Godot has none built-in for GDScript); correctness is checked via a headless story-data validator script and manual playtesting steps described per task.

## Global Constraints

- Godot version: 4.x (per spec).
- No numeric combat stats/inventory/turn-based combat (per spec Non-goals).
- Fate factors affect only text flavor and simple choice-gating — no hidden success/failure rolls (per spec Non-goals).
- No external image assets — all scene art is procedural `_draw()` code (per spec).
- Story content lives entirely in `res://story/*.json`; no story text hardcoded in scripts.
- Fate factor definitions live entirely in `res://story/fate_factors.json`; character creation UI is built dynamically from that data, not hardcoded per-factor UI.
- Exactly 12 fate factors for MVP (per spec "Fate Profile" section): `gender`, `age`, `background`, `spiritual_root`, `wealth`, `moral_alignment`, `species`, `birth_location`, `family_relationships`, `fengshui_omen`, `appearance`, `talent_aptitude`.
- Single save slot at `user://save.json`, storing `{arc, current_node_id, flags, profile}`.

---

## File Structure

```
goxian/
  project.godot
  autoload/
    story_manager.gd
    profile_manager.gd
  scenes/
    main_menu.tscn
    main_menu.gd
    character_creation.tscn
    character_creation.gd
    game_screen.tscn
    game_screen.gd
    scene_art.tscn
    scene_art.gd
  story/
    intro_arc.json
    fate_factors.json
  tools/
    validate_story.gd
```

---

### Task 1: Godot project scaffold

**Files:**
- Create: `project.godot`
- Create: `autoload/`, `scenes/`, `story/`, `tools/` directories

**Interfaces:**
- Produces: a Godot project openable by the Godot 4 editor/CLI, with the main scene set later (Task 7) once `MainMenu` exists.

- [ ] **Step 1: Create the project.godot file**

```ini
; Engine configuration file.
; It's best edited using the editor UI and not directly,
; since the parameters that go here are not all obvious.

config_version=5

[application]

config/name="Goxian"
config/description="A xianxia text adventure"
run/main_scene=""
config/features=PackedStringArray("4.3", "GL Compatibility")
config/icon="res://icon.svg"

[rendering]

renderer/rendering_method="gl_compatibility"
```

- [ ] **Step 2: Create the folder structure**

```bash
mkdir -p autoload scenes story tools
```

- [ ] **Step 3: Verify the project opens**

Run: `godot4 --headless --path . --quit` (or `godot --headless --path . --quit` depending on your Godot binary name)
Expected: exits with code 0 and no errors about a missing/invalid project.

- [ ] **Step 4: Commit**

```bash
git add project.godot autoload scenes story tools
git commit -m "chore: scaffold Godot 4 project structure"
```

---

### Task 2: Fate factor data + ProfileManager autoload

**Files:**
- Create: `story/fate_factors.json`
- Create: `autoload/profile_manager.gd`
- Modify: `project.godot` (register autoload)

**Interfaces:**
- Produces:
  - `ProfileManager.get_factors() -> Dictionary` — `{factor_id: {"label": String, "options": Array[Dictionary]}}` where each option dict is `{"id": String, "label": String, "snippet": String}`
  - `ProfileManager.profile: Dictionary` (factor_id -> chosen option id), public var, empty until character creation sets it
  - `ProfileManager.set_choice(factor_id: String, option_id: String) -> void`
  - `ProfileManager.get_snippet(factor_id: String) -> String`
  - `ProfileManager.apply_template(text: String) -> String`
  - `ProfileManager.is_complete() -> bool` (true once every factor in `get_factors()` has a chosen value in `profile`)
- Consumes: nothing (loaded at startup, independent of StoryManager).

- [ ] **Step 1: Write fate_factors.json with all 12 factors**

`story/fate_factors.json`:
```json
{
  "gender": {
    "label": "Gender",
    "options": [
      { "id": "male", "label": "Male", "snippet": "a young man" },
      { "id": "female", "label": "Female", "snippet": "a young woman" },
      { "id": "nonbinary", "label": "Non-binary", "snippet": "someone who has never fit neatly into the village's old words" }
    ]
  },
  "age": {
    "label": "Age",
    "options": [
      { "id": "child", "label": "Child", "snippet": "small for the trial, and painfully aware of it" },
      { "id": "youth", "label": "Youth", "snippet": "young enough that the elders still call you 'little one'" },
      { "id": "young_adult", "label": "Young Adult", "snippet": "at the age most cultivators begin, neither too early nor too late" },
      { "id": "middle_aged", "label": "Middle-aged", "snippet": "older than most who stand at this gate, and you feel every year of it" },
      { "id": "elder", "label": "Elder", "snippet": "gray-haired among disciples half your age, here anyway" }
    ]
  },
  "background": {
    "label": "Background",
    "options": [
      { "id": "orphan", "label": "Orphan", "snippet": "you have no family name to offer, only yourself" },
      { "id": "merchant", "label": "Merchant Family", "snippet": "your family's coin bought you the road here, if nothing else" },
      { "id": "farming", "label": "Farming Family", "snippet": "your hands still remember the calluses of the family field" },
      { "id": "fallen_noble", "label": "Fallen Noble House", "snippet": "your house's name once meant something, before it didn't" },
      { "id": "performer", "label": "Wandering Performer", "snippet": "you learned to read a crowd before you learned to read words" },
      { "id": "scholar", "label": "Scholar's Household", "snippet": "you were raised on ink and old texts, not swords" }
    ]
  },
  "spiritual_root": {
    "label": "Spiritual Root",
    "options": [
      { "id": "fire", "label": "Fire", "snippet": "warmth radiates faintly from your core, like a banked coal" },
      { "id": "water", "label": "Water", "snippet": "a cool stillness pools beneath your ribs" },
      { "id": "wood", "label": "Wood", "snippet": "something in you grows quietly, patient as a root in soil" },
      { "id": "metal", "label": "Metal", "snippet": "a faint, hard resonance hums beneath your skin like struck iron" },
      { "id": "earth", "label": "Earth", "snippet": "a heavy, grounded weight settles behind your sternum" },
      { "id": "heretical", "label": "Heretical (multi-element)", "snippet": "too many elements answer you at once, tangled and unruly" },
      { "id": "void", "label": "Void (near-zero root)", "snippet": "almost nothing answers when you reach inward, an unsettling quiet" }
    ]
  },
  "wealth": {
    "label": "Wealth",
    "options": [
      { "id": "destitute", "label": "Destitute", "snippet": "you own nothing but the clothes on your back" },
      { "id": "modest", "label": "Modest", "snippet": "you carry just enough coin to not worry about tonight" },
      { "id": "comfortable", "label": "Comfortable", "snippet": "you have never gone hungry, and it shows" },
      { "id": "wealthy", "label": "Wealthy", "snippet": "the silk at your collar marks you before you speak a word" },
      { "id": "hidden_fortune", "label": "Hidden Fortune", "snippet": "you carry more wealth than anyone here would guess to look at you" }
    ]
  },
  "moral_alignment": {
    "label": "Moral Alignment",
    "options": [
      { "id": "righteous", "label": "Righteous", "snippet": "you believe the Dao should be earned honestly, or not at all" },
      { "id": "pragmatic", "label": "Pragmatic", "snippet": "you believe results matter more than the path taken to them" },
      { "id": "ruthless", "label": "Ruthless", "snippet": "you have already decided that mercy is a debt you cannot afford" },
      { "id": "compassionate", "label": "Compassionate", "snippet": "you cannot help but notice the suffering of those around you" },
      { "id": "detached", "label": "Detached", "snippet": "you watch the world's troubles the way one watches weather" }
    ]
  },
  "species": {
    "label": "Species",
    "options": [
      { "id": "human", "label": "Human", "snippet": "your blood is plain and human, for whatever that is worth here" },
      { "id": "half_spirit_beast", "label": "Half-Spirit-Beast", "snippet": "something ancient and feral stirs faintly beneath your human shape" },
      { "id": "demonic_bloodline", "label": "Demonic Bloodline", "snippet": "a bloodline the sects would call demonic runs quiet in your veins" },
      { "id": "reincarnated_soul", "label": "Reincarnated Soul", "snippet": "fragments of a life not your own surface at the strangest moments" }
    ]
  },
  "birth_location": {
    "label": "Birth Location",
    "options": [
      { "id": "mountain_village", "label": "Remote Mountain Village", "snippet": "you grew up where the mountains kept the world at a distance" },
      { "id": "bustling_city", "label": "Bustling City", "snippet": "you grew up in noise and crowds, never silence" },
      { "id": "sect_territory", "label": "Sect Territory", "snippet": "you grew up in the shadow of cultivators, always looking up" },
      { "id": "borderlands", "label": "Borderlands Near Wilds", "snippet": "you grew up close enough to the wilds to know their smell before a storm" },
      { "id": "trade_barge", "label": "Floating Trade Barge", "snippet": "you grew up with the world sliding past beneath a barge's deck" }
    ]
  },
  "family_relationships": {
    "label": "Family Relationships",
    "options": [
      { "id": "loving_family", "label": "Loving Family", "snippet": "a family waits for your letters, worried and warm" },
      { "id": "estranged_family", "label": "Estranged Family", "snippet": "you left words unsaid to a family you may never see again" },
      { "id": "sole_survivor", "label": "Sole Survivor", "snippet": "you are the only one left of the family you were born into" },
      { "id": "clan_obligations", "label": "Large Clan Obligations", "snippet": "a sprawling clan's expectations ride on your shoulders here" },
      { "id": "adoptive_family", "label": "Adoptive Family", "snippet": "the family that raised you shares none of your blood, and all of your loyalty" }
    ]
  },
  "fengshui_omen": {
    "label": "Fengshui Omen",
    "options": [
      { "id": "auspicious", "label": "Auspicious Birth", "snippet": "you were born beneath signs the local diviner called auspicious" },
      { "id": "cursed", "label": "Cursed Birth", "snippet": "you were born beneath signs the local diviner refused to fully explain" },
      { "id": "neutral", "label": "Neutral", "snippet": "no omen marked your birth one way or the other" },
      { "id": "twin_star", "label": "Twin-Star Omen", "snippet": "a diviner once told your family a rival or ally is fated to mirror your path" },
      { "id": "unreadable", "label": "Unreadable Fate", "snippet": "every diviner who has tried to read your fate has simply gone quiet" }
    ]
  },
  "appearance": {
    "label": "Appearance",
    "options": [
      { "id": "striking", "label": "Striking", "snippet": "people's eyes catch on you and linger a moment too long" },
      { "id": "plain", "label": "Plain", "snippet": "you have the kind of face people forget within the hour" },
      { "id": "unsettling", "label": "Unsettling", "snippet": "something about your bearing makes strangers take half a step back" },
      { "id": "delicate", "label": "Delicate", "snippet": "you look like something easily broken, whether or not that's true" },
      { "id": "imposing", "label": "Imposing", "snippet": "you take up more space in a room than your frame should allow" }
    ]
  },
  "talent_aptitude": {
    "label": "Talent Aptitude",
    "options": [
      { "id": "slow_steady", "label": "Slow but Steady", "snippet": "you have never learned anything quickly, but you have never unlearned it either" },
      { "id": "prodigy", "label": "Prodigy", "snippet": "things that take others years have always come to you in weeks" },
      { "id": "late_bloomer", "label": "Late Bloomer", "snippet": "you suspect your real talent hasn't shown itself yet" },
      { "id": "one_trick_genius", "label": "One-Trick Genius", "snippet": "you are astonishing at exactly one thing, and unremarkable at everything else" },
      { "id": "balanced", "label": "Balanced", "snippet": "you are competent at nearly everything, exceptional at nothing" }
    ]
  }
}
```

- [ ] **Step 2: Write ProfileManager**

`autoload/profile_manager.gd`:
```gdscript
extends Node

const FACTORS_PATH := "res://story/fate_factors.json"

var _factors: Dictionary = {}
var profile: Dictionary = {}

func _ready() -> void:
	_factors = _load_factors()

func _load_factors() -> Dictionary:
	var file := FileAccess.open(FACTORS_PATH, FileAccess.READ)
	if file == null:
		push_error("ProfileManager: could not open %s" % FACTORS_PATH)
		return _fallback_factors()
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY or parsed.is_empty():
		push_error("ProfileManager: %s is not a valid JSON object" % FACTORS_PATH)
		return _fallback_factors()
	return parsed

func _fallback_factors() -> Dictionary:
	return {
		"gender": {
			"label": "Gender",
			"options": [
				{ "id": "male", "label": "Male", "snippet": "a young man" },
				{ "id": "female", "label": "Female", "snippet": "a young woman" }
			]
		},
		"background": {
			"label": "Background",
			"options": [
				{ "id": "orphan", "label": "Orphan", "snippet": "you have no family name to offer" }
			]
		}
	}

func get_factors() -> Dictionary:
	return _factors

func set_choice(factor_id: String, option_id: String) -> void:
	profile[factor_id] = option_id

func is_complete() -> bool:
	for factor_id in _factors:
		if not profile.has(factor_id):
			return false
	return true

func _find_option(factor_id: String, option_id: String) -> Dictionary:
	var factor: Dictionary = _factors.get(factor_id, {})
	var options: Array = factor.get("options", [])
	for option in options:
		if option.get("id", "") == option_id:
			return option
	return {}

func get_snippet(factor_id: String) -> String:
	var option_id: String = profile.get(factor_id, "")
	if option_id == "":
		return ""
	var option := _find_option(factor_id, option_id)
	return option.get("snippet", "")

func apply_template(text: String) -> String:
	var result := text
	for factor_id in _factors:
		var placeholder := "{%s}" % factor_id
		if result.find(placeholder) != -1:
			var snippet := get_snippet(factor_id)
			if snippet == "":
				push_warning("ProfileManager: no snippet available for factor '%s' referenced in text" % factor_id)
				snippet = ""
			result = result.replace(placeholder, snippet)
	return result

func set_profile(new_profile: Dictionary) -> void:
	var cleaned: Dictionary = {}
	for factor_id in new_profile:
		if not _factors.has(factor_id):
			continue
		var option_id: String = new_profile[factor_id]
		if _find_option(factor_id, option_id).is_empty():
			continue
		cleaned[factor_id] = option_id
	profile = cleaned
```

- [ ] **Step 3: Register the autoload in project.godot**

Append to `project.godot`:
```ini

[autoload]

ProfileManager="*res://autoload/profile_manager.gd"
```

- [ ] **Step 4: Commit**

```bash
git add story/fate_factors.json autoload/profile_manager.gd project.godot
git commit -m "feat: add fate factor data and ProfileManager autoload"
```

---

### Task 3: Story data format + StoryManager autoload (with templating + profile gating)

**Files:**
- Create: `story/intro_arc.json`
- Create: `autoload/story_manager.gd`
- Modify: `project.godot` (register autoload)

**Interfaces:**
- Consumes: `ProfileManager.apply_template(text)`, `ProfileManager.profile`, `ProfileManager.set_profile(dict)` (Task 2).
- Produces:
  - `StoryManager.start_arc(arc_name: String) -> void`
  - `StoryManager.get_current_node() -> Dictionary` — `{"text": String (already templated), "backdrop": String, "choices": Array[Dictionary], "is_ending": bool}`, choices are `{"label": String, "index": int}`
  - `StoryManager.choose(choice_index: int) -> void`
  - `StoryManager.save_game() -> void`
  - `StoryManager.load_game() -> bool`
  - `StoryManager.has_save() -> bool`
  - `signal node_changed`

- [ ] **Step 1: Write the intro story arc JSON, using a couple of {slot} placeholders and one profile-gated choice**

`story/intro_arc.json`:
```json
{
  "start": {
    "text": "Dawn mist curls around the stone steps of Azure Cloud Sect. You have walked three days to reach this gate, and today is the entrance trial. A stern disciple blocks your path.\n\n\"State your reason for seeking the Dao,\" she says. Even now, {spiritual_root}.",
    "backdrop": "mountain_gate",
    "choices": [
      { "label": "\"I seek strength to protect those I love.\"", "next": "answer_protect", "set_flags": {"motive": "protect"} },
      { "label": "\"I seek to transcend my mortal limits.\"", "next": "answer_transcend", "set_flags": {"motive": "transcend"} },
      { "label": "Say nothing, and let your bearing answer for you.", "next": "answer_heretical", "requires_profile": {"name": "spiritual_root", "equals": "heretical"} }
    ]
  },
  "answer_protect": {
    "text": "The disciple's eyes soften slightly. \"A common answer, but an honest one.\" She steps aside. \"Enter. The Elder awaits in the Hall of Falling Blossoms.\"",
    "backdrop": "mountain_gate",
    "choices": [
      { "label": "Enter the sect.", "next": "hall_elder" }
    ]
  },
  "answer_transcend": {
    "text": "The disciple studies you a long moment. \"Ambition. Dangerous, but useful.\" She steps aside. \"Enter. The Elder awaits in the Hall of Falling Blossoms.\"",
    "backdrop": "mountain_gate",
    "choices": [
      { "label": "Enter the sect.", "next": "hall_elder" }
    ]
  },
  "answer_heretical": {
    "text": "The disciple frowns, unsettled — the tangled resonance coming off you answers a question you never spoke aloud. \"...Enter,\" she says finally, watching you a beat too long. \"The Elder will want to see you personally.\"",
    "backdrop": "mountain_gate",
    "choices": [
      { "label": "Enter the sect.", "next": "hall_elder" }
    ]
  },
  "hall_elder": {
    "text": "Elder Wren regards you from atop a dais carved like a coiled dragon. \"Every generation, one outsider is given a trial stone. Hold it, and it will show me your heart.\" She offers a smooth grey stone. You remember, briefly, that {background}.",
    "backdrop": "sect_hall",
    "choices": [
      { "label": "Take the stone without hesitation.", "next": "trial_bold" },
      { "label": "Ask what happens if you refuse.", "next": "trial_cautious", "set_flags": {"cautious": true} }
    ]
  },
  "trial_bold": {
    "text": "You grasp the stone. It flares white-hot for an instant, then cools. Elder Wren nods slowly. \"Bold. The stone shows a heart unclouded by fear.\"",
    "backdrop": "sect_hall",
    "choices": [
      { "label": "Ask to begin training.", "next": "ending_bold" }
    ]
  },
  "trial_cautious": {
    "text": "\"Refuse, and you may leave in peace, empty-handed,\" Elder Wren says. You weigh the stone in your palm before finally accepting it. It flares, then dims. \"Caution paired with resolve. Rarer than you'd think.\"",
    "backdrop": "sect_hall",
    "choices": [
      { "label": "Ask to begin training.", "next": "ending_cautious" }
    ]
  },
  "ending_bold": {
    "text": "You are led to the outer courtyard, where forty other disciples drill under the morning sun. Your journey as a cultivator of Azure Cloud Sect begins today — {talent_aptitude}, and driven by a heart that seeks strength above all.",
    "backdrop": "sect_hall",
    "choices": []
  },
  "ending_cautious": {
    "text": "Elder Wren walks with you personally to the outer courtyard. \"Watch, listen, then act,\" she says. \"That is how you'll survive what's coming.\" Your journey as a cultivator of Azure Cloud Sect begins — carefully, and {talent_aptitude}.",
    "backdrop": "sect_hall",
    "choices": []
  }
}
```

- [ ] **Step 2: Write StoryManager**

`autoload/story_manager.gd`:
```gdscript
extends Node

signal node_changed

const SAVE_PATH := "user://save.json"

var _arc_name: String = ""
var _nodes: Dictionary = {}
var current_node_id: String = ""
var flags: Dictionary = {}

func start_arc(arc_name: String) -> void:
	_arc_name = arc_name
	_nodes = _load_arc(arc_name)
	flags = {}
	current_node_id = "start"
	node_changed.emit()

func _load_arc(arc_name: String) -> Dictionary:
	var path := "res://story/%s.json" % arc_name
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("StoryManager: could not open story file %s" % path)
		return _error_arc()
	var text := file.get_as_text()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("StoryManager: story file %s is not a valid JSON object" % path)
		return _error_arc()
	return parsed

func _error_arc() -> Dictionary:
	return {
		"start": {
			"text": "(Story data failed to load. Please check the console for errors.)",
			"backdrop": "mountain_gate",
			"choices": []
		}
	}

func get_current_node() -> Dictionary:
	var raw: Dictionary = _nodes.get(current_node_id, {})
	if raw.is_empty():
		push_error("StoryManager: unknown node id '%s'" % current_node_id)
		raw = _error_arc()["start"]

	var raw_choices: Array = raw.get("choices", [])
	var visible_choices: Array = []
	for i in raw_choices.size():
		var choice: Dictionary = raw_choices[i]
		if _choice_is_visible(choice):
			visible_choices.append({"label": choice.get("label", ""), "index": i})

	return {
		"text": ProfileManager.apply_template(raw.get("text", "")),
		"backdrop": raw.get("backdrop", "mountain_gate"),
		"choices": visible_choices,
		"is_ending": raw_choices.is_empty()
	}

func _choice_is_visible(choice: Dictionary) -> bool:
	if choice.has("requires_flag") and not _requirement_met(choice["requires_flag"], flags):
		return false
	if choice.has("requires_profile") and not _requirement_met(choice["requires_profile"], ProfileManager.profile):
		return false
	return true

func _requirement_met(req: Dictionary, source: Dictionary) -> bool:
	var key = req.get("name", "")
	var expected_value = req.get("equals", true)
	return source.get(key, null) == expected_value

func choose(choice_index: int) -> void:
	var raw: Dictionary = _nodes.get(current_node_id, {})
	var raw_choices: Array = raw.get("choices", [])
	if choice_index < 0 or choice_index >= raw_choices.size():
		push_error("StoryManager: choice_index %d out of range for node '%s'" % [choice_index, current_node_id])
		return
	var choice: Dictionary = raw_choices[choice_index]
	var set_flags: Dictionary = choice.get("set_flags", {})
	for key in set_flags:
		flags[key] = set_flags[key]

	var next_id: String = choice.get("next", "")
	if not _nodes.has(next_id):
		push_error("StoryManager: choice points to unknown node '%s'" % next_id)
		return
	current_node_id = next_id
	node_changed.emit()

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_game() -> void:
	var data := {
		"arc": _arc_name,
		"current_node_id": current_node_id,
		"flags": flags,
		"profile": ProfileManager.profile
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))

func load_game() -> bool:
	if not has_save():
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return false

	var arc_name: String = parsed.get("arc", "")
	if arc_name == "":
		return false
	_arc_name = arc_name
	_nodes = _load_arc(arc_name)
	flags = parsed.get("flags", {})
	ProfileManager.set_profile(parsed.get("profile", {}))
	var loaded_node: String = parsed.get("current_node_id", "start")
	current_node_id = loaded_node if _nodes.has(loaded_node) else "start"
	node_changed.emit()
	return true
```

- [ ] **Step 3: Register the autoload in project.godot**

Append to the `[autoload]` section of `project.godot` (order matters: `ProfileManager` must be listed before `StoryManager` since `StoryManager` calls `ProfileManager.apply_template` — Godot initializes autoloads in declaration order):
```ini

[autoload]

ProfileManager="*res://autoload/profile_manager.gd"
StoryManager="*res://autoload/story_manager.gd"
```

(This replaces the `[autoload]` section written in Task 2 Step 3 — make sure `ProfileManager` stays listed first.)

- [ ] **Step 4: Commit**

```bash
git add story/intro_arc.json autoload/story_manager.gd project.godot
git commit -m "feat: add StoryManager autoload with profile-templated story arc"
```

---

### Task 4: Headless story + fate-factor data validator

**Files:**
- Create: `tools/validate_story.gd`

**Interfaces:**
- Consumes: `res://story/*.json` files directly (re-implements minimal JSON loading, independent of the autoloads, so it runs as a plain `SceneTree` script via `--script`).
- Produces: a CLI-runnable script that exits non-zero on story/profile data errors, printing each problem found.

- [ ] **Step 1: Write the validator script**

`tools/validate_story.gd`:
```gdscript
extends SceneTree

func _init() -> void:
	var errors: Array[String] = []
	errors.append_array(_validate_fate_factors("res://story/fate_factors.json"))

	var valid_factor_ids := _load_factor_ids("res://story/fate_factors.json")

	var dir := DirAccess.open("res://story")
	if dir == null:
		printerr("Could not open res://story")
		quit(1)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	var checked_any_arc := false
	while file_name != "":
		if file_name.ends_with(".json") and file_name != "fate_factors.json":
			checked_any_arc = true
			errors.append_array(_validate_arc_file("res://story/%s" % file_name, valid_factor_ids))
		file_name = dir.get_next()
	dir.list_dir_end()

	if not checked_any_arc:
		errors.append("No story arc JSON files found in res://story")

	if errors.is_empty():
		print("Story data OK.")
		quit(0)
	else:
		for e in errors:
			printerr(e)
		printerr("%d error(s) found." % errors.size())
		quit(1)

func _load_factor_ids(path: String) -> Dictionary:
	# Returns {factor_id: [option_id, ...]}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	var result := {}
	for factor_id in parsed:
		var factor: Dictionary = parsed[factor_id]
		var option_ids: Array = []
		for option in factor.get("options", []):
			option_ids.append(option.get("id", ""))
		result[factor_id] = option_ids
	return result

func _validate_fate_factors(path: String) -> Array[String]:
	var errors: Array[String] = []
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		errors.append("%s: could not open file" % path)
		return errors
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		errors.append("%s: root is not a JSON object" % path)
		return errors
	if parsed.is_empty():
		errors.append("%s: no fate factors defined" % path)
	for factor_id in parsed:
		var factor: Dictionary = parsed[factor_id]
		var options: Array = factor.get("options", [])
		if options.is_empty():
			errors.append("%s: factor '%s' has no options" % [path, factor_id])
		for option in options:
			if String(option.get("snippet", "")).strip_edges() == "":
				errors.append("%s: factor '%s' option '%s' has an empty snippet" % [path, factor_id, option.get("id", "?")])
	return errors

func _validate_arc_file(path: String, valid_factor_ids: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		errors.append("%s: could not open file" % path)
		return errors

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		errors.append("%s: root is not a JSON object" % path)
		return errors

	var nodes: Dictionary = parsed
	if not nodes.has("start"):
		errors.append("%s: missing required 'start' node" % path)

	var reachable := {}
	var queue: Array[String] = []
	if nodes.has("start"):
		queue.append("start")
		reachable["start"] = true

	for node_id in nodes:
		var node: Dictionary = nodes[node_id]
		var choices: Array = node.get("choices", [])
		for choice in choices:
			if not choice.has("next"):
				errors.append("%s: node '%s' has a choice with no 'next'" % [path, node_id])
				continue
			var next_id: String = choice["next"]
			if not nodes.has(next_id):
				errors.append("%s: node '%s' points to missing node '%s'" % [path, node_id, next_id])
			if choice.has("requires_profile"):
				var req: Dictionary = choice["requires_profile"]
				var factor_id = req.get("name", "")
				var expected = req.get("equals", "")
				if not valid_factor_ids.has(factor_id):
					errors.append("%s: node '%s' choice requires_profile references unknown factor '%s'" % [path, node_id, factor_id])
				elif not valid_factor_ids[factor_id].has(expected):
					errors.append("%s: node '%s' choice requires_profile references unknown option '%s' for factor '%s'" % [path, node_id, expected, factor_id])

	while not queue.is_empty():
		var current: String = queue.pop_front()
		var node: Dictionary = nodes.get(current, {})
		var choices: Array = node.get("choices", [])
		for choice in choices:
			var next_id = choice.get("next", "")
			if next_id != "" and nodes.has(next_id) and not reachable.has(next_id):
				reachable[next_id] = true
				queue.append(next_id)

	for node_id in nodes:
		if not reachable.has(node_id):
			errors.append("%s: node '%s' is unreachable from 'start'" % [path, node_id])

	for node_id in nodes:
		var node: Dictionary = nodes[node_id]
		var text: String = node.get("text", "")
		var i := text.find("{")
		while i != -1:
			var j := text.find("}", i)
			if j == -1:
				break
			var factor_id := text.substr(i + 1, j - i - 1)
			if not valid_factor_ids.has(factor_id):
				errors.append("%s: node '%s' text references unknown factor placeholder '{%s}'" % [path, node_id, factor_id])
			i = text.find("{", j)

	return errors
```

- [ ] **Step 2: Run the validator against the intro arc and fate factors**

Run: `godot4 --headless --script res://tools/validate_story.gd`
Expected output: `Story data OK.` and exit code 0.

- [ ] **Step 3: Verify it actually catches errors (regression check)**

Temporarily edit `story/intro_arc.json`, changing `"equals": "heretical"` (in the `answer_heretical` choice's `requires_profile`) to `"equals": "heretcial"` (typo), then run the same command again.

Expected: prints `...references unknown option 'heretcial' for factor 'spiritual_root'` and exits non-zero.

Then revert the typo:
```bash
git checkout -- story/intro_arc.json
```

- [ ] **Step 4: Commit**

```bash
git add tools/validate_story.gd
git commit -m "feat: add headless story and fate-factor data validator"
```

---

### Task 5: SceneArt procedural backdrop component

**Files:**
- Create: `scenes/scene_art.tscn`
- Create: `scenes/scene_art.gd`

**Interfaces:**
- Produces:
  - `SceneArt.set_backdrop(key: String) -> void`
- Consumes: nothing external (pure `Control` + `_draw()`).

- [ ] **Step 1: Write the SceneArt script**

`scenes/scene_art.gd`:
```gdscript
extends Control
class_name SceneArt

var _backdrop: String = "mountain_gate"

func set_backdrop(key: String) -> void:
	_backdrop = key
	queue_redraw()

func _draw() -> void:
	var size := get_rect().size
	match _backdrop:
		"mountain_gate":
			_draw_mountain_gate(size)
		"sect_hall":
			_draw_sect_hall(size)
		_:
			_draw_fallback(size)

func _draw_sky_gradient(size: Vector2, top_color: Color, bottom_color: Color) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), top_color)
	var band_count := 24
	for i in band_count:
		var t := float(i) / band_count
		var c := top_color.lerp(bottom_color, t)
		var y := size.y * t
		var h := size.y / band_count + 1.0
		draw_rect(Rect2(Vector2(0, y), Vector2(size.x, h)), c)

func _draw_mountain_gate(size: Vector2) -> void:
	_draw_sky_gradient(size, Color(0.53, 0.62, 0.75), Color(0.85, 0.78, 0.68))
	draw_circle(Vector2(size.x * 0.8, size.y * 0.25), size.y * 0.08, Color(0.95, 0.9, 0.75, 0.9))

	var back_points := PackedVector2Array([
		Vector2(0, size.y * 0.55),
		Vector2(size.x * 0.2, size.y * 0.35),
		Vector2(size.x * 0.45, size.y * 0.5),
		Vector2(size.x * 0.7, size.y * 0.3),
		Vector2(size.x, size.y * 0.5),
		Vector2(size.x, size.y),
		Vector2(0, size.y)
	])
	draw_colored_polygon(back_points, Color(0.45, 0.5, 0.55, 0.6))

	var front_points := PackedVector2Array([
		Vector2(0, size.y * 0.75),
		Vector2(size.x * 0.3, size.y * 0.5),
		Vector2(size.x * 0.55, size.y * 0.7),
		Vector2(size.x * 0.8, size.y * 0.45),
		Vector2(size.x, size.y * 0.65),
		Vector2(size.x, size.y),
		Vector2(0, size.y)
	])
	draw_colored_polygon(front_points, Color(0.25, 0.28, 0.32))

	var pillar_w := size.x * 0.04
	var pillar_h := size.y * 0.4
	var pillar_y := size.y - pillar_h
	draw_rect(Rect2(Vector2(size.x * 0.35, pillar_y), Vector2(pillar_w, pillar_h)), Color(0.15, 0.1, 0.08))
	draw_rect(Rect2(Vector2(size.x * 0.6, pillar_y), Vector2(pillar_w, pillar_h)), Color(0.15, 0.1, 0.08))
	draw_rect(Rect2(Vector2(size.x * 0.33, pillar_y - size.y * 0.05), Vector2(size.x * 0.34, size.y * 0.05)), Color(0.15, 0.1, 0.08))

func _draw_sect_hall(size: Vector2) -> void:
	_draw_sky_gradient(size, Color(0.75, 0.7, 0.8), Color(0.9, 0.85, 0.75))
	draw_rect(Rect2(Vector2(0, size.y * 0.8), Vector2(size.x, size.y * 0.2)), Color(0.35, 0.3, 0.25))

	var roof_points := PackedVector2Array([
		Vector2(size.x * 0.1, size.y * 0.45),
		Vector2(size.x * 0.5, size.y * 0.15),
		Vector2(size.x * 0.9, size.y * 0.45),
		Vector2(size.x * 0.75, size.y * 0.45),
		Vector2(size.x * 0.5, size.y * 0.3),
		Vector2(size.x * 0.25, size.y * 0.45)
	])
	draw_colored_polygon(roof_points, Color(0.2, 0.15, 0.12))
	draw_rect(Rect2(Vector2(size.x * 0.2, size.y * 0.45), Vector2(size.x * 0.6, size.y * 0.35)), Color(0.4, 0.2, 0.15))

	for i in range(3):
		var px := size.x * (0.28 + i * 0.22)
		draw_rect(Rect2(Vector2(px, size.y * 0.5), Vector2(size.x * 0.03, size.y * 0.3)), Color(0.15, 0.1, 0.08))

func _draw_fallback(size: Vector2) -> void:
	_draw_sky_gradient(size, Color(0.4, 0.4, 0.45), Color(0.6, 0.6, 0.65))
```

- [ ] **Step 2: Build the SceneArt scene**

`scenes/scene_art.tscn`:
```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scenes/scene_art.gd" id="1"]

[node name="SceneArt" type="Control"]
layout_mode=3
anchors_preset=15
anchor_right=1.0
anchor_bottom=1.0
script=ExtResource("1")
```

- [ ] **Step 3: Manual visual check**

Open the project in the Godot editor, open `scenes/scene_art.tscn`, run the scene (F6). Confirm a mountain-gate backdrop renders (gradient sky, sun disc, two mountain silhouette layers, gate pillars) with no console errors. Then temporarily call `set_backdrop("sect_hall")` from a `_ready()` test line, re-run, confirm the hall backdrop renders, then remove the test line.

- [ ] **Step 4: Commit**

```bash
git add scenes/scene_art.tscn scenes/scene_art.gd
git commit -m "feat: add procedural SceneArt backdrop component"
```

---

### Task 6: CharacterCreation screen

**Files:**
- Create: `scenes/character_creation.tscn`
- Create: `scenes/character_creation.gd`

**Interfaces:**
- Consumes: `ProfileManager.get_factors()`, `ProfileManager.set_choice(factor_id, option_id)`, `ProfileManager.is_complete()` (Task 2).
- Produces: a scene `MainMenu` (Task 7) transitions to via `get_tree().change_scene_to_file("res://scenes/character_creation.tscn")`; on completion it calls `StoryManager.start_arc("intro_arc")` and transitions to `res://scenes/game_screen.tscn`.

- [ ] **Step 1: Build the CharacterCreation scene shell**

`scenes/character_creation.tscn`:
```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scenes/character_creation.gd" id="1"]

[node name="CharacterCreation" type="Control"]
layout_mode=3
anchors_preset=15
anchor_right=1.0
anchor_bottom=1.0
script=ExtResource("1")

[node name="ScrollContainer" type="ScrollContainer" parent="."]
layout_mode=1
anchors_preset=15
anchor_right=1.0
anchor_bottom=1.0

[node name="VBox" type="VBoxContainer" parent="ScrollContainer"]
layout_mode=2
size_flags_horizontal=3

[node name="BeginButton" type="Button" parent="."]
layout_mode=1
anchors_preset=3
anchor_left=1.0
anchor_top=1.0
anchor_right=1.0
anchor_bottom=1.0
offset_left=-160.0
offset_top=-50.0
text="Begin Journey"
```

- [ ] **Step 2: Write the CharacterCreation script**

`scenes/character_creation.gd`:
```gdscript
extends Control

@onready var vbox: VBoxContainer = $ScrollContainer/VBox
@onready var begin_button: Button = $BeginButton

func _ready() -> void:
	_build_factor_rows()
	begin_button.pressed.connect(_on_begin_pressed)

func _build_factor_rows() -> void:
	var factors := ProfileManager.get_factors()
	for factor_id in factors:
		var factor: Dictionary = factors[factor_id]

		var row := HBoxContainer.new()

		var label := Label.new()
		label.text = factor.get("label", factor_id)
		label.custom_minimum_size = Vector2(200, 0)
		row.add_child(label)

		var option_button := OptionButton.new()
		var options: Array = factor.get("options", [])
		for option in options:
			option_button.add_item(option.get("label", option.get("id", "")))
		if options.size() > 0:
			ProfileManager.set_choice(factor_id, options[0].get("id", ""))
		option_button.item_selected.connect(_on_option_selected.bind(factor_id, options))

		row.add_child(option_button)
		vbox.add_child(row)

func _on_option_selected(index: int, factor_id: String, options: Array) -> void:
	if index >= 0 and index < options.size():
		ProfileManager.set_choice(factor_id, options[index].get("id", ""))

func _on_begin_pressed() -> void:
	if not ProfileManager.is_complete():
		return
	StoryManager.start_arc("intro_arc")
	get_tree().change_scene_to_file("res://scenes/game_screen.tscn")
```

- [ ] **Step 3: Manual check — character creation populates and locks in choices**

Open the project in the Godot editor, temporarily set `run/main_scene="res://scenes/character_creation.tscn"` in `project.godot`, run the project (F5). Verify:
1. All 12 factor rows render with labels and dropdowns pre-populated (each defaulting to its first option).
2. Changing a dropdown (e.g. `spiritual_root` to "Heretical (multi-element)") is reflected — add a temporary `print(ProfileManager.profile)` at the end of `_on_option_selected` to confirm in the Output panel, then remove it.
3. Clicking "Begin Journey" doesn't crash (it will error trying to load `game_screen.tscn`, which doesn't exist until Task 7 — that error is expected here and will be resolved once Task 7 lands; confirm the error is specifically a missing-scene-file error, not a script error in `character_creation.gd`).

Revert the temporary `run/main_scene` change afterward (leave it as it was — this will be set for real in Task 8).

- [ ] **Step 4: Commit**

```bash
git add scenes/character_creation.tscn scenes/character_creation.gd
git commit -m "feat: add CharacterCreation screen driven by fate factor data"
```

---

### Task 7: GameScreen (story log + choices UI)

**Files:**
- Create: `scenes/game_screen.tscn`
- Create: `scenes/game_screen.gd`

**Interfaces:**
- Consumes: `StoryManager.node_changed`, `StoryManager.get_current_node()`, `StoryManager.choose(index)`, `StoryManager.save_game()` (Task 3); `SceneArt.set_backdrop(key)` (Task 5).
- Produces: a scene reachable from `CharacterCreation` (Task 6) and `MainMenu`'s Continue flow (Task 8).

- [ ] **Step 1: Build the GameScreen scene layout**

`scenes/game_screen.tscn`:
```
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://scenes/game_screen.gd" id="1"]
[ext_resource type="PackedScene" path="res://scenes/scene_art.tscn" id="2"]

[node name="GameScreen" type="Control"]
layout_mode=3
anchors_preset=15
anchor_right=1.0
anchor_bottom=1.0
script=ExtResource("1")

[node name="VBox" type="VBoxContainer" parent="."]
layout_mode=1
anchors_preset=15
anchor_right=1.0
anchor_bottom=1.0

[node name="SceneArt" parent="VBox" instance=ExtResource("2")]
layout_mode=2
custom_minimum_size=Vector2(0, 220)
size_flags_vertical=3

[node name="StoryLog" type="RichTextLabel" parent="VBox"]
layout_mode=2
size_flags_vertical=3
bbcode_enabled=true
scroll_following=true

[node name="ChoicesBox" type="VBoxContainer" parent="VBox"]
layout_mode=2
```

- [ ] **Step 2: Write the GameScreen script**

`scenes/game_screen.gd`:
```gdscript
extends Control

@onready var scene_art: SceneArt = $VBox/SceneArt
@onready var story_log: RichTextLabel = $VBox/StoryLog
@onready var choices_box: VBoxContainer = $VBox/ChoicesBox

func _ready() -> void:
	StoryManager.node_changed.connect(_on_node_changed)
	_render_current_node()

func _on_node_changed() -> void:
	_render_current_node()

func _render_current_node() -> void:
	var node := StoryManager.get_current_node()

	scene_art.set_backdrop(node["backdrop"])
	story_log.append_text("\n\n" + node["text"])

	for child in choices_box.get_children():
		child.queue_free()

	if node["is_ending"]:
		StoryManager.save_game()
		var end_label := Label.new()
		end_label.text = "— The End —"
		choices_box.add_child(end_label)

		var menu_button := Button.new()
		menu_button.text = "Return to Menu"
		menu_button.pressed.connect(_on_return_to_menu_pressed)
		choices_box.add_child(menu_button)
		return

	for choice in node["choices"]:
		var button := Button.new()
		button.text = choice["label"]
		button.pressed.connect(_on_choice_pressed.bind(choice["index"]))
		choices_box.add_child(button)

	StoryManager.save_game()

func _on_choice_pressed(choice_index: int) -> void:
	StoryManager.choose(choice_index)

func _on_return_to_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
```

- [ ] **Step 3: Commit**

```bash
git add scenes/game_screen.tscn scenes/game_screen.gd
git commit -m "feat: add GameScreen story log and choice UI"
```

---

### Task 8: MainMenu + save/continue wiring + project entry point

**Files:**
- Create: `scenes/main_menu.tscn`
- Create: `scenes/main_menu.gd`
- Modify: `project.godot` (set `run/main_scene`)

**Interfaces:**
- Consumes: `StoryManager.load_game()`, `StoryManager.has_save()` (Task 3); `res://scenes/character_creation.tscn` (Task 6); `res://scenes/game_screen.tscn` (Task 7).
- Produces: the game's entry point.

- [ ] **Step 1: Build the MainMenu scene**

`scenes/main_menu.tscn`:
```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scenes/main_menu.gd" id="1"]

[node name="MainMenu" type="Control"]
layout_mode=3
anchors_preset=15
anchor_right=1.0
anchor_bottom=1.0
script=ExtResource("1")

[node name="VBox" type="VBoxContainer" parent="."]
layout_mode=1
anchors_preset=8
anchor_left=0.5
anchor_top=0.5
anchor_right=0.5
anchor_bottom=0.5
offset_left=-100.0
offset_top=-60.0
offset_right=100.0
offset_bottom=60.0

[node name="Title" type="Label" parent="VBox"]
layout_mode=2
text="Goxian"
horizontal_alignment=1

[node name="NewGameButton" type="Button" parent="VBox"]
layout_mode=2
text="New Game"

[node name="ContinueButton" type="Button" parent="VBox"]
layout_mode=2
text="Continue"

[node name="QuitButton" type="Button" parent="VBox"]
layout_mode=2
text="Quit"
```

- [ ] **Step 2: Write the MainMenu script**

`scenes/main_menu.gd`:
```gdscript
extends Control

@onready var continue_button: Button = $VBox/ContinueButton

func _ready() -> void:
	$VBox/NewGameButton.pressed.connect(_on_new_game_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	$VBox/QuitButton.pressed.connect(_on_quit_pressed)
	continue_button.disabled = not StoryManager.has_save()

func _on_new_game_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/character_creation.tscn")

func _on_continue_pressed() -> void:
	if StoryManager.load_game():
		get_tree().change_scene_to_file("res://scenes/game_screen.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
```

- [ ] **Step 3: Set the main scene and playtest end-to-end**

Edit `project.godot`, set:
```ini
run/main_scene="res://scenes/main_menu.tscn"
```

Open the project in the Godot editor and run it (F5). Manually verify:
1. Main menu shows with "Continue" disabled (no save yet).
2. Click "New Game" → character creation screen shows all 12 factors; pick `spiritual_root = "Heretical (multi-element)"` (to test the profile-gated choice) and leave the rest at defaults, click "Begin Journey".
3. The gate scene appears with mountain-gate art; confirm the text includes the heretical spiritual-root flavor snippet in place of `{spiritual_root}` (no literal `{spiritual_root}` should appear anywhere), and that a third choice ("Say nothing, and let your bearing answer for you.") is visible because of the profile match.
4. Pick the profile-gated choice → confirm it leads to `answer_heretical` then `hall_elder`, backdrop switches to sect hall art, and `{background}` is substituted in the hall_elder text.
5. Pick "Take the stone without hesitation" → reach `ending_bold`, confirm `{talent_aptitude}` is substituted, see "— The End —" and "Return to Menu".
6. Click "Return to Menu" → back at main menu, "Continue" is now enabled.
7. Click "Continue" → lands back on the ending node with the same profile (spiritual_root still heretical) — confirms save/load round-trips profile + story state correctly.
8. Quit and relaunch, click "Continue" again → same result, confirming persistence across process restarts.
9. Repeat from a fresh "New Game" picking a *non*-heretical spiritual root, and confirm the third gate choice does NOT appear (profile gating correctly hides it), and the "Ask what happens if you refuse" branch at the hall leads to `ending_cautious` correctly.

Expected: no console errors in any step, no unsubstituted `{...}` placeholders visible, both endings reachable, save/continue works, profile-gated choice appears/disappears correctly.

- [ ] **Step 4: Commit**

```bash
git add scenes/main_menu.tscn scenes/main_menu.gd project.godot
git commit -m "feat: add MainMenu with New Game/Continue/Quit and set as entry point"
```

---

## Self-Review Notes

- **Spec coverage:** fate_factors.json + ProfileManager (Task 2), `{slot}` template substitution wired into `StoryManager.get_current_node()` (Task 3), profile-gated choices via `requires_profile` alongside existing `requires_flag` (Task 3), CharacterCreation screen built dynamically from factor data (Task 6), procedural SceneArt (Task 5), choice-button GameScreen UI (Task 7), MainMenu with New Game → CharacterCreation and Continue restoring profile (Task 8), save/load persisting `{arc, current_node_id, flags, profile}` (Task 3/7/8), headless validator covering both story links and fate-factor data plus placeholder references (Task 4), error handling for bad JSON/dangling links/unknown placeholders (Task 3 `_error_arc`, ProfileManager `_fallback_factors`/`apply_template` warning, Task 4 validator) — all spec sections have a corresponding task.
- **Autoload order dependency:** flagged explicitly in Task 3 Step 3 since `StoryManager.get_current_node()` calls `ProfileManager.apply_template()` — Godot autoloads initialize in the order listed in `project.godot`, so `ProfileManager` must be registered first. This is called out so the implementer doesn't hit a null-autoload error.
- **No placeholders:** all code blocks are complete and runnable; no TBD/TODO left.
- **Type consistency:** `get_current_node()` return shape (`text`, `backdrop`, `choices`, `is_ending`) is identical across Task 3 (producer) and Task 7 (consumer). `ProfileManager.apply_template(text: String) -> String` signature matches its Task 3 call site. `requires_flag`/`requires_profile` both use `{name, equals}` shape as specified in the design doc, verified consistently in Task 3's `_choice_is_visible`/`_requirement_met` and Task 4's validator.
