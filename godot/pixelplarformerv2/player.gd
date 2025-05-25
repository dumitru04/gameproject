# player.gd
class_name Player
extends CharacterBody2D

# --- Экспортируемые переменные ---
@export var speed = 150.0
@export var jump_velocity_value = -350.0
@export var min_x_player_position = 0.0 

# Y-координата, ниже которой камера перестает следовать за игроком вниз.
# Должна быть выше death_y_threshold. Например, это Y-координата "пола" уровня.
@export var camera_lock_y_threshold = 500.0 

# Y-координата, ниже которой игрок проигрывает.
@export var death_y_threshold = 1000.0 

# Новые переменные для завершения уровня
var is_completing_level: bool = false
var level_complete_run_speed: float = 120.0

# --- Ссылки на узлы (@onready) ---
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var head_hit_raycast: RayCast2D = $HeadHitRaycast 
@onready var camera_node: Camera2D = $Camera2D 

# --- Внутренние переменные ---
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var camera_bottom_limit_was_set = false # Флаг, что нижний предел камеры был установлен

# Значение по умолчанию для camera.limit_bottom (очень большое число)
const CAMERA_DEFAULT_LIMIT_BOTTOM = 67108864 

@export var pause_menu_node_path: NodePath
var pause_menu_node: CanvasLayer # Будет инициализировано в _ready

@export var invincibility_duration: float = 1.0 # Длительность неуязвимости и мигания в секундах
@export var knockback_horizontal_power: float = 250.0
@export var knockback_vertical_power: float = -150.0

var is_invincible: bool = false
var invincibility_timer: Timer

func _ready():
	if camera_node: # Предполагается, что camera_node у вас уже есть
		camera_node.limit_left = 0
		camera_node.limit_bottom = CAMERA_DEFAULT_LIMIT_BOTTOM
	# camera_bottom_limit_was_set = false # Эта переменная тоже должна быть объявлена
	pass

	# Инициализация ссылки на меню паузы
	if not pause_menu_node_path.is_empty():
		pause_menu_node = get_node_or_null(pause_menu_node_path)
	
	if not pause_menu_node:
		print("[Player] _ready: !!! ОШИБКА: Узел меню паузы не найден! Проверьте pause_menu_node_path в инспекторе или абсолютный путь.")
	
	invincibility_timer = Timer.new()
	invincibility_timer.one_shot = true # Таймер сработает один раз
	invincibility_timer.timeout.connect(_on_invincibility_timer_timeout) # Подключаем сигнал
	add_child(invincibility_timer) 

func take_damage(damage_source_position: Vector2 = global_position): # damage_source_position - позиция того, кто нанес урон
	if is_invincible or not is_physics_processing(): # Если уже неуязвим или "мертв"
		return

	print("[Player] Получен урон.")
	GameManager.lose_life() 
	
	is_invincible = true
	invincibility_timer.start(invincibility_duration)
	print("[Player] Неуязвимость активирована на {invincibility_duration} сек.")

	# --- Эффект мигания ---
	var blink_tween = create_tween().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	# Количество полных миганий (невидимый -> видимый). 
	# Если invincibility_duration = 1.0, а длительность одного мигания 0.1+0.1 = 0.2, то будет 5 миганий.
	var num_blinks = int(invincibility_duration / 0.2) 
	blink_tween.set_loops(num_blinks) 
	
	blink_tween.tween_property(animated_sprite, "modulate:a", 0.3, 0.1) # Стать полупрозрачным
	blink_tween.tween_property(animated_sprite, "modulate:a", 1.0, 0.1) # Вернуть полную видимость
	# Убедимся, что по окончании мигания спрайт точно видим (если неуязвимость еще не прошла)
	blink_tween.finished.connect(func(): 
		if is_instance_valid(animated_sprite) and is_invincible: # Если все еще неуязвим (на случай если длительность твина и таймера не совпадут идеально)
			animated_sprite.modulate.a = 1.0
	)
	print("[Player] Эффект мигания запущен.")

	# --- Логика отбрасывания ---
	var knock_direction_x = sign(global_position.x - damage_source_position.x)
	
	# Если источник урона находится точно там же по X (маловероятно, но возможно)
	if knock_direction_x == 0:
		knock_direction_x = -1.0 if not animated_sprite.flip_h else 1.0 # Отбросить в сторону, противоположную взгляду

	velocity.x = knock_direction_x * knockback_horizontal_power
	velocity.y = knockback_vertical_power # Подбросить вверх
	print("[Player] Игрок отброшен. Новая velocity: {velocity}")
	
	# move_and_slide() будет вызван в _physics_process и применит эту скорость.
	# Можно добавить временное отключение управления игроком ("стан").

func _on_invincibility_timer_timeout():
	is_invincible = false
	if is_instance_valid(animated_sprite): # Проверка, что узел еще существует
		animated_sprite.modulate.a = 1.0 # Гарантированно вернуть полную видимость
	print("[Player] Неуязвимость закончилась.")	
	
