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

# Reference to AnimatedSprite3D node
@onready var animated_sprite = $AnimatedSprite3D

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

# Attack system
var is_attacking = false
var attack_timer = 0.0
const ATTACK_TIMEOUT = 1.0  # Fallback timeout for attack animations
var current_attack_type = ""  # Track "Punch" or "Kick"
const ATTACK_RANGE = 3.0  # Range to initiate attack
const ATTACK_PROBABILITY = 0.02  # 2% chance per frame when conditions met

# Damage state system
var is_damaged = false
var damage_timer = 0.0
const DAMAGE_DURATION = 0.5  # How long damage state lasts

func _ready():
	# Start with random direction
	if randf() > 0.5:
		current_state = State.MOVING_RIGHT
	else:
		current_state = State.MOVING_LEFT

func _physics_process(delta):
	# Update attack timer
	if is_attacking:
		attack_timer -= delta
		if attack_timer <= 0:
			# Force reset attack state if timeout reached
			is_attacking = false
			current_attack_type = ""
	
	# Update damage timer
	if is_damaged:
		damage_timer -= delta
		if damage_timer <= 0:
			# Damage state ended, restore normal color
			is_damaged = false
			damage_timer = 0.0
			if animated_sprite:
				animated_sprite.modulate = Color.WHITE
	
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
	
	# Apply movement based on state (only if not attacking)
	if not is_attacking:
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
	else:
		# Lock horizontal position during attacks (Street Fighter style)
		velocity.x = 0.0
		input_dir = 0.0
	
	# Move the character
	move_and_slide()
	
	# Update animations based on state
	if animated_sprite:
		update_animation(input_dir)
	
	# AI attack decision - attack when Player 1 is in range (only if not damaged)
	if is_on_floor() and not is_attacking and not is_damaged and player1:
		var distance_to_player1 = global_position.distance_to(player1.global_position)
		if distance_to_player1 <= ATTACK_RANGE:
			# Random chance to attack
			if randf() < ATTACK_PROBABILITY:
				# Randomly choose between punch and kick
				var attack_type = "Punch" if randf() > 0.5 else "Kick"
				start_attack(attack_type)
	
	# Check for attack hits and trigger damage on Player 1
	if is_attacking and player1:
		check_attack_hit()
	
	# AI shooting - shoot randomly when on ground, cooldown ready, and has enough points
	if is_on_floor() and projectile_cooldown_timer <= 0 and damage_points >= PROJECTILE_COST and not is_attacking:
		if randf() < SHOOT_PROBABILITY:
			shoot_projectile()
			projectile_cooldown_timer = PROJECTILE_COOLDOWN

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

func take_damage():
	# Trigger damage state
	is_damaged = true
	damage_timer = DAMAGE_DURATION
	
	# Cancel any ongoing attacks
	if is_attacking:
		is_attacking = false
		current_attack_type = ""
		attack_timer = 0.0
	
	# Set red overlay
	if animated_sprite:
		animated_sprite.modulate = Color.RED

func start_attack(attack_type: String):
	is_attacking = true
	current_attack_type = attack_type
	attack_timer = ATTACK_TIMEOUT  # Reset timeout
	# Stop horizontal movement immediately when attack starts
	velocity.x = 0.0
	if animated_sprite:
		animated_sprite.play(attack_type)

func update_animation(input_dir: float):
	if not animated_sprite:
		return
	
	# Priority: Attack > Jump > Walk > Idle
	if is_attacking:
		# Don't change animation during attack
		# Wait for attack timer to finish
		if attack_timer <= 0:
			is_attacking = false
			current_attack_type = ""
		return
	
	# Jump states
	if not is_on_floor():
		if velocity.y > 0:
			# Ascending
			if animated_sprite.animation != "Jump Up":
				animated_sprite.play("Jump Up")
		else:
			# Falling
			if animated_sprite.animation != "Jump Down":
				animated_sprite.play("Jump Down")
		return
	
	# Ground movement
	if input_dir != 0:
		# Walking
		if animated_sprite.animation != "Walk":
			animated_sprite.play("Walk")
	else:
		# Idle
		if animated_sprite.animation != "Idle":
			animated_sprite.play("Idle")
	
	# Always face towards Player 1
	if player1:
		# Face left (flip_h = true) when Player 1 is to the left
		# Face right (flip_h = false) when Player 1 is to the right
		animated_sprite.flip_h = (player1.global_position.x < global_position.x)

func check_attack_hit():
	if not player1:
		return
	
	# Calculate distance to Player 1
	var distance = global_position.distance_to(player1.global_position)
	
	# Check if Player 1 is in attack range
	if distance <= ATTACK_RANGE:
		# Check if Player 1 is rolling (invulnerable)
		if "is_rolling" in player1 and player1.is_rolling:
			return  # Player 1 is rolling, no damage
		
		# Check if attack animation is in active hit frame (middle portion)
		var attack_progress = (ATTACK_TIMEOUT - attack_timer) / ATTACK_TIMEOUT
		if attack_progress >= 0.2 and attack_progress <= 0.8:
			# Hit detected! Trigger damage on Player 1
			if player1.has_method("take_damage"):
				player1.take_damage()
			# Award points for successful hit
			earn_points(POINTS_PER_HIT)
