extends Control

const RANDOM_NAMES := [
	"Lian", "Wei", "Xiu", "Feng", "Jin", "Rui", "Bai", "Ming",
	"Yun", "Zhen", "Qing", "Lei", "Xue", "Hao", "Mei"
]

@onready var scene_art: SceneArt = $MainVBox/SceneArt
@onready var name_edit: LineEdit = $MainVBox/ScrollContainer/VBox/NameRow/NameEdit
@onready var vbox: VBoxContainer = $MainVBox/ScrollContainer/VBox
@onready var randomize_button: Button = $MainVBox/ButtonsRow/RandomizeButton
@onready var begin_button: Button = $MainVBox/ButtonsRow/BeginButton

var _option_buttons: Dictionary = {}

func _ready() -> void:
	scene_art.set_backdrop("character_creation")
	name_edit.text_changed.connect(_on_name_changed)
	_build_factor_rows()
	randomize_button.pressed.connect(_on_randomize_pressed)
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

		_option_buttons[factor_id] = {"button": option_button, "options": options}

		row.add_child(option_button)
		vbox.add_child(row)

func _on_name_changed(new_text: String) -> void:
	ProfileManager.set_player_name(new_text)

func _on_option_selected(index: int, factor_id: String, options: Array) -> void:
	if index >= 0 and index < options.size():
		ProfileManager.set_choice(factor_id, options[index].get("id", ""))

func _on_randomize_pressed() -> void:
	name_edit.text = RANDOM_NAMES[randi() % RANDOM_NAMES.size()]
	ProfileManager.set_player_name(name_edit.text)

	for factor_id in _option_buttons:
		var entry: Dictionary = _option_buttons[factor_id]
		var options: Array = entry["options"]
		if options.is_empty():
			continue
		var random_index := randi() % options.size()
		var button: OptionButton = entry["button"]
		button.select(random_index)
		ProfileManager.set_choice(factor_id, options[random_index].get("id", ""))

func _on_begin_pressed() -> void:
	if not ProfileManager.is_complete():
		return
	StoryManager.start_arc("intro_arc")
	get_tree().change_scene_to_file("res://scenes/game_screen.tscn")
