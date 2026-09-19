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

func _create_item_card(item_id: String, data: Dictionary, amount: int) -> PanelContainer:
	var card = PanelContainer.new()
	var is_equipped = (item_id == GameManager.equipped_bait)
	
	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	
	if is_equipped:
		style.bg_color = Color(0.18, 0.45, 0.3, 0.9)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = Color(0.4, 0.9, 0.5)
	else:
		style.bg_color = Color(0.15, 0.2, 0.25, 0.85)
		
	card.add_theme_stylebox_override("panel", style)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	card.add_child(hbox)
	
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
	name_lbl.add_theme_font_size_override("font_size", 18)
	title_box.add_child(name_lbl)
	
	var qty_lbl = Label.new()
	qty_lbl.text = "x%d" % amount
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
			GameManager.set_equipped_bait(item_id)
		)
	btn_box.add_child(btn_use)
	
	return card

func _on_sell_all_pressed() -> void:
	var earned = GameManager.sell_all_fish()
	if earned > 0 and btn_sell_all:
		btn_sell_all.text = "Sold! +%d 🪙" % earned
		await get_tree().create_timer(1.2).timeout
		if is_inside_tree() and btn_sell_all:
			btn_sell_all.text = "Sell All Fish 🪙"
