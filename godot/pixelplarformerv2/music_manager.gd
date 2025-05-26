extends Node

@onready var music_player: AudioStreamPlayer = $MusicPlayer

@export var main_menu_theme: AudioStream
@export var level_1_theme: AudioStream
@export var level_2_theme: AudioStream
@export var level_3_theme: AudioStream
@export var overlay_menu_theme: AudioStream

const NUM_SFX_PLAYERS = 5
var sfx_players: Array[AudioStreamPlayer] = []
var sfx_player_index: int = 0

@export var sfx_button_click: AudioStream
@export var sfx_player_jump: AudioStream
@export var sfx_player_damage: AudioStream
@export var sfx_coin_collect: AudioStream
@export var sfx_enemy_defeated: AudioStream
@export var sfx_block_hit: AudioStream
@export var sfx_powerup_spawn: AudioStream

var current_music_stream: AudioStream = null

func _ready():
    if not music_player:
        printerr("[MusicManager] _ready: !!! ERROR: MusicPlayer (AudioStreamPlayer) not found as child!")
    
    for i in range(NUM_SFX_PLAYERS):
        var new_sfx_player = AudioStreamPlayer.new()
        add_child(new_sfx_player)
        sfx_players.append(new_sfx_player)
    print("[MusicManager] _ready: Created {sfx_players.size()} players for SFX.")

func play_track(new_stream: AudioStream, target_volume_db: float = 0.0, force_restart: bool = false):
    if not is_instance_valid(new_stream):
        printerr("[MusicManager] Error: Attempting to play invalid AudioStream for music.")
        return

    if music_player.stream == new_stream and music_player.playing and not force_restart:
        if not is_equal_approx(music_player.volume_db, target_volume_db):
            music_player.volume_db = target_volume_db
        return

    print("[MusicManager] Starting music: '{new_stream.resource_path if new_stream else }'")
    music_player.stop()
    music_player.stream = new_stream
    music_player.volume_db = target_volume_db
    music_player.play()
    current_music_stream = new_stream

func stop_music():
    print("[MusicManager] Stopping music.")
    music_player.stop()
    current_music_stream = null

func set_volume_db(volume: float):
    music_player.volume_db = volume

func play_main_menu_music(force_restart: bool = true):
    if main_menu_theme:
        play_track(main_menu_theme, 0.0, force_restart)
    else:
        printerr("[MusicManager] Main menu theme (main_menu_theme) not assigned!")

func play_level_music_by_index(index: int, force_restart: bool = true):
    print("[MusicManager] Request for music for level with index: {index}")
    var theme_to_play: AudioStream = null
    match index:
        0:
            theme_to_play = level_1_theme
            if not theme_to_play: printerr("[MusicManager] Theme for Level 1 (level_1_theme) not assigned!")
        1:
            theme_to_play = level_2_theme
            if not theme_to_play: printerr("[MusicManager] Theme for Level 2 (level_2_theme) not assigned!")
        2:
            theme_to_play = level_3_theme
            if not theme_to_play: printerr("[MusicManager] Theme for Level 3 (level_3_theme) not assigned!")
        _:
            printerr("[MusicManager] No specific theme for level with index {index}. Trying default theme.")
            theme_to_play = level_1_theme
            if not theme_to_play: printerr("[MusicManager] Default level theme also not assigned!")
    
    if theme_to_play:
        play_track(theme_to_play, 0.0, force_restart)
    else:
        stop_music()

func play_overlay_menu_music(force_restart: bool = true):
    if overlay_menu_theme:
        play_track(overlay_menu_theme, 0.0, force_restart)
    else:
        printerr("[MusicManager] Overlay menu theme (overlay_menu_theme) not assigned! Using main menu theme or stopping.")
        if main_menu_theme:
            play_track(main_menu_theme, 0.0, force_restart)
        else:
            stop_music()

func fade_out_music(duration: float = 1.0):
    if music_player.playing:
        print("[MusicManager] Fading out music over {duration} sec.")
        var tween = create_tween()
        tween.tween_property(music_player, "volume_db", -80.0, duration).from_current()
        await tween.finished
        music_player.stop()
        current_music_stream = null

func fade_in_music(new_stream: AudioStream, duration: float = 1.0, target_volume_db: float = 0.0):
    if not is_instance_valid(new_stream):
        printerr("[MusicManager] Error: Attempting to fade in invalid AudioStream.")
        return
    
    print("[MusicManager] Fading in music '{new_stream.resource_path}' over {duration} sec.")
    music_player.stop()
    music_player.stream = new_stream
    music_player.volume_db = -80.0
    music_player.play()
    current_music_stream = new_stream

    var tween = create_tween()
    tween.tween_property(music_player, "volume_db", target_volume_db, duration)

func play_sfx(sfx_stream: AudioStream, volume_db: float = 0.0, pitch_scale: float = 1.0):
    if not is_instance_valid(sfx_stream):
        return

    if sfx_players.is_empty():
        printerr("[MusicManager] Error: SFX player pool is empty!")
        return

    var player_to_use = sfx_players[sfx_player_index]
    sfx_player_index = (sfx_player_index + 1) % sfx_players.size()

    player_to_use.stream = sfx_stream
    player_to_use.volume_db = volume_db
    player_to_use.pitch_scale = pitch_scale
    player_to_use.play()

func GM_sfx_button_click():
    play_sfx(sfx_button_click)

func GM_sfx_player_jump():
    play_sfx(sfx_player_jump, -5.0)

func GM_sfx_player_damage():
    play_sfx(sfx_player_damage)

func GM_sfx_coin_collect():
    play_sfx(sfx_coin_collect, 0.0, randf_range(0.9, 1.1)) 

func GM_sfx_enemy_defeated():
    play_sfx(sfx_enemy_defeated)

func GM_sfx_block_hit():
    play_sfx(sfx_block_hit)

func GM_sfx_powerup_spawn():
    play_sfx(sfx_powerup_spawn)
