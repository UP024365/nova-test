
extends Control

# =====================================
# NOVA INDUSTRIA - MAIN MENU
# =====================================

@export var game_scene_path: String = "res://factory_game.tscn"

# 오디오 버스 이름
var master_bus := "Master"
var music_bus := "Music"
var sfx_bus := "SFX"

# =====================================
# 초기 설정
# =====================================

func _ready():
	$SettingsPanel.hide()
	$CreditsPanel.hide()

	$SettingsPanel/SettingsVBox/MasterVolumeSlider.value = 80
	$SettingsPanel/SettingsVBox/MusicVolumeSlider.value = 80
	$SettingsPanel/SettingsVBox/SFXVolumeSlider.value = 80

	# 버튼 연결
	$CenterContainer/MenuPanel/NewGameButton.pressed.connect(_on_new_game)
	$CenterContainer/MenuPanel/LoadGameButton.pressed.connect(_on_load_game)
	$CenterContainer/MenuPanel/SettingsButton.pressed.connect(_on_settings)
	$CenterContainer/MenuPanel/CreditsButton.pressed.connect(_on_credits)
	$CenterContainer/MenuPanel/ExitButton.pressed.connect(_on_exit)

	$SettingsPanel/SettingsVBox/SettingsBackButton.pressed.connect(_on_settings_back)
	
	# 슬라이더 연결
	$SettingsPanel/SettingsVBox/MasterVolumeSlider.value_changed.connect(_on_master_volume_changed)
	$SettingsPanel/SettingsVBox/MusicVolumeSlider.value_changed.connect(_on_music_volume_changed)
	$SettingsPanel/SettingsVBox/SFXVolumeSlider.value_changed.connect(_on_sfx_volume_changed)

	# 처음에는 메인 메뉴 표시
	$CenterContainer.show()


# =====================================
# 새 게임
# =====================================

func _on_new_game():
	if ResourceLoader.exists(game_scene_path):
		get_tree().change_scene_to_file(game_scene_path)
	else:
		print("게임 씬을 찾을 수 없습니다: ", game_scene_path)


# =====================================
# 불러오기
# =====================================

func _on_load_game():
	print("불러오기 기능은 다음 단계에서 구현합니다.")


# =====================================
# 환경설정
# =====================================

func _on_settings():
	$CenterContainer.hide()
	$SettingsPanel.show()


func _on_settings_back():
	$SettingsPanel.hide()
	$CenterContainer.show()


# =====================================
# 제작진
# =====================================

func _on_credits():
	$CenterContainer.hide()
	$CreditsPanel.show()


# =====================================
# 오디오 설정
# =====================================

func _on_master_volume_changed(value: float):
	_set_bus_volume(master_bus, value)


func _on_music_volume_changed(value: float):
	_set_bus_volume(music_bus, value)


func _on_sfx_volume_changed(value: float):
	_set_bus_volume(sfx_bus, value)


func _set_bus_volume(bus_name: String, value: float):
	var bus_index = AudioServer.get_bus_index(bus_name)

	if bus_index == -1:
		print("오디오 버스를 찾을 수 없습니다: ", bus_name)
		return

	AudioServer.set_bus_mute(bus_index, value <= 0)

	if value > 0:
		AudioServer.set_bus_volume_db(
			bus_index,
			linear_to_db(value / 100.0)
		)


# =====================================
# 게임 종료
# =====================================

func _on_exit():
	get_tree().quit()
