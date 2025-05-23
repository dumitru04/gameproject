# life_up_item.gd
extends Area2D

# Небольшое движение вверх после появления
var initial_impulse_y = -100 # Сила начального "подпрыгивания"
var gravity_pull = 250    # Сила гравитации для предмета
var current_velocity = Vector2.ZERO
var can_be_collected = false # Флаг, чтобы предмет не подбирался мгновенно
var can_move = false         # Флаг для начала движения

func _ready():
    # Предмет не должен подбираться сразу, если игрок все еще под блоком
    # body_entered не будет срабатывать, пока monitoring = false
    set_deferred("monitoring", false) 
    
    # Задержка перед тем, как предмет можно будет подобрать и он начнет двигаться
    var timer = get_tree().create_timer(0.25) # Короткая задержка
    timer.timeout.connect(func(): 
        set_deferred("monitoring", true) # Включаем возможность подбора
        can_be_collected = true
        can_move = true
        current_velocity.y = initial_impulse_y # Применяем начальный импульс
    )
    body_entered.connect(_on_body_entered)


func _physics_process(delta):
    if can_move:
        current_velocity.y += gravity_pull * delta
        position += current_velocity * delta
        # Опционально: можно добавить исчезновение предмета через некоторое время, если его не подобрали.
        # Например, используя еще один Timer.

func _on_body_entered(body):
    # Проверяем, что предмет можно подобрать и что это игрок
    if can_be_collected and body.is_in_group("player"): # Игрок должен быть в группе "player"
        GameManager.add_life()
        # Здесь можно проиграть звук подбора жизни
        queue_free() # Уничтожаем предмет
