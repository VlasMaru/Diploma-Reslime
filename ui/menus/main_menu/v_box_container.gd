extends VBoxContainer

# Добавляем ссылки на узлы
@onready var play_button: Button = $play_button

func _ready() -> void:
	# Автоматический фокус на кнопке "Играть"
	# Это позволит игроку сразу нажать Enter/Пробел без использования мыши
	if play_button:
		play_button.grab_focus()

func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://levels/test_level.tscn")

func _on_quit_button_pressed() -> void:
	get_tree().quit()

@onready var settings_panel: Panel = $"../../../../SettingsPanel"

func _on_settings_button_pressed() -> void:
	if settings_panel:
		settings_panel.show()

func _on_close_settings_button_pressed() -> void:
	if settings_panel:
		settings_panel.hide()
