extends CanvasLayer
# GameUI.gd
# '야화전' 전체 통합 UI 관리 스크립트
# - 하단 버튼 6개로 탭 전환 (같은 버튼 재클릭 시 닫힘)
# - ESC 키로 열린 패널 닫기
# - 각 탭 진입 시 해당 시스템 데이터를 Label에 갱신

# ==========================================
# 탭 인덱스 상수 (TabContainer 순서와 일치)
# ==========================================
const TAB_GROWTH    : int = 0  # [성장]
const TAB_EQUIP     : int = 1  # [장비]
const TAB_RELIC     : int = 2  # [유물]
const TAB_SPIRIT    : int = 3  # [영수]
const TAB_REBIRTH   : int = 4  # [환생]
const TAB_COMMUNITY : int = 5  # [커뮤니티]
const TAB_MOVE      : int = 6  # [이동]

const ZONES : Array = [
	{"name": "한양 도성",  "min_lv": 1,  "desc": "도성 내 출몰하는 잡귀"},
	{"name": "북악 귀림",  "min_lv": 16, "desc": "북악산 귀신이 우글거리는 숲"},
	{"name": "남산 요굴",  "min_lv": 36, "desc": "남산 기슭의 요괴 소굴"},
	{"name": "한강 유역",  "min_lv": 61, "desc": "한강변을 떠도는 물귀신"},
	{"name": "도성 외곽",  "min_lv": 91, "desc": "도성 밖 험준한 황무지"},
]

const ZONE_BACKGROUNDS : Dictionary = {
	"한양 도성": "res://assets/Han.png",
	"북악 귀림": "res://assets/Buk.png",
}

# ==========================================
# 노드 참조 (@onready)
# ==========================================

# 중앙 탭 영역 (show/hide 대상)
@onready var tab_area      : Control      = $RootContainer/TabArea
@onready var tab_container : TabContainer = $RootContainer/TabArea/TabContainer

# 하단 버튼
@onready var btn_growth    : Button = $RootContainer/BottomBar/BtnGroup/BtnGrowth
@onready var btn_equip     : Button = $RootContainer/BottomBar/BtnGroup/BtnEquip
@onready var btn_relic     : Button = $RootContainer/BottomBar/BtnGroup/BtnRelic
@onready var btn_spirit    : Button = $RootContainer/BottomBar/BtnGroup/BtnSpirit
@onready var btn_rebirth   : Button = $RootContainer/BottomBar/BtnGroup/BtnRebirth
@onready var btn_community : Button = $RootContainer/BottomBar/BtnGroup/BtnCommunity
@onready var btn_move      : Button = $RootContainer/BottomBar/BtnGroup/BtnMove
@onready var btn_close     : Button = $RootContainer/TabArea/BtnClose

# ── [이동] 탭 노드
@onready var lbl_current_zone : Label         = $RootContainer/TabArea/TabContainer/PanelMove/Layout/LblCurrentZone
@onready var zone_list        : VBoxContainer = $RootContainer/TabArea/TabContainer/PanelMove/Layout/ScrollContainer/ZoneList

