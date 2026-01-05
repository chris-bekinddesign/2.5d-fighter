extends CharacterBody3D

# Movement parameters
const WALK_SPEED = 5.0
const RUN_SPEED = 8.0
const JUMP_VELOCITY = 8.0
const ROLL_SPEED = 10.0
const ROLL_DURATION = 0.5

# Double-tap detection
const DOUBLE_TAP_TIME = 0.3
var last_key_press_time = {"A": 0.0, "D": 0.0}
var last_key_press_dir = 0.0
var is_running = false

# Combo system
const COMBO_TIMEOUT = 0.5
var combo_buffer = []
var combo_patterns = {
	["J", "J", "K"]: "punch_punch_kick",
	["J", "K", "J"]: "punch_kick_punch",
	["K", "J", "K"]: "kick_punch_kick",
}

# State tracking
var is_rolling = false
var roll_timer = 0.0
var is_attacking = false
var attack_combo_name = ""
var current_animation_finished = false
var attack_timer = 0.0
const ATTACK_TIMEOUT = 1.0  # Fallback timeout for attack animations
var is_air_attack = false  # Track if attack started in the air

# Attack chaining system
var queued_attack = ""  # Next attack to chain into
var attack_start_time = 0.0  # Time when current attack started
const CANCEL_WINDOW_START = 0.3  # Start of cancel window (30% through animation)
const CANCEL_WINDOW_END = 0.7  # End of cancel window (70% through animation)
const INPUT_BUFFER_TIME = 0.2  # Time window to buffer input before cancel window

# Get the gravity from the project settings
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Track previous frame's key states
var was_w_pressed = false
var was_n_pressed = false
var was_j_pressed = false
var was_k_pressed = false
var was_a_pressed = false
var was_d_pressed = false
var was_u_pressed = false

# Projectile shooting
const PROJECTILE_COOLDOWN = 0.5
var projectile_cooldown_timer = 0.0
var projectile_scene = preload("res://scenes/Projectile.tscn")

# Damage points system
var damage_points = 0
const MAX_POINTS = 100
const PROJECTILE_COST = 50
const POINTS_PER_HIT = 15
const POINTS_ON_DAMAGE = 5  # Points when taking damage
const COMBO_MULTIPLIER = 1.5  # Bonus multiplier for chained attacks

# Damage state system
var is_damaged = false
var damage_timer = 0.0
const DAMAGE_DURATION = 0.5  # How long damage state lasts

# Reference to AnimatedSprite3D node
@onready var animated_sprite = $AnimatedSprite3D

# Reference to opponent (Player 2)
@onready var opponent = get_node("../Player2")

# Hit detection
const ATTACK_RANGE = 2.5  # Range for attack to hit
var last_hit_time = 0.0
const HIT_COOLDOWN = 0.3  # Prevent multiple hits from same attack

# Collision mask for roll through opponent
var original_collision_mask = 0
const GROUND_ONLY_MASK = 1  # Only collide with ground layer

func _ready():
	if animated_sprite:
		animated_sprite.animation_finished.connect(_on_animation_finished)
	# Store original collision mask for roll through opponent
	original_collision_mask = collision_mask

func _on_animation_finished():
	current_animation_finished = true
	# Reset attack state when attack animation finishes
	# But check if we have a queued attack to chain into
	if is_attacking:
		if queued_attack != "":
			# Chain to queued attack immediately
			chain_attack(queued_attack)
			queued_attack = ""
		else:
			# No queued attack, reset state
			is_attacking = false
			attack_combo_name = ""
			attack_timer = 0.0
			is_air_attack = false

