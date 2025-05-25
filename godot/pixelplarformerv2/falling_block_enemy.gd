# falling_block_enemy.gd
extends CharacterBody2D

# ДОБАВЛЕНО состояние LANDED
enum State { IDLE, WARNING, FALLING, LANDED, RETURNING, SQUASHED }
var current_state: State = State.IDLE

@export var fall_speed: float = 400.0
@export var return_speed: float = 100.0
@export var warning_duration: float = 0.4
@export var points_for_kill: int = 100
@export var death_duration_after_stomp: float = 0.5

var original_position: Vector2
var gravity_force: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var player_is_underneath: bool = false

@onready var animated_sprite: AnimatedSprite2D = $BlockSprite
@onready var player_detector_area: Area2D = $PlayerDetector
@onready var damage_area: Area2D = $DamageArea
@onready var stomp_hitbox_area: Area2D = $StompHitbox
@onready var physics_collision_shape: CollisionShape2D = $PhysicsShape

var warning_timer: Timer = Timer.new()
var death_timer: Timer = Timer.new()

func _ready():
	original_position = global_position
	
	if not animated_sprite: printerr(name + ": Узел 'BlockSprite' не найден!")
	if not player_detector_area: printerr(name + ": Узел 'PlayerDetector' не найден!")
	# ... (остальные проверки узлов) ...

	player_detector_area.body_entered.connect(_on_PlayerDetector_body_entered)
	player_detector_area.body_exited.connect(_on_PlayerDetector_body_exited)
	damage_area.body_entered.connect(_on_DamageArea_body_entered)
	stomp_hitbox_area.body_entered.connect(_on_StompHitbox_body_entered)

	warning_timer.wait_time = warning_duration
	warning_timer.one_shot = true
	warning_timer.timeout.connect(_on_warning_timer_timeout)
	add_child(warning_timer)

	death_timer.wait_time = death_duration_after_stomp
	death_timer.one_shot = true
	death_timer.timeout.connect(_on_death_timer_timeout)
	add_child(death_timer)

	change_state(State.IDLE)


func change_state(new_state: State):
	if current_state == new_state and current_state != State.IDLE :
		return
	
	# print(name + " состояние: " + State.keys()[current_state] + " -> " + State.keys()[new_state])
	current_state = new_state

	match current_state:
		State.IDLE:
			if animated_sprite and animated_sprite.sprite_frames.has_animation("idle"):
				animated_sprite.play("idle")
			velocity = Vector2.ZERO
			# ИСПРАВЛЕНО: Используем is_equal_approx() для сравнения векторов
			# Эта проверка гарантирует, что блок точно на своей исходной позиции.
			if not global_position.is_equal_approx(original_position):
				print("[{name}] Корректировка позиции в IDLE. Было: {global_position}, Стало: {original_position}")
				global_position = original_position
			if damage_area: damage_area.monitoring = false
		State.WARNING:
			if animated_sprite and animated_sprite.sprite_frames.has_animation("warning"):
				animated_sprite.play("warning")
			elif animated_sprite and animated_sprite.sprite_frames.has_animation("idle"): # Запасной вариант
				animated_sprite.play("idle") # Или анимация "дрожания"
			warning_timer.start()
			if damage_area: damage_area.monitoring = false
		State.FALLING:
			if animated_sprite and animated_sprite.sprite_frames.has_animation("falling"):
				animated_sprite.play("falling")
			# velocity.y = 0 # Начать падение с текущей скоростью (гравитация сделает свое дело)
			if damage_area: damage_area.monitoring = true # Активен при падении
		State.LANDED: # НОВОЕ ПОВЕДЕНИЕ ДЛЯ СОСТОЯНИЯ
			print(name + " приземлился (состояние LANDED).")
			velocity = Vector2.ZERO # Останавливаемся после удара
			# Анимация может быть "idle" или специальная "landed_idle"
			if animated_sprite and animated_sprite.sprite_frames.has_animation("idle"): 
				animated_sprite.play("idle")
			elif animated_sprite and animated_sprite.sprite_frames.has_animation("falling"): # Или последний кадр падения
				animated_sprite.stop() # Остановить анимацию падения
			if damage_area: damage_area.monitoring = true # Продолжает наносить урон, пока лежит!
		State.RETURNING:
			if animated_sprite and animated_sprite.sprite_frames.has_animation("returning"):
				animated_sprite.play("returning")
			elif animated_sprite and animated_sprite.sprite_frames.has_animation("falling"):
				animated_sprite.play("falling") # Может использовать ту же анимацию, что и при падении
			if damage_area: damage_area.monitoring = false # Неактивен при подъеме
		State.SQUASHED:
			# ... (код без изменений, как в предыдущей версии) ...
			velocity = Vector2.ZERO 
			if physics_collision_shape: physics_collision_shape.set_deferred("disabled", true)
			if player_detector_area: player_detector_area.set_deferred("monitorable", false)
			if damage_area: damage_area.set_deferred("monitorable", false) # Умирающий не должен наносить урон
			if stomp_hitbox_area: stomp_hitbox_area.set_deferred("monitorable", false)
			if animated_sprite and animated_sprite.sprite_frames.has_animation("squashed"):
				animated_sprite.play("squashed")
			elif animated_sprite: animated_sprite.stop()
			death_timer.start()