# ── [성장] 탭 노드
@onready var lbl_stat_points     : Label  = $RootContainer/TabArea/TabContainer/PanelGrowth/Layout/LblStatPoints
@onready var lbl_strength_val    : Label  = $RootContainer/TabArea/TabContainer/PanelGrowth/Layout/RowStrength/LblStrengthVal
@onready var lbl_agility_val     : Label  = $RootContainer/TabArea/TabContainer/PanelGrowth/Layout/RowAgility/LblAgilityVal
@onready var lbl_intelligence_val: Label  = $RootContainer/TabArea/TabContainer/PanelGrowth/Layout/RowIntelligence/LblIntelligenceVal
@onready var lbl_vitality_val    : Label  = $RootContainer/TabArea/TabContainer/PanelGrowth/Layout/RowVitality/LblVitalityVal
@onready var lbl_perception_val  : Label  = $RootContainer/TabArea/TabContainer/PanelGrowth/Layout/RowPerception/LblPerceptionVal
@onready var lbl_endurance_val   : Label  = $RootContainer/TabArea/TabContainer/PanelGrowth/Layout/RowEndurance/LblEnduranceVal
@onready var lbl_derived         : Label  = $RootContainer/TabArea/TabContainer/PanelGrowth/Layout/LblDerived
@onready var btn_strength        : Button = $RootContainer/TabArea/TabContainer/PanelGrowth/Layout/RowStrength/BtnStrength
@onready var btn_agility         : Button = $RootContainer/TabArea/TabContainer/PanelGrowth/Layout/RowAgility/BtnAgility
@onready var btn_intelligence    : Button = $RootContainer/TabArea/TabContainer/PanelGrowth/Layout/RowIntelligence/BtnIntelligence
@onready var btn_vitality        : Button = $RootContainer/TabArea/TabContainer/PanelGrowth/Layout/RowVitality/BtnVitality
@onready var btn_perception      : Button = $RootContainer/TabArea/TabContainer/PanelGrowth/Layout/RowPerception/BtnPerception
@onready var btn_endurance       : Button = $RootContainer/TabArea/TabContainer/PanelGrowth/Layout/RowEndurance/BtnEndurance
@onready var lbl_attack_speed_val: Label  = $RootContainer/TabArea/TabContainer/PanelGrowth/Layout/RowAttackSpeed/LblAttackSpeedVal
@onready var btn_attack_speed    : Button = $RootContainer/TabArea/TabContainer/PanelGrowth/Layout/RowAttackSpeed/BtnAttackSpeed
@onready var lbl_mana_val        : Label  = $RootContainer/TabArea/TabContainer/PanelGrowth/Layout/RowMana/LblManaVal
@onready var btn_mana_stat       : Button = $RootContainer/TabArea/TabContainer/PanelGrowth/Layout/RowMana/BtnMana

@onready var btn_strength_minus     : Button = $RootContainer/TabArea/TabContainer/PanelGrowth/Layout/RowStrength/BtnStrengthMinus
@onready var btn_agility_minus      : Button = $RootContainer/TabArea/TabContainer/PanelGrowth/Layout/RowAgility/BtnAgilityMinus
@onready var btn_intelligence_minus : Button = $RootContainer/TabArea/TabContainer/PanelGrowth/Layout/RowIntelligence/BtnIntelligenceMinus
@onready var btn_vitality_minus     : Button = $RootContainer/TabArea/TabContainer/PanelGrowth/Layout/RowVitality/BtnVitalityMinus
@onready var btn_perception_minus   : Button = $RootContainer/TabArea/TabContainer/PanelGrowth/Layout/RowPerception/BtnPerceptionMinus
@onready var btn_endurance_minus    : Button = $RootContainer/TabArea/TabContainer/PanelGrowth/Layout/RowEndurance/BtnEnduranceMinus
@onready var btn_attack_speed_minus : Button = $RootContainer/TabArea/TabContainer/PanelGrowth/Layout/RowAttackSpeed/BtnAttackSpeedMinus
@onready var btn_mana_minus         : Button = $RootContainer/TabArea/TabContainer/PanelGrowth/Layout/RowMana/BtnManaMinus

