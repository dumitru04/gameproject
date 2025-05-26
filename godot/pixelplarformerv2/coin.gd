# coin.gd
extends Area2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D 

signal coin_collected 

func _ready():
    body_entered.connect(_on_body_entered)
    if animated_sprite:
     animated_sprite.play("spin")

func _on_body_entered(body):
    if body.name == "Player":
        GameManager.add_score(10)
        GameManager.GM_sfx_coin_collect()
        queue_free()
