extends ColorRect

signal continue_pressed

@onready var content_label = $CenterContainer/PanelContainer/VBoxContainer/MarginContainer/ContentLabel
@onready var continue_button = $CenterContainer/PanelContainer/VBoxContainer/ButtonContainer/ContinueButton

func _ready():
	# Hide by default
	visible = false
	
	# Connect button signal
	if continue_button and not continue_button.pressed.is_connected(self._on_continue_button_pressed):
		continue_button.pressed.connect(_on_continue_button_pressed)

func show_modal(message: String):
	# Set the message
	if content_label:
		content_label.text = message
	
	# Show the modal
	visible = true

func hide_modal():
	visible = false

func _on_continue_button_pressed():
	emit_signal("continue_pressed")
	hide_modal()