func _physics_process(delta):
	# Update timers
	roll_timer -= delta
	if roll_timer <= 0 and is_rolling:
		is_rolling = false
		# Restore original collision mask when roll ends
		collision_mask = original_collision_mask
		# Remove collision exception with opponent
		if opponent:
			remove_collision_exception_with(opponent)
	
	# Update damage timer
	if is_damaged:
		damage_timer -= delta
		if damage_timer <= 0:
			# Damage state ended, restore normal color
			is_damaged = false
			damage_timer = 0.0
			if animated_sprite:
				animated_sprite.modulate = Color.WHITE
		else:
			# Smooth color transition (optional - can keep solid red)
			# For now, keep solid red during damage
			pass
	
	# Attack timeout fallback and chaining
	if is_attacking:
		attack_timer -= delta
		
		# Check if we're in cancel window and have queued attack
		if queued_attack != "":
			# Calculate animation progress using attack timer (0.0 to 1.0)
			var elapsed_time = ATTACK_TIMEOUT - attack_timer
			var progress = elapsed_time / ATTACK_TIMEOUT
			
			# Check if in cancel window (30% to 70% through animation)
			if progress >= CANCEL_WINDOW_START and progress <= CANCEL_WINDOW_END:
				# Cancel current attack and chain to next
				chain_attack(queued_attack)
				queued_attack = ""
			elif progress > CANCEL_WINDOW_END:
				# Missed cancel window, clear queue
				queued_attack = ""
		
		if attack_timer <= 0:
			# Force reset attack state if timeout reached
			is_attacking = false
			attack_combo_name = ""
			is_air_attack = false
			current_animation_finished = true
			queued_attack = ""  # Clear queue if attack times out
	
	# Update combo buffer timeout
	update_combo_buffer(delta)
	
	# Add gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Handle roll (N key) - only when on ground and not attacking
	if is_on_floor() and not is_attacking:
		var n_just_pressed = Input.is_key_pressed(KEY_N) and not was_n_pressed
		was_n_pressed = Input.is_key_pressed(KEY_N)
		
		if n_just_pressed and not is_rolling:
			# Set collision mask immediately to pass through opponent (ground only)
			# This must be done FIRST before any other roll setup
			collision_mask = GROUND_ONLY_MASK
			# Add collision exception with opponent to ensure we can roll through
			if opponent:
				add_collision_exception_with(opponent)
			is_rolling = true
			roll_timer = ROLL_DURATION
	
	# Handle jump (W or Space) - only when on ground and not attacking/rolling
	if is_on_floor() and not is_attacking and not is_rolling:
		var w_just_pressed = Input.is_key_pressed(KEY_W) and not was_w_pressed
		was_w_pressed = Input.is_key_pressed(KEY_W)
		
		if Input.is_action_just_pressed("ui_accept") or w_just_pressed:
			velocity.y = JUMP_VELOCITY
	
	# Handle attack inputs (J for punch, K for kick) - only if not damaged
	if not is_rolling and not is_damaged:
		handle_attack_inputs()
	
	# Handle projectile shooting (U key)
	handle_projectile_shooting(delta)
	
	# Get input direction (A/D for left/right) - disabled during roll, but allowed during air attacks
	var input_dir = 0.0
	if not is_rolling and (not is_attacking or is_air_attack):
		var a_just_pressed = Input.is_key_pressed(KEY_A) and not was_a_pressed
		var d_just_pressed = Input.is_key_pressed(KEY_D) and not was_d_pressed
		var a_pressed = Input.is_key_pressed(KEY_A)
		var d_pressed = Input.is_key_pressed(KEY_D)
		
		was_a_pressed = a_pressed
		was_d_pressed = d_pressed
		
		# Double-tap detection
		if a_just_pressed:
			var current_time = Time.get_ticks_msec() / 1000.0
			if last_key_press_dir == -1.0 and (current_time - last_key_press_time["A"]) < DOUBLE_TAP_TIME:
				is_running = true
			last_key_press_time["A"] = current_time
			last_key_press_dir = -1.0
		elif d_just_pressed:
			var current_time = Time.get_ticks_msec() / 1000.0
			if last_key_press_dir == 1.0 and (current_time - last_key_press_time["D"]) < DOUBLE_TAP_TIME:
				is_running = true
			last_key_press_time["D"] = current_time
			last_key_press_dir = 1.0
		
		# Set input direction
		if a_pressed:
			input_dir = -1.0
		elif d_pressed:
			input_dir = 1.0
		else:
			# Reset running state when key is released
			is_running = false
			last_key_press_dir = 0.0
	
	# Apply movement
	if is_attacking:
		if is_air_attack:
			# Allow horizontal movement during air attacks
			if input_dir:
				# Apply air control (slightly reduced compared to ground)
				var air_speed = WALK_SPEED * 0.7  # 70% of walk speed for air control
				velocity.x = input_dir * air_speed
			# Don't force stop, allow momentum to continue
		else:
			# Lock horizontal position during ground attacks (Street Fighter style)
			velocity.x = 0.0
	elif is_rolling:
		# Roll movement - use direct position updates to bypass collision with players
		var roll_dir = 1.0 if input_dir >= 0 else -1.0
		if input_dir == 0:
			roll_dir = 1.0 if animated_sprite.flip_h == false else -1.0
		velocity.x = roll_dir * ROLL_SPEED
		
		# Apply gravity during roll
		velocity.y -= gravity * delta
		
		# Direct position movement to pass through players
		var movement = velocity * delta
		global_position += movement
		
		# Manual ground collision check and snap to ground
		var space_state = get_world_3d().direct_space_state
		var ground_check = PhysicsRayQueryParameters3D.create(
			global_position + Vector3(0, 0.5, 0),  # Check from player center
			global_position + Vector3(0, -2.0, 0)   # Check below player
		)
		ground_check.collision_mask = 1  # Only check ground layer
		var ground_result = space_state.intersect_ray(ground_check)
		
		if ground_result:
			# Snap to ground level (player height is 2 units, center at 1 unit)
			var ground_y = ground_result.position.y + 1.5
			if global_position.y <= ground_y:
				global_position.y = ground_y
				velocity.y = 0.0
	else:
		# Normal movement (walk or run)
		if input_dir:
			var speed = RUN_SPEED if is_running else WALK_SPEED
			velocity.x = input_dir * speed
		else:
			velocity.x = move_toward(velocity.x, 0, WALK_SPEED)
			is_running = false
	
	# Update animations based on state
	if animated_sprite:
		update_animation(input_dir)
	
	# Check for attack hits and award points
	if is_attacking:
		check_attack_hit()
	
	# Move the character (skip if rolling, already moved directly)
	if not is_rolling:
		move_and_slide()

