extends CharacterBody2D

var chase = false
var speed = 200.0
const JUMP_VELOCITY = -400.0 

@onready var anim = $"AnimatedSprite2D"
@onready var animPlayer = $AnimationPlayer
var alive = true

func _physics_process(delta: float) -> void:
	if not alive:
		return

	if not is_on_floor():
		velocity += get_gravity() * delta
		
	var player = $"../../Player/Player"
	var direction = (player.position - self.position).normalized()
	
	if chase == true:
		velocity.x = direction.x * speed
		
		# крыса прыгает, если стоит на земле И (уперлась в стену ИЛИ игрок находится значительно выше)
		if is_on_floor():
			if is_on_wall() or (player.position.y < self.position.y - 50):
				velocity.y = JUMP_VELOCITY	
		if is_on_floor():
			anim.play("Run")
		else:
			pass 
	else:
		velocity.x = move_toward(velocity.x, 0, speed) # Плавная остановка
		if is_on_floor():
			anim.play("Idle")
		
	# Разворот спрайта
	if direction.x < 0 :
		anim.flip_h = true
	elif direction.x > 0 :
		anim.flip_h = false
	
	move_and_slide()

func _on_detector_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		chase = true

func _on_detector_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		chase = false

func _on_detector_death_body_entered(body: Node2D) -> void:
	if body.name == "Player" and alive:
		body.velocity.y -= 200 # Отскок игрока
		death()

func _on_detector_attack_body_entered(body: Node2D) -> void:
	if body.name == "Player" and alive:
		animPlayer.play("Bite")
		body.health -= 100
		death()

func death():
	alive = false
	velocity = Vector2.ZERO 
	$CollisionShape2D.set_deferred("disabled", true) 
	anim.play("Death")
	anim.animation_finished.connect(queue_free)
