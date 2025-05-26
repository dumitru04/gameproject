class_name Player
extends CharacterBody2D

@export var speed = 150.0
@export var jump_velocity_value = -350.0
@export var min_x_player_position = 0.0 
@export var camera_lock_y_threshold = 500.0 
@export var death_y_threshold = 1000.0 

var is_completing_level: bool = false
var level_complete_run_speed: float = 120.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var head_hit_raycast: RayCast2D = $HeadHitRaycast 
@onready var camera_node: Camera2D = $Camera2D 

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var camera_bottom_limit_was_set = false

const CAMERA_DEFAULT_LIMIT_BOTTOM = 67108864 

@export var pause_menu_node_path: NodePath
var pause_menu_node: CanvasLayer

@export var invincibility_duration: float = 1.0
@export var knockback_horizontal_power: float = 250.0
@export var knockback_vertical_power: float = -150.0

var is_invincible: bool = false
var invincibility_timer: Timer

func _ready():
    if camera_node:
        camera_node.limit_left = 0
        camera_node.limit_bottom = CAMERA_DEFAULT_LIMIT_BOTTOM

    if not pause_menu_node_path.is_empty():
        pause_menu_node = get_node_or_null(pause_menu_node_path)
    
    if not pause_menu_node:
        print("[Player] _ready: !!! ERROR: Pause menu node not found! Check pause_menu_node_path in inspector or absolute path.")
    
    invincibility_timer = Timer.new()
    invincibility_timer.one_shot = true
    invincibility_timer.timeout.connect(_on_invincibility_timer_timeout)
    add_child(invincibility_timer) 

func take_damage(damage_source_position: Vector2 = global_position):
    if is_invincible or not is_physics_processing():
        return
    GameManager.GM_sfx_player_damage()

    print("[Player] Took damage.")
    GameManager.lose_life() 
    
    is_invincible = true
    invincibility_timer.start(invincibility_duration)
    print("[Player] Invincibility activated for {invincibility_duration} sec.")

    var blink_tween = create_tween().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
    var num_blinks = int(invincibility_duration / 0.2) 
    blink_tween.set_loops(num_blinks) 
    
    blink_tween.tween_property(animated_sprite, "modulate:a", 0.3, 0.1)
    blink_tween.tween_property(animated_sprite, "modulate:a", 1.0, 0.1)
    blink_tween.finished.connect(func(): 
        if is_instance_valid(animated_sprite) and is_invincible:
            animated_sprite.modulate.a = 1.0
    )
    print("[Player] Blinking effect started.")

    var knock_direction_x = sign(global_position.x - damage_source_position.x)
    
    if knock_direction_x == 0:
        knock_direction_x = -1.0 if not animated_sprite.flip_h else 1.0

    velocity.x = knock_direction_x * knockback_horizontal_power
    velocity.y = knockback_vertical_power
    print("[Player] Player knocked back. New velocity: {velocity}")

func _on_invincibility_timer_timeout():
    is_invincible = false
    if is_instance_valid(animated_sprite):
        animated_sprite.modulate.a = 1.0
    print("[Player] Invincibility ended.")	
    
func _unhandled_input(event: InputEvent):
    if event.is_action_pressed("ui_pause"):
        if not get_tree().paused:
            print("[Player] _unhandled_input: 'ui_pause' pressed. Game NOT paused. Calling pause menu.")
            if pause_menu_node and pause_menu_node.has_method("open_menu_and_pause"):
                pause_menu_node.open_menu_and_pause() 
                get_viewport().set_input_as_handled()
            elif pause_menu_node:
                print("[Player] _unhandled_input: !!! ERROR: Pause menu node found but doesn't have open_menu_and_pause() method.")
            else:
                print("[Player] _unhandled_input: !!! ERROR: Cannot open pause menu, node not found.")

func _physics_process(delta):
    if is_completing_level:
        _handle_level_complete_run(delta)
        return

    if not is_on_floor():
        velocity.y += gravity * delta

    if Input.is_action_just_pressed("ui_up") and is_on_floor():
        velocity.y = jump_velocity_value
        GameManager.GM_sfx_player_jump()

    var direction = Input.get_axis("ui_left", "ui_right")
    if direction:
        velocity.x = direction * speed
        if animated_sprite.sprite_frames.has_animation("run"):
            animated_sprite.play("run")
        animated_sprite.flip_h = direction > 0
    else:
        velocity.x = move_toward(velocity.x, 0, speed)
        if is_on_floor(): 
            if animated_sprite.sprite_frames.has_animation("idle"):
                animated_sprite.play("idle")
            elif animated_sprite.sprite_frames.has_animation("run"):
                animated_sprite.stop()
                animated_sprite.set_frame(0)

    move_and_slide()

    if global_position.x < min_x_player_position:
        global_position.x = min_x_player_position
        velocity.x = 0 

    if camera_node:
        if global_position.y > camera_lock_y_threshold:
            if not camera_bottom_limit_was_set:
                var viewport_half_height_world = (camera_node.get_viewport_rect().size.y / camera_node.zoom.y) / 2.0
                var target_camera_center_y_when_locked = camera_lock_y_threshold - viewport_half_height_world
                
                camera_node.limit_bottom = int(target_camera_center_y_when_locked)
                camera_bottom_limit_was_set = true
                print("Player below camera_lock_y_threshold. Camera Y locked. Limit Bottom: {camera_node.limit_bottom}")
        else:
            if camera_bottom_limit_was_set:
                camera_node.limit_bottom = CAMERA_DEFAULT_LIMIT_BOTTOM 
                camera_bottom_limit_was_set = false
                print("Player above camera_lock_y_threshold. Camera Y unlocked.")

    if velocity.y < -5 and head_hit_raycast.is_colliding():
        var collider = head_hit_raycast.get_collider()
        if collider and collider.has_method("hit_block_from_below"):
            velocity.y = 30 
            collider.hit_block_from_below(self)

    if global_position.y > death_y_threshold:
        handle_death()

func _handle_level_complete_run(delta: float):
    velocity.x = level_complete_run_speed
    
    if not is_on_floor():
        velocity.y += gravity * delta
    else:
        velocity.y = 0
    
    if animated_sprite.sprite_frames.has_animation("run"):
        animated_sprite.play("run")
    animated_sprite.flip_h = true

    move_and_slide()

func start_level_complete_sequence():
    if is_completing_level:
        return
        
    print("[Player] Starting level completion sequence.")
    is_completing_level = true

func handle_death():
    if not is_physics_processing(): 
        return
    
    set_physics_process(false) 
    if animated_sprite: animated_sprite.stop()     
    
    GameManager.trigger_instant_game_over("Fell into abyss")

func get_jump_velocity() -> float:
    return jump_velocity_value
