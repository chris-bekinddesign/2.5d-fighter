extends CharacterBody3D

# Movement parameters
const SPEED = 5.0
const JUMP_VELOCITY = 8.0

# Get the gravity from the project settings to be synced with RigidBody nodes
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Track previous frame's W key state to detect just-pressed
var was_w_pressed = false

func _physics_process(delta):
	# Add gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Handle jump (W or Space) - check if key was just pressed this frame
	var w_just_pressed = Input.is_key_pressed(KEY_W) and not was_w_pressed
	was_w_pressed = Input.is_key_pressed(KEY_W)
	
	if is_on_floor() and (Input.is_action_just_pressed("ui_accept") or w_just_pressed):
		velocity.y = JUMP_VELOCITY
	
	# Get input direction (A/D for left/right)
	var input_dir = 0.0
	if Input.is_key_pressed(KEY_A):
		input_dir = -1.0
	elif Input.is_key_pressed(KEY_D):
		input_dir = 1.0
	
	# Apply movement only on X axis
	if input_dir:
		velocity.x = input_dir * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	# Move the character
	move_and_slide()

