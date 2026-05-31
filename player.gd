extends CharacterBody2D
enum {
	MOVE,
	JUMP,
	FALL,
	WALLSLIDE,
	ATTACK,
	DAMAGE,
	DEATH 
}

@onready var anim = $"AnimatedSprite2D"
@onready var animPlay = $AnimationPlayer
@onready var coyoteTimer = $CoyoteTime
@onready var wallJumpLockTimer = $WallJumpLock

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var health: int = PlayerStats.current_health:
	set(val):
		if state == DEATH:
			return
		if val < health:
			state = DAMAGE
			animPlay.play("Damage")
			PlayerStats.current_health = val
			health = val

var bodyInAttackRange = false
var target
var player_pos 
var state = MOVE

func _ready() -> void:
	animPlay.animation_finished.connect(_on_animation_finished)
	$HurtBox.add_to_group("hurtbox")

func _physics_process(delta: float) -> void:
	# обработка смерти
	if health <= 0 and state != DEATH:
		state = DEATH
		handle_death()
		
	if state == DEATH:
		if not is_on_floor():
			velocity.y += gravity * delta
		move_and_slide()
		return
	
	var was_on_floor = is_on_floor()
	# конечный автомат
	match state:
		MOVE:
			move_state(delta)
		JUMP:
			jump_state(delta)
		FALL:
			$CollisionShape2D.shape.size = Vector2(9, 14)
			fall_state(delta)
		WALLSLIDE:
			$CollisionShape2D.shape.size = Vector2(9, 14)
			wallslide_state(delta)
		ATTACK:
			attack_state(delta)
		DAMAGE:
			damage_state(delta) 

	move_and_slide()
	player_pos = self.position
	Signals.emit_signal("player_position_update", player_pos)
	if was_on_floor and not is_on_floor() and velocity.y >= 0:
		coyoteTimer.start()


# состояния

func move_state(delta: float) -> void:
	apply_base_movement(delta)
	if velocity.x != 0:
		$CollisionShape2D.shape.size = Vector2(19, 14)
		animPlay.play("Run")
	else:
		$CollisionShape2D.shape.size = Vector2(19, 14)
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
	velocity.y = move_toward(velocity.y, PlayerStats.wall_slide_speed, gravity * delta)
	$CollisionShape2D.shape.size = Vector2(11, 14)
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
	
func damage_state(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	velocity.x = move_toward(velocity.x, 0, PlayerStats.speed)

#ловит пользовательский ввод
func apply_base_movement(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
		
	var direction := Input.get_axis("left", "right")
	if wallJumpLockTimer.is_stopped():
		if direction:
			velocity.x = direction * PlayerStats.speed
			if not is_on_wall() or is_on_floor():
				anim.flip_h = (direction == -1)
				if (direction == -1):
					$AttackDirection.rotation_degrees = 180
				else:
					$AttackDirection.rotation_degrees = 0
		else:
			velocity.x = move_toward(velocity.x, 0, PlayerStats.speed)

func perform_jump() -> void:
	velocity.y = PlayerStats.jump_velocity
	state = JUMP

func perform_wall_jump() -> void:
	var wall_normal = get_wall_normal()
	velocity.y = PlayerStats.jump_velocity
	velocity.x = wall_normal.x * PlayerStats.wall_jump_push
	wallJumpLockTimer.start()
	anim.flip_h = wall_normal.x < 0
	if (wall_normal.x < 0):
		$AttackDirection.rotation_degrees = 180
	else:
		$AttackDirection.rotation_degrees = 0
	state = JUMP

func perform_attack() -> void:
	animPlay.play("Attack")
	state = ATTACK
	if bodyInAttackRange and target != null:
		target.health -= PlayerStats.damage
		if ($AttackDirection.rotation_degrees == 0):
			target.velocity.x += 200
		else:
			target.velocity.x -= 200
		




func handle_death() -> void:
	velocity.x = 0
	animPlay.play("Death")
	await animPlay.animation_finished
	PlayerStats.current_health = 100
	get_tree().call_deferred("change_scene_to_file", "res://ui/menus/main_menu/main_menu.tscn")
	

func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "Attack" or anim_name == "Damage":
		if is_on_floor():
			state = MOVE
		else:
			state = FALL


func _on_attack_range_body_entered(body: Node2D) -> void:
	bodyInAttackRange = true
	target = body


func _on_attack_range_body_exited(body: Node2D) -> void:
	bodyInAttackRange = false
