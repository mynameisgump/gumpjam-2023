extends CharacterBody3D;

var direction : Vector3;
var target_speed : Vector3;
var accel : float;
var hvel : Vector3;

@onready var head  : Node3D = $Body/Head;
@onready var camera : Camera3D = $Body/Head/Camera3D;
@onready var flamer_particles : GPUParticles3D = $Body/Head/Weapons/GumpThrower/FlameParticles;
@onready var flamer_hurt_box : Area3D = $Body/Head/Weapons/GumpThrower/FlameArea;
@onready var timer: Timer = $FlamerTick;
@onready var gun_raycast: RayCast3D = $Body/Head/Camera3D/RayCast3D;
@onready var gun_animation: AnimationPlayer = $Body/Head/Weapons/Pistol/AnimationPlayer;
@onready var animation_hud: AnimationPlayer = $AnimationPlayerHUD;
@onready var dash_timer: Timer = $DashTimer;

@onready var main_animation: AnimationPlayer = $AnimationPlayer;
@onready var animation_hud_damage: AnimationPlayer = $AnimationPlayerHUDDamage;

@onready var hud_combo: Label = $HUD/ComboLabel;
@onready var hud_kills: Label = $HUD/KillLabel
@onready var hud_health: Label = $HUD/HealthLabel;
@onready var hud_wave: Label = $HUD/WaveLabel;
@onready var death_score: Label = $HUD/DeathLabelScore; 

@onready var iFrames : Timer = $iFrames

@onready var dash_sound: AudioStreamPlayer = $Audio/DashSound;
@onready var death_sound: AudioStreamPlayer = $Audio/DeathSound;
@onready var fire_sound: AudioStreamPlayer = $Audio/FireSound;
@onready var gun_sound: AudioStreamPlayer = $Body/Head/Weapons/Pistol/AudioStreamPlayer;
@onready var hurt_sound: AudioStreamPlayer = $Audio/HurtSound;

@export var GRAVITY = 9.8;
@export var MAX_SPEED: float = 10.0;
# Original Default of 18
@export var JUMP_SPEED = 500;
@export var ACCEL = 4.5;
@export var MAX_ACCEL = 150.0;
@export var DEACCEL= 0.86;
@export var MAX_SLOPE_ANGLE = 40;
@export var default_fov = 75;



# Speed Parameter
const SPEED = 7.0;
# Jump Velocity Parameter
#const JUMP_VELOCITY = 10;
const JUMP_VELOCITY = 10;
# Amount of directional control
const CONTROL : float = 15.0;
const DAMAGE = 5;

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity");

# Dashing Variables
var is_dashing = false
var dashing = false
var dash_dir = Vector3()
var dash_move_vec = Vector2()
var dash_acc = 0
var dash_accel = 20
#var dash_fov = 10
var dir
@export var DASH_SPEED: float = 30.0
@export var DASH_TIME = 0.2

# Leaning Variables
var lean_left;
var lean_right;
var z_tilt = 0.0;
var z_tilt_target = 0.0;
var z_tilt_value = 0.01;
var LEAN_SPEED = 5;

var alive = true;
var death_scene = false;
var jump_dash_reset = false;

var health = 100;
var score = 0;
var combo = 1;
var kills = 0;
var current_wave = 1;

signal death;

func _ready():
	animation_hud.play("RESET")
	

func damage():
	if iFrames.is_stopped() and alive:
		iFrames.start()
		health -= 5;
		hurt_sound.play()
		animation_hud_damage.play("Hit")
		if health <=0:
			alive = false;
			death_sound.play()
			main_animation.play("Dead")
			death.emit();

	
func set_combo(new_combo):
	combo = new_combo;

func set_wave(new_wave):
	current_wave = new_wave;
	animation_hud_damage.play("Newwave")

func _physics_process(delta : float) -> void:
	if alive:
		handle_hud(delta);
		handle_input(delta);
		handle_movement(delta);
		handle_gun(delta);

	else:
		if death_scene == false:
			death_scene = true;

