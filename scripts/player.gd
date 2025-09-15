extends CharacterBody2D

var movement_speed = 40.0
var hp = 80
var maxhp = 80
var last_movement = Vector2.UP
var time = 0 

var experience = 0
var experience_level = 1
var collected_experience = 0

var iceSpear = preload("res://scenes/ice_spear.tscn")
var tornado = preload("res://scenes/tornado.tscn")
var javelin = preload("res://scenes/javelin.tscn")

@onready var iceSpearTimer = get_node("%IceSpearTimer")
@onready var iceSpearAttackTimer = get_node("%IceSpearAttackTimer")
@onready var tornadoTimer = get_node("%TornadoTimer")
@onready var tornadoAttackTimer = get_node("%TornadoAttackTimer")
@onready var javelin_base: Node = get_node("%JavelinBase")

#Upgrades
var collected_upgrades = []
var upgrade_options = []
var armor = 0
var speed = 0
var spell_cooldown = 0
var spell_size = 0
var additional_attacks = 0

var iceSpear_ammo = 0
var iceSpear_baseAmmo = 0
var iceSpear_attackSpeed = 1.5
var iceSpear_level = 0

var tornado_ammo = 0
var tornado_baseAmmo = 0
var tornado_attackSpeed = 3
var tornado_level = 0

var javelin_ammo = 0
var javelin_level = 0

var enemy_close = []

@onready var sprite: Sprite2D = $Sprite2D
@onready var walk_timer: Timer = get_node("%WalkTimer")

@onready var experience_bar: TextureProgressBar = get_node("%ExperienceBar")
@onready var lbl_level: Label = get_node("%Lbl_level")

@onready var levelPanel: Panel = get_node("%LevelUp")
@onready var upgradeOptions = get_node("%UpgradeOptions")
@onready var sndLevelUp = get_node("%snd_levelup")
@onready var healthBar = get_node("%HealthBar")
@onready var lblTimer = get_node("%lblTimer")
@onready var collectedWeapons = get_node("%CollectedWeapons")
@onready var collectedUpgrades = get_node("%CollectedUpgrades")
@onready var itemContainer = preload("res://scenes/item_container.tscn")

@onready var itemOptions = preload("res://scenes/item_option.tscn")

@onready var deathPanel = get_node("%DeathPanel")
@onready var lblResult = get_node("%lbl_Result")
@onready var sndVictory = get_node("%snd_victory")
@onready var sndLose = get_node("%snd_lose")

signal playerdeath

func _ready():
	upgrade_character("icespear1")
	attack()
	set_expbar(experience, calculate_experience_cap())
	_on_hurtbox_hurt(0,0,0)
	
func attack(): 
	if iceSpear_level > 0:
		iceSpearTimer.wait_time = iceSpear_attackSpeed * (1 - spell_cooldown)
		if iceSpearTimer.is_stopped():
			iceSpearTimer.start()
	if tornado_level > 0:
		tornadoTimer.wait_time = tornado_attackSpeed * (1 - spell_cooldown)
		if tornadoTimer.is_stopped():
			tornadoTimer.start()
	if javelin_level > 0:
		spawn_javelin()

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
		last_movement = mov
		if walk_timer.is_stopped():
			if sprite.frame >= sprite.hframes - 1:
				sprite.frame = 0
			else: 
				sprite.frame = 1
			walk_timer.start()
	velocity = mov.normalized() * movement_speed
	move_and_slide()


func _on_hurtbox_hurt(damage: Variant, _angle, _knockback) -> void:
	hp -= clamp(damage - armor, 1.0, 999.0)
	healthBar.max_value = maxhp
	healthBar.value = hp
	if hp <= 0:
		death()

func _on_ice_spear_timer_timeout() -> void:
	iceSpear_ammo += iceSpear_baseAmmo + additional_attacks
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
			
func _on_tornado_timer_timeout() -> void:
	tornado_ammo += tornado_baseAmmo + additional_attacks
	tornadoAttackTimer.start()

func _on_tornado_attack_timer_timeout() -> void:
	if tornado_ammo > 0:
		var tornado_attack = tornado.instantiate()
		tornado_attack.position = position
		tornado_attack.last_movement = last_movement
		tornado_attack.level = tornado_level
		add_child(tornado_attack)
		tornado_ammo -= 1
		if tornado_ammo > 0:
			tornadoAttackTimer.start()
		else:
			tornadoAttackTimer.stop()

func spawn_javelin():
	var get_javelin_total = javelin_base.get_child_count()
	var calc_spawns = (javelin_ammo + additional_attacks) - get_javelin_total
	while calc_spawns > 0:
		var javelin_spawn = javelin.instantiate()
		javelin_spawn.global_position = global_position
		javelin_base.add_child(javelin_spawn)
		calc_spawns -= 1
	var get_javelins = javelin_base.get_children()
	for i in get_javelins:
		if i.has_method("update_javelin"):
			i.update_javelin()

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


func _on_grab_area_area_entered(area: Area2D) -> void:
	if area.is_in_group("loot"):
		area.target = self

func _on_collect_area_area_entered(area: Area2D) -> void:
	if area.is_in_group("loot"):
		var gem_exp = area.collect()
		calculate_experience(gem_exp)

