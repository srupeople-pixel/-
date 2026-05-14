extends TextureProgressBar
# ExpBar.gd
# 경험치 바 전용 스크립트
# TextureProgressBar의 value를 Tween으로 부드럽게 갱신한다.
# StatsHUD.tscn의 ExpBar 노드에 부착하여 사용한다.

# ==========================================
# 설정
# ==========================================
## Tween 전환 시간 (초) — 경험치가 들어올 때 바가 채워지는 속도
@export var tween_duration: float = 0.3

# ==========================================
# 내장 콜백
# ==========================================

func _ready() -> void:
	# TextureProgressBar 기본 범위 설정
	min_value = 0.0
	max_value = 100.0
	value    = 0.0

# ==========================================
# 공개 API
# ==========================================

## 새 값(0.0 ~ 100.0 비율)으로 바를 부드럽게 갱신한다.
## StatsHUD.gd에서 매 프레임 또는 경험치 획득 시 호출한다.
func update_bar(new_value: float) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "value", clampf(new_value, 0.0, 100.0), tween_duration)

## 레벨업 시 바를 즉시 0으로 초기화한 뒤 새 경험치 비율로 채운다.
## (레벨업 직후 바가 100에서 새 값으로 자연스럽게 이어지도록 처리)
func reset_and_fill(new_value: float) -> void:
	# 먼저 100으로 채운 뒤 즉시 0으로 리셋, 그 다음 새 비율로 채움
	value = 100.0
	await get_tree().process_frame
	value = 0.0
	update_bar(new_value)