func handle_attack_inputs():
	var j_just_pressed = Input.is_key_pressed(KEY_J) and not was_j_pressed
	var k_just_pressed = Input.is_key_pressed(KEY_K) and not was_k_pressed
	was_j_pressed = Input.is_key_pressed(KEY_J)
	was_k_pressed = Input.is_key_pressed(KEY_K)
	
	if j_just_pressed:
		add_to_combo_buffer("J")
		check_combos()
		if not is_attacking:
			start_attack("Punch")
		else:
			# Queue attack for chaining
			queued_attack = "Punch"
	elif k_just_pressed:
		add_to_combo_buffer("K")
		check_combos()
		if not is_attacking:
			start_attack("Kick")
		else:
			# Queue attack for chaining
			queued_attack = "Kick"

func start_attack(attack_type: String):
	is_attacking = true
	current_animation_finished = false
	attack_timer = ATTACK_TIMEOUT  # Reset timeout
	attack_start_time = Time.get_ticks_msec() / 1000.0
	# Detect if attack started in the air
	is_air_attack = not is_on_floor()
	# Stop horizontal movement immediately when ground attack starts
	if not is_air_attack:
		velocity.x = 0.0
	if animated_sprite:
		animated_sprite.play(attack_type)

func add_to_combo_buffer(input: String):
	var current_time = Time.get_ticks_msec() / 1000.0
	combo_buffer.append({"input": input, "time": current_time})
	# Keep only last 5 inputs
	if combo_buffer.size() > 5:
		combo_buffer.pop_front()

func update_combo_buffer(delta):
	var current_time = Time.get_ticks_msec() / 1000.0
	# Remove inputs older than combo timeout
	combo_buffer = combo_buffer.filter(func(entry): return (current_time - entry["time"]) < COMBO_TIMEOUT)

func check_combos():
	var input_sequence = []
	for entry in combo_buffer:
		input_sequence.append(entry["input"])
	
	# Check for combo patterns (check last 3 inputs)
	if input_sequence.size() >= 3:
		var last_three = input_sequence.slice(-3)
		for pattern in combo_patterns.keys():
			if last_three == pattern:
				# Execute combo
				attack_combo_name = combo_patterns[pattern]
				start_attack("Kick")  # Combos end with kick for now
				combo_buffer.clear()
				return

