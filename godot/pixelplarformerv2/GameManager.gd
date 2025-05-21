extends Node

var score = 0
var lives = 3

# Сигналы для обновления UI
signal score_updated(new_score)
signal lives_updated(new_lives)

func add_score(amount):
    score += amount
    emit_signal("score_updated", score)
    print("Счет: ", score)

func lose_life():
    lives -= 1
    emit_signal("lives_updated", lives)
    print("Жизней осталось: ", lives)
    if lives <= 0:
        # Логика окончания игры
        print("Игра окончена из GameManager!")
        # get_tree().reload_current_scene() # Например, перезапуск

func reset_game():
    score = 0
    lives = 3
    emit_signal("score_updated", score)
    emit_signal("lives_updated", lives)
