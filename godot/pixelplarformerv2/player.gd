extends CharacterBody2D

# Переменные для настройки движения
@export var speed = 150.0  # Скорость движения в пикселях/секунду
@export var jump_velocity = -350.0  # Сила прыжка (отрицательное значение, т.к. Y идет вниз)

# Получаем значение гравитации из настроек проекта
# Это удобно, так как гравитация будет одинаковой для всех физических объектов
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _physics_process(delta):
    # Применяем гравитацию, если игрок не на земле
    if not is_on_floor():
        velocity.y += gravity * delta

    # Обработка прыжка
    # "ui_accept" обычно привязана к Space или Enter, можно изменить в "Настройки проекта" -> "Карта ввода"
    # Для прыжка лучше использовать "ui_up" (стрелка вверх) или создать свое действие.
    if Input.is_action_just_pressed("ui_up") and is_on_floor():
        velocity.y = jump_velocity

    # Получаем направление ввода (влево/вправо)
    # "ui_left" и "ui_right" привязаны к стрелкам влево и вправо
    var direction = Input.get_axis("ui_left", "ui_right")

    # Движение влево/вправо
    if direction:
        velocity.x = direction * speed
    else:
        # Плавная остановка, если нет ввода
        velocity.x = move_toward(velocity.x, 0, speed)

    # Встроенная функция для движения и обработки столкновений
    move_and_slide()

    # Простое отражение спрайта в зависимости от направления движения
    if direction < 0: # Идет влево
        $Sprite2D.flip_h = true
    elif direction > 0: # Идет вправо
        $Sprite2D.flip_h = false
