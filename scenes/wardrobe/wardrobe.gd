extends Control

# Angler Wardrobe & Skills Scene
# Allows browsing full-body character portraits with < and > carousel navigation

@onready var btn_back: Button = $TopBar/Margin/HBox/BtnBack
@onready var lbl_cahs: Label = $TopBar/Margin/HBox/CahsBadge/LblCahs

@onready var btn_prev: Button = $StageArea/BtnPrev
@onready var btn_next: Button = $StageArea/BtnNext

# Center showcase nodes
@onready var char_texture: TextureRect = $StageArea/CenterShowcase/Stage/CharTexture
@onready var silhouette_box: Control = $StageArea/CenterShowcase/Stage/SilhouetteBox
@onready var dots_container: HBoxContainer = $StageArea/CenterShowcase/DotsContainer

# Detail card nodes
@onready var lbl_name: Label = $StageArea/DetailPanel/Margin/VBox/HeaderBox/LblName
@onready var lbl_title: Label = $StageArea/DetailPanel/Margin/VBox/HeaderBox/LblTitle
@onready var lbl_lore: Label = $StageArea/DetailPanel/Margin/VBox/LblLore
@onready var traits_container: VBoxContainer = $StageArea/DetailPanel/Margin/VBox/TraitsScroll/TraitsContainer
@onready var lbl_cost_status: Label = $StageArea/DetailPanel/Margin/VBox/ActionBox/LblCostStatus
@onready var btn_action: Button = $StageArea/DetailPanel/Margin/VBox/ActionBox/BtnAction
@onready var lbl_insufficient: Label = $StageArea/DetailPanel/Margin/VBox/ActionBox/LblInsufficient

var characters: Array[Dictionary] = [
	{
		"id": "none",
		"name": "None",
		"title": "Default Rookie Angler",
		"cost": 0,
		"texture": null,
		"lore": "Standard fishing gear. Pure patience and raw angling instinct with no extra buffs or penalties.",
		"buffs": ["0% All Stats (Standard Gameplay)"],
		"debuffs": []
	},
	{
		"id": "jia",
		"name": "Jia",
		"title": "Swift Breeze Angler",
		"cost": 50,
		"texture": preload("res://assets/player/Jia.png"),
		"lore": "Keen reflexes and sharp eyes. With an expanded rod sweet spot, fish bite eagerly before they even know they're hooked.",
		"buffs": [
			"+25% Safe Bar (Massive catch zone)",
			"+25% Lure Speed (Fish bite significantly faster)"
		],
		"debuffs": [
			"-20% Line Resilience (Escapes fast if outside bar)"
		]
	},
	{
		"id": "joe",
		"name": "Joe",
		"title": "Steadfast Hooded Angler",
		"cost": 50,
		"texture": preload("res://assets/player/Joe.png"),
		"lore": "Calm, focused, and unyielding. Even the most furious fighters can't shake his steady tension on the line.",
		"buffs": [
			"+15% Lure Speed (Faster bites)",
			"+35% Line Resilience (Tough line, steady control)"
		],
		"debuffs": [
			"-20% Safe Bar (Requires sharper precision)"
		]
	}
]

var current_index: int = 0
var _animating: bool = false

func _ready() -> void:
	btn_back.pressed.connect(_on_back_pressed)
	btn_prev.pressed.connect(_on_prev_pressed)
	btn_next.pressed.connect(_on_next_pressed)
	btn_action.pressed.connect(_on_action_pressed)
	
	if GameManager:
		GameManager.cahs_changed.connect(func(_c): _update_cahs())
		GameManager.character_changed.connect(func(_id): _display_character(current_index, false))
		
		# Find index of currently selected character
		for i in range(characters.size()):
			if characters[i]["id"] == GameManager.selected_character:
				current_index = i
				break
				
	_update_cahs()
	_create_dots()
	_display_character(current_index, false)
	
	# Entry fade in
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.25)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_left"):
		_on_prev_pressed()
	elif event.is_action_pressed("ui_right"):
		_on_next_pressed()
	elif event.is_action_pressed("ui_cancel"):
		_on_back_pressed()

func _update_cahs() -> void:
	if lbl_cahs and GameManager:
		lbl_cahs.text = "🪙 %d Cahs" % GameManager.cahs

func _create_dots() -> void:
	for child in dots_container.get_children():
		child.queue_free()
	for i in range(characters.size()):
		var dot = Label.new()
		dot.text = "●"
		dot.add_theme_font_size_override("font_size", 20)
		dot.custom_minimum_size = Vector2(24, 24)
		dot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dots_container.add_child(dot)

func _update_dots() -> void:
	var children = dots_container.get_children()
	for i in range(children.size()):
		var dot = children[i] as Label
		if dot:
			if i == current_index:
				dot.modulate = Color(1.0, 0.85, 0.35, 1.0) # Active golden
				dot.scale = Vector2(1.25, 1.25)
			else:
				dot.modulate = Color(0.4, 0.5, 0.6, 0.6) # Dim inactive
				dot.scale = Vector2.ONE

func _on_prev_pressed() -> void:
	if _animating:
		return
	var new_idx = current_index - 1
	if new_idx < 0:
		new_idx = characters.size() - 1
	_slide_to_character(new_idx, -1)

func _on_next_pressed() -> void:
	if _animating:
		return
	var new_idx = current_index + 1
	if new_idx >= characters.size():
		new_idx = 0
	_slide_to_character(new_idx, 1)

