# enemy.gd
extends CharacterBody2D

@export var speed = 40.0
@export var patrol_radius = 80.0 # Как далеко от начальной точки патрулировать, если нет стен/обрывов
@export var death_duration = 0.5 # Время в секундах для анимации смерти (например, затухания)

# Настройки для RayCast, определяющего край платформы
@export var ledge_check_distance_y: float = 20.0 # Насколько низко будет смотреть луч RayCast от "ног" врага
@export var ledge_check_offset_x_from_edge: float = 5.0 # Насколько вперед от КРАЯ врага будет смотреть луч

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox # Зона для получения урона от игрока (прыжок сверху)
@onready var damage_area: Area2D = $DamageArea # Зона для нанесения урона игроку
@onready var physics_shape: CollisionShape2D = $PhysicsShape # Основная форма столкновений CharacterBody2D
@onready var ledge_raycast: RayCast2D = $LedgeRaycast # RayCast для определения края платформы

var initial_position_x: float
var current_direction = 1 # 1 для движения вправо, -1 для движения влево
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var is_dying = false # Флаг состояния "умирания"
var death_timer: Timer # Таймер для полного удаления после смерти

func _ready():
	print("[" + name + "] _ready: Инициализация врага.")
	initial_position_x = global_position.x
	_update_sprite_facing_direction()

	# Подключение сигналов от Area2D
	if hitbox:
		var connect_error_hitbox = hitbox.body_entered.connect(_on_hitbox_body_entered)
		if connect_error_hitbox == OK:
			print("[" + name + "] _ready: Сигнал Hitbox.body_entered успешно подключен.")
		else:
			print("[" + name + "] _ready: !!! ОШИБКА подключения сигнала Hitbox. Код: " + str(connect_error_hitbox))
	else:
		print("[" + name + "] _ready: !!! ОШИБКА: Узел Hitbox не найден!")
		
	if damage_area:
		var connect_error_damage = damage_area.body_entered.connect(_on_damage_area_body_entered)
		if connect_error_damage == OK:
			print("[" + name + "] _ready: Сигнал DamageArea.body_entered успешно подключен.")
		else:
			print("[" + name + "] _ready: !!! ОШИБКА подключения сигнала DamageArea. Код: " + str(connect_error_damage))
	else:
		print("[" + name + "] _ready: !!! ОШИБКА: Узел DamageArea не найден!")

	# Проверка наличия обязательных узлов
	if not physics_shape: print("[" + name + "] _ready: !!! ОШИБКА: Узел PhysicsShape (основная CollisionShape2D) не найден!")
	if not ledge_raycast: print("[" + name + "] _ready: !!! ОШИБКА: Узел LedgeRaycast не найден!")

	# Создание и настройка таймера смерти
	death_timer = Timer.new()
	death_timer.one_shot = true
	death_timer.wait_time = death_duration
	death_timer.timeout.connect(_on_death_timer_timeout)
	add_child(death_timer) # Добавляем таймер как дочерний узел, чтобы он работал
	print("[" + name + "] _ready: Таймер смерти создан и добавлен. Длительность: " + str(death_duration))


