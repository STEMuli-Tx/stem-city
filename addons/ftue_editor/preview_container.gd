@tool
extends Control

const FTUEManager = preload("res://scripts/ftue_manager.gd")

var step_data := {}

signal action_button_pressed

@onready var action_button: Button = $ActionButton

func _parse_vector2_string(vector_str: String) -> Vector2:
	# Remove parentheses and split by comma
	var clean_str = vector_str.replace("(", "").replace(")", "")
	var parts = clean_str.split(",")
	if parts.size() == 2:
		return Vector2(float(parts[0]), float(parts[1]))
	return Vector2.ZERO

func set_step_data(data):
	print("Preview container received data: ", data)
	step_data = data
	queue_redraw()
	# Show and update the action button
	action_button.show()
	var is_last_step = false
	if step_data.has("is_last_step"):
		is_last_step = step_data.is_last_step
	action_button.text = "Close" if is_last_step else "Next"
	if action_button.pressed.is_connected(_on_action_button_pressed):
		action_button.pressed.disconnect(_on_action_button_pressed)
	action_button.pressed.connect(_on_action_button_pressed)

func _on_action_button_pressed():
	emit_signal("action_button_pressed")

func _ready():
	action_button.hide()

func _wrap_text(text: String, font: Font, max_width: float) -> Array:
	var lines = []
	var current_line = ""
	for word in text.split(" "):
		var test_line = current_line + ("" if current_line == "" else " ") + word
		if font.get_string_size(test_line).x > max_width and current_line != "":
			lines.append(current_line)
			current_line = word
		else:
			current_line = test_line
	if current_line != "":
		lines.append(current_line)
	return lines

func _draw():
	print("Drawing preview with data: ", step_data)
	# Draw semi-transparent black overlay over the whole preview area
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.6), true)

	if not step_data or not step_data.has("highlight"):
		print("No highlight data found")
		return
	var highlight = step_data.highlight
	print("Highlight data: ", highlight)
	
	# Convert position and size from strings if needed
	var highlight_pos = highlight.position
	if typeof(highlight_pos) == TYPE_STRING:
		highlight_pos = _parse_vector2_string(highlight_pos)
	print("Highlight position: ", highlight_pos)
	
	# Convert shape to integer
	var shape = int(highlight.shape)
	print("Shape value: ", shape)
	
	# Draw highlight (yellow) on top
	match shape:
		FTUEManager.HighlightShape.RECTANGLE:
			var highlight_size = highlight.size
			if typeof(highlight_size) == TYPE_STRING:
				highlight_size = _parse_vector2_string(highlight_size)
			print("Drawing rectangle at ", highlight_pos, " with size ", highlight_size)
			draw_rect(Rect2(highlight_pos, highlight_size), Color(1, 1, 0, 0.3), true)
		FTUEManager.HighlightShape.CIRCLE:
			print("Drawing circle at ", highlight_pos, " with radius ", highlight.radius)
			draw_circle(highlight_pos, highlight.radius, Color(1, 1, 0, 0.3))

	var font = get_theme_font("font")
	var pos = step_data.dialog_position
	if typeof(pos) == TYPE_STRING:
		pos = _parse_vector2_string(pos)
	var y_offset = 0

	# --- Dialog Backdrop ---
	var dialog_size = Vector2(320, 120)
	if step_data.has("dialog_size"):
		dialog_size = step_data.dialog_size
		if typeof(dialog_size) == TYPE_STRING:
			dialog_size = _parse_vector2_string(dialog_size)
	var dialog_width = dialog_size.x
	var dialog_height = dialog_size.y
	var backdrop_pos = pos
	var backdrop_rect = Rect2(backdrop_pos, Vector2(dialog_width, dialog_height))
	draw_rect(backdrop_rect, Color(1, 1, 1, 0.92), true)

	var content_x = backdrop_pos.x
	var content_y = backdrop_pos.y
	var padding_top = 12
	var padding_sides = 12
	var spacing = 8

	# Title at the top
	if step_data.has("title") and step_data.title != "" and font:
		var title_size = font.get_string_size(step_data.title)
		var title_pos = Vector2(content_x + (dialog_width - title_size.x) / 2, content_y + padding_top)
		draw_string(font, title_pos, step_data.title, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1, 0.9, 0.2))
		content_y += padding_top + 24  # Move y below title
	else:
		content_y += padding_top

	# Text under the title
	if step_data.has("text") and font:
		var max_text_width = dialog_width - 2 * padding_sides
		var text = step_data.text
		var text_lines = _wrap_text(text, font, max_text_width)
		var text_y = content_y + spacing
		for line in text_lines:
			var line_size = font.get_string_size(line)
			var text_pos = Vector2(content_x + (dialog_width - line_size.x) / 2, text_y)
			draw_string(font, text_pos, line, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0,0,0))
			text_y += line_size.y
		content_y = text_y + 8

	# Center the button horizontally in the backdrop, near the bottom
	if is_instance_valid(action_button):
		action_button.position = backdrop_pos + Vector2((dialog_width - action_button.size.x) / 2, dialog_height - action_button.size.y - 12)
	# Draw image if present
	if step_data.has("image") and step_data.image != "":
		var tex = load(step_data.image)
		if tex and tex is Texture2D:
			var img_size = tex.get_size()
			var img_pos = pos + Vector2((dialog_width - img_size.x) / 2, y_offset)
			draw_texture(tex, img_pos)
			y_offset += img_size.y + 8  # Add some spacing