# ── [장비] 탭 노드
@onready var lbl_equip_weapon      : Label = $RootContainer/TabArea/TabContainer/PanelEquip/Layout/RowWeapon/LblItem
@onready var lbl_equip_offhand     : Label = $RootContainer/TabArea/TabContainer/PanelEquip/Layout/RowOffhand/LblItem
@onready var lbl_equip_helmet      : Label = $RootContainer/TabArea/TabContainer/PanelEquip/Layout/RowHelmet/LblItem
@onready var lbl_equip_armor       : Label = $RootContainer/TabArea/TabContainer/PanelEquip/Layout/RowArmor/LblItem
@onready var lbl_equip_gloves      : Label = $RootContainer/TabArea/TabContainer/PanelEquip/Layout/RowGloves/LblItem
@onready var lbl_equip_boots       : Label = $RootContainer/TabArea/TabContainer/PanelEquip/Layout/RowBoots/LblItem
@onready var lbl_equip_necklace    : Label = $RootContainer/TabArea/TabContainer/PanelEquip/Layout/RowNecklace/LblItem
@onready var lbl_equip_ring1       : Label = $RootContainer/TabArea/TabContainer/PanelEquip/Layout/RowRing1/LblItem
@onready var lbl_equip_ring2       : Label = $RootContainer/TabArea/TabContainer/PanelEquip/Layout/RowRing2/LblItem
@onready var lbl_equip_transcendent: Label = $RootContainer/TabArea/TabContainer/PanelEquip/Layout/RowTranscendent/LblItem

# ── [환생] 탭 노드
@onready var lbl_cond_lv        : Label  = $RootContainer/TabArea/TabContainer/PanelRebirth/Layout/LblCondLv
@onready var lbl_rebirth_count  : Label  = $RootContainer/TabArea/TabContainer/PanelRebirth/Layout/LblRebirthCount
@onready var lbl_soul_stone     : Label  = $RootContainer/TabArea/TabContainer/PanelRebirth/Layout/LblSoulStone
@onready var lbl_rebirth_bonus  : Label  = $RootContainer/TabArea/TabContainer/PanelRebirth/Layout/LblRebirthBonus
@onready var btn_rebirth_exec   : Button = $RootContainer/TabArea/TabContainer/PanelRebirth/Layout/BtnRebirth

# ==========================================
# 상태 변수
# ==========================================
var is_ui_open: bool = false

# ==========================================
# 내장 콜백
# ==========================================

func _ready() -> void:
	btn_close.move_to_front()
	_close_ui()

