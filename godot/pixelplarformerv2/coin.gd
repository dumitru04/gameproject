extends Area2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D # Если используете AnimatedSprite2D
# @onready var sprite: Sprite2D = $Sprite2D # Если используете Sprite2D

signal coin_collected # Сигнал, который будет отправлен при сборе монеты

func _ready():
    # Подключаем сигнал body_entered к нашей функции
    body_entered.connect(_on_body_entered)
    if animated_sprite: # Если есть анимация
     animated_sprite.play("spin") # Предполагаем, что есть анимация "spin"

func _on_body_entered(body):
    if body.name == "Player":
        GameManager.add_score(10) # Добавляем очки через GameManager
        # emit_signal("coin_collected") # Сигнал теперь может быть не нужен, если UI обновляется через GameManager
        queue_free()
