extends Control

# Tackle Box Dialog
# Supports "Everything is bait!" with Use and Release features

signal closed()

@onready var item_container: VBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/ItemContainer
@onready var lbl_current_bait: Label = $PanelContainer/MarginContainer/VBoxContainer/HeaderBox/LblCurrentBait
@onready var btn_close: Button = $PanelContainer/MarginContainer/VBoxContainer/HeaderBox/BtnClose
@onready var lbl_cahs: Label = $PanelContainer/MarginContainer/VBoxContainer/HeaderBox/LblCahs
@onready var btn_sell_all: Button = $PanelContainer/MarginContainer/VBoxContainer/HeaderBox/BtnSellAll

# Release Modal nodes
@onready var release_modal: Control = $ReleaseModal
@onready var lbl_modal_title: Label = $ReleaseModal/Panel/Margin/VBox/LblModalTitle
@onready var lbl_modal_count: Label = $ReleaseModal/Panel/Margin/VBox/LblModalCount
@onready var slider_amount: HSlider = $ReleaseModal/Panel/Margin/VBox/SliderAmount
@onready var btn_cancel_release: Button = $ReleaseModal/Panel/Margin/VBox/BtnRow/BtnCancelRelease
@onready var btn_confirm_release: Button = $ReleaseModal/Panel/Margin/VBox/BtnRow/BtnConfirmRelease

var _release_item_id: String = ""
var _release_max_qty: int = 1

func _ready() -> void:
	btn_close.pressed.connect(_on_close_pressed)
	btn_sell_all.pressed.connect(_on_sell_all_pressed)
	btn_cancel_release.pressed.connect(_close_release_modal)
	btn_confirm_release.pressed.connect(_confirm_release)
	slider_amount.value_changed.connect(_on_slider_amount_changed)
	
	release_modal.visible = false
	
	if GameManager:
		GameManager.inventory_updated.connect(refresh_items)
		GameManager.bait_changed.connect(func(_b): refresh_items())
		GameManager.cahs_changed.connect(func(_c): refresh_items())
	refresh_items()

func open() -> void:
	visible = true
	release_modal.visible = false
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
		
	var current_data = GameManager.get_equipped_bait_data()
	if current_data.is_empty():
		lbl_current_bait.text = "Equipped Bait: None"
	else:
		var qty = GameManager.inventory.get(GameManager.equipped_bait, 0)
		lbl_current_bait.text = "Equipped: %s %s (x%d)" % [
			current_data.get("icon_symbol", "🎣"),
			current_data.get("name", ""),
			qty
		]
	
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
		
	# Action buttons container (Sell + Use + Release)
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
	
	# 2. Use Button
	var btn_use = Button.new()
	btn_use.custom_minimum_size = Vector2(85, 40)
	if is_equipped:
		btn_use.text = "✓ Equipped"
		btn_use.disabled = true
	else:
		btn_use.text = "Use"
		btn_use.pressed.connect(func():
			GameManager.set_equipped_bait(item_id)
		)
	btn_box.add_child(btn_use)
	
	# 2. Release Button
	var btn_release = Button.new()
	btn_release.custom_minimum_size = Vector2(85, 40)
	btn_release.text = "Release"
	
	var release_style = StyleBoxFlat.new()
	release_style.bg_color = Color(0.32, 0.16, 0.16, 0.85)
	release_style.border_width_left = 1
	release_style.border_width_top = 1
	release_style.border_width_right = 1
	release_style.border_width_bottom = 1
	release_style.border_color = Color(0.75, 0.35, 0.35, 0.6)
	release_style.corner_radius_top_left = 8
	release_style.corner_radius_top_right = 8
	release_style.corner_radius_bottom_left = 8
	release_style.corner_radius_bottom_right = 8
	btn_release.add_theme_stylebox_override("normal", release_style)
	
	btn_release.pressed.connect(func():
		_on_release_clicked(item_id, data, amount)
	)
	btn_box.add_child(btn_release)
	
	return card

func _on_release_clicked(item_id: String, data: Dictionary, amount: int) -> void:
	if amount <= 1:
		# Directly release 1
		GameManager.remove_from_inventory(item_id, 1)
	else:
		# Trigger draggable slider modal
		_release_item_id = item_id
		_release_max_qty = amount
		lbl_modal_title.text = "Release %s" % data.get("name", "Item")
		slider_amount.min_value = 1.0
		slider_amount.max_value = float(amount)
		slider_amount.value = 1.0
		lbl_modal_count.text = "Amount to release: 1 / %d" % amount
		release_modal.visible = true
		release_modal.modulate.a = 0.0
		var tween = create_tween()
		tween.tween_property(release_modal, "modulate:a", 1.0, 0.15)

func _on_slider_amount_changed(val: float) -> void:
	lbl_modal_count.text = "Amount to release: %d / %d" % [int(val), _release_max_qty]

func _close_release_modal() -> void:
	release_modal.visible = false
	_release_item_id = ""

func _confirm_release() -> void:
	if not _release_item_id.is_empty():
		var count = int(slider_amount.value)
		GameManager.remove_from_inventory(_release_item_id, count)
	_close_release_modal()

func _on_sell_all_pressed() -> void:
	var earned = GameManager.sell_all_fish()
	if earned > 0 and btn_sell_all:
		btn_sell_all.text = "Sold! +%d 🪙" % earned
		await get_tree().create_timer(1.2).timeout
		if is_inside_tree() and btn_sell_all:
			btn_sell_all.text = "Sell All Fish 🪙"
