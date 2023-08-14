extends CharacterBody3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer;
@onready var nav_agent : NavigationAgent3D = get_node("NavigationAgent3D");
@onready var burning_timer: Timer = $BurningTimer;
@onready var burn_tick_timer: Timer = $BurnTickTimer;
@onready var rat_mesh: MeshInstance3D = $Armature/Skeleton3D/Rat;
@onready var hitbox: CollisionShape3D = $Hitbox

@onready var sound_death: AudioStreamPlayer3D = $RatDeath;
@onready var sound_tunnel: AudioStreamPlayer3D = $RatTunnel;
@onready var fire_tick: AudioStreamPlayer3D = $FireTick;
@onready var sound_runnning: AudioStreamPlayer3D = $RatRun;

@onready var fire_particles: GPUParticles3D = $FireParticles;

@onready var death_timer: Timer = $DeathTimer;

# @export var SPEED = 3.0;
@export var SPEED = 12.0;
@export var health = 100;

signal death;
signal burned;

var cur_burn = 1;
var burnt = false;
var shader_mat: ShaderMaterial;
var cur_state = "Running";
var dead = false;
var on_fire = true;

var damaging_player = false;
var player_area

func kill():
	health = -1;	

func damage_gun(DAMAGE: int):
	if burnt and not dead:
		cur_state = "Hit"
		animation_player.play("Hit")
		health -= DAMAGE;
		return true;

func damage_flamer(DAMAGE: int):
	if not dead:
		if not burnt:
			burnt = true;
			SPEED = SPEED*0.8;
		fire_particles.emitting = true;
		health -= DAMAGE
		fire_tick.play();
		burning_timer.start();
		on_fire = true;
		burned.emit()

func damage_afterburn(DAMAGE: int):
	if not dead:
		health -= DAMAGE
		fire_tick.play();
		burned.emit();

func update_target_location(target):
	nav_agent.target_position = target;
	
func update_rotation(target):
	#var rotation_target = Vector3(target.x,  0, target.z)
	if not dead:
		self.look_at(target)

func handle_movement():
	if not dead and cur_state != "Hit":
		var current_location = global_transform.origin;
		var next_location = nav_agent.get_next_path_position();


		var new_velocity = (next_location - current_location).normalized() * SPEED;
		velocity = velocity.move_toward(new_velocity, .25);
		move_and_slide();

func handle_damage():
	if burning_timer.is_stopped() == false:
		if burn_tick_timer.is_stopped():
			damage_afterburn(5)
			burn_tick_timer.start()
	else:
		fire_particles.emitting = false;
			
		
	if health <= 0 and dead == false:
		fire_particles.emitting = false;
		dead = true;
		on_fire = false;
		cur_state = "Death";
		animation_player.play("Death");
		sound_death.play()
		hitbox.disabled = true;
		sound_runnning.stop()
		death.emit();
		death_timer.start();
		#queue_free();

func handle_burn():
	if burnt and cur_burn > 0:
		cur_burn -= 0.0025;
		shader_mat.set_shader_parameter("dissolve_amount", cur_burn);

func _ready():
	shader_mat = rat_mesh.get_surface_override_material(0).get_next_pass()
	animation_player.play("Spawn");
	sound_tunnel.play();
	cur_state = "Running";
	sound_runnning.play()

func _process(delta):
	if dead and animation_player.is_playing() == false and death_timer.is_stopped():
		print("Destroying enemy")
		queue_free();
	elif not dead and animation_player.is_playing() == false:
		cur_state = "Running"
		animation_player.play("Running");
	
	if burning_timer.is_stopped():
		on_fire = false;

	handle_movement();
	
	handle_burn()	
	if not dead:
		handle_damage()
		damage_player()



func damage_player():
	if damaging_player:
		var player = player_area.get_parent()
		player.damage()

func _on_hurtbox_area_entered(area):
	player_area = area;
	damaging_player = true;



func _on_hurtbox_area_exited(area):
	damaging_player = false;

func _on_safezone_exited(area):
	print("I'm dead");

func _on_navigation_agent_3d_velocity_computed(safe_velocity):
	pass # Replace with function body.
