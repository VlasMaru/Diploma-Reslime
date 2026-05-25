extends CharacterBody2D
enum {
	IDLE,
	ATTACK,
	CHASE, 
	DEATH,
	DAMAGE 
}

var state: int = IDLE:
	set(val):
		if state == DEATH:
			return
		state = val
		enter_state()


var health: int = 20:
	set(val):
		if state == DEATH:
			return
		health = val
		if health > 0:
			state = DAMAGE

var player_pos: Vector2 = Vector2.ZERO 
var direction: Vector2 = Vector2.ZERO
var speed = 200.0
const JUMP_VELOCITY = -400.0 

@onready var anim = $"AnimatedSprite2D"
@onready var animPlayer = $AnimationPlayer
var alive = true

func _ready() -> void:
	Signals.connect("player_position_update", Callable(self,"_on_player_position_update"))
	animPlayer.animation_finished.connect(_on_animation_finished)

func _on_player_position_update(pos: Vector2):
	player_pos = pos

func enter_state():
	match state:
		IDLE:
			velocity.x = 0
			animPlayer.play("Idle")
			$AttackDirection/AttackRange/CollisionShape2D.set_deferred("disabled", false)
			$Detector/CollisionShape2D.set_deferred("disabled", false)
		ATTACK:
			velocity.x = 0
			animPlayer.play("Bite")
			deal_damage()
		DAMAGE:
			velocity.x = 0
			animPlayer.play("GetHit")
		DEATH:
			death()

func _physics_process(delta: float) -> void:
	if health <= 0 and state != DEATH:
		state = DEATH
		
	if not is_on_floor():
		velocity += get_gravity() * delta

	if state == DEATH:
		move_and_slide()
		return

	if state == CHASE:
		chase_state()
		
	move_and_slide()


func chase_state():
	direction = (player_pos - self.position).normalized()
	
	velocity.x = direction.x * speed
	
	if direction.x < 0 :
		anim.flip_h = true
		$AttackDirection.rotation_degrees = 180
	elif direction.x > 0 :
		anim.flip_h = false
		$AttackDirection.rotation_degrees = 0
		
	if is_on_floor():
		if is_on_wall() or (player_pos.y < self.position.y - 50):
			velocity.y = JUMP_VELOCITY
		animPlayer.play("Run")

func deal_damage():
	var bodies = $AttackDirection/AttackRange.get_overlapping_bodies()
	for body in bodies:
		if body.name == "Player":
			body.health -= 20



func _on_animation_finished(anim_name: String):
	if anim_name == "Bite" and state != DEATH:
		$AttackDirection/AttackRange/CollisionShape2D.set_deferred("disabled", true)
		$Detector/CollisionShape2D.set_deferred("disabled", true)
		state = IDLE
	
	# 4. Выход из состояния получения урона
	elif anim_name == "GetHit" and state != DEATH:
		# После получения удара крыса агрессивно продолжает погоню
		state = CHASE

func _on_detector_body_entered(body: Node2D) -> void:
	if body.name == "Player" and state != DEATH:
		state = CHASE

func _on_detector_body_exited(body: Node2D) -> void:
	if body.name == "Player" and state != DEATH:
		state = IDLE

func _on_attack_range_body_entered(body: Node2D) -> void:
	if body.name == "Player" and state != DEATH:
		state = ATTACK

func _on_detector_death_body_entered(body: Node2D) -> void:
	if body.name == "Player" and state != DEATH:
		body.velocity.y -= 200 # Отскок игрока
		state = DEATH

func death():
	alive = false
	velocity.x = 0
	$AttackDirection/AttackRange/CollisionShape2D.set_deferred("disabled", true)
	anim.play("Death")
	anim.animation_finished.connect(queue_free)
