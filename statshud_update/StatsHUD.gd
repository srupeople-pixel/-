extends CanvasLayer
# StatsHUD.gd
# 경험치·엽전·HP·MP 상시 표시 HUD 및 획득량 팝업 텍스트 처리

# ==========================================
# 노드 참조
# ==========================================
@onready var lbl_level : Label       = $HUDPanel/LblLevel
@onready var lbl_coin  : Label       = $HUDPanel/LblCoin

@onready var hp_bar    : ProgressBar = $HUDPanel/HpBar
@onready var lbl_hp    : Label       = $HUDPanel/LblHp

@onready var mp_bar    : ProgressBar = $HUDPanel/MpBar
@onready var lbl_mp    : Label       = $HUDPanel/LblMp

@onready var exp_bar   : ProgressBar = $BottomExpArea/ExpBar
@onready var lbl_exp   : Label       = $BottomExpArea/LblExp

@onready var popup_exp  : Label = $PopupLayer/PopupContainer/PopupExp
@onready var popup_coin : Label = $PopupLayer/PopupContainer/PopupCoin

# ==========================================
# 팝업 설정
# ==========================================
const POPUP_RISE_PX   : float = 40.0
const POPUP_DURATION  : float = 1.2
const POPUP_FADE_START: float = 0.6

var _exp_popup_offset : float = 0.0
var _coin_popup_offset: float = 0.0

# ==========================================
# 내장 콜백
# ==========================================

func _ready() -> void:
	PlayerData.exp_gained.connect(_on_exp_gained)
	PlayerData.coin_gained.connect(_on_coin_gained)
	PlayerData.hp_changed.connect(_on_hp_changed)
	PlayerData.mp_changed.connect(_on_mp_changed)
	_refresh_hud()

func _process(_delta: float) -> void:
	_refresh_hud()

# ==========================================
# HUD 갱신
# ==========================================

func _refresh_hud() -> void:
	var lv  : int = PlayerData.level
	var exp : int = PlayerData.experience
	var req : int = PlayerData.exp_required_for_level(lv)

	lbl_level.text = str(lv)
	lbl_coin.text  = _format_number(PlayerData.coin)

	exp_bar.max_value = req
	exp_bar.value     = exp
	lbl_exp.text      = "%d / %d EXP" % [exp, req]

	var max_hp : int = PlayerData.get_max_hp()
	hp_bar.max_value = max_hp
	hp_bar.value     = PlayerData.current_hp
	lbl_hp.text      = "%d / %d HP" % [PlayerData.current_hp, max_hp]

	var max_mp : int = PlayerData.get_max_mp()
	mp_bar.max_value = max_mp
	mp_bar.value     = PlayerData.current_mp
	lbl_mp.text      = "%d / %d MP" % [PlayerData.current_mp, max_mp]

# ==========================================
# 시그널 수신 (즉각 갱신)
# ==========================================

func _on_hp_changed(current: int, maximum: int) -> void:
	hp_bar.max_value = maximum
	hp_bar.value     = current
	lbl_hp.text      = "%d / %d HP" % [current, maximum]

func _on_mp_changed(current: int, maximum: int) -> void:
	mp_bar.max_value = maximum
	mp_bar.value     = current
	lbl_mp.text      = "%d / %d MP" % [current, maximum]

# ==========================================
# 팝업 텍스트
# ==========================================

func _on_exp_gained(amount: int) -> void:
	popup_exp.text = "+%d EXP" % amount
	_play_popup(popup_exp, _exp_popup_offset)
	_exp_popup_offset = fmod(_exp_popup_offset + 16.0, 48.0)

func _on_coin_gained(amount: int) -> void:
	popup_coin.text = "+%d 엽전" % amount
	_play_popup(popup_coin, _coin_popup_offset)
	_coin_popup_offset = fmod(_coin_popup_offset + 16.0, 48.0)

func _play_popup(lbl: Label, y_offset: float) -> void:
	var start_y : float = lbl.position.y + y_offset
	lbl.position.y = start_y
	lbl.modulate.a = 1.0
	lbl.visible    = true

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(lbl, "position:y", start_y - POPUP_RISE_PX, POPUP_DURATION)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(lbl, "modulate:a", 0.0, POPUP_DURATION - POPUP_FADE_START)\
		.set_delay(POPUP_FADE_START)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_LINEAR)
	tween.chain().tween_callback(func(): lbl.visible = false)

# ==========================================
# 유틸리티
# ==========================================

func _format_number(n: int) -> String:
	var s := str(n)
	var result := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = s[i] + result
		count += 1
	return result
