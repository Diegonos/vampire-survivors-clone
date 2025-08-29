extends CharacterBody2D

var movement_speed = 40.0
@onready var sprite: Sprite2D = $Sprite2D
@onready var walk_timer: Timer = get_node("%WalkTimer")

func _physics_process(_delta: float) -> void: 
	movement()

func movement(): 
	var x_mov = Input.get_action_strength("right") - Input.get_action_strength("left")
	var y_mov = Input.get_action_strength("down") - Input.get_action_strength("up")
	var mov = Vector2(x_mov, y_mov)

	if mov.x > 0:
		sprite.flip_h = true
	elif mov.x < 0:
		sprite.flip_h = false
	if mov != Vector2.ZERO:
		if walk_timer.is_stopped():
			if sprite.frame >= sprite.hframes - 1:
				sprite.frame = 0
			else: 
				sprite.frame = 1
			walk_timer.start()
	velocity = mov.normalized() * movement_speed
	move_and_slide()
