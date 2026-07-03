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
