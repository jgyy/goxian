extends Node

const FACTORS_PATH := "res://story/fate_factors.json"

var _factors: Dictionary = {}
var profile: Dictionary = {}
var player_name: String = ""

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
	if player_name.strip_edges() == "":
		return false
	for factor_id in _factors:
		if not profile.has(factor_id):
			return false
	return true

func set_player_name(new_name: String) -> void:
	player_name = new_name

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
	if result.find("{name}") != -1:
		var display_name := player_name if player_name.strip_edges() != "" else "you"
		result = result.replace("{name}", display_name)
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