func _physics_process(delta):
	if is_dying:
		# Логика во время "умирания" (например, затухание)
		if death_timer.is_stopped(): # Если таймер еще не запущен или уже сработал
			animated_sprite.modulate.a = 0.0 # Убедиться, что полностью прозрачный
		elif death_timer.wait_time > 0: # Избегаем деления на ноль
			# Прогресс затухания от 1.0 (полностью видим) до 0.0 (полностью прозрачен)
			animated_sprite.modulate.a = death_timer.time_left / death_timer.wait_time
		
		# Можно добавить другие эффекты, например, уменьшение размера:
		# var scale_value = death_timer.time_left / death_timer.wait_time
		# animated_sprite.scale = Vector2(scale_value, scale_value)
		return # Прерываем дальнейшую обработку физики для умирающего врага

	# Гравитация
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0 # Сбрасываем вертикальную скорость, если на земле

	# Настройка и проверка LedgeRaycast
	var about_to_fall_off_ledge = false
	if ledge_raycast and physics_shape and is_on_floor(): # Проверяем обрыв только если на полу
		# Ширина физической формы врага (учитывая масштаб самого врага, если он есть)
		var enemy_scaled_half_width = (physics_shape.shape.get_rect().size.x / 2.0) * global_scale.x
		
		# RayCast должен быть расположен у переднего края врага по направлению движения.
		# target_position отсчитывается от локальной позиции узла LedgeRaycast.
		# Если LedgeRaycast.position = (0,0) относительно Enemy, то это от центра Enemy.
		var ray_target_x_component = (enemy_scaled_half_width + ledge_check_offset_x_from_edge) * current_direction
		ledge_raycast.target_position = Vector2(ray_target_x_component, ledge_check_distance_y)
		ledge_raycast.force_raycast_update() # Принудительное обновление состояния RayCast перед проверкой
		
		if not ledge_raycast.is_colliding():
			about_to_fall_off_ledge = true
			# print(f"[{name}] LedgeRaycast не сталкивается. target_pos: {ledge_raycast.target_position}") # Для отладки

	# Движение
	velocity.x = speed * current_direction
	move_and_slide()

	# Логика разворота
	var should_turn = false
	if is_on_wall(): # Столкновение со стеной или другим врагом (если настроены слои/маски)
		print("[{name}] Столкнулся со стеной/препятствием (is_on_wall). Разворот.")
		should_turn = true
	
	if not should_turn and about_to_fall_off_ledge: # Обнаружен обрыв
		print("[{name}] Обнаружен обрыв (LedgeRaycast). Разворот.")
		should_turn = true
	
	if not should_turn: # Проверка границ патрулирования, если другие причины для разворота не найдены
		if current_direction == 1 and global_position.x >= initial_position_x + patrol_radius:
			print("[{name}] Достиг правой границы патрулирования. Разворот.")
			should_turn = true
		elif current_direction == -1 and global_position.x <= initial_position_x - patrol_radius:
			print("[{name}] Достиг левой границы патрулирования. Разворот.")
			should_turn = true
	
	if should_turn:
		current_direction *= -1
		_update_sprite_facing_direction()
		# Немедленно применяем новую скорость, чтобы избежать "залипания" или лишнего кадра движения
		velocity.x = speed * current_direction 

	# Анимация ходьбы
	if animated_sprite and animated_sprite.sprite_frames:
		if animated_sprite.sprite_frames.has_animation("walk"):
			animated_sprite.play("walk")
		# else:
			# print(f"[{name}] Анимация 'walk' не найдена.")


func _update_sprite_facing_direction():
	if animated_sprite:
		animated_sprite.flip_h = current_direction > 0


func _on_hitbox_body_entered(body: Node2D):
	if is_dying or not body.is_in_group("player"):
		return

	var player = body as CharacterBody2D
	if player and player.velocity.y > 1.0: # Игрок движется вниз (прыгает на врага)
		print("[{name}] Игрок {player.name} прыгнул на врага. Скорость Y: {player.velocity.y}")
		
		is_dying = true
		speed = 0 
		velocity = Vector2.ZERO 
		
		# Отключаем физику и дальнейшие взаимодействия
		if physics_shape: physics_shape.set_deferred("disabled", true)
		if hitbox: hitbox.set_deferred("monitorable", false) 
		if damage_area: damage_area.set_deferred("monitorable", false)
		
		# Анимация "сплющивания" или смерти
		# Убедитесь, что эта анимация НЕ зациклена в редакторе анимаций
		if animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("squashed"):
			animated_sprite.play("squashed")
			print("[{name}] Проигрывается анимация 'squashed'.")
		else:
			if animated_sprite: animated_sprite.stop() # Если нет спец. анимации, просто остановить
			print("[{name}] Анимация 'squashed' не найдена.")
		
		GameManager.add_score(100) # Начисление очков за убийство
		print("[{name}] Игроку начислено 100 очков.")
		
		# Отскок игрока
		if player.has_method("get_jump_velocity"):
			player.velocity.y = player.get_jump_velocity() * 0.9 
		
		death_timer.start() # Запускаем таймер для затухания и последующего queue_free()
		print("[{name}] Таймер смерти запущен.")
	# else:
		# if player: print(f"[{name}] Игрок коснулся hitbox, но не прыгнул сверху. Скорость Y: {player.velocity.y}")


func _on_damage_area_body_entered(body: Node2D):
	if is_dying or not body.is_in_group("player"): # Умирающий враг не наносит урон
		return

	var player_node = body as Node # Используем Node для проверки has_method
	if player_node and player_node.has_method("take_damage"):
		print("[{name}] Наношу урон игроку {body.name}")
		player_node.take_damage(global_position) # Передаем позицию врага для расчета отбрасывания


func _on_death_timer_timeout():
	print("[{name}] Таймер смерти сработал. Уничтожаю врага.")
	queue_free() # Окончательно удаляем врага со сцены
