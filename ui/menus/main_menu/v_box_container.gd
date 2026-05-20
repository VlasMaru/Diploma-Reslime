extends VBoxContainer

# Добавляем ссылки на узлы
@onready var play_button: Button = $play_button

func _ready() -> void:
	# Автоматический фокус на кнопке "Играть"
	# Это позволит игроку сразу нажать Enter/Пробел без использования мыши
	if play_button:
		play_button.grab_focus()

func _on_play_button_pressed() -> void:
	# Можно добавить звук нажатия перед загрузкой сцены
	get_tree().change_scene_to_file("res://levels/test_level.tscn")

func _on_settings_button_pressed() -> void:
	pass # Здесь потом сделаем вызов окна настроек (например, show() для Panel)

func _on_quit_button_pressed() -> void:
	get_tree().quit()
