extends CharacterBody3D

# Projectile parameters
const SPEED = 12.0
const LIFETIME = 3.0
const MAX_DISTANCE = 50.0

var direction = Vector3(1, 0, 0)  # Default direction (right)
var spawn_position = Vector3.ZERO
var lifetime_timer = 0.0

# Get the gravity from the project settings
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Reference to Area3D for player detection
@onready var hit_area = $HitArea

func _ready():
	spawn_position = global_position
	# Connect Area3D signal to detect player hits
	if hit_area:
		hit_area.body_entered.connect(_on_area_body_entered)

func _physics_process(delta):
	# Update lifetime
	lifetime_timer += delta
	if lifetime_timer >= LIFETIME:
		queue_free()
		return
	
	# Check distance traveled
	var distance_traveled = global_position.distance_to(spawn_position)
	if distance_traveled >= MAX_DISTANCE:
		queue_free()
		return
	
	# Apply gravity (slight downward arc)
	velocity.y -= gravity * delta * 0.3  # Reduced gravity for projectiles
	
	# Apply horizontal movement
	velocity.x = direction.x * SPEED
	velocity.z = direction.z * SPEED
	
	# Move the projectile
	move_and_slide()
	
	# Check for collisions (ground only, since collision_mask = 1)
	if get_slide_collision_count() > 0:
		# Hit ground, destroy projectile
		queue_free()

func _on_area_body_entered(body):
	# Check if the body is a player (CharacterBody3D)
	if body is CharacterBody3D:
		# Hit a player, destroy projectile
		queue_free()