func _process(_delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	# ESC 키 → 열려 있는 패널 닫기
	if event.is_action_pressed("ui_cancel") and is_ui_open:
		_close_ui()
		get_viewport().set_input_as_handled()

# ==========================================
# UI 열기 / 닫기 핵심 로직
# ==========================================

func _close_ui() -> void:
	is_ui_open = false
	tab_area.modulate.a = 0.0
	tab_area.process_mode = Node.PROCESS_MODE_DISABLED
	tab_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn_close.visible = false
	_update_button_states(-1)

func _open_ui(tab_index: int) -> void:
	is_ui_open = true
	tab_area.modulate.a = 1.0
	tab_area.process_mode = Node.PROCESS_MODE_INHERIT
	tab_area.mouse_filter = Control.MOUSE_FILTER_STOP
	btn_close.visible = true
	tab_container.current_tab = tab_index
	_update_button_states(tab_index)
	# 탭 진입 시 해당 패널 데이터 갱신
	_refresh_tab_content(tab_index)

# ==========================================
# 탭 전환 함수
# ==========================================

## 같은 탭 버튼을 다시 누르면 닫히고, 다른 탭이면 전환한다.
func _switch_tab(tab_index: int) -> void:
	if is_ui_open and tab_container.current_tab == tab_index:
		_close_ui()
	else:
		_open_ui(tab_index)

## 활성 탭 버튼을 disabled 처리하여 '선택됨' 상태를 표시한다.
func _update_button_states(active_tab: int) -> void:
	btn_growth.disabled    = (active_tab == TAB_GROWTH)
	btn_equip.disabled     = (active_tab == TAB_EQUIP)
	btn_relic.disabled     = (active_tab == TAB_RELIC)
	btn_spirit.disabled    = (active_tab == TAB_SPIRIT)
	btn_rebirth.disabled   = (active_tab == TAB_REBIRTH)
	btn_community.disabled = (active_tab == TAB_COMMUNITY)
	btn_move.disabled      = (active_tab == TAB_MOVE)

# ==========================================
# 탭별 데이터 갱신
# ==========================================

## 탭이 열릴 때마다 해당 패널의 Label을 PlayerData 최신값으로 갱신한다.
func _refresh_tab_content(tab_index: int) -> void:
	match tab_index:
		TAB_GROWTH:
			_refresh_growth()
		TAB_EQUIP:
			_refresh_equip()
		TAB_RELIC:
			pass  # TODO: 유물 파편 수량 연동
		TAB_SPIRIT:
			pass  # TODO: 보유 영수 목록 연동
		TAB_REBIRTH:
			_refresh_rebirth()
		TAB_COMMUNITY:
			pass  # TODO: 길드·우편 데이터 연동
		TAB_MOVE:
			_refresh_move()

## [성장] 탭 — 6대 스탯 값·파생 스탯 갱신, 포인트 없으면 + 버튼 비활성화
func _refresh_growth() -> void:
	var pd := PlayerData
	var no_points: bool = pd.stat_points <= 0

	lbl_stat_points.text      = "잔여 포인트: %d" % pd.stat_points
	lbl_strength_val.text     = str(pd.stat_strength)
	lbl_agility_val.text      = str(pd.stat_agility)
	lbl_intelligence_val.text = str(pd.stat_intelligence)
	lbl_vitality_val.text     = str(pd.stat_vitality)
	lbl_perception_val.text   = str(pd.stat_perception)
	lbl_endurance_val.text     = str(pd.stat_endurance)
	lbl_attack_speed_val.text  = str(pd.stat_attack_speed)
	lbl_mana_val.text          = str(pd.stat_mana)

	btn_strength.disabled     = no_points
	btn_agility.disabled      = no_points
	btn_intelligence.disabled = no_points
	btn_vitality.disabled     = no_points
	btn_perception.disabled   = no_points
	btn_endurance.disabled    = no_points
	btn_attack_speed.disabled = no_points
	btn_mana_stat.disabled    = no_points

	btn_strength_minus.disabled     = pd.stat_strength <= 0
	btn_agility_minus.disabled      = pd.stat_agility <= 0
	btn_intelligence_minus.disabled = pd.stat_intelligence <= 0
	btn_vitality_minus.disabled     = pd.stat_vitality <= 0
	btn_perception_minus.disabled   = pd.stat_perception <= 0
	btn_endurance_minus.disabled    = pd.stat_endurance <= 0
	btn_attack_speed_minus.disabled = pd.stat_attack_speed <= 0
	btn_mana_minus.disabled         = pd.stat_mana <= 0

	lbl_derived.text = "[ 파생 스탯 ]\n최대 HP: %d   최대 MP: %d   물리공격: %d   술법공격: %d\n방어력: %d   치명타율: %.1f%%   회피율: %.1f%%\nHP재생: %.1f/초   MP재생: %.1f/초   드랍률: +%.1f%%\n이동속도: %.0f   공격속도: x%.2f" % [
		pd.get_max_hp(), pd.get_max_mp(), pd.get_physical_attack(), pd.get_magic_attack(),
		pd.get_defense(), pd.get_crit_rate(), pd.get_evasion_rate(),
		pd.get_hp_regen(), pd.get_mp_regen(), pd.get_drop_rate_bonus(),
		pd.get_move_speed(), pd.get_attack_speed()
	]

## [장비] 탭 — PlayerData의 장착 장비를 슬롯 Label에 반영
func _refresh_equip() -> void:
	lbl_equip_weapon.text       = PlayerData.get_equip_display("weapon")
	lbl_equip_offhand.text      = PlayerData.get_equip_display("offhand")
	lbl_equip_helmet.text       = PlayerData.get_equip_display("helmet")
	lbl_equip_armor.text        = PlayerData.get_equip_display("armor")
	lbl_equip_gloves.text       = PlayerData.get_equip_display("gloves")
	lbl_equip_boots.text        = PlayerData.get_equip_display("boots")
	lbl_equip_necklace.text     = PlayerData.get_equip_display("necklace")
	lbl_equip_ring1.text        = PlayerData.get_equip_display("ring1")
	lbl_equip_ring2.text        = PlayerData.get_equip_display("ring2")
	lbl_equip_transcendent.text = PlayerData.get_equip_display("transcendent")

## [환생] 탭 — PlayerData의 환생 관련 수치를 Label에 반영
func _refresh_rebirth() -> void:
	# 환생 조건 ① 레벨 100 달성 여부
	var lv_ok := PlayerData.level >= 100
	lbl_cond_lv.text = "  ① 레벨 100 달성:  현재 Lv. %d  [ %s ]" % [
		PlayerData.level,
		"달성" if lv_ok else "미달성"
	]

	# 누적 스탯
	lbl_rebirth_count.text = "  환생 횟수: %d회  (최대 10회)" % PlayerData.rebirth_count
	lbl_soul_stone.text    = "  보유 영혼석: %d개" % PlayerData.soul_stone

	var exp_bonus := PlayerData.rebirth_count * 20  # 환생마다 +20%
	var stat_bonus := PlayerData.rebirth_count       # 환생마다 기본 스탯 +1 (임시)
	lbl_rebirth_bonus.text = "  경험치 보너스: +%d%%  |  기본 스탯 증가: +%d" % [exp_bonus, stat_bonus]

	# 환생 버튼 활성화 조건: Lv.100 + 유문 관문 클리어 (유문 클리어는 TODO)
	btn_rebirth_exec.disabled = not lv_ok
	btn_rebirth_exec.text = "환생 실행" if lv_ok else "환생 실행 (조건 미달성)"

# ==========================================
# 하단 버튼 시그널 핸들러
# ==========================================

# ==========================================
# 스탯 배분 버튼 시그널 핸들러
# ==========================================

func _allocate_stat(stat_name: String) -> void:
	if PlayerData.stat_points <= 0:
		return
	PlayerData.stat_points -= 1
	match stat_name:
		"strength":     PlayerData.stat_strength += 1
		"agility":      PlayerData.stat_agility += 1
		"intelligence": PlayerData.stat_intelligence += 1
		"vitality":     PlayerData.stat_vitality += 1
		"perception":   PlayerData.stat_perception += 1
		"endurance":    PlayerData.stat_endurance += 1
		"attack_speed": PlayerData.stat_attack_speed += 1
		"mana":         PlayerData.stat_mana += 1
	PlayerData.recalculate_vitals()
	_refresh_growth()

func _deallocate_stat(stat_name: String) -> void:
	match stat_name:
		"strength":
			if PlayerData.stat_strength <= 0: return
			PlayerData.stat_strength -= 1
		"agility":
			if PlayerData.stat_agility <= 0: return
			PlayerData.stat_agility -= 1
		"intelligence":
			if PlayerData.stat_intelligence <= 0: return
			PlayerData.stat_intelligence -= 1
		"vitality":
			if PlayerData.stat_vitality <= 0: return
			PlayerData.stat_vitality -= 1
		"perception":
			if PlayerData.stat_perception <= 0: return
			PlayerData.stat_perception -= 1
		"endurance":
			if PlayerData.stat_endurance <= 0: return
			PlayerData.stat_endurance -= 1
		"attack_speed":
			if PlayerData.stat_attack_speed <= 0: return
			PlayerData.stat_attack_speed -= 1
		"mana":
			if PlayerData.stat_mana <= 0: return
			PlayerData.stat_mana -= 1
	PlayerData.stat_points += 1
	PlayerData.recalculate_vitals()
	_refresh_growth()

func _on_btn_stat_strength_pressed()     -> void: _allocate_stat("strength")
func _on_btn_stat_agility_pressed()      -> void: _allocate_stat("agility")
func _on_btn_stat_intelligence_pressed() -> void: _allocate_stat("intelligence")
func _on_btn_stat_vitality_pressed()     -> void: _allocate_stat("vitality")
func _on_btn_stat_perception_pressed()   -> void: _allocate_stat("perception")
func _on_btn_stat_endurance_pressed()    -> void: _allocate_stat("endurance")
func _on_btn_stat_attack_speed_pressed() -> void: _allocate_stat("attack_speed")
func _on_btn_stat_mana_pressed()         -> void: _allocate_stat("mana")

func _on_btn_stat_strength_minus_pressed()     -> void: _deallocate_stat("strength")
func _on_btn_stat_agility_minus_pressed()      -> void: _deallocate_stat("agility")
func _on_btn_stat_intelligence_minus_pressed() -> void: _deallocate_stat("intelligence")
func _on_btn_stat_vitality_minus_pressed()     -> void: _deallocate_stat("vitality")
func _on_btn_stat_perception_minus_pressed()   -> void: _deallocate_stat("perception")
func _on_btn_stat_endurance_minus_pressed()    -> void: _deallocate_stat("endurance")
func _on_btn_stat_attack_speed_minus_pressed() -> void: _deallocate_stat("attack_speed")
func _on_btn_stat_mana_minus_pressed()         -> void: _deallocate_stat("mana")

# ==========================================
# 하단 버튼 시그널 핸들러
# ==========================================

func _on_btn_close_pressed()     -> void: _close_ui()

func _on_btn_growth_pressed()    -> void: _switch_tab(TAB_GROWTH)
func _on_btn_equip_pressed()     -> void: _switch_tab(TAB_EQUIP)
func _on_btn_relic_pressed()     -> void: _switch_tab(TAB_RELIC)
func _on_btn_spirit_pressed()    -> void: _switch_tab(TAB_SPIRIT)
func _on_btn_rebirth_pressed()   -> void: _switch_tab(TAB_REBIRTH)
func _on_btn_community_pressed() -> void: _switch_tab(TAB_COMMUNITY)
func _on_btn_move_pressed()      -> void: _switch_tab(TAB_MOVE)

# ==========================================
# 외부 공개 API
# ==========================================

## [이동] 탭 — 사냥터 목록을 동적으로 생성하고 이동 버튼을 배치한다.
func _refresh_move() -> void:
	lbl_current_zone.text = "현재 위치:  " + PlayerData.current_region

	# 기존 목록 초기화
	for child in zone_list.get_children():
		child.queue_free()

	for zone in ZONES:
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var lbl := Label.new()
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var unlocked : bool = PlayerData.level >= zone["min_lv"]
		lbl.text = "  %s   (권장 Lv.%d+)   %s" % [
			zone["name"], zone["min_lv"], zone["desc"]
		]
		if not unlocked:
			lbl.modulate = Color(0.5, 0.5, 0.5, 1.0)

		var btn := Button.new()
		btn.custom_minimum_size = Vector2(80, 0)
		var is_current : bool = (PlayerData.current_region == zone["name"])
		if is_current:
			btn.text = "현재 위치"
			btn.disabled = true
		elif not unlocked:
			btn.text = "미개방"
			btn.disabled = true
		else:
			btn.text = "이동"
			var zone_name : String = zone["name"]
			btn.pressed.connect(func(): _move_to_zone(zone_name))

		row.add_child(lbl)
		row.add_child(btn)
		zone_list.add_child(row)

func _move_to_zone(zone_name: String) -> void:
	PlayerData.current_region = zone_name
	_refresh_move()
	_update_background(zone_name)

func _update_background(zone_name: String) -> void:
	var bg : Sprite2D = get_node_or_null("/root/Main/Background")
	if not bg:
		return
	var path : String = ZONE_BACKGROUNDS.get(zone_name, "")
	if path == "":
		return
	var tex : Texture2D = load(path)
	if tex:
		bg.texture = tex
		var tex_size := tex.get_size()
		bg.scale = Vector2(1920.0 / tex_size.x, 1080.0 / tex_size.y)

## 다른 스크립트에서 특정 탭을 직접 열 때 사용
## 예) GameUI.open_tab(GameUI.TAB_REBIRTH)
func open_tab(tab_index: int) -> void:
	_open_ui(tab_index)
