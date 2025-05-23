# ui.gd
extends CanvasLayer

@onready var score_label: Label = $ScoreLabel
@onready var lives_label: Label = $LivesLabel
@onready var notification_label: Label = $NotificationLabel # Для сообщений типа "+500 очков"

func _ready():
    # Подписываемся на сигналы от GameManager
    GameManager.score_updated.connect(_on_score_updated)
    GameManager.lives_updated.connect(_on_lives_updated)
    GameManager.score_added_for_life.connect(_on_score_added_for_life)
    
    # Инициализируем значения при запуске UI
    _on_score_updated(GameManager.score)
    _on_lives_updated(GameManager.lives)
    
    if notification_label:
        notification_label.hide() # Скрываем уведомления по умолчанию

func _on_score_updated(new_score: int):
    if score_label:
        score_label.text = "Счет: " + str(new_score)

func _on_lives_updated(new_lives: int):
    if lives_label:
        lives_label.text = "Жизни: " + str(new_lives)

func _on_score_added_for_life(points_value: int):
    if notification_label:
        notification_label.text = "+{points_value} ОЧКОВ!"
        notification_label.show()
        # Создаем таймер, чтобы скрыть сообщение через некоторое время
        var timer = get_tree().create_timer(2.0) # Показать на 2 секунды
        timer.timeout.connect(notification_label.hide)
    else:
        print("UI: Игрок получил {points_value} очков за лишнюю жизнь!")
