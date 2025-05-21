extends CharacterBody2D

# Переменные для настройки движения
@export var speed = 150.0  # Скорость движения в пикселях/секунду
@export var jump_velocity = -350.0  # Сила прыжка (отрицательное значение, т.к. Y идет вниз)

# Получаем значение гравитации из настроек проекта
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# Ссылка на узел AnimatedSprite2D
# Убедитесь, что имя узла в сцене совпадает (например, "AnimatedSprite2D" или "AnimatedSprite")
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D 

# Пример локального здоровья, если вы не используете GameManager для этого
var health = 3 

func _physics_process(delta):
    # Применяем гравитацию, если игрок не на земле
    if not is_on_floor():
        velocity.y += gravity * delta

    # Обработка прыжка
    if Input.is_action_just_pressed("ui_up") and is_on_floor():
        velocity.y = jump_velocity

    # Получаем направление ввода (влево/вправо)
    var direction = Input.get_axis("ui_left", "ui_right")
    
    # Движение и анимация
    if direction: # Если есть горизонтальный ввод (игрок двигается)
        velocity.x = direction * speed
        animated_sprite.play("run") # Воспроизводим анимацию "run"
        
        # Отражение спрайта в зависимости от направления движения
        if direction < 0: # Идет влево
            animated_sprite.flip_h = false
        elif direction > 0: # Идет вправо
            animated_sprite.flip_h = true
    else: # Если нет горизонтального ввода (игрок не двигается по горизонтали)
        velocity.x = move_toward(velocity.x, 0, speed) # Плавная остановка
        
        # Останавливаем анимацию и показываем первый кадр (индекс 0) анимации "run".
        # Это будет использоваться как состояние покоя или для прыжка на месте.
        animated_sprite.stop()
        animated_sprite.set_frame(0) # Устанавливаем анимацию на первый кадр

    # Встроенная функция для движения и обработки столкновений
    move_and_slide()

# Функция для получения урона (из предыдущей части)
func take_damage():
    # health -= 1 # Локальное здоровье теперь можно убрать, если используется GameManager
    GameManager.lose_life() # Уменьшаем жизни через GameManager
    # ... остальная логика получения урона ...
    if GameManager.lives <= 0:
        get_tree().reload_current_scene()