func calculate_experience(gem_exp):
	var exp_required = calculate_experience_cap()
	collected_experience += gem_exp
	if experience + collected_experience >= exp_required: #level up
		collected_experience -= exp_required - experience
		experience_level += 1
		experience = 0
		exp_required = calculate_experience_cap()
		levelup()
	else:
		experience += collected_experience
		collected_experience = 0
		
	set_expbar(experience, exp_required)

func calculate_experience_cap():
	var exp_cap = experience_level
	if experience_level < 20:
		exp_cap = experience_level * 5
	elif experience_level < 40:
		exp_cap = 95 * (experience_level - 19) * 8
	else: 
		exp_cap = 255 + (experience_level - 39) * 12
	return exp_cap

func set_expbar(set_value = 1, set_max_value = 100):
	experience_bar.value = set_value
	experience_bar.max_value = set_max_value
	
func levelup():
	sndLevelUp.play()
	lbl_level.text = str("Level: ", experience_level)
	var tween = levelPanel.create_tween()
	tween.tween_property(levelPanel, "position", Vector2(220, 50), 0.2).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	tween.play()
	levelPanel.visible = true
	var options = 0
	var options_max = 3
	while options < options_max:
		var option_choice = itemOptions.instantiate()
		option_choice.item = get_random_item()
		upgradeOptions.add_child(option_choice)
		options += 1
	get_tree().paused = true

func upgrade_character(upgrade):
	match upgrade:
		"icespear1":
			iceSpear_level = 1
			iceSpear_baseAmmo += 1
		"icespear2":
			iceSpear_level = 2
			iceSpear_baseAmmo += 1
		"icespear3":
			iceSpear_level = 3
		"icespear4":
			iceSpear_level = 4
			iceSpear_baseAmmo += 2
		"tornado1":
			tornado_level = 1
			tornado_baseAmmo += 1
		"tornado2":
			tornado_level = 2
			tornado_baseAmmo += 1
		"tornado3":
			tornado_level = 3
			tornado_attackSpeed -= 0.5
		"tornado4":
			tornado_level = 4
			tornado_baseAmmo += 1
		"javelin1":
			javelin_level = 1
			javelin_ammo = 1
		"javelin2":
			javelin_level = 2
		"javelin3":
			javelin_level = 3
		"javelin4":
			javelin_level = 4
		"armor1","armor2","armor3","armor4":
			armor += 1
		"speed1","speed2","speed3","speed4":
			movement_speed += 20.0
		"tome1","tome2","tome3","tome4":
			spell_size += 0.10
		"scroll1","scroll2","scroll3","scroll4":
			spell_cooldown += 0.05
		"ring1","ring2":
			additional_attacks += 1
		"food":
			hp += 20
			hp = clamp(hp,0,maxhp)
	adjust_gui_collection(upgrade)
	attack()
	var option_children = upgradeOptions.get_children()
	for i in option_children:
		i.queue_free()
	upgrade_options.clear()
	collected_upgrades.append(upgrade)
	levelPanel.visible = false
	levelPanel.position = Vector2(800,50)
	get_tree().paused = false
	calculate_experience(0)
	
func get_random_item():
	var dblist = []
	for i in UpgradeDb.UPGRADES:
		if i in collected_upgrades: #already collected upgrade
			pass
		elif i in upgrade_options: # if it is already an option
			pass
		elif UpgradeDb.UPGRADES[i]["type"] == "item":
			pass
		elif UpgradeDb.UPGRADES[i]["prerequisite"].size() > 0:
			var to_add = true
			for n in UpgradeDb.UPGRADES[i]["prerequisite"]:
				if not n in collected_upgrades:
					to_add = false
			if to_add: 
				dblist.append(i)
				
		else:
			dblist.append(i)
	if dblist.size() > 0:
		var randomitem = dblist.pick_random()
		upgrade_options.append(randomitem)
		return randomitem
	else:
		return null
		

func change_time(argtime = 0):
	time = argtime
	var get_m = int(time / 60.0)
	var get_s = time % 60
	if get_m < 10:
		get_m = str(0, get_m)
	if get_s < 10:
		get_s = str(0, get_s)
	lblTimer.text = str(get_m, ":", get_s)

func adjust_gui_collection(upgrade):
	var get_upgraded_displaynames = UpgradeDb.UPGRADES[upgrade]["displayname"]
	var get_type = UpgradeDb.UPGRADES[upgrade]["type"]
	if get_type != "item":
		var get_collected_displaynames = []
		for i in collected_upgrades:
			get_collected_displaynames.append(UpgradeDb.UPGRADES[i]["displayname"])
		if not get_upgraded_displaynames in get_collected_displaynames:
			var new_item = itemContainer.instantiate()
			new_item.upgrade = upgrade
			match get_type:
				"weapon":
					collectedWeapons.add_child(new_item)
				"upgrade":
					collectedUpgrades.add_child(new_item)
			
func death():
	deathPanel.visible = true
	emit_signal("playerdeath")
	get_tree().paused = true
	var tween = deathPanel.create_tween()
	tween.tween_property(deathPanel, "position", Vector2(220, 50), 3.0).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.play()
	if time >= 300:
		lblResult.text = "You Won"
		sndVictory.play()
	else:
		lblResult.text = "You Lost"
		sndLose.play()

func _on_btn_menu_click_end() -> void:
	get_tree().paused = false
	var _level = get_tree().change_scene_to_file("res://scenes/menu.tscn")
