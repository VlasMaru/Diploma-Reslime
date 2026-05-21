extends CharacterBody2D

var chase = false
var speed = 200
@onready var anim = $"AnimatedSprite2D"
var alive = true

func _physics_process(delta: float) -> void:
	
	if not is_on_floor():
		velocity += get_gravity() * delta
	var player = $"../../Player/Player"
	var direction = (player.position - self.position).normalized()
	if (alive):
		if chase == true:
			velocity.x = direction.x * speed
			if (velocity.y == 0):
				anim.play("Run")
		else:
			velocity.x = 0
			anim.play("Idle")
		
	if direction.x < 0 :
		$AnimatedSprite2D.flip_h = true
	elif direction.x > 0 :
		$AnimatedSprite2D.flip_h = false
	
	move_and_slide()
	
	
	

func _on_detector_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		chase = true

func _on_detector_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		chase = false


func _on_detector_death_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		body.velocity.y-= 200
		death()

func death():
	alive = false
	anim.play("Death")
	await anim.animation_finished
	queue_free()


func _on_detector_attack_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		body.health-=40
		death()
