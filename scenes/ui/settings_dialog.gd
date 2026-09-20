extends Control

# Dialog Pengaturan (Settings)
signal closed()

@onready var slider_master: HSlider = $PanelContainer/MarginContainer/VBoxContainer/GridContainer/SliderMaster
@onready var slider_music: HSlider = $PanelContainer/MarginContainer/VBoxContainer/GridContainer/SliderMusic
@onready var slider_sfx: HSlider = $PanelContainer/MarginContainer/VBoxContainer/GridContainer/SliderSFX
@onready var check_fullscreen: CheckButton = $PanelContainer/MarginContainer/VBoxContainer/HBoxFullscreen/CheckFullscreen
@onready var btn_close: Button = $PanelContainer/MarginContainer/VBoxContainer/HeaderBox/BtnClose
@onready var btn_reset: Button = $PanelContainer/MarginContainer/VBoxContainer/HBoxReset/BtnReset

@onready var confirm_modal: Control = $ConfirmModal
@onready var btn_cancel_reset: Button = $ConfirmModal/Panel/Margin/VBox/BtnRow/BtnCancelReset
@onready var btn_confirm_reset: Button = $ConfirmModal/Panel/Margin/VBox/BtnRow/BtnConfirmReset

func _ready() -> void:
	btn_close.pressed.connect(_on_close_pressed)
	if btn_reset:
		btn_reset.pressed.connect(_on_reset_pressed)
	if btn_cancel_reset:
		btn_cancel_reset.pressed.connect(_on_cancel_reset_pressed)
	if btn_confirm_reset:
		btn_confirm_reset.pressed.connect(_on_confirm_reset_pressed)
	if confirm_modal:
		confirm_modal.visible = false
	
	# Setup slider default values from GameManager
	if GameManager:
		slider_master.value = GameManager.master_volume
		slider_music.value = GameManager.music_volume
		slider_sfx.value = GameManager.sfx_volume
		
	slider_master.value_changed.connect(_on_master_changed)
	slider_music.value_changed.connect(_on_music_changed)
	slider_sfx.value_changed.connect(_on_sfx_changed)
	check_fullscreen.toggled.connect(_on_fullscreen_toggled)
	
	# Deteksi status fullscreen saat ini
	check_fullscreen.button_pressed = (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)

func open() -> void:
	if GameManager:
		slider_master.value = GameManager.master_volume
		slider_music.value = GameManager.music_volume
		slider_sfx.value = GameManager.sfx_volume
	visible = true
	if confirm_modal:
		confirm_modal.visible = false
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.18)

func close() -> void:
	if GameManager:
		GameManager.save_game()
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	await tween.finished
	visible = false
	if confirm_modal:
		confirm_modal.visible = false
	closed.emit()

func _on_close_pressed() -> void:
	close()

func _on_master_changed(val: float) -> void:
	_set_bus_volume("Master", val)
	if GameManager:
		GameManager.master_volume = val

func _on_music_changed(val: float) -> void:
	_set_bus_volume("Music", val)
	if GameManager:
		GameManager.music_volume = val

func _on_sfx_changed(val: float) -> void:
	_set_bus_volume("SFX", val)
	if GameManager:
		GameManager.sfx_volume = val

func _set_bus_volume(bus_name: String, val: float) -> void:
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx >= 0:
		if val <= 0.001:
			AudioServer.set_bus_mute(bus_idx, true)
		else:
			AudioServer.set_bus_mute(bus_idx, false)
			# Mengubah linear 0.0 - 1.0 ke dB (-40 dB s/d 0 dB)
			AudioServer.set_bus_volume_db(bus_idx, linear_to_db(val))

func _on_fullscreen_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_reset_pressed() -> void:
	if confirm_modal:
		confirm_modal.visible = true
		confirm_modal.modulate.a = 0.0
		var tween = create_tween()
		tween.tween_property(confirm_modal, "modulate:a", 1.0, 0.15)

func _on_cancel_reset_pressed() -> void:
	if confirm_modal:
		confirm_modal.visible = false

func _on_confirm_reset_pressed() -> void:
	if confirm_modal:
		confirm_modal.visible = false
	if GameManager:
		GameManager.reset_game_data()
	if btn_reset:
		btn_reset.text = "Progress Reset!"
		await get_tree().create_timer(1.5).timeout
		if is_inside_tree() and btn_reset:
			btn_reset.text = "Reset All Progress"
