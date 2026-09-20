extends Control

# Tackle Box Dialog
# Supports "Everything is bait!" with Use, Unequip, and Sell Fish features

signal closed()

@onready var item_container: VBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/ItemContainer
@onready var btn_close: Button = $PanelContainer/MarginContainer/VBoxContainer/HeaderBox/BtnClose
@onready var lbl_cahs: Label = $PanelContainer/MarginContainer/VBoxContainer/HeaderBox/LblCahs
@onready var btn_sell_all: Button = $PanelContainer/MarginContainer/VBoxContainer/HeaderBox/BtnSellAll

func _ready() -> void:
	btn_close.pressed.connect(_on_close_pressed)
	btn_sell_all.pressed.connect(_on_sell_all_pressed)
	
	if GameManager:
		GameManager.inventory_updated.connect(refresh_items)
		GameManager.bait_changed.connect(func(_b): refresh_items())
		GameManager.cahs_changed.connect(func(_c): refresh_items())
	refresh_items()

func open() -> void:
	visible = true
	refresh_items()
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.18)

func close() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	await tween.finished
	visible = false
	closed.emit()

func _on_close_pressed() -> void:
	close()

func refresh_items() -> void:
	if not is_inside_tree() or not item_container:
		return
		
	if lbl_cahs:
		lbl_cahs.text = "🪙 %d Cahs" % GameManager.cahs
	
	for child in item_container.get_children():
		child.queue_free()
		
	var inv = GameManager.inventory
	if inv.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "Your pockets are empty! Search the ground for bait."
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.modulate = Color(0.75, 0.8, 0.85)
		item_container.add_child(empty_lbl)
		
		var btn_dig = Button.new()
		btn_dig.text = "🪱 Dig for Earthworm (+1)"
		btn_dig.custom_minimum_size = Vector2(220, 44)
		btn_dig.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn_dig.pressed.connect(func():
			GameManager.add_to_inventory("bait_worm", 1)
			GameManager.set_equipped_bait("bait_worm")
		)
		item_container.add_child(btn_dig)
		return

	for item_id in inv.keys():
		var amount: int = inv[item_id]
		if amount <= 0:
			continue
			
		var data = GameManager.get_item_data(item_id)
		if data.is_empty():
			continue
			
		var card = _create_item_card(item_id, data, amount)
		item_container.add_child(card)

const FONT_OUTFIT = preload("res://assets/fonts/Outfit-Bold.ttf")

