extends CanvasLayer

@onready var health_bar: ProgressBar = $MarginContainer/HBoxContainer/VBoxContainerStats/HealthSection/HealthBar
@onready var gem_label: Label = $MarginContainer/HBoxContainer/VBoxContainerStats/CurrencySection/GemLabel

@onready var weapon_icons: Array = [
	$MarginContainer/HBoxContainer/WeaponSlots/WeaponIcon,
	$MarginContainer/HBoxContainer/WeaponSlots/ArmorIcon,
	$MarginContainer/HBoxContainer/WeaponSlots/JewelryIcon
]

var player: CharacterBody2D = null

func _process(_delta: float) -> void:
	# 1. Если игрок не найден или ссылка на него устарела, ищем снова
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
	
	# 2. Если после поиска игрок все еще null (не найден), выходим из функции
	if not is_instance_valid(player):
		return
	
	# 3. Обновляем UI только если мы точно знаем, что игрок существует
	# Используем проверку 'get', чтобы избежать ошибок, если у игрока нет свойств
	if "health" in player:
		health_bar.value = player.health
	
	if "crystal" in player:
		gem_label.text = str(player.crystal)
