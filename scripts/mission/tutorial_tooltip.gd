extends Control

@export var message: String = "Tutorial tooltip"
@export var pointer_position: Vector2 = Vector2(125, 80)
@export var pointer_direction: String = "down"  # up, down, left, right

@onready var label = $Panel/MarginContainer/Label
@onready var pointer = $Pointer

func _ready():
	# Hide by default
	visible = false
	
	# Set the message
	if label:
		label.text = message
	
	# Position and orient the pointer
	if pointer:
		pointer.position = pointer_position
		
		match pointer_direction:
			"up":
				pointer.polygon = PackedVector2Array([Vector2(0, 15), Vector2(20, 15), Vector2(10, 0)])
			"down":
				pointer.polygon = PackedVector2Array([Vector2(0, 0), Vector2(20, 0), Vector2(10, 15)])
			"left":
				pointer.polygon = PackedVector2Array([Vector2(15, 0), Vector2(15, 20), Vector2(0, 10)])
			"right":
				pointer.polygon = PackedVector2Array([Vector2(0, 0), Vector2(0, 20), Vector2(15, 10)])

func show_tooltip():
	visible = true

func hide_tooltip():
	visible = false
