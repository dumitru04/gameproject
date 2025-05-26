extends CharacterBody2D

@export var speed = 40.0
@export var patrol_radius = 80.0 
@export var death_duration = 0.5 
@export var ledge_check_distance_y: float = 20.0 
@export var ledge_check_offset_x_from_edge: float = 5.0 

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox 
@onready var damage_area: Area2D = $DamageArea
@onready var physics_shape: CollisionShape2D = $PhysicsShape 
@onready var ledge_raycast: RayCast2D = $LedgeRaycast 

var initial_position_x: float
var current_direction = 1 
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var is_dying = false 
var death_timer: Timer 

func _ready():
    print("[" + name + "] _ready: Enemy initialization.")
    initial_position_x = global_position.x
    _update_sprite_facing_direction()

    if hitbox:
        var connect_error_hitbox = hitbox.body_entered.connect(_on_hitbox_body_entered)
        if connect_error_hitbox == OK:
            print("[" + name + "] _ready: Hitbox.body_entered signal successfully connected.")
        else:
            print("[" + name + "] _ready: !!! ERROR connecting Hitbox signal. Code: " + str(connect_error_hitbox))
    else:
        print("[" + name + "] _ready: !!! ERROR: Hitbox node not found!")
        
    if damage_area:
        var connect_error_damage = damage_area.body_entered.connect(_on_damage_area_body_entered)
        if connect_error_damage == OK:
            print("[" + name + "] _ready: DamageArea.body_entered signal successfully connected.")
        else:
            print("[" + name + "] _ready: !!! ERROR connecting DamageArea signal. Code: " + str(connect_error_damage))
    else:
        print("[" + name + "] _ready: !!! ERROR: DamageArea node not found!")

    if not physics_shape: print("[" + name + "] _ready: !!! ERROR: PhysicsShape (main CollisionShape2D) not found!")
    if not ledge_raycast: print("[" + name + "] _ready: !!! ERROR: LedgeRaycast node not found!")

    death_timer = Timer.new()
    death_timer.one_shot = true
    death_timer.wait_time = death_duration
    death_timer.timeout.connect(_on_death_timer_timeout)
    add_child(death_timer)
    print("[" + name + "] _ready: Death timer created and added. Duration: " + str(death_duration))

func _physics_process(delta: float):
    if is_dying:
        if death_timer.is_stopped() or death_timer.wait_time == 0:
            animated_sprite.modulate.a = 0.0
        else:
            animated_sprite.modulate.a = death_timer.time_left / death_timer.wait_time
        return

    if not is_on_floor():
        velocity.y += gravity * delta
    else:
        velocity.y = 0

    var about_to_fall_off_ledge = false
    if ledge_raycast and physics_shape and is_on_floor():
        var enemy_scaled_half_width = (physics_shape.shape.get_rect().size.x / 2.0) * global_scale.x
        var ray_target_x_component = (enemy_scaled_half_width + ledge_check_offset_x_from_edge) * current_direction
        ledge_raycast.target_position = Vector2(ray_target_x_component, ledge_check_distance_y)
        ledge_raycast.force_raycast_update()
        if not ledge_raycast.is_colliding():
            about_to_fall_off_ledge = true

    velocity.x = speed * current_direction
    
    move_and_slide() 

    var should_turn_this_frame = false
    var wall_normal_for_nudge = Vector2.ZERO

    if is_on_wall():
        print("[{name}] is_on_wall() == true. Planning to turn around.")
        should_turn_this_frame = true
        if get_slide_collision_count() > 0:
            var collision = get_slide_collision(0)
            if collision:
                wall_normal_for_nudge = collision.get_normal()
                print("[{name}] Wall collision normal: {wall_normal_for_nudge}")
            else:
                print("[{name}] is_on_wall()=true, but get_slide_collision(0) returned null.")
        else:
            print("[{name}] is_on_wall()=true, but get_slide_collision_count() == 0.")
    
    if not should_turn_this_frame and about_to_fall_off_ledge:
        print("[{name}] Detected ledge (LedgeRaycast). Turning around.")
        should_turn_this_frame = true
    
    if not should_turn_this_frame:
        if (current_direction == 1 and global_position.x >= initial_position_x + patrol_radius) or \
           (current_direction == -1 and global_position.x <= initial_position_x - patrol_radius):
            print("[{name}] Reached patrol boundary. Turning around.")
            should_turn_this_frame = true
    
    if should_turn_this_frame:
        current_direction *= -1
        _update_sprite_facing_direction()
        
        velocity.x = speed * current_direction 
        
        if wall_normal_for_nudge != Vector2.ZERO:
            var nudge_strength = 2.0
            global_position += wall_normal_for_nudge * nudge_strength
            print("[{name}] Nudged away from obstacle by vector: {wall_normal_for_nudge * nudge_strength}")
    
    if animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("walk"):
        animated_sprite.play("walk")

func _update_sprite_facing_direction():
    if animated_sprite:
        animated_sprite.flip_h = current_direction > 0

func _on_hitbox_body_entered(body: Node2D):
    if is_dying or not body.is_in_group("player"):
        return

    var player = body as CharacterBody2D
    if player and player.velocity.y > 1.0:
        print("[{name}] Player {player.name} jumped on enemy. Y velocity: {player.velocity.y}")
        
        is_dying = true
        speed = 0 
        velocity = Vector2.ZERO 
        
        if physics_shape: physics_shape.set_deferred("disabled", true)
        if hitbox: hitbox.set_deferred("monitorable", false) 
        if damage_area: damage_area.set_deferred("monitorable", false)
        
        if animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("squashed"):
            animated_sprite.play("squashed")
            print("[{name}] Playing 'squashed' animation.")
        else:
            if animated_sprite: animated_sprite.stop()
            print("[{name}] 'squashed' animation not found.")
        
        GameManager.add_score(100)
        GameManager.GM_sfx_enemy_defeated()
        print("[{name}] Player awarded 100 points.")
        
        if player.has_method("get_jump_velocity"):
            player.velocity.y = player.get_jump_velocity() * 0.9 
        
        death_timer.start()
        print("[{name}] Death timer started.")

func _on_damage_area_body_entered(body: Node2D):
    if is_dying or not body.is_in_group("player"):
        return

    var player_node = body as Node
    if player_node and player_node.has_method("take_damage"):
        print("[{name}] Dealing damage to player {body.name}")
        player_node.take_damage(global_position)

func _on_death_timer_timeout():
    print("[{name}] Death timer triggered. Destroying enemy.")
    queue_free()
