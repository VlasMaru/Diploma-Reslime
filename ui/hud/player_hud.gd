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
	# Ищем игрока, если он еще не найден
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return
	
	# Обновляем UI только если игрок найден
	health_bar.value = player.health
	gem_label.text = str(player.crystal)
