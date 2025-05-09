@tool
extends Node

# Signals
signal tutorial_completed(tutorial_id)
signal tutorial_step_completed(step_id)

# Enums
enum HighlightShape {
	CIRCLE,
	RECTANGLE,
	NONE
}

# Variables
var current_tutorial: Dictionary = {}
var current_step_index: int = -1
var is_active: bool = false
@export var auto_start: bool = true
@export var tutorial_id: String = "welcome_tutorial"
@export var debug_mode: bool = false

# References
@onready var dialog_panel: PanelContainer = $DialogPanel
@onready var dialog_text: RichTextLabel = $DialogPanel/MarginContainer/VBoxContainer/DialogText
@onready var next_button: Button = $DialogPanel/MarginContainer/VBoxContainer/NextButton
@onready var highlight_mask: ColorRect = $HighlightMask
@onready var click_blocker: ColorRect = $ClickBlocker

func _ready():
	# Initialize UI
	dialog_panel.hide()
	highlight_mask.hide()
	click_blocker.hide()
	
	# Connect signals
	next_button.pressed.connect(_on_next_button_pressed)
	click_blocker.gui_input.connect(_on_click_blocker_gui_input)
	
	# Set up highlight mask
	highlight_mask.color = Color(1, 1, 1, 1)  # White for the mask
	click_blocker.color = Color(0, 0, 0, 0)  # Transparent
	
	# Auto-start tutorial if enabled
	if auto_start and not debug_mode:
		# Wait a frame to ensure everything is ready
		await get_tree().process_frame
		start_welcome_tutorial()

func _input(event: InputEvent) -> void:
	if not debug_mode or not is_active:
		return
		
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var click_pos = event.position
		_update_highlight_position(click_pos)
		_save_current_position(click_pos)

func _update_highlight_position(position: Vector2) -> void:
	if current_step_index < 0 or current_step_index >= current_tutorial.steps.size():
		return
		
	var step = current_tutorial.steps[current_step_index]
	var highlight = step.highlight
	
	match highlight.shape:
		HighlightShape.CIRCLE:
			highlight.position = position
			highlight_mask.material.set_shader_parameter("center", position)
		HighlightShape.RECTANGLE:
			highlight.position = position
			highlight_mask.material.set_shader_parameter("position", position)

func _save_current_position(position: Vector2) -> void:
	if current_step_index < 0 or current_step_index >= current_tutorial.steps.size():
		return
		
	var step = current_tutorial.steps[current_step_index]
	var highlight = step.highlight
	
	match highlight.shape:
		HighlightShape.CIRCLE:
			highlight.position = position
			print("Saved circle highlight position: ", position)
		HighlightShape.RECTANGLE:
			highlight.position = position
			print("Saved rectangle highlight position: ", position)

func _on_click_blocker_gui_input(event: InputEvent) -> void:
	if debug_mode:
		return
		
	if event is InputEventMouseButton and event.pressed:
		# Check if click is within the highlight mask area
		var mask_rect = highlight_mask.get_rect()
		if mask_rect.has_point(event.position):
			# Allow the click to pass through
			click_blocker.mouse_filter = Control.MOUSE_FILTER_IGNORE
			# Re-enable click blocking after a short delay
			await get_tree().create_timer(0.1).timeout
			click_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
		else:
			# Block the click
			get_viewport().set_input_as_handled()

func start_welcome_tutorial() -> void:
	print("FTUEManager: start_welcome_tutorial called")
	var file = FileAccess.open("res://tutorial_data.json", FileAccess.READ)
	if file:
		var data = file.get_as_text()
		var parsed = JSON.parse_string(data)
		if typeof(parsed) == TYPE_DICTIONARY:
			start_tutorial(parsed)
		else:
			push_error("Failed to parse tutorial_data.json")
		file.close()
	else:
		push_error("Could not open tutorial_data.json")

func start_tutorial(tutorial_data: Dictionary) -> void:
	print("FTUEManager: start_tutorial called, steps:", tutorial_data.steps.size() if tutorial_data.has('steps') else "NO STEPS")
	if is_active:
		push_warning("Tutorial already in progress")
		return
		
	current_tutorial = tutorial_data
	current_step_index = -1
	is_active = true
	
	# Show the first step
	_show_next_step()

func _show_next_step() -> void:
	print("FTUEManager: _show_next_step called, current_step_index:", current_step_index)
	current_step_index += 1

	if current_step_index >= current_tutorial.steps.size():
		current_step_index = 0  # Loop back to the first step

	var step = current_tutorial.steps[current_step_index]
	# Update dialog
	dialog_text.text = step.text
	var dialog_pos = step.dialog_position
	if typeof(dialog_pos) == TYPE_STRING:
		dialog_pos = _parse_vector2_string(dialog_pos)
	dialog_panel.position = dialog_pos
	# Set dialog size
	var dialog_size = Vector2(320, 120)
	if step.has("dialog_size"):
		dialog_size = step.dialog_size
		if typeof(dialog_size) == TYPE_STRING:
			dialog_size = _parse_vector2_string(dialog_size)
	dialog_panel.custom_minimum_size = dialog_size
	dialog_panel.show()

	# Update highlight
	_update_highlight(step.highlight)

	# Show click blocker
	click_blocker.show()

	# Emit step completed signal
	emit_signal("tutorial_step_completed", current_step_index)

