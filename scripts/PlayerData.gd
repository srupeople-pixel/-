extends Node
# PlayerData.gd
# '야화전' 플레이어 전역 데이터 관리 싱글톤 (Autoload)

# ==========================================
# 시그널 (Signal)
# ==========================================
## 경험치가 지급될 때 발생 — 실제 지급된 양(보너스 적용 후)을 전달
signal exp_gained(amount: int)
## 엽전이 지급될 때 발생 — 지급된 양을 전달
signal coin_gained(amount: int)
## HP가 변할 때 발생
signal hp_changed(current: int, maximum: int)
## MP가 변할 때 발생
signal mp_changed(current: int, maximum: int)

# ==========================================
# 기본 스탯 (Base Stats)
# ==========================================
## 플레이어의 현재 레벨 (초기값: 1)
var level: int = 1
## 보유 중인 엽전 (골드)
var coin: int = 0
## 현재 누적된 경험치
var experience: int = 0

# ==========================================
# 방치형 특화 데이터 (Idle-specific Data)
# ==========================================
## 환생 횟수 (누적 스탯 영구 증가 및 빠른 성장에 영향)
var rebirth_count: int = 0
## 보유 중인 영혼석 개수 (환생 시 획득 및 유지되는 재화)
var soul_stone: int = 0
## 오프라인 창고 최대 보관 시간 (단위: 시간, 기본 8시간)
var max_offline_storage_hours: int = 8

# ==========================================
# 6대 핵심 스탯 (六大 核心 能力値) — 기획서 10.1
# ==========================================
## 무력 (武力) — 물리 공격력 +3/포인트, 귀신 관통력 +1/포인트
var stat_strength: int = 0
## 신법 (身法) — 회피율 +0.5%/포인트, 이동속도 +1/포인트, 치명타율 +0.3%/포인트
var stat_agility: int = 0
## 영력 (靈力) — 술법 공격력 +3/포인트, 스킬 쿨타임 -0.1%/포인트
var stat_intelligence: int = 0
## 체력 (體力) — 최대 HP +20/포인트, HP 재생 +0.2/초/포인트
var stat_vitality: int = 0
## 심안 (心眼) — 드랍률 +0.4%/포인트, 귀신 탐지 범위 +2/포인트
var stat_perception: int = 0
## 원기 (元氣) — 방어력 +2/포인트, 상태이상 저항 +0.5%/포인트
var stat_endurance: int = 0
## 신속 (迅速) — 공격속도 +1%/포인트 (최대 +100%)
var stat_attack_speed: int = 0
## 정신력 (精神力) — 최대 MP +15/포인트, MP 재생 +0.1/초/포인트
var stat_mana: int = 0

## 배분 가능한 스탯 포인트 (레벨업 시 5포인트 지급)
var stat_points: int = 0
## 환생 누적 영구 보너스 스탯 (환생 횟수에 따라 증가)
var rebirth_stat_bonus: int = 0

# ==========================================
# 기타 (Miscellaneous)
# ==========================================
## 현재 접속 중인 지역 (예: "한양 도성", "북악 귀림" 등)
var current_region: String = "한양 도성"

## 현재 HP (0이 되면 전투 불능)
var current_hp: int = 0
## 현재 MP (스킬 사용 시 소모)
var current_mp: int = 0

# ==========================================
# 파생 스탯 계산 (Derived Stats — 기획서 10.2)
# 장비·버프·영수 보너스는 호출 측에서 더해서 사용
# ==========================================
func get_max_hp() -> int:
	return stat_vitality * 20 + level * 50

func get_physical_attack() -> int:
	return stat_strength * 3

func get_magic_attack() -> int:
	return stat_intelligence * 3

func get_defense() -> int:
	return stat_endurance * 2

## 치명타율 (%) — 최대 60% 상한
func get_crit_rate() -> float:
	return minf(stat_agility * 0.3, 60.0)

## 치명타 배율 — 장비 보너스 제외 기본값
func get_crit_multiplier() -> float:
	return 1.5

## 회피율 (%) — 최대 40% 상한
func get_evasion_rate() -> float:
	return minf(stat_agility * 0.5, 40.0)

## 귀신 관통력
func get_penetration() -> int:
	return stat_strength

## HP 재생 (/초) — 기본 1.0 + 체력×0.2
func get_hp_regen() -> float:
	return stat_vitality * 0.2 + 1.0

## 드랍률 보정 (%)
func get_drop_rate_bonus() -> float:
	return stat_perception * 0.4

