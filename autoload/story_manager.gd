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
		"text": ProfileManager.apply_template(_select_text(raw)),
		"backdrop": raw.get("backdrop", "mountain_gate"),
		"choices": visible_choices,
		"is_ending": raw_choices.is_empty()
	}

func _select_text(raw: Dictionary) -> String:
	var variants: Array = raw.get("variants", [])
	for variant in variants:
		var when: Dictionary = variant.get("when", {})
		if _all_conditions_met(when):
			return variant.get("text", raw.get("text", ""))
	return raw.get("text", "")

func _all_conditions_met(when: Dictionary) -> bool:
	for key in when:
		var expected = when[key]
		var actual = flags.get(key, ProfileManager.profile.get(key, null))
		if actual != expected:
			return false
	return true

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
		"profile": ProfileManager.profile,
		"player_name": ProfileManager.player_name
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
	ProfileManager.set_player_name(parsed.get("player_name", ""))
	var loaded_node: String = parsed.get("current_node_id", "start")
	current_node_id = loaded_node if _nodes.has(loaded_node) else "start"
	node_changed.emit()
	return true
