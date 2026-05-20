extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0

@onready var anim = $"AnimatedSprite2D"
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var health = 100;
var crystal = 0;

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		anim.play("Jump")
		
	# Handle attack.
	if Input.is_action_just_pressed("attack"):
		anim.play("Attack")
		await anim.animation_finished

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("left", "right")
	if (health > 0):
		if direction:
			velocity.x = direction * SPEED
			if (velocity.y == 0):
				anim.play("Run")
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			if (velocity.y == 0):
				anim.play("Idle")
				
	if direction == -1:
		$AnimatedSprite2D.flip_h = true
	elif direction == 1:
		$AnimatedSprite2D.flip_h = false
	if (velocity.y > 0):
		anim.play("Fall")
	if (health <= 0):
		anim.play("Death")
		await anim.animation_finished
		queue_free()
		get_tree().change_scene_to_file("res://ui/menus/main_menu/main_menu.tscn")
	move_and_slide()
