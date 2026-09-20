extends Control

# Catch Dialog
# Shows caught fish and gives the option to [Keep] or immediately [Hook as Bait!]
signal dialog_closed(action: String, fish_data: Dictionary)

@onready var lbl_header: Label = $PanelContainer/Margin/VBox/LblHeader
@onready var lbl_icon: Label = $PanelContainer/Margin/VBox/CenterIcon/LblIcon
@onready var texture_icon: TextureRect = $PanelContainer/Margin/VBox/CenterIcon/TextureIcon
@onready var lbl_name: Label = $PanelContainer/Margin/VBox/LblName
@onready var lbl_rarity: Label = $PanelContainer/Margin/VBox/LblRarity
@onready var lbl_weight: Label = $PanelContainer/Margin/VBox/LblWeight
@onready var lbl_desc: Label = $PanelContainer/Margin/VBox/LblDesc
@onready var btn_keep: Button = $PanelContainer/Margin/VBox/BtnBox/BtnKeep
@onready var btn_hook: Button = $PanelContainer/Margin/VBox/BtnBox/BtnHook

var current_fish: Dictionary = {}

func _ready() -> void:
	btn_keep.pressed.connect(_on_keep_pressed)
	btn_hook.pressed.connect(_on_hook_pressed)

func show_catch(fish_data: Dictionary) -> void:
	current_fish = fish_data
	var is_fish = (fish_data.get("category", "fish") == "fish")
	var tier = fish_data.get("tier", 1)
	var tier_name = GameManager.TIER_NAMES.get(tier, "Common")
	var tier_color = GameManager.TIER_COLORS.get(tier, Color.WHITE)
	
	if is_fish:
		lbl_header.text = "✨ FISH CAUGHT! ✨"
		var size_range = fish_data.get("size_range", [10.0, 20.0])
		var weight = randf_range(size_range[0], size_range[1])
		var price = fish_data.get("price_cahs", 0)
		lbl_weight.text = "Weight: %.1f kg • Value: 🪙 %d Cahs" % [weight, price]
	else:
		lbl_header.text = "📦 LAKE DEBRIS HOOKED! 📦"
		lbl_weight.text = "Lake Junk • Can be used as Bait!"
	
	var icon_tex_path = fish_data.get("icon_texture", "")
	if icon_tex_path != "" and ResourceLoader.exists(icon_tex_path):
		texture_icon.texture = load(icon_tex_path)
		texture_icon.visible = true
		lbl_icon.visible = false
	else:
		texture_icon.visible = false
		lbl_icon.visible = true
		lbl_icon.text = fish_data.get("icon_symbol", "🐟")

	lbl_name.text = fish_data.get("name", "Fish")
	lbl_name.modulate = tier_color
	
	lbl_rarity.text = "[ %s ]" % tier_name.to_upper()
	lbl_rarity.modulate = tier_color
	
	lbl_desc.text = fish_data.get("desc", "")
	
	visible = true
	modulate.a = 0.0
	scale = Vector2(0.85, 0.85)
	var tween = create_tween().set_parallel()
	tween.tween_property(self, "modulate:a", 1.0, 0.18)
	tween.tween_property(self, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Icon bounce
	var active_icon: Control = lbl_icon
	if texture_icon.visible:
		active_icon = texture_icon
	var icon_tween = create_tween()
	active_icon.scale = Vector2(1.35, 1.35)
	icon_tween.tween_property(active_icon, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func _close(action: String) -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	await tween.finished
	visible = false
	dialog_closed.emit(action, current_fish)

func _on_keep_pressed() -> void:
	var fish_id = current_fish.get("id", "")
	if not fish_id.is_empty():
		GameManager.add_to_inventory(fish_id, 1)
	_close("keep")

const FONT_OUTFIT = preload("res://assets/fonts/Outfit-Bold.ttf")

func _on_hook_pressed() -> void:
	var fish_id = current_fish.get("id", "")
	if fish_id.is_empty():
		_close("keep")
		return
		
	if GameManager.is_highest_tier_fish(fish_id):
		_show_high_tier_warning(current_fish, func():
			GameManager.add_to_inventory(fish_id, 1)
			GameManager.set_equipped_bait(fish_id)
			_close("hook_as_bait")
		)
		return
		
	GameManager.add_to_inventory(fish_id, 1)
	GameManager.set_equipped_bait(fish_id)
	_close("hook_as_bait")

func _show_high_tier_warning(fish_data: Dictionary, on_confirm: Callable) -> void:
	var old_modal = get_node_or_null("HighTierWarningModal")
	if old_modal:
		old_modal.queue_free()
		
	var fish_name = fish_data.get("name", "Rare Fish")
	var tier = fish_data.get("tier", 5)
	var tier_name = GameManager.TIER_NAMES.get(tier, "Legendary")
	var price = fish_data.get("price_cahs", 10)
	var icon_sym = fish_data.get("icon_symbol", "🐟")
	var icon_tex_path = fish_data.get("icon_texture", "")
	
	var modal = Control.new()
	modal.name = "HighTierWarningModal"
	modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.72)
	modal.add_child(dim)
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(500, 320)
	panel.anchors_preset = Control.PRESET_CENTER
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -250.0
	panel.offset_top = -160.0
	panel.offset_right = 250.0
	panel.offset_bottom = 160.0
	panel.pivot_offset = Vector2(250, 160)
	
	var p_style = StyleBoxFlat.new()
	p_style.bg_color = Color(0.08, 0.11, 0.16, 0.98)
	p_style.border_width_left = 3
	p_style.border_width_top = 3
	p_style.border_width_right = 3
	p_style.border_width_bottom = 3
	p_style.border_color = Color(1.0, 0.82, 0.2, 0.95)
	p_style.corner_radius_top_left = 16
	p_style.corner_radius_top_right = 16
	p_style.corner_radius_bottom_left = 16
	p_style.corner_radius_bottom_right = 16
	p_style.shadow_size = 14
	p_style.shadow_offset = Vector2(0, 6)
	p_style.shadow_color = Color(0, 0, 0, 0.6)
	panel.add_theme_stylebox_override("panel", p_style)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)
	
	var lbl_title = Label.new()
	lbl_title.text = "⚠️ PERINGATAN UMPAN LANGKA! ⚠️"
	lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_title.add_theme_font_override("font", FONT_OUTFIT)
	lbl_title.add_theme_font_size_override("font_size", 19)
	lbl_title.add_theme_color_override("font_color", Color(1.0, 0.84, 0.25))
	vbox.add_child(lbl_title)
	
	var sep1 = HSeparator.new()
	vbox.add_child(sep1)
	
	# Fish preview box
	var p_fish = PanelContainer.new()
	var fish_box_style = StyleBoxFlat.new()
	fish_box_style.bg_color = Color(0.05, 0.07, 0.1, 0.85)
	fish_box_style.border_width_left = 1
	fish_box_style.border_width_top = 1
	fish_box_style.border_width_right = 1
	fish_box_style.border_width_bottom = 1
	fish_box_style.border_color = Color(1.0, 0.82, 0.2, 0.5)
	fish_box_style.corner_radius_top_left = 10
	fish_box_style.corner_radius_top_right = 10
	fish_box_style.corner_radius_bottom_left = 10
	fish_box_style.corner_radius_bottom_right = 10
	fish_box_style.content_margin_left = 14
	fish_box_style.content_margin_right = 14
	fish_box_style.content_margin_top = 8
	fish_box_style.content_margin_bottom = 8
	p_fish.add_theme_stylebox_override("panel", fish_box_style)
	
	var fish_hbox = HBoxContainer.new()
	fish_hbox.add_theme_constant_override("separation", 14)
	
	if icon_tex_path != "" and ResourceLoader.exists(icon_tex_path):
		var tex = TextureRect.new()
		tex.texture = load(icon_tex_path)
		tex.custom_minimum_size = Vector2(48, 48)
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		fish_hbox.add_child(tex)
	else:
		var lbl_ico = Label.new()
		lbl_ico.text = icon_sym
		lbl_ico.add_theme_font_size_override("font_size", 34)
		fish_hbox.add_child(lbl_ico)
		
	var fish_vbox = VBoxContainer.new()
	fish_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var lbl_fname = Label.new()
	lbl_fname.text = fish_name
	lbl_fname.add_theme_font_override("font", FONT_OUTFIT)
	lbl_fname.add_theme_font_size_override("font_size", 17)
	lbl_fname.add_theme_color_override("font_color", Color(1.0, 0.88, 0.3))
	fish_vbox.add_child(lbl_fname)
	
	var lbl_ftier = Label.new()
	lbl_ftier.text = "[ %s ] • Nilai Jual: 🪙 %d Cahs" % [tier_name.to_upper(), price]
	lbl_ftier.add_theme_font_size_override("font_size", 12)
	lbl_ftier.add_theme_color_override("font_color", Color(0.75, 0.88, 0.95))
	fish_vbox.add_child(lbl_ftier)
	
	fish_hbox.add_child(fish_vbox)
	p_fish.add_child(fish_hbox)
	vbox.add_child(p_fish)
	
	# Warning description
	var lbl_msg = Label.new()
	lbl_msg.text = "Ikan ini adalah ikan tier tertinggi (Legendary) yang bernilai sangat tinggi! Jika dipasang sebagai umpan, ikan ini akan TERPAKAI dan HILANG dari tas saat memancing.\n\nApakah kamu yakin ingin menggunakannya sebagai umpan?"
	lbl_msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_msg.add_theme_font_size_override("font_size", 13)
	lbl_msg.add_theme_color_override("font_color", Color(0.9, 0.92, 0.95, 0.92))
	vbox.add_child(lbl_msg)
	
	var sep2 = HSeparator.new()
	vbox.add_child(sep2)
	
	# Button box
	var hbox_btns = HBoxContainer.new()
	hbox_btns.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_btns.add_theme_constant_override("separation", 16)
	
	var btn_cancel = Button.new()
	btn_cancel.text = "✕ Batal"
	btn_cancel.custom_minimum_size = Vector2(130, 42)
	btn_cancel.add_theme_font_override("font", FONT_OUTFIT)
	var cancel_style = StyleBoxFlat.new()
	cancel_style.bg_color = Color(0.18, 0.24, 0.33, 0.95)
	cancel_style.border_width_left = 1
	cancel_style.border_width_top = 1
	cancel_style.border_width_right = 1
	cancel_style.border_width_bottom = 1
	cancel_style.border_color = Color(0.45, 0.6, 0.75, 0.8)
	cancel_style.corner_radius_top_left = 10
	cancel_style.corner_radius_top_right = 10
	cancel_style.corner_radius_bottom_left = 10
	cancel_style.corner_radius_bottom_right = 10
	btn_cancel.add_theme_stylebox_override("normal", cancel_style)
	
	var btn_confirm = Button.new()
	btn_confirm.text = "🪝 Tetap Pasang Umpan"
	btn_confirm.custom_minimum_size = Vector2(185, 42)
	btn_confirm.add_theme_font_override("font", FONT_OUTFIT)
	var confirm_style = StyleBoxFlat.new()
	confirm_style.bg_color = Color(0.72, 0.32, 0.1, 0.98)
	confirm_style.border_width_left = 2
	confirm_style.border_width_top = 2
	confirm_style.border_width_right = 2
	confirm_style.border_width_bottom = 2
	confirm_style.border_color = Color(1.0, 0.82, 0.25, 0.95)
	confirm_style.corner_radius_top_left = 10
	confirm_style.corner_radius_top_right = 10
	confirm_style.corner_radius_bottom_left = 10
	confirm_style.corner_radius_bottom_right = 10
	btn_confirm.add_theme_stylebox_override("normal", confirm_style)
	
	hbox_btns.add_child(btn_cancel)
	hbox_btns.add_child(btn_confirm)
	vbox.add_child(hbox_btns)
	
	modal.add_child(panel)
	add_child(modal)
	
	btn_cancel.pressed.connect(func():
		var tw = create_tween().set_parallel()
		tw.tween_property(modal, "modulate:a", 0.0, 0.12)
		tw.tween_property(panel, "scale", Vector2(0.9, 0.9), 0.12)
		await tw.finished
		modal.queue_free()
	)
	
	btn_confirm.pressed.connect(func():
		var tw = create_tween().set_parallel()
		tw.tween_property(modal, "modulate:a", 0.0, 0.12)
		tw.tween_property(panel, "scale", Vector2(0.9, 0.9), 0.12)
		await tw.finished
		modal.queue_free()
		on_confirm.call()
	)
	
	modal.modulate.a = 0.0
	panel.scale = Vector2(0.9, 0.9)
	var tween = create_tween().set_parallel()
	tween.tween_property(modal, "modulate:a", 1.0, 0.18)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