func _physics_process(delta: float):
	match current_state:
		State.IDLE:
			if player_is_underneath:
				change_state(State.WARNING)
		State.WARNING:
			# Ждем срабатывания warning_timer
			pass 
		State.FALLING:
			velocity.y += gravity_force * delta
			velocity.y = min(velocity.y, fall_speed) 
			move_and_slide()

			if is_on_floor(): # УДАР! (о землю или игрока)
				change_state(State.LANDED)
			# Убрали условие возврата, если игрок ушел ВО ВРЕМЯ падения
		State.LANDED:
			velocity = Vector2.ZERO # Удерживаем позицию на земле
			move_and_slide() # Позволяет ему оставаться твердым и реагировать на толчки
			
			if not player_is_underneath: # Игрок ушел из-под приземлившегося блока
				change_state(State.RETURNING)
		State.RETURNING:
			velocity.y = -return_speed 
			velocity.x = 0 
			move_and_slide()

			# ИСПРАВЛЕНО: Используем is_equal_approx() для более точной проверки возврата
			# Это проверит и X, и Y координаты.
			if global_position.is_equal_approx(original_position):
				global_position = original_position # Точно на место
				velocity = Vector2.ZERO
				change_state(State.IDLE)
			# Дополнительная проверка на случай, если блок "проскочил" исходную позицию вверх:
			elif global_position.y < original_position.y and not global_position.is_equal_approx(original_position):
				print("[{name}] Блок проскочил вверх в RETURNING. Возвращаю на место.")
				global_position = original_position 
				velocity = Vector2.ZERO
				change_state(State.IDLE)
			elif player_is_underneath: # Если игрок вернулся под блок во время подъема
				change_state(State.WARNING) 
		State.SQUASHED:
			if animated_sprite: # Анимация затухания
				if death_timer.is_stopped() or death_timer.wait_time == 0:
					animated_sprite.modulate.a = 0.0
				else:
					animated_sprite.modulate.a = death_timer.time_left / death_timer.wait_time
	# print(name + " State: " + State.keys()[current_state] + " PlayerUnder: " + str(player_is_underneath) + " VelY: " + str(velocity.y) + " PosY: " + str(global_position.y))


# --- Обработчики сигналов ---
func _on_PlayerDetector_body_entered(body: Node2D):
	if body.is_in_group("player"):
		player_is_underneath = true
		if current_state == State.IDLE:
			change_state(State.WARNING)
		# Если блок уже LANDED и игрок снова под него зашел, 
		# он НЕ должен сразу падать. Он останется LANDED.
		# Логика _physics_process для LANDED будет удерживать его, пока player_is_underneath = true.

func _on_PlayerDetector_body_exited(body: Node2D):
	if body.is_in_group("player"):
		player_is_underneath = false
		# Если блок был в состоянии LANDED и игрок ушел, 
		# _physics_process для LANDED обнаружит это и переключит на RETURNING.

func _on_warning_timer_timeout(): # ... (без изменений) ...
	if current_state == State.WARNING:
		change_state(State.FALLING)

func _on_DamageArea_body_entered(body: Node2D):
	# Урон наносится только при активном падении (FALLING) 
	# ИЛИ когда блок лежит на земле и давит (LANDED)
	if current_state == State.FALLING or current_state == State.LANDED:
		if body.is_in_group("player") and body.has_method("take_damage"):
			print(name + " наносит урон игроку.")
			body.take_damage(global_position)
	# Остальные состояния не наносят урон (IDLE, WARNING, RETURNING, SQUASHED)

func _on_StompHitbox_body_entered(body: Node2D): # ... (без изменений, как в предыдущей версии) ...
	if current_state == State.SQUASHED: return
	if body.is_in_group("player"):
		var player = body as CharacterBody2D
		if player and player.velocity.y > 0 and player.global_position.y < stomp_hitbox_area.global_position.y:
			print(name + ": Уничтожен прыжком игрока.")
			GameManager.add_score(points_for_kill)
			if player.has_method("get_jump_velocity"):
				player.velocity.y = player.get_jump_velocity() * 0.7 
			change_state(State.SQUASHED)

func _on_death_timer_timeout(): # ... (без изменений) ...
	print(name + ": Таймер смерти сработал. Удаляюсь со сцены.")
	queue_free()
