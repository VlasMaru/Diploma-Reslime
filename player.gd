extends CharacterBody2D

enum {
	MOVE,
	JUMP,
	FALL,
	WALLSLIDE,
	ATTACK,
	DEATH 
}

#константы
const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const WALL_SLIDE_SPEED = 120.0  
const WALL_JUMP_PUSH = 200.0   

@onready var anim = $"AnimatedSprite2D"
@onready var animPlay = $AnimationPlayer
@onready var coyoteTimer = $CoyoteTime
@onready var wallJumpLockTimer = $WallJumpLock

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var health = 100
var crystal = 0
var state = MOVE

func _ready() -> void:
	animPlay.animation_finished.connect(_on_animation_finished)

func _physics_process(delta: float) -> void:
	if health <= 0 and state != DEATH:
		state = DEATH
		handle_death()
	if state == DEATH:
		if not is_on_floor():
			velocity.y += gravity * delta
		move_and_slide()
		return
	var was_on_floor = is_on_floor()
	match state:
		MOVE:
			move_state(delta)
		JUMP:
			jump_state(delta)
		FALL:
			fall_state(delta)
		WALLSLIDE:
			wallslide_state(delta)
		ATTACK:
			attack_state(delta)

	move_and_slide()
	if was_on_floor and not is_on_floor() and velocity.y >= 0:
		coyoteTimer.start()


# состояния

func move_state(delta: float) -> void:
	apply_base_movement(delta)
	if velocity.x != 0:
		animPlay.play("Run")
	else:
		animPlay.play("Idle")
		
	if not is_on_floor():
		state = FALL
	elif Input.is_action_just_pressed("jump"):
		perform_jump()
	elif Input.is_action_just_pressed("attack"):
		perform_attack()

func jump_state(delta: float) -> void:
	apply_base_movement(delta)
	animPlay.play("Jump")
	
	if velocity.y >= 0:
		state = FALL
	elif Input.is_action_just_pressed("attack"):
		perform_attack()

func fall_state(delta: float) -> void:
	apply_base_movement(delta)
	animPlay.play("Fall")
	
	var direction := Input.get_axis("left", "right")
	
	if is_on_floor():
		state = MOVE
	elif is_on_wall() and direction != 0:
		state = WALLSLIDE
	elif Input.is_action_just_pressed("jump") and not coyoteTimer.is_stopped():
		perform_jump()
		coyoteTimer.stop()
	elif Input.is_action_just_pressed("attack"):
		perform_attack()

func wallslide_state(delta: float) -> void:
	velocity.y = move_toward(velocity.y, WALL_SLIDE_SPEED, gravity * delta)
	animPlay.play("WallSlide")
	
	var direction := Input.get_axis("left", "right")
	
	if is_on_floor():
		state = MOVE
	elif not is_on_wall() or direction == 0:
		state = FALL
	elif Input.is_action_just_pressed("jump"):
		perform_wall_jump()

func attack_state(delta: float) -> void:
	apply_base_movement(delta)


#вспомогательные функции
func apply_base_movement(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	var direction := Input.get_axis("left", "right")
	
	if wallJumpLockTimer.is_stopped():
		if direction:
			velocity.x = direction * SPEED
			if not is_on_wall() or is_on_floor():
				anim.flip_h = (direction == -1)
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

func perform_jump() -> void:
	velocity.y = JUMP_VELOCITY
	state = JUMP

func perform_wall_jump() -> void:
	var wall_normal = get_wall_normal()
	velocity.y = JUMP_VELOCITY
	velocity.x = wall_normal.x * WALL_JUMP_PUSH
	wallJumpLockTimer.start()
	anim.flip_h = wall_normal.x < 0
	state = JUMP

func perform_attack() -> void:
	animPlay.play("Attack")
	state = ATTACK

func handle_death() -> void:
	velocity.x = 0
	animPlay.play("Death")
	await animPlay.animation_finished
	get_tree().call_deferred("change_scene_to_file", "res://ui/menus/main_menu/main_menu.tscn")
	

func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "Attack":
		if is_on_floor():
			state = MOVE
		else:
			state = FALL
