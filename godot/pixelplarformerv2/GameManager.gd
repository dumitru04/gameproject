extends Node

var score = 0
var lives = 1  # Начальное количество жизней
var max_lives = 3 # Максимальное количество жизней
var points_for_extra_life = 500 # Очки за жизнь, если достигнут максимум

signal score_updated(new_score)
signal lives_updated(new_lives)
# Сигнал для UI, чтобы показать, что были начислены очки вместо жизни
signal score_added_for_life(points_value) 

func _ready():
    # Вы можете захотеть сбрасывать это при каждом запуске игры или уровня
    reset_game_state() 

func add_score(amount: int):
    score += amount
    emit_signal("score_updated", score)

func lose_life():
    lives -= 1
    emit_signal("lives_updated", lives)
    if lives < 0: # Обычно жизни не уходят в минус, 0 - это конец игры
        lives = 0 # Корректируем на всякий случай
        emit_signal("lives_updated", lives) # Обновляем UI если было <0
        print("Игра окончена из GameManager!")
        # Здесь логика "Game Over", например, перезапуск текущей сцены:
        get_tree().reload_current_scene() 

func add_life():
    if lives < max_lives:
        lives += 1
        emit_signal("lives_updated", lives)
        # Проиграть звук получения жизни
    else:
        add_score(points_for_extra_life)
        emit_signal("score_added_for_life", points_for_extra_life) # Отправляем сигнал с количеством очков
        print("Максимум жизней достигнут. Начислено {points_for_extra_life} очков.")
        # Проиграть звук получения очков

func reset_game_state(): # Вызывать при старте новой игры или перезапуске уровня (если нужно)
    score = 0
    lives = 1
    emit_signal("score_updated", score)
    emit_signal("lives_updated", lives)

# Вызовите эту функцию при старте игры (например, из главной сцены или _ready() GameManager)
# reset_game_state()
