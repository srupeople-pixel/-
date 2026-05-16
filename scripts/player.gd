extends CharacterBody2D

@export var speed = 150.0
@export var attack_range = 60.0

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
@onready var sword_sfx: AudioStreamPlayer = $SwordSFX

var target_enemy: Node2D = null
var is_attacking := false

# 맵 경계 (뷰포트 크기에 맞춤)
const MAP_MIN = Vector2(20, 20)
const MAP_MAX = Vector2(1132, 628)

# 마지막으로 바라본 방향 저장
var last_direction := Vector2.DOWN

# ★ 걷기 애니메이션용 타이머 변수
var anim_timer: float = 0.0
var anim_toggle: int = 0
@export var anim_speed: float = 0.2 # 0.2초마다 발걸음(프레임)이 바뀜

func _ready():
	add_to_group("Player")
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	update_sprite_frame(false) # 시작 시 대기 상태

func _physics_process(delta):
	if is_attacking:
		return

	find_closest_enemy()

	if target_enemy != null and is_instance_valid(target_enemy):
		var distance = global_position.distance_to(target_enemy.global_position)

		if distance <= attack_range:
			attack()
		else:
			var direction = (target_enemy.global_position - global_position).normalized()
			velocity = direction * PlayerData.get_move_speed()
			move_and_slide()

			
			# ★ 이동 중일 때만 애니메이션 타이머 작동
			anim_timer += delta
			if anim_timer >= anim_speed:
				anim_timer = 0.0
				# 0과 1을 번갈아가며 토글 (0 -> 1 -> 0 -> 1)
				anim_toggle = (anim_toggle + 1) % 2 
			
			update_facing_direction(direction)
			update_sprite_frame(true) 
	else:
		# 적이 없어 멈추면 타이머 초기화 및 대기 자세
		velocity = Vector2.ZERO
		anim_toggle = 0 
		update_sprite_frame(false)

func update_facing_direction(direction: Vector2):
	if direction.length() == 0:
		return
		
	# x축 이동이 더 크면 좌/우 우선
	if abs(direction.x) >= abs(direction.y):
		sprite.flip_h = false # 좌우 이미지가 다 있으므로 반전 끔
		if direction.x < 0:
			last_direction = Vector2.LEFT
		else:
			last_direction = Vector2.RIGHT
	else:
		sprite.flip_h = false
		if direction.y < 0:
			last_direction = Vector2.UP
		else:
			last_direction = Vector2.DOWN

# 핵심: 방향과 타이머(anim_toggle)에 따라 정확한 도트 칸을 렌더링
func update_sprite_frame(is_moving: bool):
	if animation_player.is_playing() and animation_player.current_animation != "attack":
		animation_player.stop()

	var base_col = 0 # 기준 열(Column) 번호
	
	# 방향에 따라 시작 열 번호를 지정 (0, 2, 4, 6)
	if last_direction == Vector2.DOWN:      # 앞모습
		base_col = 0
	elif last_direction == Vector2.RIGHT:   # 오른쪽
		base_col = 2
	elif last_direction == Vector2.LEFT:    # 왼쪽
		base_col = 4
	elif last_direction == Vector2.UP:      # 뒷모습
		base_col = 6

	# 이동 중이면 기준 열(base_col)에 +0, +1을 번갈아 더해서 애니메이션 효과를 줌.
	# 멈춰있으면 무조건 +0을 해서 첫 번째 자세(대기)로 고정.
	var current_col = base_col + (anim_toggle if is_moving else 0)

	# 걷기 프레임이 2번째 줄(Index 1)에 있고, 대기 프레임이 1번째 줄(Index 0)에 있는 기존 로직 유지
	var current_row = 1 if is_moving else 0
	
	sprite.frame_coords = Vector2i(current_col, current_row)

func find_closest_enemy():
	var enemies = get_tree().get_nodes_in_group("Enemy")
	var closest_distance = INF
	target_enemy = null

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var distance = global_position.distance_to(enemy.global_position)
		if distance < closest_distance:
			closest_distance = distance
			target_enemy = enemy

func attack():
	is_attacking = true
	velocity = Vector2.ZERO

	if target_enemy and is_instance_valid(target_enemy):
		var direction = (target_enemy.global_position - global_position).normalized()
		update_facing_direction(direction)
		# 공격할 때도 방향을 맞춘 기본 프레임을 먼저 잡아줍니다.
		update_sprite_frame(false) 
	
	sword_sfx.play()
	animation_player.speed_scale = PlayerData.get_attack_speed()
	animation_player.play("attack")

func _on_animation_finished(anim_name: String):
	if anim_name == "attack":
		animation_player.speed_scale = 1.0
		is_attacking = false
		if target_enemy and is_instance_valid(target_enemy):
			if target_enemy.has_method("die"):
				target_enemy.die()
			else:
				target_enemy.queue_free()
		target_enemy = null
