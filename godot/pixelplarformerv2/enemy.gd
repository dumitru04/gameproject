# enemy.gd
extends CharacterBody2D

@export var speed = 40.0  # Скорость движения врага
@export var patrol_radius = 80.0 # Расстояние в пикселях от начальной точки X, которое враг будет патрулировать в каждую сторону

# Ссылка на узел для анимации. Убедитесь, что имя узла в сцене врага совпадает.
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D 

# Раскомментируйте и настройте, если вы используете эти области для урона игроку или получения урона врагом
@onready var hitbox: Area2D = $Hitbox 
@onready var damage_area: Area2D = $DamageArea

var initial_position_x: float  # Начальная X координата врага для патрулирования
var current_direction = 1     # 1 для движения вправо, -1 для движения влево
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity") # Получаем гравитацию из настроек проекта

func _ready():
    initial_position_x = global_position.x # Запоминаем начальную позицию по X

    # Подключение сигналов от hitbox и damage_area, если они используются
    if hitbox:
        hitbox.body_entered.connect(_on_hitbox_body_entered)
    if damage_area:
        damage_area.body_entered.connect(_on_damage_area_body_entered)
    
    _update_sprite_facing_direction() # Устанавливаем начальное направление спрайта

func _physics_process(delta):
    # Применение гравитации
    if not is_on_floor():
        velocity.y += gravity * delta
    else:
        # Предотвращает "подпрыгивание" на ровной поверхности при смене направления
        velocity.y = 0 

    # Устанавливаем горизонтальную скорость
    velocity.x = speed * current_direction
    
    # Двигаем врага
    move_and_slide()

    var should_turn = false # Флаг, указывающий, нужно ли развернуться

    # 1. Проверка столкновения со стеной
    if is_on_wall():
        should_turn = true
    
    # 2. Проверка границ патрулирования (только если не уперлись в стену в этом же кадре)
    # Это предотвращает "залипание", если граница патрулирования совпадает со стеной.
    if not should_turn:
        if current_direction == 1 and global_position.x >= initial_position_x + patrol_radius:
            should_turn = true
        elif current_direction == -1 and global_position.x <= initial_position_x - patrol_radius:
            should_turn = true
    
    # Если нужно развернуться (из-за стены или достижения границы патрулирования)
    if should_turn:
        current_direction *= -1 # Меняем направление (1 -> -1, -1 -> 1)
        _update_sprite_facing_direction() # Обновляем отражение спрайта
        # Немедленно применяем новую скорость, чтобы враг не "проскальзывал" на границе или у стены
        velocity.x = speed * current_direction 

    # Воспроизведение анимации ходьбы (убедитесь, что у вас есть анимация "walk" в AnimatedSprite2D)
    if animated_sprite:
        animated_sprite.play("walk") 

# Вспомогательная функция для обновления отражения спрайта
func _update_sprite_facing_direction():
    if animated_sprite:
        if current_direction < 0: # Если движется влево
            animated_sprite.flip_h = true
        else: # Если движется вправо
            animated_sprite.flip_h = false

func _on_hitbox_body_entered(body):
    if body.name == "Player":
        if body.has_method("get_jump_velocity"): # Предполагаем, что у игрока есть метод для силы отскока
            body.velocity.y = body.get_jump_velocity() * 0.6 
            body.move_and_slide()
        
        queue_free()

func _on_damage_area_body_entered(body):
    if body.name == "Player":
        if body.has_method("take_damage"):
            body.take_damage()
