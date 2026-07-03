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
