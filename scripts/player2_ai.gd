extends CharacterBody3D

# Movement parameters
const SPEED = 3.5
const BOUNDARY_LEFT = -12.0
const BOUNDARY_RIGHT = 12.0
const DIRECTION_CHANGE_TIME = 2.0  # Change direction every 2 seconds

# AI state
enum State { IDLE, MOVING_LEFT, MOVING_RIGHT }
var current_state = State.MOVING_LEFT
var direction_timer = 0.0

# Reference to Player 1
@onready var player1 = get_node("../Player1")

# Get the gravity from the project settings
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	# Start with random direction
	if randf() > 0.5:
		current_state = State.MOVING_RIGHT
	else:
		current_state = State.MOVING_LEFT

func _physics_process(delta):
	# Add gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Update direction timer
	direction_timer += delta
	
	# Simple AI behavior: move back and forth
	var input_dir = 0.0
	
	# Check boundaries
	if global_position.x <= BOUNDARY_LEFT:
		current_state = State.MOVING_RIGHT
		direction_timer = 0.0
	elif global_position.x >= BOUNDARY_RIGHT:
		current_state = State.MOVING_LEFT
		direction_timer = 0.0
	# Change direction based on timer
	elif direction_timer >= DIRECTION_CHANGE_TIME:
		if current_state == State.MOVING_LEFT:
			current_state = State.MOVING_RIGHT
		else:
			current_state = State.MOVING_LEFT
		direction_timer = 0.0
	
	# Apply movement based on state
	match current_state:
		State.MOVING_LEFT:
			input_dir = -1.0
		State.MOVING_RIGHT:
			input_dir = 1.0
		State.IDLE:
			input_dir = 0.0
	
	# Apply movement only on X axis
	if input_dir:
		velocity.x = input_dir * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	# Move the character
	move_and_slide()

