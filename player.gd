extends CharacterBody2D
#константы
const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const WALL_SLIDE_SPEED = 120.0  #max скорость сползания по стене
const WALL_JUMP_PUSH = 200.0    #cила отталкивания от стены по горизонтали

@onready var anim = $"AnimatedSprite2D"
@onready var animPlay = $AnimationPlayer
@onready var coyoteTimer = $CoyoteTime
@onready var wallJumpLockTimer = $WallJumpLock

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var health = 100
var crystal = 0



func _physics_process(delta: float) -> void:
	
	if not is_on_floor():
		var direction := Input.get_axis("left", "right")
		
		if is_on_wall() and velocity.y > 0 and direction != 0:
			velocity.y = move_toward(velocity.y, WALL_SLIDE_SPEED, gravity * delta)
			if health > 0:
				animPlay.play("WallSlide")
		else:
			velocity.y += gravity * delta
			
	if health <= 0:
		velocity.x = 0
		animPlay.play("Death")
		if not animPlay.is_playing():
			queue_free()
			get_tree().change_scene_to_file("res://ui/menus/main_menu/main_menu.tscn")
		move_and_slide()
		return

	# обработка прыжков 
	if Input.is_action_just_pressed("jump"):
		if (is_on_floor() || !coyoteTimer.is_stopped()):
			velocity.y = JUMP_VELOCITY
			animPlay.play("Jump")
			coyoteTimer.stop()
		elif is_on_wall() and not is_on_floor():
			var wall_normal = get_wall_normal() 
			velocity.y = JUMP_VELOCITY
			velocity.x = wall_normal.x * WALL_JUMP_PUSH 
			wallJumpLockTimer.start() 
			
			$AnimatedSprite2D.flip_h = wall_normal.x < 0
			animPlay.play("Jump")

	if Input.is_action_just_pressed("attack"):
		animPlay.play("Attack")

	var direction := Input.get_axis("left", "right")
	
	if wallJumpLockTimer.is_stopped():
		if direction:
			velocity.x = direction * SPEED
			if not is_on_wall() or is_on_floor():
				$AnimatedSprite2D.flip_h = (direction == -1)
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			
	var was_on_floor = is_on_floor()
	_update_animations(direction)

	move_and_slide()
	if was_on_floor and not is_on_floor() and velocity.y >= 0:
		coyoteTimer.start()


func _update_animations(direction: float) -> void:
	if animPlay.current_animation  == "Attack" and animPlay.is_playing():
		return
		
	if is_on_floor():
		if direction != 0:
			animPlay.play("Run")
		else:
			animPlay.play("Idle")
	else:
		if animPlay.current_animation != "WallSlide":
			if velocity.y > 0:
				animPlay.play("Fall")
			elif velocity.y < 0:
				animPlay.play("Jump")
