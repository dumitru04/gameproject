# enemy.gd
extends CharacterBody2D

@export var speed = 40.0
@export var patrol_radius = 100.0
@export var death_duration = 0.5

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox 
@onready var damage_area: Area2D = $DamageArea
# ВАЖНО: Убедитесь, что основной CollisionShape2D вашего CharacterBody2D врага называется "PhysicsShape"
# Если он называется "CollisionShape2D", то измените следующую строку на:
# @onready var physics_shape: CollisionShape2D = $CollisionShape2D 
@onready var physics_shape: CollisionShape2D = $PhysicsShape 

var initial_position_x: float
var current_direction = 1
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var is_dying = false
var death_timer: Timer

func _ready():
	print("[" + name + "] _ready: Инициализация врага.")
	initial_position_x = global_position.x
	_update_sprite_facing_direction()

	if hitbox:
		var connect_error = hitbox.body_entered.connect(_on_hitbox_body_entered)
		if connect_error == OK: # OK это 0
			print("[" + name + "] _ready: Сигнал Hitbox.body_entered успешно подключен.")
		else:
			print("[" + name + "] _ready: !!! ОШИБКА подключения сигнала Hitbox.body_entered! Код ошибки: " + str(connect_error))
	else:
		print("[" + name + "] _ready: !!! ОШИБКА: Узел Hitbox не найден!")
		
	if damage_area:
		var connect_error_dmg = damage_area.body_entered.connect(_on_damage_area_body_entered)
		if connect_error_dmg == OK:
			print("[" + name + "] _ready: Сигнал DamageArea.body_entered успешно подключен.")
		else:
			print("[" + name + "] _ready: !!! ОШИБКА подключения сигнала DamageArea.body_entered! Код ошибки: " + str(connect_error_dmg))
	else:
		print("[" + name + "] _ready: !!! ОШИБКА: Узел DamageArea не найден!")

	if not physics_shape:
		print("[" + name + "] _ready: !!! ОШИБКА: Узел PhysicsShape (основная CollisionShape2D врага) не найден! Проверьте имя узла.")

	death_timer = Timer.new()
	death_timer.one_shot = true
	death_timer.wait_time = death_duration
	death_timer.timeout.connect(_on_death_timer_timeout)
	add_child(death_timer)
	print("[" + name + "] _ready: Таймер смерти создан и добавлен.")

func _physics_process(delta):
	if is_dying:
		return

	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

	velocity.x = speed * current_direction
	move_and_slide()

	var should_turn = false
	if is_on_wall():
		should_turn = true
	
	if not should_turn:
		if current_direction == 1 and global_position.x >= initial_position_x + patrol_radius:
			should_turn = true
		elif current_direction == -1 and global_position.x <= initial_position_x - patrol_radius:
			should_turn = true
	
	if should_turn:
		current_direction *= -1
		_update_sprite_facing_direction()
		velocity.x = speed * current_direction

	if animated_sprite and animated_sprite.sprite_frames: # Проверяем, что sprite_frames существует
		# ИСПРАВЛЕНО: animated_sprite.sprite_frames.has_animation
		if animated_sprite.sprite_frames.has_animation("walk"): 
			animated_sprite.play("walk")
		# else:
			# print("[" + name + "] _physics_process: Анимация 'walk' не найдена.")


func _update_sprite_facing_direction():
	if animated_sprite:
		animated_sprite.flip_h = current_direction > 0

func _on_hitbox_body_entered(body: Node2D):
	print("[" + name + "] _on_hitbox_body_entered: Сработал сигнал Hitbox. Столкновение с: " + body.name)
	
	if is_dying:
		print("[" + name + "] _on_hitbox_body_entered: Уже в процессе умирания, выход.")
		return
		
	if not body.is_in_group("player"):
		print("[" + name + "] _on_hitbox_body_entered: Столкнувшийся объект '" + body.name + "' не в группе 'player'. Выход.")
		return
	
	print("[" + name + "] _on_hitbox_body_entered: Столкнулся игрок!")
	var player = body as CharacterBody2D
	
	if not player:
		print("[" + name + "] _on_hitbox_body_entered: Не удалось привести тело к CharacterBody2D. Выход.")
		return
		
	print("[" + name + "] _on_hitbox_body_entered: Скорость игрока по Y: " + str(player.velocity.y))
	
	if player.velocity.y > 0: 
		print("[" + name + "] _on_hitbox_body_entered: Условие прыжка на врага ВЫПОЛНЕНО (velocity.y > 0).")
		
		is_dying = true
		speed = 0 
		velocity = Vector2.ZERO 
		
		if physics_shape:
			print("[" + name + "] _on_hitbox_body_entered: Отключаю PhysicsShape.")
			physics_shape.set_deferred("disabled", true)
		else:
			print("[" + name + "] _on_hitbox_body_entered: !!! PhysicsShape не найден, не могу отключить.")
			
		if hitbox: hitbox.set_deferred("monitorable", false) 
		if damage_area: damage_area.set_deferred("monitorable", false)

		if animated_sprite and animated_sprite.sprite_frames: # Проверяем, что sprite_frames существует
			# ИСПРАВЛЕНО: animated_sprite.sprite_frames.has_animation
			if animated_sprite.sprite_frames.has_animation("squashed"):
				animated_sprite.play("squashed")
				print("[" + name + "] _on_hitbox_body_entered: Проигрываю анимацию 'squashed'.")
			else:
				animated_sprite.stop()
				print("[" + name + "] _on_hitbox_body_entered: Анимация 'squashed' не найдена, останавливаю текущую анимацию.")
		
		GameManager.add_score(100)
		print("[" + name + "] Начислено 100 очков за убийство врага.")
		
		if player.has_method("get_jump_velocity"):
			player.velocity.y = player.get_jump_velocity() * 0.9 
			print("[" + name + "] _on_hitbox_body_entered: Игрок отскочил.")
		
		death_timer.start()
		print("[" + name + "] _on_hitbox_body_entered: Таймер смерти запущен на " + str(death_timer.wait_time) + " сек.")
	else:
		print("[" + name + "] _on_hitbox_body_entered: Условие прыжка на врага НЕ ВЫПОЛНЕНО (velocity.y игрока: " + str(player.velocity.y) + ").")

func _on_damage_area_body_entered(body: Node2D):
	print("[" + name + "] _on_damage_area_body_entered: Сработал сигнал DamageArea. Столкновение с: " + body.name)
	if is_dying or not body.is_in_group("player"):
		return

	var player = body as Node 
	if player and player.has_method("take_damage"):
		print("[" + name + "] _on_damage_area_body_entered: Наношу урон игроку.")
		player.take_damage()

func _on_death_timer_timeout():
	print("[" + name + "] _on_death_timer_timeout: Таймер смерти сработал. Уничтожаю врага.")
	queue_free()
