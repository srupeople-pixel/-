extends CharacterBody2D
# PlayerController.gd
# '야화전' 플레이어 컨트롤러 — 자동 전투 FSM (Finite State Machine)
# 기획서 6. 전투 시스템 기반
#
# [통합 방침]
#   - 기존 player.gd의 이동·애니메이션·공격 로직을 그대로 보존합니다.
#   - _physics_process 진입부를 FSM match 문으로 교체하여
#     상태별로 기존 로직 함수들을 호출하는 구조입니다.
#   - PlayerData(싱글톤)와 연동하여 레벨·엽전·경험치를 참조합니다.

# ==========================================
# FSM 상태 정의 (State Enum)
# ==========================================
enum State {
	IDLE,         # 대기 — 주변에 적이 없거나 자동 전투 비활성 상태
	AUTO_MOVE,    # 자동 이동 — 탐지된 적을 향해 접근 중
	AUTO_ATTACK,  # 자동 기본 공격 — 사거리 내 적에게 기본 공격 반복
	SKILL_CAST,   # 스킬 시전 — 쿨타임 복귀 즉시 우선순위 순으로 자동 발동
}

# ==========================================
# FSM 상태 변수
# ==========================================
## 현재 FSM 상태 (초기값: IDLE)
var current_state: State = State.IDLE

## 자동 전투 활성화 여부 (방치 모드 진입 시 true)
var is_auto_battle: bool = true

## 스킬 쿨타임 타이머 (0이 되면 스킬 발동 가능)
## TODO: 스킬이 여러 개가 되면 배열로 확장
var skill_timer: float = 0.0

## 스킬 쿨타임 (초 단위)
var skill_cooldown: float = 5.0

## 스킬 1회 MP 소모량
const SKILL_MP_COST: int = 20

## HP 재생 누적 버퍼 (소수점 누적 후 정수 단위로 heal)
var _hp_regen_buffer: float = 0.0
## MP 재생 누적 버퍼
var _mp_regen_buffer: float = 0.0

# ==========================================
# 기존 player.gd 변수 (원본 보존)
# ==========================================
@export var speed = 150.0
@export var attack_range = 60.0

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
@onready var sword_sfx: AudioStreamPlayer = $SwordSFX

var target_enemy: Node2D = null
var is_attacking := false

const MAP_MIN = Vector2(30, 30)
const MAP_MAX = Vector2(1890, 890)

var last_direction := Vector2.DOWN

var anim_timer: float = 0.0
var anim_toggle: int = 0
@export var anim_speed: float = 0.2

# ==========================================
# 내장 콜백
# ==========================================

func _ready() -> void:
	add_to_group("Player")
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	update_sprite_frame(false)
	# 게임 시작 시 오프라인 보상 처리 (OfflineManager 싱글톤 연동)
	OfflineManager.process_offline_rewards()

func _physics_process(delta: float) -> void:
	# HP 재생 — 항상 진행
	_hp_regen_buffer += PlayerData.get_hp_regen() * delta
	if _hp_regen_buffer >= 1.0:
		var amount := int(_hp_regen_buffer)
		PlayerData.heal(amount)
		_hp_regen_buffer -= amount

	# MP 재생 — 항상 진행
	_mp_regen_buffer += PlayerData.get_mp_regen() * delta
	if _mp_regen_buffer >= 1.0:
		var amount := int(_mp_regen_buffer)
		PlayerData.restore_mp(amount)
		_mp_regen_buffer -= amount

	# 공격 애니메이션 재생 중에는 FSM 진입 차단 (기존 로직과 동일)
	if is_attacking:
		return

	# 스킬 쿨타임 타이머는 상태와 무관하게 매 프레임 감소
	skill_timer = maxf(skill_timer - delta, 0.0)

	match current_state:
		State.IDLE:
			_state_idle()

		State.AUTO_MOVE:
			_state_auto_move(delta)

		State.AUTO_ATTACK:
			_state_auto_attack()

		State.SKILL_CAST:
			_state_skill_cast()

# ==========================================
# 상태별 처리 함수
# ==========================================

## [IDLE] 대기 상태
## 자동 전투가 활성화되어 있으면 즉시 적 탐색을 시도하고,
## 타겟이 발견되면 AUTO_MOVE로 전이한다.
func _state_idle() -> void:
	velocity = Vector2.ZERO
	anim_toggle = 0
	update_sprite_frame(false)

	if not is_auto_battle:
		return

	target_enemy = _find_nearest_enemy()
	if target_enemy != null:
		_change_state(State.AUTO_MOVE)

## [AUTO_MOVE] 자동 이동 상태
## 타겟이 사라지면 IDLE로 복귀하고,
## 사거리 안에 들어오면 AUTO_ATTACK으로 전이한다.
## 스킬 쿨타임이 복귀되어 있으면 SKILL_CAST를 우선 발동한다.
func _state_auto_move(delta: float) -> void:
	if target_enemy == null or not is_instance_valid(target_enemy):
		_change_state(State.IDLE)
		return

	# 스킬 쿨타임 복귀 시 이동 중에도 즉시 스킬 우선 발동 (기획서 6절)
	if skill_timer <= 0.0:
		_change_state(State.SKILL_CAST)
		return

	var distance: float = global_position.distance_to(target_enemy.global_position)
	if distance <= attack_range:
		_change_state(State.AUTO_ATTACK)
		return

	# 기존 player.gd 이동 로직 그대로 사용
	var direction := (target_enemy.global_position - global_position).normalized()
	velocity = direction * PlayerData.get_move_speed()
	move_and_slide()

	anim_timer += delta
	if anim_timer >= anim_speed:
		anim_timer = 0.0
		anim_toggle = (anim_toggle + 1) % 2

	update_facing_direction(direction)
	update_sprite_frame(true)