func _update_highlight(highlight_data: Dictionary) -> void:
	print("FTUEManager: _update_highlight called with:", highlight_data)
	if highlight_data.has("position") and typeof(highlight_data.position) == TYPE_STRING:
		highlight_data.position = _parse_vector2_string(highlight_data.position)
	if highlight_data.has("size") and typeof(highlight_data.size) == TYPE_STRING:
		highlight_data.size = _parse_vector2_string(highlight_data.size)
	if highlight_data.shape == HighlightShape.NONE:
		highlight_mask.hide()
		click_blocker.hide()
		return
	
	highlight_mask.show()
	click_blocker.show()
	
	# Set up the highlight mask to cover the entire screen
	highlight_mask.size = get_viewport().get_visible_rect().size
	highlight_mask.position = Vector2.ZERO
	var shape = int(highlight_data.shape)
	match shape:
		HighlightShape.CIRCLE:
			print("Setting circle mask center:", highlight_data.position, "radius:", highlight_data.radius)
			highlight_mask.material = ShaderMaterial.new()
			highlight_mask.material.shader = load("res://shaders/circle_mask.gdshader")
			highlight_mask.material.set_shader_parameter("center", highlight_data.position)
			highlight_mask.material.set_shader_parameter("radius", highlight_data.radius)
		HighlightShape.RECTANGLE:
			print("Setting rect mask pos/size:", highlight_data.position, highlight_data.size)
			highlight_mask.material = ShaderMaterial.new()
			highlight_mask.material.shader = load("res://shaders/rectangle_mask.gdshader")
			highlight_mask.material.set_shader_parameter("position", highlight_data.position)
			highlight_mask.material.set_shader_parameter("size", highlight_data.size)

func _complete_tutorial() -> void:
	is_active = false
	dialog_panel.hide()
	highlight_mask.hide()
	click_blocker.hide()
	emit_signal("tutorial_completed", current_tutorial.id)

func _on_next_button_pressed() -> void:
	_show_next_step()

# Debug functions
func print_tutorial_data() -> void:
	print(JSON.stringify(current_tutorial, "  "))

func save_tutorial_data() -> void:
	var file = FileAccess.open("res://tutorial_data.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(current_tutorial, "  "))
	file.close()
	print("Tutorial data saved to tutorial_data.json")

# Example usage:
# var tutorial_data = {
#     "id": "building_tutorial",
#     "steps": [
#         {
#             "text": "Welcome to the game! Let's learn how to build structures.",
#             "dialog_position": Vector2(100, 100),
#             "highlight": {
#                 "shape": HighlightShape.CIRCLE,
#                 "position": Vector2(400, 300),
#                 "radius": 100
#             }
#         },
#         {
#             "text": "Click the building button to open the construction menu.",
#             "dialog_position": Vector2(500, 100),
#             "highlight": {
#                 "shape": HighlightShape.RECTANGLE,
#                 "position": Vector2(50, 50),
#                 "size": Vector2(100, 100)
#             }
#         }
#     ]
# }
# start_tutorial(tutorial_data) 

func _parse_vector2_string(vector_str: String) -> Vector2:
	var clean_str = vector_str.replace("(", "").replace(")", "")
	var parts = clean_str.split(",")
	if parts.size() == 2:
		return Vector2(float(parts[0]), float(parts[1]))
	return Vector2.ZERO 

	
func _unhandled_input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F5:
			print("Reloading FTUE tutorial_data.json")
			is_active = false
			current_step_index = -1
			start_welcome_tutorial()
			return
		elif event.keycode == KEY_RIGHT:
			if is_active:
				_show_next_step()
				return
		elif event.keycode == KEY_LEFT:
			if is_active:
				_show_previous_step()
				return

# Add a new function to go to the previous step and wrap around
func _show_previous_step() -> void:
	print("FTUEManager: _show_previous_step called, current_step_index:", current_step_index)
	current_step_index -= 1
	if current_step_index < 0:
		current_step_index = current_tutorial.steps.size() - 1  # Wrap to last step

	var step = current_tutorial.steps[current_step_index]
	# Update dialog
	dialog_text.text = step.text
	var dialog_pos = step.dialog_position
	if typeof(dialog_pos) == TYPE_STRING:
		dialog_pos = _parse_vector2_string(dialog_pos)
	dialog_panel.position = dialog_pos
	# Set dialog size
	var dialog_size = Vector2(320, 120)
	if step.has("dialog_size"):
		dialog_size = step.dialog_size
		if typeof(dialog_size) == TYPE_STRING:
			dialog_size = _parse_vector2_string(dialog_size)
	dialog_panel.custom_minimum_size = dialog_size
	dialog_panel.show()

	# Update highlight
	_update_highlight(step.highlight)

	# Show click blocker
	click_blocker.show()

	# Emit step completed signal
	emit_signal("tutorial_step_completed", current_step_index)
