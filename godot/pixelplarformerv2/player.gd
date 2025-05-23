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

# --- Ссылки на узлы (@onready) ---
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var head_hit_raycast: RayCast2D = $HeadHitRaycast 
@onready var camera_node: Camera2D = $Camera2D 

# --- Внутренние переменные ---
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var camera_bottom_limit_was_set = false # Флаг, что нижний предел камеры был установлен

# Значение по умолчанию для camera.limit_bottom (очень большое число)
const CAMERA_DEFAULT_LIMIT_BOTTOM = 67108864 

func _ready():
    if camera_node:
        camera_node.limit_left = 0 # Абсолютный мировой предел X=0 для камеры
        # Сбрасываем нижний предел камеры при старте/рестарте уровня
        camera_node.limit_bottom = CAMERA_DEFAULT_LIMIT_BOTTOM
        print("Player _ready: Camera limit_left={camera_node.limit_left}, limit_bottom={camera_node.limit_bottom}")
    else:
        print("Player _ready: ВНИМАНИЕ! Узел Camera2D не найден как дочерний.")
    camera_bottom_limit_was_set = false


func _physics_process(delta):
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


func handle_death():
    if not is_physics_processing(): 
        return
    print("Игрок упал в пропасть! Game Over.")
    set_physics_process(false) 
    if animated_sprite: animated_sprite.stop()     
    GameManager.fall_life()


func take_damage():
    if not is_physics_processing(): return
    GameManager.lose_life()
    print("Игрок получил урон! Жизней: ", GameManager.lives)


func get_jump_velocity() -> float:
    return jump_velocity_value
