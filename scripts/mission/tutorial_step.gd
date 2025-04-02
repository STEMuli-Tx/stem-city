extends Resource
class_name TutorialStep

enum StepType {
	MODAL,        # A modal dialog with a message and a continue button
	TOOLTIP,      # A tooltip pointing to a specific UI element
	HIGHLIGHT,    # Highlight a UI element without a tooltip
	OBJECTIVE     # Require the player to complete an objective
}

@export var type: StepType = StepType.MODAL
@export var message: String = ""  # The message to display in the modal or tooltip
@export var target_node_path: String = ""  # The path to the node to point to (for tooltips and highlights)
@export var position_offset: Vector2 = Vector2.ZERO  # Offset for tooltip position
@export var wait_for_input: bool = true  # Whether to wait for user input to continue
@export var objective_type: int = -1  # For objective steps, the type of objective to complete
@export var required_count: int = 1  # For objective steps, how many times the objective must be completed