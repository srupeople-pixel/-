extends Node2D

@export var enemy_scene: PackedScene
@export var spawn_interval: float = 2.5

# 스폰 영역 (벽 안쪽 기준)
@export var spawn_margin : float = 60.0   # 벽에서 얼마나 안쪽에 스폰할지
@export var area_x_min  : float = 60.0
@export var area_x_max  : float = 1860.0
@export var area_y_min  : float = 40.0   # 상단 EXP바 아래
@export var area_y_max  : float = 880.0  # 하단 메뉴 위

@onready var timer: Timer = $Timer

func _ready():
	timer.wait_time = spawn_interval
	timer.one_shot = false
	timer.timeout.connect(_on_timer_timeout)
	timer.start()

func _on_timer_timeout():
	if enemy_scene == null:
		return
	var enemy = enemy_scene.instantiate()
	enemy.global_position = _get_random_spawn_position()
	get_parent().add_child(enemy)

func _get_random_spawn_position() -> Vector2:
	return Vector2(
		randf_range(area_x_min + spawn_margin, area_x_max - spawn_margin),
		randf_range(area_y_min + spawn_margin, area_y_max - spawn_margin)
	)
