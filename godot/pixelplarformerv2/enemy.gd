extends CharacterBody2D

@export var speed = 50.0
@export var patrol_distance = 100.0 # Расстояние патрулирования в одну сторону

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D # Убедитесь, что имя узла верное
@onready var hitbox: Area2D = $Hitbox
@onready var damage_area: Area2D = $DamageArea

var initial_position: Vector2
var direction = 1 # 1 вправо, -1 влево
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
    initial_position = global_position
    # Подключаем сигналы от Area2D
    hitbox.body_entered.connect(_on_hitbox_body_entered)
    damage_area.body_entered.connect(_on_damage_area_body_entered)

func _physics_process(delta):
    if not is_on_floor():
        velocity.y += gravity * delta

    velocity.x = speed * direction

    # Логика патрулирования
    if global_position.x > initial_position.x + patrol_distance:
        direction = -1
        animated_sprite.flip_h = true
    elif global_position.x < initial_position.x - patrol_distance:
        direction = 1
        animated_sprite.flip_h = false

    # Простая анимация (если есть)
    if animated_sprite:
        animated_sprite.play("walk") # Предполагаем, что есть анимация "walk"

    move_and_slide()

# Игрок прыгнул на врага
func _on_hitbox_body_entered(body):
    if body.name == "Player": # Убедитесь, что узел игрока называется "Player"
        # Опционально: дать игроку небольшой отскок
        body.velocity.y = body.jump_velocity * 0.6 # Немного слабее обычного прыжка
        body.move_and_slide() # Применить отскок немедленно

        print("Враг уничтожен!")
        queue_free() # Уничтожить врага

# Враг коснулся игрока
func _on_damage_area_body_entered(body):
    if body.name == "Player":
        if body.has_method("take_damage"): # Проверяем, есть ли у игрока метод take_damage
            body.take_damage()
        print("Игрок получил урон!")
        # Здесь можно реализовать перезапуск уровня или уменьшение жизней игрока