func _slide_to_character(new_idx: int, direction: int) -> void:
	_animating = true
	var char_stage = $StageArea/CenterShowcase/Stage
	var start_x = char_stage.position.x
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(char_stage, "position:x", start_x - (40 * direction), 0.12)
	tween.tween_property(char_stage, "modulate:a", 0.0, 0.12)
	await tween.finished
	
	current_index = new_idx
	_display_character(current_index, false)
	char_stage.position.x = start_x + (40 * direction)
	
	var tween_in = create_tween().set_parallel(true)
	tween_in.tween_property(char_stage, "position:x", start_x, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween_in.tween_property(char_stage, "modulate:a", 1.0, 0.16)
	await tween_in.finished
	_animating = false

func _display_character(idx: int, _with_anim: bool = false) -> void:
	if idx < 0 or idx >= characters.size():
		return
	var char_data = characters[idx]
	var char_id: String = char_data["id"]
	var is_selected: bool = (GameManager.selected_character == char_id)
	var is_unlocked: bool = GameManager.is_character_unlocked(char_id)
	
	# Character sprite / silhouette
	if char_data["texture"] != null:
		char_texture.texture = char_data["texture"]
		char_texture.visible = true
		silhouette_box.visible = false
	else:
		char_texture.visible = false
		silhouette_box.visible = true
		
	# Text details
	lbl_name.text = char_data["name"]
	lbl_title.text = char_data["title"]
	lbl_lore.text = char_data["lore"]
	
	# Traits list
	for child in traits_container.get_children():
		child.queue_free()
		
	# Buffs
	for buff in char_data.get("buffs", []):
		var buff_box = PanelContainer.new()
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.12, 0.35, 0.22, 0.85)
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
		style.border_color = Color(0.35, 0.85, 0.5, 0.7)
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_left = 8
		style.corner_radius_bottom_right = 8
		style.content_margin_left = 12
		style.content_margin_top = 6
		style.content_margin_right = 12
		style.content_margin_bottom = 6
		buff_box.add_theme_stylebox_override("panel", style)
		
		var buff_lbl = Label.new()
		buff_lbl.text = "🟩 " + buff
		buff_lbl.add_theme_font_size_override("font_size", 13)
		buff_lbl.add_theme_color_override("font_color", Color(0.85, 1.0, 0.9))
		buff_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		buff_box.add_child(buff_lbl)
		traits_container.add_child(buff_box)
		
	# Debuffs
	for debuff in char_data.get("debuffs", []):
		var debuff_box = PanelContainer.new()
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.35, 0.16, 0.16, 0.85)
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
		style.border_color = Color(0.85, 0.4, 0.4, 0.7)
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_left = 8
		style.corner_radius_bottom_right = 8
		style.content_margin_left = 12
		style.content_margin_top = 6
		style.content_margin_right = 12
		style.content_margin_bottom = 6
		debuff_box.add_theme_stylebox_override("panel", style)
		
		var debuff_lbl = Label.new()
		debuff_lbl.text = "🟥 " + debuff
		debuff_lbl.add_theme_font_size_override("font_size", 13)
		debuff_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.85))
		debuff_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		debuff_box.add_child(debuff_lbl)
		traits_container.add_child(debuff_box)
		
	# Action button state
	lbl_insufficient.visible = false
	if is_selected:
		lbl_cost_status.text = "Active Angler"
		lbl_cost_status.modulate = Color(0.4, 0.95, 0.6)
		btn_action.text = "✓ SELECTED"
		btn_action.disabled = true
		_set_btn_style(btn_action, Color(0.15, 0.4, 0.25, 0.8), Color(0.4, 0.9, 0.5, 0.9))
	elif is_unlocked:
		lbl_cost_status.text = "Unlocked"
		lbl_cost_status.modulate = Color(0.5, 0.8, 1.0)
		btn_action.text = "SELECT ANGLER"
		btn_action.disabled = false
		_set_btn_style(btn_action, Color(0.18, 0.55, 0.35, 0.95), Color(0.5, 0.95, 0.65, 0.9))
	else:
		var cost: int = char_data.get("cost", 50)
		lbl_cost_status.text = "Price: 🪙 %d Cahs" % cost
		lbl_cost_status.modulate = Color(1.0, 0.88, 0.35)
		btn_action.text = "UNLOCK (50 CAHS 🪙)"
		if GameManager.cahs >= cost:
			btn_action.disabled = false
			_set_btn_style(btn_action, Color(0.5, 0.38, 0.12, 0.95), Color(1.0, 0.85, 0.3, 0.95))
		else:
			btn_action.disabled = true
			lbl_insufficient.visible = true
			lbl_insufficient.text = "Need %d more Cahs" % (cost - GameManager.cahs)
			_set_btn_style(btn_action, Color(0.22, 0.22, 0.25, 0.7), Color(0.4, 0.4, 0.45, 0.5))
			
	_update_dots()

func _set_btn_style(btn: Button, bg_col: Color, border_col: Color) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = bg_col
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = border_col
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("disabled", style)

func _on_action_pressed() -> void:
	var char_data = characters[current_index]
	var char_id: String = char_data["id"]
	var is_unlocked: bool = GameManager.is_character_unlocked(char_id)
	
	if is_unlocked:
		GameManager.select_character(char_id)
		_display_character(current_index, true)
	else:
		if GameManager.buy_character(char_id):
			_update_cahs()
			_display_character(current_index, true)
			# Celebration pulse
			var tween = create_tween()
			btn_action.scale = Vector2(1.15, 1.15)
			tween.tween_property(btn_action, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)

func _on_back_pressed() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	await tween.finished
	get_tree().change_scene_to_file("res://scenes/lobby/lobby.tscn")
