extends CharacterBody2D

@export var crystal_scene: PackedScene

enum {
	IDLE,
	ATTACK,
	ATTACK_COOLDOWN,
	CHASE,
	DEATH,
	DAMAGE
}

var state: int = IDLE:
	set(val):
		if state == DEATH:
			return

		if state == val:
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

var player_in_range = false
var alive = true

@onready var anim = $AnimatedSprite2D
@onready var animPlayer = $AnimationPlayer
@onready var attack_cooldown = $AttackCooldown


func _ready() -> void:
	Signals.connect("player_position_update", Callable(self, "_on_player_position_update"))
	animPlayer.animation_finished.connect(_on_animation_finished)


func _physics_process(delta: float) -> void:
	if health <= 0 and state != DEATH:
		state = DEATH

	if not is_on_floor():
		velocity += get_gravity() * delta

	if state == DEATH:
		move_and_slide()
		return

	match state:
		CHASE:
			chase_state()

		ATTACK_COOLDOWN:
			velocity.x = 0

	move_and_slide()


func _on_player_position_update(pos: Vector2):
	player_pos = pos


func enter_state():
	match state:
		IDLE:
			velocity.x = 0
			animPlayer.play("Idle")

		CHASE:
			animPlayer.play("Run")

			$AttackDirection/AttackRange/CollisionShape2D.set_deferred("disabled", false)
			$Detector/CollisionShape2D.set_deferred("disabled", false)

		ATTACK:
			velocity.x = 0
			animPlayer.play("Bite")

		ATTACK_COOLDOWN:
			velocity.x = 0
			animPlayer.play("Idle")
			attack_cooldown.start()

		DAMAGE:
			velocity.x = 0
			animPlayer.play("GetHit")

		DEATH:
			death()


func chase_state():
	direction = (player_pos - position).normalized()
	velocity.x = direction.x * speed
	
	if direction.x < 0:
		anim.flip_h = true
		$AttackDirection.rotation_degrees = 180

	elif direction.x > 0:
		anim.flip_h = false
		$AttackDirection.rotation_degrees = 0

	if is_on_floor():
		if is_on_wall() or player_pos.y < position.y - 50:
			velocity.y = JUMP_VELOCITY

	if player_in_range:
		state = ATTACK


func deal_damage():
	var bodies = $AttackDirection/AttackRange.get_overlapping_bodies()

	for body in bodies:
		if body.name == "Player":
			body.health -= 20


func _on_animation_finished(anim_name: String):
	match anim_name:
		"Bite":
			if state != DEATH:
				state = ATTACK_COOLDOWN

		"GetHit":
			if state != DEATH:
				state = CHASE


func _on_detector_body_entered(body: Node2D) -> void:
	if body.name == "Player" and state != DEATH:
		state = CHASE


func _on_detector_body_exited(body: Node2D) -> void:
	if body.name == "Player" and state != DEATH:
		state = IDLE


func _on_attack_range_body_entered(body: Node2D) -> void:
	if body.name == "Player" and state != DEATH:
		player_in_range = true


func _on_attack_range_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_in_range = false
		
		if state == ATTACK_COOLDOWN:
			state = CHASE


func _on_attack_cooldown_timeout():
	if state == DEATH:
		return

	if player_in_range:
		state = ATTACK
	else:
		state = CHASE


func death():
	alive = false

	velocity.x = 0

	$AttackDirection/AttackRange/CollisionShape2D.set_deferred( "disabled", true)

	animPlayer.play("Death")

	await animPlayer.animation_finished
	
	var crystal = crystal_scene.instantiate()
	crystal.global_position = global_position
	get_parent().add_child(crystal)

	Signals.emit_signal("enemy_died")

	queue_free()
