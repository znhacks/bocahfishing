extends Control

# Lobby Scene Controller
# Bocah Fishing - Everything is Bait!

@onready var lbl_equipped_icon: Label = $HUD/BottomBar/BaitInfoContainer/HBoxBait/LblBaitIcon
@onready var tex_equipped_icon: TextureRect = $HUD/BottomBar/BaitInfoContainer/HBoxBait/TexBaitIcon
@onready var lbl_equipped_name: Label = $HUD/BottomBar/BaitInfoContainer/HBoxBait/VBoxBaitInfo/LblBaitName
@onready var lbl_equipped_tags: Label = $HUD/BottomBar/BaitInfoContainer/HBoxBait/VBoxBaitInfo/LblBaitTags
@onready var btn_unequip: Button = $HUD/BottomBar/BaitInfoContainer/HBoxBait/BtnUnequip

@onready var btn_play: Button = $HUD/CenterButtons/BtnPlay
@onready var btn_tackle: Button = $HUD/BottomBar/BtnTackleBox
@onready var bait_card: PanelContainer = $HUD/BottomBar/BaitInfoContainer

@onready var btn_skills: Button = $HUD/TopRightBar/BtnSkills
@onready var btn_stats: Button = $HUD/TopRightBar/BtnStats
@onready var lbl_cahs: Label = $HUD/TopRightBar/CahsBadge/LblCahs
@onready var btn_almanac: Button = $HUD/TopRightBar/BtnAlmanac
@onready var btn_settings: Button = $HUD/TopRightBar/BtnSettings

@onready var tackle_dialog: Control = $DialogLayer/TackleBoxDialog
@onready var almanac_dialog: Control = $DialogLayer/AlmanacDialog
@onready var settings_dialog: Control = $DialogLayer/SettingsDialog
@onready var stats_dialog: Control = $DialogLayer/StatsDialog

@onready var title_container: Control = $HUD/TitleContainer
@onready var joe_char: TextureRect = $HUD/JoeChar
@onready var jia_char: TextureRect = $HUD/JiaChar
@onready var water_texture: TextureRect = $BackgroundLayer/WaterTexture
@onready var water_texture_fade: TextureRect = $BackgroundLayer/WaterTextureFade
@onready var bg_texture: TextureRect = $BackgroundLayer/BgTexture
@onready var bg_texture_fade: TextureRect = $BackgroundLayer/BgTextureFade
@onready var lbl_clock: Label = $HUD/TopLeftBar/ClockBadge/LblClock

var _time_passed: float = 0.0
var _title_base_y: float = 220.0
var _joe_base_y: float = 0.0
var _jia_base_y: float = 0.0

func _ready() -> void:
	if title_container:
		_title_base_y = title_container.position.y
	if joe_char:
		_joe_base_y = joe_char.position.y
	if jia_char:
		_jia_base_y = jia_char.position.y
	# GameManager signal connections
	if GameManager:
		GameManager.bait_changed.connect(_on_bait_changed)
		GameManager.inventory_updated.connect(_update_ui)
		GameManager.fish_unlocked.connect(func(_f): _update_ui())
		GameManager.cahs_changed.connect(func(_c): _update_ui())
		GameManager.character_changed.connect(func(_id): _update_ui())
		GameManager.time_updated.connect(_on_time_updated)
		GameManager.period_changed.connect(_on_period_changed)
		
		# Set initial background & animated water textures
		if bg_texture:
			bg_texture.texture = GameManager.get_current_period_bg_texture()
		if water_texture:
			water_texture.texture = GameManager.get_current_period_water_texture()
		if lbl_clock:
			lbl_clock.text = GameManager.get_time_formatted()
		
	# Button signals
	btn_play.pressed.connect(_on_play_pressed)
	btn_tackle.pressed.connect(_on_tackle_pressed)
	btn_skills.pressed.connect(_on_skills_pressed)
	btn_stats.pressed.connect(_on_stats_pressed)
	btn_almanac.pressed.connect(_on_almanac_pressed)
	btn_settings.pressed.connect(_on_settings_pressed)
	if btn_unequip:
		btn_unequip.pressed.connect(_on_unequip_pressed)
	
	# Clicking the bait card directly also opens the tackle box
	bait_card.gui_input.connect(_on_bait_card_gui_input)
	
	# Hide dialogs initially
	tackle_dialog.visible = false
	almanac_dialog.visible = false
	settings_dialog.visible = false
	stats_dialog.visible = false
	
	_update_ui()
	_start_intro_animation()

