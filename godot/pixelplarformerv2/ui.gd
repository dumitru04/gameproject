extends CanvasLayer

@onready var score_label: Label = $ScoreLabel
@onready var lives_label: Label = $LivesLabel

func _ready():
    # Подписываемся на сигналы от GameManager
    GameManager.score_updated.connect(_on_score_updated)
    GameManager.lives_updated.connect(_on_lives_updated)

    # Инициализируем значения при запуске
    _on_score_updated(GameManager.score)
    _on_lives_updated(GameManager.lives)

func _on_score_updated(new_score):
    score_label.text = "Счет: " + str(new_score)

func _on_lives_updated(new_lives):
    lives_label.text = "Жизни: " + str(new_lives)
