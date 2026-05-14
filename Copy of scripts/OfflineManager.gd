extends Node
# OfflineManager.gd
# '야화전' 오프라인 방치 보상 및 창고 관리 싱글톤 (Autoload)

# 마지막 접속 종료 시간을 저장하는 변수 (Unix Time)
var last_logout_time: int = 0

# 오프라인 최대 적립 시간 (12시간 = 43200초)
# 기획서 4.1 핵심 방치 루프: "최대 12시간 적립", "12시간 초과 시 창고 포화"
const MAX_OFFLINE_SECONDS: int = 12 * 60 * 60

# ==========================================
# 오프라인 시간 기록 및 계산
# ==========================================

## 게임 종료 시 호출하여 현재 시간을 저장하는 함수
func save_logout_time() -> void:
	last_logout_time = int(Time.get_unix_time_from_system())
	# TODO: 실제 구현에서는 이 값을 파일(SaveData)이나 서버에 저장해야 합니다.
	print("게임 종료 시간 저장됨: ", last_logout_time)

## 게임 접속 시 오프라인 경과 시간을 계산하는 함수
## 반환값: 적립 가능한 오프라인 시간 (초 단위)
func calculate_offline_time() -> int:
	if last_logout_time == 0:
		return 0 # 첫 접속이거나 기록이 없는 경우
		
	var current_time: int = int(Time.get_unix_time_from_system())
	var offline_seconds: int = current_time - last_logout_time
	
	# 창고 최대 보관 시간(PlayerData.max_offline_storage_hours)과
	# 방치 최대 적립 시간(12시간) 중 더 작은 값을 실제 상한으로 적용
	# (기본 창고 8시간, 확장 시 최대 24시간이나 방치 루프 자체의 상한은 12시간으로 명시됨)
	var storage_limit_seconds: int = PlayerData.max_offline_storage_hours * 60 * 60
	var actual_limit_seconds: int = min(MAX_OFFLINE_SECONDS, storage_limit_seconds)
	
	if offline_seconds > actual_limit_seconds:
		print("오프라인 창고 포화 상태입니다. (최대 ", actual_limit_seconds / 3600.0, "시간까지만 적립)")
		offline_seconds = actual_limit_seconds
		
	return offline_seconds

# ==========================================
# 오프라인 보상 지급
# ==========================================

## 계산된 오프라인 시간을 바탕으로 보상을 지급하는 함수
func process_offline_rewards() -> void:
	var offline_seconds: int = calculate_offline_time()
	
	if offline_seconds <= 0:
		print("지급할 오프라인 보상이 없습니다.")
		return
		
	print("오프라인 경과 시간: ", offline_seconds, "초")
	
	# 임시 드랍률 공식 (구체적인 수치는 기획에 따라 추후 채워넣음)
	var earned_coin: int = calculate_earned_coin(offline_seconds)
	var earned_exp: int = calculate_earned_exp(offline_seconds)
	
	# PlayerData에 보상 지급
	PlayerData.coin += earned_coin
	PlayerData.experience += earned_exp
	
	print("오프라인 보상 획득! 엽전: ", earned_coin, " / 경험치: ", earned_exp)
	
	# 보상 수령 후 시간 초기화 (재접속 시 중복 지급 방지)
	last_logout_time = int(Time.get_unix_time_from_system())

## 오프라인 시간에 비례한 엽전 획득량 계산 (임시 뼈대)
func calculate_earned_coin(seconds: int) -> int:
	# TODO: 지역별 엽전 드랍률, 영수 시너지(구미호 등) 적용
	var coin_per_second: float = 1.5 # 임시 수치
	return int(seconds * coin_per_second)

## 오프라인 시간에 비례한 경험치 획득량 계산 (임시 뼈대)
func calculate_earned_exp(seconds: int) -> int:
	# TODO: 지역별 경험치 획득량, 환생 보너스, 영수 시너지 적용
	var exp_per_second: float = 5.0 # 임시 수치
	return int(seconds * exp_per_second)