func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("ui_pause"):
		if not get_tree().paused: # Если игра еще не на паузе
			print("[Player] _unhandled_input: Нажата 'ui_pause'. Игра НЕ на паузе. Вызываю меню паузы.")
			if pause_menu_node and pause_menu_node.has_method("open_menu_and_pause"):
				# Сначала ставим игру на паузу, затем открываем меню
				# pause_menu_node.open_menu_and_pause() вызовет get_tree().paused = true
				pause_menu_node.open_menu_and_pause() 
				get_viewport().set_input_as_handled() # ИСПРАВЛЕНО
			elif pause_menu_node:
				print("[Player] _unhandled_input: !!! ОШИБКА: Узел меню паузы найден, но не имеет метода open_menu_and_pause().")
			else:
				print("[Player] _unhandled_input: !!! ОШИБКА: Не могу открыть меню паузы, узел не найден.")
		# else:
			# Если игра уже на паузе, меню паузы само обработает ui_pause для закрытия (в своем _unhandled_input)
			# get_viewport().set_input_as_handled() // Можно и здесь, если меню паузы не поглотило событие первым

func _physics_process(delta):
	if is_completing_level:
		_handle_level_complete_run(delta)
		return # Пропускаем обычную обработку ввода и физики
	# Гравитация
	if not is_on_floor():
		velocity.y += gravity * delta

	# Прыжок
	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = jump_velocity_value

	# Горизонтальное движение
	var direction = Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * speed
		if animated_sprite.sprite_frames.has_animation("run"): # Проверка на существование анимации
			animated_sprite.play("run")
		animated_sprite.flip_h = direction > 0
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		if is_on_floor(): 
			if animated_sprite.sprite_frames.has_animation("idle"): # Проверка на существование анимации
				animated_sprite.play("idle")
			elif animated_sprite.sprite_frames.has_animation("run"): # Если нет idle, используем первый кадр run
				animated_sprite.stop()
				animated_sprite.set_frame(0)


	move_and_slide()

	# Ограничение движения игрока по X
	if global_position.x < min_x_player_position:
		global_position.x = min_x_player_position
		velocity.x = 0 

	# Логика фиксации камеры при падении
	if camera_node:
		if global_position.y > camera_lock_y_threshold:
			if not camera_bottom_limit_was_set:
				# Игрок опустился ниже порога фиксации камеры.
				# Фиксируем камеру так, чтобы camera_lock_y_threshold была у нижнего края экрана.
				var viewport_half_height_world = (camera_node.get_viewport_rect().size.y / camera_node.zoom.y) / 2.0
				var target_camera_center_y_when_locked = camera_lock_y_threshold - viewport_half_height_world
				
				camera_node.limit_bottom = int(target_camera_center_y_when_locked)
				camera_bottom_limit_was_set = true
				print("Player ниже camera_lock_y_threshold. Camera Y зафиксирована. Limit Bottom: {camera_node.limit_bottom}")
		else:
			# Если игрок вернулся выше порога (маловероятно для падения в пропасть, но для общей логики)
			if camera_bottom_limit_was_set:
				camera_node.limit_bottom = CAMERA_DEFAULT_LIMIT_BOTTOM 
				camera_bottom_limit_was_set = false
				print("Player выше camera_lock_y_threshold. Camera Y разблокирована.")

	# Логика удара по блоку головой
	if velocity.y < -5 and head_hit_raycast.is_colliding():
		var collider = head_hit_raycast.get_collider()
		if collider and collider.has_method("hit_block_from_below"):
			velocity.y = 30 
			collider.hit_block_from_below(self)

	# Проверка падения в пропасть для смерти игрока
	if global_position.y > death_y_threshold:
		handle_death()

func _handle_level_complete_run(delta: float):
	velocity.x = level_complete_run_speed # Двигаемся вправо
	
	# Применяем гравитацию, чтобы игрок не летел по воздуху, если есть неровности
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0 # Если на земле, вертикальная скорость 0
	
	if animated_sprite.sprite_frames.has_animation("run"): # Убедимся, что играется анимация бега
		animated_sprite.play("run")
	animated_sprite.flip_h = true # Смотрим вправо

	move_and_slide()
	# Камера, будучи дочерним узлом, должна следовать за игроком
	# Никаких специальных проверок на "убежал за экран" здесь не нужно,
	# уровень сам решит, когда показать меню.

# Новая функция, вызываемая извне (например, из скрипта уровня)
func start_level_complete_sequence():
	if is_completing_level: # Если уже выполняется, ничего не делаем
		return
		
	print("[Player] Запуск последовательности завершения уровня.")
	is_completing_level = true
	# Отключаем коллизии с врагами/опасностями на время убегания (опционально)
	# set_collision_mask_value(НОМЕР_СЛОЯ_ВРАГОВ, false)

func handle_death(): # Вызывается при падении в пропасть
	if not is_physics_processing(): 
		return
	
	# Сообщение о причине теперь будет выводиться из GameManager
	set_physics_process(false) 
	if animated_sprite: animated_sprite.stop()     
	
	# ИЗМЕНЕНИЕ: Вызываем новую функцию для мгновенного Game Over
	GameManager.trigger_instant_game_over("Упал в пропасть")

func get_jump_velocity() -> float:
	return jump_velocity_value
