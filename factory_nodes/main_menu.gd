extends Control

const GAME_SCENE_PATH = "res://factory_nodes/factory_game.tscn"
const SETTINGS_PATH = "user://nova_settings.cfg"

# 1. 메인 메뉴 패널 & 버튼
@onready var center_container: CenterContainer = $CenterContainer
@onready var new_game_btn: Button = $CenterContainer/MenuPanel/NewGameButton
@onready var load_game_btn: Button = $CenterContainer/MenuPanel/LoadGameButton
@onready var settings_btn: Button = $CenterContainer/MenuPanel/SettingsButton
@onready var credits_btn: Button = $CenterContainer/MenuPanel/CreditsButton
@onready var exit_btn: Button = $CenterContainer/MenuPanel/ExitButton

# 2. 환경설정 패널 & 오디오 슬라이더
@onready var settings_panel: Control = $SettingsPanel
@onready var master_slider: HSlider = $SettingsPanel/SettingsVBox/MasterVolumeSlider
@onready var music_slider: HSlider = $SettingsPanel/SettingsVBox/MusicVolumeSlider
@onready var sfx_slider: HSlider = $SettingsPanel/SettingsVBox/SFXVolumeSlider
@onready var settings_back_btn: Button = $SettingsPanel/SettingsVBox/SettingsBackButton

# 3. 제작진(Credits) 패널
@onready var credits_panel: Control = $CreditsPanel

func _ready() -> void:
	# 시작 시 팝업 패널 숨기기
	settings_panel.visible = false
	if credits_panel:
		credits_panel.visible = false
	
	# 저장된 볼륨 불러오기 및 슬라이더 동기화
	load_settings()
	
	# 메인 메뉴 버튼 시그널 연결
	new_game_btn.pressed.connect(_on_new_game_pressed)
	load_game_btn.pressed.connect(_on_load_game_pressed)
	settings_btn.pressed.connect(_on_settings_pressed)
	credits_btn.pressed.connect(_on_credits_pressed)
	exit_btn.pressed.connect(_on_exit_pressed)
	
	# 설정창 슬라이더 및 뒤로가기 버튼 연결
	master_slider.value_changed.connect(_on_master_changed)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	settings_back_btn.pressed.connect(_on_settings_back_pressed)

# --- 메인 메뉴 버튼 동작 ---
func _on_new_game_pressed() -> void:
	get_tree().change_scene_to_file(GAME_SCENE_PATH)

func _on_load_game_pressed() -> void:
	print("저장 시스템은 추후 연결")

func _on_settings_pressed() -> void:
	center_container.visible = false
	settings_panel.visible = true

func _on_credits_pressed() -> void:
	if credits_panel:
		center_container.visible = false
		credits_panel.visible = true

func _on_exit_pressed() -> void:
	get_tree().quit()

# --- 오디오 버스 볼륨 조절 & 저장 ---
func _on_master_changed(value: float) -> void:
	_set_bus_volume("Master", value)
	save_settings()

func _on_music_changed(value: float) -> void:
	_set_bus_volume("music", value)
	save_settings()

func _on_sfx_changed(value: float) -> void:
	_set_bus_volume("sfx", value)
	save_settings()

func _on_settings_back_pressed() -> void:
	settings_panel.visible = false
	center_container.visible = true

func _set_bus_volume(bus_name: String, value: float) -> void:
	var idx = AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		AudioServer.set_bus_mute(idx, value <= 0.001)
		AudioServer.set_bus_volume_linear(idx, maxf(value, 0.001))

func save_settings() -> void:
	var cfg = ConfigFile.new()
	cfg.set_value("audio", "master", master_slider.value)
	cfg.set_value("audio", "music", music_slider.value)
	cfg.set_value("audio", "sfx", sfx_slider.value)
	cfg.save(SETTINGS_PATH)

func load_settings() -> void:
	var cfg = ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		master_slider.value = cfg.get_value("audio", "master", 1.0)
		music_slider.value = cfg.get_value("audio", "music", 0.7)
		sfx_slider.value = cfg.get_value("audio", "sfx", 0.8)
	else:
		master_slider.value = 1.0
		music_slider.value = 0.7
		sfx_slider.value = 0.8
	
	_set_bus_volume("Master", master_slider.value)
	_set_bus_volume("music", music_slider.value)
	_set_bus_volume("sfx", sfx_slider.value)
