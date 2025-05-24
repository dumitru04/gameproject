# star_item.gd
extends Area2D

var initial_impulse_y = -130.0 # Начальный импульс вверх
var gravity_pull = 300.0      # Гравитация для звезды
var horizontal_drift_speed = 40.0 # Скорость горизонтального "дрейфа"

var current_velocity = Vector2.ZERO
var can_be_collected = false
var can_move = false

var points_on_collect = 200 # Очки за подбор самой звезды (можно 0)

func _ready():
	set_deferred("monitoring", false) # Нельзя подобрать сразу
	var timer = get_tree().create_timer(0.15) # Короткая задержка
	timer.timeout.connect(func():
		set_deferred("monitoring", true)
		can_be_collected = true
		can_move = true
		current_velocity.y = initial_impulse_y
		# Небольшой случайный дрейф влево или вправо
		current_velocity.x = randf_range(-horizontal_drift_speed, horizontal_drift_speed)
	)
	body_entered.connect(_on_body_entered)
	
	if $AnimatedSprite2D.sprite_frames.has_animation("spin"):
		$AnimatedSprite2D.play("spin")

func _physics_process(delta: float):
	if can_move:
		current_velocity.y += gravity_pull * delta
		position += current_velocity * delta
		# Опционально: исчезновение через время, если не подобрали

func _on_body_entered(body: Node2D):
	if can_be_collected and body.is_in_group("player"):
		print("Звезда подобрана игроком!")
		if points_on_collect > 0:
			GameManager.add_score(points_on_collect)
		# Проиграть звук подбора звезды
		queue_free()
