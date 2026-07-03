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
