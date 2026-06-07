extends Node

var max_health: int = 100
var current_health: int = 100
var damage: int = 10

var speed: float = 300.0
var jump_velocity: float = -400.0
var wall_slide_speed: float = 120.0
var wall_jump_push: float = 200.0 

var crystals: int = 10

var cur_armor: int = 0
var cur_weapon: int = 0
var cur_accessory: int = 0

var cur_level: int = 1
var cur_level_type: String = "cave"


func recalculate_stats():
	match cur_weapon:
		0:
			damage = 10
		1:
			damage = 20
		2:
			damage = 30

	match cur_armor:
		0:
			max_health = 100
		1:
			max_health = 125
		2:
			max_health = 150

	match cur_accessory:
		0:
			speed = 300
		1:
			speed = 325
		2:
			speed = 350

	current_health = max_health
  
 
