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
# 기타 (Miscellaneous)
# ==========================================
## 현재 접속 중인 지역 (예: "한양 도성", "북악 귀림" 등)
var current_region: String = "한양 도성"

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
	# TODO: 레벨업 연출(이펙트, 사운드) 호출
	# TODO: 스탯 자동 증가 로직 연결
	print("[PlayerData] 레벨업! 현재 레벨: %d" % level)

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
