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

# Projectile shooting
const PROJECTILE_COOLDOWN = 0.5
var projectile_cooldown_timer = 0.0
var projectile_scene = preload("res://scenes/Projectile.tscn")
const SHOOT_PROBABILITY = 0.01  # 1% chance per frame when conditions met

# Damage points system
var damage_points = 0
const MAX_POINTS = 100
const PROJECTILE_COST = 50
const POINTS_PER_HIT = 15
const POINTS_ON_DAMAGE = 5  # Points when taking damage

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
	
	# Update projectile cooldown
	if projectile_cooldown_timer > 0:
		projectile_cooldown_timer -= delta
	
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
	
	# AI shooting - shoot randomly when on ground, cooldown ready, and has enough points
	if is_on_floor() and projectile_cooldown_timer <= 0 and damage_points >= PROJECTILE_COST:
		if randf() < SHOOT_PROBABILITY:
			shoot_projectile()
			projectile_cooldown_timer = PROJECTILE_COOLDOWN
	
	# Check for attack hits (if Player 2 had attacks, would check here)
	# For now, Player 2 doesn't have attacks, so no hit detection needed

func shoot_projectile():
	if not projectile_scene:
		return
	
	# Create projectile instance
	var projectile = projectile_scene.instantiate()
	
	# Get the scene root to add projectile to
	var scene_root = get_tree().current_scene
	if not scene_root:
		return
	
	# Determine direction based on AI state (facing Player 1)
	var facing_right = (current_state == State.MOVING_RIGHT)
	if player1:
		# Face towards Player 1
		facing_right = (player1.global_position.x > global_position.x)
	
	var direction = Vector3(1, 0, 0) if facing_right else Vector3(-1, 0, 0)
	
	# Set projectile position (slightly in front of player)
	var spawn_offset = direction * 1.5
	projectile.global_position = global_position + spawn_offset + Vector3(0, 1, 0)  # Slightly above player
	
	# Set projectile direction
	projectile.direction = direction
	
	# Deduct points
	damage_points -= PROJECTILE_COST
	damage_points = max(0, damage_points)  # Ensure points don't go negative
	
	# Add to scene
	scene_root.add_child(projectile)

func earn_points(amount: int):
	damage_points += amount
	damage_points = min(damage_points, MAX_POINTS)  # Cap at maximum