func _process(delta: float) -> void:
	_time_passed += delta
	# Subtle floating motion on title logo
	if title_container:
		title_container.position.y = _title_base_y + sin(_time_passed * 1.8) * 3.5
	# Gentle breathing animation on Play button
	if btn_play:
		var scale_factor = 1.0 + sin(_time_passed * 3.0) * 0.02
		btn_play.scale = Vector2(scale_factor, scale_factor)
	# Lively subtle idle sway on Joe and Jia
	if joe_char:
		joe_char.position.y = _joe_base_y + sin(_time_passed * 1.5) * 3.0
	if jia_char:
		jia_char.position.y = _jia_base_y + sin(_time_passed * 1.5 + 1.2) * 3.0

func _start_intro_animation() -> void:
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.4)

func _update_ui() -> void:
	if not GameManager:
		return
		
	if lbl_cahs:
		lbl_cahs.text = "%d Cahs" % GameManager.cahs
		
	var bait_data = GameManager.get_equipped_bait_data()
	var qty = GameManager.inventory.get(GameManager.equipped_bait, 0)
	var char_name = GameManager.character_db.get(GameManager.selected_character, {}).get("name", "None")
	
	if bait_data.is_empty() or qty <= 0:
		if tex_equipped_icon:
			tex_equipped_icon.texture = load("res://assets/textures/icons/icon_hook.svg")
			tex_equipped_icon.visible = true
		if lbl_equipped_icon:
			lbl_equipped_icon.visible = false
		lbl_equipped_name.text = "Bare Hook (No Bait)"
		lbl_equipped_tags.text = "Angler: %s • Higher chance of snagging junk" % char_name
		if btn_unequip:
			btn_unequip.visible = false
	else:
		var icon_tex_path = bait_data.get("icon_texture", "")
		if icon_tex_path != "" and ResourceLoader.exists(icon_tex_path) and tex_equipped_icon:
			tex_equipped_icon.texture = load(icon_tex_path)
			tex_equipped_icon.visible = true
			if lbl_equipped_icon:
				lbl_equipped_icon.visible = false
		else:
			if tex_equipped_icon:
				tex_equipped_icon.texture = load("res://assets/textures/icons/icon_hook.svg")
				tex_equipped_icon.visible = true
			if lbl_equipped_icon:
				lbl_equipped_icon.visible = false

		lbl_equipped_name.text = "%s (x%d)" % [bait_data.get("name", "Bait"), qty]
		
		var tags = bait_data.get("tags", [])
		if tags.is_empty() and bait_data.has("preferred_tags"):
			tags = bait_data.get("preferred_tags")
		lbl_equipped_tags.text = "Angler: %s • Traits: %s" % [char_name, ", ".join(tags).capitalize()]
		if btn_unequip:
			btn_unequip.visible = true

func _on_unequip_pressed() -> void:
	GameManager.unequip_bait()

func _on_bait_changed(_new_id: String) -> void:
	_update_ui()
	var tween = create_tween()
	lbl_equipped_icon.scale = Vector2(1.3, 1.3)
	tween.tween_property(lbl_equipped_icon, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_play_pressed() -> void:
	var tween = create_tween()
	tween.tween_property(btn_play, "scale", Vector2(0.92, 0.92), 0.08)
	tween.tween_property(btn_play, "scale", Vector2(1.0, 1.0), 0.08)
	await tween.finished
	GameManager.change_scene("res://scenes/gameplay/fishing_spot.tscn")

func _on_tackle_pressed() -> void:
	tackle_dialog.open()

func _on_skills_pressed() -> void:
	GameManager.change_scene("res://scenes/wardrobe/wardrobe.tscn")

func _on_bait_card_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		tackle_dialog.open()

func _on_almanac_pressed() -> void:
	almanac_dialog.open()

func _on_settings_pressed() -> void:
	settings_dialog.open()

func _on_stats_pressed() -> void:
	stats_dialog.open()

func _on_time_updated(_time: float) -> void:
	if lbl_clock:
		lbl_clock.text = GameManager.get_time_formatted()

func _on_period_changed(_new_period: String) -> void:
	var new_bg = GameManager.get_current_period_bg_texture()
	var new_water = GameManager.get_current_period_water_texture()
	
	var tween = create_tween().set_parallel()
	
	if bg_texture_fade and new_bg:
		bg_texture_fade.texture = new_bg
		bg_texture_fade.modulate.a = 0.0
		tween.tween_property(bg_texture_fade, "modulate:a", 1.0, 1.2)
	elif bg_texture and new_bg:
		bg_texture.texture = new_bg
		
	if water_texture_fade and new_water:
		water_texture_fade.texture = new_water
		water_texture_fade.modulate.a = 0.0
		tween.tween_property(water_texture_fade, "modulate:a", 1.0, 1.2)
	elif water_texture and new_water:
		water_texture.texture = new_water
		
	await tween.finished
	
	if bg_texture and new_bg:
		bg_texture.texture = new_bg
	if bg_texture_fade:
		bg_texture_fade.modulate.a = 0.0
		
	if water_texture and new_water:
		water_texture.texture = new_water
	if water_texture_fade:
		water_texture_fade.modulate.a = 0.0

