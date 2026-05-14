extends CharacterBody2D

@export var speed = 60.0
@export var anim_speed = 0.2

## 플레이어에게 공격이 닿는 거리
@export var attack_range: float = 40.0
## 공격력 (플레이어 HP 감소량)
@export var attack_damage: int = 5
## 공격 쿨타임 (초)
@export var attack_cooldown: float = 1.5

# ==========================================
# 처치 보상 (기획서 4.1 핵심 방치 루프)
# ==========================================
## 이 몬스터를 처치했을 때 지급할 경험치
@export var exp_reward: int = 20
## 이 몬스터를 처치했을 때 지급할 엽전
@export var coin_reward: int = 5

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var player: Node2D = null
var anim_timer: float = 0.0
var anim_toggle: int = 0
var last_direction := Vector2.DOWN

var _attack_timer: float = 0.0  # 0이 되면 공격 가능

func _ready():
	add_to_group("Enemy")
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	player = get_tree().get_first_node_in_group("Player")
	update_sprite_frame(false)

func _physics_process(delta):
	_attack_timer = maxf(_attack_timer - delta, 0.0)

	if player and is_instance_valid(player):
		var distance = global_position.distance_to(player.global_position)

		if distance <= attack_range:
			# 사거리 안 — 멈추고 공격
			velocity = Vector2.ZERO
			update_sprite_frame(false)
			_try_attack()
		else:
			# 사거리 밖 — 플레이어 추적
			var direction = (player.global_position - global_position).normalized()
			velocity = direction * speed
			move_and_slide()

			anim_timer += delta
			if anim_timer >= anim_speed:
				anim_timer = 0.0
				anim_toggle = (anim_toggle + 1) % 2

			update_facing_direction(direction)
			update_sprite_frame(true)
	else:
		velocity = Vector2.ZERO
		anim_toggle = 0
		update_sprite_frame(false)

func _try_attack() -> void:
	if _attack_timer > 0.0:
		return
	_attack_timer = attack_cooldown
	PlayerData.take_damage(attack_damage)
	print("[적 공격] 플레이어에게 %d 피해!  HP: %d / %d" % [
		attack_damage, PlayerData.current_hp, PlayerData.get_max_hp()
	])

func update_facing_direction(direction: Vector2):
	if direction.length() == 0: return
	if abs(direction.x) >= abs(direction.y):
		last_direction = Vector2.LEFT if direction.x < 0 else Vector2.RIGHT
	else:
		last_direction = Vector2.UP if direction.y < 0 else Vector2.DOWN

func update_sprite_frame(is_moving: bool):
	var base_col = 0
	match last_direction:
		Vector2.DOWN:  base_col = 0
		Vector2.RIGHT: base_col = 2
		Vector2.LEFT:  base_col = 4
		Vector2.UP:    base_col = 6

	var current_col = base_col + (anim_toggle if is_moving else 0)
	var current_row = 1 if is_moving else 0
	sprite.frame_coords = Vector2i(current_col, current_row)

func die():
	# 처치 보상을 PlayerData 싱글톤에 지급한 뒤 오브젝트 제거
	PlayerData.add_exp(exp_reward)
	PlayerData.add_coin(coin_reward)
	queue_free()
