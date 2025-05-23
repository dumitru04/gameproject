# GameManager.gd
extends Node

var score = 0
var lives = 1  # Начальное количество жизней
var max_lives = 3 # Максимальное количество жизней
var points_for_extra_life = 500 # Очки за жизнь, если жизни уже на максимуме

signal score_updated(new_score)
signal lives_updated(new_lives)
signal score_added_for_life(points_value) # Сигнал для UI о начислении очков вместо жизни

func _ready():
    # Вызываем reset_game_state() при старте, чтобы инициализировать значения
    reset_game_state() 

func add_score(amount: int):
    score += amount
    emit_signal("score_updated", score)

func lose_life():
    lives -= 1
    emit_signal("lives_updated", lives)
    if lives < 0: 
        lives = 0 # Жизни не должны быть отрицательными
        emit_signal("lives_updated", lives) # Обновляем UI, если было < 0
        print("Игра окончена из GameManager!")
        # Логика "Game Over", например, перезапуск текущей сцены:
        get_tree().reload_current_scene() 
func fall_life():
    lives -= 5
    emit_signal("lives_updated", lives)
    if lives < 0: 
        lives = 0 # Жизни не должны быть отрицательными
        emit_signal("lives_updated", lives) # Обновляем UI, если было < 0
        print("Игра окончена из GameManager!")
        # Логика "Game Over", например, перезапуск текущей сцены:
        get_tree().reload_current_scene() 

func add_life():
    if lives < max_lives:
        lives += 1
        emit_signal("lives_updated", lives)
        # Здесь можно проиграть звук получения жизни
    else:
        add_score(points_for_extra_life)
        emit_signal("score_added_for_life", points_for_extra_life)
        print("Максимум жизней достигнут. Начислено {points_for_extra_life} очков.")
        # Здесь можно проиграть звук получения очков (отличный от звука получения жизни)

func reset_game_state():
    score = 0
    lives = 1 # Устанавливаем начальное количество жизней
    emit_signal("score_updated", score)
    emit_signal("lives_updated", lives)