## [AUTO_ATTACK] 자동 기본 공격 상태
## 타겟이 사거리를 벗어나면 AUTO_MOVE로 복귀하고,
## 스킬 쿨타임이 복귀되면 SKILL_CAST를 우선한다.
func _state_auto_attack() -> void:
	if target_enemy == null or not is_instance_valid(target_enemy):
		_change_state(State.IDLE)
		return

	# 스킬 쿨타임 복귀 시 기본 공격보다 스킬을 우선 발동 (기획서 6절)
	if skill_timer <= 0.0:
		_change_state(State.SKILL_CAST)
		return

	var distance: float = global_position.distance_to(target_enemy.global_position)
	if distance > attack_range:
		_change_state(State.AUTO_MOVE)
		return

	# 기존 player.gd attack() 호출
	attack()

## [SKILL_CAST] 스킬 시전 상태
## 스킬을 1회 발동한 뒤 즉시 AUTO_ATTACK으로 복귀한다.
## 타겟이 없으면 IDLE로 복귀한다.
func _state_skill_cast() -> void:
	if target_enemy == null or not is_instance_valid(target_enemy):
		_change_state(State.IDLE)
		return

	_perform_skill()
	skill_timer = skill_cooldown

	# 스킬 시전 후 기본 공격 상태로 복귀
	_change_state(State.AUTO_ATTACK)

# ==========================================
# 상태 전이 헬퍼
# ==========================================

## 상태를 전이하고 진입/퇴장 처리를 중앙에서 관리한다.
func _change_state(new_state: State) -> void:
	if current_state == new_state:
		return
	# TODO: 퇴장(exit) 처리 — 현재 상태에서 나갈 때 필요한 정리 작업
	current_state = new_state
	# TODO: 진입(enter) 처리 — 새 상태에 진입할 때 애니메이션 재생 등

# ==========================================
# 전투 액션 뼈대 (신규)
# ==========================================

## 스킬 발동 뼈대
## TODO: 우선순위 큐에서 발동 가능한 스킬 선택, 이펙트 재생, 데미지 계산 구현
func _perform_skill() -> void:
	# MP 부족 시 스킬 발동 취소
	if not PlayerData.use_mp(SKILL_MP_COST):
		return
	print("[스킬] 발동! MP 소모: %d  |  잔여 MP: %d" % [SKILL_MP_COST, PlayerData.current_mp])

## 가장 가까운 적 탐색 — 기존 find_closest_enemy() 로직을 래핑
func _find_nearest_enemy() -> Node2D:
	find_closest_enemy()
	return target_enemy

# ==========================================
# 기존 player.gd 함수 (원본 보존)
# ==========================================

func update_facing_direction(direction: Vector2) -> void:
	if direction.length() == 0:
		return
	if abs(direction.x) >= abs(direction.y):
		sprite.flip_h = false
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

func update_sprite_frame(is_moving: bool) -> void:
	if animation_player.is_playing() and animation_player.current_animation != "attack":
		animation_player.stop()

	var base_col := 0
	if last_direction == Vector2.DOWN:
		base_col = 0
	elif last_direction == Vector2.RIGHT:
		base_col = 2
	elif last_direction == Vector2.LEFT:
		base_col = 4
	elif last_direction == Vector2.UP:
		base_col = 6

	var current_col := base_col + (anim_toggle if is_moving else 0)
	var current_row := 1 if is_moving else 0
	sprite.frame_coords = Vector2i(current_col, current_row)

func find_closest_enemy() -> void:
	var enemies := get_tree().get_nodes_in_group("Enemy")
	var closest_distance := INF
	target_enemy = null

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var distance := global_position.distance_to(enemy.global_position)
		if distance < closest_distance:
			closest_distance = distance
			target_enemy = enemy

func attack() -> void:
	is_attacking = true
	velocity = Vector2.ZERO

	if target_enemy and is_instance_valid(target_enemy):
		var direction := (target_enemy.global_position - global_position).normalized()
		update_facing_direction(direction)
		update_sprite_frame(false)

	sword_sfx.play()
	animation_player.speed_scale = PlayerData.get_attack_speed()
	animation_player.play("attack")

func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "attack":
		animation_player.speed_scale = 1.0
		is_attacking = false
		sword_sfx.stop()
		if target_enemy and is_instance_valid(target_enemy):
			if target_enemy.has_method("die"):
				target_enemy.die()
			else:
				target_enemy.queue_free()
		target_enemy = null
		# 공격 완료 후 상태 재평가 (타겟이 사라졌으므로 IDLE로 복귀)
		_change_state(State.IDLE)
