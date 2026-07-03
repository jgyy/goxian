extends Control

const CHOICE_FONT_SIZE := 28
const LATEST_TEXT_COLOR := "#ffd166"

@onready var scene_art: SceneArt = $VBox/SceneArt
@onready var story_log: RichTextLabel = $VBox/StoryLog
@onready var choices_box: VBoxContainer = $VBox/ChoicesBox

var _beat_count := 0

func _ready() -> void:
	StoryManager.node_changed.connect(_on_node_changed)
	_render_current_node()

func _on_node_changed() -> void:
	_render_current_node()

func _render_current_node() -> void:
	var node := StoryManager.get_current_node()

	scene_art.set_backdrop(node["backdrop"])
	_dim_previous_text()
	_beat_count += 1
	story_log.append_text("\n\n[color=%s][b]%d.[/b] %s[/color]" % [LATEST_TEXT_COLOR, _beat_count, node["text"].replace("[", "[lb]")])

	for child in choices_box.get_children():
		child.queue_free()

	if node["is_ending"]:
		StoryManager.save_game()
		var end_label := Label.new()
		end_label.text = "— The End —"
		end_label.add_theme_font_size_override("font_size", CHOICE_FONT_SIZE)
		choices_box.add_child(end_label)

		var menu_button := Button.new()
		menu_button.text = "Return to Menu"
		menu_button.add_theme_font_size_override("font_size", CHOICE_FONT_SIZE)
		menu_button.pressed.connect(_on_return_to_menu_pressed)
		choices_box.add_child(menu_button)
		return

	for choice in node["choices"]:
		var button := Button.new()
		button.text = choice["label"]
		button.add_theme_font_size_override("font_size", CHOICE_FONT_SIZE)
		button.pressed.connect(_on_choice_pressed.bind(choice["index"]))
		choices_box.add_child(button)

	StoryManager.save_game()

func _dim_previous_text() -> void:
	var plain := story_log.get_parsed_text()
	if plain == "":
		return
	story_log.text = "[color=#aaaaaa]%s[/color]" % plain.replace("[", "[lb]")

func _on_choice_pressed(choice_index: int) -> void:
	StoryManager.choose(choice_index)

func _on_return_to_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
