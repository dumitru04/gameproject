extends Area2D

var initial_impulse_y = -100
var gravity_pull = 250
var current_velocity = Vector2.ZERO
var can_be_collected = false
var can_move = false

func _ready():
    set_deferred("monitoring", false) 
    
    var timer = get_tree().create_timer(0.25)
    timer.timeout.connect(func(): 
        set_deferred("monitoring", true)
        can_be_collected = true
        can_move = true
        current_velocity.y = initial_impulse_y
    )
    body_entered.connect(_on_body_entered)

func _physics_process(delta):
    if can_move:
        current_velocity.y += gravity_pull * delta
        position += current_velocity * delta

func _on_body_entered(body):
    if can_be_collected and body.is_in_group("player"):
        GameManager.add_life()
        GameManager.GM_sfx_powerup_spawn()
        queue_free() 