func handle_hud(delta):
	hud_combo.text = str(combo)+"x";
	hud_kills.text = "Score: "+str(score);
	hud_health.text = "Health: "+str(health);
	hud_wave.text = "Wave: "+str(current_wave);
	death_score.text = "Final Score: "+str(score);

func is_moving():
	return Input.is_action_pressed("move_left") or \
	Input.is_action_pressed("move_right") or \
	Input.is_action_pressed("move_up") or \
	Input.is_action_pressed("move_down") 

func handle_input(delta : float) -> void:

	z_tilt_target = 0.0
	var cam_xform = camera.get_global_transform()
	
	if Input.is_action_pressed("move_left"):
		lean_left = true
		z_tilt_target = z_tilt_value*5
		
	if Input.is_action_pressed("move_right"):
		lean_right = true
		z_tilt_target = -z_tilt_value*5
		
	if Input.is_action_just_pressed("fire_flamer"):
		flamer_particles.emitting = true;
		MAX_SPEED = 2.0;
		GRAVITY = 5.0;
		timer.start();
		fire_sound.play();
		
	if Input.is_action_just_released("fire_flamer"):
		flamer_particles.emitting = false;
		MAX_SPEED = 10.0;
		GRAVITY = 9.8;
		timer.stop();
		fire_sound.stop();
		
	if Input.is_action_just_pressed("move_dash") \
		and not dashing \
		and dash_timer.is_stopped():
			main_animation.play("Dash")
			dash_sound.play()
			dash_dir = Vector3()
			dash_move_vec = Vector2()
			dashing = true 
			dash_move_vec = Input.get_vector("move_left", "move_right", "move_down", "move_up")
			if dash_move_vec.x == 0 and dash_move_vec.y == 0:
				dash_move_vec.y = 1
			dash_move_vec = dash_move_vec.normalized()
		
			dash_dir += -cam_xform.basis.z * dash_move_vec.y
			dash_dir += cam_xform.basis.x * dash_move_vec.x

func handle_movement(delta : float) -> void:
			
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
		
	if Input.is_action_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		jump_dash_reset = true;
	
	if jump_dash_reset == true and is_on_floor():
		jump_dash_reset = false
		dash_timer.stop()
		
	
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta * CONTROL)

	hvel = velocity
	hvel.y = 0.0
	hvel *= DEACCEL
	
	if hvel.length() < MAX_SPEED * 0.01:
		hvel = Vector3.ZERO
	
	var speed = hvel.dot(direction)

	var accel = clamp(MAX_SPEED - speed, 0.0, MAX_ACCEL * delta)
	hvel += direction * accel
	
	velocity.x = hvel.x
	velocity.z = hvel.z
	
	if dashing: 
		dash_acc += delta
		dash_dir.y = 0
		dash_dir = dash_dir.normalized()
		
		velocity.y = 0
		var hvel = velocity
		hvel.y = 0

		var target = dash_dir
		target *= DASH_SPEED

		hvel = hvel.lerp(target, dash_accel * delta)
		
		velocity.x = hvel.x
		velocity.z = hvel.z

		if dash_acc >= DASH_TIME:
			dashing = false
			dash_acc = 0
			dash_timer.start()

	# Leaning code
	z_tilt += (z_tilt_target-z_tilt)*LEAN_SPEED*delta
	head.rotation.z = z_tilt

	move_and_slide()
	
func handle_gun(delta):
	if Input.is_action_just_pressed("fire_gun"):
		gun_animation.play("gun_fire");

		gun_sound.play();

		if gun_raycast.is_colliding():
			var target = gun_raycast.get_collider();
			if target.is_in_group("enemy"):
				var hit = target.damage_gun(30);
				if hit:
					animation_hud.play("HitMarker")

func _on_flamer_tick_timeout():
	var enemies = flamer_hurt_box.get_overlapping_bodies();

	for e in enemies:
		if e.has_method("damage_flamer"):
			e.damage_flamer(DAMAGE)


func _on_enemy_death():
	score += 100*combo;
	
func _on_enemy_burned():
	score += 5*combo;
	
func _on_enemy_hurtbox_entered():
	print("hit")
	