func _create_item_card(item_id: String, data: Dictionary, amount: int) -> PanelContainer:
	var card = PanelContainer.new()
	var is_equipped = (item_id == GameManager.equipped_bait)
	
	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 2)
	style.shadow_color = Color(0, 0, 0, 0.3)
	
	if is_equipped:
		style.bg_color = Color(0.18, 0.48, 0.32, 0.95)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = Color(0.45, 0.95, 0.6)
	else:
		style.bg_color = Color(0.12, 0.17, 0.22, 0.9)
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
		style.border_color = Color(0.28, 0.38, 0.48, 0.6)
		
	card.add_theme_stylebox_override("panel", style)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	card.add_child(hbox)
	
	var icon_tex_path = data.get("icon_texture", "")
	if icon_tex_path != "" and ResourceLoader.exists(icon_tex_path):
		var tex_rect = TextureRect.new()
		tex_rect.custom_minimum_size = Vector2(48, 48)
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.texture = load(icon_tex_path)
		hbox.add_child(tex_rect)
	else:
		var icon_lbl = Label.new()
		icon_lbl.text = data.get("icon_symbol", "📦")
		icon_lbl.add_theme_font_size_override("font_size", 32)
		icon_lbl.custom_minimum_size = Vector2(48, 48)
		icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hbox.add_child(icon_lbl)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)
	
	var title_box = HBoxContainer.new()
	var name_lbl = Label.new()
	name_lbl.text = data.get("name", "Item")
	name_lbl.add_theme_font_override("font", FONT_OUTFIT)
	name_lbl.add_theme_font_size_override("font_size", 18)
	title_box.add_child(name_lbl)
	
	var qty_lbl = Label.new()
	qty_lbl.text = "x%d" % amount
	qty_lbl.add_theme_font_override("font", FONT_OUTFIT)
	qty_lbl.modulate = Color(0.8, 0.9, 1.0, 0.8)
	title_box.add_child(qty_lbl)
	
	if data.get("category") == "fish":
		var fish_tag = Label.new()
		fish_tag.text = "[Fish as Bait!]"
		fish_tag.modulate = Color(1.0, 0.8, 0.3)
		fish_tag.add_theme_font_size_override("font_size", 12)
		title_box.add_child(fish_tag)
		
		var price = data.get("price_cahs", 0)
		if price > 0:
			var price_tag = Label.new()
			price_tag.text = "• 🪙 %d Cahs each" % price
			price_tag.modulate = Color(1.0, 0.88, 0.35, 0.95)
			price_tag.add_theme_font_size_override("font_size", 12)
			title_box.add_child(price_tag)
		
	vbox.add_child(title_box)
	
	var desc_lbl = Label.new()
	desc_lbl.text = data.get("desc", "")
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.modulate = Color(0.85, 0.85, 0.85, 0.8)
	desc_lbl.add_theme_font_size_override("font_size", 13)
	vbox.add_child(desc_lbl)
	
	var tags = data.get("tags", [])
	if tags.is_empty() and data.has("preferred_tags"):
		tags = data.get("preferred_tags")
	if not tags.is_empty():
		var tag_str = "Traits: " + ", ".join(tags).capitalize()
		var tag_lbl = Label.new()
		tag_lbl.text = tag_str
		tag_lbl.modulate = Color(0.5, 0.9, 0.9, 0.9)
		tag_lbl.add_theme_font_size_override("font_size", 12)
		vbox.add_child(tag_lbl)
		
	# Action buttons container (Sell + Use / Unequip)
	var btn_box = HBoxContainer.new()
	btn_box.add_theme_constant_override("separation", 10)
	btn_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(btn_box)
	
	# 1. Sell Button (Only for fish with price > 0, junk cannot be sold)
	if data.get("category") == "fish" and data.get("price_cahs", 0) > 0:
		var btn_sell = Button.new()
		btn_sell.custom_minimum_size = Vector2(85, 40)
		btn_sell.text = "Sell 🪙"
		var sell_style = StyleBoxFlat.new()
		sell_style.bg_color = Color(0.16, 0.38, 0.24, 0.88)
		sell_style.border_width_left = 1
		sell_style.border_width_top = 1
		sell_style.border_width_right = 1
		sell_style.border_width_bottom = 1
		sell_style.border_color = Color(0.35, 0.85, 0.5, 0.6)
		sell_style.corner_radius_top_left = 8
		sell_style.corner_radius_top_right = 8
		sell_style.corner_radius_bottom_left = 8
		sell_style.corner_radius_bottom_right = 8
		btn_sell.add_theme_stylebox_override("normal", sell_style)
		btn_sell.pressed.connect(func():
			GameManager.sell_fish(item_id, 1)
		)
		btn_box.add_child(btn_sell)
	
	# 2. Use / Unequip Button
	var btn_use = Button.new()
	btn_use.custom_minimum_size = Vector2(95, 40)
	if is_equipped:
		btn_use.text = "Unequip"
		var unequip_style = StyleBoxFlat.new()
		unequip_style.bg_color = Color(0.28, 0.32, 0.4, 0.9)
		unequip_style.border_width_left = 1
		unequip_style.border_width_top = 1
		unequip_style.border_width_right = 1
		unequip_style.border_width_bottom = 1
		unequip_style.border_color = Color(0.6, 0.75, 0.9, 0.8)
		unequip_style.corner_radius_top_left = 8
		unequip_style.corner_radius_top_right = 8
		unequip_style.corner_radius_bottom_left = 8
		unequip_style.corner_radius_bottom_right = 8
		btn_use.add_theme_stylebox_override("normal", unequip_style)
		btn_use.pressed.connect(func():
			GameManager.unequip_bait()
		)
	else:
		btn_use.text = "Use"
		btn_use.pressed.connect(func():
			if GameManager.is_highest_tier_fish(item_id):
				_show_high_tier_warning(item_id, func():
					GameManager.set_equipped_bait(item_id)
				)
			else:
				GameManager.set_equipped_bait(item_id)
		)
	btn_box.add_child(btn_use)
	
	return card

func _show_high_tier_warning(item_id: String, on_confirm: Callable) -> void:
	var old_modal = get_node_or_null("HighTierWarningModal")
	if old_modal:
		old_modal.queue_free()
		
	var data = GameManager.get_item_data(item_id)
	var fish_name = data.get("name", "Rare Fish")
	var tier = data.get("tier", 5)
	var tier_name = GameManager.TIER_NAMES.get(tier, "Legendary")
	var price = data.get("price_cahs", 10)
	var icon_sym = data.get("icon_symbol", "🐟")
	var icon_tex_path = data.get("icon_texture", "")
	
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
	lbl_title.text = "⚠️ RARE BAIT WARNING! ⚠️"
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
	lbl_ftier.text = "[ %s ] • Value: 🪙 %d Cahs" % [tier_name.to_upper(), price]
	lbl_ftier.add_theme_font_size_override("font_size", 12)
	lbl_ftier.add_theme_color_override("font_color", Color(0.75, 0.88, 0.95))
	fish_vbox.add_child(lbl_ftier)
	
	fish_hbox.add_child(fish_vbox)
	p_fish.add_child(fish_hbox)
	vbox.add_child(p_fish)
	
	# Warning description
	var lbl_msg = Label.new()
	lbl_msg.text = "This is a highest-tier fish (Legendary) with exceptional value!\nIf used as bait, this rare catch will be CONSUMED and PERMANENTLY LOST upon casting/hooking a fish.\n\nAre you sure you want to equip it as bait?"
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
	btn_cancel.text = "✕ Cancel"
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
	btn_confirm.text = "🪝 Equip as Bait"
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

func _on_sell_all_pressed() -> void:
	var earned = GameManager.sell_all_fish()
	if earned > 0 and btn_sell_all:
		btn_sell_all.text = "Sold! +%d 🪙" % earned
		await get_tree().create_timer(1.2).timeout
		if is_inside_tree() and btn_sell_all:
			btn_sell_all.text = "Sell All Fish 🪙"
