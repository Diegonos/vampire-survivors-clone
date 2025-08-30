extends CharacterBody2D

var movement_speed = 40.0
var hp = 80

var iceSpear = preload("res://scenes/ice_spear.tscn")

@onready var iceSpearTimer = get_node("%IceSpearTimer")
@onready var iceSpearAttackTimer = get_node("%IceSpearAttackTimer")

var iceSpear_ammo = 0
var iceSpear_baseAmmo = 1
var iceSpear_attackSpeed = 1.5
var iceSpear_level = 1

var enemy_close = []

@onready var sprite: Sprite2D = $Sprite2D
@onready var walk_timer: Timer = get_node("%WalkTimer")

func _ready():
	attack()
	
func attack(): 
	if iceSpear_level > 0:
		iceSpearTimer.wait_time = iceSpear_attackSpeed
		if iceSpearTimer.is_stopped():
			iceSpearTimer.start()
		

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


func _on_hurtbox_hurt(damage: Variant) -> void:
	hp -= damage
	print(hp)


func _on_ice_spear_timer_timeout() -> void:
	iceSpear_ammo += iceSpear_baseAmmo
	iceSpearAttackTimer.start()

func _on_ice_spear_attack_timer_timeout() -> void:
	if iceSpear_ammo > 0:
		var iceSpear_attack = iceSpear.instantiate()
		iceSpear_attack.position = position
		iceSpear_attack.target = get_random_target()
		iceSpear_attack.level = iceSpear_level
		add_child(iceSpear_attack)
		iceSpear_ammo -= 1
		if iceSpear_ammo > 0:
			iceSpearAttackTimer.start()
		else:
			iceSpearAttackTimer.stop()
		

func get_random_target():
	if enemy_close.size() > 0:
		return enemy_close.pick_random().global_position
	else:
		return Vector2.UP

func _on_enemy_detection_area_body_entered(body: Node2D) -> void:
	if not enemy_close.has(body):
		enemy_close.append(body)

func _on_enemy_detection_area_body_exited(body: Node2D) -> void:
	if enemy_close.has(body):
		enemy_close.erase(body)