func chain_attack(attack_type: String):
	# Chain to next attack smoothly
	# Don't reset attack state, just switch animation
	current_animation_finished = false
	attack_timer = ATTACK_TIMEOUT  # Reset timeout for new attack
	attack_start_time = Time.get_ticks_msec() / 1000.0
	# Maintain air attack state if chaining in air
	if not is_on_floor():
		is_air_attack = true
	# Stop horizontal movement for ground attacks
	if not is_air_attack:
		velocity.x = 0.0
	if animated_sprite:
		animated_sprite.play(attack_type)

func handle_projectile_shooting(delta):
	# Update cooldown timer
	if projectile_cooldown_timer > 0:
		projectile_cooldown_timer -= delta
	
	# Check for shoot input (U key)
	var u_just_pressed = Input.is_key_pressed(KEY_U) and not was_u_pressed
	was_u_pressed = Input.is_key_pressed(KEY_U)
	
	if u_just_pressed and projectile_cooldown_timer <= 0:
		# Only shoot if player has enough points
		if damage_points >= PROJECTILE_COST:
			shoot_projectile()
			projectile_cooldown_timer = PROJECTILE_COOLDOWN

func shoot_projectile():
	# Check if player has enough points
	if damage_points < PROJECTILE_COST:
		return  # Not enough points to shoot
	
	if not projectile_scene:
		return
	
	# Create projectile instance
	var projectile = projectile_scene.instantiate()
	
	# Get the scene root to add projectile to
	var scene_root = get_tree().current_scene
	if not scene_root:
		return
	
	# Determine direction based on sprite facing
	var facing_right = true
	if animated_sprite:
		facing_right = not animated_sprite.flip_h
	
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

func check_attack_hit():
	if not opponent:
		return
	
	# Check if enough time has passed since last hit
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_hit_time < HIT_COOLDOWN:
		return
	
	# Calculate distance to opponent
	var distance = global_position.distance_to(opponent.global_position)
	
	# Check if opponent is in attack range
	if distance <= ATTACK_RANGE:
		# Check if opponent is rolling (invulnerable)
		if "is_rolling" in opponent and opponent.is_rolling:
			return  # Opponent is rolling, no damage
		
		# Check if attack animation is in active hit frame (middle portion)
		var attack_progress = (ATTACK_TIMEOUT - attack_timer) / ATTACK_TIMEOUT
		if attack_progress >= 0.2 and attack_progress <= 0.8:
			# Hit detected! Award points
			var points_earned = POINTS_PER_HIT
			
			# Bonus for chained attacks
			if attack_combo_name != "":
				points_earned = int(points_earned * COMBO_MULTIPLIER)
			
			earn_points(points_earned)
			last_hit_time = current_time
			
			# Trigger damage on opponent
			if opponent.has_method("take_damage"):
				opponent.take_damage()
			
			# Also award points to opponent for taking damage
			if opponent.has_method("earn_points"):
				opponent.earn_points(POINTS_ON_DAMAGE)

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
		attack_combo_name = ""
		attack_timer = 0.0
		queued_attack = ""
	
	# Set red overlay
	if animated_sprite:
		animated_sprite.modulate = Color.RED

func update_animation(input_dir: float):
	if not animated_sprite:
		return
	
	# Priority: Attack > Roll > Jump > Run > Walk > Idle
	if is_attacking:
		# Don't change animation during attack
		# Wait for animation to finish or timeout
		if current_animation_finished:
			is_attacking = false
			attack_combo_name = ""
			is_air_attack = false
			attack_timer = 0.0
		return
	
	if is_rolling:
		if animated_sprite.animation != "Roll":
			animated_sprite.play("Roll")
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
		if is_running:
			if animated_sprite.animation != "Run":
				animated_sprite.play("Run")
		else:
			if animated_sprite.animation != "Walk":
				animated_sprite.play("Walk")
	else:
		# Idle
		if animated_sprite.animation != "Idle":
			animated_sprite.play("Idle")
	
	# Always face towards opponent
	if opponent:
		# Face right (flip_h = false) when opponent is to the right
		# Face left (flip_h = true) when opponent is to the left
		animated_sprite.flip_h = (opponent.global_position.x < global_position.x)