## 이동속도 — 기본 150 + 신법×1
func get_move_speed() -> float:
	return 150.0 + stat_agility * 1.0

## 공격속도 배율 (1.0 = 기본, 최대 2.0)
func get_attack_speed() -> float:
	return minf(1.0 + stat_attack_speed * 0.01, 2.0)

## 최대 MP — 영력×10 + 정신력×15 + 레벨×20
func get_max_mp() -> int:
	return stat_intelligence * 10 + stat_mana * 15 + level * 20

## MP 재생 속도 (/초) — 영력×0.1 + 정신력×0.1 + 기본 0.5
func get_mp_regen() -> float:
	return stat_intelligence * 0.1 + stat_mana * 0.1 + 0.5

# ==========================================
# HP / MP 조작 함수
# ==========================================

## 씬 시작 시 HP·MP를 최대치로 초기화
func _ready() -> void:
	full_restore()

## 스탯 변경 후 HP·MP 상한만 재계산한다 (현재값 유지, 초과분만 잘라냄).
## 스탯 배분 시 호출.
func recalculate_vitals() -> void:
	current_hp = clampi(current_hp, 0, get_max_hp())
	current_mp = clampi(current_mp, 0, get_max_mp())
	hp_changed.emit(current_hp, get_max_hp())
	mp_changed.emit(current_mp, get_max_mp())

## HP·MP를 최대치로 완전 회복한다. 레벨업·게임 시작 시 호출.
func full_restore() -> void:
	current_hp = get_max_hp()
	current_mp = get_max_mp()
	hp_changed.emit(current_hp, get_max_hp())
	mp_changed.emit(current_mp, get_max_mp())

## 피해를 받는다. HP가 0이 되면 전투 불능.
func take_damage(amount: int) -> void:
	current_hp = clampi(current_hp - amount, 0, get_max_hp())
	hp_changed.emit(current_hp, get_max_hp())

## HP를 회복한다.
func heal(amount: int) -> void:
	current_hp = clampi(current_hp + amount, 0, get_max_hp())
	hp_changed.emit(current_hp, get_max_hp())

## MP를 소모한다. 부족하면 false 반환(스킬 발동 불가).
func use_mp(amount: int) -> bool:
	if current_mp < amount:
		return false
	current_mp -= amount
	mp_changed.emit(current_mp, get_max_mp())
	return true

## MP를 회복한다.
func restore_mp(amount: float) -> void:
	current_mp = clampi(current_mp + int(amount), 0, get_max_mp())
	mp_changed.emit(current_mp, get_max_mp())

# ==========================================
# 경험치 / 레벨업 (기획서 3.2)
# ==========================================

## 레벨별 필요 경험치를 계산한다.
## 공식: 기본 50 × 레벨 × 1.15^(레벨-1) — 추후 기획 수치로 교체 가능
func exp_required_for_level(lv: int) -> int:
	return int(50 * lv * pow(1.15, lv - 1))

## 경험치를 지급하고, 조건이 충족되면 레벨업을 처리한다.
## 환생 보너스(rebirth_count × 20%)가 자동 적용된다.
func add_exp(amount: int) -> void:
	# 환생 횟수에 비례한 경험치 보너스 적용 (환생 1회당 +20%)
	var bonus_rate: float = 1.0 + rebirth_count * 0.20
	var actual_amount: int = int(amount * bonus_rate)

	experience += actual_amount

	# StatsHUD 팝업용 시그널 발생 (보너스 적용된 실제 획득량 전달)
	exp_gained.emit(actual_amount)

	# 레벨업 반복 처리 (한 번에 여러 레벨 오를 수 있음)
	while experience >= exp_required_for_level(level):
		experience -= exp_required_for_level(level)
		level += 1
		_on_level_up()

## 레벨업 시 호출되는 내부 처리 함수 (추후 스탯 증가·연출 연동)
func _on_level_up() -> void:
	stat_points += 5  # 레벨업마다 스탯 포인트 5 지급
	full_restore()    # 레벨업 시 HP·MP 완전 회복
	print("[PlayerData] 레벨업! 현재 레벨: %d  |  잔여 포인트: %d" % [level, stat_points])

# ==========================================
# 엽전 (기획서 4.1 / 4.4)
# ==========================================

## 엽전을 지급한다. 음수 입력은 무시한다.
func add_coin(amount: int) -> void:
	if amount <= 0:
		return
	coin += amount

	# StatsHUD 팝업용 시그널 발생
	coin_gained.emit(amount)
